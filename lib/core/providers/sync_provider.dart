import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// FIXED: This is the actual logic class from your network folder
import 'package:here/core/network/sync_service.dart';

part 'sync_provider.g.dart';

/// Sync status enum for UI feedback
enum SyncStatus { idle, syncing, success, error }

/// 1. State provider for the UI to show "Syncing..." or "Success"
@riverpod
class SyncState extends _$SyncState {
  @override
  SyncStatus build() => SyncStatus.idle;

  void setStatus(SyncStatus status) => state = status;
}

/// 2. Connectivity stream - uses the new List return type for connectivity_plus 6.x
@riverpod
Stream<List<ConnectivityResult>> connectivityStream(ConnectivityStreamRef ref) {
  return Connectivity().onConnectivityChanged;
}

/// 3. The Main Sync Logic (Renamed to 'Sync' to generate 'syncProvider')
@riverpod
class Sync extends _$Sync {
  @override
  FutureOr<void> build() => null;
  
  // This helper gets the underlying service from your network folder
  // Note: This assumes syncServiceProvider exists in core/network/sync_service.dart
  SyncService _getService() => ref.read(syncServiceProvider.notifier);
  
  // This helper updates the UI status
  SyncState _getState() => ref.read(syncStateProvider.notifier);

  Future<void> syncAll() async {
    _getState().setStatus(SyncStatus.syncing);
    try {
      await _getService().syncAll();
      _getState().setStatus(SyncStatus.success);
    } catch (e) {
      _getState().setStatus(SyncStatus.error);
    } finally {
      // Return to idle after 2 seconds so the "Success" icon disappears
      Future.delayed(const Duration(seconds: 2), () {
        if (ref.exists(syncStateProvider)) {
          _getState().setStatus(SyncStatus.idle);
        }
      });
    }
  }

  Future<void> syncMessages() async {
    await _getService().syncMessages();
  }

  Future<void> syncFeed() async {
    await _getService().syncFeed();
  }
}