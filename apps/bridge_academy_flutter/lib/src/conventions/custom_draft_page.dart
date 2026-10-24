import 'dart:convert';

import 'package:bridge_conventions/bridge_conventions.dart';
import 'package:flutter/services.dart';
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
  bool _confirmingImport = false;
  String? _error;
  String? _notice;
  int _loadGeneration = 0;
  int? _compareFromRevision;

  AppCopy get copy => AppCopy(widget.isEnglish);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    final baseId = _base.profileId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final archive = await _storage.load(baseId);
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _archive = archive;
        _compareFromRevision = null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || generation != _loadGeneration) return;
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

  /// Explicit clipboard export contains rule intentions and hashes, no deal
  /// or credential. This is NOT a signed/certified engine manifest.
  Future<void> _export() async {
    if (_loading || _archive.latest == null) return;
    try {
      await Clipboard.setData(ClipboardData(text: jsonEncode(_archive.toJson())));
      if (!mounted) return;
      setState(() => _notice = 'm4ExportDone');
    } catch (_) {
      if (!mounted) return;
      setState(() => _notice = 'm4ExportFailed');
    }
  }

  Future<void> _import() async {
    if (_loading || _error != null) return;
    setState(() {
      _loading = true;
      _notice = null;
    });
    try {
      final clipboard = await Clipboard.getData('text/plain');
      final raw = clipboard?.text;
      if (raw == null || raw.isEmpty || raw.length > 131072) {
        throw const FormatException('Invalid import size');
      }
      final incoming = CustomConventionArchive.fromJson(jsonDecode(raw));
      final mode = CustomArchiveImport.compare(
          local: _archive, incoming: incoming,
          expectedBase: _base.profileId);
      if (!mounted) return;
      if (mode == CustomArchiveRestore.divergent) {
        setState(() => _notice = 'm4ImportConflict');
        return;
      }
      if (mode == CustomArchiveRestore.identical) {
        setState(() => _notice = 'm4ImportSame');
        return;
      }
      setState(() => _confirmingImport = true);
      final accepted = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(copy.t('m4ImportTitle')),
          content: Text('${copy.t('m4ImportConfirm')} '
              '${copy.t('m4Revision')}: ${incoming.latest!.revision}'),
          actions: [
            TextButton(
              key: const Key('m4_import_cancel'),
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(copy.t('m4Cancel')),
            ),
            FilledButton(
              key: const Key('m4_import_confirm'),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(copy.t('m4Confirm')),
            ),
          ],
        ),
      );
      if (!mounted) return;
      setState(() => _confirmingImport = false);
      if (accepted != true) return;
      await _storage.save(_base.profileId, incoming);
      if (!mounted) return;
      setState(() {
        _archive = incoming;
        _compareFromRevision = null;
        _notice = 'm4ImportDone';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _notice = 'm4ImportInvalid');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _confirmingImport = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = _archive.latest;
    final choices = CustomRuleCatalog.choices[_slot]!;
    final report = draft == null ? null : CustomConventionReviewer.assess(draft);
    final compareOptions = _archive.revisions
        .where((revision) => draft != null && revision.revision < draft.revision)
        .toList(growable: false);
    final fromRevision = compareOptions.isEmpty
        ? null
        : compareOptions.any((r) => r.revision == _compareFromRevision)
            ? _compareFromRevision
            : compareOptions.last.revision;
    final diff = draft == null || fromRevision == null
        ? null
        : CustomConventionHistory.compare(
            _archive, fromRevision: fromRevision,
            toRevision: draft.revision);
    final preview = draft == null ? null : CustomConventionReviewer.preview(
      draft, CustomRuleCatalog.publicAuctions[_slot]!);
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
            if (_loading && !_confirmingImport) const LinearProgressIndicator(
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
            if (diff != null) ...[
              const Divider(),
              Text(copy.t('m4DiffHeading'),
                  key: const Key('m4_diff_heading')),
              DropdownButton<int>(
                key: const Key('m4_compare_from'),
                value: fromRevision,
                isExpanded: true,
                onChanged: _loading || _error != null ? null :
                    (value) => setState(() => _compareFromRevision = value),
                items: [
                  for (final historical in compareOptions)
                    DropdownMenuItem(
                      value: historical.revision,
                      child: Text('${copy.t('m4Revision')}: ${historical.revision}'),
                    ),
                ],
              ),
              Text(copy.t('m4DiffUnverified'),
                  key: const Key('m4_diff_disclaimer')),
              if (diff.isUnchanged)
                Text(copy.t('m4DiffNoChanges'),
                    key: const Key('m4_diff_empty')),
              for (final change in diff.changes)
                ListTile(
                  key: Key('m4_diff_${change.slot.name}'),
                  title: Text(change.auction),
                  subtitle: Text(
                    '${copy.t('m4DiffBefore')}: '
                    '${change.beforeChoice == null ? copy.t('m4DiffNone') : copy.t('m4choice_${change.beforeChoice}')}  →  '
                    '${copy.t('m4DiffAfter')}: '
                    '${change.afterChoice == null ? copy.t('m4DiffNone') : copy.t('m4choice_${change.afterChoice}')}',
                  ),
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
            const SizedBox(height: 8),
            Text(copy.t('m4PreviewTitle'),
                key: const Key('m4_preview_heading')),
            Text(CustomRuleCatalog.publicAuctions[_slot]!,
                key: const Key('m4_preview_auction')),
            Text(preview?.userSelectedMeaning == null
                ? copy.t('m4PreviewUnknown')
                : copy.t('m4choice_${preview!.userSelectedMeaning}'),
                key: const Key('m4_preview_meaning')),
            Text(copy.t('m4PreviewUnverified'),
                key: const Key('m4_preview_disclaimer')),
            if (report != null)
              Text(copy.t(report.executionStatus ==
                      CustomExecutionStatus.engineEvidenceRequired
                  ? 'm4EvidenceMissing' : 'm4BaseOnly'),
                  key: const Key('m4_evidence_status')),
            const SizedBox(height: 8),
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
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: [
                OutlinedButton.icon(
                  key: const Key('m4_export'),
                  onPressed: _loading || draft == null ? null : _export,
                  icon: const Icon(Icons.copy_outlined),
                  label: Text(copy.t('m4Export')),
                ),
                OutlinedButton.icon(
                  key: const Key('m4_import'),
                  onPressed: _loading || _error != null ? null : _import,
                  icon: const Icon(Icons.input_outlined),
                  label: Text(copy.t('m4Import')),
                ),
              ],
            ),
            if (_notice != null)
              Text(copy.t(_notice!), key: const Key('m4_import_notice')),
            Text(copy.t('m4LocalOnly')),
          ],
        ),
      ),
    );
  }
}
