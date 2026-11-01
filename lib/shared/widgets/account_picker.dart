import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/account_model.dart';

/// Horizontal row of account chips with a title, used wherever a
/// transaction's account is chosen.
class AccountPicker extends StatelessWidget {
  final String label;
  final List<AccountModel> accounts;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final VoidCallback? onManage;

  /// Greyed out and not selectable (e.g. the "from" account in a transfer).
  final String? disabledId;

  /// Side inset for the label row and chip list. Zero when the parent
  /// already pads its content.
  final double horizontalPadding;

  const AccountPicker({
    super.key,
    required this.label,
    required this.accounts,
    required this.selectedId,
    required this.onSelect,
    this.onManage,
    this.disabledId,
    this.horizontalPadding = 20,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: onSurface.withValues(alpha: 0.6),
                ),
              ),
              if (onManage != null)
                GestureDetector(
                  onTap: onManage,
                  child: Row(
                    children: [
                      Icon(Icons.tune_rounded, size: 14, color: primary),
                      const SizedBox(width: 4),
                      Text(
                        'Manage',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            physics: const BouncingScrollPhysics(),
            itemCount: accounts.length,
            itemBuilder: (ctx, i) {
              final a = accounts[i];
              final selected = a.id == selectedId;
              final disabled = a.id == disabledId;
              return Opacity(
                opacity: disabled ? 0.35 : 1,
                child: GestureDetector(
                  onTap: disabled ? null : () => onSelect(a.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: selected
                          ? a.color.withValues(alpha: 0.18)
                          : onSurface.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? a.color
                            : onSurface.withValues(alpha: 0.1),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(a.icon,
                            size: 18,
                            color: selected
                                ? a.color
                                : onSurface.withValues(alpha: 0.6)),
                        const SizedBox(width: 8),
                        Text(
                          a.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? a.color : onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
