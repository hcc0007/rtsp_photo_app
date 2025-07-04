class UserInfo {
  final int userId;
  final String username;
  final String token;
  final String nickname;
  final String avatar;

  UserInfo({
    required this.userId,
    required this.username,
    required this.token,
    required this.nickname,
    required this.avatar,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userId: json['userId'] ?? 0,
      username: json['username'] ?? '',
      token: json['token'] ?? '',
      nickname: json['nickname'] ?? '',
      avatar: json['avatar'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'token': token,
      'nickname': nickname,
      'avatar': avatar,
    };
  }
} 