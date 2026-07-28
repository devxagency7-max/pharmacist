import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmacist/core/constants/app_colors.dart';

class MedicalRecordsScreen extends StatelessWidget {
  final List<dynamic> records;
  final String patientName;

  const MedicalRecordsScreen({
    super.key,
    required this.records,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildBackgroundMesh(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: records.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                          physics: const BouncingScrollPhysics(),
                          itemCount: records.length,
                          separatorBuilder: (context, index) => SizedBox(height: 14.h),
                          itemBuilder: (context, index) {
                            final record = records[index];
                            return FadeInUp(
                              delay: Duration(milliseconds: 50 * index),
                              child: _buildRecordCard(context, record),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundMesh() {
    return Stack(
      children: [
        Positioned(
          top: -100.h,
          right: -100.w,
          child: Container(
            width: 300.r,
            height: 300.r,
            decoration: BoxDecoration(
              color: const Color(0xFFB3E5FC).withOpacity(0.4),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: 200.h,
          left: -50.w,
          child: Container(
            width: 250.r,
            height: 250.r,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE6DC).withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 100.h,
          right: -50.w,
          child: Container(
            width: 280.r,
            height: 280.r,
            decoration: BoxDecoration(
              color: const Color(0xFFEAEFF5).withOpacity(0.5),
              shape: BoxShape.circle,
            ),
          ),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
          child: Container(color: Colors.transparent),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: FadeInDown(
        duration: const Duration(milliseconds: 600),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'السجلات الطبية',
                    style: GoogleFonts.cairo(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'ملف المريض: $patientName',
                    style: GoogleFonts.cairo(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
            Icon(Icons.folder_open_rounded, size: 64.r, color: AppColors.textSecondary),
            SizedBox(height: 16.h),
            Text(
              'لا توجد سجلات طبية مرفوعة لهذا المريض',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(BuildContext context, Map<String, dynamic> record) {
    final fileUrl = record['fileUrl'] as String? ?? '';
    final type = record['type'] as String? ?? 'سند طبي';
    final createdAtStr = record['createdAt'] as String? ?? '';
    
    DateTime? createdAt = DateTime.tryParse(createdAtStr);
    final dateFormatted = createdAt != null
        ? '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}'
        : 'تاريخ غير معروف';

    final isImage = _isImageFile(fileUrl);
    final arabicType = _getArabicType(type);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: Colors.white.withOpacity(0.75), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: InkWell(
            onTap: () => _openRecord(context, arabicType, fileUrl, isImage),
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Icon(
                      isImage ? Icons.image_rounded : Icons.insert_drive_file_rounded,
                      color: AppColors.primaryGreen,
                      size: 24.r,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          arabicType,
                          style: GoogleFonts.cairo(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 12.r, color: AppColors.textSecondary),
                            SizedBox(width: 4.w),
                            Text(
                              dateFormatted,
                              style: GoogleFonts.poppins(
                                fontSize: 12.sp,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14.r,
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isImageFile(String url) {
    final cleanUrl = url.toLowerCase().split('?').first;
    return cleanUrl.endsWith('.jpg') ||
        cleanUrl.endsWith('.jpeg') ||
        cleanUrl.endsWith('.png') ||
        cleanUrl.endsWith('.gif') ||
        cleanUrl.endsWith('.webp');
  }

  String _getArabicType(String type) {
    switch (type.toLowerCase()) {
      case 'report':
      case 'medicalreport':
        return 'تقرير طبي';
      case 'prescription':
        return 'روشتة طبية';
      case 'labresult':
      case 'lab':
        return 'تحليل معملي';
      case 'xray':
        return 'أشعة سينية';
      default:
        return type;
    }
  }

  void _openRecord(BuildContext context, String type, String url, bool isImage) {
    if (isImage) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _ImagePreviewScreen(title: type, imageUrl: url),
        ),
      );
    } else {
      _showDocumentDialog(context, type, url);
    }
  }

  void _showDocumentDialog(BuildContext context, String type, String url) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
          title: Text(
            type,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(fontWeight: FontWeight.w900, color: AppColors.textPrimary, fontSize: 18.sp),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insert_drive_file_rounded, size: 64.r, color: AppColors.primaryGreen),
              SizedBox(height: 16.h),
              Text(
                'هذا السند عبارة عن مستند ملف وليس صورة. يمكنك نسخ الرابط لفتحه في المتصفح.',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 13.sp),
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontSize: 12.sp, color: AppColors.textSecondary),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy_rounded, color: AppColors.primaryGreen, size: 20.r),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: url));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم نسخ رابط الملف إلى الحافظة.')),
                        );
                      },
                    )
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'إغلاق',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePreviewScreen extends StatelessWidget {
  final String title;
  final String imageUrl;

  const _ImagePreviewScreen({required this.title, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          title,
          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const CircularProgressIndicator(color: Colors.white);
            },
            errorBuilder: (context, error, stackTrace) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image_rounded, size: 64.r, color: Colors.white54),
                SizedBox(height: 12.h),
                Text(
                  'تعذر تحميل الصورة المرفقة',
                  style: GoogleFonts.cairo(color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
