import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/sychro/sync_provider.dart';

class SyncOverLay extends StatelessWidget {
  const SyncOverLay({super.key});

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncProvider>();
    // Only show if we are a client receiving data
    if (!sync.isReceivingFile || !sync.isClient) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        // Position it exactly above the ShellPlayer and BottomNav
        padding: const EdgeInsets.only(bottom: 140),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
            boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10)],
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 12, height: 12,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
              ),
              const SizedBox(width: 12),
              const Text("Buffering...", style: TextStyle(color: Colors.white70, fontSize: 12)),
              const Spacer(),
              Text("${(sync.transferProgress * 100).toInt()}%",
                  style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}