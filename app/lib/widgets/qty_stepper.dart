import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// The -/[qty]/+ control used in the catalog row, cart line and product
/// detail sheet. `filledInc` draws the + button as a solid accent pill
/// (catalog row); otherwise both buttons are plain glyphs on a light pill
/// (cart line, detail sheet) — matching the two variants in the prototype.
class QtyStepper extends StatefulWidget {
  const QtyStepper({
    super.key,
    required this.text,
    required this.onChanged,
    required this.onCommit,
    required this.onInc,
    required this.onDec,
    this.height = 38,
    this.buttonSize = 36,
    this.inputWidth = 52,
    this.pillBg = AppColors.accentSoftBg,
    this.filledInc = true,
    this.expand = false,
  });

  final String text;
  final ValueChanged<String> onChanged;
  final VoidCallback onCommit;
  final VoidCallback onInc;
  final VoidCallback onDec;
  final double height;
  final double buttonSize;
  final double inputWidth;
  final Color pillBg;
  final bool filledInc;

  /// When true (used where the pill sits inside an [Expanded]/[Row]) the
  /// middle input stretches to fill the available width instead of using
  /// [inputWidth].
  final bool expand;

  @override
  State<QtyStepper> createState() => _QtyStepperState();
}

class _QtyStepperState extends State<QtyStepper> {
  late final FocusNode _focus = FocusNode();
  late final TextEditingController _controller = TextEditingController(text: widget.text);

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) widget.onCommit();
    });
  }

  @override
  void didUpdateWidget(covariant QtyStepper old) {
    super.didUpdateWidget(old);
    if (widget.text != _controller.text) {
      _controller.value = _controller.value.copyWith(
        text: widget.text,
        selection: TextSelection.collapsed(offset: widget.text.length),
        composing: TextRange.empty,
      );
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = DecoratedBox(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9)),
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        onChanged: widget.onChanged,
        onSubmitted: (_) => widget.onCommit(),
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary),
        decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: widget.pillBg, borderRadius: BorderRadius.circular(widget.height / 2 + 4)),
      child: Row(
        mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          _StepButton(
            size: widget.buttonSize,
            height: widget.height,
            onTap: widget.onDec,
            filled: false,
            glyph: '−',
          ),
          widget.expand
              ? Expanded(child: SizedBox(height: widget.height, child: field))
              : SizedBox(width: widget.inputWidth, height: widget.height, child: field),
          _StepButton(
            size: widget.buttonSize,
            height: widget.height,
            onTap: widget.onInc,
            filled: widget.filledInc,
            glyph: '+',
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.size, required this.height, required this.onTap, required this.filled, required this.glyph});

  final double size;
  final double height;
  final VoidCallback onTap;
  final bool filled;
  final String glyph;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: size,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          glyph,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w600,
            color: filled ? Colors.white : AppColors.accent,
            height: 1,
          ),
        ),
      ),
    );
  }
}
