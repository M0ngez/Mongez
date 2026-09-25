import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/core/routing/navigation_service.dart';
import 'package:mongez/core/session/guest_session.dart';
import 'package:mongez/features/client/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:mongez/generated/l10n.dart';

class FavoriteButton extends StatefulWidget {
  final int workerId;
  final double size;
  final double iconSize;

  const FavoriteButton({
    super.key,
    required this.workerId,
    this.size = 32,
    this.iconSize = 15,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onToggle(FavoritesCubit cubit) {
    if (GuestSession.isGuest) {
      NavigationService.requireLogin(
        context,
        message: S.of(context).signInToViewData,
        onLoggedIn: () {
          if (!mounted) return;
          cubit.toggleFavorite(widget.workerId);
        },
      );
      return;
    }
    _animController.forward().then((_) => _animController.reverse());
    cubit.toggleFavorite(widget.workerId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<FavoritesCubit, FavoritesState>(
      builder: (context, state) {
        final cubit = context.read<FavoritesCubit>();
        final isFav = cubit.isFavorite(widget.workerId);
        final isLoading = cubit.isToggling(widget.workerId);

        return GestureDetector(
          onTap: isLoading ? null : () => _onToggle(cubit),
          child: AnimatedBuilder(
            animation: _scaleAnim,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnim.value,
                child: child,
              );
            },
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.45)
                    : Colors.white.withValues(alpha: 0.85),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
              child: isLoading
                  ? SizedBox(
                      width: widget.iconSize * 0.6,
                      height: widget.iconSize * 0.6,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark ? Colors.white70 : theme.colorScheme.primary,
                      ),
                    )
                  : Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      size: widget.iconSize,
                      color: isFav
                          ? Colors.red
                          : (isDark ? Colors.white : Colors.black87),
                    ),
            ),
          ),
        );
      },
    );
  }
}
