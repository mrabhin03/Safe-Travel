import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';

class NetworkWatcher {
  StreamSubscription? _sub;
  Function()? onBackOnline;
  Function()? onOffline;

  bool isOffline = false;

  void start() {
    _sub = Connectivity().onConnectivityChanged.listen((result) async {
      bool online = await _hasRealInternet();

      if (!online) {
        if (isOffline == false) {
          isOffline = true;
          if (onOffline != null) onOffline!();
        }
      } else {
        if (isOffline == true) {
          isOffline = false;
          if (onBackOnline != null) onBackOnline!();
        }
      }
    });
  }

  Future<bool> _hasRealInternet() async {
    try {
      final r = await InternetAddress.lookup('google.com');
      return r.isNotEmpty && r[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void stop() {
    _sub?.cancel();
  }
}
