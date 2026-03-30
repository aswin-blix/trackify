import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnimatedCounter extends StatefulWidget {
  final double value;
  final String prefix;
  final String suffix;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;
  final int decimalPlaces;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.style,
    this.duration = const Duration(milliseconds: 800),
    this.curve = Curves.easeOutExpo,
    this.decimalPlaces = 2,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _from = 0;
  double _to = 0;

  @override
  void initState() {
    super.initState();
    _to = widget.value;
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: 0, end: _to).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _from = _animation.value;
      _to = widget.value;
      _controller.duration = widget.duration;
      _animation = Tween<double>(begin: _from, end: _to).animate(
        CurvedAnimation(parent: _controller, curve: widget.curve),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final val = _animation.value;
        final formatted = widget.decimalPlaces > 0
            ? val.toStringAsFixed(widget.decimalPlaces)
            : val.toStringAsFixed(0);
        // Add comma formatting
        final parts = formatted.split('.');
        final intPart = _addCommas(parts[0]);
        final display = parts.length > 1 ? '$intPart.${parts[1]}' : intPart;

        return Text(
          '${widget.prefix}$display${widget.suffix}',
          style: widget.style ??
              GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        );
      },
    );
  }

  String _addCommas(String intStr) {
    final isNeg = intStr.startsWith('-');
    final digits = isNeg ? intStr.substring(1) : intStr;
    if (digits.length <= 3) return intStr;
    final result = StringBuffer();
    int count = 0;
    for (int i = digits.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) result.write(',');
      result.write(digits[i]);
      count++;
    }
    final reversed = result.toString().split('').reversed.join();
    return isNeg ? '-$reversed' : reversed;
  }
}
