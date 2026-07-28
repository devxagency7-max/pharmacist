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
import '../../../branches/domain/entities/branch_entity.dart';
import '../../../branches/domain/repositories/branches_repository.dart';
import '../../domain/entities/order_entity.dart';
import '../bloc/orders_bloc.dart';
import '../bloc/orders_event.dart';
import '../bloc/orders_state.dart';
import 'order_details_screen.dart';

class OrdersQueueScreen extends StatefulWidget {
  const OrdersQueueScreen({super.key});

  @override
  State<OrdersQueueScreen> createState() => _OrdersQueueScreenState();
}

class _OrdersQueueScreenState extends State<OrdersQueueScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedBranchId;
  List<BranchEntity> _branches = [];
  bool _isLoadingBranches = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadBranchesAndOrders();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_selectedBranchId != null && !_tabController.indexIsChanging) {
      _loadOrders();
    }
  }

  Future<void> _loadBranchesAndOrders() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final user = authState.user;
    setState(() {
      _isLoadingBranches = true;
      _selectedBranchId = user.branchId;
    });

    if (user.pharmacyId != null) {
      try {
        final branchesList = await getIt<BranchesRepository>().getBranches(pharmacyId: user.pharmacyId!);
        setState(() {
          _branches = branchesList;
          if (_selectedBranchId == null && branchesList.isNotEmpty) {
            _selectedBranchId = branchesList.first.id;
          }
        });
      } catch (_) {
        // Fallback to profile branchId
      }
    }

    setState(() {
      _isLoadingBranches = false;
    });

    _loadOrders();
  }

  void _loadOrders() {
    if (_selectedBranchId == null) return;
    final status = _tabController.index == 0 ? 'Pending' : 'Accepted';
    context.read<OrdersBloc>().add(
      OrdersLoadQueueRequested(branchId: _selectedBranchId!, status: status),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<OrdersBloc>(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        drawerScrimColor: Colors.transparent,
        endDrawer: const AppDrawer(),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'طابور الطلبات',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w900,
              fontSize: 22.sp,
              color: AppColors.textPrimary,
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primaryGreen,
            labelColor: AppColors.primaryGreen,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 14.sp),
            unselectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14.sp),
            tabs: const [
              Tab(text: 'طلبات جديدة'),
              Tab(text: 'قيد التجهيز'),
            ],
          ),
        ),
        body: Stack(
          children: [
            _buildBackgroundMesh(),
            Column(
              children: [
                _buildBranchSelector(),
                Expanded(
                  child: BlocConsumer<OrdersBloc, OrdersState>(
                    listener: (context, state) {
                      if (state is OrdersActionSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.message, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                            backgroundColor: AppColors.primaryGreen,
                          ),
                        );
                      } else if (state is OrdersError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.message, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
                    builder: (context, state) {
                      if (state is OrdersLoading) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
                      }

                      if (state is OrdersQueueLoaded) {
                        final items = state.orders.items;
                        if (items.isEmpty) {
                          return _buildEmptyState();
                        }
                        return RefreshIndicator(
                          onRefresh: () async => _loadOrders(),
                          color: AppColors.primaryGreen,
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final order = items[index];
                              return FadeInUp(
                                duration: const Duration(milliseconds: 400),
                                child: _buildOrderCard(order),
                              );
                            },
                          ),
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
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

  Widget _buildBranchSelector() {
    if (_isLoadingBranches) {
      return const SizedBox.shrink();
    }
    if (_branches.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedBranchId,
            isExpanded: true,
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primaryGreen, size: 24.r),
            items: _branches.map((b) {
              return DropdownMenuItem<String>(
                value: b.id,
                child: Text(
                  b.name,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14.sp),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedBranchId = val;
                });
                _loadOrders();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderEntity order) {
    final formattedTime = order.createdAt.contains('T')
        ? order.createdAt.split('T').first
        : order.createdAt;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => BlocProvider.value(
                value: context.read<OrdersBloc>(),
                child: OrderDetailsScreen(
                  order: order,
                  branchId: _selectedBranchId!,
                ),
              ),
            ),
          ).then((value) => _loadOrders());
        },
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'طلب #${order.id.substring(0, 6).toUpperCase()}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900,
                      fontSize: 14.sp,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: order.orderStatus == 'Pending'
                          ? Colors.orange.withOpacity(0.1)
                          : AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      order.orderStatus == 'Pending' ? 'جديد' : 'مقبول',
                      style: GoogleFonts.cairo(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w900,
                        color: order.orderStatus == 'Pending' ? Colors.orange : AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Icon(Icons.person_outline_rounded, color: AppColors.textSecondary, size: 16.r),
                  SizedBox(width: 6.w),
                  Text(
                    order.customerName,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Row(
                children: [
                  Icon(Icons.medical_services_outlined, color: AppColors.textSecondary, size: 16.r),
                  SizedBox(width: 6.w),
                  Text(
                    '${order.items.length} أصناف أدوية',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (order.prescription != null) ...[
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.description_outlined, color: Colors.blue, size: 12.r),
                          SizedBox(width: 4.w),
                          Text(
                            'روشتة مرفقة',
                            style: GoogleFonts.cairo(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 12.h),
              const Divider(color: Colors.white, thickness: 1),
              SizedBox(height: 6.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formattedTime,
                    style: GoogleFonts.poppins(
                      fontSize: 11.sp,
                      color: AppColors.textSecondary.withOpacity(0.6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'عرض التفاصيل',
                    style: GoogleFonts.cairo(
                      fontSize: 12.sp,
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeIn(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64.r, color: AppColors.textSecondary.withOpacity(0.3)),
            SizedBox(height: 16.h),
            Text(
              'لا توجد طلبات حالياً في هذا الفرع',
              style: GoogleFonts.cairo(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
