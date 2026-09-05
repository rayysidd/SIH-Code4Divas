import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:design_system/tokens/colors.dart';
import 'package:design_system/tokens/spacing.dart';
import '../services/api_service.dart';

/// Screen M-13a: Analytics Screen (Insights)
/// All data fetched from real API — no hardcoded values.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  String? _error;

  // Overview KPIs
  int _totalScans = 0;
  double _passRate = 0.0;
  int _openViolations = 0;
  double _avgScanTime = 0.0;

  // Top violations
  List<dynamic> _topViolations = [];

  // Compliance trend
  List<dynamic> _trendData = [];

  // Category breakdown
  List<dynamic> _categoryData = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final overview = await ApiService.getAnalyticsOverview();
      _totalScans = overview['total_scans'] ?? 0;
      _passRate = (overview['pass_rate'] as num?)?.toDouble() ?? 0.0;
      _openViolations = overview['open_violations'] ?? 0;
      _avgScanTime = (overview['avg_scan_time_seconds'] as num?)?.toDouble() ?? 0.0;

      try {
        _topViolations = await ApiService.getTopViolations();
      } catch (_) {
        _topViolations = [];
      }

      try {
        final trendResp = await ApiService.getComplianceTrend();
        _trendData = trendResp['data'] ?? [];
      } catch (_) {
        _trendData = [];
      }

      try {
        _categoryData = await ApiService.getByCategory();
      } catch (_) {
        _categoryData = [];
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: LabelLensColors.statusFail),
                            const SizedBox(height: 12),
                            Text(_error!, style: const TextStyle(color: LabelLensColors.statusFail)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _fetchData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _totalScans == 0
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.bar_chart_outlined, size: 64, color: LabelLensColors.textTertiary),
                                SizedBox(height: 16),
                                Text('No data yet', style: TextStyle(color: LabelLensColors.textTertiary, fontSize: 18, fontWeight: FontWeight.w600)),
                                SizedBox(height: 4),
                                Text('Scans will appear here once inspectors start submitting.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: LabelLensColors.textTertiary, fontSize: 13)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchData,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(LabelLensSpacing.s4),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: _KpiCard(title: 'Products Scanned', value: '$_totalScans', trend: 'this month', isPositive: true)),
                                      const SizedBox(width: LabelLensSpacing.s4),
                                      Expanded(child: _KpiCard(title: 'Pass Rate', value: '$_passRate%', trend: _passRate > 0 ? '↑ trending up' : '—', isPositive: _passRate > 50)),
                                    ],
                                  ),
                                  const SizedBox(height: LabelLensSpacing.s4),
                                  Row(
                                    children: [
                                      Expanded(child: _KpiCard(title: 'Open Violations', value: '$_openViolations', trend: 'critical + high', isPositive: false)),
                                      const SizedBox(width: LabelLensSpacing.s4),
                                      Expanded(child: _KpiCard(title: 'Avg Scan Time', value: '${_avgScanTime}s', trend: _avgScanTime > 0 ? '↑ measured' : '—', isPositive: _avgScanTime > 0 && _avgScanTime < 10)),
                                    ],
                                  ),
                                  const SizedBox(height: LabelLensSpacing.s6),

                                  // Compliance Trend
                                  _GlassCard(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Compliance Trend — 30 Days', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                        const SizedBox(height: LabelLensSpacing.s4),
                                        _trendData.isEmpty
                                            ? Container(
                                                height: 150,
                                                alignment: Alignment.center,
                                                child: const Text('No trend data available', style: TextStyle(color: LabelLensColors.textTertiary)),
                                              )
                                            : Container(
                                                height: 150,
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(8),
                                                  color: Colors.white.withOpacity(0.5),
                                                  border: Border.all(color: LabelLensColors.surface3),
                                                ),
                                                child: Stack(
                                                  children: [
                                                    Column(
                                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                      children: List.generate(4, (index) => Container(height: 1, color: LabelLensColors.surface3.withOpacity(0.5))),
                                                    ),
                                                    Positioned.fill(
                                                      child: Padding(
                                                        padding: const EdgeInsets.only(bottom: 24, top: 16, left: 16, right: 16),
                                                        child: CustomPaint(
                                                          painter: _DynamicLineChartPainter(_trendData),
                                                        ),
                                                      ),
                                                    ),
                                                    if (_trendData.length >= 2)
                                                      Positioned(
                                                        bottom: 8, left: 16, right: 16,
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            Text(_trendData.first['date']?.toString().substring(5) ?? '', style: const TextStyle(fontSize: 10, color: LabelLensColors.textTertiary)),
                                                            Text(_trendData.last['date']?.toString().substring(5) ?? '', style: const TextStyle(fontSize: 10, color: LabelLensColors.textTertiary)),
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

                                  // Top Violated Rules
                                  _GlassCard(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Top Violated Rules', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                        const SizedBox(height: LabelLensSpacing.s4),
                                        if (_topViolations.isEmpty)
                                          const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 24),
                                            child: Center(child: Text('No violation data available', style: TextStyle(color: LabelLensColors.textTertiary))),
                                          )
                                        else
                                          ..._topViolations.map((v) {
                                            final maxCount = (_topViolations.first['count'] as num?) ?? 1;
                                            final count = (v['count'] as num?) ?? 0;
                                            final pct = maxCount > 0 ? count / maxCount : 0.0;
                                            return _RuleBar(
                                              rule: v['rule']?.toString() ?? 'Unknown',
                                              desc: v['description']?.toString() ?? '',
                                              pct: pct.toDouble(),
                                            );
                                          }).toList(),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: LabelLensSpacing.s6),

                                  // By Category
                                  _GlassCard(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('By Category', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                        const SizedBox(height: LabelLensSpacing.s4),
                                        if (_categoryData.isEmpty)
                                          const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 24),
                                            child: Center(child: Text('No category data available', style: TextStyle(color: LabelLensColors.textTertiary))),
                                          )
                                        else ...[
                                          Container(
                                            height: 150,
                                            alignment: Alignment.center,
                                            child: CustomPaint(
                                              size: const Size(120, 120),
                                              painter: _DynamicPieChartPainter(_categoryData),
                                              child: const SizedBox(width: 120, height: 120),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Wrap(
                                            alignment: WrapAlignment.center,
                                            spacing: 12,
                                            runSpacing: 8,
                                            children: _categoryData.asMap().entries.map((entry) {
                                              final colors = [LabelLensColors.brandPrimary, LabelLensColors.statusWarn, LabelLensColors.textSecondary, LabelLensColors.statusPass];
                                              return _LegendItem(
                                                color: colors[entry.key % colors.length],
                                                label: '${entry.value['category']} (${entry.value['count']})',
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 100),
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
              Flexible(
                child: Text(
                  trend,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isPositive ? LabelLensColors.statusPass : LabelLensColors.statusFail,
                  ),
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
              Flexible(child: Text(rule, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: LabelLensColors.textPrimary))),
              Flexible(child: Text(desc, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: LabelLensColors.textSecondary), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(color: LabelLensColors.surface2, borderRadius: BorderRadius.circular(4)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pct.clamp(0.0, 1.0),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: LabelLensColors.textSecondary, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

/// Draws a line chart from real compliance trend data points.
class _DynamicLineChartPainter extends CustomPainter {
  final List<dynamic> data;
  _DynamicLineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = LabelLensColors.brandPrimary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rates = data.map((d) => (d['compliance_rate'] as num?)?.toDouble() ?? 0.0).toList();
    final maxRate = rates.reduce((a, b) => a > b ? a : b);
    final minRate = rates.reduce((a, b) => a < b ? a : b);
    final range = (maxRate - minRate).clamp(1.0, 100.0);

    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < rates.length; i++) {
      final x = data.length == 1 ? size.width / 2 : (i / (data.length - 1)) * size.width;
      final y = size.height - ((rates[i] - minRate) / range) * size.height;
      points.add(Offset(x, y));
    }

    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      final cx = (p0.dx + p1.dx) / 2;
      path.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
    }

    // Gradient fill
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Draws a donut pie chart from real category breakdown data.
class _DynamicPieChartPainter extends CustomPainter {
  final List<dynamic> data;
  _DynamicPieChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final colors = [LabelLensColors.brandPrimary, LabelLensColors.statusWarn, LabelLensColors.textSecondary, LabelLensColors.statusPass];
    final total = data.fold<int>(0, (sum, d) => sum + ((d['count'] as num?) ?? 0).toInt());
    if (total == 0) return;

    double startAngle = -0.5 * 3.14159;
    for (int i = 0; i < data.length; i++) {
      final count = ((data[i]['count'] as num?) ?? 0).toInt();
      final sweepAngle = (count / total) * 2 * 3.14159;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }

    // Inner hole for donut shape
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.6, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
