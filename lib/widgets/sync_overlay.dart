import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/sychro/sync_provider.dart';

class SyncOverLay extends StatelessWidget {
  const SyncOverLay({super.key});

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncProvider>();
    final visible = sync.isReceivingFile;

    if (!visible) return const SizedBox.shrink();

    return Stack(
      key: const ValueKey("sync_overlay"),
      children: [
        // background blur + dim
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              color: Colors.black.withOpacity(0.35),
            ),
          ),
        ),

        // bottom sheet
        Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            offset: Offset.zero,
            child: _Sheet(sync: sync),
          ),
        ),
      ],
    );
  }
}

class _Sheet extends StatelessWidget {
  final SyncProvider sync;
  const _Sheet({required this.sync});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(22), 
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          decoration: BoxDecoration(
            color: const Color(0xFF111111).withOpacity(0.97),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(22),
            ),
            border: const Border(
              top: BorderSide(color: Colors.white12),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // grab handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const Text(
                'Receiving file',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),

              LinearProgressIndicator(
                value: sync.transferProgress,
                minHeight: 6,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Colors.blueAccent,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                '${(sync.transferProgress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}