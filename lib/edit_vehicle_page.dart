import 'package:flutter/material.dart';
import 'db_helper.dart';

class EditVehiclePage extends StatefulWidget {
  final String vehicleId;
  const EditVehiclePage({super.key, required this.vehicleId});

  @override
  State<EditVehiclePage> createState() => _EditVehiclePageState();
}

class _EditVehiclePageState extends State<EditVehiclePage> {
  Map<String, dynamic>? vehicle;
  List<Map<String, dynamic>> types = [];
  String? selectedTypeId;
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final NumberCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    // load the vehicle row
    final d = await DBHelper.db;
    final v = await d.query(
      'vehicles',
      where: 'vehicle_id = ?',
      whereArgs: [widget.vehicleId],
      limit: 1,
    );
    vehicle = v.first;

    // load all types
    types = await DBHelper.getAllTypes();

    selectedTypeId = vehicle!['TypeID'];
    nameCtrl.text = vehicle!['vehicle_name'] ?? '';
    descCtrl.text = vehicle!['description'] ?? '';
    NumberCtrl.text = vehicle!['vehicle_number'] ?? '';

    setState(() {});
  }

  Future<void> saveNow() async {
    final d = await DBHelper.db;
    await d.update(
      'vehicles',
      {
        'TypeID': selectedTypeId,
        'vehicle_number': NumberCtrl.text.trim().toUpperCase().replaceAll(
          " ",
          "",
        ),
        'vehicle_name': nameCtrl.text.trim(),
        'description': descCtrl.text.trim(),
        'sync_status': 'pending',
      },
      where: 'vehicle_id = ?',
      whereArgs: [widget.vehicleId],
    );

    Navigator.pop(context, true); // return changed flag
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
          "Edit Vehicle",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // top vehicle no
              Text(
                "Vehicle Number: ${vehicle!['vehicle_number']}",
                style: const TextStyle(
                  color: Color(0xFFF5C544),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),

              // vehicle number edit field
              TextField(
                controller: NumberCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Vehicle Number",
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withOpacity(.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // dropdown
              DropdownButtonFormField<String>(
                value: selectedTypeId,
                isExpanded: true,
                dropdownColor: const Color(0xFF1A1A1A),
                style: const TextStyle(color: Colors.white),
                iconEnabledColor: Colors.white70,
                decoration: InputDecoration(
                  hintText: "Vehicle Type",
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withOpacity(.06),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: types
                    .map(
                      (t) => DropdownMenuItem<String>(
                        value: t['TypeID'],
                        child: Text(t['Type'], overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => selectedTypeId = v),
              ),

              const SizedBox(height: 14),

              // vehicle name field
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Vehicle Name",
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withOpacity(.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // description
              TextField(
                controller: descCtrl,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Description (optional)",
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withOpacity(.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5C544),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: saveNow,
                  child: const Text(
                    "Save Changes",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
