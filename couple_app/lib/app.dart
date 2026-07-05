import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/supabase_config.dart';
import 'providers/anniversary_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/couple_provider.dart';
import 'providers/coupon_provider.dart';
import 'providers/journal_provider.dart';
import 'providers/meal_provider.dart';
import 'providers/todo_provider.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/pairing_screen.dart';

class CoupleApp extends StatelessWidget {
  const CoupleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '情侣空间',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE85D75),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFFFBFB),
        useMaterial3: true,
      ),
      home:
          SupabaseConfig.isConfigured ? const AppGate() : const ConfigScreen(),
    );
  }
}

class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  String? _loadedUserId;
  String? _loadedCoupleId;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final couple = context.watch<CoupleProvider>();
    final userId = auth.user?.id;
    final coupleId =
        couple.current?.isActive == true ? couple.current?.id : null;

    if (userId == null && _loadedUserId != null) {
      _loadedUserId = null;
      _loadedCoupleId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<TodoProvider>().stopWatching();
        context.read<CouponProvider>().stopWatching();
        context.read<JournalProvider>().stopWatching();
        context.read<AnniversaryProvider>().stopWatching();
        context.read<MealProvider>().stopWatching();
        context.read<CoupleProvider>().clear();
        context.read<TodoProvider>().clear();
        context.read<CouponProvider>().clear();
        context.read<JournalProvider>().clear();
        context.read<AnniversaryProvider>().clear();
        context.read<MealProvider>().clear();
      });
    }

    if (userId != null && _loadedUserId != userId) {
      _loadedUserId = userId;
      _loadedCoupleId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<TodoProvider>().stopWatching();
        context.read<CouponProvider>().stopWatching();
        context.read<JournalProvider>().stopWatching();
        context.read<AnniversaryProvider>().stopWatching();
        context.read<MealProvider>().stopWatching();
        context.read<CoupleProvider>().clear();
        context.read<TodoProvider>().clear();
        context.read<CouponProvider>().clear();
        context.read<JournalProvider>().clear();
        context.read<AnniversaryProvider>().clear();
        context.read<MealProvider>().clear();
        context.read<CoupleProvider>().loadCurrentCouple();
      });
    }

    if (coupleId != null && _loadedCoupleId != coupleId) {
      _loadedCoupleId = coupleId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<TodoProvider>().watchTodos(coupleId);
        context.read<CouponProvider>().watchCoupons(coupleId);
        context.read<JournalProvider>().watchJournals(coupleId);
        context.read<AnniversaryProvider>().watchAnniversaries(coupleId);
        context.read<MealProvider>().watchMeals(coupleId);
      });
    }

    if (auth.isLoading || couple.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (userId == null) {
      return const AuthScreen();
    }

    if (couple.current?.isActive != true) {
      return const PairingScreen();
    }

    return const HomeScreen();
  }
}

class ConfigScreen extends StatelessWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Start the app with SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY dart defines.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
