import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/meal_entry.dart';
import '../models/meal_comment.dart';
import '../models/meal_plan.dart';
import '../services/meal_service.dart';
import '../services/supabase_service.dart';

class MealProvider extends ChangeNotifier {
  final MealService _service = MealService();

  List<MealEntry> _entries = [];
  List<MealPlan> _plans = [];
  Map<String, List<MealComment>> _commentsByEntry = {};
  final Set<String> _sendingCommentEntryIds = {};
  DateTime _selectedDate = DateTime.now();
  RealtimeChannel? _entryChannel;
  RealtimeChannel? _planChannel;
  RealtimeChannel? _commentChannel;
  String? _watchedCoupleId;
  bool _isLoading = false;
  String? _error;
  String? _commentError;

  List<MealEntry> get entries => _entries;
  List<MealPlan> get plans => _plans;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get commentError => _commentError;

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
    _commentChannel = _service.subscribeComments(
      coupleId,
      refreshComments,
    );
  }

  Future<void> stopWatching() async {
    final entryChannel = _entryChannel;
    final planChannel = _planChannel;
    final commentChannel = _commentChannel;
    _entryChannel = null;
    _planChannel = null;
    _commentChannel = null;
    _watchedCoupleId = null;

    if (entryChannel != null) {
      await SupabaseService.client.removeChannel(entryChannel);
    }
    if (planChannel != null) {
      await SupabaseService.client.removeChannel(planChannel);
    }
    if (commentChannel != null) {
      await SupabaseService.client.removeChannel(commentChannel);
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
      await _loadCommentsForCurrentEntries();
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
      await _loadCommentsForCurrentEntries();
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
      await _loadCommentsForCurrentEntries();
    });
  }

  List<MealComment> commentsForEntry(String mealEntryId) {
    return _commentsByEntry[mealEntryId] ?? const [];
  }

  bool isSendingComment(String mealEntryId) {
    return _sendingCommentEntryIds.contains(mealEntryId);
  }

  Future<bool> addComment({
    required MealEntry entry,
    required String userId,
    required String content,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty || trimmed.length > 300) {
      return false;
    }

    _sendingCommentEntryIds.add(entry.id);
    _commentError = null;
    notifyListeners();

    try {
      await _service.addComment(
        mealEntryId: entry.id,
        coupleId: entry.coupleId,
        authorId: userId,
        content: trimmed,
      );
      await _loadCommentsForCurrentEntries();
      return true;
    } catch (error) {
      _commentError = _friendlyCommentError(error);
      return false;
    } finally {
      _sendingCommentEntryIds.remove(entry.id);
      notifyListeners();
    }
  }

  Future<void> deleteComment(MealComment comment) async {
    _commentError = null;
    notifyListeners();

    try {
      await _service.deleteComment(comment.id);
      await _loadCommentsForCurrentEntries();
    } catch (error) {
      _commentError = _friendlyCommentError(error);
    } finally {
      notifyListeners();
    }
  }

  Future<void> refreshComments() async {
    await _loadCommentsForCurrentEntries();
    notifyListeners();
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
    _commentsByEntry = {};
    _sendingCommentEntryIds.clear();
    _error = null;
    _commentError = null;
    notifyListeners();
  }

  Future<void> _loadCommentsForCurrentEntries() async {
    try {
      final comments = await _service.loadComments(
        _entries.map((entry) => entry.id).toList(),
      );
      _commentsByEntry = {
        for (final entry in _entries)
          entry.id: comments
              .where((comment) => comment.mealEntryId == entry.id)
              .toList(),
      };
      _commentError = null;
    } catch (error) {
      _commentsByEntry = {};
      _commentError = _friendlyCommentError(error);
    }
  }

  String _friendlyCommentError(Object error) {
    final message = error.toString();
    if (message.contains('meal_comments') ||
        message.contains('PGRST205') ||
        message.contains('schema cache')) {
      return '评论功能需要先更新数据库';
    }
    return '评论加载失败，请稍后重试';
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
    final commentChannel = _commentChannel;
    if (entryChannel != null) {
      SupabaseService.client.removeChannel(entryChannel);
    }
    if (planChannel != null) {
      SupabaseService.client.removeChannel(planChannel);
    }
    if (commentChannel != null) {
      SupabaseService.client.removeChannel(commentChannel);
    }
    super.dispose();
  }
}
