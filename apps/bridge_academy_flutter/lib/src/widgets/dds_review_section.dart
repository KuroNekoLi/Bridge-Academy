import 'package:bridge_core/bridge_core.dart';
import 'package:bridge_dds_adapter/bridge_dds_adapter.dart';
import 'package:flutter/material.dart';
import '../app_copy.dart';

/// Only a 5x4 validated table enters the player UI; never a Deal or PBN.
class DdsReviewSection extends StatefulWidget {
  const DdsReviewSection({super.key, required this.copy, this.onAnalyze});
  final AppCopy copy;
  final Future<DoubleDummyTable> Function()? onAnalyze;
  @override
  State<DdsReviewSection> createState() => _DdsReviewSectionState();
}
class _DdsReviewSectionState extends State<DdsReviewSection> {
  DoubleDummyTable? _result;
  String? _error;
  bool _busy = false;
  Future<void> _run() async {
    if (_busy || widget.onAnalyze == null) return;
    setState(() { _busy = true; _result = null; _error = null; });
    try {
      final result = await widget.onAnalyze!();
      if (mounted) setState(() => _result = result);
    } on DoubleDummyAnalysisException catch (e) {
      if (mounted) setState(() => _error = switch(e.code) {
        DoubleDummyFailureCode.unsupportedPlatform ||
        DoubleDummyFailureCode.unavailable => 'ddsUnavailable',
        DoubleDummyFailureCode.notFinished => 'ddsNotFinished',
        _ => 'ddsError',
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'ddsError');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Column(
      key: const Key('dds_review_section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.copy.t('ddsTitle'), style: Theme.of(context).textTheme.titleSmall),
        OutlinedButton(
          key: const Key('dds_analyze'),
          onPressed: _busy || widget.onAnalyze == null ? null : _run,
          child: Text(widget.copy.t('ddsRequest')),
        ),
        if (_busy) Text(widget.copy.t('ddsLoading')),
        if (_error != null) Text(widget.copy.t(_error!), key: const Key('dds_error')),
        if (result != null) ...[
          Text(widget.copy.t('ddsResult'), key: const Key('dds_result')),
          Text('${widget.copy.t('ddsSolverVersion')}: ${result.solverCommit}'),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              key: const Key('dds_table'),
              columns: [
                DataColumn(label: Text(widget.copy.t('ddsDeclarer'))),
                for(final seat in Seat.values)
                  DataColumn(label: Text(widget.copy.seat(seat.letter))),
              ],
              rows: [
                for (final strain in Strain.values)
                  DataRow(cells: [
                    DataCell(Text(strain.code)),
                    for (final seat in Seat.values)
                      DataCell(Text('${result.tricks(strain: strain, declarer: seat)}')),
                  ]),
              ],
            ),
          ),
        ],
        Text(widget.copy.t('ddsCaveat'), key: const Key('dds_caveat')),
      ],
    );
  }
}
