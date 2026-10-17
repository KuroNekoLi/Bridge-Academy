import 'package:flutter/material.dart';
import '../app_copy.dart';

/// A navigational view only: no access to hidden Deal, archive or BEN tokens.
class FirstPlayHome extends StatelessWidget {
  const FirstPlayHome({
    super.key, required this.copy, required this.canQuickStart,
    required this.canContinue, required this.gatewayConfigured,
    required this.gatewayInvalid, required this.busy,
    required this.warningKey, required this.onQuick,
    required this.onContinue, required this.onCustom,
    required this.onLearn, required this.onShort,
    required this.onDaily, required this.onReview,
  });
  final AppCopy copy;
  final bool canQuickStart, canContinue, gatewayConfigured, gatewayInvalid, busy;
  final String? warningKey;
  final VoidCallback onQuick, onContinue, onCustom, onLearn;
  final VoidCallback onShort, onDaily, onReview;

  Widget _tile(String key, IconData icon, String title, String hint,
      VoidCallback onTap) => Card(
    margin: EdgeInsets.zero,
    child: InkWell(
      key: Key(key),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 84),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Icon(icon, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(hint, maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            )),
            const Icon(Icons.chevron_right),
          ]),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => ListView(
    key: const Key('ux_home_screen'),
    padding: const EdgeInsets.all(16),
    children: [
      Text(copy.t('uxWelcome'),
          style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      Text(copy.t('uxGuestHint')),
      const SizedBox(height: 12),
      Text(copy.t(gatewayInvalid ? 'gatewayInvalidConfig' :
          gatewayConfigured ? 'uxGatewayStatus' : 'uxDemoStatus'),
          key: const Key('ux_mode_status')),
      if (warningKey != null) ...[
        const SizedBox(height: 12),
        Text(copy.t(warningKey!), key: const Key('ux_home_warning')),
      ],
      if (busy) const LinearProgressIndicator(key: Key('ux_home_pending')),
      const SizedBox(height: 12),
      if (canContinue) ...[
        _tile('ux_home_resume', Icons.play_arrow,
            copy.t('uxResume'), copy.t('uxResumeHint'), onContinue),
        const SizedBox(height: 12),
      ],
      if (gatewayConfigured && !gatewayInvalid) ...[
        _tile('ux_home_gateway', Icons.cloud_outlined,
            copy.t('uxGatewayOpen'), copy.t('uxGatewayStatus'), onCustom),
        const SizedBox(height: 12),
      ] else if (canQuickStart) ...[
        _tile('ux_home_quick_start', Icons.play_circle_outline,
            copy.t('uxQuickStart'), copy.t('uxQuickHint'), onQuick),
        const SizedBox(height: 12),
      ],
      LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth >= 640
            ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;
        return Wrap(spacing: 12, runSpacing: 12, children: [
          if (!gatewayConfigured && !gatewayInvalid)
            SizedBox(width: width, child: _tile('ux_home_custom', Icons.tune,
                copy.t('uxCustomPlay'), copy.t('uxCustomHint'), onCustom)),
          SizedBox(width: width, child: _tile('ux_home_learn',
              Icons.school_outlined, copy.t('uxLearn'),
              copy.t('uxLearnHint'), onLearn)),
          if (!gatewayConfigured && !gatewayInvalid) ...[
            SizedBox(width: width, child: _tile('ux_home_short',
                Icons.bolt_outlined, copy.t('uxShortPractice'),
                copy.t('uxShortHint'), onShort)),
            SizedBox(width: width, child: _tile('ux_home_daily',
                Icons.today_outlined, copy.t('uxDailyPractice'),
                copy.t('uxDailyHint'), onDaily)),
            SizedBox(width: width, child: _tile('ux_home_review',
                Icons.history, copy.t('uxReview'),
                copy.t('uxReviewHint'), onReview)),
          ],
        ]);
      }),
      const SizedBox(height: 12),
      Text(copy.t('uxNoCompetition'),
          style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}
