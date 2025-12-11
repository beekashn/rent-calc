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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

// ---------------------------------------------------------------------------
// 1. THEME CONFIGURATION
// ---------------------------------------------------------------------------

class AppTheme {
  static const Color primaryBrand = Color(0xFF6750A4);

  static const Color bgLight = Color(0xFFF5F5FA);
  static const Color surfaceLight = Colors.white;

  static const Color bgDark = Color(0xFF050509);
  static const Color surfaceDark = Color(0xFF15151C);
  static const Color inputDark = Color(0xFF20202A);

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBrand,
        brightness: Brightness.light,
        surface: surfaceLight,
        primary: primaryBrand,
      ),
      scaffoldBackgroundColor: bgLight,
    );

    return base.copyWith(
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      cardTheme: base.cardTheme.copyWith(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.12)),
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryBrand, width: 2),
        ),
        labelStyle: TextStyle(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(color: Colors.grey.shade400),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ),
      snackBarTheme: base.snackBarTheme.copyWith(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBrand,
        brightness: Brightness.dark,
        primary: primaryBrand,
        surface: surfaceDark,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: bgDark,
    );

    return base.copyWith(
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: base.cardTheme.copyWith(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: inputDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryBrand, width: 2),
        ),
        labelStyle: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. MAIN APP
