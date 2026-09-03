import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/responsive/responsive.dart';

/// Custom on-screen numeric PIN keypad with dot indicators.
///
/// Compact design: small animated dots + 3×4 numeric grid. No system
/// keyboard — this is a self-contained custom keypad for PIN entry.
///
/// The keypad scales with the device: buttons, dots and gaps grow on tablet
/// (≥ 600dp) and desktop (≥ 905dp) so the now-username-less login fills the
/// available space with large, easy-to-tap keys instead of staying phone-sized.
class PinKeypadField extends StatefulWidget {
  final int length;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final bool hasError;
  final String? label;

  /// Changing this value clears the currently-entered PIN.
  ///
  /// Used by the login form to wipe the digits after a failed attempt while
  /// the parent keeps the same widget instance (so the shake animation —
  /// driven by a [hasError] transition — still plays).
  final int resetSignal;

  /// When `false` the keypad buttons are visually dimmed and taps are ignored.
  /// Used for attempt-throttling cooldowns.
  final bool enabled;

  const PinKeypadField({
    super.key,
    this.length = kAdminPinLength,
    this.onChanged,
    this.onCompleted,
    this.hasError = false,
    this.label,
    this.resetSignal = 0,
    this.enabled = true,
  });

  @override
  State<PinKeypadField> createState() => _PinKeypadFieldState();
}

class _PinKeypadFieldState extends State<PinKeypadField>
    with SingleTickerProviderStateMixin {
  String _currentPin = '';
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  /// Diagonal size of a keypad button, scaling by device type.
  double get _buttonSize => responsiveValue(
    context,
    mobile: 68,
    tablet: 84,
    desktop: 96,
  );

  /// Height of a keypad button, scaling by device type.
  double get _buttonHeight => responsiveValue(
    context,
    mobile: 48,
    tablet: 60,
    desktop: 68,
  );

  /// Dot indicator size, scaling by device type.
  double get _dotSize => responsiveValue(
    context,
    mobile: 14,
    tablet: 18,
    desktop: 20,
  );

  /// Gap between keypad rows, scaling by device type.
  double get _rowGap => responsiveValue(
    context,
    mobile: 6,
    tablet: 10,
    desktop: 12,
  );

  /// Horizontal padding around each key, scaling by device type.
  double get _keyPadding => responsiveValue(
    context,
    mobile: 6,
    tablet: 8,
    desktop: 10,
  );

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(PinKeypadField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasError && !oldWidget.hasError) {
      _shakeController.forward(from: 0);
    }
    if (!widget.hasError && oldWidget.hasError) {
      _shakeController.reset();
    }
    if (widget.resetSignal != oldWidget.resetSignal) {
      // Clear the internally-tracked digits (the dots) so the field is ready
      // for a fresh PIN. The parent owns the provider value already — the
      // failed-attempt notifier clears it in the same update — so we do NOT
      // push onChanged here (that would mutate a provider during build).
      _currentPin = '';
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKeyTap(String value) {
    if (_currentPin.length >= widget.length) return;
    setState(() => _currentPin += value);
    widget.onChanged?.call(_currentPin);
    if (_currentPin.length == widget.length) {
      widget.onCompleted?.call(_currentPin);
    }
  }

  void _onBackspace() {
    if (_currentPin.isEmpty) return;
    setState(
      () => _currentPin = _currentPin.substring(0, _currentPin.length - 1),
    );
    widget.onChanged?.call(_currentPin);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: Space.md),
        ],
        // Dot indicators
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            final offset = widget.hasError
                ? (1 - _shakeAnimation.value) * 8
                : 0.0;
            return Transform.translate(offset: Offset(offset, 0), child: child);
          },
          child: _DotRow(
            length: widget.length,
            filledCount: _currentPin.length,
            hasError: widget.hasError,
            colorScheme: colorScheme,
            dotSize: _dotSize,
          ),
        ),
        SizedBox(height: _rowGap + Space.sm),
        // Numeric keypad
        Opacity(
          opacity: widget.enabled ? 1.0 : 0.35,
          child: IgnorePointer(
            ignoring: !widget.enabled,
            child: _NumericKeypad(
              onKeyTap: _onKeyTap,
              onBackspace: _onBackspace,
              colorScheme: colorScheme,
              buttonSize: _buttonSize,
              buttonHeight: _buttonHeight,
              rowGap: _rowGap,
              keyPadding: _keyPadding,
            ),
          ),
        ),
      ],
    );
  }
}

/// Row of dots representing PIN digits.
class _DotRow extends StatelessWidget {
  final int length;
  final int filledCount;
  final bool hasError;
  final ColorScheme colorScheme;
  final double dotSize;

  const _DotRow({
    required this.length,
    required this.filledCount,
    required this.hasError,
    required this.colorScheme,
    required this.dotSize,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final isFilled = index < filledCount;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasError
                  ? colorScheme.error
                  : isFilled
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
            ),
          ),
        );
      }),
    );
  }
}

/// 3×4 numeric keypad grid.
class _NumericKeypad extends StatelessWidget {
  final ValueChanged<String> onKeyTap;
  final VoidCallback onBackspace;
  final ColorScheme colorScheme;
  final double buttonSize;
  final double buttonHeight;
  final double rowGap;
  final double keyPadding;

  const _NumericKeypad({
    required this.onKeyTap,
    required this.onBackspace,
    required this.colorScheme,
    required this.buttonSize,
    required this.buttonHeight,
    required this.rowGap,
    required this.keyPadding,
  });

  static const _keys = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _keys.map((row) {
        return Padding(
          padding: EdgeInsets.only(bottom: rowGap),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) {
              if (key.isEmpty) {
                // Blank key must carry the same horizontal padding as the
                // buttons and backspace, so every column occupies an identical
                // `buttonSize + 2*keyPadding` width and the columns line up
                // vertically across all four rows (1–9 stay on the same
                // vertical lines as 0 and ⌫ below).
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: keyPadding),
                  child: SizedBox(width: buttonSize, height: buttonHeight),
                );
              }
              if (key == '⌫') {
                return _KeypadButton(
                  label: key,
                  onTap: onBackspace,
                  colorScheme: colorScheme,
                  isBackspace: true,
                  size: buttonSize,
                  height: buttonHeight,
                  padding: keyPadding,
                );
              }
              return _KeypadButton(
                label: key,
                onTap: () => onKeyTap(key),
                colorScheme: colorScheme,
                size: buttonSize,
                height: buttonHeight,
                padding: keyPadding,
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

/// Single keypad button with M3 filled-tonal styling.
class _KeypadButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final bool isBackspace;
  final double size;
  final double height;
  final double padding;

  const _KeypadButton({
    required this.label,
    required this.onTap,
    required this.colorScheme,
    this.isBackspace = false,
    required this.size,
    required this.height,
    required this.padding,
  });

  @override
  State<_KeypadButton> createState() => _KeypadButtonState();
}

class _KeypadButtonState extends State<_KeypadButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.padding),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.size,
          height: widget.height,
          decoration: BoxDecoration(
            color: _isPressed
                ? widget.colorScheme.primaryContainer
                : widget.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(Rounded.xl),
          ),
          alignment: Alignment.center,
          child: widget.isBackspace
              ? Icon(
                  Icons.backspace_outlined,
                  color: widget.colorScheme.onSurface,
                  size: responsiveValue(context, mobile: 22, desktop: 28),
                )
              : Text(
                  widget.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: widget.colorScheme.onSurface,
                    fontSize: responsiveValue(
                      context,
                      mobile: 18,
                      tablet: 22,
                      desktop: 24,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

