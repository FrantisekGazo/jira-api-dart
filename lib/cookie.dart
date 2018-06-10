import 'dart:async';

import 'package:http/http.dart';
import 'package:logging/logging.dart';

///
/// Stores cookies.
///
abstract class CookieJar {
  void set(String key, String value);

  void clear();

  String get(String key);

  Map<String, String> getAll();
}

///
/// Dummy implementation of the [CookieJar] that does not use any permanent storage.
///
class DummyCookieJar implements CookieJar {
  final Map<String, String> _cookies = Map<String, String>();

  @override
  String get(String key) {
    return _cookies[key];
  }

  @override
  Map<String, String> getAll() {
    return _cookies;
  }

  @override
  void set(String key, String value) {
    _cookies[key] = value;
  }

  @override
  void clear() {
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
    final String cookieHeader = _prepareCookieHeader();
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

  String _prepareCookieHeader() {
    String cookieHeaderValue = "";
    _cookieJar.getAll().forEach((key, value) {
      cookieHeaderValue += "$key=$value; ";
    });
    return cookieHeaderValue;
  }

  void _storeCookies(StreamedResponse response) {
    final String cookieHeader = response.headers[_RESPONSE_COOKIE_HEADER_NAME];
    if (cookieHeader == null) {
      return;
    }

    _log.fine("updating cookies...");
    cookieHeader.replaceAll(",", ";").split(";").forEach((value) {
      final List<String> vals = value.trim().split("=");
      if (vals.length != 2) {
        return;
      }

      final key = vals[0];
      final val = vals[1];

      if (_targetCookies.contains(key)) {
        _cookieJar.set(key, val);
        _log.fine("updated cookie $key : $value");
      }
    });
  }
}
