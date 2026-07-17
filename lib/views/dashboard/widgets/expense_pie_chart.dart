import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:daily_expense_tracker/controllers/expense_controller.dart';

class ExpensePieChart extends StatefulWidget {
  const ExpensePieChart({super.key});

  @override
  State<ExpensePieChart> createState() => _ExpensePieChartState();
}

class _ExpensePieChartState extends State<ExpensePieChart> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _chartAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _chartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurveTween(curve: Curves.fastOutSlowIn).animate(_animationController),
    );
    _animationController.forward();
  }

  @override
  void didUpdateWidget(covariant ExpensePieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _animationController.reset();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ExpenseController>();
    final theme = Theme.of(context);

    return Obx(() {
      // Don't modify these variable names - aligned with your controller
      final totalSpent = controller.totalMonthlyExpenses;
      final budget = controller.income.value;
      final percentSpent = budget > 0 ? (totalSpent / budget).clamp(0.0, 1.0) : 0.0;

      return AnimatedBuilder(
        animation: _chartAnimation,
        builder: (context, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 200,
                width: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Premium Custom Painted Ring
                    CustomPaint(
                      size: const Size(200, 200),
                      painter: RingChartPainter(
                        percentage: percentSpent * _chartAnimation.value,
                        trackColor: theme.dividerColor.withValues(alpha: 0.08),
                        progressColor: theme.colorScheme.primary,
                      ),
                    ),
                    // Inner Center Stats
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Total Spent",
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.disabledColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Rs. ${totalSpent.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "${(percentSpent * 100).toStringAsFixed(0)}%",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
    });
  }
}

// Custom Painter for Smooth Animated Donut Ring
class RingChartPainter extends CustomPainter {
  final double percentage;
  final Color trackColor;
  final Color progressColor;

  RingChartPainter({
    required this.percentage,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 12; // stroke offset
    const strokeWidth = 16.0;

    // 1. Background Gray Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // 2. Animated Progress Ring
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double startAngle = -pi / 2; // Starts from top center
    double sweepAngle = 2 * pi * percentage;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant RingChartPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor;
  }
}