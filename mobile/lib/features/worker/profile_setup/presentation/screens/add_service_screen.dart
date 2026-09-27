import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/features/auth/models/auth.dart';
import 'package:mongez/features/client/home/presentation/cubit/categories_cubit.dart';
import 'package:mongez/features/worker/profile_setup/presentation/cubit/create_worker_profile_cubit.dart';
import 'package:mongez/generated/l10n.dart';
import 'package:mongez/core/routing/navigation_service.dart';
import 'package:mongez/core/widgets/custom_app_bar.dart';

/// Dual-mode service form:
/// - create (default): first-time setup, POSTs to /workers/create/.
/// - edit (`isEditMode: true`): loads /workers/me/, pre-fills every
///   field with the worker's current service and PATCHes the changes.
class AddServiceScreen extends StatefulWidget {
  final Auth? pendingAuth;
  final bool isEditMode;
  const AddServiceScreen({
    super.key,
    this.pendingAuth,
    this.isEditMode = false,
  });

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedCategoryId;
  final _experienceController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isAvailable = true;

  /// Starts true when opened in edit mode; flipped back to false if
  /// the profile fetch reveals the worker has no profile yet, so the
  /// form gracefully degrades to create mode.
  late bool _isEdit = widget.isEditMode;
  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    // Defensive: if the CategoriesCubit was reset or never finished
    // its first fetch, kick it now. The repo caches for 5 minutes so
    // this is essentially free when the list is already loaded.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<CategoriesCubit>();
      if (cubit.state is! CategoriesSuccess) {
        cubit.fetchCategories();
      }
      if (_isEdit) {
        context.read<CreateWorkerProfileCubit>().loadProfile();
      }
    });
  }

  @override
  void dispose() {
    _experienceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;
    final cubit = context.read<CreateWorkerProfileCubit>();
    if (_isEdit) {
      cubit.updateProfile(
        categoryId: _selectedCategoryId,
        experienceYears: int.parse(_experienceController.text.trim()),
        isAvailable: _isAvailable,
        description: _descriptionController.text.trim(),
      );
    } else {
      cubit.createProfile(
        categoryId: _selectedCategoryId,
        experienceYears: int.parse(_experienceController.text.trim()),
        isAvailable: _isAvailable,
        description: _descriptionController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return BlocConsumer<CreateWorkerProfileCubit, CreateWorkerProfileState>(
      listener: (context, state) {
        if (state is CreateWorkerProfileFetchLoaded && !_prefilled) {
          _prefilled = true;
          setState(() {
            _selectedCategoryId = state.profile.categoryId;
            _experienceController.text =
                state.profile.experienceYears.toString();
            _descriptionController.text = state.profile.description;
            _isAvailable = state.profile.isAvailable;
          });
        } else if (state is CreateWorkerProfileFailure &&
            _isEdit &&
            !_prefilled &&
            state.errorMessage.toLowerCase().contains('worker profile')) {
          // Worker has no profile yet (404) — degrade to create mode
          // instead of dead-ending with an error.
          setState(() => _isEdit = false);
        } else if (state is CreateWorkerProfileSuccess) {
          if (widget.pendingAuth != null) {
            NavigationService.toMainScreen(context, widget.pendingAuth!);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _isEdit ? lang.serviceUpdatedMessage : lang.profileCreatedMessage,
                ),
              ),
            );
            Navigator.pop(context);
          }
        } else if (state is CreateWorkerProfileFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is CreateWorkerProfileLoading;
        final isFetchingProfile = _isEdit && !_prefilled;
        final categoriesState = context.watch<CategoriesCubit>().state;

        return Scaffold(
          appBar: CustomAppBar(
            title: _isEdit
                ? lang.editService
                : widget.pendingAuth != null
                    ? lang.createProfile
                    : lang.addService,
          ),
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lang.category, style: textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (categoriesState is CategoriesSuccess)
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        hintText: lang.selectCategory,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14,
                        ),
                      ),
                      // Only pass the pre-filled id when it actually
                      // exists in the loaded list, otherwise Flutter
                      // asserts on missing dropdown values.
                      initialValue: categoriesState.categories
                              .any((c) => c.id == _selectedCategoryId)
                          ? _selectedCategoryId
                          : null,
                      items: categoriesState.categories
                          .where((c) => c.id != null)
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.bilingualLabel),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategoryId = v),
                      validator: (v) =>
                          v == null ? lang.thisFieldRequired : null,
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: colorScheme.outline),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  Text(lang.yearsOfExperience, style: textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _experienceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: lang.yearsOfExperience,
                      suffixText: lang.years,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14,
                      ),
                    ),
                    validator: (v) {
                      final text = v?.trim() ?? '';
                      if (text.isEmpty) return lang.thisFieldRequired;
                      final n = int.tryParse(text);
                      if (n == null) return lang.enterValidNumber;
                      if (n < 0 || n > 50) return lang.mustBeBetween0And50;
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  Text(lang.description, style: textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: lang.descriptionHint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SwitchListTile(
                    title: Text(lang.availableForWork),
                    value: _isAvailable,
                    onChanged: (v) => setState(() => _isAvailable = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading || isFetchingProfile
                          ? null
                          : _onSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isLoading || isFetchingProfile
                          ? const SizedBox(
                              height: 24, width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white,
                              ),
                            )
                          : Text(
                              _isEdit
                                  ? lang.editService
                                  : widget.pendingAuth != null
                                      ? lang.createProfile
                                      : lang.addService,
                              style: TextStyle(color: colorScheme.onPrimary),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
