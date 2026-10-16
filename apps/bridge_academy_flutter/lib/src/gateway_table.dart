import 'package:bridge_core/bridge_core.dart' hide Card;
import 'package:flutter/material.dart';

import 'app_copy.dart';
import 'gateway_game_session.dart';
import 'widgets/bridge_bidding_box.dart';
import 'widgets/bridge_table_components.dart';
import 'widgets/bridge_table_toolbar.dart';

/// Explicitly opted-in server-owned table. Unlike local Demo/BEN, no
/// in-process Coordinator/Deal or local replay exists in this screen.
class GatewayTable extends StatefulWidget {
  const GatewayTable({super.key, required this.session, required this.copy});
  final GatewayGameSession session;
  final AppCopy copy;

  @override
  State<GatewayTable> createState() => _GatewayTableState();
}

class _GatewayTableState extends State<GatewayTable> {
  int _level = 1;
  Strain _strain = Strain.notrump;

  @override
  Widget build(BuildContext context) {
    final copy = widget.copy;
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final session = widget.session;
        final view = session.view;
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(copy.t('gatewayNotice'),
                    key: const Key('gateway_mode_notice')),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      key: const Key('gateway_start'),
                      onPressed: session.busy
                          ? null : session.startNewGame,
                      icon: const Icon(Icons.cloud_outlined),
                      label: Text(copy.t('gatewayNewSession')),
                    ),
                    OutlinedButton.icon(
                      key: const Key('gateway_refresh'),
                      onPressed: session.busy || !session.started
                          ? null : session.refreshServerView,
                      icon: const Icon(Icons.sync),
                      label: Text(copy.t('gatewayRefresh')),
                    ),
                  ],
                ),
                if (session.busy) ...[
                  const LinearProgressIndicator(
                      key: Key('gateway_pending_progress')),
                  Text(copy.t('gatewayWaiting')),
                ],
                if (session.errorCode != null) ...[
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(copy.t(session.errorCode!),
                              key: const Key('gateway_error_message')),
                          if (!session.busy && session.started)
                            OutlinedButton(
                              key: const Key('gateway_retry'),
                              onPressed: session.retry,
                              child: Text(copy.t('gatewayRetry')),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (view == null) ...[
                  const SizedBox(height: 24),
                  Text(copy.t('gatewayNotStarted'),
                      key: const Key('gateway_empty')),
                ] else ...[
                  const SizedBox(height: 12),
                  BridgeBoardHeader(
                    boardNumber: 1,
                    view: view,
                    busy: session.busy,
                    copy: copy,
                  ),
                  BridgeTableSurface(
                    view: view,
                    copy: copy,
                    actionsPaused: session.actionsPaused,
                    onPlayCard: session.submitCard,
                  ),
                  BridgeTableToolbar(view: view, copy: copy),
                  if (view.phase == Phase.auction)
                    BridgeBiddingBox(
                      copy: copy,
                      selectedLevel: _level,
                      selectedStrain: _strain,
                      canSubmit: view.canAct && !session.actionsPaused,
                      onLevelChanged: (value) =>
                          setState(() => _level = value),
                      onStrainChanged: (value) =>
                          setState(() => _strain = value),
                      onSubmitCall: session.submitCall,
                    ),
                  if (view.phase == Phase.play)
                    BridgePlayerHand(
                      view: view,
                      copy: copy,
                      actionsPaused: session.actionsPaused,
                      onPlayCard: session.submitCard,
                    ),
                  if (session.finished)
                    Card(
                      key: const Key('gateway_final_result'),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(copy.t('end')),
                            if (view.contract == null)
                              Text(copy.t('passOut'))
                            else
                              Text(copy.contract(view.contract!.label)),
                            if (view.nsScore != null)
                              Text(copy.score(view.nsScore!)),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
