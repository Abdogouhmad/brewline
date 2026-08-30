/// Responsive font scaling as a `BuildContext` extension.
///
/// Spec root: `improve.md` §6.2. Apply via
/// `Text('…', style: TextStyle(fontSize: context.responsiveFontSize(16)))`
/// to the dashboard card labels/numbers that currently wrap onto a second
/// line on phones. It is a *companion* to smaller card padding/min-width —
/// font scaling alone does not fix wrapping.
library;

import 'package:flutter/widgets.dart';

extension ResponsiveFont on BuildContext {
  /// Scales [baseSize] by the screen width relative to a 400dp reference,
  /// clamped to 0.85–1.0 so text only *shrinks* on narrow phones.
  ///
  /// No fancy breakpoints: a rough continuous curve is simpler and matches
  /// how Material's web scaleFactor behaves. Never goes above 1.0 — cards
  /// have fixed heights, so growing the type on wide screens (1.25× at 800dp)
  /// used to push dense dashboard cards to overflow.
  double responsiveFontSize(double baseSize) {
    final w = MediaQuery.sizeOf(this).width;
    final scale = (w / 400).clamp(0.85, 1.0);
    return baseSize * scale;
  }
}
