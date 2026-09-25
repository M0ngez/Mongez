import 'package:flutter/material.dart';
import 'package:mongez/core/constants/endpoints.dart';
import 'package:mongez/core/di/services_locator.dart';
import 'package:mongez/core/network/api_service.dart';
import 'package:mongez/core/widgets/custom_app_bar.dart';
import 'package:mongez/features/client/home/data/models/rating_model.dart';
import 'package:mongez/features/client/home/presentation/widgets/reviews_list.dart';
import 'package:mongez/generated/l10n.dart';

class WorkerReviewsScreen extends StatefulWidget {
  final int workerId;

  const WorkerReviewsScreen({super.key, required this.workerId});

  @override
  State<WorkerReviewsScreen> createState() => _WorkerReviewsScreenState();
}

class _WorkerReviewsScreenState extends State<WorkerReviewsScreen> {
  List<RatingModel> _ratings = [];
  bool _isLoading = true;
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
        endPoint: Endpoints.workerRatings(widget.workerId),
      );
      final ratingsList = (data is List ? data : <dynamic>[])
              .map((e) => RatingModel.fromJson(e as Map<String, dynamic>))
              .toList();
      if (!mounted) return;
      setState(() {
        _ratings = ratingsList;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[RATINGS] Fetch failed: $e');
      if (!mounted) return;
      setState(() {
        _ratingsError = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    return Scaffold(
      appBar: CustomAppBar(title: lang.reviews),
      body: SingleChildScrollView(
        child: ReviewsList(
          ratings: _ratings,
          isLoading: _isLoading,
          errorMessage: _ratingsError,
        ),
      ),
    );
  }
}