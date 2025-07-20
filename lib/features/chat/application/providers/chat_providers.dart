import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:chattery/core/services/tts_service.dart';
import 'package:chattery/features/chat/data/chat_repository.dart';
import 'package:chattery/features/chat/application/notifiers/chat_notifier.dart';

final _flutterTtsInstanceProvider = Provider<FlutterTts>((ref) => FlutterTts());

final ttsServiceProvider = Provider<TtsService>((ref) {
  final tts = ref.watch(_flutterTtsInstanceProvider);
  return FlutterTtsServiceImpl(tts);
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl();
});

final chatNotifierProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final chatRepository = ref.watch(chatRepositoryProvider);
  final ttsService = ref.watch(ttsServiceProvider);
  return ChatNotifier(ref, chatRepository, ttsService);
});