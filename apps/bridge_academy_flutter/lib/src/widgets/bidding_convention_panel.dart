import 'package:flutter/material.dart';

import '../app_copy.dart';
import '../conventions/convention_profile.dart';

/// Public-auction teaching only: no private hands, no BEN configuration.
class BiddingConventionPanel extends StatefulWidget {
  const BiddingConventionPanel({
    super.key,
    required this.contextData,
    required this.copy,
  });

  final BidContext contextData;
  final AppCopy copy;

  @override
  State<BiddingConventionPanel> createState() => _BiddingConventionPanelState();
}

class _BiddingConventionPanelState extends State<BiddingConventionPanel> {
  bool _showProposals = false;

  @override
  Widget build(BuildContext context) {
    final profile = _showProposals
        ? ConventionProfiles.preview
        : ConventionProfiles.basic;
    final explanation = ConventionExplanationEngine.resolve(
      widget.contextData,
      profile: profile,
      expectedRevision: profile.revision,
    );
    final copy = widget.copy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${copy.t('b3ProfileLabel')}: ${profile.id} r${profile.revision}",
          key: const Key('b3_profile_revision'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              FilterChip(
                key: const Key('b3_preview_toggle'),
                label: Text(copy.t('b3PreviewToggle')),
                selected: _showProposals,
                onSelected: (enabled) =>
                    setState(() => _showProposals = enabled),
              ),
              Text(
                copy.t('b3Unreviewed'),
                key: const Key('b3_review_status'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (_showProposals)
          Text(
            copy.t('b3PreviewDisclaimer'),
            key: const Key('b3_preview_disclaimer'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        if (widget.contextData.auction.isNotEmpty) ...[
          Text(
            copy.t(explanation.meaningKey),
            key: const Key('bidding_explanation'),
          ),
          if (explanation.matched) ...[
            Text("${copy.t('b3RuleId')}: ${explanation.ruleId!}",
                key: const Key('b3_rule_id')),
            Text(copy.t(explanation.assumptionKey),
                key: const Key('b3_assumptions')),
            Text("${copy.t('b3Source')}: ${explanation.reference!}",
                key: const Key('b3_source')),
            if (explanation.preview)
              Text(copy.t('b3PreviewOnly'),
                  key: const Key('b3_preview_only')),
          ] else
            Text(copy.t('b3NoRule'), key: const Key('b3_convention_unknown')),
        ],
      ],
    );
  }
}
