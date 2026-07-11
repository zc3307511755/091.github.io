import 'dart:ui';

import 'package:flutter/material.dart';

import 'anniversary_screen.dart';
import 'coupon_screen.dart';
import 'dashboard_screen.dart';
import 'journal_screen.dart';
import 'meal_screen.dart';
import 'profile_screen.dart';
import 'todo_screen.dart';
import '../widgets/stitch_ui.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: [
          DashboardScreen(
            onOpenTab: _selectTab,
            onOpenMeals: () => _pushPage(const MealScreen()),
            onOpenAnniversaries: () => _pushPage(const AnniversaryScreen()),
          ),
          const TodoScreen(),
          const CouponScreen(),
          const JournalScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xF4FFFFFF),
              border: Border(top: BorderSide(color: StitchColors.line)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 72,
                child: Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: NavigationBar(
                      selectedIndex: _index,
                      onDestinationSelected: _selectTab,
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.home_outlined),
                          selectedIcon: Icon(Icons.home_rounded),
                          label: '首页',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.checklist),
                          selectedIcon: Icon(Icons.checklist_rtl),
                          label: '待办',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.local_activity_outlined),
                          selectedIcon: Icon(Icons.local_activity),
                          label: '礼券',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.book_outlined),
                          selectedIcon: Icon(Icons.book),
                          label: '回忆',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.person_outline),
                          selectedIcon: Icon(Icons.person),
                          label: '我的',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _selectTab(int value) {
    setState(() {
      _index = value;
    });
  }

  void _pushPage(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }
}
