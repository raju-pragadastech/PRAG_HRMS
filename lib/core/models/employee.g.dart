// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employee.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Employee _$EmployeeFromJson(Map<String, dynamic> json) => Employee(
  employeeId: json['employeeId'] as String?,
  firstName: json['firstName'] as String?,
  lastName: json['lastName'] as String?,
  email: json['email'] as String?,
  phone: json['phone'] as String?,
  department: json['department'] as String?,
  position: json['position'] as String?,
  role: json['role'] as String?,
  profileImage: json['profileImage'] as String?,
  joinDate: json['joinDate'] as String?,
  status: json['status'] as String?,
  address: json['address'] as String?,
  dateOfBirth: json['dateOfBirth'] as String?,
  emergencyContact: json['emergencyContact'] as String?,
  manager: json['manager'] as String?,
  workLocation: json['workLocation'] as String?,
  experience: json['experience'] as String?,
  education: json['education'] as String?,
  skills: (json['skills'] as List<dynamic>?)?.map((e) => e as String).toList(),
);

Map<String, dynamic> _$EmployeeToJson(Employee instance) => <String, dynamic>{
  'employeeId': instance.employeeId,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'email': instance.email,
  'phone': instance.phone,
  'department': instance.department,
  'position': instance.position,
  'role': instance.role,
  'profileImage': instance.profileImage,
  'joinDate': instance.joinDate,
  'status': instance.status,
  'address': instance.address,
  'dateOfBirth': instance.dateOfBirth,
  'emergencyContact': instance.emergencyContact,
  'manager': instance.manager,
  'workLocation': instance.workLocation,
  'experience': instance.experience,
  'education': instance.education,
  'skills': instance.skills,
};
