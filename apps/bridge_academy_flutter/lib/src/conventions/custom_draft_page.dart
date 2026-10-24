import 'package:bridge_conventions/bridge_conventions.dart';
import 'package:flutter/material.dart';

import '../app_copy.dart';
import 'custom_draft_store.dart';

/// M4 private convention-card editor. Every edited card stays unplayable:
/// user text/option selection is NEVER a BEN or BBA model capability.
class CustomConventionDraftPage extends StatefulWidget {
  const CustomConventionDraftPage({
    super.key, required this.isEnglish, this.storage,
  });

  final bool isEnglish;
  final CustomDraftStorage? storage;

  @override
  State<CustomConventionDraftPage> createState() =>
      _CustomConventionDraftPageState();
}

class _CustomConventionDraftPageState
    extends State<CustomConventionDraftPage> {
  late final CustomDraftStorage _storage =
      widget.storage ?? SharedPrefsCustomDraftStorage();
  PartnershipSystem _base = ConventionCatalog.sayc;
  CustomConventionArchive _archive = CustomConventionArchive.empty();
  CustomRuleSlot _slot = CustomRuleSlot.oneNotrumpOpening;
  String _choice = CustomRuleCatalog.choices[
      CustomRuleSlot.oneNotrumpOpening]!.first;
  bool _loading = true;
  String? _error;

  AppCopy get copy => AppCopy(widget.isEnglish);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final archive = await _storage.load(_base.profileId);
      if (!mounted) return;
      setState(() {
        _archive = archive;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        // A corrupted saved card is not overwritten without disclosure.
        _loading = false;
        _error = 'm4Corrupt';
      });
    }
  }

  CustomConventionDraft _newDraft() => CustomConventionDraft.create(
        id: _base == ConventionCatalog.sayc
            ? 'local_sayc' : 'local_21gf',
        label: _base == ConventionCatalog.sayc
            ? 'My SAYC' : 'My 2/1',
        base: _base,
      );

  Future<void> _commit({bool remove = false}) async {
    if (_loading || _error != null) return;
    setState(() => _loading = true);
    try {
      var archive = _archive;
      if (archive.latest == null) {
        archive = archive.append(_newDraft());
      }
      final old = archive.latest!;
      if (remove) {
        if (old.rules.any((rule) => rule.slot == _slot)) {
          archive = archive.append(old.withoutRule(_slot));
        }
      } else {
        final existing = old.rules.where((r) => r.slot == _slot);
        if (existing.isEmpty || existing.single.choice != _choice) {
          archive = archive.append(
              old.withRule(CustomConventionRule(_slot, _choice)));
        }
      }
      await _storage.save(_base.profileId, archive);
      if (!mounted) return;
      setState(() {
        _archive = archive;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'm4SaveFailed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = _archive.latest;
    final choices = CustomRuleCatalog.choices[_slot]!;
    return Scaffold(
      appBar: AppBar(title: Text(copy.t('m4Title'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(copy.t('m4Warning'), key: const Key('m4_release_warning')),
            const SizedBox(height: 12),
            DropdownButton<PartnershipSystem>(
              key: const Key('m4_base_system'),
              isExpanded: true,
              value: _base,
              onChanged: _loading ? null : (base) {
                if (base == null) return;
                setState(() => _base = base);
                _load();
              },
              items: [
                DropdownMenuItem(
                    value: ConventionCatalog.sayc,
                    child: Text(copy.t('gatewaySystemSAYC'))),
                DropdownMenuItem(
                    value: ConventionCatalog.twoOverOne,
                    child: Text(copy.t('gatewaySystem21GF'))),
              ],
            ),
            if (_loading) const LinearProgressIndicator(
                key: Key('m4_busy')),
            if (_error != null)
              Text(copy.t(_error!), key: const Key('m4_error')),
            if (draft != null) ...[
              Text('${copy.t('m4Revision')}: ${draft.revision}',
                  key: const Key('m4_revision')),
              SelectableText(draft.fingerprint,
                  key: const Key('m4_fingerprint')),
              Text(copy.t(draft.rules.isEmpty
                  ? 'm4BaseOnly' : 'm4Unsupported'),
                  key: const Key('m4_engine_status')),
              for (final rule in draft.rules)
                ListTile(
                  key: Key('m4_existing_${rule.slot.name}'),
                  title: Text(copy.t('m4slot_${rule.slot.name}')),
                  subtitle: Text(copy.t('m4choice_${rule.choice}')),
                ),
            ],
            const SizedBox(height: 12),
            Text(copy.t('m4Auction')),
            DropdownButton<CustomRuleSlot>(
              key: const Key('m4_rule_slot'),
              isExpanded: true,
              value: _slot,
              onChanged: _loading || _error != null ? null : (slot) {
                if (slot == null) return;
                setState(() {
                  _slot = slot;
                  _choice = CustomRuleCatalog.choices[slot]!.first;
                });
              },
              items: [
                for (final slot in CustomRuleSlot.values)
                  DropdownMenuItem(
                    value: slot, child: Text(copy.t('m4slot_${slot.name}'))),
              ],
            ),
            DropdownButton<String>(
              key: const Key('m4_rule_choice'),
              isExpanded: true,
              value: _choice,
              onChanged: _loading || _error != null ? null :
                  (choice) => setState(() => _choice = choice!),
              items: [
                for (final choice in choices)
                  DropdownMenuItem(
                      value: choice,
                      child: Text(copy.t('m4choice_$choice'))),
              ],
            ),
            Wrap(
              spacing: 12,
              children: [
                FilledButton(
                    key: const Key('m4_save'),
                    onPressed: _loading || _error != null ? null : _commit,
                    child: Text(copy.t('m4Save'))),
                OutlinedButton(
                    key: const Key('m4_remove'),
                    onPressed: _loading || _error != null || draft == null ||
                        !draft.rules.any((rule) => rule.slot == _slot)
                        ? null : () => _commit(remove: true),
                    child: Text(copy.t('m4Remove'))),
              ],
            ),
            Text(copy.t('m4LocalOnly')),
          ],
        ),
      ),
    );
  }
}
