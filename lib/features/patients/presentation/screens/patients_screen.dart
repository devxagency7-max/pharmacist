import 'dart:ui';
import 'package:pharmacist/core/errors/error_message_mapper.dart';
import 'package:animate_do/animate_do.dart';
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
import 'package:pharmacist/features/chat/domain/repositories/chat_repository.dart';
import 'package:pharmacist/features/chat/data/services/chat_signalr_service.dart';
import 'package:pharmacist/features/chat/presentation/screens/chat_detail_screen.dart';

/// Gen Z Rebranded My Patients & Pending Requests Screen
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildAmbientMeshBackground(),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 12.h),
                _buildHeader(context),
                SizedBox(height: 16.h),
                _buildSearchBar(),
                SizedBox(height: 16.h),
                _buildGenZSegmentedTabBar(),
                SizedBox(height: 16.h),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _MyPatientsTab(searchQuery: _searchQuery),
                      const _PendingRequestsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbientMeshBackground() {
    return Stack(
      children: [
        Positioned(
          top: -60.h,
          right: -60.w,
          child: Container(
            width: 240.r,
            height: 240.r,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: 180.h,
          left: -80.w,
          child: Container(
            width: 220.r,
            height: 220.r,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
          ),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(color: Colors.transparent),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.white, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A1D26).withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18.r,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            'سجل المرضى',
            style: GoogleFonts.cairo(
              fontSize: 22.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          // const Spacer(),
          // Container(
          //   padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          //   decoration: BoxDecoration(
          //     color: AppColors.primaryGreen.withValues(alpha: 0.12),
          //     borderRadius: BorderRadius.circular(12.r),
          //     border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3), width: 1),
          //   ),
          //   child: Row(
          //     children: [
          //       // Container(
          //       //   width: 7.r,
          //       //   height: 7.r,
          //       //   decoration: const BoxDecoration(
          //       //     shape: BoxShape.circle,
          //       //     color: AppColors.primaryGreen,
          //       //   ),
          //       // ),
          //       // SizedBox(width: 6.w),
          //       // Text(
          //       //   'نشط الآن ⚡',
          //       //   style: GoogleFonts.cairo(
          //       //     fontSize: 11.5.sp,
          //       //     fontWeight: FontWeight.w800,
          //       //     color: AppColors.primaryGreen,
          //       //   ),
          //       // ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.white, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A1D26).withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: GoogleFonts.cairo(
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'ابحث باسم المريض أو البريد الإلكتروني...',
            hintStyle: GoogleFonts.cairo(
              fontSize: 12.5.sp,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppColors.primary,
              size: 22.r,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded, size: 18.r, color: AppColors.textSecondary),
                    onPressed: () => _searchController.clear(),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          ),
        ),
      ),
    );
  }

  Widget _buildGenZSegmentedTabBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        height: 48.h,
        padding: EdgeInsets.all(4.r),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.white, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A1D26).withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: GoogleFonts.cairo(fontSize: 13.sp, fontWeight: FontWeight.w800),
          unselectedLabelStyle: GoogleFonts.cairo(fontSize: 13.sp, fontWeight: FontWeight.w700),
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'مرضاي النشطين '),
            Tab(text: 'الطلبات المعلقة '),
          ],
        ),
      ),
    );
  }
}

class _MyPatientsTab extends StatelessWidget {
  final String searchQuery;
  const _MyPatientsTab({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PatientBloc, PatientState>(
      buildWhen: (previous, current) =>
          current is MyPatientsLoading || current is MyPatientsLoaded || current is MyPatientsError,
      builder: (context, state) {
        if (state is MyPatientsLoading || state is PatientInitial) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen, strokeWidth: 3),
          );
        }
        if (state is MyPatientsError) {
          return _ErrorView(
            message: state.message,
            onRetry: () => context.read<PatientBloc>().add(MyPatientsRequested()),
          );
        }
        if (state is MyPatientsLoaded) {
          var items = state.items;
          if (searchQuery.isNotEmpty) {
            items = items.where((p) {
              return p.name.toLowerCase().contains(searchQuery) ||
                  p.email.toLowerCase().contains(searchQuery);
            }).toList();
          }

          if (items.isEmpty) {
            return _EmptyView(
              message: searchQuery.isNotEmpty
                  ? 'لا توجد نتائج تطابق بحثك'
                  : 'ليس لديك مرضى نشطون حاليًا 🩺',
            );
          }

          return RefreshIndicator(
            color: AppColors.primaryGreen,
            onRefresh: () async {
              context.read<PatientBloc>().add(MyPatientsRequested());
              await context.read<PatientBloc>().stream.firstWhere(
                    (s) => s is MyPatientsLoaded || s is MyPatientsError,
                  );
            },
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              itemCount: items.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                return FadeInUp(
                  delay: Duration(milliseconds: 60 * index),
                  duration: const Duration(milliseconds: 350),
                  child: _PatientCard(patient: items[index]),
                );
              },
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              backgroundColor: AppColors.primaryGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
            ),
          );
        } else if (state is PatientRequestActionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
            ),
          );
        }
      },
      buildWhen: (previous, current) =>
          current is PendingRequestsLoading || current is PendingRequestsLoaded || current is PendingRequestsError,
      builder: (context, state) {
        if (state is PendingRequestsLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen, strokeWidth: 3),
          );
        }
        if (state is PendingRequestsError) {
          return _ErrorView(
            message: state.message,
            onRetry: () => context.read<PatientBloc>().add(PendingRequestsRequested()),
          );
        }
        if (state is PendingRequestsLoaded) {
          if (state.items.isEmpty) {
            return const _EmptyView(message: 'لا توجد طلبات انضمام معلقة حالياً ✨');
          }
          return RefreshIndicator(
            color: AppColors.primaryGreen,
            onRefresh: () async {
              context.read<PatientBloc>().add(PendingRequestsRequested());
              await context.read<PatientBloc>().stream.firstWhere(
                    (s) => s is PendingRequestsLoaded || s is PendingRequestsError,
                  );
            },
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              itemCount: state.items.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                return FadeInUp(
                  delay: Duration(milliseconds: 60 * index),
                  duration: const Duration(milliseconds: 350),
                  child: _RequestCard(request: state.items[index]),
                );
              },
            ),
          );
        }
        return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
      },
    );
  }
}

