import 'package:meta/meta.dart';

class User {
  final String displayName;
  final String email;
  final String avatar;
  final bool active;

  const User({
    @required this.displayName,
    @required this.email,
    @required this.avatar,
    @required this.active,
  });

  static User fromJson(Map<String, dynamic> json) {
    return User(
      displayName: json['displayName'],
      email: json['emailAddress'],
      avatar: json['avatarUrls']['48x48'],
      active: json['active'],
    );
  }
}
