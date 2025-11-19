import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'edit_vehicle_page.dart';
import 'edit_travel_page.dart';
import 'function.dart';
import 'dart:io';

class VehicleDetailsPage extends StatefulWidget {
  final String vehicleId;
  final File file;
  const VehicleDetailsPage({
    super.key,
    required this.vehicleId,
    required this.file,
  });

  @override
  State<VehicleDetailsPage> createState() => _VehicleDetailsPageState();
}

class _VehicleDetailsPageState extends State<VehicleDetailsPage> {
  Map<String, dynamic>? vehicle;
  List<Map<String, dynamic>> travels = [];
  late File filedata;

  @override
  void initState() {
    super.initState();
    filedata = widget.file;
    loadData();
    try {
      Special.loadImages();
    } catch (_) {
      // ignore network errors; types remain whatever was cached
    }
  }

  Future<void> loadData() async {
    final d = await DBHelper.db;

    final v = await d.rawQuery(
      '''
    SELECT v.*, t.Type, t.Image
    FROM vehicles v
    INNER JOIN vehicletype t ON v.TypeID = t.TypeID
    WHERE v.vehicle_id = ?
    LIMIT 1
  ''',
      [widget.vehicleId],
    );

    vehicle = v.isNotEmpty ? v.first : null;

    travels = await d.query(
      'travels',
      where: 'vehicle_id = ?  AND deleted = 0',
      whereArgs: [widget.vehicleId],
      orderBy: 'travel_time DESC',
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (vehicle == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F0F),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFF5C544)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Vehicle Details",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SECTION TITLE
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Text(
              "Vehicle Information",
              style: TextStyle(
                color: Color(0xFFF5C544),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          // --- VEHICLE CARD ----
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // row: image left + main info right
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          filedata,
                          width: 130,
                          height: 130,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) {
                            return Image.asset(
                              "assets/Others.png",
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vehicle!['vehicle_number'] ?? '---',
                              style: const TextStyle(
                                color: Color(0xFFF5C544),
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (vehicle!['vehicle_name'] != '')
                                  ? vehicle!['vehicle_name'] ?? '---'
                                  : "---",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              vehicle!['Type'] ?? '',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  _dividerSmall(),
                  Text(
                    (vehicle!['description'] ?? '').toString(),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF5C544),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          final changed = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EditVehiclePage(vehicleId: widget.vehicleId),
                            ),
                          );
                          if (changed == true) loadData();
                        },
                        child: const Text("Edit"),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => _deleteVehicleConfirm(context),
                        child: const Text("Delete"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // second header
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Text(
              "Travel History",
              style: TextStyle(
                color: Color(0xFFF5C544),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: travels.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (_, i) {
                final t = travels[i];
                return Card(
                  color: const Color(0xFF1A1A1A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    textColor: Colors.white,
                    title: Text(
                      (vehicle!['TypeID'] != 'ZOther')
                          ? ((t['travel_from'] != "") && (t['travel_to'] != ""))
                                ? "${(t['travel_from'] == "") ? "---" : t['travel_from']} → ${(t['travel_to'] == "") ? "---" : t['travel_to']}"
                                : "---"
                          : "${t['travel_time']}",
                    ),
                    subtitle: Text(
                      (vehicle!['TypeID'] != 'ZOther')
                          ? "₹${t['price']} • ${t['travel_time']}"
                          : "Spotted Time",
                      style: const TextStyle(color: Colors.white54),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Color(0xFFF5C544),
                          ),
                          onPressed: () async {
                            final changed = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditTravelPage(
                                  travel: t,
                                  TypeIs: vehicle!['TypeID'],
                                ),
                              ),
                            );
                            if (changed == true) loadData();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              _deleteTravel(context, t['travel_id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _dividerSmall() => Container(
    height: 1,
    width: double.infinity,
    color: Colors.white12,
    margin: const EdgeInsets.symmetric(vertical: 6),
  );

  void _deleteVehicleConfirm(BuildContext context) async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Vehicle?"),
        content: const Text("Are you sure you want to delete this vehicle?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = await DBHelper.db;
      await db.update(
        'vehicles',
        {'deleted': 1, 'sync_status': 'pending'},
        where: 'vehicle_id = ?',
        whereArgs: [widget.vehicleId],
      );
      Navigator.pop(context, true);
    }
  }

  void _deleteTravel(BuildContext context, String id) async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Travel?"),
        content: const Text(
          "Are you sure you want to delete this travel record?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final db = await DBHelper.db;
      await db.update(
        'travels',
        {'deleted': 1, 'sync_status': 'pending'},
        where: 'travel_id = ?',
        whereArgs: [id],
      );
      loadData();
    }
  }
}
