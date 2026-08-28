import 'package:flutter/material.dart';

import 'package:brewline/core/constants/app_sizes.dart';

/// Custom on-screen numeric PIN keypad with dot indicators.
///
/// Compact design: small animated dots + 3×4 numeric grid. No system
/// keyboard — this is a self-contained custom keypad for PIN entry.
class PinKeypadField extends StatefulWidget {
  final int length;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final bool hasError;
  final String? label;

  const PinKeypadField({
    super.key,
    this.length = kAdminPinLength,
    this.onChanged,
    this.onCompleted,
    this.hasError = false,
    this.label,
  });

  @override
  State<PinKeypadField> createState() => _PinKeypadFieldState();
}

class _PinKeypadFieldState extends State<PinKeypadField>
    with SingleTickerProviderStateMixin {
  String _currentPin = '';
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

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
        () => _currentPin = _currentPin.substring(0, _currentPin.length - 1));
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
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
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
            return Transform.translate(
              offset: Offset(offset, 0),
              child: child,
            );
          },
          child: _DotRow(
            length: widget.length,
            filledCount: _currentPin.length,
            hasError: widget.hasError,
            colorScheme: colorScheme,
          ),
        ),
        SizedBox(height: Space.lg),
        // Numeric keypad
        _NumericKeypad(
          onKeyTap: _onKeyTap,
          onBackspace: _onBackspace,
          colorScheme: colorScheme,
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

  const _DotRow({
    required this.length,
    required this.filledCount,
    required this.hasError,
    required this.colorScheme,
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
            width: 14,
            height: 14,
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

  const _NumericKeypad({
    required this.onKeyTap,
    required this.onBackspace,
    required this.colorScheme,
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
          padding: EdgeInsets.only(bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) {
              if (key.isEmpty) {
                return SizedBox(width: 68, height: 48);
              }
              if (key == '⌫') {
                return _KeypadButton(
                  label: key,
                  onTap: onBackspace,
                  colorScheme: colorScheme,
                  isBackspace: true,
                );
              }
              return _KeypadButton(
                label: key,
                onTap: () => onKeyTap(key),
                colorScheme: colorScheme,
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

  const _KeypadButton({
    required this.label,
    required this.onTap,
    required this.colorScheme,
    this.isBackspace = false,
  });

  @override
  State<_KeypadButton> createState() => _KeypadButtonState();
}

class _KeypadButtonState extends State<_KeypadButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 68,
          height: 48,
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
                  size: 22,
                )
              : Text(
                  widget.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: widget.colorScheme.onSurface,
                      ),
                ),
        ),
      ),
    );
  }
}
