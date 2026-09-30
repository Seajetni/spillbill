import 'dart:math';
import 'package:flutter/material.dart';

class CategoryExpense {
  final String title;
  final double amount;
  final Color color;
  final String emoji;

  const CategoryExpense({
    required this.title,
    required this.amount,
    required this.color,
    required this.emoji,
  });
}

class DonutChart extends StatelessWidget {
  final List<CategoryExpense> categories;
  final double totalAmount;
  final double size;

  const DonutChart({
    super.key,
    required this.categories,
    required this.totalAmount,
    this.size = 200.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutChartPainter(
              categories: categories,
              totalAmount: totalAmount,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ใช้ไปทั้งหมด',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF4B5563),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '฿${totalAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F1729),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<CategoryExpense> categories;
  final double totalAmount;

  _DonutChartPainter({
    required this.categories,
    required this.totalAmount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 22.0;

    double startAngle = -pi / 2;

    if (totalAmount <= 0) {
      final paint = Paint()
        ..color = const Color(0xFFEDF0F5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, radius, paint);
      return;
    }

    for (var cat in categories) {
      final sweepAngle = (cat.amount / totalAmount) * 2 * pi;
      final paint = Paint()
        ..color = cat.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // Small gap between segments
      final gap = 0.04;
      if (sweepAngle > gap) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle + (gap / 2),
          sweepAngle - gap,
          false,
          paint,
        );
      }
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
