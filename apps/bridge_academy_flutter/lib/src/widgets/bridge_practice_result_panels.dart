import 'package:flutter/material.dart';
import 'package:bridge_core/bridge_core.dart' hide Card;
import '../app_copy.dart';
import '../bridge_session.dart';
import '../conventions/convention_profile.dart';
import 'bidding_convention_panel.dart';

class BridgeBiddingPracticePanel extends StatelessWidget {
  const BridgeBiddingPracticePanel({super.key, required this.session, required this.copy});
  final BridgeSession session;
  final AppCopy copy;
  @override
  Widget build(BuildContext context) {
    final view = session.view!;
    final complete = session.biddingPracticeComplete;
    return Card(
      key: const Key('bidding_practice_panel'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(copy.t('biddingTitle'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(copy.t('biddingScope')),
            BiddingConventionPanel(
              contextData: BidContext.fromView(view),
              copy: copy,
            ),
            if (!complete && session.biddingSuggestion != null)
              Text("${copy.t('biddingHint')}: ${session.biddingSuggestion!.code}",
                  key: const Key('bidding_suggestion')),
            if (complete) ...[
              Text(copy.t('biddingFinished'),
                  key: const Key('bidding_finished')),
              Text(copy.contract(view.contract?.label ?? 'PASS OUT')),
            ],
          ],
        ),
      ),
    );
  }
}

class BridgeFourBoardPanel extends StatelessWidget {
  const BridgeFourBoardPanel({super.key, required this.session, required this.copy});
  final BridgeSession session;
  final AppCopy copy;
  @override
  Widget build(BuildContext context) {
    final practice = session.fourBoardPractice!;
    return Card(
      key: const Key('four_board_panel'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(copy.t('practiceFourTitle'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('${copy.t('practiceFourCompleted')}: '
                '${practice.completed} / 4',
                key: const Key('four_board_progress')),
            Text('${copy.t('practiceFourHumanScore')}: '
                '${practice.humanNetScore > 0 ? '+' : ''}'
                '${practice.humanNetScore}',
                key: const Key('four_board_score')),
            Text(copy.t('practiceFourScope')),
            for (final result in practice.results)
              ListTile(
                dense: true,
                title: Text('${copy.boardNumber(result.boardNumber)} · '
                    '${result.contract}'),
                trailing: Text('${practice.humanSeat.isNS
                    ? result.nsScore : -result.nsScore}'),
              ),
            if (practice.isComplete)
              Text(copy.t('practiceFourFinished'),
                  key: const Key('four_board_finished'))
            else if (!session.finished)
              Text(copy.t('practiceFourCurrent')),
          ],
        ),
      ),
    );
  }
}

class BridgeFinalResultCard extends StatelessWidget {
  const BridgeFinalResultCard({super.key, required this.view, required this.copy});
  final PlayerView view;
  final AppCopy copy;
  @override
  Widget build(BuildContext context) {
    return Card(
        key: const Key('final_result'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(copy.t('end'), style: Theme.of(context).textTheme.titleLarge),
              if (view.contract == null) Text(copy.t('passOut')),
              if (view.contract != null)
                Text(copy.contract(view.contract!.label)),
              if (view.nsScore != null) Text(copy.score(view.nsScore!)),
            ],
          ),
        ),
      );
  }
}


/// Contract goal and success state in just-declare practice.
class BridgeJustDeclareProgressCard extends StatelessWidget {
  const BridgeJustDeclareProgressCard({super.key, required this.session, required this.copy});
  final BridgeSession session;
  final AppCopy copy;

  @override
  Widget build(BuildContext context) {
    final view = session.view;
    final trainingContract = session.isJustDeclare ? view?.contract : null;
    final declarerTricks = trainingContract == null || view == null
        ? 0
        : view.completedTricks.where(
            (trick) => trick.winner.isNS == trainingContract.declarer.isNS,
          ).length;
    return Card(
                          key: const Key('just_declare_active'),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(copy.t('justDeclareActive')),
                                if (trainingContract != null) ...[
                                  Text(
                                    '${copy.t('justDeclareDeclarer')}: '
                                    '${copy.seat(trainingContract.declarer.letter)}',
                                  ),
                                  Text(
                                    '${copy.t('justDeclareDummy')}: '
                                    '${copy.seat(trainingContract.dummy.letter)}',
                                  ),
                                  Text(
                                    copy.justDeclareProgress(
                                      declarerTricks,
                                      trainingContract.targetTricks,
                                    ),
                                    key: const Key('just_declare_goal'),
                                  ),
                                  if (session.finished)
                                    Text(
                                      copy.t(
                                        declarerTricks >=
                                                trainingContract.targetTricks
                                            ? 'justDeclareMade'
                                            : 'justDeclareDown',
                                      ),
                                      key: const Key('just_declare_outcome'),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        );
  }
}
