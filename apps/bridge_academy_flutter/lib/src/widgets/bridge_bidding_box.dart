import 'package:bridge_core/bridge_core.dart' hide Card;
import 'package:flutter/material.dart';

import '../app_copy.dart';

/// Controlled auction UI. The caller owns the selection; Bridge Core owns
/// legality and session state. An enabled call is not necessarily a legal call
/// until the reducer accepts it. Selectors are direct Wrap children to avoid
/// horizontal Row overflow at 320px. A future Core legalCalls projection can
/// disable individual calls without duplicating auction rules in Flutter.
class BridgeBiddingBox extends StatelessWidget {
  const BridgeBiddingBox({
    super.key,
    required this.copy,
    required this.selectedLevel,
    required this.selectedStrain,
    required this.canSubmit,
    required this.onLevelChanged,
    required this.onStrainChanged,
    required this.onSubmitCall,
  });

  final AppCopy copy;
  final int selectedLevel;
  final Strain selectedStrain;
  final bool canSubmit;
  final ValueChanged<int> onLevelChanged;
  final ValueChanged<Strain> onStrainChanged;
  final ValueChanged<Call> onSubmitCall;

  @override
  Widget build(BuildContext context) => Card(
    key: const Key('auction_controls'),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Tooltip(
              message: copy.t('level'),
              child: DropdownButton<int>(
                key: const Key('bid_level'),
                value: selectedLevel,
                items: [
                  for (var n = 1; n <= 7; n++)
                    DropdownMenuItem(value: n, child: Text('$n')),
                ],
                onChanged: canSubmit
                    ? (n) {
                        if (n != null) onLevelChanged(n);
                      }
                    : null,
              ),
            ),
            Tooltip(
              message: copy.t('strain'),
              child: SizedBox(
                width: 220,
                child: DropdownButton<Strain>(
                  key: const Key('bid_strain'),
                  isExpanded: true,
                  value: selectedStrain,
                  items: [
                    for (final strain in Strain.values)
                      DropdownMenuItem(
                        value: strain,
                        child: Text(
                          copy.t(bridgeStrainKey(strain)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: canSubmit
                      ? (strain) {
                          if (strain != null) onStrainChanged(strain);
                        }
                      : null,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
              key: const Key('make_bid'),
              onPressed: canSubmit
                  ? () => onSubmitCall(Bid(selectedLevel, selectedStrain))
                  : null,
              child: Text(copy.t('call')),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
              key: const Key('pass'),
              onPressed: canSubmit ? () => onSubmitCall(const Pass()) : null,
              child: Text(copy.t('pass')),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
              key: const Key('double'),
              onPressed: canSubmit
                  ? () => onSubmitCall(const DoubleCall())
                  : null,
              child: Text(copy.t('double')),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
              key: const Key('redouble'),
              onPressed: canSubmit
                  ? () => onSubmitCall(const RedoubleCall())
                  : null,
              child: Text(copy.t('redouble')),
            ),
          ],
        ),
      ),
    ),
  );
}

String bridgeStrainKey(Strain strain) => switch (strain) {
  Strain.clubs => 'strainC',
  Strain.diamonds => 'strainD',
  Strain.hearts => 'strainH',
  Strain.spades => 'strainS',
  Strain.notrump => 'strainNT',
};
