import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/onboarding_bloc.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/data/services/chat_signalr_service.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import '../../features/chat/presentation/bloc/ai_assistant_chat_bloc.dart';
import '../../features/chat/presentation/bloc/chat_detail_bloc.dart';
import '../../features/chat/presentation/bloc/conversation_list_bloc.dart';
import '../../features/devices/data/datasources/device_remote_datasource.dart';
import '../../features/devices/data/datasources/device_remote_datasource_impl.dart';
import '../../features/devices/data/services/chat_push_handler.dart';
import '../../features/devices/data/services/device_push_service.dart';
import '../services/local_notifications_service.dart';
import '../../features/notifications/data/repositories/notification_repository_impl.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/notifications/presentation/bloc/notification_bloc.dart';
import '../../features/patients/data/repositories/patient_repository_impl.dart';
import '../../features/patients/domain/repositories/patient_repository.dart';
import '../../features/patients/presentation/bloc/patient_bloc.dart';
import '../../features/prescriptions/data/repositories/prescription_repository_impl.dart';
import '../../features/prescriptions/domain/repositories/prescription_repository.dart';
import '../../features/prescriptions/presentation/bloc/prescription_bloc.dart';
import '../../features/ratings/data/repositories/rating_repository_impl.dart';
import '../../features/ratings/domain/repositories/rating_repository.dart';
import '../../features/ratings/presentation/bloc/rating_bloc.dart';
import '../../features/orders/domain/repositories/orders_repository.dart';
import '../../features/orders/data/repositories/orders_repository_impl.dart';
import '../../features/orders/presentation/bloc/orders_bloc.dart';
import '../../features/branches/domain/repositories/branches_repository.dart';
import '../../features/branches/data/repositories/branches_repository_impl.dart';
import '../../features/branches/presentation/bloc/branches_bloc.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../features/medication_plans/domain/repositories/medication_plan_repository.dart';
import '../../features/medication_plans/data/repositories/medication_plan_repository_impl.dart';
import '../../features/reminders/domain/repositories/reminder_repository.dart';
import '../../features/reminders/data/repositories/reminder_repository_impl.dart';
import '../../features/intern/domain/repositories/intern_repository.dart';
import '../../features/intern/data/repositories/intern_repository_impl.dart';
import '../../features/intern/presentation/bloc/intern_home_bloc.dart';
import '../../features/intern/domain/repositories/intern_patient_repository.dart';
import '../../features/intern/data/repositories/intern_patient_repository_impl.dart';
import '../../features/intern/presentation/bloc/intern_patients_bloc.dart';
import '../../features/academic/domain/repositories/academic_repository.dart';
import '../../features/academic/data/repositories/academic_repository_impl.dart';
import '../network/api_client.dart';
import '../network/file_upload_service.dart';

final getIt = GetIt.instance;

Future<void> setupInjection() async {
  // 1. External
  final sharedPrefs = await SharedPreferences.getInstance();
  getIt.registerLazySingleton(() => sharedPrefs);
  getIt.registerLazySingleton(() => FirebaseAuth.instance);

  // 2. Core (e.g., Network, Storage)
  getIt.registerLazySingleton(() => ApiClient(getIt()));
  getIt.registerLazySingleton(() => FileUploadService(getIt()));
  // Shared with MaterialApp(navigatorKey: ...) in main.dart so push
  // notification deep-links can navigate without a BuildContext of their own.
  getIt.registerLazySingleton(() => GlobalKey<NavigatorState>());

  // 3. Features
  // - Devices (FCM push registration)
  getIt.registerLazySingleton<DeviceRemoteDataSource>(
    () => DeviceRemoteDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton(() => DevicePushService(getIt(), getIt()));
  getIt.registerLazySingleton(() => LocalNotificationsService());
  // ChatRepository (registered below, in "- Chat") is resolved lazily here
  // too — fine, since this factory only runs once setupInjection() and thus
  // all registrations, are complete.
  getIt.registerLazySingleton(() => ChatPushHandler(getIt(), getIt(), getIt()));

  // - Auth
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt(), getIt(), getIt()),
  );
  getIt.registerFactory(() => AuthBloc(getIt()));
  getIt.registerFactory(() => OnboardingBloc(getIt(), getIt()));

  // - Prescriptions
  getIt.registerLazySingleton<PrescriptionRepository>(
    () => PrescriptionRepositoryImpl(getIt()),
  );
  getIt.registerFactory(() => PrescriptionBloc(getIt()));

  // - Patients
  getIt.registerLazySingleton<PatientRepository>(
    () => PatientRepositoryImpl(getIt()),
  );
  getIt.registerFactory(() => PatientBloc(getIt()));

  // - Notifications
  getIt.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(getIt()),
  );
  getIt.registerFactory(() => NotificationBloc(getIt()));

  // - Ratings
  getIt.registerLazySingleton<RatingRepository>(
    () => RatingRepositoryImpl(getIt()),
  );
  getIt.registerFactory(() => RatingBloc(getIt()));

  // - Intern
  getIt.registerLazySingleton<InternRepository>(
    () => InternRepositoryImpl(getIt()),
  );
  getIt.registerFactory(() => InternHomeBloc(getIt()));

  // - Intern Patients
  getIt.registerLazySingleton<InternPatientRepository>(
    () => InternPatientRepositoryImpl(getIt()),
  );
  getIt.registerFactory(() => InternPatientsBloc(getIt()));

  // - Academic (universities/faculties pickers)
  getIt.registerLazySingleton<AcademicRepository>(
    () => AcademicRepositoryImpl(getIt(), getIt()),
  );

  // - Orders
  getIt.registerLazySingleton<OrdersRepository>(
    () => OrdersRepositoryImpl(getIt()),
  );
  getIt.registerFactory(() => OrdersBloc(getIt()));

  // - Branches
  getIt.registerLazySingleton<BranchesRepository>(
    () => BranchesRepositoryImpl(getIt()),
  );
  getIt.registerFactory(() => BranchesBloc(getIt()));

  // - Dashboard
  getIt.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(getIt()),
  );
  getIt.registerFactory(() => DashboardBloc(getIt()));

  // - Medication plans (pharmacist-authored)
  getIt.registerLazySingleton<MedicationPlanRepository>(
    () => MedicationPlanRepositoryImpl(getIt()),
  );

  // - Reminders (pharmacist-authored)
  getIt.registerLazySingleton<ReminderRepository>(
    () => ReminderRepositoryImpl(getIt()),
  );

  // - Chat
  getIt.registerLazySingleton(() => ChatSignalRService(getIt()));
  getIt.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(getIt()),
  );
  getIt.registerFactory(() => ConversationListBloc(getIt(), getIt()));
  getIt.registerFactoryParam<ChatDetailBloc, String, bool?>(
    (conversationId, initialIsClosed) => ChatDetailBloc(
      getIt(),
      getIt(),
      getIt(),
      conversationId,
      initialIsClosed: initialIsClosed ?? false,
    ),
  );
  getIt.registerFactoryParam<AiAssistantChatBloc, String?, void>(
    (patientId, _) => AiAssistantChatBloc(getIt(), patientId: patientId),
  );
}
