class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String dob;
  final String gender;
  final String age;
  final String address;
  final String phone;
  final String altPhone;
  final String guardianName;

  UserModel({
    this.uid = "", // Default to empty string to avoid null issues
    required this.fullName,
    required this.email,
    required this.dob,
    required this.gender,
    required this.age,
    required this.address,
    required this.phone,
    required this.altPhone,
    required this.guardianName,
  });

  // ✅ Firestore Storage: Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'dob': dob,
      'gender': gender,
      'age': age,
      'address': address,
      'phone': phone,
      'altPhone': altPhone,
      'guardianName': guardianName,
    };
  }

  // ✅ Firestore Retrieval: Convert from Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? "",
      fullName: map['fullName'] ?? "",
      email: map['email'] ?? "",
      dob: map['dob'] ?? "",
      gender: map['gender'] ?? "",
      age: map['age'] ?? "",
      address: map['address'] ?? "",
      phone: map['phone'] ?? "",
      altPhone: map['altPhone'] ?? "",
      guardianName: map['guardianName'] ?? "",
    );
  }

  // ✅ Fix: Add copyWith Method to Update Specific Fields
  UserModel copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? dob,
    String? gender,
    String? age,
    String? address,
    String? phone,
    String? altPhone,
    String? guardianName,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      altPhone: altPhone ?? this.altPhone,
      guardianName: guardianName ?? this.guardianName,
    );
  }
}
