import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/meal_entry.dart';
import '../models/meal_plan.dart';
import '../services/meal_service.dart';
import '../services/supabase_service.dart';

class MealProvider extends ChangeNotifier {
  final MealService _service = MealService();

  List<MealEntry> _entries = [];
  List<MealPlan> _plans = [];
  DateTime _selectedDate = DateTime.now();
  RealtimeChannel? _entryChannel;
  RealtimeChannel? _planChannel;
  String? _watchedCoupleId;
  bool _isLoading = false;
  String? _error;

  List<MealEntry> get entries => _entries;
  List<MealPlan> get plans => _plans;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> watchMeals(String coupleId) async {
    if (_watchedCoupleId == coupleId) {
      return;
    }

    await stopWatching();
    _watchedCoupleId = coupleId;
    await loadForDate(coupleId, _selectedDate);
    _entryChannel = _service.subscribeEntries(
      coupleId,
      () => loadForDate(coupleId, _selectedDate),
    );
    _planChannel = _service.subscribePlans(
      coupleId,
      () => loadForDate(coupleId, _selectedDate),
    );
  }

  Future<void> stopWatching() async {
    final entryChannel = _entryChannel;
    final planChannel = _planChannel;
    _entryChannel = null;
    _planChannel = null;
    _watchedCoupleId = null;

    if (entryChannel != null) {
      await SupabaseService.client.removeChannel(entryChannel);
    }
    if (planChannel != null) {
      await SupabaseService.client.removeChannel(planChannel);
    }
  }

  Future<void> changeDate(String coupleId, DateTime date) async {
    _selectedDate = DateTime(date.year, date.month, date.day);
    await loadForDate(coupleId, _selectedDate);
  }

  Future<void> loadForDate(String coupleId, DateTime date) async {
    await _run(() async {
      _selectedDate = DateTime(date.year, date.month, date.day);
      _entries = await _service.loadEntries(
        coupleId: coupleId,
        date: _selectedDate,
      );
      _plans = await _service.loadPlans(
        coupleId: coupleId,
        date: _selectedDate,
      );
    });
  }

  Future<void> addEntry({
    required String coupleId,
    required String userId,
    required String mealType,
    required Uint8List imageBytes,
    required String fileExtension,
    String? note,
  }) async {
    await _run(() async {
      final trimmedNote = note?.trim();
      await _service.addEntry(
        coupleId: coupleId,
        userId: userId,
        mealDate: _selectedDate,
        mealType: mealType,
        imageBytes: imageBytes,
        fileExtension: fileExtension,
        note: trimmedNote?.isEmpty == true ? null : trimmedNote,
      );
      _entries = await _service.loadEntries(
        coupleId: coupleId,
        date: _selectedDate,
      );
    });
  }

  Future<String> signedPhotoUrl(String photoPath) {
    return _service.signedPhotoUrl(photoPath);
  }

  Future<void> deleteEntry(MealEntry entry) async {
    await _run(() async {
      await _service.deleteEntry(entry);
      final coupleId = _watchedCoupleId ?? entry.coupleId;
      _entries = await _service.loadEntries(
        coupleId: coupleId,
        date: _selectedDate,
      );
    });
  }

  Future<void> addPlan({
    required String coupleId,
    required String mealType,
    required String content,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return;
    }

    await _run(() async {
      await _service.addPlan(
        coupleId: coupleId,
        mealDate: _selectedDate,
        mealType: mealType,
        content: trimmed,
      );
      _plans = await _service.loadPlans(
        coupleId: coupleId,
        date: _selectedDate,
      );
    });
  }

  Future<void> setPlanDone(MealPlan plan, bool isDone) async {
    await _run(() async {
      await _service.setPlanDone(plan.id, isDone);
      final coupleId = _watchedCoupleId ?? plan.coupleId;
      _plans = await _service.loadPlans(
        coupleId: coupleId,
        date: _selectedDate,
      );
    });
  }

  Future<void> deletePlan(MealPlan plan) async {
    await _run(() async {
      await _service.deletePlan(plan.id);
      final coupleId = _watchedCoupleId ?? plan.coupleId;
      _plans = await _service.loadPlans(
        coupleId: coupleId,
        date: _selectedDate,
      );
    });
  }

  List<MealEntry> entriesForType(String mealType) {
    return _entries.where((entry) => entry.mealType == mealType).toList();
  }

  List<MealPlan> plansForType(String mealType) {
    return _plans.where((plan) => plan.mealType == mealType).toList();
  }

  void clear() {
    _entries = [];
    _plans = [];
    _error = null;
    notifyListeners();
  }

  Future<void> _run(Future<void> Function() action) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await action();
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    final entryChannel = _entryChannel;
    final planChannel = _planChannel;
    if (entryChannel != null) {
      SupabaseService.client.removeChannel(entryChannel);
    }
    if (planChannel != null) {
      SupabaseService.client.removeChannel(planChannel);
    }
    super.dispose();
  }
}
