import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class MusicDatabase extends ChangeNotifier {
  final List<Map<String, dynamic>> _songs = [];
  List<Map<String, dynamic>> get songs => List.unmodifiable(_songs);

  Future<void> scanMusic() async {
    _songs.clear();

    // Request permission first - Android 13+ uses READ_MEDIA_AUDIO, older uses STORAGE
    if (!kIsWeb && Platform.isAndroid) {
      // Android 13+ (API 33+) uses audio permission
      final audioStatus = await Permission.audio.status;
      if (audioStatus.isDenied || audioStatus.isPermanentlyDenied) {
        final result = await Permission.audio.request();
        if (result.isDenied || result.isPermanentlyDenied) {
          debugPrint('[MusicDatabase] Audio permission denied');
          notifyListeners();
          return;
        }
      }
    }

    final directories = <String>[];

    if (!kIsWeb && Platform.isAndroid) {
      // Standard music directories
      final standardDirs = [
        '/storage/emulated/0/Music',
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Podcasts',
      ];
      
      for (final dirPath in standardDirs) {
        final dir = Directory(dirPath);
        if (dir.existsSync() && !directories.contains(dirPath)) {
          directories.add(dirPath);
        }
      }

      // Scan all top-level directories for music-related folders
      try {
        final rootDir = Directory('/storage/emulated/0');
        if (rootDir.existsSync()) {
          for (final entry in rootDir.listSync()) {
            if (entry is Directory) {
              final name = entry.path.split('/').last.toLowerCase();
              final isMusicRelated = name.contains('music') || 
                                     name.contains('song') || 
                                     name.contains('audio') || 
                                     name.contains('media');
              if (isMusicRelated && !directories.contains(entry.path)) {
                directories.add(entry.path);
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[MusicDatabase] Error scanning root dirs: $e');
      }
    }

    if (!kIsWeb && Platform.isWindows) {
      final username = Platform.environment['USERNAME'] ?? Platform.environment['USER'];
      if (username != null) {
        final musicFolder = Directory('C:/Users/$username/Music');
        if (musicFolder.existsSync()) {
          directories.add(musicFolder.path);
        }
      }
    }

    if (!kIsWeb && Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        final musicFolder = Directory('$home/Music');
        if (musicFolder.existsSync()) {
          directories.add(musicFolder.path);
        }
      }
    }

    // Scan each directory
    for (final dirPath in directories) {
      final dir = Directory(dirPath);
      if (dir.existsSync()) {
        _scanDirectory(dir, depth: 0);
      }
    }

    // Sort by title
    _songs.sort((a, b) => a['title'].compareTo(b['title']));
    debugPrint('[MusicDatabase] Found ${_songs.length} songs');
    notifyListeners();
  }

  void _scanDirectory(Directory dir, {int depth = 0}) {
    if (depth > 5) {
      debugPrint('[MusicDatabase] Skipping deep directory: ${dir.path}');
      return;
    }
    
    try {
      final entities = dir.listSync(recursive: false);
      for (final entity in entities) {
        if (entity is File && _isAudioFile(entity.path)) {
          final name = entity.path.split(Platform.pathSeparator).last;
          _songs.add({
            'path': entity.path,
            'title': _extractTitle(name),
            'artist': 'Unknown Artist',
            'album': 'Unknown Album',
            'duration': 0,
          });
        } else if (entity is Directory) {
          _scanDirectory(entity, depth: depth + 1);
        }
      }
    } catch (e) {
      debugPrint('[MusicDatabase] Error scanning directory ${dir.path}: $e');
    }
  }

  bool _isAudioFile(String path) {
    final ext = path.toLowerCase().split('.').last;
    return ext == 'mp3' || ext == 'flac' || ext == 'wav' || 
           ext == 'aac' || ext == 'ogg' || ext == 'm4a' || 
           ext == 'wma' || ext == 'opus' || ext == 'webm';
  }

  String _extractTitle(String filename) {
    return filename.replaceAll(RegExp(r'\.[^.]+$'), '');
  }
}
