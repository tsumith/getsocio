import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../home/music_lib/player_provider.dart';
import 'custom_progress_bar.dart';

class ShellPlayer extends StatefulWidget {
  const ShellPlayer({super.key});

  @override
  State<ShellPlayer> createState() => _ShellPlayerState();
}

class _ShellPlayerState extends State<ShellPlayer> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.watch<PlayerProvider>();

    if (provider.currentIndex >= 0 &&
        _pageController.hasClients &&
        _pageController.page?.round() != provider.currentIndex) {
      _pageController.animateToPage(
        provider.currentIndex,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final currentSong = playerProvider.currentSong;
    if (currentSong == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap:()=>context.push('/player'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        height: 65,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            // Album Cover with Shaped Progress
            StreamBuilder<Duration>(
              stream: playerProvider.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = playerProvider.player.duration ?? Duration.zero;
                double progress = 0.0;
                if (duration.inMilliseconds > 0) {
                  progress = position.inMilliseconds / duration.inMilliseconds;
                }

                return Hero(
                  tag:'song_art',
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: RoundedRectProgressPainter(
                        progress: progress,
                        color: Colors.blueAccent,
                        strokeWidth: 2.5,
                        borderRadius: 10,
                      ),
                      child: Container(
                        margin:EdgeInsets.all(2.5),
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: currentSong.coverPath != null
                            ? Image.file(
                          File(currentSong.coverPath!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.music_note, color: Colors.blueAccent, size: 20),
                        )
                            : Center(
                          child: Icon(
                              Icons.music_note,
                              color: Colors.blueAccent.withOpacity(0.8),
                              size: 20
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(width: 12),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                itemCount: playerProvider.queue.length,
                onPageChanged: (index) {
                  playerProvider.playAt(index);
                },
                itemBuilder: (context, index) {
                  final song = playerProvider.queue[index];

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          song.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          song.artist,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),


            IconButton(
              icon: Icon(
                playerProvider.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                color: Colors.white,
                size: 35,
              ),
              onPressed: () => playerProvider.togglePlay(),
            ),
          ],
        ),
      ),
    );
  }
}

