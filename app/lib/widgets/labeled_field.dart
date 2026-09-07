import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Uppercase label + boxed input, as used on the login, registration and
/// checkout screens.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.height = 50,
    this.hint,
    this.mono = false,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
  });

  /// No label above the box — just the boxed input (used where the label
  /// is already rendered separately, e.g. the cart comment field).
  const LabeledField.raw({
    super.key,
    required this.value,
    required this.onChanged,
    this.height = 50,
    this.hint,
    this.mono = false,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
  }) : label = null;

  final String? label;
  final String value;
  final ValueChanged<String> onChanged;
  final double height;
  final String? hint;
  final bool mono;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final field = _BoundField(
      value: value,
      onChanged: onChanged,
      height: height,
      hint: hint,
      mono: mono,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
    );
    if (label == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label!, style: AppText.label),
        const SizedBox(height: 6),
        field,
      ],
    );
  }
}

/// A [TextField] whose controller text is kept in sync with an externally
/// owned string value, without stomping the caret while the user types.
class _BoundField extends StatefulWidget {
  const _BoundField({
    required this.value,
    required this.onChanged,
    required this.height,
    this.hint,
    this.mono = false,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final double height;
  final String? hint;
  final bool mono;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;

  @override
  State<_BoundField> createState() => _BoundFieldState();
}

class _BoundFieldState extends State<_BoundField> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant _BoundField old) {
    super.didUpdateWidget(old);
    if (widget.value != _controller.text) {
      _controller.value = _controller.value.copyWith(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
        composing: TextRange.empty,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: widget.height),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: widget.maxLines > 1 ? 10 : 0),
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(widget.maxLines > 1 ? 12 : 13),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
      ),
      alignment: widget.maxLines > 1 ? Alignment.topLeft : Alignment.centerLeft,
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        maxLines: widget.maxLines,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        style: TextStyle(
          fontFamily: widget.mono ? 'monospace' : null,
          fontWeight: widget.mono ? FontWeight.w600 : FontWeight.w500,
          fontSize: widget.mono ? 19 : 16,
          letterSpacing: widget.mono ? 1 : 0,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: widget.hint,
          hintStyle: const TextStyle(color: AppColors.textTertiary, fontWeight: FontWeight.w500, fontSize: 15),
        ),
      ),
    );
  }
}
