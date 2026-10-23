import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

/// Settings page: signed-in account info, app info, configurations, and log out.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Controllers for the configuration text fields
  final TextEditingController _paymentController = TextEditingController();
  final TextEditingController _bathroomController = TextEditingController();
  final TextEditingController _airconController = TextEditingController();
  final TextEditingController _maintenanceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      AppConfig.paymentDueSoonDays = prefs.getInt('paymentDueSoonDays') ?? AppConfig.paymentDueSoonDays;
      AppConfig.bathroomDueDays = prefs.getInt('bathroomDueDays') ?? AppConfig.bathroomDueDays;
      AppConfig.airConDueDays = prefs.getInt('airConDueDays') ?? AppConfig.airConDueDays;
      AppConfig.maintenanceDueDays = prefs.getInt('maintenanceDueDays') ?? AppConfig.maintenanceDueDays;

      _paymentController.text = AppConfig.paymentDueSoonDays.toString();
      _bathroomController.text = AppConfig.bathroomDueDays.toString();
      _airconController.text = AppConfig.airConDueDays.toString();
      _maintenanceController.text = AppConfig.maintenanceDueDays.toString();
    });
  }

  Future<void> _updateSetting(String key, String value, void Function(int) updateAppConfig) async {
    final intValue = int.tryParse(value);
    if (intValue == null) return;

    updateAppConfig(intValue);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, intValue);
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _paymentController.dispose();
    _bathroomController.dispose();
    _airconController.dispose();
    _maintenanceController.dispose();
    super.dispose();
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await FirebaseAuth.instance.signOut();
    if (context.mounted) Navigator.of(context).pop();
  }

  /// Helper method to build consistent configuration rows
  Widget _buildConfigRow(String title, TextEditingController controller, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 100,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                suffixText: 'days',
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: AppColors.primary,
                child: Icon(Icons.person_outline),
              ),
              title: Text(user?.email ?? 'Unknown account'),
              subtitle: const Text('Signed in'),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: AppColors.primary,
                child: Icon(Icons.home_work_outlined),
              ),
              title: Text(AppConfig.appName),
              subtitle: Text('${AppConfig.totalRooms} rooms'),
            ),
          ),

          const SizedBox(height: 24),

          // Configuration Section
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              'Notification Thresholds',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _buildConfigRow(
                      'Payment Due Soon',
                      _paymentController,
                      (val) => _updateSetting('paymentDueSoonDays', val, (newVal) => AppConfig.paymentDueSoonDays = newVal)
                  ),
                  const Divider(height: 1),
                  _buildConfigRow(
                      'Bathroom Cleaning',
                      _bathroomController,
                      (val) => _updateSetting('bathroomDueDays', val, (newVal) => AppConfig.bathroomDueDays = newVal)
                  ),
                  const Divider(height: 1),
                  _buildConfigRow(
                      'AirCon Service',
                      _airconController,
                      (val) => _updateSetting('airConDueDays', val, (newVal) => AppConfig.airConDueDays = newVal)
                  ),
                  const Divider(height: 1),
                  _buildConfigRow(
                      'General Maintenance',
                      _maintenanceController,
                      (val) => _updateSetting('maintenanceDueDays', val, (newVal) => AppConfig.maintenanceDueDays = newVal)
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          FilledButton.icon(
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}