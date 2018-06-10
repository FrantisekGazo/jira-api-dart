import 'package:jira_api/model/issue.dart';
import 'package:meta/meta.dart';

class WorkLog {
  final String id;
  final int timeSpentSeconds;
  final int billedSeconds;
  final DateTime dateStarted;
  final String comment;
  final Issue issue;

  const WorkLog({
    @required this.id,
    @required this.timeSpentSeconds,
    @required this.billedSeconds,
    @required this.dateStarted,
    @required this.comment,
    @required this.issue,
  });

  static WorkLog fromJson(Map<String, dynamic> json) {
    return WorkLog(
      id: json['id'].toString(),
      timeSpentSeconds: json['timeSpentSeconds'] as int,
      billedSeconds: json['billedSeconds'] as int,
      dateStarted: DateTime.parse(json['dateStarted']),
      comment: json['comment'] as String,
      issue: Issue.fromJson(json['issue']),
    );
  }
}
