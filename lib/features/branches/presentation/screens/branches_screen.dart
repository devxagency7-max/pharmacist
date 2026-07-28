import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmacist/core/constants/app_colors.dart';
import 'package:pharmacist/core/di/injection_container.dart';
import 'package:pharmacist/core/widgets/app_drawer.dart';
import 'package:pharmacist/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pharmacist/features/auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/branch_entity.dart';
import '../bloc/branches_bloc.dart';
import '../bloc/branches_event.dart';
import '../bloc/branches_state.dart';
import 'pharmacy_profile_screen.dart';

class BranchesScreen extends StatefulWidget {
  const BranchesScreen({super.key});

  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  String? _pharmacyId;

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _pharmacyId = authState.user.pharmacyId;
    }

    return BlocProvider(
      create: (context) {
        final bloc = getIt<BranchesBloc>();
        if (_pharmacyId != null) {
          bloc.add(BranchesLoadList(_pharmacyId!));
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
            'الصيدلية والفروع',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w900,
              fontSize: 20.sp,
              color: AppColors.textPrimary,
            ),
          ),
          actions: [
            Builder(
              builder: (ctx) => IconButton(
                icon: Icon(Icons.edit_note_rounded, color: AppColors.primaryGreen, size: 26.r),
                onPressed: () {
                  Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (context) => BlocProvider.value(
                        value: ctx.read<BranchesBloc>(),
                        child: const PharmacyProfileScreen(),
                      ),
                    ),
                  ).then((value) {
                    if (_pharmacyId != null && ctx.mounted) {
                      ctx.read<BranchesBloc>().add(BranchesLoadList(_pharmacyId!));
                    }
                  });
                },
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            _buildBackgroundMesh(),
            BlocConsumer<BranchesBloc, BranchesState>(
              listener: (context, state) {
                if (state is BranchesActionSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                      backgroundColor: AppColors.primaryGreen,
                    ),
                  );
                } else if (state is BranchesError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is BranchesLoading && state is! BranchesLoaded) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
                }

                if (state is BranchesLoaded) {
                  final list = state.branches;
                  return Column(
                    children: [
                      Expanded(
                        child: list.isEmpty
                            ? _buildEmptyState()
                            : RefreshIndicator(
                                onRefresh: () async {
                                  if (_pharmacyId != null) {
                                    context.read<BranchesBloc>().add(BranchesLoadList(_pharmacyId!));
                                  }
                                },
                                color: AppColors.primaryGreen,
                                child: ListView.builder(
                                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                                  itemCount: list.length,
                                  itemBuilder: (context, index) {
                                    final branch = list[index];
                                    return FadeInUp(
                                      duration: const Duration(milliseconds: 400),
                                      child: _buildBranchCard(context, branch),
                                    );
                                  },
                                ),
                              ),
                      ),
                      _buildAddBranchButton(context),
                    ],
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

  Widget _buildBranchCard(BuildContext context, BranchEntity branch) {
    bool isActive = branch.status.toLowerCase() == 'active';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Navigator.canPop(context)
              ? Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primaryGreen.withOpacity(0.1)
                        : AppColors.textSecondary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.store_rounded,
                    color: isActive ? AppColors.primaryGreen : AppColors.textSecondary,
                    size: 24.r,
                  ),
                )
              : Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primaryGreen.withOpacity(0.1)
                        : AppColors.textSecondary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.store_rounded,
                    color: isActive ? AppColors.primaryGreen : AppColors.textSecondary,
                    size: 24.r,
                  ),
                ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      branch.name,
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w900,
                        fontSize: 14.sp,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (branch.isMainBranch) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          'رئيسي',
                          style: GoogleFonts.cairo(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  branch.address,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  branch.phoneNumber,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 11.sp,
                    color: AppColors.textSecondary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isActive,
            onChanged: (val) {
              if (_pharmacyId != null) {
                context.read<BranchesBloc>().add(
                      BranchesToggleStatusRequested(
                        pharmacyId: _pharmacyId!,
                        branchId: branch.id,
                        status: val ? 'Active' : 'Inactive',
                      ),
                    );
              }
            },
            activeColor: AppColors.primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_mall_directory_outlined, size: 64.r, color: AppColors.textSecondary.withOpacity(0.3)),
          SizedBox(height: 16.h),
          Text(
            'لم يتم إضافة أي فروع لهذه الصيدلية بعد',
            style: GoogleFonts.cairo(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddBranchButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.6), width: 1)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56.h,
        child: ElevatedButton.icon(
          onPressed: () => _showAddBranchSheet(context),
          icon: Icon(Icons.add_rounded, color: Colors.white, size: 22.r),
          label: Text(
            'إضافة فرع جديد',
            style: GoogleFonts.cairo(fontSize: 15.sp, fontWeight: FontWeight.w900),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  void _showAddBranchSheet(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    bool isMain = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: StatefulBuilder(
          builder: (stCtx, setSt) => Container(
            padding: EdgeInsets.only(
              top: 24.h,
              left: 24.w,
              right: 24.w,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24.h,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32.r),
                topRight: Radius.circular(32.r),
              ),
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50.w,
                      height: 5.h,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'إضافة فرع جديد',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 18.sp),
                  ),
                  SizedBox(height: 20.h),
                  TextFormField(
                    controller: nameController,
                    style: GoogleFonts.cairo(fontSize: 14.sp),
                    decoration: InputDecoration(
                      labelText: 'اسم الفرع',
                      labelStyle: GoogleFonts.cairo(),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'اسم الفرع مطلوب' : null,
                  ),
                  SizedBox(height: 16.h),
                  TextFormField(
                    controller: addressController,
                    style: GoogleFonts.cairo(fontSize: 14.sp),
                    decoration: InputDecoration(
                      labelText: 'العنوان بالتفصيل',
                      labelStyle: GoogleFonts.cairo(),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'عنوان الفرع مطلوب' : null,
                  ),
                  SizedBox(height: 16.h),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.poppins(fontSize: 14.sp),
                    decoration: InputDecoration(
                      labelText: 'رقم تليفون الفرع',
                      labelStyle: GoogleFonts.cairo(),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'تليفون الفرع مطلوب' : null,
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'هل هذا الفرع الرئيسي؟',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.sp),
                      ),
                      Switch(
                        value: isMain,
                        onChanged: (val) {
                          setSt(() {
                            isMain = val;
                          });
                        },
                        activeColor: AppColors.primaryGreen,
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate() && _pharmacyId != null) {
                          Navigator.pop(ctx);
                          context.read<BranchesBloc>().add(
                                BranchesCreateRequested(
                                  pharmacyId: _pharmacyId!,
                                  name: nameController.text.trim(),
                                  address: addressController.text.trim(),
                                  phoneNumber: phoneController.text.trim(),
                                  isMainBranch: isMain,
                                ),
                              );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        elevation: 0,
                      ),
                      child: Text(
                        'إرسال وإضافة',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
