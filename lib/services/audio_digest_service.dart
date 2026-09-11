import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum TtsAudioState { stopped, playing, paused }

class AudioDigestService with ChangeNotifier {
  static final AudioDigestService _instance = AudioDigestService._internal();
  factory AudioDigestService() => _instance;

  AudioDigestService._internal() {
    _initChannel();
  }

  static const MethodChannel _channel = MethodChannel('com.powernews.app/tts');

  TtsAudioState _state = TtsAudioState.stopped;
  double _speechRate = 1.0;
  String? _currentlyPlayingText;
  int _currentStoryIndex = 0;

  TtsAudioState get state => _state;
  bool get isPlaying => _state == TtsAudioState.playing;
  bool get isPaused => _state == TtsAudioState.paused;
  bool get isStopped => _state == TtsAudioState.stopped;
  double get speechRate => _speechRate;
  int get currentStoryIndex => _currentStoryIndex;
  String? get currentlyPlayingText => _currentlyPlayingText;

  void _initChannel() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onStart':
          _state = TtsAudioState.playing;
          notifyListeners();
          break;
        case 'onDone':
          _state = TtsAudioState.stopped;
          notifyListeners();
          break;
        case 'onError':
          _state = TtsAudioState.stopped;
          notifyListeners();
          break;
      }
    });
  }

  Future<void> playAudioScript(String script) async {
    if (script.trim().isEmpty) return;
    try {
      _currentlyPlayingText = script;
      _state = TtsAudioState.playing;
      notifyListeners();

      await _channel.invokeMethod('speak', {
        'text': script,
        'rate': _speechRate,
      });
    } catch (e) {
      debugPrint('[AudioDigest] Play error: $e');
      _state = TtsAudioState.stopped;
      notifyListeners();
    }
  }

  Future<void> pauseAudio() async {
    try {
      await _channel.invokeMethod('stop');
      _state = TtsAudioState.paused;
      notifyListeners();
    } catch (e) {
      debugPrint('[AudioDigest] Pause error: $e');
    }
  }

  Future<void> stopAudio() async {
    try {
      await _channel.invokeMethod('stop');
      _state = TtsAudioState.stopped;
      notifyListeners();
    } catch (e) {
      debugPrint('[AudioDigest] Stop error: $e');
    }
  }

  Future<void> setRate(double rate) async {
    _speechRate = rate;
    try {
      await _channel.invokeMethod('setRate', {'rate': rate});
    } catch (_) {}
    notifyListeners();
  }

  void setCurrentStoryIndex(int index) {
    _currentStoryIndex = index;
    notifyListeners();
  }
}
