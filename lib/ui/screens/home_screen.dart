import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_player_app/player/audio_player_controller.dart';
import 'package:music_player_app/player/music_database.dart';
import 'package:music_player_app/ui/widgets/song_list_tile.dart';
import 'package:music_player_app/ui/widgets/bottom_player_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _scanned = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initMusic(context));
  }

  Future<void> _initMusic(BuildContext ctx) async {
    if (_scanned) return;
    final db = ctx.read<MusicDatabase>();
    await db.scanMusic();
    final controller = ctx.read<AudioPlayerController>();
    controller.loadPlaylist(db.songs);
    if (mounted) setState(() => _scanned = true);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AudioPlayerController>();
    final db = context.watch<MusicDatabase>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Aura Music'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() => _scanned = false);
              _initMusic(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Library',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${db.songs.length} tracks',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Expanded(
            child: db.songs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.music_note_outlined,
                          size: 80,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No music found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Place .mp3/.flac/.wav files in your Music folder',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: controller.playlist.length,
                    itemBuilder: (context, index) {
                      final song = controller.playlist[index];
                      return SongListTile(
                        index: index,
                        title: song['title'],
                        artist: song['artist'],
                        onTap: () => controller.playSong(index),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: controller.currentIndex >= 0
          ? const BottomPlayerBar()
          : const SizedBox.shrink(),
    );
  }
}
