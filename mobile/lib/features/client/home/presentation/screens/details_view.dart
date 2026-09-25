import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mongez/core/constants/endpoints.dart';
import 'package:mongez/core/di/services_locator.dart';
import 'package:mongez/core/network/api_service.dart';
import 'package:mongez/core/routing/navigation_service.dart';
import 'package:mongez/features/client/home/data/models/rating_model.dart';
import 'package:mongez/features/client/home/presentation/widgets/book_cta.dart';
import 'package:mongez/features/client/home/presentation/widgets/details_header.dart';
import 'package:mongez/features/client/home/presentation/widgets/details_section.dart';
import 'package:mongez/features/client/home/presentation/widgets/info_card.dart';
import 'package:mongez/features/client/home/presentation/widgets/reviews_list.dart';
import 'package:mongez/features/client/home/presentation/widgets/stats_row.dart';
import 'package:mongez/features/client/order/presentation/screens/checkout_screen.dart';
import 'package:mongez/features/shared/workers/data/models/worker_model.dart';
import 'package:mongez/generated/l10n.dart';

class DetailsView extends StatefulWidget {
  final bool isCustomer;
  final WorkerModel worker;

  const DetailsView({
    super.key,
    required this.worker,
    required this.isCustomer,
  });

  @override
  State<DetailsView> createState() => _DetailsViewState();
}

class _DetailsViewState extends State<DetailsView> {
  List<RatingModel> _ratings = [];
  bool _isLoadingRatings = true;
  String? _ratingsError;

  @override
  void initState() {
    super.initState();
    _fetchRatings();
  }

  Future<void> _fetchRatings() async {
    try {
      final apiService = getIt<ApiService>();
      final data = await apiService.get(
        endPoint: Endpoints.workerRatings(widget.worker.userId ?? widget.worker.id),
      );
      final ratingsList = (data is List ? data : <dynamic>[])
              .map((e) => RatingModel.fromJson(e as Map<String, dynamic>))
              .toList();
      if (!mounted) return;
      setState(() {
        _ratings = ratingsList;
        _isLoadingRatings = false;
      });
    } catch (e) {
      debugPrint('[RATINGS] Fetch failed: $e');
      if (!mounted) return;
      setState(() {
        _ratingsError = e.toString();
        _isLoadingRatings = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final tt = theme.textTheme;
    final w = widget.worker;

    final name = w.nameFor(locale).isNotEmpty ? w.nameFor(locale) : (w.username ?? '');
    final profession = w.professionFor(locale);
    final bio = w.bioFor(locale);
    final location = w.locationLabel(locale);
    final rate = _formatMoney(w.hourlyRate, w.currency, locale);
    final minCharge = _formatMoney(w.minimumCharge, w.currency, locale);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          DetailsHeader(
            worker: w,
            isCustomer: widget.isCustomer,
            name: name,
            profession: profession,
            location: location,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: StatsRow(worker: w),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: InfoCard(
                children: [
                  if (rate != null)
                    InfoRow(
                      icon: Icons.payments_outlined,
                      label: S.of(context).hourlyRate,
                      value: '$rate / hr',
                      highlight: true,
                    ),
                  if (minCharge != null)
                    InfoRow(
                      icon: Icons.receipt_long_outlined,
                      label: lang.callOutFee,
                      value: minCharge,
                    ),
                  if (w.languages.isNotEmpty)
                    InfoRow(
                      icon: Icons.language_outlined,
                      label: lang.languages,
                      value: w.languages.map((c) => _langName(lang, c)).join(' · '),
                    ),
                  if (w.serviceRadiusKm > 0)
                    InfoRow(
                      icon: Icons.location_searching,
                      label: lang.serviceArea,
                      value: lang.withinKm(w.serviceRadiusKm),
                    ),
                ],
              ),
            ),
          ),
          if (w.specialtiesFor(locale).isNotEmpty)
            SliverToBoxAdapter(
              child: DetailsSection(
                title: lang.specialties,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: w.specialtiesFor(locale).map((s) =>
                      Tag(label: s),
                    ).toList(),
                  ),
                ),
              ),
            ),
          if (bio.isNotEmpty)
            SliverToBoxAdapter(
              child: DetailsSection(
                title: lang.description,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Text(
                    bio,
                    style: tt.bodyMedium?.copyWith(height: 1.55),
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: DetailsSection(
              title: lang.reviews,
              child: ReviewsList(
                ratings: _ratings,
                isLoading: _isLoadingRatings,
                errorMessage: _ratingsError,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: widget.isCustomer
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: BookCTA(
                  onTap: () {
                    NavigationService.requireLogin(
                      context,
                      message: lang.checkoutLoginRequired,
                      onLoggedIn: () => NavigationService
                          .navigatorKey.currentState
                          ?.push(
                        MaterialPageRoute(
                          builder: (_) => CheckoutScreen(worker: w),
                        ),
                      ),
                    );
                  },
                  label: lang.bookNow,
                  rate: rate,
                ),
              ),
            )
          : null,
    );
  }

  static String? _formatMoney(double? v, String currency, String locale) {
    if (v == null || v <= 0) return null;
    final fmt = NumberFormat.decimalPattern(locale);
    final body = fmt.format(v.round());
    final symbol = currency == 'EGP'
        ? (locale == 'ar' ? 'ج.م' : 'EGP')
        : currency;
    return '$body $symbol';
  }

  static String _langName(S lang, String code) {
    switch (code) {
      case 'ar': return lang.languageArabic;
      case 'en': return lang.languageEnglish;
      case 'fr': return lang.languageFrench;
      default:    return code.toUpperCase();
    }
  }
}
