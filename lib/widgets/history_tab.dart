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
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  size: 48,
                  color: theme.disabledColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No History Yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your saved bills will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.hintColor, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // MAIN LIST
        ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 80), // extra bottom
          itemCount: bills.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final bill = bills[index];

            return Dismissible(
              key: Key(bill.id),
              direction: DismissDirection.endToStart,
              background: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "Delete",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.delete_outline_rounded, color: Colors.white),
                  ],
                ),
              ),
              confirmDismiss: (d) async {
                onDeleteBill(bill);
                return true;
              },
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.2 : 0.04,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.05),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
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
                        children: [
                          // DATE BOX
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  bill.monthYear.substring(0, 3).toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: primary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  bill.billingDateBs.split('-').last,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 16),

                          // DETAILS
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bill.monthYear,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.bolt_rounded,
                                      size: 14,
                                      color: theme.hintColor,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${bill.units} units',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.hintColor,
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      width: 3,
                                      height: 3,
                                      decoration: BoxDecoration(
                                        color: theme.hintColor.withValues(
                                          alpha: 0.5,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Text(
                                      bill.billingDateBs,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.hintColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // PRICE & ARROW
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Rs. ${_fmt(bill.total.round())}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: isDark
                                      ? const Color(0xFF69F0AE)
                                      : const Color(0xFF00C853),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 12,
                                color: theme.hintColor.withValues(alpha: 0.5),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // FIXED BOTTOM-LEFT "Clear all" BUTTON
        Positioned(
          right: 16,
          bottom: 16,
          child: SafeArea(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                elevation: 4,
              ),
              icon: const Icon(Icons.delete_sweep_rounded, size: 18),
              label: const Text(
                'Clear all',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear all history?'),
                    content: const Text(
                      'This will permanently delete all saved bills. '
                      'Are you sure you want to continue?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  onClearAll();
                }
              },
            ),
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
      initialChildSize: 0.85,
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Text(
                      'Bill Details',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        side: BorderSide(color: primary.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: onShare,
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text("Share"),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: theme
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.5),
                      ),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
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
