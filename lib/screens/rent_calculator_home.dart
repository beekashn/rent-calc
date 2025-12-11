import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart' as nepali_picker;
import 'package:nepali_utils/nepali_utils.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../models/rent_bill.dart';
import '../widgets/section_card.dart';
import '../widgets/pro_input.dart';
import '../widgets/receipt_ticket.dart';
import '../widgets/history_tab.dart';

class RentCalculatorHome extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const RentCalculatorHome({super.key, required this.onToggleTheme});

  @override
  State<RentCalculatorHome> createState() => _RentCalculatorHomeState();
}

class _RentCalculatorHomeState extends State<RentCalculatorHome>
    with SingleTickerProviderStateMixin {
  final TextEditingController _prevReadingCtrl = TextEditingController();
  final TextEditingController _currReadingCtrl = TextEditingController();
  final TextEditingController _costPerUnitCtrl = TextEditingController();
  final TextEditingController _waterChargeCtrl = TextEditingController();
  final TextEditingController _baseRentCtrl = TextEditingController();
  final TextEditingController _monthYearCtrl = TextEditingController();

  final FocusNode _prevFocus = FocusNode();
  final FocusNode _currFocus = FocusNode();
  final FocusNode _costFocus = FocusNode();
  final FocusNode _waterFocus = FocusNode();
  final FocusNode _rentFocus = FocusNode();

  final ScreenshotController _screenshotController = ScreenshotController();
  late TabController _tabController;
  final GlobalKey _receiptKey = GlobalKey();

  NepaliDateTime? _billingDateBs;
  RentBill? _currentBill;
  List<RentBill> _history = [];

  int? _liveUnits;
  double? _liveElecCost;

  static const String _historyKey = 'rent_history_v1';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initDateDefaults();
    _loadHistory();
  }

  void _initDateDefaults() {
    _billingDateBs = NepaliDateTime.now();
    _monthYearCtrl.text = _monthYearLabelForDate(_billingDateBs!);
  }

  String _monthYearLabelForDate(NepaliDateTime date) {
    const months = [
      '',
      'Baisakh',
      'Jestha',
      'Ashadh',
      'Shrawan',
      'Bhadra',
      'Ashwin',
      'Kartik',
      'Mangsir',
      'Poush',
      'Magh',
      'Falgun',
      'Chaitra',
    ];
    return '${months[date.month]} ${date.year}';
  }

  void _updateLiveValues() {
    final prev = int.tryParse(_prevReadingCtrl.text.trim());
    final curr = int.tryParse(_currReadingCtrl.text.trim());
    final rate = double.tryParse(_costPerUnitCtrl.text.trim());

    setState(() {
      if (prev != null && curr != null && curr >= prev) {
        _liveUnits = curr - prev;
      } else {
        _liveUnits = null;
      }
      if (_liveUnits != null && rate != null) {
        _liveElecCost = _liveUnits! * rate;
      } else {
        _liveElecCost = null;
      }
    });
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_historyKey);
    if (raw == null) return;
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      setState(() {
        _history = list
            .map((e) => RentBill.fromMap(e as Map<String, dynamic>))
            .toList()
            .reversed
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _saveBillToHistory(RentBill bill) async {
    final prefs = await SharedPreferences.getInstance();
    final List<RentBill> updated = [bill, ..._history];
    final List<Map<String, dynamic>> mapped = updated
        .map((b) => b.toMap())
        .toList();
    await prefs.setString(_historyKey, jsonEncode(mapped));
    setState(() => _history = updated);
    _showSnackBar('Saved successfully!', isError: false);
    _tabController.animateTo(1);
  }

  Future<void> _deleteBill(RentBill bill) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _history.removeWhere((b) => b.id == bill.id));
    final List<Map<String, dynamic>> mapped = _history
        .map((b) => b.toMap())
        .toList();
    await prefs.setString(_historyKey, jsonEncode(mapped));
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    setState(() => _history = []);
  }

  Future<void> _pickNepaliBillingDate() async {
    final initial = _billingDateBs ?? NepaliDateTime.now();
    final picked = await nepali_picker.showNepaliDatePicker(
      context: context,
      initialDate: initial,
      firstDate: NepaliDateTime(2070, 1, 1),
      lastDate: NepaliDateTime(2100, 12, 30),
      initialDatePickerMode: DatePickerMode.day,
    );
    if (picked != null) {
      setState(() {
        _billingDateBs = picked;
        _monthYearCtrl.text = _monthYearLabelForDate(picked);
      });
    }
  }

  Future<void> _shareBillImage(
    RentBill bill, {
    bool isFromHistory = false,
  }) async {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    HapticFeedback.lightImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      Uint8List? imageBytes;
      if (isFromHistory) {
        final controller = ScreenshotController();
        imageBytes = await controller.captureFromWidget(
          Theme(
            data: Theme.of(context),
            child: MediaQuery(
              data: MediaQuery.of(context),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ReceiptTicket(bill: bill),
                ),
              ),
            ),
          ),
          pixelRatio: pixelRatio * 2.0,
          delay: const Duration(milliseconds: 50),
        );
      } else {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;
        imageBytes = await _screenshotController.capture(
          pixelRatio: pixelRatio * 2.0,
        );
      }

      if (imageBytes == null) throw Exception('Capture failed');

      final directory = await getTemporaryDirectory();
      final imagePath = await File(
        '${directory.path}/bill_${bill.monthYear.replaceAll(' ', '_')}.png',
      ).create();
      await imagePath.writeAsBytes(imageBytes);

      if (mounted) Navigator.pop(context);

      final xFile = XFile(imagePath.path);
      await Share.shareXFiles([xFile], text: 'Rent Bill: ${bill.monthYear}');
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnackBar('Share failed: $e');
    }
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    final prev = int.tryParse(_prevReadingCtrl.text.trim());
    final curr = int.tryParse(_currReadingCtrl.text.trim());
    final cost = double.tryParse(_costPerUnitCtrl.text.trim());
    final water = double.tryParse(_waterChargeCtrl.text.trim());
    final rent = double.tryParse(_baseRentCtrl.text.trim());
    final monthYear = _monthYearCtrl.text.trim();

    if (prev == null ||
        curr == null ||
        cost == null ||
        water == null ||
        rent == null ||
        _billingDateBs == null) {
      _showSnackBar('Please check all fields.');
      return;
    }
    if (curr < prev) {
      _showSnackBar('Current reading cannot be lower than previous.');
      return;
    }

    final units = curr - prev;
    final electricityBill = units * cost;
    final total = rent + water + electricityBill;
    final billingDateFormatted = NepaliDateFormat(
      'yyyy-MM-dd',
    ).format(_billingDateBs!);

    setState(() {
      _currentBill = RentBill(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        monthYear: monthYear,
        billingDateBs: billingDateFormatted,
        previousReading: prev,
        currentReading: curr,
        units: units,
        costPerUnit: cost,
        electricityBill: electricityBill,
        waterCharge: water,
        baseRent: rent,
        total: total,
        createdAt: DateTime.now(),
      );
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _receiptKey.currentContext != null) {
        Scrollable.ensureVisible(
          _receiptKey.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearForm() {
    setState(() {
      _prevReadingCtrl.clear();
      _currReadingCtrl.clear();
      _costPerUnitCtrl.clear();
      _waterChargeCtrl.clear();
      _baseRentCtrl.clear();
      _currentBill = null;
      _liveUnits = null;
      _liveElecCost = null;
      _initDateDefaults();
    });
    FocusScope.of(context).unfocus();
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isError
            ? const Color(0xFFFF5252)
            : const Color(0xFF00C853),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Rent Manager',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            onPressed: widget.onToggleTheme,
            icon: Icon(
              isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
            ),
            color: isDark ? Colors.amber : Colors.white,
            tooltip: 'Toggle Theme',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.cardTheme.color?.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(18),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: theme.hintColor,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'Calculator'),
                  Tab(text: 'History'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Top header background
          Container(
            height: 230,
            decoration: const BoxDecoration(
              color: Color(0xFF7A63B3),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
            ),
          ),
          SafeArea(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCalculatorTab(theme),
                HistoryTab(
                  bills: _history,
                  onDeleteBill: _deleteBill,
                  onClearAll: _clearHistory,
                  onShareBill: (bill) =>
                      _shareBillImage(bill, isFromHistory: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatorTab(ThemeData theme) {
    final primary = theme.colorScheme.primary;
    final textColor = theme.textTheme.bodyLarge?.color;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HEADER SUMMARY CARD
              Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primary.withValues(alpha: 0.12),
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          color: primary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Billing month',
                              style: TextStyle(
                                color: theme.hintColor,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _monthYearCtrl.text,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 14,
                                  color: theme.hintColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _billingDateBs != null
                                      ? NepaliDateFormat(
                                          'yyyy-MM-dd',
                                        ).format(_billingDateBs!)
                                      : '--',
                                  style: TextStyle(
                                    color: theme.hintColor,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _pickNepaliBillingDate,
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: primary.withValues(alpha: 0.12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_calendar_rounded,
                                size: 16,
                                color: primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Change',
                                style: TextStyle(
                                  color: primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // METER CARD
              SectionCard(
                title: 'Meter & Consumption',
                subtitle: 'Enter previous and current reading',
                icon: Icons.electric_meter_rounded,
                trailing: _liveUnits != null
                    ? Chip(
                        backgroundColor: primary.withValues(alpha: 0.12),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt_rounded, size: 16, color: primary),
                            const SizedBox(width: 4),
                            Text(
                              '${_liveUnits!} units',
                              style: TextStyle(
                                color: primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      )
                    : null,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ProInput(
                            controller: _prevReadingCtrl,
                            label: 'Previous reading',
                            icon: Icons.history_rounded,
                            hint: '0000',
                            focusNode: _prevFocus,
                            nextFocus: _currFocus,
                            onChanged: (_) => _updateLiveValues(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ProInput(
                            controller: _currReadingCtrl,
                            label: 'Current reading',
                            icon: Icons.update_rounded,
                            hint: '0000',
                            focusNode: _currFocus,
                            nextFocus: _costFocus,
                            onChanged: (_) => _updateLiveValues(),
                          ),
                        ),
                      ],
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      child: (_liveUnits != null && _liveUnits! >= 0)
                          ? Padding(
                              padding: const EdgeInsets.only(top: 12, left: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.timeline_rounded,
                                    size: 16,
                                    color: primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'You consumed ',
                                    style: TextStyle(
                                      color: theme.textTheme.bodyMedium?.color,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${_liveUnits!} units',
                                    style: TextStyle(
                                      color: primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // CHARGES CARD
              SectionCard(
                title: 'Rates & Fixed Charges',
                subtitle: 'Add electricity rate, water and base rent',
                icon: Icons.payments_rounded,
                trailing: _liveElecCost != null
                    ? Chip(
                        backgroundColor: primary.withValues(alpha: 0.12),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Rs.',
                              style: TextStyle(
                                color: primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_liveElecCost!.round()}',
                              style: TextStyle(
                                color: primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      )
                    : null,
                child: Column(
                  children: [
                    ProInput(
                      controller: _costPerUnitCtrl,
                      label: 'Electricity rate',
                      icon: Icons.flash_on_rounded,
                      suffixText: '/ unit',
                      hint: 'e.g. 10',
                      decimal: true,
                      focusNode: _costFocus,
                      nextFocus: _waterFocus,
                      onChanged: (_) => _updateLiveValues(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ProInput(
                            controller: _waterChargeCtrl,
                            label: 'Water charge',
                            icon: Icons.water_drop_rounded,
                            prefixText: 'Rs. ',
                            hint: '500',
                            decimal: true,
                            focusNode: _waterFocus,
                            nextFocus: _rentFocus,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ProInput(
                            controller: _baseRentCtrl,
                            label: 'Monthly rent',
                            icon: Icons.home_rounded,
                            prefixText: 'Rs. ',
                            hint: '15000',
                            decimal: true,
                            focusNode: _rentFocus,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ACTION ROW
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _clearForm,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _calculate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 4,
                        shadowColor: primary.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.calculate_rounded),
                      label: const Text(
                        'Calculate bill',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // RECEIPT PREVIEW
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _currentBill == null
                    ? const SizedBox.shrink()
                    : Column(
                        key: const ValueKey('receipt_preview'),
                        children: [
                          const SizedBox(height: 28),
                          Text(
                            'BILL PREVIEW',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              letterSpacing: 3,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              color: theme.hintColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Screenshot(
                            controller: _screenshotController,
                            child: Container(
                              key: _receiptKey,
                              child: ReceiptTicket(bill: _currentBill!),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _shareBillImage(_currentBill!),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    side: BorderSide(
                                      color: primary,
                                      width: 1.8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    foregroundColor: primary,
                                  ),
                                  icon: const Icon(Icons.share_rounded),
                                  label: const Text('Share'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _saveBillToHistory(_currentBill!),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    backgroundColor: const Color(0xFF00C853),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  icon: const Icon(Icons.save_rounded),
                                  label: const Text('Save'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
