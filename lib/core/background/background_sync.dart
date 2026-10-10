import 'background_sync_stub.dart'
    if (dart.library.io) 'background_sync_mobile.dart'
    as implementation;

Future<void> configureBackgroundSync() =>
    implementation.configureBackgroundSync();
