import 'package:flutter/foundation.dart';

const String appEnvironment = String.fromEnvironment(
  'APP_ENV',
  defaultValue: kReleaseMode ? 'production' : 'development',
);

const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: kIsWeb
      // Use an explicit IPv4 loopback address. On some Windows/Chrome setups,
      // `localhost` resolves to ::1 while the local Django server is bound only
      // to IPv4, which Dio reports as a connection error with no HTTP status.
      ? 'http://127.0.0.1:8000/api/v1/'
      : 'http://10.19.112.220:8000/api/v1/',
);

bool get isProduction => appEnvironment == 'production';
