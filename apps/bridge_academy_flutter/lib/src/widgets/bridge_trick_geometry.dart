import 'dart:math' as math;

import 'package:bridge_core/bridge_core.dart' show Seat;
import 'package:flutter/widgets.dart';

/// One coordinate system for public cards, their entrance and collection.
/// Contains only dimensions and seats; no cards or private game state.
class BridgeTrickGeometry {
  const BridgeTrickGeometry({
    this.cardWidth = 40,
    this.arenaSize,
    this.viewer = Seat.south,
  });

  factory BridgeTrickGeometry.fit(
    Size available, {
    required Size arenaSize,
    Seat viewer = Seat.south,
  }) => BridgeTrickGeometry(
    cardWidth: math.max(
      24,
      math.min(84, math.min(available.width / 2.35, available.height / 2.464)),
    ),
    arenaSize: arenaSize,
    viewer: viewer,
  );

  final double cardWidth;
  final Size? arenaSize;
  final Seat viewer;

  /// Rotate presentation only: the viewer is at the bottom, identities stay real.
  Seat displaySeat(Seat seat) =>
      Seat.values[(seat.index - viewer.index + Seat.south.index + 4) % 4];

  Seat seatAt(Seat position) =>
      Seat.values[(position.index + viewer.index - Seat.south.index + 4) % 4];
  Size get cardSize => Size(cardWidth, cardWidth * 1.4);
  Size get size => Size(cardWidth * 2.35, cardSize.height * 1.76);

  Offset seatOffset(Seat seat) => switch (displaySeat(seat)) {
    Seat.north => Offset(0, -cardSize.height * .38),
    Seat.east => Offset(cardWidth * .675, 0),
    Seat.south => Offset(0, cardSize.height * .38),
    Seat.west => Offset(-cardWidth * .675, 0),
  };

  Offset position(Seat seat) =>
      size.center(Offset.zero) -
      cardSize.center(Offset.zero) +
      seatOffset(seat);

  Offset seatAnchor(Seat seat) {
    final arena = arenaSize ?? size;
    return switch (displaySeat(seat)) {
      Seat.north => Offset(arena.width / 2, 18),
      Seat.east => Offset(arena.width - 18, arena.height / 2),
      Seat.south => Offset(arena.width / 2, arena.height - 18),
      Seat.west => Offset(18, arena.height / 2),
    };
  }

  Offset entranceFrom(Seat seat) =>
      seatAnchor(seat) -
      (arenaSize ?? size).center(Offset.zero) -
      seatOffset(seat);
}
