// lib/viewmodels/base_view_model.dart
import 'package:flutter/foundation.dart';

import '../core/api/api_exception.dart';

abstract class BaseViewModel extends ChangeNotifier {
  bool _loading = false;
  ApiException? _error;

  bool get loading => _loading;
  ApiException? get error => _error;

  void setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  void setError(ApiException e) {
    _error = e;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
