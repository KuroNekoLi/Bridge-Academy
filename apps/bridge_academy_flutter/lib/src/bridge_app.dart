import 'package:bridge_core/bridge_core.dart' hide Card;
import 'package:bridge_core/bridge_core.dart' as bridge show Card;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_copy.dart';
import 'bridge_session.dart';

/// App composition: Flutter sees only PlayerView through BridgeSession.
class BridgeAcademyApp extends StatefulWidget {
  const BridgeAcademyApp({super.key, this.session});
  final BridgeSession? session;

  @override
  State<BridgeAcademyApp> createState() => _BridgeAcademyAppState();
}

class _BridgeAcademyAppState extends State<BridgeAcademyApp> {
  late final BridgeSession _session;
  late final bool _ownsSession;
  bool _isEnglish = false;

  @override
  void initState() {
    super.initState();
    _ownsSession = widget.session == null;
    _session = widget.session ?? BridgeSession();
  }

  @override
  void dispose() {
    if (_ownsSession) _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = AppCopy(_isEnglish);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (_) => copy.t('title'),
      locale: _isEnglish ? const Locale('en') : const Locale('zh', 'TW'),
      supportedLocales: const [Locale('zh', 'TW'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0C746E),
        scaffoldBackgroundColor: const Color(0xFFF2F6F3),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text(copy.t('title'), maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
              key: const Key('toggle_locale'),
              tooltip: copy.t('language'),
              onPressed: () => setState(() => _isEnglish = !_isEnglish),
              icon: const Icon(Icons.language),
            ),
          ],
        ),
        body: BridgeTable(session: _session, copy: copy),
      ),
    );
  }
}

class BridgeTable extends StatefulWidget {
  const BridgeTable({super.key, required this.session, required this.copy});
  final BridgeSession session;
  final AppCopy copy;

  @override
  State<BridgeTable> createState() => _BridgeTableState();
}

