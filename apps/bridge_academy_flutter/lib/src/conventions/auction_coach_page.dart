import 'package:bridge_conventions/bridge_conventions.dart';
import 'package:flutter/material.dart';

import '../app_copy.dart';
import 'custom_draft_store.dart';

/// Evidence-aware M5 teaching sandbox: public calls only, not live robot
/// reasoning, not recommended bids, no PlayerView/Deal/hand access.
class AuctionCoachPage extends StatefulWidget {
  const AuctionCoachPage({super.key, required this.isEnglish, this.storage});

  final bool isEnglish;
  final CustomDraftStorage? storage;

  @override
  State<AuctionCoachPage> createState() => _AuctionCoachPageState();
}

class _AuctionCoachPageState extends State<AuctionCoachPage> {
  late final CustomDraftStorage _store =
      widget.storage ?? SharedPrefsCustomDraftStorage();
  final TextEditingController _calls = TextEditingController(text: '1NT P 2C');
  PartnershipSystem _ns = ConventionCatalog.sayc;
  PartnershipSystem _ew = ConventionCatalog.twoOverOne;
  String _dealer = 'N';
  CoachAuctionReport? _report;
  bool _includeLocalDraft = false;
  bool _busy = false;
  String? _error;

  AppCopy get copy => AppCopy(widget.isEnglish);

  @override
  void dispose() {
    _calls.dispose();
    super.dispose();
  }

  Future<void> _explain() async {
    setState(() {
      _busy = true;
      _error = null;
      _report = null;
    });
    try {
      final values = _calls.text.trim();
      if (values.length > 256) {
        throw const FormatException('Unbounded auction');
      }
      final calls = values.isEmpty
          ? <String>[]
          : values.toUpperCase().split(RegExp(r'[-\s]+'));
      CustomConventionDraft? draft;
      if (_includeLocalDraft &&
          (_ns == ConventionCatalog.sayc ||
              _ns == ConventionCatalog.twoOverOne)) {
        final saved = await _store.load(_ns.profileId);
        draft = saved.latest;
        if (draft != null && draft.rules.isEmpty) draft = null;
      }
      final report = PublicAuctionCoach.review(
        dealer: _dealer,
        calls: calls,
        systems: GameSystems(northSouth: _ns, eastWest: _ew),
        draft: draft,
        draftNorthSouth: draft == null ? null : true,
      );
      if (!mounted) return;
      setState(() => _report = report);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'm5InvalidAuction');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profiles = [
      ConventionCatalog.sayc, ConventionCatalog.twoOverOne,
      ConventionCatalog.precisionMeckwell,
    ];
    return Scaffold(
      appBar: AppBar(title: Text(copy.t('m5CoachTitle'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(copy.t('m5CoachDisclaimer'),
                key: const Key('m5_disclaimer')),
            const SizedBox(height: 12),
            Text(copy.t('m5NorthSouth')),
            DropdownButton<PartnershipSystem>(
              key: const Key('m5_ns'),
              isExpanded: true,
              value: _ns,
              items: [
                for (final profile in profiles)
                  DropdownMenuItem(
                    value: profile,
                    child: Text(copy.t(_profileKey(profile))),
                  ),
              ],
              onChanged: _busy ? null :
                  (system) => setState(() => _ns = system!),
            ),
            Text(copy.t('m5EastWest')),
            DropdownButton<PartnershipSystem>(
              key: const Key('m5_ew'),
              isExpanded: true,
              value: _ew,
              items: [
                for (final profile in profiles)
                  DropdownMenuItem(
                    value: profile,
                    child: Text(copy.t(_profileKey(profile))),
                  ),
              ],
              onChanged: _busy ? null :
                  (system) => setState(() => _ew = system!),
            ),
            Text(copy.t('m5Dealer')),
            DropdownButton<String>(
              key: const Key('m5_dealer'),
              value: _dealer,
              isExpanded: true,
              items: [
                for (final seat in const ['N', 'E', 'S', 'W'])
                  DropdownMenuItem(value: seat, child: Text(copy.seat(seat))),
              ],
              onChanged: _busy ? null :
                  (seat) => setState(() => _dealer = seat!),
            ),
            TextField(
              key: const Key('m5_public_auction'),
              controller: _calls,
              decoration: InputDecoration(
                labelText: copy.t('m5Auction'),
                helperText: copy.t('m5AuctionExample'),
              ),
              maxLength: 256,
              maxLines: 2,
            ),
            if (_ns == ConventionCatalog.sayc ||
                _ns == ConventionCatalog.twoOverOne)
              CheckboxListTile(
                key: const Key('m5_local_draft'),
                title: Text(copy.t('m5DraftToggle')),
                subtitle: Text(copy.t('m5DraftDisclaimer')),
                value: _includeLocalDraft,
                onChanged: _busy ? null :
                    (value) => setState(() => _includeLocalDraft = value!),
              ),
            FilledButton.icon(
              key: const Key('m5_explain'),
              onPressed: _busy ? null : _explain,
              icon: const Icon(Icons.fact_check_outlined),
              label: Text(copy.t('m5Explain')),
            ),
            if (_busy) const LinearProgressIndicator(),
            if (_error != null)
              Text(copy.t(_error!), key: const Key('m5_error')),
            if (_report != null) ...[
              const Divider(),
              Text(copy.t('m5Results'), key: const Key('m5_results')),
              Text(copy.t('m5NoRecommendations'),
                  key: const Key('m5_no_recommendations')),
              SelectableText(_report!.gameSystemsFingerprint,
                  key: const Key('m5_game_fingerprint')),
              if (_report!.draftFingerprint != null)
                Text(copy.t('m5DraftOnly'),
                    key: const Key('m5_draft_disclaimer')),
              for (final entry in _report!.entries)
                ListTile(
                  key: Key('m5_entry_${entry.index}'),
                  title: Text('${copy.seat(entry.seat)}: ${entry.call}'),
                  subtitle: Text([
                    entry.profileId,
                    entry.userSelectedMeaning == null
                        ? copy.t(entry.evidence ==
                            CoachMeaningEvidence.baseNotReviewed
                              ? 'm5BaseUnreviewed' : 'm5Unknown')
                        : '${copy.t('m5AuthorMeaning')}: '
                          '${copy.t('m4choice_${entry.userSelectedMeaning}')}; '
                          '${copy.t('m5DraftOnly')}',
                  ].join(' · ')),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _profileKey(PartnershipSystem profile) {
    if (profile == ConventionCatalog.sayc) return 'gatewaySystemSAYC';
    if (profile == ConventionCatalog.twoOverOne) return 'gatewaySystem21GF';
    return 'gatewaySystemPrecisionResearch';
  }
}
