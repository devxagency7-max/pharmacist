import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmacist/core/constants/app_colors.dart';
import '../../domain/entities/prescription_entity.dart';
import '../bloc/prescription_bloc.dart';
import '../bloc/prescription_event.dart';
import '../bloc/prescription_state.dart';

/// Approve/reject detail screen for a single pending prescription
/// (backend Module C: GET /prescriptions/{id}, POST /{id}/approve|reject).
///
/// [initialPrescription] is the item as it appeared in the queue list, shown
/// immediately while a fresh GET /prescriptions/{id} call loads in the
/// background — so the screen isn't limited to whatever fields the list
/// endpoint happened to include.
class PrescriptionDetailScreen extends StatefulWidget {
  final PrescriptionEntity initialPrescription;

  const PrescriptionDetailScreen({super.key, required this.initialPrescription});

  @override
  State<PrescriptionDetailScreen> createState() => _PrescriptionDetailScreenState();
}

class _PrescriptionDetailScreenState extends State<PrescriptionDetailScreen> {

  @override
  void initState() {
    super.initState();
    context.read<PrescriptionBloc>().add(
          PrescriptionDetailRequested(widget.initialPrescription.id),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          'عرض الوصفة الطبية',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900, color: AppColors.textPrimary),
        ),
      ),
      body: BlocBuilder<PrescriptionBloc, PrescriptionState>(
        builder: (context, state) {
          final p = state is PrescriptionDetailLoaded ? state.prescription : widget.initialPrescription;
          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state is PrescriptionDetailError)
                  Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: Text(
                      state.message,
                      style: GoogleFonts.cairo(color: AppColors.error, fontSize: 12.sp),
                    ),
                  ),
                _buildInfoRow('المريض', p.patientName),
                if (p.doctorName != null && p.doctorName!.isNotEmpty)
                  _buildInfoRow('الطبيب', p.doctorName!),
                if (p.clinicName != null && p.clinicName!.isNotEmpty)
                  _buildInfoRow('العيادة', p.clinicName!),
                if (p.issueDate != null) _buildInfoRow('تاريخ الإصدار', _formatDate(p.issueDate!)),
                if (p.expiryDate != null) _buildInfoRow('تاريخ الانتهاء', _formatDate(p.expiryDate!)),
                SizedBox(height: 16.h),
                if (p.imageUrls.isEmpty)
                  Text(
                    'لا توجد صور مرفقة لهذه الوصفة.',
                    style: GoogleFonts.cairo(color: AppColors.textSecondary),
                  )
                else
                  SizedBox(
                    height: 300.h,
                    child: PageView.builder(
                      itemCount: p.imageUrls.length,
                      itemBuilder: (context, index) => InteractiveViewer(
                        minScale: 1,
                        maxScale: 4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16.r),
                          child: Image.network(
                            p.imageUrls[index],
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Center(
                              child: Icon(Icons.broken_image_outlined, size: 48.r, color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: 32.h),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
