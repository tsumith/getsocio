import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/sychro/sync_provider.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  // Define a consistent "Surface" color to replace glass effects
  final Color surfaceColor = const Color(0xFF1A1A1A);
  final Color borderColor = const Color(0xFF333333);

  int? _targetIndex; // Tracks where the user WANTS to go

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),

            Center(child: _buildStatusIndicator(sync)),

            const Spacer(flex: 2),

            const Text(
              "Your Music, Synced.",
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Choose how you want to play",
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),

            const Spacer(flex: 1),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildModePanel(sync),
            ),

            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _simpleContainer(
            padding: const EdgeInsets.all(10),
            child: const Icon(Icons.menu, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _simpleContainer(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text("Search music...", style: TextStyle(color: Colors.grey)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(SyncProvider sync) {
    final isConnected = sync.isHost || sync.isClient;
    final isSyncing = sync.isHost && sync.clientCount == 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: isConnected ? Colors.greenAccent.withOpacity(0.1) : surfaceColor,
        borderRadius: BorderRadius.circular(8), // More squared/modern
        border: Border.all(
          color: isConnected ? Colors.greenAccent : borderColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSyncing)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
            )
          else
            Icon(
              isConnected ? Icons.circle : Icons.circle_outlined,
              size: 10,
              color: isConnected ? Colors.greenAccent : Colors.grey,
            ),
          const SizedBox(width: 10),
          Text(
            isConnected ? "ACTIVE" : (isSyncing ? "SCANNING" : "STANDBY"),
            style: TextStyle(
              color: isConnected ? Colors.greenAccent : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _simpleContainer({required Widget child, double? height, EdgeInsetsGeometry? padding}) {
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }

  Widget _buildModePanel(SyncProvider sync) {

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
      Opacity(
      opacity: sync.isSwitching ? 0.6 : 1,
        child: IgnorePointer(
          ignoring: sync.isSwitching,
          child: _buildSegmentedControl(sync),
        ),
      ),
          const SizedBox(height: 24),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: sync.canJoin //- wifi enabled -
                ? const Text(
              "Turn off Wi-Fi to host via hotspot",
              key: ValueKey("wifi_on_hint"),
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            )
                : const Text(
              "Clients will connect via your hotspot",
              key: ValueKey("wifi_off_hint"),
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 24),

      AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _buildModeDetails(sync),
      ),
        ],
      ),
    );
  }
  Widget _buildSegmentedControl(SyncProvider sync) {
    final int displayIndex = (sync.isSwitching && _targetIndex != null)
        ? _targetIndex!
        : (sync.isSolo ? 0 : sync.isHost ? 1 : 2);
    // -- Toast message for mode events ---
    void _showStatusSnackBar(BuildContext context, String message, {bool isError = false}) {
      ScaffoldMessenger.of(context).clearSnackBars(); // Remove existing ones

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          backgroundColor: isError ? Colors.redAccent.withOpacity(0.9) : const Color(0xFF333333),
          behavior: SnackBarBehavior.floating,
          width: 280, // Makes it look like a small floating pill
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    void _handleTap(SyncProvider sync, int index) async{
      setState(()=>_targetIndex=index);
      try{
        if(index==0) {
          await sync.stop();
          _showStatusSnackBar(context, "Back to Solo Mode", isError: false);
        }
        if(index==1){
          await sync.startHost();
          _showStatusSnackBar(context, "Hosting session started!", isError: false);
        }
        if(index==2){
          await sync.joinHost();
          _showStatusSnackBar(context, "Connected to Host!", isError: false);
        }
      }catch(e){
        final errorMessage = e.toString().replaceFirst('Exception:', '').trim();
        _showStatusSnackBar(context, errorMessage, isError: true);
      }finally{
        if(mounted) setState(()=>_targetIndex=null);
      }
    }


    return LayoutBuilder(
      builder: (context, constraints) {
        final segmentWidth = constraints.maxWidth / 3;

        return Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                left: segmentWidth * displayIndex,
                child: _PulsingKnob(
                  active: sync.isSwitching,
                  child: Container(
                    width: segmentWidth,
                    height: 48,
                    decoration: BoxDecoration(
                      color: sync.isSwitching?Colors.greenAccent:Colors.blueAccent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: sync.isSwitching?const Center(child:SizedBox(width: 16,height:16)):null,
                  ),
                ),
              ),
              Row(
                children: [
                  _segmentLabel("Solo", displayIndex == 0, true, () =>_handleTap(sync,0)),
                  _segmentLabel("Host", displayIndex == 1, sync.canHost, () => _handleTap(sync,1)),
                  _segmentLabel("Join", displayIndex == 2, sync.canJoin, ()=>_handleTap(sync,2)),
                ],
              ),
            ],
          ),
        );
      },
    );

  }

  Widget _segmentLabel(String label, bool active,bool isEnabled, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isEnabled?onTap:null,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: isEnabled?( active ? Colors.white : Colors.white54):Colors.white24,
              fontWeight: FontWeight.w600,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  Widget _buildModeDetails(SyncProvider sync) {
    if (sync.isHost) {
      return Column(
        key: const ValueKey("host"),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Hosting Session",
            style: TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          if (sync.localIp != null)
            Text(
              "IP: ${sync.localIp}",
              style: const TextStyle(color: Colors.white70),
            ),
          const SizedBox(height: 8),
          Text(
            "Clients connected: ${sync.clientCount}",
            style: const TextStyle(color: Colors.white),
          ),
        ],
      );
    }

    if (sync.isClient) {
      return Column(
        key: const ValueKey("client"),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Connected to Host",
            style: TextStyle(
              color: Colors.greenAccent,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Waiting for playback...",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      );
    }

    return const Text(
      "Play music from your library.",
      key: ValueKey("solo"),
      style: TextStyle(color: Colors.grey),
    );
  }

}
class _PulsingKnob extends StatefulWidget {
  final Widget child;
  final bool active;

  const _PulsingKnob({required this.child, required this.active});

  @override
  State<_PulsingKnob> createState() => _PulsingKnobState();
}

class _PulsingKnobState extends State<_PulsingKnob> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1.0).animate(_controller),
      child: widget.child,
    );
  }
}