class _BridgeTableState extends State<BridgeTable> {
  Seat _selectedSeat = Seat.north;
  OpponentMode _selectedMode = OpponentMode.demo;
  int _bidLevel = 1;
  Strain _bidStrain = Strain.notrump;

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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: LayoutBuilder(
                  builder: (context, constraints) => Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _modeSelector(copy, constraints.maxWidth),
                    _seatSelector(copy, constraints.maxWidth),
                    FilledButton.icon(
                      key: const Key('new_game'),
                      onPressed: session.busy
                          ? null
                          : () => session.newGame(
                              humanSeat: _selectedSeat,
                              mode: _selectedMode,
                            ),
                      icon: const Icon(Icons.refresh),
                      label: Text(session.started
                          ? copy.t('restart')
                          : copy.t('newGame')),
                    ),
                  ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              copy.t(session.mode == OpponentMode.demo
                  ? 'demoNotice'
                  : 'liveNotice'),
            ),
            if (view == null) ...[
              const SizedBox(height: 24),
              Text(copy.t('notStarted'), key: const Key('empty_state')),
            ] else ...[
              const SizedBox(height: 12),
              _status(view, session, copy),
              if (session.errorCode != null) ...[
                const SizedBox(height: 8),
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Wrap(
                      spacing: 12,
                      children: [
                        Text(copy.t(session.errorCode!),
                            key: const Key('error_message')),
                        if (!session.busy && !view.canAct && !session.finished)
                          TextButton(
                            key: const Key('retry_bot'),
                            onPressed: session.retryBots,
                            child: Text(copy.t('retry')),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              if (session.busy) ...[
                const LinearProgressIndicator(key: Key('bot_progress')),
                const SizedBox(height: 8),
                Text(copy.t('waitingBot')),
              ],
              const SizedBox(height: 12),
              _board(view, session, copy),
              const SizedBox(height: 8),
              _auctionHistory(view, copy),
              const SizedBox(height: 8),
              if (!session.finished)
                _humanControls(view, session, copy)
              else
                _finishCard(view, copy),
            ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _modeSelector(AppCopy copy, double availableWidth) => SizedBox(
        width: availableWidth < 320 ? availableWidth : 320,
        child: DropdownButtonFormField<OpponentMode>(
          key: const Key('mode_selector'),
          isExpanded: true,
          initialValue: _selectedMode,
          decoration: InputDecoration(labelText: copy.t('mode')),
          items: [
            for (final mode in OpponentMode.values)
              DropdownMenuItem(
                value: mode,
                child: Text(copy.t(mode == OpponentMode.demo ? 'demo' : 'live'),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 13)),
              ),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _selectedMode = value);
          },
        ),
      );

  Widget _seatSelector(AppCopy copy, double availableWidth) => SizedBox(
        width: availableWidth < 185 ? availableWidth : 185,
        child: DropdownButtonFormField<Seat>(
          key: const Key('seat_selector'),
          isExpanded: true,
          initialValue: _selectedSeat,
          decoration: InputDecoration(labelText: copy.t('humanSeat')),
          items: [
            for (final seat in Seat.values)
              DropdownMenuItem(
                value: seat,
                child: Text(copy.seat(seat.letter),
                    overflow: TextOverflow.ellipsis, maxLines: 1),
              ),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _selectedSeat = value);
          },
        ),
      );

  Widget _status(PlayerView view, BridgeSession session, AppCopy copy) {
    return Card(
      key: const Key('game_status'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 24,
          runSpacing: 6,
          children: [
            Text(copy.formatTurn(view.turn?.letter)),
            Text(copy.contract(view.contract?.label ?? copy.t('notYet'))),
            Text(copy.trickCount(view.completedTricks.length)),
            if (view.nsScore != null) Text(copy.score(view.nsScore!)),
            if (session.busy) const CircularProgressIndicator(strokeWidth: 2),
          ],
        ),
      ),
    );
  }

  Widget _board(PlayerView view, BridgeSession session, AppCopy copy) {
    return Card(
      key: const Key('bridge_board'),
      color: const Color(0xFFE6F1E8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _seatPanel(Seat.north, view, session, copy),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _seatPanel(Seat.west, view, session, copy)),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(copy.t('currentTrick')),
                        const SizedBox(height: 8),
                        for (final played in view.currentTrick)
                          Text('${played.handOwner.letter}: ${_cardText(played.card)}'),
                        if (view.currentTrick.isEmpty)
                          Text(copy.t('notYet')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _seatPanel(Seat.east, view, session, copy)),
              ],
            ),
            _seatPanel(Seat.south, view, session, copy),
          ],
        ),
      ),
    );
  }

  Widget _seatPanel(Seat seat, PlayerView view, BridgeSession session,
      AppCopy copy) {
    final dummy = view.contract?.dummy == seat && view.dummyExposed;
    final hasDummyCards = dummy && view.dummyCards != null;
    final active = view.turn == seat;
    return Container(
      key: Key('seat_${seat.letter}'),
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: active ? Theme.of(context).colorScheme.primary : Colors.grey,
          width: active ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(copy.seat(seat.letter),
              style: const TextStyle(fontWeight: FontWeight.w600)),
          if (seat == view.viewer)
            Text(copy.t('yourSeat'))
          else if (!hasDummyCards)
            Text(copy.remaining(view.remainingCards[seat] ?? 0)),
          if (hasDummyCards && seat != view.viewer) ...[
            Text(copy.t('dummy'), key: const Key('dummy_revealed')),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              children: [
                for (final card in view.dummyCards!)
                  _cardButton(
                    card,
                    prefix: 'dummy_card_',
                    copy: copy,
                    legal: view.canAct && active &&
                        view.legalCards.contains(card),
                    busy: session.busy,
                    onTap: () => session.submitCard(card),
                  ),
              ],
            ),
          ],
          if (seat != view.viewer && !hasDummyCards)
            const Icon(Icons.style_outlined),
        ],
      ),
    );
  }

  Widget _auctionHistory(PlayerView view, AppCopy copy) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(copy.t('auction')),
              Wrap(
                spacing: 6,
                children: [
                  for (final entry in view.auction)
                    Chip(label: Text('${entry.seat.letter}: ${entry.call.code}')),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _humanControls(PlayerView view, BridgeSession session, AppCopy copy) {
    if (view.phase == Phase.auction) {
      return Card(
        key: const Key('auction_controls'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DropdownButton<int>(
                key: const Key('bid_level'),
                value: _bidLevel,
                items: [
                  for (var n = 1; n <= 7; n++)
                    DropdownMenuItem(value: n, child: Text('$n')),
                ],
                onChanged: (n) {
                  if (n != null) setState(() => _bidLevel = n);
                },
              ),
              DropdownButton<Strain>(
                key: const Key('bid_strain'),
                value: _bidStrain,
                items: [
                  for (final strain in Strain.values)
                    DropdownMenuItem(
                      value: strain,
                      child: Text(copy.t(_strainKey(strain))),
                    ),
                ],
                onChanged: (strain) {
                  if (strain != null) setState(() => _bidStrain = strain);
                },
              ),
              FilledButton(
                key: const Key('make_bid'),
                onPressed: view.canAct && !session.busy
                    ? () => session.submitCall(Bid(_bidLevel, _bidStrain))
                    : null,
                child: Text(copy.t('call')),
              ),
              OutlinedButton(
                key: const Key('pass'),
                onPressed: view.canAct && !session.busy
                    ? () => session.submitCall(const Pass())
                    : null,
                child: Text(copy.t('pass')),
              ),
              OutlinedButton(
                key: const Key('double'),
                onPressed: view.canAct && !session.busy
                    ? () => session.submitCall(const DoubleCall())
                    : null,
                child: Text(copy.t('double')),
              ),
              OutlinedButton(
                key: const Key('redouble'),
                onPressed: view.canAct && !session.busy
                    ? () => session.submitCall(const RedoubleCall())
                    : null,
                child: Text(copy.t('redouble')),
              ),
            ],
          ),
        ),
      );
    }
    if (view.phase == Phase.play) {
      return Card(
        key: const Key('hand_controls'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(copy.t('cards')),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 5,
                children: [
                  for (final card in view.ownCards)
                    _cardButton(
                      card,
                      prefix: 'hand_card_',
                      copy: copy,
                      legal: view.canAct && view.turn == view.viewer &&
                          view.legalCards.contains(card),
                      busy: session.busy,
                      onTap: () => session.submitCard(card),
                    ),
                ],
              ),
              if (view.contract != null && !view.dummyExposed)
                Text(copy.t('hidden'), key: const Key('dummy_hidden')),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _finishCard(PlayerView view, AppCopy copy) => Card(
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

  Widget _cardButton(bridge.Card card, {required String prefix,
      required AppCopy copy, required bool legal, required bool busy,
      required VoidCallback onTap}) {
    return OutlinedButton(
      key: Key('$prefix${card.code}'),
      onPressed: legal && !busy ? onTap : null,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: const Size(42, 40),
      ),
      child: Text('${_cardText(card)}${legal ? " ✓" : ""}'),
    );
  }

  String _cardText(bridge.Card card) => '${switch (card.suit) {
      Suit.clubs => "♣",
      Suit.diamonds => "♦",
      Suit.hearts => "♥",
      Suit.spades => "♠",
    }}${card.rank.symbol}';

  String _strainKey(Strain strain) => switch (strain) {
    Strain.clubs => 'strainC',
    Strain.diamonds => 'strainD',
    Strain.hearts => 'strainH',
    Strain.spades => 'strainS',
    Strain.notrump => 'strainNT',
  };
}


