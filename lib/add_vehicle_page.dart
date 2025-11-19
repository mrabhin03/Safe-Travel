import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'db_helper.dart';
import 'api_service.dart';

class AddVehiclePage extends StatefulWidget {
  final String uid;
  final String vehicleNumber;
  const AddVehiclePage({
    super.key,
    required this.uid,
    required this.vehicleNumber,
  });

  @override
  State<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  List<Map<String, dynamic>> types = [];
  String? selectedTypeId;
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTypes();
    updateType();
  }

  void updateType() async {
    try {
      final types = await ApiService.getVehicleTypes();
      await DBHelper.upsertVehicleTypes(types);
    } catch (_) {
      // ignore network errors; types remain whatever was cached
    }
  }

  Future<void> _loadTypes() async {
    types = await DBHelper.getAllTypes();
    if (types.isNotEmpty) selectedTypeId = types.first['TypeID'].toString();
    setState(() {});
  }

  Future<void> _save() async {
    if (selectedTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No vehicle types available')),
      );
      return;
    }
    final id = const Uuid().v4();
    await DBHelper.insertVehicle({
      'vehicle_id': id,
      'uid': widget.uid,
      'TypeID': selectedTypeId,
      'vehicle_number': widget.vehicleNumber,
      'vehicle_name': nameCtrl.text.trim().isEmpty
          ? null
          : nameCtrl.text.trim(),
      'description': descCtrl.text.isEmpty ? null : descCtrl.text,
      'created_at': DateTime.now().toIso8601String(),
      'sync_status': 'pending',
    });
    if (!mounted) return;
    Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Add Vehicle", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // vehicle number (read only)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.confirmation_number,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.vehicleNumber,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButtonFormField<String>(
                  value: selectedTypeId,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1A1A1A),
                  style: const TextStyle(color: Colors.white),
                  iconEnabledColor: Colors.white70,
                  decoration: InputDecoration(
                    hintText: "Select Vehicle Type",
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
                          value: t['TypeID'].toString(),
                          child: Text(
                            t['Type']?.toString() ?? t['TypeID'].toString(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => selectedTypeId = v),
                ),
              ),

              const SizedBox(height: 14),

              // vehicle name optional
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Vehicle Name (optional)",
                  hintStyle: TextStyle(
                    color: const Color.fromARGB(255, 128, 128, 128),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: descCtrl,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Description (optional)",
                  hintStyle: const TextStyle(
                    color: Color.fromARGB(255, 128, 128, 128),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),

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
                  onPressed: _save,
                  child: const Text(
                    "Save Vehicle",
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
