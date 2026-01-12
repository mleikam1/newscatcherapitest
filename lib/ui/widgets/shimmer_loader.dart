import 'dart:math' as math;

import 'package:flutter/material.dart';

class ShimmerLoader extends StatefulWidget {
  final int itemCount;

  const ShimmerLoader({super.key, this.itemCount = 6});

  @override
  State<ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<ShimmerLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surfaceVariant;
    final highlightColor =
        Color.lerp(baseColor, Colors.white, 0.6) ?? Colors.white;

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final shimmerPosition = _controller.value;
        return Column(
          children: List.generate(widget.itemCount, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _ShimmerRow(
                baseColor: baseColor,
                highlightColor: highlightColor,
                position: (shimmerPosition + index * 0.1) % 1,
              ),
            );
          }),
        );
      },
    );
  }
}

class _ShimmerRow extends StatelessWidget {
  final Color baseColor;
  final Color highlightColor;
  final double position;

  const _ShimmerRow({
    required this.baseColor,
    required this.highlightColor,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) {
        final width = rect.width;
        final dx = (position * 2 - 1) * width;
        return LinearGradient(
          colors: [baseColor, highlightColor, baseColor],
          stops: const [0.35, 0.5, 0.65],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          transform: _SlidingGradientTransform(dx),
        ).createShader(rect);
      },
      blendMode: BlendMode.srcATop,
      child: Row(
        children: [
          _ShimmerBox(
            width: 28,
            height: 28,
            color: baseColor,
            radius: 14,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(
                  width: double.infinity,
                  height: 14,
                  color: baseColor,
                ),
                const SizedBox(height: 8),
                _ShimmerBox(
                  width: double.infinity,
                  height: 16,
                  color: baseColor,
                ),
                const SizedBox(height: 8),
                _ShimmerBox(
                  width: math.max(80, 160 + position * 60),
                  height: 12,
                  color: baseColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final Color color;

  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.color,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(slidePercent, 0.0, 0.0);
  }
}
