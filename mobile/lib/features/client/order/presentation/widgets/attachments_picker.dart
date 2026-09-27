import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/core/utils/picked_attachment.dart';
import 'package:mongez/core/utils/image_picker_service.dart';
import 'package:mongez/features/client/order/presentation/widgets/attachment_bundle.dart';
import 'package:mongez/features/client/order/presentation/widgets/picker_action_chip.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// Mic recording is only wired for mobile + macOS — on Linux/Windows the
/// permission_handler plugin has no native implementation and would throw
/// MissingPluginException. Web is also excluded for now.
bool get _audioRecordingSupported {
  if (kIsWeb) return false;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return true;
    default:
      return false;
  }
}

class AttachmentsPicker extends StatefulWidget {
  /// Called whenever the bundle changes — the parent should hold the latest.
  final ValueChanged<AttachmentBundle> onChanged;
  const AttachmentsPicker({super.key, required this.onChanged});

  @override
  State<AttachmentsPicker> createState() => _AttachmentsPickerState();
}

class _AttachmentsPickerState extends State<AttachmentsPicker> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  final List<PickedAttachment> _photos = [];
  static const int maxPhotos = 4;
  String? _audioPath;
  int? _audioDurationSeconds;
  bool _isRecording = false;
  bool _isPlaying = false;
  Timer? _recordTimer;
  int _recordSeconds = 0;

  /// Permission rationales already shown this session, keyed by feature so a
  /// granted permission is never re-explained and a denied one is only
  /// explained once.
  final Set<String> _rationaleShown = {};

  /// Explains why an OS permission is about to be requested. Returns false
  /// when the user backs out, so the caller skips the real request.
  Future<bool> _confirmRationale({required String title, required String body}) async {
    if (!mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(S.of(dialogContext).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(S.of(dialogContext).continueLabel),
          ),
        ],
      ),
    );
    if (!mounted) return false;
    return result ?? false;
  }

  Future<bool> _alreadyGranted(List<Permission> permissions) async {
    for (final permission in permissions) {
      try {
        final status = await permission.status;
        if (status.isGranted || status.isLimited) return true;
      } catch (_) {
        // No native implementation on this platform — treat as not granted.
      }
    }
    return false;
  }

  /// Shows the rationale only before the first real request, and never when
  /// the OS permission is already granted.
  Future<bool> _confirmRationaleIfNeeded(
    String id, {
    required String title,
    required String body,
    List<Permission> permissions = const [],
  }) async {
    if (_rationaleShown.contains(id)) return true;
    if (await _alreadyGranted(permissions)) return true;
    if (!mounted) return true;
    final proceed = await _confirmRationale(title: title, body: body);
    _rationaleShown.add(id);
    return proceed;
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(AttachmentBundle(
      photos: List.unmodifiable(_photos),
      audioPath: _audioPath,
      audioDurationSeconds: _audioDurationSeconds,
    ));
  }

  Future<void> _pickFromCamera() async {
    if (_photos.length >= maxPhotos) {
      if (!mounted) return;
      _showError(S.of(context).maxPhotosReached);
      return;
    }
    final proceed = await _confirmRationaleIfNeeded(
      'camera',
      title: S.of(context).cameraPermissionTitle,
      body: S.of(context).cameraPermissionBody,
      permissions: const [Permission.camera],
    );
    if (!proceed || !mounted) return;
    try {
      final picked = await ImagePickerService.pickOne(fromCamera: true);
      if (picked != null) {
        setState(() => _photos.add(picked));
        _emit();
      }
    } on MissingPluginException catch (_) {
      if (!mounted) return;
      _showError(S.of(context).cameraNotSupported);
    } catch (e) {
      debugPrint('[CAMERA] Open failed: $e');
      if (!mounted) return;
      _showError(S.of(context).couldNotOpenCamera);
    }
  }

  Future<void> _pickFromGallery() async {
    final proceed = await _confirmRationaleIfNeeded(
      'gallery',
      title: S.of(context).galleryPermissionTitle,
      body: S.of(context).galleryPermissionBody,
      permissions: const [Permission.photos, Permission.storage],
    );
    if (!proceed || !mounted) return;
    try {
      final remaining = maxPhotos - _photos.length;
      final files = await ImagePickerService.pickMulti(limit: remaining);
      if (files.isNotEmpty) {
        setState(() => _photos.addAll(files.take(remaining)));
        _emit();
      }
    } on MissingPluginException catch (_) {
      if (!mounted) return;
      _showError(S.of(context).galleryNotSupported);
    } catch (e) {
      debugPrint('[GALLERY] Open failed: $e');
      if (!mounted) return;
      _showError(S.of(context).couldNotOpenGallery);
    }
  }

  void _removePhoto(int idx) {
    setState(() => _photos.removeAt(idx));
    _emit();
  }

  Future<void> _toggleRecord() async {
    if (!_audioRecordingSupported) {
      _showError(S.of(context).audioNotSupported);
      return;
    }

    if (_isRecording) {
      final path = await _recorder.stop();
      _recordTimer?.cancel();
      setState(() {
        _isRecording = false;
        if (path != null) {
          _audioPath = path;
          _audioDurationSeconds = _recordSeconds;
        }
      });
      _emit();
      return;
    }

    final proceed = await _confirmRationaleIfNeeded(
      'microphone',
      title: S.of(context).micPermissionTitle,
      body: S.of(context).micPermissionBody,
      permissions: const [Permission.microphone],
    );
    if (!proceed || !mounted) return;

    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (!mounted) return;
        _showError(S.of(context).micPermissionDenied);
        return;
      }
    } on MissingPluginException catch (_) {
      if (!mounted) return;
      _showError(S.of(context).audioNotSupported);
      return;
    } catch (_) {
      if (!mounted) return;
      _showError(S.of(context).micPermissionUnavailable);
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/order_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
    try {
      await _recorder.start(const RecordConfig(), path: path);
      setState(() {
        _isRecording = true;
        _recordSeconds = 0;
      });
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _recordSeconds++);
        if (_recordSeconds >= 120) _toggleRecord(); // cap at 2 min
      });
    } catch (e) {
      if (!mounted) return;
      _showError(S.of(context).couldNotStartRecording);
    }
  }

  Future<void> _togglePlay() async {
    if (_audioPath == null) return;
    if (_isPlaying) {
      await _player.stop();
      setState(() => _isPlaying = false);
      return;
    }
    setState(() => _isPlaying = true);
    await _player.play(DeviceFileSource(_audioPath!));
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  void _removeAudio() {
    setState(() {
      _audioPath = null;
      _audioDurationSeconds = null;
    });
    _emit();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  String _fmtDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final lang = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Action row
        Row(
          children: [
            PickerActionChip(
              icon: Icons.photo_camera_outlined,
              label: lang.cameraOption,
              onTap: _photos.length < maxPhotos ? _pickFromCamera : null,
            ),
            const SizedBox(width: 8),
            const SizedBox(width: 8),
            PickerActionChip(
              icon: Icons.photo_library_outlined,
              label: lang.galleryOption,
              onTap: _photos.length < maxPhotos ? _pickFromGallery : null,
            ),
            const SizedBox(width: 8),
            PickerActionChip(
              icon: _isRecording ? Icons.stop_rounded : Icons.mic_none_rounded,
              label: _isRecording
                  ? _fmtDuration(_recordSeconds)
                  : (_audioPath != null ? lang.rerecord : lang.record),
              onTap: _audioRecordingSupported ? _toggleRecord : null,
              tint: _isRecording ? cs.error : null,
              recording: _isRecording,
            ),
          ],
        ),
        if (_photos.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.memory(
                        _photos[i].bytes,
                        width: 88, height: 88, fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: -6, right: -6,
                      child: InkWell(
                        onTap: () => _removePhoto(i),
                        child: Container(
                          decoration: BoxDecoration(
                            color: cs.error, shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
                            ],
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
        if (_audioPath != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: _togglePlay,
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cs.primary, shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                      color: Colors.white, size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lang.voiceNote, style: tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      )),
                      if (_audioDurationSeconds != null)
                        Text(_fmtDuration(_audioDurationSeconds!),
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.6),
                            )),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: cs.error),
                  onPressed: _removeAudio,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
