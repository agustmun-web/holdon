import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import '../services/security_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SecurityService _securityService = SecurityService();
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = true;
  Locale? _selectedLocale;
  double _pocketTimerSeconds = 5;
  bool _isPocketTimerLoading = true;
  bool _isPocketTimerUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadPocketTimerSetting();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedLocale ??= context.read<AppState>().locale;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appState = context.watch<AppState>();
    return Scaffold(
      backgroundColor: const Color(0xFF0E1720),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1720),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(l10n.translate('settings.title')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          _buildSectionHeader(l10n.translate('settings.section.general')),
          const SizedBox(height: 12),
          _buildSwitchTile(
            title: l10n.translate('settings.option.notifications'),
            subtitle: l10n.translate('settings.option.notifications.subtitle'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          _buildSwitchTile(
            title: l10n.translate('settings.option.darkmode'),
            subtitle: l10n.translate('settings.option.darkmode.subtitle'),
            value: _darkModeEnabled,
            onChanged: (value) {
              setState(() {
                _darkModeEnabled = value;
              });
            },
          ),
          _buildPocketTimerTile(l10n),
          _buildLanguageTile(
            title: l10n.translate('settings.option.language'),
            subtitle: l10n.translate('settings.option.language.subtitle'),
            value: _selectedLocale ?? appState.locale,
            onChanged: (locale) {
              setState(() {
                _selectedLocale = locale;
              });
              appState.setLocale(locale);
            },
            l10n: l10n,
          ),
        ],
      ),
    );
  }

  Widget _buildPocketTimerTile(AppLocalizations l10n) {
    final int currentSeconds = _pocketTimerSeconds.round();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D131C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: Color(0xFF34A853)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translate('settings.option.pocketTimer.title'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.translate('settings.option.pocketTimer.subtitle'),
                      style: const TextStyle(
                        color: Color(0xFF9AA0A6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.translate(
                    'settings.option.pocketTimer.value',
                    params: {'seconds': currentSeconds.toString()},
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _isPocketTimerLoading
              ? const Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF34A853),
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
                    thumbColor: const Color(0xFF34A853),
                    overlayShape: SliderComponentShape.noOverlay,
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: _pocketTimerSeconds,
                    min: 3,
                    max: 10,
                    divisions: 7,
                    onChanged: (value) {
                      setState(() {
                        _pocketTimerSeconds = value;
                      });
                    },
                    onChangeEnd: (value) {
                      _updatePocketTimer(value.round());
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Future<void> _loadPocketTimerSetting() async {
    try {
      final seconds = await _securityService.getPocketGraceSeconds();
      if (!mounted) return;
      setState(() {
        _pocketTimerSeconds = seconds.toDouble();
        _isPocketTimerLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isPocketTimerLoading = false;
      });
    }
  }

  Future<void> _updatePocketTimer(int seconds) async {
    final clamped = seconds.clamp(3, 10).toInt();
    if (_isPocketTimerUpdating) return;
    setState(() {
      _pocketTimerSeconds = clamped.toDouble();
      _isPocketTimerUpdating = true;
    });
    try {
      await _securityService.setPocketGraceSeconds(clamped);
    } finally {
      if (mounted) {
        setState(() {
          _isPocketTimerUpdating = false;
        });
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D131C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF34A853),
        inactiveThumbColor: Colors.grey[400],
        inactiveTrackColor: Colors.grey[700],
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF9AA0A6), fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildLanguageTile({
    required String title,
    required String subtitle,
    required Locale value,
    required ValueChanged<Locale> onChanged,
    required AppLocalizations l10n,
  }) {
    final options = <Locale, String>{
      const Locale('es'): l10n.translate('settings.option.language.es'),
      const Locale('en'): l10n.translate('settings.option.language.en'),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D131C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: const Icon(Icons.language, color: Color(0xFF34A853)),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF9AA0A6), fontSize: 14),
        ),
        trailing: DropdownButton<Locale>(
          value: value,
          dropdownColor: const Color(0xFF0D131C),
          style: const TextStyle(color: Colors.white),
          underline: const SizedBox.shrink(),
          onChanged: (locale) {
            if (locale != null) {
              onChanged(locale);
            }
          },
          items: options.entries
              .map(
                (entry) => DropdownMenuItem<Locale>(
                  value: entry.key,
                  child: Text(entry.value),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D131C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF34A853)),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF9AA0A6), fontSize: 14),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        onTap: onTap,
      ),
    );
  }
}
