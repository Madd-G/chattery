// ignore_for_file: unused_import

import 'package:chattery/core/models/message.dart';
import 'package:chattery/features/chat/data/chat_repository.dart';
import 'package:chattery/features/chat/data/hints_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HintsState {
  final List<String>? hints;
  final bool isLoading;

  HintsState({this.hints, this.isLoading = false});

  HintsState copyWith({List<String>? hints, bool? isLoading}) {
    return HintsState(
      hints: hints ?? this.hints,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class HintsNotifier extends StateNotifier<HintsState> {
  final HintsRepository _hintRepository;

  HintsNotifier(this._hintRepository) : super(HintsState());

  Future<void> updateHints(List<Message> messages) async {
    if (messages.isEmpty) {
      state = HintsState(hints: [], isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final List<String> generatedHints = await _hintRepository.generateHints(
        messages,
      );

      state = state.copyWith(hints: generatedHints, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      debugPrint("Hints update error: $e");
    }
  }

  void clearHints() {
    state = HintsState(hints: [], isLoading: false);
  }
}
