import 'package:flutter/material.dart';

import 'anniversary_screen.dart';
import 'coupon_screen.dart';
import 'dashboard_screen.dart';
import 'journal_screen.dart';
import 'meal_screen.dart';
import 'profile_screen.dart';
import 'todo_screen.dart';

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
      body: IndexedStack(
        index: _index,
        children: [
          DashboardScreen(onOpenTab: _selectTab),
          const TodoScreen(),
          const CouponScreen(),
          const MealScreen(),
          const JournalScreen(),
          const AnniversaryScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
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
            label: '券',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant),
            label: '吃啥',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: '日志',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: '纪念',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }

  void _selectTab(int value) {
    setState(() {
      _index = value;
    });
  }
}
