import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmacist/core/constants/app_colors.dart';
import '../../domain/entities/order_entity.dart';
import '../bloc/orders_bloc.dart';
import '../bloc/orders_event.dart';
import '../bloc/orders_state.dart';

class OrderDetailsScreen extends StatelessWidget {
  final OrderEntity order;
  final String branchId;

  const OrderDetailsScreen({
    super.key,
    required this.order,
    required this.branchId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrdersBloc, OrdersState>(
      listener: (context, state) {
        if (state is OrdersActionSuccess) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20.r),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'تفاصيل الطلب #${order.id.substring(0, 6).toUpperCase()}',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w900,
              fontSize: 18.sp,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        body: Stack(
          children: [
            _buildBackgroundMesh(),
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatusCard(),
                          SizedBox(height: 20.h),
                          _buildCustomerCard(),
                          SizedBox(height: 20.h),
                          _buildMedicationsList(),
                          if (order.prescription != null) ...[
                            SizedBox(height: 20.h),
                            _buildPrescriptionCard(),
                          ],
                          if (order.deliveryNotes != null && order.deliveryNotes!.isNotEmpty) ...[
                            SizedBox(height: 20.h),
                            _buildDeliveryNotesCard(),
                          ],
                          SizedBox(height: 30.h),
                        ],
                      ),
                    ),
                  ),
                  _buildActionButtons(context),
                ],
              ),
            ),
          ],
        ),
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
              color: const Color(0xFFB3E5FC).withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -50.h,
          left: -50.w,
          child: Container(
            width: 250.r,
            height: 250.r,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE6DC).withOpacity(0.2),
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

  Widget _buildStatusCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'حالة الطلب',
                style: GoogleFonts.cairo(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                _getStatusText(order.orderStatus),
                style: GoogleFonts.cairo(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: _getStatusColor(order.orderStatus),
                ),
              ),
            ],
          ),
          if (order.finalPrice != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'السعر الإجمالي',
                  style: GoogleFonts.cairo(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${order.finalPrice} ج.م',
                  style: GoogleFonts.poppins(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_rounded, color: AppColors.primaryGreen, size: 22.r),
              SizedBox(width: 8.w),
              Text(
                'بيانات المريض',
                style: GoogleFonts.cairo(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Colors.white),
          Text(
            order.customerName,
            style: GoogleFonts.cairo(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Icon(Icons.storefront_rounded, color: AppColors.textSecondary, size: 16.r),
              SizedBox(width: 6.w),
              Text(
                order.branchName,
                style: GoogleFonts.cairo(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationsList() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medical_services_rounded, color: AppColors.primaryGreen, size: 22.r),
              SizedBox(width: 8.w),
              Text(
                'الأدوية المطلوبة',
                style: GoogleFonts.cairo(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Colors.white),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.items.length,
            separatorBuilder: (ctx, idx) => const Divider(height: 20, color: Colors.white),
            itemBuilder: (ctx, idx) {
              final item = order.items[idx];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44.r,
                    height: 44.r,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(Icons.medication_rounded, color: AppColors.primaryGreen, size: 24.r),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w900,
                            fontSize: 13.sp,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (item.dosage != null && item.dosage!.isNotEmpty)
                          Text(
                            item.dosage!,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 11.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    'الكمية: ${item.quantity}',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w900,
                      fontSize: 12.sp,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_rounded, color: Colors.blue, size: 22.r),
              SizedBox(width: 8.w),
              Text(
                'الروشتة الطبية المرفقة',
                style: GoogleFonts.cairo(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Colors.white),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.sticky_note_2_rounded, color: Colors.blue, size: 24.r),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'روشتة رقم #${order.prescription!.id.substring(0, 6).toUpperCase()}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'حالة الروشتة: ${order.prescription!.status}',
                      style: GoogleFonts.cairo(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryNotesCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping_rounded, color: AppColors.primaryGreen, size: 22.r),
              SizedBox(width: 8.w),
              Text(
                'ملاحظات التوصيل',
                style: GoogleFonts.cairo(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Colors.white),
          Text(
            order.deliveryNotes!,
            style: GoogleFonts.cairo(
              fontSize: 13.sp,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (order.orderStatus == 'Pending') {
      return Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.6), width: 1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52.h,
                child: OutlinedButton(
                  onPressed: () => _showRejectDialog(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                  ),
                  child: Text(
                    'رفض الطلب',
                    style: GoogleFonts.cairo(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: SizedBox(
                height: 52.h,
                child: ElevatedButton(
                  onPressed: () => _onAccept(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                    elevation: 0,
                  ),
                  child: Text(
                    'قبول الطلب',
                    style: GoogleFonts.cairo(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (order.orderStatus == 'Accepted') {
      return Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.6), width: 1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52.h,
                child: OutlinedButton(
                  onPressed: () => _onCancel(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                  ),
                  child: Text(
                    'إلغاء الطلب',
                    style: GoogleFonts.cairo(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: SizedBox(
                height: 52.h,
                child: ElevatedButton(
                  onPressed: () => _onComplete(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                    elevation: 0,
                  ),
                  child: Text(
                    'تجهيز واكتمال',
                    style: GoogleFonts.cairo(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _onAccept(BuildContext context) {
    final initialPrice = (order.finalPrice != null && order.finalPrice! > 0)
        ? order.finalPrice!.toStringAsFixed(0)
        : '';
    final priceController = TextEditingController(text: initialPrice);
    final notesController = TextEditingController(text: 'تم قبول الطلب وجاري التجهيز');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          'قبول الطلب وتحديد السعر النهائي',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 16.sp),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'السعر النهائي المطلوب تدفعه عند الاستلام (جنيه):',
              style: GoogleFonts.cairo(fontSize: 13.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.cairo(fontSize: 14.sp, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'أدخل السعر المطلوب',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                suffixText: 'ج.م',
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'ملاحظات إضافية (اختياري):',
              style: GoogleFonts.cairo(fontSize: 13.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: notesController,
              maxLines: 2,
              style: GoogleFonts.cairo(fontSize: 13.sp),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final priceVal = double.tryParse(priceController.text.trim()) ?? (order.finalPrice ?? 0.0);
              Navigator.pop(ctx);
              context.read<OrdersBloc>().add(
                    OrdersRespondSubmitted(
                      branchId: branchId,
                      orderId: order.id,
                      action: 'accept',
                      finalPrice: priceVal,
                      notes: notesController.text.trim(),
                    ),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              elevation: 0,
            ),
            child: Text(
              'تأكيد القبول',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _onComplete(BuildContext context) {
    context.read<OrdersBloc>().add(
          OrdersCompleteSubmitted(
            branchId: branchId,
            orderId: order.id,
          ),
        );
  }

  void _onCancel(BuildContext context) {
    context.read<OrdersBloc>().add(
          OrdersCancelSubmitted(
            branchId: branchId,
            orderId: order.id,
          ),
        );
  }

  void _showRejectDialog(BuildContext context) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          'رفض الطلب',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 16.sp),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'من فضلك أدخل سبب رفض الطلب:',
              style: GoogleFonts.cairo(fontSize: 13.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: GoogleFonts.cairo(fontSize: 13.sp),
              decoration: InputDecoration(
                hintText: 'مثال: الدواء غير متوفر حالياً',
                hintStyle: GoogleFonts.cairo(color: AppColors.textSecondary.withOpacity(0.5)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<OrdersBloc>().add(
                    OrdersRespondSubmitted(
                      branchId: branchId,
                      orderId: order.id,
                      action: 'reject',
                      notes: reasonController.text.trim(),
                    ),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              elevation: 0,
            ),
            child: Text(
              'رفض الطلب',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'قيد الانتظار';
      case 'accepted':
        return 'مقبول وقيد التجهيز';
      case 'completed':
        return 'مكتمل';
      case 'rejected':
        return 'مرفوض';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'completed':
        return AppColors.primaryGreen;
      case 'rejected':
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textPrimary;
    }
  }
}
