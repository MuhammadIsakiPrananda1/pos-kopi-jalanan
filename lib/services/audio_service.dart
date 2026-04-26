import 'package:audioplayers/audioplayers.dart';

class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final AudioPlayer _player = AudioPlayer();
  bool _initialized = false;

  Future<void> init() async {
    try {
      _initialized = true;
    } catch (e) {
      _initialized = false;
    }
  }

  Future<void> playSuccess() async {
    if (!_initialized) return;
    try {
      await _player.play(AssetSource('sounds/success.mp3'));
    } catch (e) {
      // Silent fallback jika asset belum ada
    }
  }

  void dispose() {
    _player.dispose();
  }
}
