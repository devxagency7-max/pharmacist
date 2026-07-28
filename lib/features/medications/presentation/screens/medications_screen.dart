import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmacist/core/constants/app_colors.dart';
import 'package:pharmacist/core/di/injection_container.dart';
import 'package:pharmacist/features/prescriptions/domain/entities/prescription_entity.dart';
import 'package:pharmacist/features/prescriptions/presentation/bloc/prescription_bloc.dart';
import 'package:pharmacist/features/prescriptions/presentation/bloc/prescription_event.dart';
import 'package:pharmacist/features/prescriptions/presentation/bloc/prescription_state.dart';
import 'package:pharmacist/features/prescriptions/presentation/screens/prescription_detail_screen.dart';

/// The Prescription Review queue (backend Module C:
/// GET /prescriptions/pending, FIFO oldest-first).
///
/// Note: this screen's route/class name (`المدخلات`/"الروشته" in the
/// drawer) predates this rewrite — kept as-is to avoid touching the
/// navigation call sites in app_drawer.dart / home_screen.dart. What was
/// previously here was a mocked prescription-authoring form with no backend
/// support; per PHARMACIST_APP_GUIDE.md Module C, pharmacists only review
/// prescriptions patients upload, they don't author new ones.
class MedicationsScreen extends StatelessWidget {
  const MedicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<PrescriptionBloc>()..add(PrescriptionQueueRequested()),
      child: const _PrescriptionQueueView(),
    );
  }
}

class _PrescriptionQueueView extends StatelessWidget {
  const _PrescriptionQueueView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          'أرشيف الوصفات الطبية',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900, color: AppColors.textPrimary),
        ),
      ),
      body: BlocConsumer<PrescriptionBloc, PrescriptionState>(
        listenWhen: (previous, current) =>
            current is PrescriptionActionSuccess || current is PrescriptionActionError,
        listener: (context, state) {
          if (state is PrescriptionActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is PrescriptionActionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        buildWhen: (previous, current) =>
            current is PrescriptionQueueLoading ||
            current is PrescriptionQueueLoaded ||
            current is PrescriptionQueueError ||
            current is PrescriptionInitial,
        builder: (context, state) {
          if (state is PrescriptionQueueLoading || state is PrescriptionInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PrescriptionQueueError) {
            return _buildErrorState(context, state.message);
          }
          if (state is PrescriptionQueueLoaded) {
            if (state.items.isEmpty) {
              return _buildEmptyState();
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<PrescriptionBloc>().add(PrescriptionQueueRequested());
                await context.read<PrescriptionBloc>().stream.firstWhere(
                      (s) => s is PrescriptionQueueLoaded || s is PrescriptionQueueError,
                    );
              },
              child: ListView.separated(
                padding: EdgeInsets.all(16.w),
                itemCount: state.items.length,
                separatorBuilder: (_, __) => SizedBox(height: 12.h),
                itemBuilder: (context, index) => _PrescriptionCard(prescription: state.items[index]),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 64.r, color: AppColors.textSecondary),
            SizedBox(height: 16.h),
            Text(
              'لا توجد وصفات طبية مسجلة في الأرشيف',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 64.r, color: AppColors.error),
            SizedBox(height: 16.h),
            Text(message, style: GoogleFonts.cairo(color: AppColors.textSecondary), textAlign: TextAlign.center),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => context.read<PrescriptionBloc>().add(PrescriptionQueueRequested()),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
              child: Text('إعادة المحاولة', style: GoogleFonts.cairo(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  final PrescriptionEntity prescription;

  const _PrescriptionCard({required this.prescription});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<PrescriptionBloc>(),
            child: PrescriptionDetailScreen(initialPrescription: prescription),
          ),
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: prescription.imageUrls.isNotEmpty
                  ? Image.network(
                      prescription.imageUrls.first,
                      width: 56.r,
                      height: 56.r,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _thumbnailPlaceholder(),
                    )
                  : _thumbnailPlaceholder(),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prescription.patientName,
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  if (prescription.doctorName != null && prescription.doctorName!.isNotEmpty)
                    Text(
                      prescription.doctorName!,
                      style: GoogleFonts.cairo(fontSize: 12.sp, color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14.r, color: AppColors.textSecondary.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }

  Widget _thumbnailPlaceholder() {
    return Container(
      width: 56.r,
      height: 56.r,
      color: AppColors.primaryGreen.withValues(alpha: 0.1),
      child: Icon(Icons.description_outlined, color: AppColors.primaryGreen),
    );
  }
}
