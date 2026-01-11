import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  FlutterSoundRecorder? _recorder;
  String? _recordingPath;
  bool _isRecording = false;
  bool _isInitialized = false;

  bool get isRecording => _isRecording;
  String? get recordingPath => _recordingPath;
  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      _recorder = FlutterSoundRecorder();
      await _recorder!.openRecorder();
      _isInitialized = true;
      debugPrint('✅ Audio recorder инициализирован');
    } catch (e) {
      debugPrint('❌ Ошибка инициализации recorder: $e');
    }
  }
  Future<bool> requestPermission() async {
    try {
      final status = await Permission.microphone.request();
      
      if (status.isDenied) {
        debugPrint('❌ Разрешение на микрофон отклонено');
        return false;
      }
      
      if (status.isPermanentlyDenied) {
        debugPrint('❌ Разрешение на микрофон запрещено навсегда');
        await openAppSettings();
        return false;
      }
      
      debugPrint('✅ Разрешение на микрофон получено');
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка запроса разрешения: $e');
      return false;
    }
  }
  Future<bool> startRecording() async {
    try {
      if (!_isInitialized) {
        await init();
      }
      if (!await requestPermission()) {
        return false;
      }
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _recordingPath = '${dir.path}/sos_audio_$timestamp.aac';
      await _recorder!.startRecorder(
        toFile: _recordingPath,
        codec: Codec.aacADTS,
      );
      
      _isRecording = true;
      debugPrint('✅ Запись аудио начата: $_recordingPath');
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка начала записи: $e');
      return false;
    }
  }
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording || _recorder == null) {
        debugPrint('⚠️ Запись не была начата');
        return null;
      }

      final path = await _recorder!.stopRecorder();
      _isRecording = false;
      
      if (path != null) {
        debugPrint('✅ Запись остановлена: $path');
        _recordingPath = path;
        final file = File(path);
        if (await file.exists()) {
          final size = await file.length();
          debugPrint('📁 Размер файла: ${size / 1024} KB');
        }
        
        return path;
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Ошибка остановки записи: $e');
      _isRecording = false;
      return null;
    }
  }
  Future<void> cancelRecording() async {
    try {
      if (_isRecording && _recorder != null) {
        await _recorder!.stopRecorder();
        _isRecording = false;
      }
      if (_recordingPath != null) {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      _recordingPath = null;
      debugPrint('✅ Запись отменена');
    } catch (e) {
      debugPrint('❌ Ошибка отмены записи: $e');
    }
  }
  Future<bool> sendAudioToTelegram({
    required String botToken,
    required String chatId,
    required String audioPath,
    String? caption,
  }) async {
    try {
      final file = File(audioPath);
      
      if (!await file.exists()) {
        debugPrint('❌ Файл не найден: $audioPath');
        return false;
      }
      final fileSize = await file.length();
      debugPrint('📁 Размер файла для отправки: ${fileSize / 1024} KB');
      final url = Uri.parse(
        'https://api.telegram.org/bot$botToken/sendAudio'
      );
      final request = http.MultipartRequest('POST', url);
      
      request.fields['chat_id'] = chatId;
      if (caption != null) {
        request.fields['caption'] = caption;
      }
      request.files.add(
        await http.MultipartFile.fromPath(
          'audio',
          audioPath,
          filename: 'sos_audio.aac',
        ),
      );
      debugPrint('📤 Отправка аудио в Telegram (chat_id: $chatId)...');
      final response = await request.send();
      
      if (response.statusCode == 200) {
        debugPrint('✅ Аудио отправлено в Telegram');
        return true;
      } else {
        final responseBody = await response.stream.bytesToString();
        debugPrint('❌ Ошибка Telegram API: ${response.statusCode}');
        debugPrint('Response: $responseBody');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Ошибка отправки в Telegram: $e');
      return false;
    }
  }
  Future<void> cleanupOldRecordings() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final files = dir.listSync()
          .where((e) => e.path.contains('sos_audio_'))
          .toList();
      final now = DateTime.now();
      int deleted = 0;
      
      for (final file in files) {
        final stat = await File(file.path).stat();
        final age = now.difference(stat.modified);
        
        if (age.inHours > 24) {
          await File(file.path).delete();
          deleted++;
        }
      }
      
      if (deleted > 0) {
        debugPrint('🗑️ Удалено старых записей: $deleted');
      }
    } catch (e) {
      debugPrint('❌ Ошибка очистки: $e');
    }
  }
  Future<void> dispose() async {
    try {
      if (_recorder != null) {
        if (_isRecording) {
          await _recorder!.stopRecorder();
        }
        await _recorder!.closeRecorder();
        _recorder = null;
        _isInitialized = false;
        debugPrint('✅ Audio recorder освобожден');
      }
    } catch (e) {
      debugPrint('❌ Ошибка dispose: $e');
    }
  }
}