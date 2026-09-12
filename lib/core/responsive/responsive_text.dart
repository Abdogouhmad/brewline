/// Responsive font scaling as a `BuildContext` extension.
///
/// Spec root: `improve.md` §6.2. Apply via
/// `Text('…', style: TextStyle(fontSize: context.responsiveFontSize(16)))`
/// to the dashboard card labels/numbers that currently wrap onto a second
/// line on phones. It is a *companion* to smaller card padding/min-width —
/// font scaling alone does not fix wrapping.
///
/// ## Interaction with the OS accessibility text scaler (feat.md §7)
///
/// `responsiveFontSize` only *shrinks* on narrow screens (clamped 0.85–1.0);
/// it never grows text. The OS accessibility scaler ([MediaQuery.textScalerOf])
/// multiplies the *result* of that base size via Flutter's `Text` widget, so
/// the two compose multiplicatively — which is safe here precisely because
/// the responsive factor is ≤ 1.0: an accessibility-scaled, wide-desktop
/// reading combination can still exceed 1.0× overall, but a small phone with
/// large-text mode gets the responsive *shrink* applied first, cancelling
/// part of the OS zoom instead of stacking on top of it.
///
/// Do not change this to grow text on wide screens (e.g. `unclamped / 400`):
/// that would compound with the accessibility scaler on phones with large-text
/// enabled and overflow the fixed-height dashboard cards.
library;

import 'package:flutter/widgets.dart';

extension ResponsiveFont on BuildContext {
  /// Scales [baseSize] by the screen width relative to a 400dp reference,
  /// clamped to 0.85–1.0 so text only *shrinks* on narrow phones.
  ///
  /// Composes safely with the platform text scaler because the factor never
  /// exceeds 1.0 (see the library doc above for the reconciliation rationale).
  double responsiveFontSize(double baseSize) {
    final w = MediaQuery.sizeOf(this).width;
    final scale = (w / 400).clamp(0.85, 1.0);
    return baseSize * scale;
  }
}
