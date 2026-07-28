import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmacist/core/constants/app_colors.dart';
import 'package:pharmacist/core/di/injection_container.dart';
import 'package:pharmacist/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pharmacist/features/auth/presentation/bloc/auth_state.dart';
import 'package:pharmacist/features/ratings/domain/entities/rating_entity.dart';
import 'package:pharmacist/features/ratings/presentation/bloc/rating_bloc.dart';
import 'package:pharmacist/features/ratings/presentation/bloc/rating_event.dart';
import 'package:pharmacist/features/ratings/presentation/bloc/rating_state.dart';

/// My Ratings (backend Module H: GET /ratings/pharmacist/{pharmacistId}).
///
/// This screen previously showed a fabricated pharmacy revenue/sales
/// dashboard with no backend support (see AUDIT_REPORT.md, Issue 9) — the
/// backend has no inventory/sales/revenue concept at all. My Ratings is the
/// real capability this app has for a "reports"-shaped screen.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final pharmacistId = authState is AuthAuthenticated ? authState.user.id : null;

    if (pharmacistId == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'يجب تسجيل الدخول لعرض التقييمات.',
            style: GoogleFonts.cairo(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return BlocProvider(
      create: (context) => getIt<RatingBloc>()..add(PharmacistRatingsRequested(pharmacistId)),
      child: const _RatingsView(),
    );
  }
}

class _RatingsView extends StatelessWidget {
  const _RatingsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          'تقييماتي',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900, color: AppColors.textPrimary),
        ),
      ),
      body: BlocBuilder<RatingBloc, RatingState>(
        builder: (context, state) {
          if (state is RatingLoading || state is RatingInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is RatingError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Text(
                  state.message,
                  style: GoogleFonts.cairo(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (state is RatingLoaded) {
            if (state.items.isEmpty) {
              return Center(
                child: Text(
                  'لا توجد تقييمات بعد.',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
              );
            }
            return ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                _buildAverageCard(state),
                SizedBox(height: 16.h),
                ...state.items.map((r) => Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: _RatingCard(rating: r),
                    )),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildAverageCard(RatingLoaded state) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.averageScore.toStringAsFixed(1),
                style: GoogleFonts.poppins(fontSize: 36.sp, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
              ),
              Text(
                'متوسط هذه الصفحة (${state.items.length} تقييم)',
                style: GoogleFonts.cairo(fontSize: 12.sp, color: AppColors.textSecondary),
              ),
            ],
          ),
          Icon(Icons.star_rounded, color: Colors.amber, size: 40.r),
        ],
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  final RatingEntity rating;

  const _RatingCard({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(rating.reviewerName, style: GoogleFonts.cairo(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < rating.score ? Icons.star_rounded : Icons.star_border_rounded,
                    color: Colors.amber,
                    size: 18.r,
                  ),
                ),
              ),
            ],
          ),
          if (rating.comment != null && rating.comment!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(rating.comment!, style: GoogleFonts.cairo(fontSize: 13.sp, color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}
