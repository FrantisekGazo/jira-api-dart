import 'dart:async';

import 'package:http/http.dart';
import 'package:logging/logging.dart';

///
/// Represents a network error
///
class NetworkError extends StateError {
  final int statusCode;
  final String body;

  NetworkError(Response response)
      : statusCode = response.statusCode,
        body = response.body,
        super("Request failed with ${response.statusCode}: ${response.body}");
}

///
/// Represents a network error
///
class ResponseContentError extends StateError {
  ResponseContentError() : super("Missing content");
}

///
/// Base for all API classes.
///
abstract class BaseApi {
  static const Duration DEFAULT_TIMEOUT = const Duration(seconds: 5);

  final Logger _log = new Logger('BaseApi');
  final String _endpoint;
  final Client _client;

  BaseApi(this._endpoint, this._client);

  Client get client => _client;

  Future<Response> post(String relativeUrl,
      {Map<String, String> headers, body, bool checkIfExpired: true}) {
    var url = _endpoint + relativeUrl;
    return _client
        .post(url, headers: _combineWithDefaultHeaders(headers), body: body)
        .then(_logResponse)
        .then((response) => _checkResponse(response, checkIfExpired))
        .timeout(DEFAULT_TIMEOUT);
  }

  Future<Response> get(String relativeUrl,
      {Map<String, String> headers, bool checkIfExpired: true}) {
    var url = _endpoint + relativeUrl;
    return _client
        .get(url, headers: _combineWithDefaultHeaders(headers))
        .then(_logResponse)
        .then((response) => _checkResponse(response, checkIfExpired))
        .timeout(DEFAULT_TIMEOUT);
  }

  Future<Response> delete(String relativeUrl,
      {Map<String, String> headers, bool checkIfExpired: true}) {
    var url = _endpoint + relativeUrl;
    return _client
        .delete(url, headers: _combineWithDefaultHeaders(headers))
        .then(_logResponse)
        .then((response) => _checkResponse(response, checkIfExpired))
        .timeout(DEFAULT_TIMEOUT);
  }

  Response _logResponse(Response response) {
    _log.fine("_BaseApi: Response body: ${response.body}");
    return response;
  }

  Response _checkResponse(Response response, bool checkIfExpired) {
    _log.fine("Check response");
    if (response.statusCode >= 400) {
      if (checkIfExpired && response.statusCode == 401) {
        onAuthExpired();
      }
      throw new NetworkError(response);
    }
    return response;
  }

  Map<String, String> _combineWithDefaultHeaders(Map<String, String> headers) {
    final Map<String, String> all = new Map();
    all["Content-Type"] = "application/json";
    all["X-Atlassian-Token"] = "no-check";
    if (headers != null) {
      all.addAll(headers);
    }
    return all;
  }

  Future<Null> onAuthExpired() async {}
}
