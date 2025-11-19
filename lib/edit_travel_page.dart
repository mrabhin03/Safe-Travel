import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'function.dart';

class EditTravelPage extends StatefulWidget {
  final Map<String, dynamic> travel;
  final String TypeIs;
  const EditTravelPage({super.key, required this.travel, required this.TypeIs});

  @override
  State<EditTravelPage> createState() => _EditTravelPageState();
}

class _EditTravelPageState extends State<EditTravelPage> {
  late TextEditingController fromCtrl;
  late TextEditingController toCtrl;
  late TextEditingController priceCtrl;
  DateTime? selectedDateTime;
  String typeIs = "";

  @override
  void initState() {
    super.initState();
    typeIs = widget.TypeIs;
    fromCtrl = TextEditingController(text: widget.travel['travel_from']);
    toCtrl = TextEditingController(text: widget.travel['travel_to']);
    priceCtrl = TextEditingController(text: widget.travel['price'].toString());
    selectedDateTime = DateTime.tryParse(widget.travel['travel_time'] ?? "");
  }

  Future<void> pickDateTime() async {
    final initDate = selectedDateTime ?? DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: initDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initDate),
    );
    if (time == null) return;

    setState(() {
      selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> saveNow() async {
    final d = await DBHelper.db;
    await d.update(
      'travels',
      {
        'travel_from': fromCtrl.text.trim(),
        'travel_to': toCtrl.text.trim(),
        'price': double.tryParse(priceCtrl.text.trim()),
        'travel_time': Special.toMySQLDate(selectedDateTime!),
        'sync_status': 'pending',
      },
      where: 'travel_id = ?',
      whereArgs: [widget.travel['travel_id']],
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          (typeIs != "ZOther") ? "Edit Travel" : "Edit Spot Time",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // FROM
              (typeIs != "ZOther")
                  ? Column(
                      children: [
                        TextField(
                          controller: fromCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "From",
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

                        // TO
                        TextField(
                          controller: toCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "To",
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

                        // PRICE
                        TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Price",
                            hintStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: Colors.white.withOpacity(.06),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),
                      ],
                    )
                  : Container(),

              // PICK DATETIME btn
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(.06),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: pickDateTime,
                  child: Text(
                    selectedDateTime == null
                        ? "Pick Travel Time"
                        : "Time: ${selectedDateTime.toString().substring(0, 16)}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // SAVE button
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
