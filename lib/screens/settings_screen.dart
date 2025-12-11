import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/section_card.dart';
import '../widgets/pro_input.dart';
import '../widgets/app_toast.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _defaultsKey = 'default_charges_v1';

  final TextEditingController _rateCtrl = TextEditingController();
  final TextEditingController _waterCtrl = TextEditingController();
  final TextEditingController _rentCtrl = TextEditingController();

  final FocusNode _rateFocus = FocusNode();
  final FocusNode _waterFocus = FocusNode();
  final FocusNode _rentFocus = FocusNode();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  void _showToast(String message, {bool isError = true, bool top = true}) {
    AppToast.show(
      context,
      message,
      isError: isError,
      style: AppToastStyle.cupertino,
      position: top ? AppToastPosition.top : AppToastPosition.bottom,
      duration: const Duration(seconds: 2),
    );
  }

  /// Same UI formatter: thousand separators + strip `.0` when integer
  String _formatNumberForUi(num value) {
    String raw;
    if (value is int || value % 1 == 0) {
      raw = value.toInt().toString();
    } else {
      raw = value.toString();
    }

    String integerPart = raw;
    String decimalPart = '';
    if (raw.contains('.')) {
      final parts = raw.split('.');
      integerPart = parts[0];
      decimalPart = parts.length > 1 ? parts[1] : '';
    }

    final isNegative = integerPart.startsWith('-');
    if (isNegative) {
      integerPart = integerPart.substring(1);
    }

    final buffer = StringBuffer();
    for (int i = 0; i < integerPart.length; i++) {
      final positionFromEnd = integerPart.length - i;
      buffer.write(integerPart[i]);
      if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }

    String result = buffer.toString();
    if (decimalPart.isNotEmpty && decimalPart != '0') {
      result = '$result.$decimalPart';
    }
    if (isNegative) {
      result = '-$result';
    }
    return result;
  }

  Future<void> _loadDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_defaultsKey);

    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final rate = (map['rate'] as num?)?.toDouble();
        final water = (map['water'] as num?)?.toDouble();
        final rent = (map['rent'] as num?)?.toDouble();

        _rateCtrl.text = rate != null ? _formatNumberForUi(rate) : '';
        _waterCtrl.text = water != null ? _formatNumberForUi(water) : '';
        _rentCtrl.text = rent != null ? _formatNumberForUi(rent) : '';
      } catch (_) {
        _rateCtrl.clear();
        _waterCtrl.clear();
        _rentCtrl.clear();
      }
    } else {
      _rateCtrl.clear();
      _waterCtrl.clear();
      _rentCtrl.clear();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDefaults() async {
    final rate = double.tryParse(_rateCtrl.text.trim().replaceAll(',', ''));
    final water = double.tryParse(_waterCtrl.text.trim().replaceAll(',', ''));
    final rent = double.tryParse(_rentCtrl.text.trim().replaceAll(',', ''));

    if (rate == null && water == null && rent == null) {
      _showToast('Enter at least one default value.', isError: true);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final map = {'rate': rate, 'water': water, 'rent': rent};

    await prefs.setString(_defaultsKey, jsonEncode(map));

    if (!mounted) return;

    _showToast('Default charges saved.', isError: false);
    Navigator.of(context).pop(true);
  }

  Future<void> _clearDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_defaultsKey);

    setState(() {
      _rateCtrl.clear();
      _waterCtrl.clear();
      _rentCtrl.clear();
    });

    if (!mounted) return;

    _showToast('Defaults cleared.', isError: false);
  }

  @override
  void dispose() {
    _rateCtrl.dispose();
    _waterCtrl.dispose();
    _rentCtrl.dispose();
    _rateFocus.dispose();
    _waterFocus.dispose();
    _rentFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionCard(
                      title: 'Default rates & charges',
                      subtitle:
                          'These values will be used when you tap the download icon in the calculator.',
                      icon: Icons.settings_suggest_rounded,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ProInput(
                                  controller: _rateCtrl,
                                  label: 'Default electricity rate',
                                  icon: Icons.currency_rupee_rounded,
                                  suffixText: '/ unit',
                                  hint: '10',
                                  decimal: true,
                                  formatWithSeparator: true,
                                  focusNode: _rateFocus,
                                  nextFocus: _waterFocus,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ProInput(
                                  controller: _waterCtrl,
                                  label: 'Default water charge',
                                  icon: Icons.currency_rupee_rounded,
                                  hint: '500',
                                  decimal: true,
                                  formatWithSeparator: true,
                                  focusNode: _waterFocus,
                                  nextFocus: _rentFocus,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ProInput(
                            controller: _rentCtrl,
                            label: 'Default monthly rent',
                            icon: Icons.currency_rupee_rounded,
                            hint: '15,000',
                            decimal: true,
                            formatWithSeparator: true,
                            focusNode: _rentFocus,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 4, top: 6),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 14,
                                    color: theme.hintColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Apply these values from the download icon in "Rates & Fixed Charges".',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: theme.hintColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _saveDefaults,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 3,
                      ),
                      icon: const Icon(Icons.save_rounded),
                      label: const Text(
                        'Save defaults',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _clearDefaults,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text(
                        'Clear defaults',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
