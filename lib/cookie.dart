import 'dart:async';

import 'package:http/http.dart';
import 'package:logging/logging.dart';

///
/// Stores cookies.
///
abstract class CookieJar {
  Future<Null> set(String key, String value);

  Future<Null> clear();

  Future<String> get(String key);

  Future<Map<String, String>> getAll();
}

///
/// Dummy implementation of the [CookieJar] that does not use any permanent storage.
///
class DummyCookieJar implements CookieJar {
  final Map<String, String> _cookies = Map<String, String>();

  @override
  Future<String> get(String key) async {
    return _cookies[key];
  }

  @override
  Future<Map<String, String>> getAll() async {
    return _cookies;
  }

  @override
  Future<Null> set(String key, String value) async {
    _cookies[key] = value;
  }

  @override
  Future<Null> clear() async {
    _cookies.clear();
  }
}

///
/// Client that also manages session cookies.
///
class InterceptorClient extends BaseClient {
  static const String _REQUEST_COOKIE_HEADER_NAME = "cookie";
  static const String _RESPONSE_COOKIE_HEADER_NAME = "set-cookie";

  final Logger _log = new Logger('InterceptorClient');
  final Client _inner;
  final List<String> _targetCookies;
  final CookieJar _cookieJar;

  InterceptorClient(this._inner, this._cookieJar, this._targetCookies);

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    final String cookieHeader = await _prepareCookieHeader();
    if (cookieHeader.isNotEmpty) {
      _log.fine("using cookies: $cookieHeader");
      request.headers[_REQUEST_COOKIE_HEADER_NAME] = cookieHeader;
    }

    _log.fine("--> ${request.method} ${request.url}");
    _log.fine("Request headers: ${request.headers}");
    final response = await _inner.send(request);
    _log.fine("<-- ${response.statusCode} ${request.url}");
    _log.fine("Response headers: ${response.headers}");

    _storeCookies(response);

    return response;
  }

  Future<String> _prepareCookieHeader() async {
    String cookieHeaderValue = "";
    final cookies = await _cookieJar.getAll();
    cookies.forEach((key, value) {
      cookieHeaderValue += "$key=$value; ";
    });
    return cookieHeaderValue;
  }

  Future<Null> _storeCookies(StreamedResponse response) async {
    final String cookieHeader = response.headers[_RESPONSE_COOKIE_HEADER_NAME];
    if (cookieHeader == null) {
      return;
    }

    _log.fine("updating cookies...");
    final cookieParts = cookieHeader.replaceAll(",", ";").split(";");
    for (int i = 0; i < cookieParts.length; i++) {
      final value = cookieParts[i];
      final List<String> vals = value.trim().split("=");
      if (vals.length != 2) {
        continue;
      }

      final key = vals[0];
      final val = vals[1];

      if (_targetCookies.contains(key)) {
        await _cookieJar.set(key, val);
        _log.fine("updated cookie $key : $value");
      }
    }
  }
}
