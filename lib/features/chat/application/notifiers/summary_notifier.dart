import 'package:chattery/features/chat/data/summary_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chattery/core/models/message.dart';
import 'package:chattery/features/chat/data/chat_repository.dart';

class SummaryState {
  final String? summary;
  final bool isLoading;

  SummaryState({this.summary, this.isLoading = false});

  SummaryState copyWith({String? summary, bool? isLoading}) {
    return SummaryState(
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SummaryNotifier extends StateNotifier<SummaryState> {
  final SummaryRepository _summaryRepository;

  SummaryNotifier(this._summaryRepository) : super(SummaryState());

  Future<void> updateSummary(List<Message> messages) async {
    if (messages.isEmpty) {
      state = SummaryState(summary: null, isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final String generatedSummary =
      await _summaryRepository.generateSummary(messages);

      state = state.copyWith(
        summary: generatedSummary.isEmpty ? "Summary being processed..." : generatedSummary,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      debugPrint("Summary update error: $e");
    }
  }

  void clearSummary() {
    state = SummaryState(summary: null, isLoading: false);
  }
}