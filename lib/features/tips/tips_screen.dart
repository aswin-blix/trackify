import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tips_data.dart';

final _favoriteTipsProvider = StateProvider<Set<String>>((ref) => {});

class TipsScreen extends ConsumerStatefulWidget {
  const TipsScreen({super.key});

  @override
  ConsumerState<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends ConsumerState<TipsScreen>
    with SingleTickerProviderStateMixin {
  TipCategory? _selectedCategory;
  bool _showFavorites = false;

  List<FinanceTip> get _filteredTips {
    var tips = List<FinanceTip>.from(allTips);
    if (_showFavorites) {
      final favs = ref.read(_favoriteTipsProvider);
      tips = tips.where((t) => favs.contains(t.id)).toList();
    } else if (_selectedCategory != null) {
      tips = tips.where((t) => t.category == _selectedCategory).toList();
    }
    return tips;
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(_favoriteTipsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Money Tips',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        setState(() => _showFavorites = !_showFavorites),
                    icon: Icon(
                      _showFavorites ? Icons.bookmark : Icons.bookmark_outline,
                      color: _showFavorites
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    tooltip: 'Saved Tips',
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
            // Category filter
            if (!_showFavorites)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _CategoryChip(
                        label: 'All',
                        selected: _selectedCategory == null,
                        onTap: () => setState(() => _selectedCategory = null),
                      ),
                      ...TipCategory.values.map((c) => _CategoryChip(
                            label: _categoryLabel(c),
                            selected: _selectedCategory == c,
                            onTap: () => setState(() => _selectedCategory = c),
                          )),
                    ],
                  ),
                ),
              ).animate(delay: 60.ms).fadeIn(duration: 300.ms),
            // Tips grid
            Expanded(
              child: _filteredTips.isEmpty
                  ? Center(
                      child: Text(
                        _showFavorites
                            ? 'No saved tips yet.\nSwipe tips to bookmark them!'
                            : 'No tips in this category.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.4),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _filteredTips.length,
                      itemBuilder: (ctx, i) {
                        final tip = _filteredTips[i];
                        final isFav = favorites.contains(tip.id);
                        return _TipCard(
                          tip: tip,
                          isFavorite: isFav,
                          onToggleFavorite: () {
                            ref.read(_favoriteTipsProvider.notifier).update(
                                  (s) => Set<String>.from(s)
                                    ..toggle(tip.id, isFav),
                                );
                          },
                          index: i,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(TipCategory c) {
    switch (c) {
      case TipCategory.dailyHabits:
        return 'Daily Habits';
      case TipCategory.bigPurchases:
        return 'Big Purchases';
      case TipCategory.savings:
        return 'Savings';
      case TipCategory.investments:
        return 'Investments';
      case TipCategory.mindset:
        return 'Mindset';
    }
  }
}

extension _SetToggle on Set<String> {
  Set<String> toggle(String id, bool isPresent) {
    if (isPresent) {
      return Set<String>.from(this)..remove(id);
    }
    return Set<String>.from(this)..add(id);
  }
}

class _TipCard extends StatelessWidget {
  final FinanceTip tip;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final int index;

  const _TipCard({
    required this.tip,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.index,
  });

  Color get _categoryColor {
    switch (tip.category) {
      case TipCategory.dailyHabits:
        return const Color(0xFF6C63FF);
      case TipCategory.bigPurchases:
        return const Color(0xFFFF6B6B);
      case TipCategory.savings:
        return const Color(0xFF00B87C);
      case TipCategory.investments:
        return const Color(0xFF0984E3);
      case TipCategory.mindset:
        return const Color(0xFFFFB300);
    }
  }

  String get _categoryLabel {
    switch (tip.category) {
      case TipCategory.dailyHabits:
        return 'Daily Habits';
      case TipCategory.bigPurchases:
        return 'Big Purchases';
      case TipCategory.savings:
        return 'Savings';
      case TipCategory.investments:
        return 'Investments';
      case TipCategory.mindset:
        return 'Mindset';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _categoryColor.withValues(alpha: 0.2),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tip.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _categoryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _categoryLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _categoryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tip.text,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    height: 1.5,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onToggleFavorite,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                isFavorite ? Icons.bookmark : Icons.bookmark_outline,
                key: ValueKey(isFavorite),
                color: isFavorite ? _categoryColor : null,
                size: 20,
              ),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 40))
        .fadeIn(duration: 350.ms)
        .slideY(
            begin: 0.1, end: 0, duration: 350.ms, curve: Curves.easeOutExpo);
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? accent : accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : accent,
          ),
        ),
      ),
    );
  }
}
