import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'db_helper.dart';
import 'api_service.dart';
import 'add_travel_page.dart';
import 'function.dart';
import 'vehicle_details_page.dart';
import 'SmallFunctions/network_watcher.dart';

int active = 1;

class TravelPage extends StatefulWidget {
  const TravelPage({super.key});
  @override
  State<TravelPage> createState() => _TravelPageState();
}

class _TravelPageState extends State<TravelPage> {
  List<Map<String, dynamic>> travels = [];
  late NetworkWatcher watcher;

  @override
  void initState() {
    super.initState();
    _loadTravels();
    Special.syncNow(
      active,
      'Everthing is upto date',
      context,
      _loadTravels,
      mounted,
    );
    active = 0;
    try {
      Special.loadImages();
    } catch (_) {
      // ignore network errors; types remain whatever was cached
    }
    Special.networkReload(context, setState, mounted);
  }

  Future<void> _loadTravels() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    travels = await DBHelper.getTravelsForUser(uid);
    if (mounted) setState(() {});
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    try {
      ApiService.isLatestVersion();
    } catch (_) {}
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 2,
        title: Row(
          children: [
            Image.asset('assets/SafeTravelLogo.png', height: 25),
            SizedBox(width: 10),
            const Text("Safe Travel", style: TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
        ],
      ),

      endDrawer: Special.DrawerData(
        context,
        Special.syncNow,
        _signOut,
        mounted,
        _loadTravels,
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          (ApiService.newVersion > ApiService.Version)
              ? Special.newUpdate()
              : Container(),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Travel Details",
                  style: TextStyle(
                    color: Color(0xFFF5C544),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  "Overview of your recorded travels",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),

          Expanded(
            child: travels.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.inbox_outlined,
                          color: Colors.white54,
                          size: 60,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "No travels found",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Tap + to add a new travel",
                          style: TextStyle(
                            color: Color.fromARGB(153, 255, 255, 255),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: travels.length,
                    itemBuilder: (_, i) {
                      final t = travels[i];
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          final file = await ApiService.getTypeFile(
                            "TypeImage/${t['Image']}",
                          );
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VehicleDetailsPage(
                                vehicleId: t['vehicle_id'],
                                file: file,
                              ),
                            ),
                          );
                          _loadTravels();
                          await Special.syncNow(
                            0,
                            "",
                            context,
                            _loadTravels,
                            mounted,
                          );
                        },
                        child: Card(
                          color: const Color(0xFF1A1A1A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 3,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: FutureBuilder(
                                        future: ApiService.getTypeFile(
                                          "TypeImage/${t['Image']}",
                                        ),
                                        builder: (context, snap) {
                                          if (!snap.hasData) {
                                            return Image.asset(
                                              "assets/Others.png",
                                              width: 130,
                                              height: 130,
                                              fit: BoxFit.cover,
                                            );
                                          }

                                          return Image.file(
                                            snap.data!,
                                            width: 130,
                                            height: 130,
                                            fit: BoxFit.cover,
                                          );
                                        },
                                      ),
                                    ),

                                    const SizedBox(width: 14),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            t['vehicle_number'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),

                                          Text(
                                            t['Type'],
                                            style: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 13,
                                            ),
                                          ),

                                          const SizedBox(height: 6),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                ((t['travel_from'] != "") &&
                                                        (t['travel_to'] != ""))
                                                    ? "${(t['travel_from'] == "") ? "---" : t['travel_from']} → ${(t['travel_to'] == "") ? "---" : t['travel_to']}"
                                                    : "---",
                                                style: const TextStyle(
                                                  color: Color(0xFFF5C544),
                                                  fontSize: 15,
                                                ),
                                              ),

                                              const SizedBox(height: 12),

                                              Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 6,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Color(0xFFF5C544),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      "₹${t['price']}",
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 6),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 30,
                                      height: 120,
                                      child: const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        color: Color(0xFFF5C544),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      t['sync_status'],
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFF5C544),
        foregroundColor: Colors.black,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTravelPage()),
          );
          _loadTravels();
          Special.syncNow(0, '', context, _loadTravels, mounted);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
