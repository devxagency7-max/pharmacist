import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pharmacist/core/constants/app_colors.dart';
import 'package:pharmacist/core/di/injection_container.dart';
import 'package:pharmacist/core/widgets/app_avatar.dart';
import '../bloc/patient_bloc.dart';
import '../bloc/patient_event.dart';
import '../bloc/patient_state.dart';
import '../../domain/entities/patient_entity.dart';
import 'patient_detail_screen.dart';

/// My Patients (GET /pharmacists/my-patients, Active only) + Pending
/// Requests (GET /pharmacists/pending-requests) — backend Module D. There is
/// no push notification for new requests, so this screen must be refreshed
/// manually / on focus (per PHARMACIST_APP_GUIDE.md Module D).
class PatientsScreen extends StatelessWidget {
  const PatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<PatientBloc>()..add(MyPatientsRequested()),
      child: const _PatientsView(),
    );
  }
}

class _PatientsView extends StatefulWidget {
  const _PatientsView();

  @override
  State<_PatientsView> createState() => _PatientsViewState();
}

class _PatientsViewState extends State<_PatientsView> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (_tabController.index == 1) {
        context.read<PatientBloc>().add(PendingRequestsRequested());
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          'المرضى',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900, color: AppColors.textPrimary),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryGreen,
          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w800),
          tabs: const [
            Tab(text: 'مرضاي'),
            Tab(text: 'طلبات معلقة'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _MyPatientsTab(),
          _PendingRequestsTab(),
        ],
      ),
    );
  }
}

class _MyPatientsTab extends StatelessWidget {
  const _MyPatientsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PatientBloc, PatientState>(
      buildWhen: (previous, current) =>
          current is MyPatientsLoading || current is MyPatientsLoaded || current is MyPatientsError,
      builder: (context, state) {
        if (state is MyPatientsLoading || state is PatientInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is MyPatientsError) {
          return _ErrorView(
            message: state.message,
            onRetry: () => context.read<PatientBloc>().add(MyPatientsRequested()),
          );
        }
        if (state is MyPatientsLoaded) {
          if (state.items.isEmpty) {
            return const _EmptyView(message: 'ليس لديك مرضى نشطون حاليًا.');
          }
          return RefreshIndicator(
            onRefresh: () async {
              context.read<PatientBloc>().add(MyPatientsRequested());
              await context.read<PatientBloc>().stream.firstWhere(
                    (s) => s is MyPatientsLoaded || s is MyPatientsError,
                  );
            },
            child: ListView.separated(
              padding: EdgeInsets.all(16.w),
              itemCount: state.items.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, index) => _PatientCard(patient: state.items[index]),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _PendingRequestsTab extends StatelessWidget {
  const _PendingRequestsTab();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PatientBloc, PatientState>(
      listenWhen: (previous, current) =>
          current is PatientRequestActionSuccess || current is PatientRequestActionError,
      listener: (context, state) {
        if (state is PatientRequestActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is PatientRequestActionError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      buildWhen: (previous, current) =>
          current is PendingRequestsLoading || current is PendingRequestsLoaded || current is PendingRequestsError,
      builder: (context, state) {
        if (state is PendingRequestsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is PendingRequestsError) {
          return _ErrorView(
            message: state.message,
            onRetry: () => context.read<PatientBloc>().add(PendingRequestsRequested()),
          );
        }
        if (state is PendingRequestsLoaded) {
          if (state.items.isEmpty) {
            return const _EmptyView(message: 'لا توجد طلبات معلقة.');
          }
          return RefreshIndicator(
            onRefresh: () async {
              context.read<PatientBloc>().add(PendingRequestsRequested());
              await context.read<PatientBloc>().stream.firstWhere(
                    (s) => s is PendingRequestsLoaded || s is PendingRequestsError,
                  );
            },
            child: ListView.separated(
              padding: EdgeInsets.all(16.w),
              itemCount: state.items.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, index) => _RequestCard(request: state.items[index]),
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _PatientCard extends StatelessWidget {
  final PatientSummaryEntity patient;

  const _PatientCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PatientDetailScreen(patientId: patient.patientId)),
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
            AppAvatar(
              avatarUrl: patient.avatarUrl,
              name: patient.name,
              radius: 24.r,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(patient.name, style: GoogleFonts.cairo(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  Text(patient.email, style: GoogleFonts.poppins(fontSize: 12.sp, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14.r, color: AppColors.textSecondary.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final AssignmentRequestEntity request;

  const _RequestCard({required this.request});

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
          Text(request.patientName, style: GoogleFonts.cairo(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          if (request.patientNote != null && request.patientNote!.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(request.patientNote!, style: GoogleFonts.cairo(fontSize: 13.sp, color: AppColors.textSecondary)),
          ],
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showRejectSheet(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error),
                  ),
                  child: Text('رفض', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.read<PatientBloc>().add(
                        PatientRequestRespondSubmitted(assignmentId: request.assignmentId, accept: true),
                      ),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
                  child: Text('قبول', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRejectSheet(BuildContext context) {
    final reasonController = TextEditingController();
    final blocContext = context;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 20.h,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('سبب الرفض', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 18.sp)),
            SizedBox(height: 12.h),
            TextField(
              controller: reasonController,
              maxLength: 500,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'اكتب سبب رفض الطلب...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final reason = reasonController.text.trim();
                  if (reason.isEmpty) {
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      const SnackBar(content: Text('سبب الرفض مطلوب.')),
                    );
                    return;
                  }
                  Navigator.pop(sheetContext);
                  blocContext.read<PatientBloc>().add(
                        PatientRequestRespondSubmitted(
                          assignmentId: request.assignmentId,
                          accept: false,
                          rejectionReason: reason,
                        ),
                      );
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                child: Text('تأكيد الرفض', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String message;
  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline_rounded, size: 64.r, color: AppColors.textSecondary),
            SizedBox(height: 16.h),
            Text(message, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
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
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
              child: Text('إعادة المحاولة', style: GoogleFonts.cairo(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
