import 'dart:io';
import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pharmacist/core/constants/app_colors.dart';
import 'package:pharmacist/core/di/injection_container.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pharmacist/core/network/file_upload_service.dart';
import 'package:pharmacist/features/auth/domain/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'application_status_screen.dart';
import 'login_screen.dart';

const int _maxDocumentSizeBytes = 5 * 1024 * 1024;

const Map<String, String> _documentTypeToFileType = {
  'NationalIdFront': 'Identification',
  'NationalIdBack': 'Identification',
  'PharmacyLicense': 'License',
  'UniversityCertificate': 'Other',
  'InternshipCard': 'Other',
};

const Map<String, String> _docNames = {
  'NationalIdFront': 'وجه البطاقة الشخصية',
  'NationalIdBack': 'ظهر البطاقة الشخصية',
  'PharmacyLicense': 'رخصة مزاولة المهنة / الصيدلية',
  'UniversityCertificate': 'شهادة التخرج',
  'InternshipCard': 'كارنيه التدريب أو النقابة',
};

class SignUpScreen extends StatefulWidget {
  final String? initialName;
  final String? initialEmail;
  final String? initialPhone;

  const SignUpScreen({
    super.key,
    this.initialName,
    this.initialEmail,
    this.initialPhone,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Step 0 controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Step 1 controllers & values
  bool isPharmacist = true;
  final _licenseController = TextEditingController();
  final _membershipController = TextEditingController();
  final _universityController = TextEditingController();

  // Step 2 values (Selected file paths)
  final Map<String, String?> _selectedFiles = {
    'NationalIdFront': null,
    'NationalIdBack': null,
    'PharmacyLicense': null,
    'UniversityCertificate': null,
    'InternshipCard': null,
  };

  int _currentStep = 0;
  bool _isLoading = false;
  String _loadingMessage = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialName != null && widget.initialName!.isNotEmpty) {
      _nameController.text = widget.initialName!;
    }
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }
    if (widget.initialPhone != null && widget.initialPhone!.isNotEmpty) {
      _phoneController.text = widget.initialPhone!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _licenseController.dispose();
    _membershipController.dispose();
    _universityController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        backgroundColor: isError ? AppColors.error : AppColors.primaryGreen,
      ),
    );
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty) {
        _showSnackBar('يرجى إدخال الاسم بالكامل');
        return false;
      }
      if (_phoneController.text.trim().isEmpty) {
        _showSnackBar('يرجى إدخال رقم الهاتف');
        return false;
      }
      if (_emailController.text.trim().isEmpty) {
        _showSnackBar('يرجى إدخال البريد الإلكتروني');
        return false;
      }
      if (FirebaseAuth.instance.currentUser == null && _passwordController.text.length < 6) {
        _showSnackBar('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
        return false;
      }
    } else if (_currentStep == 2) {
      final missingDocs = _selectedFiles.entries
          .where((e) => e.value == null)
          .map((e) => _docNames[e.key] ?? e.key)
          .toList();
      if (missingDocs.isNotEmpty) {
        _showSnackBar('يرجى رفع المستندات الإلزامية التالية أولاً:\n• ${missingDocs.join("\n• ")}');
        return false;
      }
    }
    return true;
  }

  Future<void> _pickDocument(String docType) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (image == null) return;

    final size = await File(image.path).length();
    if (size > _maxDocumentSizeBytes) {
      _showSnackBar('حجم الصورة أكبر من 5 ميجابايت، من فضلك اختر صورة أصغر');
      return;
    }

    setState(() {
      _selectedFiles[docType] = image.path;
    });
  }

  void _removeDocument(String docType) {
    setState(() {
      _selectedFiles[docType] = null;
    });
  }

  Future<void> _registerUser() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'جاري تهيئة طلبك...';
    });

    try {
      final authRepo = getIt<AuthRepository>();
      final fileUploadService = getIt<FileUploadService>();

      // 1. Firebase SignUp / Update Profile Sync
      if (FirebaseAuth.instance.currentUser == null) {
        setState(() {
          _loadingMessage = 'جاري إنشاء حسابك الإلكتروني...';
        });
        try {
          await authRepo.signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
            displayName: _nameController.text.trim().split(' ').first,
            phoneNumber: _phoneController.text.trim(),
          );
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            await authRepo.login(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              name: _nameController.text.trim(),
              displayName: _nameController.text.trim().split(' ').first,
              phoneNumber: _phoneController.text.trim(),
            );
          } else {
            rethrow;
          }
        }
      } else {
        setState(() {
          _loadingMessage = 'جاري مزامنة بيانات حسابك...';
        });
        await authRepo.updateProfile(
          name: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
        );
      }

      // 2. Submit professional application
      setState(() {
        _loadingMessage = 'جاري تقديم طلب الانضمام المهني...';
      });
      final app = await authRepo.applyPharmacist(
        applicationType: isPharmacist ? 'Pharmacist' : 'Intern',
        licenseNumber: _licenseController.text.trim().isEmpty ? null : _licenseController.text.trim(),
        membershipNumber: _membershipController.text.trim().isEmpty ? null : _membershipController.text.trim(),
        universityName: _universityController.text.trim().isEmpty ? null : _universityController.text.trim(),
      );

      // 3. Upload & link files
      final selectedDocs = _selectedFiles.entries.where((e) => e.value != null).toList();
      for (int i = 0; i < selectedDocs.length; i++) {
        final docType = selectedDocs[i].key;
        final filePath = selectedDocs[i].value!;
        final docName = _docNames[docType] ?? docType;

        setState(() {
          _loadingMessage = 'جاري رفع المستند (${i + 1}/${selectedDocs.length}):\n$docName...';
        });

        final fileType = _documentTypeToFileType[docType] ?? 'Other';
        final uploaded = await fileUploadService.uploadFile(
          filePath: filePath,
          fileType: fileType,
        );

        final fileName = filePath.split(RegExp(r'[\\/]')).last;
        final size = await File(filePath).length();

        await authRepo.uploadDocument(
          applicationId: app.id,
          documentType: docType,
          uploadedFileId: uploaded.id,
          originalFileName: fileName,
          fileSizeBytes: size,
        );
      }

      setState(() {
        _loadingMessage = 'تم التسجيل ورفع المستندات بنجاح! 🚀';
      });

      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        // Refresh Auth State so Bloc gets updated user entity
        context.read<AuthBloc>().add(AuthRefreshRequested());

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => ApplicationStatusScreen(initialApplication: app),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('حدث خطأ أثناء التسجيل: $e');
      }
    }
  }

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
                _buildHeader(),
                _buildStepperIndicator(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
                    child: Form(
                      key: _formKey,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildCurrentStepContent(),
                      ),
                    ),
                  ),
                ),
                _buildBottomNavigationButtons(),
              ],
            ),
          ),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep0AccountInfo();
      case 1:
        return _buildStep1ProfessionalInfo();
      case 2:
        return _buildStep2Documents();
      default:
        return const SizedBox.shrink();
    }
  }

  // --- STEP 0: Account Details ---
  Widget _buildStep0AccountInfo() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isGoogleUser = currentUser != null;

    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInDown(
          duration: const Duration(milliseconds: 500),
          child: Text(
            'بيانات الحساب',
            style: GoogleFonts.cairo(
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(height: 6.h),
        FadeInDown(
          delay: const Duration(milliseconds: 100),
          child: Text(
            isGoogleUser
                ? 'تم ربط حسابك بـ Google، يرجى إكمال رقم الهاتف والبيانات المهنية'
                : 'أدخل بياناتك الشخصية الأساسية لإنشاء الحساب',
            style: GoogleFonts.cairo(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        if (isGoogleUser)
          FadeInDown(
            delay: const Duration(milliseconds: 150),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              margin: EdgeInsets.only(bottom: 16.h),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/google.png',
                    width: 22.w,
                    height: 22.h,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primaryGreen,
                      size: 22.r,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'مسجل بحساب: ${currentUser.email ?? ""}',
                      style: GoogleFonts.cairo(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (!isGoogleUser) ...[
          FadeInRight(
            delay: const Duration(milliseconds: 150),
            child: _buildGoogleSignUpButton(),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(child: Divider(color: AppColors.textSecondary.withOpacity(0.3))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Text('أو ادخل بياناتك يدوياً', style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 12.sp, fontWeight: FontWeight.bold)),
              ),
              Expanded(child: Divider(color: AppColors.textSecondary.withOpacity(0.3))),
            ],
          ),
          SizedBox(height: 16.h),
        ],
        FadeInRight(
          delay: const Duration(milliseconds: 150),
          child: _buildGlassTextField(
            controller: _nameController,
            label: 'الاسم بالكامل',
            hint: 'مثال: د. أحمد محمود',
            icon: Icons.person_outline_rounded,
          ),
        ),
        SizedBox(height: 16.h),
        FadeInRight(
          delay: const Duration(milliseconds: 200),
          child: _buildGlassTextField(
            controller: _phoneController,
            label: 'رقم الهاتف',
            hint: '01xxxxxxxxx',
            icon: Icons.phone_android_rounded,
            isNumeric: true,
          ),
        ),
        SizedBox(height: 16.h),
        FadeInRight(
          delay: const Duration(milliseconds: 250),
          child: _buildGlassTextField(
            controller: _emailController,
            label: 'البريد الإلكتروني',
            hint: 'example@mail.com',
            icon: Icons.email_outlined,
          ),
        ),
        if (!isGoogleUser) ...[
          SizedBox(height: 16.h),
          FadeInRight(
            delay: const Duration(milliseconds: 300),
            child: _buildGlassTextField(
              controller: _passwordController,
              label: 'كلمة المرور',
              hint: '********',
              icon: Icons.lock_outline_rounded,
              isPassword: true,
            ),
          ),
        ],
        SizedBox(height: 24.h),
        FadeInUp(
          delay: const Duration(milliseconds: 350),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'لديك حساب بالفعل؟ ',
                style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                child: Text(
                  'تسجيل الدخول',
                  style: GoogleFonts.cairo(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w900,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildGoogleSignUpButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return GestureDetector(
          onTap: isLoading
              ? null
              : () {
                  context.read<AuthBloc>().add(GoogleSignInSubmitted());
                },
          child: Container(
            width: double.infinity,
            height: 52.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.grey.shade300, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/google.png',
                  width: 22.w,
                  height: 22.h,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.g_mobiledata_rounded,
                    color: Colors.red.shade600,
                    size: 28.r,
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  isLoading ? 'جاري التسجيل بـ Google...' : 'التسجيل السريع باستخدام Google',
                  style: GoogleFonts.cairo(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- STEP 1: Professional Details ---
  Widget _buildStep1ProfessionalInfo() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInDown(
          duration: const Duration(milliseconds: 500),
          child: Text(
            'البيانات المهنية',
            style: GoogleFonts.cairo(
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(height: 6.h),
        FadeInDown(
          delay: const Duration(milliseconds: 100),
          child: Text(
            'حدد هويتك المهنية لتوثيق الحساب صيدلي معتمد',
            style: GoogleFonts.cairo(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: 24.h),
        FadeInUp(
          delay: const Duration(milliseconds: 150),
          child: _buildRoleSelector(),
        ),
        SizedBox(height: 24.h),
        FadeInUp(
          delay: const Duration(milliseconds: 200),
          child: _buildGlassTextField(
            controller: _licenseController,
            label: 'رقم ترخيص مزاولة المهنة (اختياري)',
            hint: 'مثال: PH-2024-88231',
            icon: Icons.badge_outlined,
          ),
        ),
        SizedBox(height: 16.h),
        FadeInUp(
          delay: const Duration(milliseconds: 250),
          child: _buildGlassTextField(
            controller: _membershipController,
            label: 'رقم عضوية النقابة (اختياري)',
            hint: 'مثال: SYN-55214',
            icon: Icons.card_membership_outlined,
          ),
        ),
        SizedBox(height: 16.h),
        FadeInUp(
          delay: const Duration(milliseconds: 300),
          child: _buildGlassTextField(
            controller: _universityController,
            label: 'اسم جامعة التخرج (اختياري)',
            hint: 'مثال: جامعة القاهرة - كلية الصيدلة',
            icon: Icons.school_outlined,
          ),
        ),
        SizedBox(height: 20.h),
      ],
    );
  }

  // --- STEP 2: Documents & Uploads ---
  Widget _buildStep2Documents() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInDown(
          duration: const Duration(milliseconds: 500),
          child: Text(
            'المستندات والوثائق',
            style: GoogleFonts.cairo(
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(height: 6.h),
        FadeInDown(
          delay: const Duration(milliseconds: 100),
          child: Text(
            'ارفع مستنداً واحداً على الأقل للتحقق وتفعيل صلاحيات الحساب',
            style: GoogleFonts.cairo(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: 20.h),
        ..._docNames.entries.map((entry) {
          final docType = entry.key;
          final docName = entry.value;
          final filePath = _selectedFiles[docType];

          return _buildDocumentUploadRow(docType, docName, filePath);
        }),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildDocumentUploadRow(String docType, String docName, String? filePath) {
    final isSelected = filePath != null;
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    docName,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w900,
                      fontSize: 13.sp,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (isSelected) ...[
                    SizedBox(height: 4.h),
                    Text(
                      filePath.split(RegExp(r'[\\/]')).last,
                      style: GoogleFonts.poppins(
                        fontSize: 11.sp,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 12.w),
            if (isSelected) ...[
              IconButton(
                onPressed: () => _removeDocument(docType),
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              ),
              Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen, size: 24.r),
            ] else
              TextButton.icon(
                onPressed: () => _pickDocument(docType),
                icon: Icon(Icons.add_photo_alternate_outlined, size: 16.r, color: AppColors.primaryGreen),
                label: Text(
                  'اختيار',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w900,
                    fontSize: 12.sp,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- Shared Widgets ---
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 80.h,
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: 0,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.textPrimary,
                  size: 16,
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 45.w,
                fit: BoxFit.contain,
              ),
              SizedBox(width: 10.w),
              Text(
                'طمني صيدلي',
                style: GoogleFonts.cairo(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepperIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepNode(0, 'الحساب'),
          _buildStepDivider(0),
          _buildStepNode(1, 'المهنة'),
          _buildStepDivider(1),
          _buildStepNode(2, 'المستندات'),
        ],
      ),
    );
  }

  Widget _buildStepNode(int index, String title) {
    bool isCompleted = _currentStep > index;
    bool isActive = _currentStep == index;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32.r,
          height: 32.r,
          decoration: BoxDecoration(
            color: isCompleted
                ? AppColors.primaryGreen
                : isActive
                    ? Colors.white
                    : Colors.white.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(
              color: isCompleted || isActive ? AppColors.primaryGreen : Colors.white.withOpacity(0.6),
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: isCompleted
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Text(
                  '${index + 1}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                    color: isActive ? AppColors.primaryGreen : AppColors.textSecondary,
                  ),
                ),
        ),
        SizedBox(height: 4.h),
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 11.sp,
            fontWeight: isActive || isCompleted ? FontWeight.w900 : FontWeight.bold,
            color: isActive || isCompleted ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider(int fromIndex) {
    bool isCompleted = _currentStep > fromIndex;
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(bottom: 16.h, left: 8.w, right: 8.w),
        child: Container(
          height: 2.h,
          color: isCompleted ? AppColors.primaryGreen : Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationButtons() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.5), width: 1)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: SizedBox(
                height: 50.h,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _currentStep--;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    'السابق',
                    style: GoogleFonts.cairo(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) SizedBox(width: 16.w),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 50.h,
              child: ElevatedButton(
                onPressed: () {
                  if (_validateCurrentStep()) {
                    if (_currentStep < 2) {
                      setState(() {
                        _currentStep++;
                      });
                    } else {
                      _registerUser();
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _currentStep == 2 ? 'إنشاء حساب ورفع المستندات' : 'المتابعة والتالي',
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

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نوع الطلب',
          style: GoogleFonts.cairo(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _buildSelectorTile(
                title: 'صيدلي ممارس',
                value: true,
                icon: Icons.medical_services_rounded,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: _buildSelectorTile(
                title: 'متدرب / طالب',
                value: false,
                icon: Icons.local_pharmacy_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectorTile({
    required String title,
    required bool value,
    required IconData icon,
  }) {
    bool isSelected = isPharmacist == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          isPharmacist = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : Colors.white.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryGreen : AppColors.textSecondary,
              size: 28.r,
            ),
            SizedBox(height: 10.h),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 14.sp,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                color: isSelected ? AppColors.primaryGreen : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isNumeric = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(right: 4.w, bottom: 8.h),
          child: Text(
            label,
            style: GoogleFonts.cairo(fontSize: 14.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: TextFormField(
                controller: controller,
                obscureText: isPassword,
                keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: GoogleFonts.cairo(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 13.sp),
                  prefixIcon: Icon(icon, color: AppColors.primaryGreen, size: 22.r),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
                ),
              ),
            ),
          ),
        ),
      ],
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
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
          child: Container(color: Colors.transparent),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Stack(
      children: [
        ModalBarrier(
          dismissible: false,
          color: Colors.black.withOpacity(0.55),
        ),
        Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 40.w),
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: AppColors.primaryGreen,
                  strokeWidth: 3,
                ),
                SizedBox(height: 24.h),
                Text(
                  _loadingMessage,
                  style: GoogleFonts.cairo(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
