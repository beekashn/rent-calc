import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/rent_bill.dart';

/* ===================== helpers ===================== */

String compactNum(num n) {
  final v = n.toDouble().abs();
  if (v >= 1000000000) {
    return '${(n / 1000000000).toStringAsFixed(1)}B';
  }
  if (v >= 1000000) {
    return '${(n / 1000000).toStringAsFixed(1)}M';
  }
  if (v >= 1000) {
    return '${(n / 1000).toStringAsFixed(1)}K';
  }
  return n.round().toString();
}

double niceInterval(double maxY) {
  if (maxY <= 0) {
    return 1;
  }
  final raw = maxY / 4;
  final pow10 = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  final d = raw / pow10;
  final nice = (d < 1.5)
      ? 1
      : (d < 3)
      ? 2
      : (d < 7)
      ? 5
      : 10;
  return nice * pow10;
}

/* ===================== dashboard ===================== */

class DashboardTab extends StatefulWidget {
  final List<RentBill> bills;

  const DashboardTab({super.key, required this.bills});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  int? _selectedBsYear; // null = All

  // Custom Nepali group formatting: 1,23,456
  String _fmtNepali(num value) {
    String str = value.round().toString();
    if (str.length <= 3) {
      return str;
    }

    String lastThree = str.substring(str.length - 3);
    String otherNumbers = str.substring(0, str.length - 3);

    if (otherNumbers != '') {
      lastThree = ',$lastThree';
    }

    String res = otherNumbers.replaceAllMapped(
      RegExp(r'(\d+?)(?=(\d{2})+(?!\d))'),
      (Match m) => '${m[1]},',
    );

    return res + lastThree;
  }

  /// Extract BS year from monthYear text.
  /// Supports: "Baisakh 2083", "2083/01", "2083-02", etc.
  int? _bsYearOf(RentBill b) {
    final s = b.monthYear.trim();
    final m = RegExp(r'\b(20\d{2}|21\d{2})\b').firstMatch(s);
    if (m != null) {
      return int.tryParse(m.group(1)!);
    }

    final m2 = RegExp(r'\b(\d{4})\b').firstMatch(s);
    if (m2 != null) {
      return int.tryParse(m2.group(1)!);
    }

    return null;
  }

  List<int> _availableBsYears(List<RentBill> bills) {
    final years = <int>{};
    for (final b in bills) {
      final y = _bsYearOf(b);
      if (y != null) {
        years.add(y);
      }
    }
    final list = years.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }

