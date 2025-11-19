import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'dart:io';
import 'api_service.dart';
import 'package:flutter/material.dart';
import 'travel_page.dart';
import 'other_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'db_helper.dart';
import 'SmallFunctions/network_watcher.dart';

class Special {
  static late NetworkWatcher watcher;
  static void networkReload(context, setState, mounted) {
    watcher = NetworkWatcher();

    watcher.onOffline = () {
      print("OFFLINE");
    };

    watcher.onBackOnline = () async {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Network back online")));
      await Special.initSystem();
      print(mounted);
      if (mounted) setState(() {});
    };

    watcher.start();
  }

  static Future<void> initSystem() async {
    print("System Setting up...");
    try {
      final types = await ApiService.getVehicleTypes();
      Special.loadImages();
      await DBHelper.upsertVehicleTypes(types);
      ApiService.isLatestVersion();
    } catch (_) {
      // ignore network errors; types remain whatever was cached
    }
  }

  static Future<void> syncNow(
    notify,
    text,
    context,
    _loadTravels,
    mounted,
  ) async {
    if (!await Special.checkInternet()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("No internet Connection")));
      notify = 0;
      _loadTravels();
      return;
    }
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // push VEHICLES ↓
    final pendingVehicles = await DBHelper.getPendingVehicles();
    for (final v in pendingVehicles) {
      final ok = await ApiService.pushVehicle(v);
      if (ok) await DBHelper.markVehicleSynced(v['vehicle_id']);
    }

    // push TRAVELS ↓
    final pendingTravels = await DBHelper.getPendingTravels();
    for (final t in pendingTravels) {
      final ok = await ApiService.pushTravel(t);
      if (ok) await DBHelper.markTravelSynced(t['travel_id']);
    }

    // pull VEHICLES ↓
    final serverVehicles = await ApiService.fetchUserVehicles(uid);
    await DBHelper.upsertVehicleList(serverVehicles);

    // pull TRAVELS ↓
    final serverTravels = await ApiService.fetchUserTravels(uid);
    await DBHelper.upsertTravelList(serverTravels);

    if (mounted) {
      if (notify == 1) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(text)));
      }
      _loadTravels();
    }
  }

  static Future<bool> checkInternet() async {
    final result = await Connectivity().checkConnectivity();
    if (result == ConnectivityResult.none) {
      return false;
    }

    try {
      final lookup = await InternetAddress.lookup('google.com');
      if (lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty) {
        return true;
      } else {
        return false;
      }
    } on SocketException catch (_) {
      return false;
    }
  }

  static String toMySQLDate(DateTime dt) {
    return dt.toIso8601String().replaceFirst('T', ' ').substring(0, 19);
  }

  static void loadImages() async {
    final types = await ApiService.getVehicleTypes();
    for (var item in types) {
      if (item['Image'].trim() != '') {
        await ApiService.saveTypeImage(item['Image']);
      }
    }
  }

  static Widget DrawerData(
    context,
    Function syncNow,
    Function _signOut,
    mounted,
    _loadTravels,
  ) {
    return Drawer(
      backgroundColor: const Color(0xFF1A1A1A),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                "More Options",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.sync, color: Colors.white),
              title: const Text(
                "Sync Now",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                syncNow(1, 'Sync completed', context, _loadTravels, mounted);
              },
            ),

            // ---------------- NEW ITEMS ----------------
            ListTile(
              leading: const Icon(Icons.directions_car, color: Colors.white),
              title: const Text(
                "Travels",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => _PageController(context, const TravelPage()),
            ),

            ListTile(
              leading: const Icon(Icons.more_horiz, color: Colors.white),
              title: const Text(
                "None Transports",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => _PageController(context, const OtherPage()),
            ),

            // --------------------------------------------
            const Spacer(),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _signOut();
              },
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 14, left: 14, top: 0),
              child: Text(
                "Version: ${ApiService.CVersionNo}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _PageController(BuildContext context, Widget page) {
    Navigator.of(context).pop(); // close drawer

    // if already on same page → do nothing
    if (context.widget.runtimeType == page.runtimeType) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => page),
      (route) => false,
    );
  }
}
