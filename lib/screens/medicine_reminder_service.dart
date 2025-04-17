import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'MedicineModel.dart';
import 'medicine_model.dart';
import 'medicine_reminder_service.dart';

class MedicineFormScreen extends StatefulWidget {
  @override
  _MedicineFormScreenState createState() => _MedicineFormScreenState();
}

class _MedicineFormScreenState extends State<MedicineFormScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  TimeOfDay? _selectedTime;
  int _selectedFrequency = 8; // Default: Every 8 hours

  Future<void> _pickTime() async {
    TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveMedicine() async {
    if (_nameController.text.isEmpty || _dosageController.text.isEmpty || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill all fields")));
      return;
    }

    Medicine medicine = Medicine(
      name: _nameController.text,
      dosage: _dosageController.text,
      time: _selectedTime!,
      frequency: _selectedFrequency,
    );

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> medicineList = prefs.getStringList("medicines") ?? [];
    medicineList.add(jsonEncode(medicine.toJson()));
    await prefs.setStringList("medicines", medicineList);

    var medicine_reminder_service;
    medicine_reminder_service.scheduleReminder(medicine);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Medicine Added & Reminder Set")));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Medicine")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Medicine Name"),
            ),
            TextField(
              controller: _dosageController,
              decoration: InputDecoration(labelText: "Dosage"),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_selectedTime == null ? "Select Time" : "Time: ${_selectedTime!.format(context)}"),
                ElevatedButton(onPressed: _pickTime, child: Text("Pick Time")),
              ],
            ),
            SizedBox(height: 10),
            DropdownButton<int>(
              value: _selectedFrequency,
              items: [4, 6, 8, 12, 24].map((int value) {
                return DropdownMenuItem<int>(value: value, child: Text("Every $value hours"));
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedFrequency = newValue!;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveMedicine,
              child: Text("Save & Set Reminder"),
            ),
          ],
        ),
      ),
    );
  }
}
