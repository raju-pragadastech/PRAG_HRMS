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
};
