import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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
  static const String _historyKey = 'rent_history_v1';
  static const String _themeKey = 'theme_mode_final_v2';
  static const int _backupSchemaVersion = 1;

  final TextEditingController _rateCtrl = TextEditingController();
  final TextEditingController _waterCtrl = TextEditingController();
  final TextEditingController _rentCtrl = TextEditingController();

  final FocusNode _rateFocus = FocusNode();
  final FocusNode _waterFocus = FocusNode();
  final FocusNode _rentFocus = FocusNode();

  bool _isLoading = true;
  bool _isBusy = false;

  String _backupFileName() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    return 'rent_calc_backup_$y$m$d-$hh$mm$ss.json';
  }

  List<Map<String, dynamic>> _safeHistoryList(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _exportBackup() async {
    if (_isBusy) return;

    setState(() => _isBusy = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = _safeHistoryList(prefs.getString(_historyKey));
      final defaultsRaw = prefs.getString(_defaultsKey);
      final defaults = defaultsRaw == null
          ? null
          : Map<String, dynamic>.from(jsonDecode(defaultsRaw) as Map);
      final theme = prefs.getString(_themeKey);

      final payload = <String, dynamic>{
        'schemaVersion': _backupSchemaVersion,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'app': 'rent_calc',
        'history': history,
        'defaults': defaults,
        'themeMode': theme,
      };

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/${_backupFileName()}');
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(payload),
      );

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Rent Calc backup file');

      if (!mounted) return;
      _showToast('Backup file ready to share.', isError: false);
    } catch (_) {
      if (!mounted) return;
      _showToast('Backup export failed.', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<bool?> _showRestoreModeDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore mode'),
        content: const Text(
          'Merge keeps existing bills and adds new ones. Replace overwrites current local data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Merge'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
  }

  Future<void> _importBackup() async {
    if (_isBusy) return;

    setState(() => _isBusy = true);
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );

      if (picked == null ||
          picked.files.isEmpty ||
          picked.files.first.path == null) {
        _showToast('No backup file selected.', isError: true);
        return;
      }

      final mode = await _showRestoreModeDialog();
      if (mode == null) return;

      final filePath = picked.files.first.path!;
      final raw = await File(filePath).readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        _showToast('Invalid backup format.', isError: true);
        return;
      }

      final schemaVersion = decoded['schemaVersion'];
      if (schemaVersion is! int || schemaVersion <= 0) {
        _showToast('Unsupported backup schema.', isError: true);
        return;
      }

      final importedHistoryRaw = decoded['history'];
      final importedHistory = importedHistoryRaw is List
          ? importedHistoryRaw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
          : <Map<String, dynamic>>[];
      final importedDefaults = decoded['defaults'] is Map
          ? Map<String, dynamic>.from(decoded['defaults'] as Map)
          : null;
      final importedThemeRaw = decoded['themeMode'];
      final importedTheme = importedThemeRaw is String
          ? importedThemeRaw
          : null;

      final prefs = await SharedPreferences.getInstance();

      int importedCount = 0;
      int skippedDuplicates = 0;

      if (mode) {
        // Replace mode
        await prefs.setString(_historyKey, jsonEncode(importedHistory));
        importedCount = importedHistory.length;

        if (importedDefaults == null) {
          await prefs.remove(_defaultsKey);
        } else {
          await prefs.setString(_defaultsKey, jsonEncode(importedDefaults));
        }
      } else {
        // Merge mode
        final existingHistory = _safeHistoryList(prefs.getString(_historyKey));
        final existingIds = existingHistory
            .map((e) => e['id']?.toString())
            .whereType<String>()
            .toSet();

        final merged = <Map<String, dynamic>>[...existingHistory];
        for (final entry in importedHistory) {
          final id = entry['id']?.toString();
          if (id != null && id.isNotEmpty && existingIds.contains(id)) {
            skippedDuplicates++;
            continue;
          }
          if (id != null && id.isNotEmpty) {
            existingIds.add(id);
          }
          merged.add(entry);
          importedCount++;
        }

        await prefs.setString(_historyKey, jsonEncode(merged));

        if (importedDefaults != null) {
          await prefs.setString(_defaultsKey, jsonEncode(importedDefaults));
        }
      }

      if (importedTheme == 'dark' || importedTheme == 'light') {
        await prefs.setString(_themeKey, importedTheme!);
      }

      if (!mounted) return;
      final modeText = mode ? 'replaced' : 'merged';
      _showToast(
        'Backup $modeText. Added $importedCount bill(s), skipped $skippedDuplicates duplicate(s).',
        isError: false,
      );
      await _loadDefaults();
    } catch (_) {
      if (!mounted) return;
      _showToast('Backup import failed.', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  void _showToast(
    String message, {
    bool isError = true,
    bool top = true,
    AppToastStyle? style,
  }) {
    AppToast.show(
      context,
      message,
      isError: isError,
      style: style,
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
    final borderColor = theme.colorScheme.outline.withValues(alpha: 0.18);

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
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.tune_rounded,
                              color: primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Manage your default charges and backup your data for device changes.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SectionCard(
                      title: 'Default rates & charges',
                      subtitle:
                          'Used when you tap the download icon in Calculator.',
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
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.30),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _clearDefaults,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: BorderSide(
                                  color: Colors.red.withValues(alpha: 0.35),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: const Text(
                                'Clear',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: _saveDefaults,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              icon: const Icon(Icons.save_rounded),
                              label: const Text(
                                'Save defaults',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SectionCard(
                      title: 'Backup & Restore',
                      subtitle:
                          'Export JSON backup and restore across devices.',
                      icon: Icons.backup_rounded,
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.35),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.verified_user_rounded,
                                  size: 16,
                                  color: theme.hintColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Import supports Merge and Replace modes with duplicate checks by bill id.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.hintColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isBusy ? null : _exportBackup,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.ios_share_rounded),
                              label: const Text('Export backup'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isBusy ? null : _importBackup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.secondary,
                                foregroundColor: theme.colorScheme.onSecondary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.upload_file_rounded),
                              label: const Text('Import backup'),
                            ),
                          ),
                          if (_isBusy) ...[
                            const SizedBox(height: 12),
                            const LinearProgressIndicator(minHeight: 3),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
