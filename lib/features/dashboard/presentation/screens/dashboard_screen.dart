import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmacist/core/constants/app_colors.dart';
import 'package:pharmacist/core/di/injection_container.dart';
import 'package:pharmacist/core/widgets/app_drawer.dart';
import 'package:pharmacist/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pharmacist/features/auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/dashboard_entities.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _pharmacyId;

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _pharmacyId = authState.user.pharmacyId;
    }

    return BlocProvider(
      create: (context) {
        final bloc = getIt<DashboardBloc>();
        if (_pharmacyId != null) {
          bloc.add(DashboardLoadRequested(_pharmacyId!));
        }
        return bloc;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        drawerScrimColor: Colors.transparent,
        endDrawer: const AppDrawer(),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20.r),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'لوحة البيانات والإحصائيات',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w900,
              fontSize: 20.sp,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        body: Stack(
          children: [
            _buildBackgroundMesh(),
            BlocBuilder<DashboardBloc, DashboardState>(
              builder: (context, state) {
                if (state is DashboardLoading) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
                }

                if (state is DashboardLoaded) {
                  final data = state.data;
                  return RefreshIndicator(
                    onRefresh: () async {
                      if (_pharmacyId != null) {
                        context.read<DashboardBloc>().add(DashboardLoadRequested(_pharmacyId!));
                      }
                    },
                    color: AppColors.primaryGreen,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildKpiGrid(data.metrics),
                          SizedBox(height: 24.h),
                          _buildTrendChartCard(data.trend),
                          SizedBox(height: 20.h),
                          _buildDistributionCard(data.distribution),
                          SizedBox(height: 20.h),
                          _buildTopMedicationsCard(data.topMedications),
                          SizedBox(height: 20.h),
                          _buildRejectionNotesCard(data.rejectionNotes),
                          SizedBox(height: 40.h),
                        ],
                      ),
                    ),
                  );
                }

                if (state is DashboardError) {
                  return Center(
                    child: Text(
                      state.message,
                      style: GoogleFonts.cairo(color: AppColors.error, fontWeight: FontWeight.bold),
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
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

  Widget _buildKpiGrid(DashboardMetricsEntity metrics) {
    final successPercent = (metrics.successRate * 100).toStringAsFixed(0);
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16.w,
      mainAxisSpacing: 16.h,
      childAspectRatio: 1.4,
      children: [
        _buildKpiCard(
          title: 'إجمالي الطلبات',
          value: metrics.totalOrders.toString(),
          icon: Icons.shopping_bag_rounded,
          color: Colors.blue,
        ),
        _buildKpiCard(
          title: 'طلبات معلقة',
          value: metrics.pendingOrders.toString(),
          icon: Icons.hourglass_empty_rounded,
          color: Colors.orange,
        ),
        _buildKpiCard(
          title: 'طلبات ناجحة',
          value: metrics.completedOrders.toString(),
          icon: Icons.check_circle_rounded,
          color: AppColors.primaryGreen,
        ),
        _buildKpiCard(
          title: 'معدل النجاح',
          value: '$successPercent%',
          icon: Icons.trending_up_rounded,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              Icon(icon, color: color, size: 20.r),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChartCard(List<FulfillmentTrendEntity> trend) {
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
          Text(
            'معدل الإنجاز الشهري',
            style: GoogleFonts.cairo(
              fontSize: 15.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 20.h),
          if (trend.isEmpty)
            Center(
              child: Text(
                'لا توجد بيانات كافية',
                style: GoogleFonts.cairo(color: AppColors.textSecondary),
              ),
            )
          else
            SizedBox(
              height: 180.h,
              child: BarChart(
                BarChartData(
                  barGroups: trend.asMap().entries.map((entry) {
                    int idx = entry.key;
                    var item = entry.value;
                    return BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(
                          toY: item.completedCount.toDouble(),
                          color: AppColors.primaryGreen,
                          width: 16.w,
                          borderRadius: BorderRadius.circular(4.r),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 100,
                            color: Colors.grey.withOpacity(0.05),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          int idx = value.toInt();
                          if (idx >= 0 && idx < trend.length) {
                            return Padding(
                              padding: EdgeInsets.only(top: 8.h),
                              child: Text(
                                '${trend[idx].month}/${trend[idx].year.toString().substring(2)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDistributionCard(OrderDistributionEntity distribution) {
    final total = distribution.withPrescription + distribution.withoutPrescription;
    final withPrescPercent = total > 0 ? (distribution.withPrescription / total * 100).toStringAsFixed(0) : '0';

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
          Text(
            'توزيع الطلبات',
            style: GoogleFonts.cairo(
              fontSize: 15.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 120.h,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4.r,
                      centerSpaceRadius: 30.r,
                      sections: [
                        PieChartSectionData(
                          color: AppColors.primaryGreen,
                          value: distribution.withPrescription.toDouble(),
                          title: '$withPrescPercent%',
                          radius: 35.r,
                          titleStyle: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11.sp,
                          ),
                        ),
                        PieChartSectionData(
                          color: Colors.blue,
                          value: distribution.withoutPrescription.toDouble(),
                          title: '${100 - int.parse(withPrescPercent)}%',
                          radius: 35.r,
                          titleStyle: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem('طلبات بروشتة', distribution.withPrescription, AppColors.primaryGreen),
                    SizedBox(height: 12.h),
                    _buildLegendItem('طلبات بدون روشتة', distribution.withoutPrescription, Colors.blue),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String title, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 12.r,
          height: 12.r,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        SizedBox(width: 8.w),
        Text(
          title,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12.sp, color: AppColors.textPrimary),
        ),
        const Spacer(),
        Text(
          count.toString(),
          style: GoogleFonts.poppins(fontWeight: FontWeight.w900, fontSize: 13.sp, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildTopMedicationsCard(List<TopMedicationEntity> meds) {
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
          Text(
            'الأدوية الأكثر طلباً',
            style: GoogleFonts.cairo(
              fontSize: 15.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          if (meds.isEmpty)
            Center(
              child: Text(
                'لا توجد بيانات',
                style: GoogleFonts.cairo(color: AppColors.textSecondary),
              ),
            )
          else
            ...meds.asMap().entries.map((entry) {
              int idx = entry.key + 1;
              var med = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Row(
                  children: [
                    Container(
                      width: 24.r,
                      height: 24.r,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          idx.toString(),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        med.name,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        '${med.orderItemCount} طلب',
                        style: GoogleFonts.cairo(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildRejectionNotesCard(List<RejectionNoteEntity> notes) {
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
          Text(
            'أسباب الرفض الشائعة للطلبات',
            style: GoogleFonts.cairo(
              fontSize: 15.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          if (notes.isEmpty)
            Center(
              child: Text(
                'لا توجد تعليقات رفض سابقة',
                style: GoogleFonts.cairo(color: AppColors.textSecondary),
              ),
            )
          else
            ...notes.map((note) => Container(
                  margin: EdgeInsets.only(bottom: 10.h),
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 18.r),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          note.reason,
                          style: GoogleFonts.cairo(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}
