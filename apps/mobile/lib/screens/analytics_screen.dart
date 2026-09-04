import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:design_system/tokens/colors.dart';
import 'package:design_system/tokens/spacing.dart';

/// Screen M-13a: Analytics Screen (Insights)
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LabelLensColors.surface1,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.7),
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: const Text('Analytics', style: TextStyle(color: LabelLensColors.textPrimary, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                side: const BorderSide(color: LabelLensColors.surface3),
              ),
              child: const Text('Export', style: TextStyle(color: LabelLensColors.textPrimary, fontSize: 12)),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          // Subtle background blobs for visual depth
          Positioned(
            top: -100,
            right: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 250,
                height: 250,
                decoration: const BoxDecoration(
                  color: LabelLensColors.brandSecondary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: LabelLensColors.brandPrimary.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(LabelLensSpacing.s4),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _KpiCard(title: 'Products Scanned', value: '247', trend: 'this month', isPositive: true)),
                      const SizedBox(width: LabelLensSpacing.s4),
                      Expanded(child: _KpiCard(title: 'Pass Rate', value: '78.5%', trend: '↑ trending up', isPositive: true)),
                    ],
                  ),
                  const SizedBox(height: LabelLensSpacing.s4),
                  Row(
                    children: [
                      Expanded(child: _KpiCard(title: 'Open Violations', value: '53', trend: '↓ from last month', isPositive: false)),
                      const SizedBox(width: LabelLensSpacing.s4),
                      Expanded(child: _KpiCard(title: 'Avg Scan Time', value: '4.2s', trend: '↑ faster', isPositive: true)),
                    ],
                  ),
                  const SizedBox(height: LabelLensSpacing.s6),

                  _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Compliance Trend — 30 Days', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: LabelLensSpacing.s4),
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white.withOpacity(0.5),
                            border: Border.all(color: LabelLensColors.surface3),
                          ),
                          child: Stack(
                            children: [
                              // Grid lines
                              Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: List.generate(4, (index) => Container(height: 1, color: LabelLensColors.surface3.withOpacity(0.5))),
                              ),
                              // Actual Line Chart using CustomPaint
                              Positioned.fill(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 24, top: 16, left: 16, right: 16),
                                  child: CustomPaint(
                                    painter: _LineChartPainter(),
                                  ),
                                ),
                              ),
                              const Positioned(
                                bottom: 8, left: 16, right: 16,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Aug 04', style: TextStyle(fontSize: 10, color: LabelLensColors.textTertiary)),
                                    Text('Aug 14', style: TextStyle(fontSize: 10, color: LabelLensColors.textTertiary)),
                                    Text('Aug 26', style: TextStyle(fontSize: 10, color: LabelLensColors.textTertiary)),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: LabelLensSpacing.s6),

                  _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Top Violated Rules', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: LabelLensSpacing.s4),
                        _RuleBar(rule: 'Rule 7(4)', desc: 'Font Size', pct: 0.9),
                        _RuleBar(rule: 'Rule 6(1)(e)', desc: 'MRP format', pct: 0.7),
                        _RuleBar(rule: 'Rule 6(1)(h)', desc: 'Consumer care', pct: 0.5),
                        _RuleBar(rule: 'Rule 6(11)', desc: 'Unit sale price', pct: 0.3),
                        _RuleBar(rule: 'Rule 6(10)', desc: 'Missing declarations', pct: 0.2),
                      ],
                    ),
                  ),
                  const SizedBox(height: LabelLensSpacing.s6),

                  _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('By Category', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: LabelLensSpacing.s4),
                        Container(
                          height: 150,
                          alignment: Alignment.center,
                          child: CustomPaint(
                            size: const Size(120, 120),
                            painter: _PieChartPainter(),
                            child: const SizedBox(
                              width: 120,
                              height: 120,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _LegendItem(color: LabelLensColors.brandPrimary, label: 'Cosmetics'),
                            SizedBox(width: 12),
                            _LegendItem(color: LabelLensColors.statusWarn, label: 'Electronics'),
                            SizedBox(width: 12),
                            _LegendItem(color: LabelLensColors.textSecondary, label: 'Food'),
                          ],
                        )
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 100), // Padding for the floating bottom bar
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(LabelLensSpacing.s5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final bool isPositive;
  const _KpiCard({required this.title, required this.value, required this.trend, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: LabelLensColors.textSecondary)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: LabelLensColors.textPrimary)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                size: 14,
                color: isPositive ? LabelLensColors.statusPass : LabelLensColors.statusFail,
              ),
              const SizedBox(width: 4),
              Text(
                trend,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? LabelLensColors.statusPass : LabelLensColors.statusFail,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RuleBar extends StatelessWidget {
  final String rule;
  final String desc;
  final double pct;
  const _RuleBar({required this.rule, required this.desc, required this.pct});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(rule, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: LabelLensColors.textPrimary)),
              Text(desc, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: LabelLensColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(color: LabelLensColors.surface2, borderRadius: BorderRadius.circular(4)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pct,
              child: Container(
                decoration: BoxDecoration(
                  color: LabelLensColors.brandPrimary,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: LabelLensColors.brandPrimary.withOpacity(0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: LabelLensColors.textSecondary, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = LabelLensColors.brandPrimary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final points = [
      Offset(0, size.height * 0.8),
      Offset(size.width * 0.2, size.height * 0.6),
      Offset(size.width * 0.4, size.height * 0.7),
      Offset(size.width * 0.6, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.4),
      Offset(size.width, size.height * 0.1),
    ];

    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      path.quadraticBezierTo(
        p0.dx + (p1.dx - p0.dx) / 2, p0.dy,
        p0.dx + (p1.dx - p0.dx) / 2, (p0.dy + p1.dy) / 2,
      );
      path.quadraticBezierTo(
        p0.dx + (p1.dx - p0.dx) / 2, p1.dy,
        p1.dx, p1.dy,
      );
    }
    
    // Add gradient fill under the line
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [LabelLensColors.brandPrimary.withOpacity(0.3), LabelLensColors.brandPrimary.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PieChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Food (74)
    final paint1 = Paint()
      ..color = LabelLensColors.textSecondary
      ..style = PaintingStyle.fill;
    canvas.drawArc(rect, -0.5 * 3.14, 1.2 * 3.14, true, paint1);

    // Cosmetics (37)
    final paint2 = Paint()
      ..color = LabelLensColors.brandPrimary
      ..style = PaintingStyle.fill;
    canvas.drawArc(rect, 0.7 * 3.14, 0.8 * 3.14, true, paint2);

    // Electronics (25)
    final paint3 = Paint()
      ..color = LabelLensColors.statusWarn
      ..style = PaintingStyle.fill;
    canvas.drawArc(rect, 1.5 * 3.14, 0.4 * 3.14, true, paint3);
    
    // Inner hole for donut shape
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.6, innerPaint);
    
    // Draw text labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    
    void drawText(String text, Offset offset, Color color) {
      textPainter.text = TextSpan(text: text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold));
      textPainter.layout();
      textPainter.paint(canvas, offset - Offset(textPainter.width / 2, textPainter.height / 2));
    }

    drawText('74', center + const Offset(35, -20), Colors.white);
    drawText('37', center + const Offset(-30, 25), Colors.white);
    drawText('25', center + const Offset(15, 35), Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
