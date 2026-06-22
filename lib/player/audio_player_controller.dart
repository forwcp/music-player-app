import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerController extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  List<Map<String, dynamic>> _playlist = [];
  List<Map<String, dynamic>> get playlist => _playlist;

  int _currentIndex = -1;
  int get currentIndex => _currentIndex;

  String get currentTitle =>
      _currentIndex >= 0 && _currentIndex < _playlist.length
          ? _playlist[_currentIndex]['title']
          : 'No Track';

  String get currentArtist =>
      _currentIndex >= 0 && _currentIndex < _playlist.length
          ? _playlist[_currentIndex]['artist']
          : 'Unknown Artist';

  String get currentPath =>
      _currentIndex >= 0 && _currentIndex < _playlist.length
          ? _playlist[_currentIndex]['path']
          : '';

  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;

  bool get isPlaying => _player.playing;
  bool get hasNext => _currentIndex < _playlist.length - 1;
  bool get hasPrevious => _currentIndex > 0;
  double get volume => _player.volume;

  AudioPlayerController() {
    _player.positionStream.listen((pos) {
      notifyListeners();
    });

    _player.playingStream.listen((playing) {
      notifyListeners();
    });

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        if (hasNext) {
          playNext();
        } else {
          _player.stop();
          notifyListeners();
        }
      }
    });

    _player.errorStream.listen((error) {
      debugPrint('[AudioPlayer] Error: $error');
    });
  }

  void loadPlaylist(List<Map<String, dynamic>> songs) {
    _playlist = songs;
    notifyListeners();
  }

  Future<void> playSong(int index) async {
    if (index < 0 || index >= _playlist.length) {
      debugPrint('[AudioPlayer] Invalid index: $index, playlist length: ${_playlist.length}');
      return;
    }

    _currentIndex = index;
    final song = _playlist[index];
    final path = song['path'];

    debugPrint('[AudioPlayer] === Starting playSong ===');
    debugPrint('[AudioPlayer] Index: $index');
    debugPrint('[AudioPlayer] Title: ${song['title']}');
    debugPrint('[AudioPlayer] Path: $path');
    debugPrint('[AudioPlayer] File exists: ${_fileExists(path)}');

    try {
      await _player.stop();
      debugPrint('[AudioPlayer] Stopped previous playback');

      await _player.setFilePath(path);
      debugPrint('[AudioPlayer] setFilePath succeeded');

      await _player.play();
      debugPrint('[AudioPlayer] play() succeeded, isPlaying: ${_player.playing}');

      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('[AudioPlayer] ERROR: $e');
      debugPrint('[AudioPlayer] Stack: $stackTrace');
      notifyListeners();
    }
  }

  bool _fileExists(String path) {
    try {
      return File(path).existsSync();
    } catch (e) {
      return false;
    }
  }

  Future<void> play() async {
    if (_currentIndex < 0 || _currentIndex >= _playlist.length) return;
    try {
      await _player.play();
      notifyListeners();
    } catch (e) {
      debugPrint('[AudioPlayer] Error playing: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
      notifyListeners();
    } catch (e) {
      debugPrint('[AudioPlayer] Error pausing: $e');
    }
  }

  Future<void> seekTo(Duration position) async {
    try {
      await _player.seek(position);
      notifyListeners();
    } catch (e) {
      debugPrint('[AudioPlayer] Error seeking: $e');
    }
  }

  Future<void> playNext() async {
    if (_currentIndex < 0 || _currentIndex >= _playlist.length) return;
    if (hasNext) {
      await playSong(_currentIndex + 1);
    }
  }

  Future<void> playPrevious() async {
    if (_currentIndex < 0 || _currentIndex >= _playlist.length) return;
    if (hasPrevious) {
      await playSong(_currentIndex - 1);
    }
  }

  Future<void> togglePlayPause() async {
    if (_currentIndex < 0 || _currentIndex >= _playlist.length) return;
    if (_player.playing) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> setVolume(double vol) async {
    try {
      _player.setVolume(vol);
      notifyListeners();
    } catch (e) {
      debugPrint('[AudioPlayer] Error setting volume: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
