import 'package:flutter/material.dart';

class Medication {
  String name;
  String dosage;
  TimeOfDay reminderTime;

  Medication({required this.name, required this.dosage, required this.reminderTime});
}

class MedicationManagementScreen extends StatefulWidget {
  @override
  _MedicationManagementScreenState createState() => _MedicationManagementScreenState();
}

class _MedicationManagementScreenState extends State<MedicationManagementScreen> {
  List<Medication> medications = [];

  void _addMedication() {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController nameController = TextEditingController();
        TextEditingController dosageController = TextEditingController();
        TimeOfDay selectedTime = TimeOfDay.now();

        return AlertDialog(
          title: Text("Add Medication"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: "Name")),
              TextField(controller: dosageController, decoration: InputDecoration(labelText: "Dosage")),
              TextButton(
                onPressed: () async {
                  TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (picked != null) {
                    selectedTime = picked;
                  }
                },
                child: Text("Pick Reminder Time"),
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  medications.add(Medication(
                    name: nameController.text,
                    dosage: dosageController.text,
                    reminderTime: selectedTime,
                  ));
                });
                Navigator.pop(context);
              },
              child: Text("Save"),
            )
          ],
        );
      },
    );
  }

  void _editMedication(int index) {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController nameController = TextEditingController(text: medications[index].name);
        TextEditingController dosageController = TextEditingController(text: medications[index].dosage);
        TimeOfDay selectedTime = medications[index].reminderTime;

        return AlertDialog(
          title: Text("Edit Medication"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: "Name")),
              TextField(controller: dosageController, decoration: InputDecoration(labelText: "Dosage")),
              TextButton(
                onPressed: () async {
                  TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (picked != null) {
                    setState(() {
                      selectedTime = picked;
                    });
                  }
                },
                child: Text("Pick Reminder Time"),
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  medications[index] = Medication(
                    name: nameController.text,
                    dosage: dosageController.text,
                    reminderTime: selectedTime,
                  );
                });
                Navigator.pop(context);
              },
              child: Text("Update"),
            )
          ],
        );
      },
    );
  }

  void _deleteMedication(int index) {
    setState(() {
      medications.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Medication Management")),
      body: ListView.builder(
        itemCount: medications.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              title: Text(medications[index].name),
              subtitle: Text("Dosage: ${medications[index].dosage}\nReminder: ${medications[index].reminderTime.format(context)}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: Icon(Icons.edit), onPressed: () => _editMedication(index)),
                  IconButton(icon: Icon(Icons.delete), onPressed: () => _deleteMedication(index)),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMedication,
        child: Icon(Icons.add),
      ),
    );
  }
}
