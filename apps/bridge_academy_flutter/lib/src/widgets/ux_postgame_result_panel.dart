import 'package:bridge_core/bridge_core.dart' hide Card;
import 'package:flutter/material.dart';

import '../app_copy.dart';

/// Terminal-only public projection. Never receives the hidden Deal or PBN.
class PostgameResult {
  const PostgameResult._({
    required this.boardNumber,
    required this.dealer,
    required this.vulnerability,
    required this.contract,
    required this.declarerTricks,
    required this.humanScore,
    required this.isJustDeclare,
  });

  factory PostgameResult.fromFinishedView({
    required PlayerView view,
    required int boardNumber,
    required bool isJustDeclare,
  }) {
    if (view.phase != Phase.finished || view.nsScore == null) {
      throw StateError('Postgame summary requires a Core terminal result');
    }
    final contract = view.contract;
    if (contract != null && view.completedTricks.length != 13) {
      throw StateError('Contracted deal must have 13 completed tricks');
    }
    if (contract == null && view.completedTricks.isNotEmpty) {
      throw StateError('Pass Out cannot have completed tricks');
    }
    return PostgameResult._(
      boardNumber: boardNumber,
      dealer: view.dealer,
      vulnerability: view.vulnerability,
      contract: contract,
      declarerTricks: contract == null
          ? null
          : view.completedTricks
              .where((trick) => trick.winner.isNS == contract.declarer.isNS)
              .length,
      humanScore: view.viewer.isNS ? view.nsScore! : -view.nsScore!,
      isJustDeclare: isJustDeclare,
    );
  }

  final int boardNumber;
  final Seat dealer;
  final Vulnerability vulnerability;
  final Contract? contract;
  final int? declarerTricks;
  final int humanScore;
  final bool isJustDeclare;
  bool get isPassOut => contract == null;
  int? get target => contract?.targetTricks;
  int? get trickDifference => contract == null
      ? null : declarerTricks! - contract!.targetTricks;
}

enum PostgameAdvance { nextBoard, fourBoard, dailyBoard, none }

/// The parent owns sessions/navigation. This widget invokes only callbacks.
class UxPostgameResultPanel extends StatelessWidget {
  const UxPostgameResultPanel({
    super.key,
    required this.copy,
    required this.result,
    required this.advance,
    required this.canChangeBoard,
    required this.canReview,
    required this.canHistory,
    required this.canRetry,
    required this.reviewFocused,
    required this.onNext,
    required this.onRetry,
    required this.onReview,
    required this.onHistory,
    required this.onBackToResult,
    required this.blocked,
  });

  final AppCopy copy;
  final PostgameResult result;
  final PostgameAdvance advance;
  final bool canChangeBoard;
  final bool canReview;
  final bool canHistory;
  final bool canRetry;
  final bool reviewFocused;
  final bool blocked;
  final VoidCallback onNext;
  final VoidCallback onRetry;
  final VoidCallback onReview;
  final VoidCallback onHistory;
  final VoidCallback onBackToResult;

  String _advanceLabel() => switch (advance) {
    PostgameAdvance.nextBoard => 'nextBoard',
    PostgameAdvance.fourBoard => 'practiceFourNext',
    PostgameAdvance.dailyBoard => 'dailyNext',
    PostgameAdvance.none => 'ux02_noNext',
  };
  String _advanceKey() => switch (advance) {
    PostgameAdvance.nextBoard => 'next_board',
    PostgameAdvance.fourBoard => 'next_practice_board',
    PostgameAdvance.dailyBoard => 'next_daily_board',
    PostgameAdvance.none => 'ux02_no_next',
  };

  @override
  Widget build(BuildContext context) {
    final contract = result.contract;
    final difference = result.trickDifference;
    return Card(
      key: const Key('final_result'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(copy.t('end'), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(copy.boardNumber(result.boardNumber),
                key: const Key('ux02_board_number')),
            Text(copy.dealer(result.dealer.letter)),
            Text(copy.vulnerability(result.vulnerability.name)),
            if (result.isJustDeclare)
              Text(copy.t('ux02_justDeclare'),
                  key: const Key('ux02_declarer_practice')),
            if (contract == null)
              Text(copy.t('passOut'), key: const Key('ux02_pass_out'))
            else ...[
              Text(copy.contract(contract.label),
                  key: const Key('ux02_contract')),
              Text('${copy.t('ux02_declarer')}: '
                  '${copy.seat(contract.declarer.letter)}',
                  key: const Key('ux02_declarer')),
              Text('${copy.t('ux02_tricks')}: '
                  '${result.declarerTricks} / ${result.target}',
                  key: const Key('ux02_tricks')),
              Text(
                '${copy.t(difference! >= 0 ? 'ux02_made' : 'ux02_down')}: '
                '${difference >= 0 ? '+' : ''}$difference',
                key: const Key('ux02_outcome'),
              ),
            ],
            const SizedBox(height: 6),
            Text('${copy.t('ux02_yourScore')}: '
                '${result.humanScore > 0 ? '+' : ''}${result.humanScore}',
                key: const Key('ux02_human_score'),
                style: Theme.of(context).textTheme.titleMedium),
            Text(copy.t('ux02_rawScoreDisclaimer'),
                style: Theme.of(context).textTheme.bodySmall),
            if (blocked) ...[
              const SizedBox(height: 8),
              Text(copy.t('ux02_saveBlocked'),
                  key: const Key('ux02_guard'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (advance != PostgameAdvance.none)
                  FilledButton.icon(
                    key: Key(_advanceKey()),
                    onPressed: canChangeBoard ? onNext : null,
                    icon: const Icon(Icons.skip_next),
                    label: Text(copy.t(_advanceLabel())),
                  ),
                if (canRetry)
                  OutlinedButton.icon(
                    key: const Key('replay_same_board'),
                    onPressed: canChangeBoard ? onRetry : null,
                    icon: const Icon(Icons.replay),
                    label: Text(copy.t('replaySameBoard')),
                  ),
                OutlinedButton.icon(
                  key: const Key('ux02_open_review'),
                  onPressed: canReview ? onReview : null,
                  icon: const Icon(Icons.history_edu),
                  label: Text(copy.t('ux02_review')),
                ),
                TextButton.icon(
                  key: const Key('ux02_open_history'),
                  onPressed: canHistory ? onHistory : null,
                  icon: const Icon(Icons.history),
                  label: Text(copy.t('ux02_history')),
                ),
                if (reviewFocused)
                  TextButton.icon(
                    key: const Key('ux02_back_to_result'),
                    onPressed: onBackToResult,
                    icon: const Icon(Icons.arrow_back),
                    label: Text(copy.t('ux02_backToResult')),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
