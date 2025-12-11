import 'package:flutter/material.dart';
import '../models/rent_bill.dart';
import 'receipt_ticket.dart';

class HistoryTab extends StatelessWidget {
  final List<RentBill> bills;
  final void Function(RentBill) onDeleteBill;
  final VoidCallback onClearAll;
  final void Function(RentBill) onShareBill;

  const HistoryTab({
    super.key,
    required this.bills,
    required this.onDeleteBill,
    required this.onClearAll,
    required this.onShareBill,
  });

  String _fmt(num value) => value.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    if (bills.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history_toggle_off_rounded,
                size: 90,
                color: theme.dividerColor.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 16),
              Text(
                'No bills yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Calculated bills you save will appear here for quick reference and sharing.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            children: [
              Text(
                'Recent bills',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onClearAll,
                icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                label: const Text('Clear all'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            itemCount: bills.length,
            itemBuilder: (context, index) {
              final bill = bills[index];
              final bool isLast = index == bills.length - 1;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Dismissible(
                  key: Key(bill.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    padding: const EdgeInsets.only(right: 24),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.centerRight,
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white,
                    ),
                  ),
                  confirmDismiss: (d) async {
                    onDeleteBill(bill);
                    return true;
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TIMELINE INDICATOR
                      Column(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primary,
                              border: Border.all(
                                color: isDark ? Colors.white : Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                          if (!isLast)
                            Container(
                              width: 1.5,
                              height: 64,
                              color: theme.dividerColor.withValues(alpha: 0.5),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),

                      // CARD
                      Expanded(
                        child: Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                isScrollControlled: true,
                                builder: (_) => BillPreviewSheet(
                                  bill: bill,
                                  onShare: () => onShareBill(bill),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left month chip
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          primary.withValues(alpha: 0.18),
                                          primary.withValues(alpha: 0.08),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Text(
                                        bill.monthYear
                                            .substring(0, 3)
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.white
                                              : primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Middle text
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          bill.monthYear,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.electric_bolt_rounded,
                                              size: 14,
                                              color: theme.hintColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                '${bill.units} units',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: theme.hintColor,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              Icons.calendar_today_rounded,
                                              size: 14,
                                              color: theme.hintColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                bill.billingDateBs,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: theme.hintColor,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  // Trailing column
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerRight,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Rs. ${_fmt(bill.total.round())}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                            color: isDark
                                                ? Colors.white
                                                : primary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        InkWell(
                                          onTap: () => onShareBill(bill),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              color: theme
                                                  .scaffoldBackgroundColor
                                                  .withValues(alpha: 0.9),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.share_rounded,
                                                  size: 12,
                                                  color: theme.hintColor,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Share',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: theme.hintColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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

class BillPreviewSheet extends StatelessWidget {
  final RentBill bill;
  final VoidCallback onShare;

  const BillPreviewSheet({
    super.key,
    required this.bill,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Text(
                      'Bill preview',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton.filledTonal(
                      style: IconButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: onShare,
                      icon: const Icon(Icons.share_rounded, size: 18),
                      tooltip: 'Share bill',
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  child: ReceiptTicket(bill: bill),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
