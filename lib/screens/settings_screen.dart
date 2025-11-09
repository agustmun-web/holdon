import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import 'sensor_test_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _vibrationEnabled = true;
  bool _darkModeEnabled = true;
  Locale? _selectedLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedLocale ??= AppStateProvider.of(context).locale;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appState = AppStateProvider.of(context);
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
            title: l10n.translate('settings.option.vibration'),
            subtitle: l10n.translate('settings.option.vibration.subtitle'),
            value: _vibrationEnabled,
            onChanged: (value) {
              setState(() {
                _vibrationEnabled = value;
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
          const SizedBox(height: 24),
          _buildSectionHeader(l10n.translate('settings.section.diagnostics')),
          const SizedBox(height: 12),
          _buildNavigationTile(
            icon: Icons.science,
            title: l10n.translate('settings.option.sensorTest'),
            subtitle: l10n.translate('settings.option.sensorTest.subtitle'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SensorTestScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
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
          style: const TextStyle(
            color: Color(0xFF9AA0A6),
            fontSize: 14,
          ),
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
        leading: const Icon(
          Icons.language,
          color: Color(0xFF34A853),
        ),
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
          style: const TextStyle(
            color: Color(0xFF9AA0A6),
            fontSize: 14,
          ),
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
        leading: Icon(
          icon,
          color: const Color(0xFF34A853),
        ),
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
          style: const TextStyle(
            color: Color(0xFF9AA0A6),
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.white54,
        ),
        onTap: onTap,
      ),
    );
  }
}

