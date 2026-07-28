import 'package:flutter/material.dart';
import 'package:pharmacist/core/di/injection_container.dart';
import 'package:pharmacist/core/widgets/app_drawer.dart';
import 'package:pharmacist/features/chat/data/services/chat_signalr_service.dart';
import 'package:pharmacist/features/chat/domain/repositories/chat_repository.dart';
import 'package:pharmacist/features/devices/data/services/device_push_service.dart';
import 'package:pharmacist/features/home/presentation/screens/home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // تسجيل FCM token في الخلفية (upsert آمن التكرار) — بدون واجهة مستخدم.
    getIt<DevicePushService>().registerCurrentDevice();
    // اتصال SignalR على مستوى التطبيق كله — بدون كده الرسايل الحية بتتوصل
    // بس لما شاشة تفاصيل المحادثة بتاعتها مفتوحة بالظبط.
    _connectAppWideChat();
  }

  Future<void> _connectAppWideChat() async {
    final signalR = getIt<ChatSignalRService>();
    await signalR.connect();
    try {
      final conversations = await getIt<ChatRepository>().getConversations(pageSize: 100);
      for (final conversation in conversations.items) {
        await signalR.joinConversation(conversation.id);
      }
    } catch (_) {
      // Best-effort: if this fails, per-screen connect()/joinConversation()
      // in ChatDetailBloc still covers the conversation being viewed.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawerScrimColor: Colors.transparent, // Remove background dimming
      // endDrawer opens from the left in Arabic (RTL) locale
      endDrawer: const AppDrawer(),
      body: const HomeScreen(),
    );
  }
}

