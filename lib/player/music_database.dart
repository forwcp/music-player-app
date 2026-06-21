import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class MusicDatabase extends ChangeNotifier {
  final List<Map<String, dynamic>> _songs = [];
  List<Map<String, dynamic>> get songs => List.unmodifiable(_songs);

  Future<void> scanMusic() async {
    _songs.clear();

    // Request permission first
    if (!kIsWeb && Platform.isAndroid) {
      final audioStatus = await Permission.audio.status;
      if (audioStatus.isDenied) {
        final result = await Permission.audio.request();
        if (result.isDenied || result.isPermanentlyDenied) {
          notifyListeners();
          return;
        }
      }
    }

    final directories = <String>[];

    if (!kIsWeb && Platform.isAndroid) {
      final musicDir = Directory('/storage/emulated/0/Music');
      if (musicDir.existsSync()) directories.add(musicDir.path);
      
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (downloadsDir.existsSync()) directories.add(downloadsDir.path);

      final podcastsDir = Directory('/storage/emulated/0/Podcasts');
      if (podcastsDir.existsSync()) directories.add(podcastsDir.path);

      final ringtonesDir = Directory('/storage/emulated/0/Ringtones');
      if (ringtonesDir.existsSync()) directories.add(ringtonesDir.path);

      final alarmsDir = Directory('/storage/emulated/0/Alarms');
      if (alarmsDir.existsSync()) directories.add(alarmsDir.path);

      final notificationsDir = Directory('/storage/emulated/0/Notifications');
      if (notificationsDir.existsSync()) directories.add(notificationsDir.path);

      // Scan all top-level directories
      final rootDir = Directory('/storage/emulated/0');
      if (rootDir.existsSync()) {
        for (final entry in rootDir.listSync()) {
          if (entry is Directory && !directories.contains(entry.path)) {
            final name = entry.path.split('/').last.toLowerCase();
            if (name.contains('music') || name.contains('song') || 
                name.contains('audio') || name.contains('media')) {
              directories.add(entry.path);
            }
          }
        }
      }
    }

    if (!kIsWeb && Platform.isWindows) {
      final username = Platform.environment['USERNAME'] ?? Platform.environment['USER'];
      if (username != null) {
        final musicFolder = Directory('C:/Users/$username/Music');
        if (musicFolder.existsSync()) directories.add(musicFolder.path);
      }
    }

    if (!kIsWeb && Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        final musicFolder = Directory('$home/Music');
        if (musicFolder.existsSync()) directories.add(musicFolder.path);
      }
    }

    for (final dirPath in directories) {
      final dir = Directory(dirPath);
      if (dir.existsSync()) {
        _scanDirectory(dir);
      }
    }

    _songs.sort((a, b) => a['title'].compareTo(b['title']));
    notifyListeners();
  }

  void _scanDirectory(Directory dir) {
    try {
      dir.listSync().forEach((entity) {
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
          _scanDirectory(entity);
        }
      });
    } catch (e) {
      // Skip inaccessible directories
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
