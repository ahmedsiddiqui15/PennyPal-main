import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  
  
  
  
  
  Stream<bool> watch() async* {
    yield await _current();
    try {
      await for (final List<ConnectivityResult> results
          in _connectivity.onConnectivityChanged) {
        yield _online(results);
      }
    } catch (_) {
      
    }
  }

  Future<bool> _current() async {
    try {
      return _online(await _connectivity.checkConnectivity());
    } catch (_) {
      return true;
    }
  }

  bool _online(List<ConnectivityResult> results) =>
      results.any((ConnectivityResult r) => r != ConnectivityResult.none);
}
