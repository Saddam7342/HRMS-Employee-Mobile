// Employee Profile Model
class EmployeeProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? department;
  final String? designation;
  final String? profileImageUrl;
  final String? employeeCode;
  final DateTime? joinDate;
  final bool isActive;

  EmployeeProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.department,
    this.designation,
    this.profileImageUrl,
    this.employeeCode,
    this.joinDate,
    required this.isActive,
  });

  String get fullName => '$firstName $lastName';

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l';
  }

  factory EmployeeProfile.fromJson(Map<String, dynamic> j) => EmployeeProfile(
        id: j['id'] ?? '',
        firstName: j['firstName'] ?? '',
        lastName: j['lastName'] ?? '',
        email: j['email'] ?? '',
        phone: j['phone'],
        department: j['department'] ?? j['departmentName'],
        designation: j['designation'] ?? j['jobTitle'],
        profileImageUrl: j['profileImageUrl'] ?? j['profilePictureUrl'],
        employeeCode: j['employeeCode'] ?? j['employeeId'],
        joinDate: j['joinDate'] != null ? DateTime.tryParse(j['joinDate']) : null,
        isActive: j['isActive'] ?? true,
      );
}
