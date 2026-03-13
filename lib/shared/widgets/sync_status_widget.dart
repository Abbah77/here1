import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:here/core/providers/sync_provider.dart';

class SyncStatusWidget extends ConsumerWidget {
  const SyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // FIXED: Using the actual name from your sync_provider.dart
    final connectivityAsync = ref.watch(connectivityStreamProvider);
    final syncStatus = ref.watch(syncStateProvider);
    
    return connectivityAsync.when(
      data: (results) {
        // connectivity_plus 6.x returns a list. If it contains 'none', we are offline.
        final bool isOffline = results.contains(ConnectivityResult.none);
        
        if (isOffline) {
          return _buildOfflineIndicator(context);
        }

        // Logic based on your SyncStatus enum
        switch (syncStatus) {
          case SyncStatus.syncing:
            return _buildSyncingIndicator(context);
          case SyncStatus.success:
            return _buildSuccessIndicator(context);
          case SyncStatus.error:
            return _buildErrorIndicator(context, ref);
          case SyncStatus.idle:
          default:
            return _buildIdleIndicator(context, ref);
        }
      },
      error: (_, __) => const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
    );
  }

  Widget _buildOfflineIndicator(BuildContext context) => const _StatusChip(icon: Icons.wifi_off, label: 'Offline', color: Colors.orange);

  Widget _buildSyncingIndicator(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue)),
          const SizedBox(width: 6),
          Text('Syncing...', style: GoogleFonts.inter(fontSize: 11, color: Colors.blue.shade700)),
        ]),
      );

  Widget _buildSuccessIndicator(BuildContext context) => const _StatusChip(icon: Icons.check_circle, label: 'Updated', color: Colors.green);
  
  Widget _buildErrorIndicator(BuildContext context, WidgetRef ref) => InkWell(
        onTap: () => ref.read(syncProvider.notifier).syncAll(),
        child: const _StatusChip(icon: Icons.sync_problem, label: 'Retry', color: Colors.red),
      );

  Widget _buildIdleIndicator(BuildContext context, WidgetRef ref) => InkWell(
        onTap: () => ref.read(syncProvider.notifier).syncAll(),
        child: const _StatusChip(icon: Icons.sync, label: 'Sync', color: Colors.grey),
      );
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final MaterialColor color;
  const _StatusChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.shade100)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color.shade700),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color.shade700)),
        ]),
      );
}