import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_player_app/player/audio_player_controller.dart';
import 'package:music_player_app/ui/theme/app_theme.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _coverScale;
  late Animation<double> _coverShadow;
  bool _isShuffleOn = false;
  bool _isRepeatOn = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      reverseDuration: const Duration(milliseconds: 300),
    );
    _coverScale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _coverShadow = Tween<double>(begin: 0.2, end: 0.6).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _updateAnimation(bool playing) {
    if (playing) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AudioPlayerController>();

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        body: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.white, size: 32),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Now Playing',
                      style: TextStyle(
                          color: Color(0xFF8888A0),
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      icon: const Icon(Icons.queue_music_rounded,
                          color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Album Art
              Expanded(
                flex: 3,
                child: Center(
                  child: AnimatedBuilder(
                    animation: controller,
                    builder: (context, child) {
                      _updateAnimation(controller.isPlaying);
                      return Transform.scale(
                        scale: _coverScale.value,
                        child: Container(
                          width: 280,
                          height: 280,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: const BorderRadius.all(Radius.circular(24)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF667eea).withValues(alpha:_coverShadow.value),
                                blurRadius: 40,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.music_note_rounded,
                              size: 80,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Song Info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  children: [
                    Text(
                      controller.currentTitle,
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 24),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.currentArtist,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 16,
                        color: const Color(0xFF8888A0),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: controller,
                      builder: (context, _) {
                        final pos = controller.position;
                        final dur = controller.duration;
                        final percent = dur.inMilliseconds > 0
                            ? pos.inMilliseconds / dur.inMilliseconds
                            : 0.0;

                        return Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                              ),
                              child: Slider(
                                value: percent.clamp(0.0, 1.0),
                                onChanged: (v) {
                                  controller.seekTo(
                                    Duration(milliseconds: (v * dur.inMilliseconds).toInt()),
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_formatDuration(pos),
                                      style: const TextStyle(color: Color(0xFF8888A0), fontSize: 12)),
                                  Text(_formatDuration(dur),
                                      style: const TextStyle(color: Color(0xFF8888A0), fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Controls
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.shuffle_rounded,
                          color: _isShuffleOn ? const Color(0xFF667eea) : const Color(0xFF8888A0), size: 28),
                      onPressed: () {
                        setState(() {
                          _isShuffleOn = !_isShuffleOn;
                        });
                      },
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded,
                          color: Colors.white, size: 40),
                      onPressed: controller.hasPrevious
                          ? () => controller.playPrevious()
                          : null,
                    ),
                    const SizedBox(width: 16),
                    // Play/Pause Button
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF667eea).withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: AnimatedBuilder(
                          animation: controller,
                          builder: (context, _) {
                            return Icon(
                              controller.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 48,
                              color: Colors.white,
                            );
                          },
                        ),
                        onPressed: () => controller.togglePlayPause(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded,
                          color: Colors.white, size: 40),
                      onPressed: controller.hasNext
                          ? () => controller.playNext()
                          : null,
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(Icons.repeat_rounded,
                          color: _isRepeatOn ? const Color(0xFF667eea) : const Color(0xFF8888A0), size: 28),
                      onPressed: () {
                        setState(() {
                          _isRepeatOn = !_isRepeatOn;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Volume
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.volume_down_rounded,
                        color: Color(0xFF8888A0), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AnimatedBuilder(
                        animation: controller,
                        builder: (context, _) {
                          return SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 2,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            ),
                            child: Slider(
                              value: controller.volume.clamp(0.0, 1.0),
                              min: 0.0,
                              max: 1.0,
                              onChanged: (v) => controller.setVolume(v),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.volume_up_rounded,
                        color: Color(0xFF8888A0), size: 20),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final min = d.inMinutes.toString().padLeft(2, '0');
    final sec = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }
}
