class ForgotPasswordRequest {
  final String employeeIdOrEmail;

  const ForgotPasswordRequest({required this.employeeIdOrEmail});

  factory ForgotPasswordRequest.fromJson(Map<String, dynamic> json) =>
      ForgotPasswordRequest(employeeIdOrEmail: json['employeeIdOrEmail'] ?? '');

  Map<String, dynamic> toJson() => {'employeeIdOrEmail': employeeIdOrEmail};
}
