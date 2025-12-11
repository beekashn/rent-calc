import 'package:flutter/material.dart';
import '../models/rent_bill.dart';

class ReceiptTicket extends StatelessWidget {
  final RentBill bill;
  const ReceiptTicket({super.key, required this.bill});

  String _fmt(num value) => value.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final ticketBg = theme.cardTheme.color;
    final ticketText = theme.textTheme.bodyLarge?.color;
    final secondaryText = theme.hintColor;
    final primary = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: ticketBg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 20,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          // HEADER STRIP (SOLID COLOR)
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              color: primary,
            ),
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.home_work_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Rent Bill',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.qr_code_rounded,
                      size: 22,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bill.monthYear,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Billing date: ${bill.billingDateBs}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'TOTAL',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            letterSpacing: 1.8,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rs. ${_fmt(bill.total.round())}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // PERFORATED DIVIDER
          Row(
            children: [
              Container(
                width: 16,
                height: 26,
                decoration: BoxDecoration(
                  color: ticketBg,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final dashWidth = 6.0;
                    final dashHeight = 1.4;
                    final dashCount = (constraints.maxWidth / (dashWidth * 2))
                        .floor();
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(dashCount, (_) {
                        return Container(
                          width: dashWidth,
                          height: dashHeight,
                          color: secondaryText.withValues(alpha: 0.4),
                        );
                      }),
                    );
                  },
                ),
              ),
              Container(
                width: 16,
                height: 26,
                decoration: BoxDecoration(
                  color: ticketBg,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
            ],
          ),

          // DETAILS BODY
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
            ).copyWith(bottom: 18),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Usage details',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded, size: 14, color: primary),
                          const SizedBox(width: 4),
                          Text(
                            '${bill.units} units',
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TicketRow(
                  label: 'Previous reading',
                  value: bill.previousReading.toString(),
                  labelColor: secondaryText,
                  valueColor: ticketText,
                ),
                TicketRow(
                  label: 'Current reading',
                  value: bill.currentReading.toString(),
                  labelColor: secondaryText,
                  valueColor: ticketText,
                ),
                TicketRow(
                  label: 'Rate per unit',
                  value: 'Rs. ${bill.costPerUnit.toStringAsFixed(2)}',
                  labelColor: secondaryText,
                  valueColor: ticketText,
                ),
                const SizedBox(height: 10),
                Divider(color: theme.dividerColor.withValues(alpha: 0.26)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Charges breakdown',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TicketRow(
                  label: 'Electricity',
                  value: 'Rs. ${_fmt(bill.electricityBill.round())}',
                  labelColor: secondaryText,
                  valueColor: ticketText,
                ),
                TicketRow(
                  label: 'Water',
                  value: 'Rs. ${_fmt(bill.waterCharge.round())}',
                  labelColor: secondaryText,
                  valueColor: ticketText,
                ),
                TicketRow(
                  label: 'Base rent',
                  value: 'Rs. ${_fmt(bill.baseRent.round())}',
                  labelColor: secondaryText,
                  valueColor: ticketText,
                ),
                const SizedBox(height: 4),
                Divider(color: theme.dividerColor.withValues(alpha: 0.26)),
                const SizedBox(height: 8),
                TicketRow(
                  label: 'Total payable',
                  value: 'Rs. ${_fmt(bill.total.round())}',
                  isHighlight: true,
                  labelColor: secondaryText,
                  valueColor: ticketText,
                ),
              ],
            ),
          ),

          // FOOTER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(22),
              ),
              color: isDark
                  ? Colors.black.withValues(alpha: 0.45)
                  : Colors.grey.shade50,
            ),
            alignment: Alignment.center,
            child: Text(
              'Generated by Rent Manager',
              style: TextStyle(
                color: secondaryText,
                fontSize: 10,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TicketRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;
  final Color? labelColor;
  final Color? valueColor;

  const TicketRow({
    super.key,
    required this.label,
    required this.value,
    this.isHighlight = false,
    this.labelColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: labelColor ?? theme.hintColor,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            value,
            style: TextStyle(
              color: isHighlight
                  ? theme.colorScheme.primary
                  : (valueColor ?? theme.textTheme.bodyLarge?.color),
              fontWeight: isHighlight ? FontWeight.w900 : FontWeight.w600,
              fontSize: isHighlight ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
