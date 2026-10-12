import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmacist/core/constants/app_colors.dart';
import 'package:pharmacist/core/di/injection_container.dart';
import 'package:pharmacist/core/errors/api_exception.dart';
import 'package:pharmacist/core/errors/error_message_mapper.dart';
import 'package:pharmacist/features/auth/domain/entities/pharmacist_application_entity.dart';
import 'package:pharmacist/features/auth/domain/repositories/auth_repository.dart';
import 'package:pharmacist/features/home/presentation/screens/main_screen.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import 'signup_screen.dart';

class ApplicationStatusScreen extends StatefulWidget {
  final PharmacistApplicationEntity initialApplication;

  const ApplicationStatusScreen({super.key, required this.initialApplication});

  @override
  State<ApplicationStatusScreen> createState() => _ApplicationStatusScreenState();
}

class _ApplicationStatusScreenState extends State<ApplicationStatusScreen>
    with WidgetsBindingObserver {
  bool _isWithdrawing = false;
  bool _isCheckingAccess = false;
  // Set when the application is Approved but the backend account still has
  // no professional role, so the user can't be let into the app yet.
  bool _accountNotActivatedYet = false;
  late PharmacistApplicationEntity _application = widget.initialApplication;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Admin approval is fast — if it happens while the user has this screen
    // backgrounded, refresh on resume so they're not stuck looking at a
    // stale "Pending" status.
    if (state == AppLifecycleState.resumed) {
      _refreshStatus();
    }
  }

  Future<void> _refreshStatus() async {
    try {
      final fresh = await getIt<AuthRepository>().getApplicationStatus();
      if (!mounted || fresh == null) return;
      setState(() => _application = fresh);
    } catch (_) {
      // Silent — this is a background refresh, not a user-initiated action.
    }
  }

  /// Re-reads the account (force-refreshed token + profile) and enters the
  /// app if the approval has been applied; otherwise explains why not.
  Future<void> _checkApprovalAndEnter() async {
    setState(() {
      _isCheckingAccess = true;
      _accountNotActivatedYet = false;
    });
    try {
      final user = await getIt<AuthRepository>().getCurrentUser();
      if (!mounted) return;

      if (user != null && user.hasProfessionalRole) {
        context.read<AuthBloc>().add(AuthRefreshRequested());
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
        return;
      }

      setState(() {
        _isCheckingAccess = false;
        _accountNotActivatedYet = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCheckingAccess = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mapErrorToMessage(e),
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _confirmAndWithdraw() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'إلغاء الطلب',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'هل أنت متأكد إنك عايز تلغي طلب التقديم ده؟ هيتم حذفه نهائيًا وتقدر تقدّم بطلب جديد بعد كده.',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('تراجع', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'نعم، إلغاء الطلب',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w900, color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isWithdrawing = true);
    try {
      final authRepository = getIt<AuthRepository>();

      // The status shown on screen may be stale (e.g. an admin approved it
      // after this screen loaded) — re-check right before withdrawing.
      final fresh = await authRepository.getApplicationStatus();
      if (fresh == null || fresh.status.toLowerCase() != 'pending') {
        if (!mounted) return;
        setState(() {
          _isWithdrawing = false;
          if (fresh != null) _application = fresh;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              fresh == null
                  ? 'الطلب لم يعد موجودًا.'
                  : 'تم تحديث حالة الطلب إلى "${fresh.status}" بواسطة الإدارة، لا يمكن إلغاؤه الآن.',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      await authRepository.withdrawApplication(fresh.id);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignUpScreen()),
      );
    } catch (e) {
      if (!mounted) return;

      // Backend may still reject with APPLICATION_NOT_PENDING even after our
      // fresh check above, if it was approved/rejected in that tiny window.
      // ApiClient wraps the backend error inside DioException.error.
      final apiError = e is DioException ? e.error : e;
      if (apiError is ApiException && apiError.errorCode == 'APPLICATION_NOT_PENDING') {
        final currentStatus = apiError.extra?['currentStatus'] as String?;
        setState(() => _isWithdrawing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentStatus != null
                  ? 'تم تحديث حالة الطلب إلى "$currentStatus" بواسطة الإدارة، لا يمكن إلغاؤه الآن.'
                  : 'حالة الطلب تغيّرت، لا يمكن إلغاؤه الآن.',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      setState(() => _isWithdrawing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mapErrorToMessage(e),
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRejected = _application.status.toLowerCase() == 'rejected';
    final isApproved = _application.status.toLowerCase() == 'approved';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildBackgroundMesh(),
          SafeArea(
            child: isApproved
                ? _buildStatusView(
                    context: context,
                    icon: Icons.check_circle_rounded,
                    iconColor: AppColors.primaryGreen,
                    title: 'تم قبول طلب التقديم',
                    subtitle: 'حالة الطلب حالياً: مقبول (Approved)',
                    facultyName: _application.facultyName,
                    rejectionReason: null,
                    showRetryButton: false,
                    showWithdrawButton: false,
                    extraContent: _buildApprovedActions(),
                  )
                : isRejected
                ? _buildStatusView(
                    context: context,
                    icon: Icons.cancel_rounded,
                    iconColor: AppColors.error,
                    title: 'تم رفض طلب التقديم',
                    subtitle: 'حالة الطلب حالياً: مرفوض (Rejected)',
                    rejectionReason: _application.rejectionReason,
                    showRetryButton: true,
                  )
                : _buildStatusView(
                    context: context,
                    icon: Icons.pending_actions_rounded,
                    iconColor: Colors.orange,
                    title: 'طلب التقديم قيد المراجعة',
                    subtitle: 'حالة الطلب حالياً: قيد الانتظار (Pending)',
                    facultyName: _application.facultyName,
                    rejectionReason: null,
                    showRetryButton: false,
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

  Widget _buildApprovedActions() {
    return Column(
      children: [
        if (_accountNotActivatedYet) ...[
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.orange.withOpacity(0.4), width: 1.5),
            ),
            child: Text(
              'الإدارة وافقت على طلبك، لكن حسابك لسه ما اتفعّلش على النظام. '
              'جرّب تاني بعد دقيقة، ولو الرسالة دي فضلت تظهر تواصل مع الدعم '
              'وقولهم إن طلبك اتقبل.',
              style: GoogleFonts.cairo(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ),
          SizedBox(height: 16.h),
        ],
        SizedBox(
          width: double.infinity,
          height: 56.h,
          child: ElevatedButton(
            onPressed: _isCheckingAccess ? null : _checkApprovalAndEnter,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              elevation: 0,
            ),
            child: _isCheckingAccess
                ? SizedBox(
                    width: 22.r,
                    height: 22.r,
                    child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    'تحديث الحالة والدخول',
                    style: GoogleFonts.cairo(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusView({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? facultyName,
    required String? rejectionReason,
    required bool showRetryButton,
    bool showWithdrawButton = true,
    Widget? extraContent,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 20.h),
          FadeInDown(
            child: Icon(icon, size: 72.r, color: iconColor),
          ),
          SizedBox(height: 16.h),
          FadeInDown(
            delay: const Duration(milliseconds: 200),
            child: Text(
              title,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w900,
                fontSize: 20.sp,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          FadeInDown(
            delay: const Duration(milliseconds: 300),
            child: Text(
              subtitle,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 13.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (facultyName != null && facultyName.trim().isNotEmpty) ...[
            SizedBox(height: 4.h),
            FadeInDown(
              delay: const Duration(milliseconds: 320),
              child: Text(
                facultyName,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w600,
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
          SizedBox(height: 24.h),
          if (rejectionReason != null && rejectionReason.trim().isNotEmpty)
            FadeInUp(
              delay: const Duration(milliseconds: 350),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.error.withOpacity(0.3), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppColors.error, size: 20.r),
                        SizedBox(width: 8.w),
                        Text(
                          'سبب الرفض',
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w900,
                            fontSize: 13.sp,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      rejectionReason,
                      style: GoogleFonts.cairo(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (showRetryButton) ...[
            SizedBox(height: 32.h),
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const SignUpScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'تسجيل مرة أخرى',
                    style: GoogleFonts.cairo(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (extraContent != null) FadeInUp(child: extraContent),
          if (showWithdrawButton) ...[
          SizedBox(height: 16.h),
          FadeInUp(
            delay: const Duration(milliseconds: 450),
            child: SizedBox(
              width: double.infinity,
              height: 56.h,
              child: OutlinedButton(
                onPressed: _isWithdrawing ? null : _confirmAndWithdraw,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: _isWithdrawing
                    ? SizedBox(
                        width: 22.r,
                        height: 22.r,
                        child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.error),
                      )
                    : Text(
                        'إلغاء الطلب',
                        style: GoogleFonts.cairo(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.error,
                        ),
                      ),
              ),
            ),
          ),
          ],
        ],
      ),
    );
  }
}
