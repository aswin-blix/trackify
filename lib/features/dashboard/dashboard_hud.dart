import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/investments.dart';
import '../../data/models/transaction_model.dart';
import '../../shared/widgets/animated_counter.dart';
import '../../shared/widgets/hud.dart';

/// Spending per day of the current month, index 0 = the 1st.
List<double> dailySpendThisMonth(
    Iterable<TransactionModel> transactions, DateTime now) {
  final days = DateTime(now.year, now.month + 1, 0).day;
  final out = List<double>.filled(days, 0);
  for (final t in transactions) {
    if (t.type != TransactionType.expense) continue;
    if (t.date.year != now.year || t.date.month != now.month) continue;
    out[t.date.day - 1] += t.amount;
  }
  return out;
}

/// Name with a blinking cursor, the date read-out, and the month runway:
/// one tick per day, past days as tall as that day's spending, today amber.
class HudDashHeader extends StatefulWidget {
  final String name;
  final List<double> dailySpend;
  final Widget? trailing;

  const HudDashHeader({
    super.key,
    required this.name,
    required this.dailySpend,
    this.trailing,
  });

  @override
  State<HudDashHeader> createState() => _HudDashHeaderState();
}

class _HudDashHeaderState extends State<HudDashHeader>
    with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))
    ..forward();
  late final AnimationController _blink = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat();

  @override
  void dispose() {
    _enter.dispose();
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final still = MediaQuery.disableAnimationsOf(context);
    final days = widget.dailySpend.length;
    final peak = widget.dailySpend.fold(0.0, math.max);
    final name = widget.name.trim().isEmpty ? 'TRACKIFY' : widget.name.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                name.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.display(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Hud.text,
                    letterSpacing: 3),
              ),
            ),
            AnimatedBuilder(
              animation: _blink,
              builder: (_, __) => Opacity(
                opacity: still || _blink.value < 0.5 ? 1 : 0,
                child: Text('_',
                    style: AppFonts.display(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Hud.amber)),
              ),
            ),
            const Spacer(),
            Text(
              '${DateFormat('MMM yyyy').format(now).toUpperCase()} · DAY ${now.day}/$days',
              style: AppFonts.mono(color: Hud.muted),
            ),
            if (widget.trailing != null) ...[
              const SizedBox(width: 10),
              widget.trailing!,
            ],
          ],
        ),
        const SizedBox(height: 8),
        Semantics(
          label: 'Day ${now.day} of $days this month',
          child: SizedBox(
            height: 14,
            child: AnimatedBuilder(
              animation: _enter,
              builder: (_, __) => Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < days; i++)
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: i == days - 1 ? 0 : 3),
                        height: _tickHeight(i, now.day, peak, still),
                        color: i == now.day - 1
                            ? Hud.amber
                            : i < now.day
                                ? Hud.cyan
                                : Hud.cyan.withValues(alpha: 0.25),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Ticks rise one after another, left to right.
  double _tickHeight(int i, int today, double peak, bool still) {
    if (i >= today) return 4;
    final full = 4.0 + (peak > 0 ? 10 * widget.dailySpend[i] / peak : 0.0);
    if (still) return full;
    final start = i * 0.02;
    final t = ((_enter.value - start) / 0.4).clamp(0.0, 1.0);
    return full * Curves.easeOutCubic.transform(t);
  }
}

/// The main panel: available balance inside a half-circle gauge (how much
/// of the budget or income is spent, against how much of the month is gone),
/// then Income / Spent / Saved as level meters. Slow waves drift along the
/// bottom and a scan line travels down the panel.
class HudBalancePanel extends StatefulWidget {
  final PortfolioSummary portfolio;
  final double income;
  final double expense;
  final double saved;
  final double? monthlyBudget;
  final String symbol;

  const HudBalancePanel({
    super.key,
    required this.portfolio,
    required this.income,
    required this.expense,
    required this.saved,
    required this.monthlyBudget,
    required this.symbol,
  });

  @override
  State<HudBalancePanel> createState() => _HudBalancePanelState();
}

