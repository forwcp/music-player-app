import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_player_app/player/audio_player_controller.dart';
import 'package:music_player_app/ui/theme/app_theme.dart';

class BottomPlayerBar extends StatelessWidget {
  const BottomPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AudioPlayerController>();

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/player');
      },
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          border: Border(
            top: BorderSide(color: const Color(0xFF2D2D3F), width: 1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Mini cover
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.music_note_rounded,
                      color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              // Song info
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.currentTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      controller.currentArtist,
                      style: const TextStyle(
                        color: Color(0xFF8888A0),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Play/Pause
              IconButton(
                icon: AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) {
                    return Icon(
                      controller.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 32,
                    );
                  },
                ),
                onPressed: () => controller.togglePlayPause(),
              ),
              // Next
              IconButton(
                icon: const Icon(Icons.skip_next_rounded,
                    color: Colors.white, size: 28),
                onPressed: () => controller.playNext(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