class _PatientCard extends StatelessWidget {
  final PatientSummaryEntity patient;

  const _PatientCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PatientDetailScreen(patientId: patient.patientId)),
      ),
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.white, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A1D26).withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryGreen, width: 1.6),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: AppAvatar(
                    avatarUrl: patient.avatarUrl,
                    name: patient.name,
                    radius: 24.r,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Container(
                    width: 11.r,
                    height: 11.r,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          patient.name,
                          style: GoogleFonts.cairo(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                     
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    patient.email,
                    style: GoogleFonts.poppins(
                      fontSize: 11.sp,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            // Quick direct chat button
            GestureDetector(
              onTap: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryGreen),
                  ),
                );
                try {
                  final conv = await getIt<ChatRepository>()
                      .startConversation(otherParticipantId: patient.patientId);
                  await getIt<ChatSignalRService>().joinConversation(conv.id);
                  navigator.pop();
                  navigator.push(
                    MaterialPageRoute(
                      builder: (context) => ChatDetailScreen(
                        conversationId: conv.id,
                        otherParticipantName: patient.name,
                        patientId: patient.patientId,
                        conversationStatus: conv.status,
                      ),
                    ),
                  );
                } catch (e) {
                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(content: Text(mapErrorToMessage(e))),
                  );
                }
              },
              child: Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.primaryGreen,
                  size: 17.r,
                ),
              ),
            ),
            SizedBox(width: 6.w),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13.r,
              color: AppColors.textSecondary.withValues(alpha: 0.4),
            ),
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
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(7.r),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_add_alt_1_rounded,
                      color: AppColors.primaryGreen,
                      size: 18.r,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    request.patientName,
                    style: GoogleFonts.cairo(
                      fontSize: 14.5.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF39C12).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'طلب جديد 🔥',
                  style: GoogleFonts.cairo(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFF39C12),
                  ),
                ),
              ),
            ],
          ),
          if (request.patientNote != null && request.patientNote!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                '💬 "${request.patientNote!}"',
                style: GoogleFonts.cairo(
                  fontSize: 11.5.sp,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ],
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showRejectSheet(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error, width: 1.2),
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: Text('رفض', style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 12.5.sp)),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen.withValues(alpha: 0.22),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => context.read<PatientBloc>().add(
                          PatientRequestRespondSubmitted(assignmentId: request.assignmentId, accept: true),
                        ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: Text('قبول الطلب 🎉', style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 12.5.sp)),
                  ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28.r))),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 24.h,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'سبب رفض الطلب',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 18.sp, color: AppColors.textPrimary),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: reasonController,
              maxLength: 500,
              maxLines: 3,
              style: GoogleFonts.cairo(fontSize: 13.sp, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'اكتب سبب رفض طلب الانضمام هنا...',
                hintStyle: GoogleFonts.cairo(fontSize: 12.sp, color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final reason = reasonController.text.trim();
                  if (reason.isEmpty) {
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      SnackBar(
                        content: Text('سبب الرفض مطلوب.', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                        backgroundColor: AppColors.error,
                      ),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                ),
                child: Text('تأكيد الرفض', style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 14.sp)),
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
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.people_outline_rounded, size: 48.r, color: AppColors.primary),
            ),
            SizedBox(height: 16.h),
            Text(
              message,
              style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 14.5.sp, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
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
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded, size: 48.r, color: AppColors.error),
            ),
            SizedBox(height: 16.h),
            Text(
              message,
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 13.5.sp, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
              child: Text('إعادة المحاولة', style: GoogleFonts.cairo(fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

