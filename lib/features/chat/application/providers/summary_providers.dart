import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chattery/features/chat/application/notifiers/summary_notifier.dart';
import 'package:chattery/features/chat/application/providers/chat_providers.dart'; // For chatRepositoryProvider

final summaryNotifierProvider = StateNotifierProvider<SummaryNotifier, SummaryState>((ref) {
  final chatRepository = ref.watch(chatRepositoryProvider);
  return SummaryNotifier(chatRepository);
});