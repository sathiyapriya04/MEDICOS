import 'package:flutter/material.dart';
import 'dart:convert';

class Medicine {
  String name;
  String dosage;
  TimeOfDay time;
  int frequency;

  Medicine({required this.name, required this.dosage, required this.time, required this.frequency});

  // Convert Medicine object to JSON
  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "dosage": dosage,
      "time": "${time.hour}:${time.minute}",
      "frequency": frequency,
    };
  }

  // Convert JSON to Medicine object
  factory Medicine.fromJson(Map<String, dynamic> json) {
    List<String> timeParts = json["time"].split(":");
    return Medicine(
      name: json["name"],
      dosage: json["dosage"],
      time: TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1])),
      frequency: json["frequency"],
    );
  }
}
