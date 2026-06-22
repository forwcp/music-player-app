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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initMusic(context));
  }

  Future<void> _initMusic(BuildContext ctx) async {
    if (_scanned) return;
    
    setState(() => _isLoading = true);
    
    try {
      final db = ctx.read<MusicDatabase>();
      await db.scanMusic();
      
      if (!mounted) return;
      
      if (db.songs.isNotEmpty) {
        final controller = context.read<AudioPlayerController>();
        controller.loadPlaylist(db.songs);
      }
      
      setState(() {
        _scanned = db.songs.isNotEmpty;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[HomeScreen] Error initializing music: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
            icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            onPressed: _isLoading ? null : () {
              setState(() {
                _scanned = false;
                _isLoading = true;
              });
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
                  _isLoading 
                      ? 'Scanning...' 
                      : '${db.songs.length} tracks',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : db.songs.isEmpty
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
      bottomNavigationBar: const BottomPlayerBar(),
    );
  }
}
