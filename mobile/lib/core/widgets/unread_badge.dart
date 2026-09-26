import 'package:flutter/material.dart';

/// Unread indicator overlaid on a navigation icon.
///
/// Pure presentation: the caller passes [count] (a value <= 0 renders
/// nothing), so counting logic stays in the cubits that own it.
class UnreadBadge extends StatelessWidget {
  final int count;
  final String? semanticsLabel;

  const UnreadBadge({
    super.key,
    required this.count,
    this.semanticsLabel,
  });

  /// 1..99 as-is, `99+` beyond it — the same convention the bell badge
  /// expectation uses, so a crowded tab never overflows its pill.
  static String format(int count) => count > 99 ? '99+' : '$count';

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: semanticsLabel,
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cs.error,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.surface, width: 1.5),
        ),
        child: Text(
          format(count),
          // Keep `99+` in LTR order inside RTL labels.
          textDirection: TextDirection.ltr,
          style: TextStyle(
            color: cs.onError,
            fontSize: 9,
            height: 1.1,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
