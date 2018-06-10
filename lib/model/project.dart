import 'package:meta/meta.dart';

class Project {
  final String id;
  final String key;
  final String name;
  final String description;

  const Project({
    @required this.id,
    @required this.key,
    @required this.name,
    @required this.description,
  });

  static Project fromJson(Map<String, dynamic> data) {
    return Project(
      id: data['id'] as String,
      key: data['key'] as String,
      name: data['name'] as String,
      description: data['description'] as String,
    );
  }
}
