import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'dart:io';
import 'api_service.dart';
import 'package:flutter/material.dart';
import 'travel_page.dart';
import 'other_page.dart';
import 'login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'db_helper.dart';
import 'SmallFunctions/network_watcher.dart';

class Special {
  static late NetworkWatcher watcher;
  static int Qwer = 1;
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

  static Widget newUpdate() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 158, 85, 2),
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "New Version Available",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            "Version: ${ApiService.newVersionNo}",
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),

          Text(
            "What's new: ${ApiService.feature}",
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: 140,
            height: 40,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => ApiService.urlOpen(),
              child: const Text(
                "Download",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
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
              onTap: () {
                Navigator.pop(context);
                if (Qwer == 1) {
                  return;
                }
                Qwer = 1;

                Navigator.of(context).pushAndRemoveUntil(
                  cupertinoLeftRoute(const TravelPage()),
                  (route) => false,
                );
              },
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
              onTap: () async {
                Navigator.pop(context);
                try {
                  await FirebaseAuth.instance.signOut();
                } catch (e) {
                  print('Sign out failed: $e');
                }
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 14, right: 14, top: 0),
              child: Container(
                width: double.infinity,
                child: Text(
                  "Version: ${ApiService.CVersionNo}",
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _PageController(BuildContext context, Widget page) {
    Qwer = 0;
    Navigator.of(context).pop(); // close drawer

    // if already on same page → do nothing
    if (context.widget.runtimeType == page.runtimeType) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => page),
      (route) => false,
    );
  }

  static Route cupertinoLeftRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 350),

      pageBuilder: (context, animation, secondaryAnimation) => page,

      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // match Cupertino curve
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
          reverseCurve: Curves.easeIn,
        );

        // slide FROM LEFT (instead of right)
        final slide = Tween<Offset>(
          begin: const Offset(-1.0, 0.0),
          end: Offset.zero,
        ).animate(curved);

        // slight fade (Cupertino feel)
        final fade = Tween<double>(begin: 0.9, end: 1.0).animate(curved);

        return SlideTransition(
          position: slide,
          child: FadeTransition(opacity: fade, child: child),
        );
      },
    );
  }
}