// ---------------------------------------------------------------------------

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>()!;

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  static const String _themeKey = 'theme_mode_final_v2';

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedTheme = prefs.getString(_themeKey);
    if (savedTheme != null) {
      setState(() {
        _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
      });
    }
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarIconBrightness: _themeMode == ThemeMode.light
            ? Brightness.dark
            : Brightness.light,
        statusBarColor: Colors.transparent,
      ),
    );

    await prefs.setString(
      _themeKey,
      _themeMode == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rent Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      home: const RentCalculatorHome(),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. HOME SCREEN
// ---------------------------------------------------------------------------

class RentCalculatorHome extends StatefulWidget {
  const RentCalculatorHome({super.key});

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
            .map((e) => RentBill.fromMap(e))
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
                  child: _ReceiptTicket(bill: bill),
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
            onPressed: () => MyApp.of(context).toggleTheme(),
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
          // Top solid header background (no gradient, not faint)
          Container(
            height: 230,
            decoration: BoxDecoration(
              color: const Color(0xFF7A63B3),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(15),
              ),
            ),
          ),
          SafeArea(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCalculatorTab(theme),
                _HistoryTab(
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
              _SectionCard(
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
                          child: _ProInput(
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
                          child: _ProInput(
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
              _SectionCard(
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
                    _ProInput(
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
                          child: _ProInput(
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
                          child: _ProInput(
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
                              child: _ReceiptTicket(bill: _currentBill!),
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

// ---------------------------------------------------------------------------
// 4. SMALL COMPONENTS (Section card & Input)
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _ProInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final String? hint;
  final String? prefixText;
  final String? suffixText;
  final bool decimal;
  final FocusNode focusNode;
  final FocusNode? nextFocus;
  final ValueChanged<String>? onChanged;

  const _ProInput({
    required this.controller,
    required this.label,
    this.icon,
    this.hint,
    this.prefixText,
    this.suffixText,
    this.decimal = false,
    required this.focusNode,
    this.nextFocus,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            label,
            style: theme.inputDecorationTheme.labelStyle?.copyWith(
              fontSize: 12,
            ),
          ),
        ),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          textInputAction: nextFocus != null
              ? TextInputAction.next
              : TextInputAction.done,
          onChanged: onChanged,
          onSubmitted: (_) => nextFocus != null
              ? FocusScope.of(context).requestFocus(nextFocus)
              : FocusScope.of(context).unfocus(),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: textColor,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null
                ? Icon(icon, size: 18, color: theme.hintColor)
                : null,
            prefixText: prefixText,
            suffixText: suffixText,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 5. RECEIPT TICKET WIDGET (Solid header color)
// ---------------------------------------------------------------------------

class _ReceiptTicket extends StatelessWidget {
  final RentBill bill;
  const _ReceiptTicket({required this.bill});

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
              color: primary, // SOLID COLOR INSTEAD OF GRADIENT
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
                _TicketRow(
                  label: 'Previous reading',
                  value: bill.previousReading.toString(),
                  labelColor: secondaryText,
                  valueColor: ticketText,
                ),
                _TicketRow(
                  label: 'Current reading',
                  value: bill.currentReading.toString(),
                  labelColor: secondaryText,
                  valueColor: ticketText,
                ),
                _TicketRow(
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
                _TicketRow(
                  label: 'Electricity',
                  value: 'Rs. ${_fmt(bill.electricityBill.round())}',
                  labelColor: secondaryText,
                  valueColor: ticketText,
                ),
                _TicketRow(
                  label: 'Water',
                  value: 'Rs. ${_fmt(bill.waterCharge.round())}',
                  labelColor: secondaryText,
                  valueColor: ticketText,
                ),
                _TicketRow(
                  label: 'Base rent',
                  value: 'Rs. ${_fmt(bill.baseRent.round())}',
                  labelColor: secondaryText,
                  valueColor: ticketText,
                ),
                const SizedBox(height: 4),
                Divider(color: theme.dividerColor.withValues(alpha: 0.26)),
                const SizedBox(height: 8),
                _TicketRow(
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

class _TicketRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;
  final Color? labelColor;
  final Color? valueColor;

  const _TicketRow({
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

// ---------------------------------------------------------------------------
// 6. HISTORY TAB
// ---------------------------------------------------------------------------

class _HistoryTab extends StatelessWidget {
  final List<RentBill> bills;
  final void Function(RentBill) onDeleteBill;
  final VoidCallback onClearAll;
  final void Function(RentBill) onShareBill;

  const _HistoryTab({
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
                                builder: (_) => _BillPreviewSheet(
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

                                  // Middle text (expands)
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

                                  // Trailing column (amount + share), wrapped with FittedBox
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

class _BillPreviewSheet extends StatelessWidget {
  final RentBill bill;
  final VoidCallback onShare;

  const _BillPreviewSheet({required this.bill, required this.onShare});

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
                  child: _ReceiptTicket(bill: bill),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 7. DATA MODEL
// ---------------------------------------------------------------------------

class RentBill {
  final String id;
  final String monthYear;
  final String billingDateBs;
  final int previousReading;
  final int currentReading;
  final int units;
  final double costPerUnit;
  final double electricityBill;
  final double waterCharge;
  final double baseRent;
  final double total;
  final DateTime createdAt;

  RentBill({
    required this.id,
    required this.monthYear,
    required this.billingDateBs,
    required this.previousReading,
    required this.currentReading,
    required this.units,
    required this.costPerUnit,
    required this.electricityBill,
    required this.waterCharge,
    required this.baseRent,
    required this.total,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'monthYear': monthYear,
    'billingDateBs': billingDateBs,
    'previousReading': previousReading,
    'currentReading': currentReading,
    'units': units,
    'costPerUnit': costPerUnit,
    'electricityBill': electricityBill,
    'waterCharge': waterCharge,
    'baseRent': baseRent,
    'total': total,
    'createdAt': createdAt.toIso8601String(),
  };

  factory RentBill.fromMap(Map<String, dynamic> map) => RentBill(
    id: map['id'],
    monthYear: map['monthYear'],
    billingDateBs: map['billingDateBs'],
    previousReading: map['previousReading'],
    currentReading: map['currentReading'],
    units: map['units'],
    costPerUnit: (map['costPerUnit'] as num).toDouble(),
    electricityBill: (map['electricityBill'] as num).toDouble(),
    waterCharge: (map['waterCharge'] as num).toDouble(),
    baseRent: (map['baseRent'] as num).toDouble(),
    total: (map['total'] as num).toDouble(),
    createdAt: DateTime.parse(map['createdAt']),
  );
}
