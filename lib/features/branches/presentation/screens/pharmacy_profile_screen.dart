import 'dart:io';
import 'package:pharmacist/core/errors/error_message_mapper.dart';
import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pharmacist/core/constants/app_colors.dart';
import 'package:pharmacist/core/di/injection_container.dart';
import 'package:pharmacist/core/network/file_upload_service.dart';
import '../bloc/branches_bloc.dart';
import '../bloc/branches_event.dart';
import '../bloc/branches_state.dart';

class PharmacyProfileScreen extends StatefulWidget {
  const PharmacyProfileScreen({super.key});

  @override
  State<PharmacyProfileScreen> createState() => _PharmacyProfileScreenState();
}

class _PharmacyProfileScreenState extends State<PharmacyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _hoursController = TextEditingController();
  String? _selectedGovernorate;
  bool _isOpen = true;
  String? _logoUrl;
  String? _logoUploadedFileId;
  bool _isUploadingLogo = false;

  List<String> _governorates = [
    'القاهرة',
    'الجيزة',
    'الإسكندرية',
    'القليوبية',
    'الدقهلية',
    'الشرقية',
    'المنوفية',
    'الغربية',
    'البحيرة',
    'الفيوم',
    'أسيوط',
    'سوهاج',
    'المنيا',
    'قنا',
    'بني سويف',
    'أسوان',
    'دمياط',
    'الإسماعيلية',
    'بورسعيد',
    'السويس',
    'الأقصر',
    'البحر الأحمر',
    'الوادى الجديد',
    'مطروح',
    'شمال سيناء',
    'جنوب سيناء',
  ];

  @override
  void initState() {
    super.initState();
    // Load governorates from API
    context.read<BranchesBloc>().add(BranchesLoadGovernorates());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadLogo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _isUploadingLogo = true;
      });
      try {
        final uploaded = await getIt<FileUploadService>().uploadFile(
          filePath: image.path,
          fileType: 'Other',
        );
        setState(() {
          _logoUrl = uploaded.previewUrl.isNotEmpty ? uploaded.previewUrl : uploaded.url;
          _logoUploadedFileId = uploaded.id;
          _isUploadingLogo = false;
        });
      } catch (e) {
        setState(() {
          _isUploadingLogo = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل رفع الشعار: ${mapErrorToMessage(e)}',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<BranchesBloc>(),
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
            'الملف التعريفي للصيدلية',
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
            BlocConsumer<BranchesBloc, BranchesState>(
              listener: (context, state) {
                if (state is PharmacyProfileUpdated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم تحديث الملف التعريفي بنجاح', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                      backgroundColor: AppColors.primaryGreen,
                    ),
                  );
                  Navigator.pop(context);
                } else if (state is BranchesGovernoratesLoaded) {
                  setState(() {
                    _governorates = state.governorates;
                  });
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
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20.h),
                        Center(
                          child: GestureDetector(
                            onTap: _isUploadingLogo ? null : _pickAndUploadLogo,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 110.r,
                                  height: 110.r,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.5),
                                    border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2), width: 2),
                                  ),
                                  child: ClipOval(
                                    child: _logoUrl != null
                                        ? Image.network(
                                            _logoUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                Icon(Icons.store_rounded, size: 48.r, color: AppColors.primaryGreen),
                                          )
                                        : Icon(Icons.store_rounded, size: 48.r, color: AppColors.primaryGreen),
                                  ),
                                ),
                                if (_isUploadingLogo)
                                  const CircularProgressIndicator(color: AppColors.primaryGreen)
                                else
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: EdgeInsets.all(6.r),
                                      decoration: const BoxDecoration(
                                        color: AppColors.primaryGreen,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16.r),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 32.h),

                        // Pharmacy Name
                        _buildInputField(
                          controller: _nameController,
                          label: 'اسم الصيدلية',
                          hint: 'مثال: صيدلية طمني الرئيسية',
                          icon: Icons.store_outlined,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'اسم الصيدلية مطلوب';
                            return null;
                          },
                        ),
                        SizedBox(height: 20.h),

                        // Governorate dropdown
                        _buildDropdownField('المحافظة', _governorates),
                        SizedBox(height: 20.h),

                        // Address
                        _buildInputField(
                          controller: _addressController,
                          label: 'العنوان بالتفصيل',
                          hint: 'مثال: شارع التسعين، التجمع الخامس',
                          icon: Icons.location_on_outlined,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'العنوان مطلوب';
                            return null;
                          },
                        ),
                        SizedBox(height: 20.h),

                        // Working hours
                        _buildInputField(
                          controller: _hoursController,
                          label: 'مواعيد العمل (وصف)',
                          hint: 'مثال: يومياً من ٩ ص إلى ١١ م، الجمعة إجازة',
                          icon: Icons.access_time_rounded,
                        ),
                        SizedBox(height: 24.h),

                        // Open Status Switch
                        _buildOpenStatusSwitch(),
                        SizedBox(height: 40.h),

                        // Save Profile Button
                        SizedBox(
                          width: double.infinity,
                          height: 56.h,
                          child: ElevatedButton(
                            onPressed: state is BranchesLoading
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate() && _selectedGovernorate != null) {
                                      context.read<BranchesBloc>().add(
                                        PharmacyUpdateProfileRequested(
                                          name: _nameController.text.trim(),
                                          logoUploadedFileId: _logoUploadedFileId,
                                          governorate: _selectedGovernorate!,
                                          address: _addressController.text.trim(),
                                          workingHoursDescription: _hoursController.text.trim().isEmpty
                                              ? null
                                              : _hoursController.text.trim(),
                                          isOpen: _isOpen,
                                        ),
                                      );
                                    } else if (_selectedGovernorate == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('يرجى اختيار المحافظة',
                                              style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                              elevation: 0,
                            ),
                            child: state is BranchesLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    'حفظ التعديلات',
                                    style: GoogleFonts.cairo(fontSize: 16.sp, fontWeight: FontWeight.w900),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: TextFormField(
                controller: controller,
                validator: validator,
                style: GoogleFonts.cairo(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: GoogleFonts.cairo(
                    color: AppColors.textSecondary.withOpacity(0.5),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  prefixIcon: Icon(icon, color: AppColors.textSecondary.withOpacity(0.8)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedGovernorate,
              isExpanded: true,
              hint: Text(
                'اختر المحافظة',
                style: GoogleFonts.cairo(
                  color: AppColors.textSecondary.withOpacity(0.5),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primaryGreen, size: 24.r),
              items: items.map((gov) {
                return DropdownMenuItem<String>(
                  value: gov,
                  child: Text(
                    gov,
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14.sp),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedGovernorate = val;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOpenStatusSwitch() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.power_settings_new_rounded,
                  color: _isOpen ? AppColors.primaryGreen : AppColors.error, size: 24.r),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'حالة الصيدلية الآن',
                    style: GoogleFonts.cairo(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _isOpen ? 'مفتوحة وتستقبل طلبات' : 'مغلقة مؤقتاً',
                    style: GoogleFonts.cairo(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: _isOpen,
            onChanged: (val) {
              setState(() {
                _isOpen = val;
              });
            },
            activeColor: AppColors.primaryGreen,
          ),
        ],
      ),
    );
  }
}
