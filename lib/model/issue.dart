import 'package:meta/meta.dart';

class Issue {
  final String id;
  final String projectId;
  final String key;
  final String summary;

  const Issue({
    @required this.id,
    @required this.projectId,
    @required this.key,
    @required this.summary,
  });

  static Issue fromJson(Map<String, dynamic> json) {
    return Issue(
      id: json['id'].toString(),
      projectId: json['projectId'].toString(),
      key: json['key'] as String,
      summary: json['summary'] as String,
    );
  }
}
