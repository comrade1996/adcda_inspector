class LoginRequest {
  final String userName;
  final String password;
  final bool rememberMe;

  LoginRequest({
    required this.userName,
    required this.password,
    this.rememberMe = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'password': password,
      'rememberMe': rememberMe,
    };
  }
}

class RefreshTokenDTO {
  final String refreshToken;

  RefreshTokenDTO({required this.refreshToken});

  Map<String, dynamic> toJson() {
    return {
      'refreshToken': refreshToken,
    };
  }
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpires;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpires,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      accessTokenExpires: json['accessTokenExpires'] != null
          ? DateTime.parse(json['accessTokenExpires'])
          : DateTime.now().add(const Duration(hours: 1)),
    );
  }
}
