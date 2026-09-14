/// One source of truth for every API client, including token refresh.
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  // Android devices connected with `adb reverse tcp:8000 tcp:8000` can use
  // the host's Django server through loopback. Production builds should pass
  // the deployed URL with --dart-define=API_BASE_URL=...
  defaultValue: 'http://10.169.241.220:8000/api/v1/',
);
