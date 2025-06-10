class UserProfile {
  final String? id;
  final String? userName;
  final String? name;
  final String? email;
  final String? phone;
  final List<String>? roles;
  final bool isUaePassUser;
  final String? uniqueName; // Store unique_name claim from UAE Pass

  UserProfile({
    this.id,
    this.userName,
    this.name,
    this.email,
    this.phone,
    this.roles,
    this.isUaePassUser = false,
    this.uniqueName,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      userName: json['userName'],
      name: json['name'] ?? json['fullName'],
      email: json['email'],
      phone: json['phone'],
      roles: json['roles'] != null
          ? List<String>.from(json['roles'])
          : null,
      isUaePassUser: json['isUaePassUser'] ?? false,
      uniqueName: json['uniqueName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'name': name,
      'email': email,
      'phone': phone,
      'roles': roles,
      'isUaePassUser': isUaePassUser,
    };
  }

  // Helper method to get a display name - returns name if available, otherwise userName
  String get displayName => name ?? userName ?? 'User';
}
