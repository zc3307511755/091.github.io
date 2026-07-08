import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/supabase_config.dart';
import 'providers/anniversary_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/couple_provider.dart';
import 'providers/coupon_provider.dart';
import 'providers/journal_provider.dart';
import 'providers/meal_provider.dart';
import 'providers/presence_provider.dart';
import 'providers/todo_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final provider = AuthProvider();
            if (SupabaseConfig.isConfigured) {
              provider.bootstrap();
            }
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => CoupleProvider()),
        ChangeNotifierProvider(create: (_) => TodoProvider()),
        ChangeNotifierProvider(create: (_) => CouponProvider()),
        ChangeNotifierProvider(create: (_) => JournalProvider()),
        ChangeNotifierProvider(create: (_) => AnniversaryProvider()),
        ChangeNotifierProvider(create: (_) => MealProvider()),
        ChangeNotifierProvider(create: (_) => PresenceProvider()),
      ],
      child: const CoupleApp(),
    ),
  );
}
