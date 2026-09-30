import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WaveformVisualizer extends StatefulWidget {
  final bool isPlayingOrRecording;
  final Color activeColor;
  final Color inactiveColor;
  final double height;
  final int barCount;

  const WaveformVisualizer({
    super.key,
    required this.isPlayingOrRecording,
    this.activeColor = AppColors.primary,
    this.inactiveColor = AppColors.line,
    this.height = 40.0,
    this.barCount = 28,
  });

  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _baseHeights = [];
  final Random _random = Random(42);

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.barCount; i++) {
      // Generate pleasing wave profile
      final normalized = sin((i / widget.barCount) * pi);
      _baseHeights.add(0.2 + (normalized * 0.7 * (0.5 + _random.nextDouble() * 0.5)));
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addListener(() {
        if (mounted) setState(() {});
      });

    if (widget.isPlayingOrRecording) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant WaveformVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlayingOrRecording != oldWidget.isPlayingOrRecording) {
      if (widget.isPlayingOrRecording) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(widget.barCount, (index) {
          double factor = _baseHeights[index];
          if (widget.isPlayingOrRecording) {
            // Dynamic modulation
            final wave = sin((_controller.value * 2 * pi) + (index * 0.4));
            factor = (factor + (wave * 0.25)).clamp(0.15, 1.0);
          } else {
            factor = factor.clamp(0.2, 0.85);
          }

          final barHeight = widget.height * factor;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            width: 3.5,
            height: barHeight,
            decoration: BoxDecoration(
              color: widget.isPlayingOrRecording ? widget.activeColor : widget.inactiveColor,
              borderRadius: BorderRadius.circular(2.0),
            ),
          );
        }),
      ),
    );
  }
}
