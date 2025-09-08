import 'package:json_annotation/json_annotation.dart';

part 'employee.g.dart';

@JsonSerializable()
class Employee {
  final String? employeeId;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? department;
  final String? position;
  final String? role;
  final String? profileImage;
  final String? joinDate;
  final String? status;
  final String? address;
  final String? dateOfBirth;
  final String? emergencyContact;
  final String? manager;
  final String? workLocation;
  final String? experience;
  final String? education;
  final List<String>? skills;

  const Employee({
    this.employeeId,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.department,
    this.position,
    this.role,
    this.profileImage,
    this.joinDate,
    this.status,
    this.address,
    this.dateOfBirth,
    this.emergencyContact,
    this.manager,
    this.workLocation,
    this.experience,
    this.education,
    this.skills,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    print('📥 Employee.fromJson called with: $json');

    // Handle different possible field names from API
    final employee = Employee(
      employeeId: json['employeeId'] ?? json['id'] ?? json['employee_id'],
      firstName:
          json['firstName'] ??
          json['first_name'] ??
          json['name']?.split(' ').first,
      lastName:
          json['lastName'] ??
          json['last_name'] ??
          json['name']?.split(' ').skip(1).join(' '),
      email: json['email'] ?? json['emailAddress'],
      phone: json['phone'] ?? json['phoneNumber'] ?? json['mobile'],
      department: json['department'] ?? json['dept'],
      position: json['position'] ?? json['jobTitle'] ?? json['title'],
      role: json['role'] ?? json['userRole'],
      profileImage: json['profileImage'] ?? json['avatar'] ?? json['image'],
      joinDate: json['joinDate'] ?? json['joiningDate'] ?? json['startDate'],
      status: json['status'] ?? json['employeeStatus'],
      address: json['address'] ?? json['homeAddress'] ?? json['location'],
      dateOfBirth: json['dateOfBirth'] ?? json['birthDate'] ?? json['dob'],
      emergencyContact:
          json['emergencyContact'] ??
          json['emergencyPhone'] ??
          json['emergencyNumber'],
      manager:
          json['manager'] ?? json['reportingManager'] ?? json['supervisor'],
      workLocation:
          json['workLocation'] ?? json['officeLocation'] ?? json['location'],
      experience:
          json['experience'] ??
          json['workExperience'] ??
          json['yearsOfExperience'],
      education: json['education'] ?? json['qualification'] ?? json['degree'],
      skills: json['skills'] != null
          ? (json['skills'] is List
                ? (json['skills'] as List).map((e) => e.toString()).toList()
                : [json['skills'].toString()])
          : null,
    );

    print(
      '📥 Created Employee: firstName="${employee.firstName}", lastName="${employee.lastName}", fullName="${employee.fullName}"',
    );
    print(
      '📥 Additional fields: address="${employee.address}", manager="${employee.manager}", workLocation="${employee.workLocation}"',
    );
    return employee;
  }

  Map<String, dynamic> toJson() => _$EmployeeToJson(this);

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
}
