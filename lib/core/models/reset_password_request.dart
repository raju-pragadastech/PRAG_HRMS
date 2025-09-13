class ResetPasswordRequest {
  final String token;
  final String newPassword;
  final String confirmPassword;

  const ResetPasswordRequest({
    required this.token,
    required this.newPassword,
    required this.confirmPassword,
  });

  factory ResetPasswordRequest.fromJson(Map<String, dynamic> json) =>
      ResetPasswordRequest(
        token: json['token'] ?? '',
        newPassword: json['newPassword'] ?? '',
        confirmPassword: json['confirmPassword'] ?? '',
      );

  Map<String, dynamic> toJson() => {
    'token': token,
    'newPassword': newPassword,
    'confirmPassword': confirmPassword,
  };
}
