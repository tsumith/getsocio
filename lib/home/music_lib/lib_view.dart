import 'dart:io';
import 'package:flutter/material.dart';
import 'package:getsocio/home/music_lib/lib_provider.dart';
import 'package:getsocio/home/music_lib/player_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/sychro/sync_provider.dart';
import '../../models/local_song.dart';

class LibView extends StatefulWidget {
  const LibView({super.key});

  @override
  State<LibView> createState() => _LibViewState();
}

class _LibViewState extends State<LibView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 600) {
      context.read<LibProvider>().loadSongsfromDb();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  _handleFilePick(BuildContext context) async {
    final provider = Provider.of<LibProvider>(context, listen: false);
    try{
      await provider.pickAudioFiles();
    }catch(e){
      _showPermissionDeniedDialog(context);
    }


  }

  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: const Text(
                'Permission Required', style: TextStyle(color: Colors.white)),
            content: const Text(
                'We need access to your storage to play local music.',
                style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              TextButton(onPressed: openAppSettings,
                  child: const Text(
                      'Settings', style: TextStyle(color: Colors.blue))),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LibProvider>();
    final audioFiles = provider.audioFiles;

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        appBar: AppBar(
          surfaceTintColor: const Color(0xFF0D0D0D),
          backgroundColor: const Color(0xFF0D0D0D),
          title: const Text("Your Library", style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.white)),
        ),
        body: Stack(
          children: [
            // LAYER 1: The Library Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Playlists", style: TextStyle(color: Colors.white54, fontSize: 14)),
                  const SizedBox(height: 16),
                  _buildFolderPicker(context,provider.totalCount),
                  const SizedBox(height: 24),
                  const Text("Tracks", style: TextStyle(color: Colors.white54, fontSize: 14)),
                  Expanded(
                    child: audioFiles.isEmpty && !provider.isDbLoading
                        ? const _EmptyState()
                        : _PlayList(
                      controller: _scrollController,
                      audioFiles: audioFiles,
                    ),
                  ),
                ],
              ),
            ),

            // LAYER 2: Full-screen Shimmer (Only for initial cold start)
            if (provider.isDbLoading && audioFiles.isEmpty)
              const Positioned.fill(child: _SkeletonList()),

            // LAYER 3: Parsing Overlay (Now triggers immediately due to 0.001 value)
            if (provider.isImporting && provider.importProgress > 0)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.9),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Colors.blueAccent),
                      const SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 50),
                        child: LinearProgressIndicator(
                          value: provider.importProgress,
                          color: Colors.blueAccent,
                          backgroundColor: Colors.white12,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        provider.loadingMessage,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${(provider.importProgress * 100).toInt()}%",
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

// Separate helper for cleaner code
  Widget _buildFolderPicker(BuildContext context, int totalCount) {
    return InkWell(
      onTap: () => _handleFilePick(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
        ),

        child: Row(
          children: [
            Container(
              height: 50, width: 50,
              decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(
                  Icons.folder_copy_rounded, color: Colors.blueAccent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Local Music", style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
                  Text("$totalCount tracks", style: const TextStyle(
                      color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: const Icon(

                Icons.add_circle_outline_rounded,
                color: Colors.white54,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_off_outlined, size: 60, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          const Text("No tracks loaded yet", style: TextStyle(color: Colors.white38, fontSize: 14)),
        ],
      ),
    );
  }
}

class _PlayList extends StatelessWidget {
  final List<LocalSong> audioFiles;
  final ScrollController controller;
  const _PlayList({required this.audioFiles,required this.controller});

  void _scrollToLetter(String letter) {
    final index = audioFiles.indexWhere(
            (song) => song.title.toUpperCase().startsWith(letter)
    );
    if (index != -1) {
      controller.animateTo(
          index * 72.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LibProvider>();
    final alphabet = "#ABCDEFGHIJKLMNOPQRSTUVWXYZ".split("");

    return Stack(
      children: [
        RawScrollbar(
            controller: controller,
            thumbColor: Colors.blueAccent.withOpacity(0.5),
            radius: const Radius.circular(20),
            thickness: 4,
            child: ListView.builder(
                controller: controller,
                itemCount: audioFiles.length + (provider.hasMore ? 1 : 0),
                padding: const EdgeInsets.only(top: 10,right:30 ),
                itemBuilder: (context, index) {
                  if (index == audioFiles.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.blueAccent)),
                    );
                  }
                  final song = audioFiles[index];
                  return _buildSongTile(context,song, audioFiles);
                }
            ),
        )
        ,
        Positioned(
          right: 0,
          top: 40,
          bottom: 40,
          child: Container(
            width: 30,
            alignment: Alignment.center,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: alphabet.map((letter) => GestureDetector(
                  onTap: () => _scrollToLetter(letter),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      letter,
                      style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ),
          ),
        ),



      ],
    );
  }
}

Widget _buildSongTile(BuildContext context,LocalSong song, List<LocalSong> queue){
  return  ListTile(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
    subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54)),
    leading: Container(
      height: 40, width: 40,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: song.coverPath != null
          ? Image.file(
        File(song.coverPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.music_note, color: Colors.blueAccent, size: 24),
      )
          : const Icon(Icons.music_note, color: Colors.blueAccent, size: 24),
    ),
    onTap: () async{
      final sync = context.read<SyncProvider>();
      final player = context.read<PlayerProvider>();

      if (sync.isHost) {
        await sync.sendFile(File(song.path));
      } else if (sync.isSolo) {
        await player.playLoadSong(song, queue);
      }
    }
    // => context.read<PlayerProvider>().playLoadSong(song,queue),
  );
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.05),
      highlightColor: Colors.white.withOpacity(0.1),
      child: ListView.builder(
        itemCount: 12,
        padding: const EdgeInsets.only(top: 10),
        itemBuilder: (context, index) => ListTile(
          leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
          title: Container(width: double.infinity, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
          subtitle: Container(width: 100, height: 10, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
        ),
      ),
    );
  }
}