class _HudBalancePanelState extends State<HudBalancePanel>
    with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800))
    ..forward();
  late final AnimationController _flow =
      AnimationController(vsync: this, duration: const Duration(seconds: 14))
        ..repeat();

  @override
  void didUpdateWidget(HudBalancePanel old) {
    super.didUpdateWidget(old);
    // New numbers: sweep the gauge and meters to their new values.
    if (old.expense != widget.expense ||
        old.income != widget.income ||
        old.saved != widget.saved) {
      _enter.forward(from: 0.35);
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    _flow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final now = DateTime.now();
    final days = DateTime(now.year, now.month + 1, 0).day;
    final monthGone = now.day / days;
    final budget = widget.monthlyBudget;
    final hasBudget = budget != null && budget > 0;
    final base = hasBudget ? budget : widget.income;
    final used = base > 0 ? widget.expense / base : 0.0;
    final pct = (used * 100).round();
    final caption = base <= 0
        ? 'MONTH GONE ${(monthGone * 100).round()}%'
        : '${hasBudget ? 'BUDGET USED' : 'SPENT'} $pct%'
            '${hasBudget ? '' : ' OF INCOME'} · MONTH GONE ${(monthGone * 100).round()}%';
    final over = used > monthGone + 0.05 && base > 0;
    final scale =
        [widget.income, widget.expense, widget.saved.abs()].fold(0.0, math.max);
    double share(double v) => scale > 0 ? v / scale : 0;
    final savedPct = widget.income > 0 && widget.saved > 0
        ? ' ${(widget.saved / widget.income * 100).round()}%'
        : '';

    return HudFrame(
      tabWidth: 178,
      child: AnimatedBuilder(
        animation: Listenable.merge([_enter, _flow]),
        builder: (context, _) {
          final t = still ? 1.0 : Curves.easeOutCubic.transform(_enter.value);
          return Stack(
            children: [
              if (!still)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _FlowPainter(phase: _flow.value),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 18,
                      child: Text(
                        widget.portfolio.hasBreakdown
                            ? 'AVAILABLE TO SPEND'
                            : 'TOTAL BALANCE',
                        style: AppFonts.label(color: Hud.cyan),
                      ),
                    ),
                    const SizedBox(height: 10),
                    AspectRatio(
                      aspectRatio: 240 / 128,
                      child: CustomPaint(
                        painter: _GaugePainter(
                          used: used.clamp(0.0, 1.0) * t,
                          monthGone: monthGone * t,
                          over: over,
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: AnimatedCounter(
                                  value: widget.portfolio.available,
                                  prefix: widget.symbol,
                                  decimalPlaces: 0,
                                  style: AppFonts.display(
                                    fontSize: 30,
                                    color: widget.portfolio.available < 0
                                        ? HudColors.expenseRed
                                        : Hud.cyan,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(caption,
                                    style: AppFonts.mono(color: Hud.muted)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _meter('INCOME', widget.income, HudColors.incomeGreen,
                            share(widget.income), t),
                        const SizedBox(width: 12),
                        _meter('SPENT', widget.expense, HudColors.expenseRed,
                            share(widget.expense), t),
                        if (widget.portfolio.hasBreakdown) ...[
                          const SizedBox(width: 12),
                          _meter(
                              widget.saved < 0 ? 'WITHDRAWN' : 'SAVED$savedPct',
                              widget.saved.abs(),
                              Hud.amber,
                              share(widget.saved.abs()),
                              t),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _meter(String label, double value, Color color, double share,
          double reveal) =>
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.label(color: Hud.muted, fontSize: 9)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: AnimatedCounter(
                value: value,
                prefix: widget.symbol,
                decimalPlaces: 0,
                style: AppFonts.display(fontSize: 14, color: color),
              ),
            ),
            const SizedBox(height: 5),
            HudSegments(value: share, color: color, reveal: reveal),
          ],
        ),
      );
}

class _GaugePainter extends CustomPainter {
  final double used;
  final double monthGone;
  final bool over;

  const _GaugePainter(
      {required this.used, required this.monthGone, required this.over});

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.min(size.width / 2, size.height) - 12;
    final center = Offset(size.width / 2, size.height - 6);
    final outer = Rect.fromCircle(center: center, radius: r);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..color = Hud.cyan.withValues(alpha: 0.22);
    // Dashed track: short ticks all the way round the half circle.
    const ticks = 48;
    for (var i = 0; i < ticks; i++) {
      canvas.drawArc(outer, math.pi + math.pi * i / ticks,
          math.pi / ticks * 0.4, false, track);
    }
    canvas.drawArc(
      outer,
      math.pi,
      math.pi * used,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..color = over ? HudColors.expenseRed : Hud.cyan,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r - 14),
      math.pi,
      math.pi * monthGone.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Hud.amber,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.used != used || old.monthGone != monthGone || old.over != over;
}

/// Two slow waves along the bottom edge and a faint scan line moving down.
class _FlowPainter extends CustomPainter {
  /// 0..1, loops.
  final double phase;
  const _FlowPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    void wave(double height, double amp, double shift, Color color) {
      final path = Path()..moveTo(0, size.height);
      for (var x = 0.0; x <= size.width; x += 4) {
        final y = size.height -
            height +
            amp * math.sin(x / size.width * 4 * math.pi + shift);
        path.lineTo(x, y);
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }

    final a = phase * 2 * math.pi;
    wave(30, 9, a * 2, Hud.cyan.withValues(alpha: 0.12));
    wave(20, 7, -a + 1.6, Hud.amber.withValues(alpha: 0.09));

    final y = (phase * 3 % 1) * (size.height + 40) - 40;
    final band = Rect.fromLTWH(0, y, size.width, 40);
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Hud.cyan.withValues(alpha: 0),
            Hud.cyan.withValues(alpha: 0.09),
          ],
        ).createShader(band),
    );
  }

  @override
  bool shouldRepaint(_FlowPainter old) => old.phase != phase;
}

/// Net worth as one bar: cash, invested (today's value) and what is owed.
class HudNetWorthBar extends StatelessWidget {
  final PortfolioSummary portfolio;
  final String symbol;
  final VoidCallback? onTap;

  const HudNetWorthBar({
    super.key,
    required this.portfolio,
    required this.symbol,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = portfolio;
    String money(double v) => AppFormatters.formatAmountCompact(v, symbol);
    final cash = math.max(p.available, 0.0);
    final invested = math.max(p.investedValue, 0.0);
    final owed = math.max(-p.loans, 0.0);
    final total = cash + invested + owed;
    int flex(double v) => total > 0 ? (v / total * 1000).round() : 0;
    final ratio = p.gainRatio;
    final gain = ratio == null || p.gain.abs() < 1
        ? ''
        : ' ${p.gain >= 0 ? '+' : '−'}${(ratio.abs() * 100).toStringAsFixed(1)}%';

    Widget legend(String mark, Color color, String text) => Flexible(
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: '$mark ', style: TextStyle(color: color)),
              TextSpan(text: text),
            ]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.mono(color: Hud.muted, fontSize: 11),
          ),
        );

    return GestureDetector(
      onTap: onTap,
      child: HudFrame(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('NET WORTH', style: AppFonts.label(color: Hud.muted)),
                Text(
                  '${p.netWorth < 0 ? '−' : ''}${AppFormatters.formatAmount(p.netWorth, symbol)}',
                  style: AppFonts.display(
                      fontSize: 15,
                      color: p.netWorth < 0 ? HudColors.expenseRed : Hud.text),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (_, t, child) => ClipRect(
                child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: t,
                    child: child),
              ),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: [
                    if (flex(cash) > 0)
                      Expanded(
                          flex: flex(cash), child: Container(color: Hud.cyan)),
                    if (flex(invested) > 0) ...[
                      const SizedBox(width: 3),
                      Expanded(
                          flex: flex(invested),
                          child: Container(color: Hud.amber)),
                    ],
                    if (flex(owed) > 0) ...[
                      const SizedBox(width: 3),
                      Expanded(
                        flex: flex(owed),
                        child: const CustomPaint(painter: _HatchPainter()),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                legend('■', Hud.cyan, 'CASH ${money(p.available)}'),
                if (p.hasInvestments)
                  legend('■', Hud.amber,
                      'INVESTED ${money(p.investedValue)}$gain'),
                if (p.hasLoans)
                  legend('▨', HudColors.expenseRed, 'OWED ${money(p.loans)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Diagonal stripes: "owed" reads differently from the solid segments even
/// without colour.
class _HatchPainter extends CustomPainter {
  const _HatchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    final paint = Paint()
      ..color = HudColors.expenseRed
      ..strokeWidth = 2.5;
    for (var x = -size.height; x < size.width; x += 6) {
      canvas.drawLine(
          Offset(x, size.height), Offset(x + size.height, 0), paint);
    }
  }

  @override
  bool shouldRepaint(_HatchPainter old) => false;
}
