import 'package:chattery/features/chat/application/notifiers/hints_notifier.dart';
import 'package:chattery/features/chat/data/hints_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final hintsRepositoryProvider = Provider<HintsRepository>((ref) {
  return HintsRepositoryImpl();
});

final hintsNotifierProvider = StateNotifierProvider<HintsNotifier, HintsState>((
  ref,
) {
  final hintsRepository = ref.watch(hintsRepositoryProvider);
  return HintsNotifier(hintsRepository);
});
