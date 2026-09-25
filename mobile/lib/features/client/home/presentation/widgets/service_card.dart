import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mongez/core/routing/navigation_service.dart';
import 'package:mongez/features/client/order/presentation/screens/checkout_screen.dart';
import 'package:mongez/features/client/home/presentation/screens/details_view.dart';
import 'package:mongez/features/client/home/presentation/widgets/service_banner.dart';
import 'package:mongez/features/client/home/presentation/widgets/service_meta_chip.dart';
import 'package:mongez/features/shared/workers/data/models/worker_model.dart';
import 'package:mongez/generated/l10n.dart';

class ServiceCard extends StatelessWidget {
  final bool isCustomer;
  final WorkerModel worker;

  const ServiceCard({
    super.key,
    required this.worker,
    required this.isCustomer,
  });

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final dim = tt.bodySmall?.color?.withValues(alpha: 0.65);

    final name = worker.nameFor(locale).isNotEmpty
        ? worker.nameFor(locale)
        : (worker.username ?? '');
    final profession = worker.professionFor(locale);
    final bio = worker.bioFor(locale);
    final location = worker.locationLabel(locale);
    final rateLabel = _formatRate(worker.hourlyRate, worker.currency, locale);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border.all(color: cs.outline.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.35 : 0.05,
              ),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ServiceBanner(
              worker: worker,
              isCustomer: isCustomer,
              cs: cs,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 38, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name + verified badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16.5,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                      if (worker.isVerified)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Icon(
                            Icons.verified_rounded,
                            size: 18,
                            color: cs.primary,
                          ),
                        ),
                    ],
                  ),
                  if (profession.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      profession,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodyMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Meta row: rating · location · experience
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ServiceMetaChip(
                        icon: Icons.star_rounded,
                        iconColor: Colors.amber.shade700,
                        label: worker.averageRating.toStringAsFixed(1),
                        sub: ' (${worker.completedJobs})',
                      ),
                      if (location.isNotEmpty)
                        ServiceMetaChip(
                          icon: Icons.location_on_outlined,
                          iconColor: dim,
                          label: location,
                        ),
                      if (worker.experienceYears > 0)
                        ServiceMetaChip(
                          icon: Icons.work_outline,
                          iconColor: dim,
                          label: '${worker.experienceYears} ${lang.years}',
                        ),
                    ],
                  ),
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      bio,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodySmall?.copyWith(
                        height: 1.45,
                        fontSize: 13,
                        color: tt.bodySmall?.color?.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (rateLabel != null)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rateLabel,
                                  style: tt.titleSmall?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  lang.perHour,
                                  style: tt.labelSmall?.copyWith(
                                    color: cs.primary.withValues(alpha: 0.8),
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (rateLabel != null) const SizedBox(width: 10),
                      Expanded(
                        flex: rateLabel == null ? 1 : 2,
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () {
                              if (isCustomer) {
                                NavigationService.requireLogin(
                                  context,
                                  message: lang.checkoutLoginRequired,
                                  onLoggedIn: () => NavigationService
                                      .navigatorKey.currentState
                                      ?.push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          CheckoutScreen(worker: worker),
                                    ),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetailsView(
                                      worker: worker,
                                      isCustomer: isCustomer,
                                    ),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cs.primary,
                              foregroundColor: cs.onPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              isCustomer ? lang.bookNow : lang.edit,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String? _formatRate(double? rate, String currency, String locale) {
    if (rate == null || rate <= 0) return null;
    final fmt = NumberFormat.decimalPattern(locale);
    final body = fmt.format(rate.round());
    // Egypt: prefer "EGP" / "ج.م" symbol convention.
    final symbol = currency == 'EGP'
        ? (locale == 'ar' ? 'ج.م' : 'EGP')
        : currency;
    return '$body $symbol';
  }
}
