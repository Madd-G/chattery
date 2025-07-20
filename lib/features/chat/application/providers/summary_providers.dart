import 'package:chattery/features/chat/data/summary_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chattery/features/chat/application/notifiers/summary_notifier.dart';

final summaryRepositoryProvider = Provider<SummaryRepository>((ref) {
  return SummaryRepositoryImpl();
});

final summaryNotifierProvider =
    StateNotifierProvider<SummaryNotifier, SummaryState>((ref) {
      final hintsRepository = ref.watch(summaryRepositoryProvider);
      return SummaryNotifier(hintsRepository);
    });
