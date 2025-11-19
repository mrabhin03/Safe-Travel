import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'db_helper.dart';
import 'add_vehicle_page.dart';

class AddTravelPage extends StatefulWidget {
  const AddTravelPage({super.key});
  @override
  State<AddTravelPage> createState() => _AddTravelPageState();
}

class _AddTravelPageState extends State<AddTravelPage> {
  final vehicleNumberCtrl = TextEditingController();
  final fromCtrl = TextEditingController();
  final toCtrl = TextEditingController();
  final priceCtrl = TextEditingController();

  Future<void> _saveTravel() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final number = vehicleNumberCtrl.text.trim().toUpperCase().replaceAll(
      " ",
      "",
    );

    if (number.isEmpty) return;

    final exist = await DBHelper.findVehicleByNumber(number, uid);
    String vehicleId;

    if (exist != null) {
      vehicleId = exist['vehicle_id'];
    } else {
      vehicleId =
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddVehiclePage(uid: uid, vehicleNumber: number),
            ),
          ) ??
          '';
      if (vehicleId == '') return;
    }

    await DBHelper.insertTravel({
      'travel_id': const Uuid().v4(),
      'vehicle_id': vehicleId,
      'travel_from': fromCtrl.text.trim(),
      'travel_to': toCtrl.text.trim(),
      'price': double.tryParse(priceCtrl.text.trim()),
      'travel_time': DateTime.now().toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
      'sync_status': 'pending',
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Add Travel", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              TextField(
                controller: vehicleNumberCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.directions_bus,
                    color: Colors.white70,
                  ),
                  hintText: "Vehicle Number",
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
                controller: fromCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.location_on_outlined,
                    color: Colors.white70,
                  ),
                  hintText: "From",
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
                controller: toCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.flag_outlined,
                    color: Colors.white70,
                  ),
                  hintText: "To",
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
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.currency_rupee,
                    color: Colors.white70,
                  ),
                  hintText: "Price",
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
                  onPressed: _saveTravel,
                  child: const Text(
                    "Save",
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