  List<RentBill> _filteredBills() {
    if (_selectedBsYear == null) {
      return widget.bills;
    }
    return widget.bills.where((b) => _bsYearOf(b) == _selectedBsYear).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (widget.bills.isEmpty) {
      return _buildEmptyState(context); //  now referenced (no unused warning)
    }

    final years = _availableBsYears(widget.bills);
    final filteredBills = _filteredBills();
    final monthly = _buildMonthlyStats(filteredBills);

    // If filtering results in no months, show message + filter
    if (monthly.isEmpty) {
      return SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _YearFilterRow(
                years: years,
                selectedYear: _selectedBsYear,
                onChanged: (val) => setState(() => _selectedBsYear = val),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.filter_alt_off_rounded,
                      size: 48,
                      color: theme.disabledColor.withValues(alpha: 0.35),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No data for selected year',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select a different year or choose "All".',
                      style: TextStyle(color: theme.hintColor),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Latest + previous within filtered set
    final latestStat = monthly.last;
    final prevStat = monthly.length >= 2 ? monthly[monthly.length - 2] : null;

    final thisMonthTotal = latestStat.total;
    final lastMonthTotal = prevStat?.total ?? 0.0;

    final totalSpent = monthly.map((e) => e.total).reduce((a, b) => a + b);
    final totalUnits = monthly.map((e) => e.units).reduce((a, b) => a + b);
    final avgCost = totalSpent / monthly.length;
    final avgUnits = totalUnits / monthly.length;

    double? trendPercent;
    double diffAmount = 0;
    if (prevStat != null && lastMonthTotal > 0) {
      diffAmount = thisMonthTotal - lastMonthTotal;
      trendPercent = (diffAmount / lastMonthTotal) * 100;
    }

    final thisMonthUnits = latestStat.units;

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. STATS ROW
            Row(
              children: [
                Expanded(
                  child: _ProStatCard(
                    title: 'Current Bill',
                    value: 'Rs. ${_fmtNepali(thisMonthTotal.round())}',
                    icon: Icons.account_balance_wallet_rounded,
                    color: cs.primary,
                    trendPercent: trendPercent,
                    inverseTrend: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ProStatCard(
                    title: 'Usage',
                    value: '${_fmtNepali(thisMonthUnits)} Units',
                    icon: Icons.bolt_rounded,
                    color: Colors.orange,
                    trendPercent: (prevStat != null && prevStat.units > 0)
                        ? ((thisMonthUnits - prevStat.units) / prevStat.units) *
                              100
                        : null,
                    inverseTrend: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 2) Year filter (BS)
            _YearFilterRow(
              years: years,
              selectedYear: _selectedBsYear,
              onChanged: (val) => setState(() => _selectedBsYear = val),
            ),

            const SizedBox(height: 16),

            // 3) Cost chart
            _ChartContainer(
              title: 'Cost History',
              subtitle: 'Red: Highest • Green: Lowest',
              action: _TrendBadge(val: trendPercent, inverse: true),
              child: _ThreeDBarChart(
                monthlyStats: monthly,
                primary: cs.primary,
                avgCost: avgCost,
                fmt: _fmtNepali,
              ),
            ),

            const SizedBox(height: 16),

            // 4) Usage chart (works with 1 record)
            _ChartContainer(
              title: 'Consumption Trend',
              subtitle: 'Electricity units vs Average',
              child: _MonthlyUnitsLineChart(
                monthlyStats: monthly,
                primary: cs.primary,
                avgUnits: avgUnits,
              ),
            ),

            const SizedBox(height: 24),

            //  DOTTED Deep Dive header
            _DottedSectionTitle(
              text: _selectedBsYear == null
                  ? 'DEEP DIVE (All Time)'
                  : 'DEEP DIVE (${_selectedBsYear!} BS)',
            ),

            const SizedBox(height: 12),

            _AnalyticsList(
              monthlyStats: monthly,
              totalSpent: totalSpent,
              totalUnits: totalUnits,
              diffAmount: diffAmount,
              prevStat: prevStat,
              fmt: _fmtNepali,
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 64,
            color: theme.disabledColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Data Available',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Save a bill to see analytics.',
            style: TextStyle(color: theme.hintColor),
          ),
        ],
      ),
    );
  }

  List<MonthlyStat> _buildMonthlyStats(List<RentBill> bills) {
    final map = <String, _Agg>{};
    for (final b in bills) {
      final key = b.monthYear.trim();
      final existing = map[key];
      if (existing == null) {
        map[key] = _Agg(
          month: key,
          total: b.total,
          units: b.units,
          latestCreatedAt: b.createdAt,
        );
      } else {
        existing.total += b.total;
        existing.units += b.units;
        if (b.createdAt.isAfter(existing.latestCreatedAt)) {
          existing.latestCreatedAt = b.createdAt;
        }
      }
    }

    final list = map.values
        .map(
          (a) => MonthlyStat(
            month: a.month,
            total: a.total,
            units: a.units,
            date: a.latestCreatedAt,
          ),
        )
        .toList();

    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }
}

/* ===================== dotted title ===================== */

class _DottedSectionTitle extends StatelessWidget {
  final String text;

  const _DottedSectionTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: _DashedLine(
            height: 1,
            dashWidth: 4,
            dashGap: 4,
            color: theme.dividerColor.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: theme.hintColor.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _DashedLine(
            height: 1,
            dashWidth: 4,
            dashGap: 4,
            color: theme.dividerColor.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class _DashedLine extends StatelessWidget {
  final double height;
  final double dashWidth;
  final double dashGap;
  final Color color;

  const _DashedLine({
    required this.height,
    required this.dashWidth,
    required this.dashGap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _DashedLinePainter(
          dashWidth: dashWidth,
          dashGap: dashGap,
          color: color,
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final double dashWidth;
  final double dashGap;
  final Color color;

  _DashedLinePainter({
    required this.dashWidth,
    required this.dashGap,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height
      ..style = PaintingStyle.stroke;

    double x = 0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + dashWidth, y), paint);
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) {
    return oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashGap != dashGap ||
        oldDelegate.color != color;
  }
}

/* ===================== Year Filter UI ===================== */

class _YearFilterRow extends StatelessWidget {
  final List<int> years;
  final int? selectedYear; // null = All
  final ValueChanged<int?> onChanged;

  const _YearFilterRow({
    required this.years,
    required this.selectedYear,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_month_rounded,
            size: 18,
            color: theme.hintColor.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 10),
          Text(
            'Year (BS)',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              value: selectedYear,
              borderRadius: BorderRadius.circular(12),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(
                    'All',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ...years.map(
                  (y) => DropdownMenuItem<int?>(
                    value: y,
                    child: Text(
                      y.toString(),
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/* ===================== models ===================== */

class MonthlyStat {
  final String month;
  final double total;
  final int units;
  final DateTime date;

  MonthlyStat({
    required this.month,
    required this.total,
    required this.units,
    required this.date,
  });
}

class _Agg {
  final String month;
  double total;
  int units;
  DateTime latestCreatedAt;

  _Agg({
    required this.month,
    required this.total,
    required this.units,
    required this.latestCreatedAt,
  });
}

/* ===================== UI Components ===================== */

class _ProStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double? trendPercent;
  final bool inverseTrend;

  const _ProStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trendPercent,
    this.inverseTrend = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              if (trendPercent != null) ...[
                _TrendPill(percent: trendPercent!, inverse: inverseTrend),
              ],
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title.toUpperCase(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.hintColor,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendPill extends StatelessWidget {
  final double percent;
  final bool inverse;

  const _TrendPill({required this.percent, required this.inverse});

  @override
  Widget build(BuildContext context) {
    final isUp = percent > 0;
    final isGood = inverse ? !isUp : isUp;

    final color = isGood ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '${percent.abs().toStringAsFixed(0)}%',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartContainer extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;

  const _ChartContainer({
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (action != null) ...[action!],
            ],
          ),
          const SizedBox(height: 24),
          AspectRatio(aspectRatio: 1.6, child: child),
        ],
      ),
    );
  }
}

/* ===================== Charts ===================== */

class _ThreeDBarChart extends StatelessWidget {
  final List<MonthlyStat> monthlyStats;
  final Color primary;
  final double avgCost;
  final String Function(num) fmt;

  const _ThreeDBarChart({
    required this.monthlyStats,
    required this.primary,
    required this.avgCost,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    if (monthlyStats.isEmpty) {
      return const SizedBox();
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final maxY = monthlyStats.map((e) => e.total).reduce(math.max);
    final minY = monthlyStats.map((e) => e.total).reduce(math.min);

    final effectiveMax = math.max(maxY, avgCost);
    final niceMaxY = effectiveMax <= 0 ? 1.0 : effectiveMax * 1.25;
    final interval = niceInterval(niceMaxY);

    final avgLine = HorizontalLine(
      y: avgCost,
      color: Colors.green.withValues(alpha: 0.5),
      strokeWidth: 2,
      dashArray: [5, 5],
      label: HorizontalLineLabel(
        show: true,
        alignment: Alignment.topRight,
        padding: const EdgeInsets.only(right: 6, bottom: 4),
        style: TextStyle(
          color: Colors.green.withValues(alpha: 0.7),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
        labelResolver: (_) => 'AVG: Rs. ${compactNum(avgCost)}',
      ),
    );

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: niceMaxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            tooltipMargin: 0,
            getTooltipColor: (_) => cs.onSurface,
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${monthlyStats[group.x].month}\n',
                TextStyle(
                  color: cs.surface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                children: [
                  TextSpan(
                    text: 'Rs. ${fmt(rod.toY.round())}',
                    style: TextStyle(
                      color: cs.surface,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        extraLinesData: ExtraLinesData(horizontalLines: [avgLine]),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: interval,
              getTitlesWidget: (val, meta) {
                if (val == 0) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    compactNum(val),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: theme.hintColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx < 0 || idx >= monthlyStats.length) {
                  return const SizedBox();
                }
                if (monthlyStats.length > 6 && idx % 2 != 0) {
                  return const SizedBox();
                }

                final m = monthlyStats[idx].month.split(' ').first;
                return Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    m.substring(0, math.min(3, m.length)).toUpperCase(),
                    style: TextStyle(
                      color: theme.hintColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.dividerColor.withValues(alpha: 0.08),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: monthlyStats.asMap().entries.map((entry) {
          final i = entry.key;
          final stat = entry.value;

          Color barColor = primary;
          if (monthlyStats.length > 2) {
            if (stat.total == maxY) {
              barColor = Colors.redAccent;
            } else if (stat.total == minY && minY > 0) {
              barColor = Colors.green;
            }
          }

          final Color frontFace = barColor;
          final Color sideFace =
              Color.lerp(barColor, Colors.black, 0.35) ?? barColor;

          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: stat.total,
                width: 20,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(3),
                ),
                gradient: LinearGradient(
                  colors: [frontFace, frontFace, sideFace, sideFace],
                  stops: const [0.0, 0.7, 0.7, 1.0],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: niceMaxY,
                  color: theme.dividerColor.withValues(alpha: 0.02),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MonthlyUnitsLineChart extends StatelessWidget {
  final List<MonthlyStat> monthlyStats;
  final Color primary;
  final double avgUnits;

  const _MonthlyUnitsLineChart({
    required this.monthlyStats,
    required this.primary,
    required this.avgUnits,
  });

  @override
  Widget build(BuildContext context) {
    if (monthlyStats.isEmpty) {
      return Center(
        child: Text(
          'No data for this year.',
          style: TextStyle(color: Theme.of(context).hintColor),
        ),
      );
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final maxY = monthlyStats.map((e) => e.units.toDouble()).reduce(math.max);
    final effectiveMax = math.max(maxY, avgUnits);
    final niceMaxY = effectiveMax <= 0 ? 1.0 : effectiveMax * 1.25;
    final interval = niceInterval(niceMaxY);

    final avgLines = <HorizontalLine>[];
    if (avgUnits > 0) {
      avgLines.add(
        HorizontalLine(
          y: avgUnits,
          color: Colors.green.withValues(alpha: 0.5),
          strokeWidth: 2,
          dashArray: [5, 5],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            padding: const EdgeInsets.only(right: 6, bottom: 6),
            style: TextStyle(
              color: Colors.green.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
            labelResolver: (_) => 'AVG: ${avgUnits.toStringAsFixed(0)} u',
          ),
        ),
      );
    }

    //  Single point fix: maxX must be 1.0 so chart has width
    final maxX = monthlyStats.length == 1
        ? 1.0
        : (monthlyStats.length - 1).toDouble();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: 0,
        maxY: niceMaxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.dividerColor.withValues(alpha: 0.08),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 12,
            getTooltipColor: (_) => cs.onSurface,
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            getTooltipItems: (spots) {
              return spots.map((s) {
                final idx = s.x.round().clamp(0, monthlyStats.length - 1);
                final stat = monthlyStats[idx];
                return LineTooltipItem(
                  '${stat.month}\n',
                  TextStyle(
                    color: cs.surface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                  children: [
                    TextSpan(
                      text: '${stat.units} u',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: cs.surface,
                        fontSize: 13,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
        extraLinesData: ExtraLinesData(horizontalLines: avgLines),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: interval,
              getTitlesWidget: (value, meta) {
                if (value == 0) {
                  return const SizedBox.shrink();
                }
                return Text(
                  compactNum(value),
                  style: TextStyle(
                    color: theme.hintColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if (i < 0 || i >= monthlyStats.length) {
                  return const SizedBox.shrink();
                }

                final showEvery = monthlyStats.length <= 6 ? 1 : 2;
                if (monthlyStats.length > 1 && i % showEvery != 0) {
                  return const SizedBox.shrink();
                }

                final m = monthlyStats[i].month.split(' ')[0];
                final label = m.length >= 3 ? m.substring(0, 3) : m;

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      color: theme.hintColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: monthlyStats.length > 2,
            curveSmoothness: 0.35,
            barWidth: 3,
            color: primary,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: theme.cardColor,
                  strokeWidth: 2,
                  strokeColor: primary,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primary.withValues(alpha: 0.25),
                  primary.withValues(alpha: 0.0),
                ],
              ),
            ),
            spots: List.generate(monthlyStats.length, (i) {
              return FlSpot(i.toDouble(), monthlyStats[i].units.toDouble());
            }),
          ),
        ],
      ),
    );
  }
}

/* ===================== Deep Dive list ===================== */

class _AnalyticsList extends StatelessWidget {
  final List<MonthlyStat> monthlyStats;
  final double totalSpent;
  final int totalUnits;
  final double diffAmount;
  final MonthlyStat? prevStat;
  final String Function(num) fmt;

  const _AnalyticsList({
    required this.monthlyStats,
    required this.totalSpent,
    required this.totalUnits,
    required this.diffAmount,
    required this.prevStat,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    if (monthlyStats.isEmpty) {
      return const SizedBox();
    }

    final highestBill = monthlyStats.reduce(
      (curr, next) => curr.total > next.total ? curr : next,
    );
    final lowestBill = monthlyStats.reduce(
      (curr, next) => curr.total < next.total ? curr : next,
    );
    final monthlyAvgCost = totalSpent / monthlyStats.length;
    final avgCostPerUnit = totalUnits > 0 ? totalSpent / totalUnits : 0.0;

    String trendText = "Comparable to previous month";
    IconData trendIcon = Icons.remove;
    Color trendColor = Colors.grey;

    if (prevStat != null) {
      if (diffAmount < 0) {
        trendText = "Rs. ${fmt(diffAmount.abs())} less than last month";
        trendIcon = Icons.trending_down;
        trendColor = Colors.green;
      } else if (diffAmount > 0) {
        trendText = "Rs. ${fmt(diffAmount.abs())} more than last month";
        trendIcon = Icons.trending_up;
        trendColor = Colors.redAccent;
      }
    }

    return Column(
      children: [
        _DetailTile(
          label: 'Comparison',
          value: trendText,
          icon: trendIcon,
          iconColor: trendColor,
          isFullText: true,
        ),
        const SizedBox(height: 12),
        _DetailTile(
          label: 'Average Monthly Cost',
          value: 'Rs. ${fmt(monthlyAvgCost.round())}',
          icon: Icons.functions_rounded,
          iconColor: Colors.blueAccent,
        ),
        const SizedBox(height: 12),
        _DetailTile(
          label: 'Highest Bill',
          value: 'Rs. ${fmt(highestBill.total.toInt())}',
          subValue: highestBill.month.split(' ')[0],
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.orangeAccent,
        ),
        const SizedBox(height: 12),
        _DetailTile(
          label: 'Lowest Bill',
          value: 'Rs. ${fmt(lowestBill.total.toInt())}',
          subValue: lowestBill.month.split(' ')[0],
          icon: Icons.eco_rounded,
          iconColor: Colors.green,
        ),
        const SizedBox(height: 12),
        _DetailTile(
          label: 'Avg. Unit Price',
          value: 'Rs. ${avgCostPerUnit.toStringAsFixed(2)}',
          icon: Icons.electric_meter_rounded,
          iconColor: Colors.purpleAccent,
        ),
        const SizedBox(height: 12),
        _DetailTile(
          label: 'Total Lifetime Spend',
          value: 'Rs. ${fmt(totalSpent.round())}',
          icon: Icons.savings_rounded,
          iconColor: Colors.teal,
          isHero: true,
        ),
      ],
    );
  }
}

class _DetailTile extends StatelessWidget {
  final String label;
  final String value;
  final String? subValue;
  final IconData icon;
  final Color iconColor;
  final bool isHero;
  final bool isFullText;

  const _DetailTile({
    required this.label,
    required this.value,
    this.subValue,
    required this.icon,
    required this.iconColor,
    this.isHero = false,
    this.isFullText = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bgColor = isHero
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
        : theme.colorScheme.surface;

    final borderColor = isHero
        ? theme.colorScheme.primary.withValues(alpha: 0.1)
        : theme.dividerColor.withValues(alpha: 0.05);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: isFullText
                            ? TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: iconColor,
                              )
                            : theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                fontSize: isHero ? 20 : 16,
                                color: isHero
                                    ? theme.colorScheme.onSurface
                                    : null,
                              ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (subValue != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        subValue!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: theme.hintColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  final double? val;
  final bool inverse;

  const _TrendBadge({this.val, this.inverse = false});

  @override
  Widget build(BuildContext context) {
    if (val == null) {
      return const SizedBox();
    }
    final isGood = inverse ? val! < 0 : val! > 0;
    final color = isGood ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        '${val!.abs().toStringAsFixed(1)}%',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
