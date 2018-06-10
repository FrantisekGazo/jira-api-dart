import 'package:flutter_test/flutter_test.dart';
import 'package:jira_api/cookie.dart';

import 'package:jira_api/jira_api.dart';

import 'private_data.dart';

void main() {

  JiraApi _buildApi() => new JiraApi(PrivateData.ENDPOINT, DummyCookieJar());

  test('Test successful login', () async {
    final jiraApi = _buildApi();

    final success = await jiraApi.login(PrivateData.VALID_USER_EMAIL, PrivateData.VALID_USER_PASSWORD);

    expect(success, true);

    final user = await jiraApi.getLoggedInUser();

    expect(user.email, PrivateData.VALID_USER_EMAIL);
    expect(user.active, true);
    expect(user.avatar.isNotEmpty, true);

    await jiraApi.logout();
  });

  test('Test failing login', () async {
    final jiraApi = _buildApi();

    try {
      await jiraApi.login(PrivateData.FAKE_USER_EMAIL, PrivateData.FAKE_USER_PASSWORD);
      expect(true, false); // this should not be executed
    } catch (e) {
      expect(e.statusCode, 401);
    }
  });

  test('Test work logs', () async {
    final jiraApi = _buildApi();

    final success = await jiraApi.login(PrivateData.VALID_USER_EMAIL, PrivateData.VALID_USER_PASSWORD);

    expect(success, true);

    final worklogs =
        await jiraApi.getWorkLogs(DateTime(2018, 5, 1), DateTime(2018, 5, 30));
    expect(worklogs.isNotEmpty, true);

    final projectId = worklogs[0].issue.projectId;
    final project = await jiraApi.getProject(projectId);
    expect(project.id.isNotEmpty, true);
  });
}
