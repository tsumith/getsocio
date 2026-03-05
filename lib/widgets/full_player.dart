import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:getsocio/widgets/scroll_text.dart';
import 'package:getsocio/widgets/wiggle_slider.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/sychro/sync_provider.dart';
import '../home/music_lib/player_provider.dart';
import 'connection_pill.dart';

class FullPlayerView extends StatefulWidget {
  const FullPlayerView({super.key});

  @override
  State<FullPlayerView> createState() => _FullPlayerViewState();
}

class _FullPlayerViewState extends State<FullPlayerView> with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final syncProvider = context.watch<SyncProvider>();
    final song = playerProvider.currentSong;

    if (song == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive logic: Determine if the screen is "small" (like an older iPhone or mini Android)
            final bool isSmallScreen = constraints.maxHeight < 700;

            // Album art should be 80% of width but never more than 40% of height
            final double albumArtSize = min(
                constraints.maxWidth * 0.82,
                constraints.maxHeight * 0.45
            );

            return Column(
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
                    onPressed: () => context.pop(),
                  ),
                  actions: [
                    // ← Connection pill in top-right corner
                    Padding(
                      padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                      child: ConnectionPill(
                        sync: syncProvider,
                        fontSize: 10,
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        const Spacer(flex: 1),

                        // Album Art - Responsive Size
                        Hero(
                          tag: 'song_art',
                          child: Container(
                            width: albumArtSize,
                            height: albumArtSize,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                )
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: song.coverPath != null && File(song.coverPath!).existsSync()
                                ? Image.file(
                              File(song.coverPath!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const _FallbackCover(),
                            )
                                : const _FallbackCover(),
                          ),
                        ),

                        const Spacer(flex: 1),

                        // Title & Artist - Responsive Font Sizes
                        ScrollingText(
                            text: song.title,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 22 : 28,
                                fontWeight: FontWeight.bold
                            )
                        ),
                        const SizedBox(height: 6),
                        ScrollingText(
                          text: song.artist,
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: isSmallScreen ? 16 : 18
                          ),
                        ),

                        const Spacer(flex: 1),

                        // Seeker
                        StreamBuilder<Duration>(
                          stream: playerProvider.positionStream,
                          builder: (context, snapshot) {
                            final position = snapshot.data ?? Duration.zero;
                            final duration = playerProvider.player.duration ?? Duration.zero;
                            final double progress = duration.inMilliseconds > 0
                                ? position.inMilliseconds / duration.inMilliseconds
                                : 0.0;

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Column(
                                children: [
                                  AnimatedBuilder(
                                    animation: _waveController,
                                    builder: (context, child) {
                                      return WiggleSlider(
                                        value: progress,
                                        isPlaying: playerProvider.isPlaying,
                                        phase: _waveController.value * 2 * pi,
                                        onScrub: (percent) {
                                          playerProvider.player.seek(duration * percent);
                                        },
                                      );
                                    },
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(_formatDuration(position), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                        Text(_formatDuration(duration), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const Spacer(flex: 1),

                        // Controls - Responsive Icon Sizes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            const Icon(Icons.shuffle, color: Colors.white54, size: 22),
                            IconButton(
                              icon: Icon(Icons.skip_previous_rounded, color: Colors.white, size: isSmallScreen ? 35 : 45),
                              onPressed: playerProvider.previous,
                            ),
                            IconButton(
                              iconSize: isSmallScreen ? 70 : 85,
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                playerProvider.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                color: Colors.white,
                              ),
                              onPressed: () => playerProvider.togglePlay(),
                            ),
                            IconButton(
                              icon: Icon(Icons.skip_next_rounded, color: Colors.white, size: isSmallScreen ? 35 : 45),
                              onPressed: playerProvider.next,
                            ),
                            const Icon(Icons.repeat, color: Colors.white54, size: 22),
                          ],
                        ),

                        const Spacer(flex: 2), // Extra space at bottom for visual weight
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FallbackCover extends StatelessWidget {
  const _FallbackCover();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withOpacity(0.05),
      alignment: Alignment.center,
      child: const Icon(
        Icons.music_note_rounded,
        color: Colors.blueAccent,
        size: 80,
      ),
    );
  }
}