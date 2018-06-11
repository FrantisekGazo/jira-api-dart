import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jira_api/cookie.dart';
import 'package:jira_api/base_api.dart';
import 'package:jira_api/model/user.dart';
import 'package:jira_api/model/project.dart';
import 'package:jira_api/model/worklog.dart';

///
/// All relevant cookie keys
///
abstract class _CookieKey {
  static const String SESSION = "JSESSIONID";
  static const String TOKEN = "atlassian.xsrf.token";
  static const String REMEMBER_ME = "seraph.rememberme.cookie";

  static List<String> all() =>
      <String>[
        SESSION, TOKEN, REMEMBER_ME
      ];
}

///
/// JIRA API
///
class JiraApi extends BaseApi {
  static const String DATETIME_FORMAT = "yyyy-MM-dd'T'HH:mm:ss.SSS";
  static const String DATE_FORMAT = "yyyy-MM-dd";

  final CookieJar _cookieJar;

  JiraApi(endpoint, this._cookieJar) : super(
      endpoint,
      InterceptorClient(http.Client(), _cookieJar, _CookieKey.all()));

  ///
  /// Returns <code>true</code> if login was successful, otherwise returns <code>false</code>.
  ///
  Future<bool> login(String username, String password) {
    // when you use map as the POST body, content type cannot be application/json
    // instead create the json string manually and it will work
    final body = "{\"username\": \"$username\", \"password\": \"$password\"}";
    return post("rest/auth/1/session", body: body, checkIfExpired: false)
        .then((response) {
      return response.body.contains("\"session\"");
    });
  }

  ///
  /// Logs out current user.
  ///
  Future<bool> logout() {
    return delete("rest/auth/1/session")
        .then((response) {
      return response.statusCode == 204;
    });
  }

  Future<User> getLoggedInUser() {
    return get("rest/api/2/myself")
        .then((response) {
      return User.fromJson(json.decode(response.body));
    });
  }

  Future<List<WorkLog>> getWorkLogs(DateTime dateFrom, DateTime dateTo) {
    final dateFromString = _formatDate(dateFrom);
    final dateToString = _formatDate(dateTo);
    return get(
        "rest/tempo-timesheets/3/worklogs/?dateFrom=$dateFromString&dateTo=$dateToString")
        .then((response) {
      final jsonList = json.decode(response.body) as List<dynamic>;
      return jsonList.map((jsonWorkLog) => WorkLog.fromJson(jsonWorkLog))
          .toList();
    });
  }

  Future<Project> getProject(String projectId) {
    return get("rest/api/2/project/$projectId")
        .then((response) {
      final data = json.decode(response.body);
      return Project.fromJson(data);
    });
  }

  String _formatDate(DateTime date) {
    return "${date.year.toString()}"
        "-${date.month.toString().padLeft(2, '0')}"
        "-${date.day.toString().padLeft(2, '0')}";
  }

  @override
  Future<Null> onAuthExpired() async {
    await _cookieJar.clear();
  }
}
