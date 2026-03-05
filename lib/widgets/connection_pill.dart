import 'package:flutter/material.dart';
import '../core/sychro/sync_provider.dart';
import '../core/app_mode.dart';

class ConnectionPill extends StatelessWidget {
  final SyncProvider sync;

  // Customization options
  final double? fontSize;
  final EdgeInsetsGeometry? padding;
  final bool showIcon;
  final VoidCallback? onTap;

  const ConnectionPill({
    super.key,
    required this.sync,
    this.fontSize,
    this.padding,
    this.showIcon = true,
    this.onTap,
  });

  // ─── Unified Status Logic ──────────────────────────────
  static ({
  String modeLabel,
  String statusLabel,
  Color statusColor,
  bool isSyncing,
  IconData icon,
  }) getConnectionData(SyncProvider sync) {

    // Determine mode
    final mode = sync.mode;
    final modeLabel = mode == AppMode.host
        ? 'HOST'
        : mode == AppMode.client
        ? 'CLIENT'
        : 'SOLO';

    final modeIcon = mode == AppMode.host
        ? Icons.wifi_tethering_rounded
        : mode == AppMode.client
        ? Icons.link_rounded
        : Icons.phone_android_rounded;

    // Determine operational status
    final isConnected = sync.isHost || sync.isClient;
    final isScanning = sync.isHost && sync.clientCount == 0;

    final (statusLabel, statusColor, isSyncing) = switch ((isConnected, isScanning)) {
      (true, true)   => ('SCANNING', Colors.blueAccent, true),
      (true, false)  => ('ACTIVE', Colors.greenAccent, false),
      (false, _)     => ('STANDBY', Colors.grey, false),
    };

    return (
    modeLabel: modeLabel,
    statusLabel: statusLabel,
    statusColor: statusColor,
    isSyncing: isSyncing,
    icon: modeIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = getConnectionData(sync);
    final effectiveFontSize = fontSize ?? 11;

    final pill = Container(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: data.statusColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: data.statusColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mode indicator icon (optional)
          if (showIcon) ...[
            Icon(
              data.icon,
              size: effectiveFontSize + 2,
              color: data.statusColor,
            ),
            const SizedBox(width: 6),
          ],

          // Mode Label (bold)
          Text(
            data.modeLabel,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: effectiveFontSize,
              letterSpacing: 0.3,
            ),
          ),

          // Separator dot
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '•',
              style: TextStyle(
                color: data.statusColor.withOpacity(0.7),
                fontSize: effectiveFontSize + 2,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),

          // Status Label + Indicator
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (data.isSyncing)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: data.statusColor,
                    valueColor: AlwaysStoppedAnimation<Color>(data.statusColor),
                  ),
                )
              else
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: data.statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(width: 6),
              Text(
                data.statusLabel,
                style: TextStyle(
                  color: data.statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: effectiveFontSize,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // Optional tap interaction
    return onTap != null
        ? GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: pill)
        : pill;
  }
}