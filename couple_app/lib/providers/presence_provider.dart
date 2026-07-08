import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_presence.dart';
import '../services/presence_service.dart';
import '../services/supabase_service.dart';

class PresenceProvider extends ChangeNotifier {
  final PresenceService _service = PresenceService();

  final Map<String, UserPresence> _presences = {};
  final List<RealtimeChannel> _channels = [];
  Timer? _heartbeatTimer;
  Timer? _clockTimer;
  String? _currentUserId;
  String? _partnerUserId;
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  UserPresence? presenceFor(String? userId) {
    if (userId == null) {
      return null;
    }
    return _presences[userId];
  }

  bool isOnline(String? userId) {
    return presenceFor(userId)?.isOnline ?? false;
  }

  Future<void> watchPair({
    required String currentUserId,
    required String partnerUserId,
  }) async {
    if (_currentUserId == currentUserId && _partnerUserId == partnerUserId) {
      return;
    }

    await stopWatching();
    _currentUserId = currentUserId;
    _partnerUserId = partnerUserId;

    await _touchAndLoad();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _touchAndLoad(silent: true),
    );
    _clockTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => notifyListeners(),
    );

    for (final userId in {currentUserId, partnerUserId}) {
      _channels.add(
        _service.subscribeUser(userId, () => loadVisible(silent: true)),
      );
    }
  }

  Future<void> stopWatching() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _clockTimer?.cancel();
    _clockTimer = null;
    _currentUserId = null;
    _partnerUserId = null;

    final channels = List<RealtimeChannel>.from(_channels);
    _channels.clear();
    for (final channel in channels) {
      await SupabaseService.client.removeChannel(channel);
    }
  }

  Future<void> loadVisible({bool silent = false}) async {
    final currentUserId = _currentUserId;
    final partnerUserId = _partnerUserId;
    if (currentUserId == null || partnerUserId == null) {
      return;
    }

    await _run(
      () async {
        final rows = await _service.loadVisible([currentUserId, partnerUserId]);
        _presences
          ..remove(currentUserId)
          ..remove(partnerUserId);
        for (final row in rows) {
          _presences[row.userId] = row;
        }
      },
      silent: silent,
    );
  }

  void clear() {
    _presences.clear();
    _error = null;
    notifyListeners();
  }

  Future<void> _touchAndLoad({bool silent = false}) async {
    await _run(
      () async {
        final ownPresence = await _service.touch();
        _presences[ownPresence.userId] = ownPresence;
        final partnerUserId = _partnerUserId;
        if (partnerUserId != null) {
          final rows =
              await _service.loadVisible([ownPresence.userId, partnerUserId]);
          for (final row in rows) {
            _presences[row.userId] = row;
          }
        }
      },
      silent: silent,
    );
  }

  Future<void> _run(
    Future<void> Function() action, {
    bool silent = false,
  }) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      await action();
      _error = null;
    } catch (error) {
      _error = _friendlyMessage(error);
    } finally {
      if (!silent) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  String _friendlyMessage(Object error) {
    final message = error.toString();
    const exceptionPrefix = 'Exception: ';
    if (message.startsWith(exceptionPrefix)) {
      return message.substring(exceptionPrefix.length);
    }
    return message;
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _clockTimer?.cancel();
    for (final channel in _channels) {
      SupabaseService.client.removeChannel(channel);
    }
    super.dispose();
  }
}
