import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/devices/data/services/chat_push_handler.dart';
import 'features/splash/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await setupInjection();
  await getIt<ChatPushHandler>().init();

  runApp(const TamennyPharmacistApp());
}

class TamennyPharmacistApp extends StatelessWidget {
  const TamennyPharmacistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return BlocProvider(
          create: (context) => getIt<AuthBloc>()..add(AppStarted()),
          child: MaterialApp(
            navigatorKey: getIt<GlobalKey<NavigatorState>>(),
            title: 'طمني صيدلي',
            debugShowCheckedModeBanner: false,
            locale: const Locale('ar', 'EG'),
            supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: AppTheme.lightTheme,
            home: const SplashScreen(),
          ),
        );
      },
    );
  }
}
