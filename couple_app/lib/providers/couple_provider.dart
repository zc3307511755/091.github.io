import 'package:flutter/foundation.dart';

import '../models/couple.dart';
import '../services/couple_service.dart';

class CoupleProvider extends ChangeNotifier {
  final CoupleService _service = CoupleService();

  Couple? _current;
  bool _isLoading = false;
  String? _error;

  Couple? get current => _current;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get inviteCode =>
      _current?.status == 'pending' ? _current?.inviteCode : null;

  Future<void> loadCurrentCouple() async {
    await _run(() async {
      _current = await _service.loadCurrentCouple();
    });
  }

  Future<void> createInvite() async {
    await _run(() async {
      await _service.createInvite();
      _current = await _service.loadCurrentCouple();
    });
  }

  Future<void> bindByInviteCode(String inviteCode) async {
    await _run(() async {
      _current = await _service.bindByInviteCode(inviteCode);
    });
  }

  Future<void> leaveCurrentCouple() async {
    await _run(() async {
      await _service.leaveCurrentCouple();
      _current = null;
    });
  }

  void clear() {
    _current = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
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
      _error = _friendlyMessage(error);
      rethrow;
    } finally {
      _isLoading = false;
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
}
