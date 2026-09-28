import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/gemini_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_loading_bar.dart';
import '../../../core/widgets/currency_tile.dart';
import '../../../core/widgets/penny_ai_icon.dart';
import '../../../core/widgets/section_header.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/currency_providers.dart';
import '../../../providers/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _onCurrencyTap(
    BuildContext context,
    WidgetRef ref,
    String code,
  ) async {
    if (ref.read(settingsProvider).currencyCode == code) return;

    
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: AppLoadingBar()),
    );

    final String? error =
        await ref.read(currencyControllerProvider).change(code);

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;
    final SettingsState settings = ref.watch(settingsProvider);
    final SettingsController controller = ref.read(settingsProvider.notifier);
    final bool geminiReady = ref.watch(effectiveAiApiKeyProvider).isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.spaceMd,
          AppConstants.spaceSm,
          AppConstants.spaceMd,
          AppConstants.spaceXxl,
        ),
        children: [
          
          const SectionHeader(
            title: 'Appearance',
            subtitle: 'Choose how PennyPal looks',
          ),
          AppCard(
            child: Column(
              children: [
                _ThemeOption(
                  label: 'System',
                  subtitle: 'Follow device settings',
                  icon: Icons.brightness_auto_rounded,
                  selected: settings.themeMode == ThemeMode.system,
                  onTap: () => controller.setThemeMode(ThemeMode.system),
                ),
                _ThemeOption(
                  label: 'Light',
                  subtitle: 'Bright and clean',
                  icon: Icons.light_mode_rounded,
                  selected: settings.themeMode == ThemeMode.light,
                  onTap: () => controller.setThemeMode(ThemeMode.light),
                ),
                _ThemeOption(
                  label: 'Dark',
                  subtitle: 'Easy on the eyes',
                  icon: Icons.dark_mode_rounded,
                  selected: settings.themeMode == ThemeMode.dark,
                  onTap: () => controller.setThemeMode(ThemeMode.dark),
                  last: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppConstants.spaceLg),

          
          const SectionHeader(
            title: 'Currency',
            subtitle: 'Amounts convert when you switch',
          ),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Column(
              children: AppConfig.currencies.asMap().entries
                  .map(
                    (MapEntry<int, CurrencyOption> e) => CurrencyTile(
                      option: e.value,
                      selected: settings.currencyCode == e.value.code,
                      showDivider: e.key != AppConfig.currencies.length - 1,
                      onTap: () => _onCurrencyTap(context, ref, e.value.code),
                    ),
                  )
                  .toList(),
            ),
          ),

          const SizedBox(height: AppConstants.spaceLg),

          
          const SectionHeader(title: 'Notifications'),
          AppCard(
            child: Column(
              children: [
                SwitchListTile(
                  value: settings.notificationsEnabled,
                  onChanged: controller.setNotificationsEnabled,
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.primary,
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: Text('Push notifications',
                      style: AppTextStyles.subtitle
                          .copyWith(color: palette.textPrimary)),
                  subtitle: Text('Budget alerts, reminders and tips',
                      style: AppTextStyles.caption
                          .copyWith(color: palette.textSecondary)),
                ),
                Divider(color: palette.divider),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule_rounded),
                  title: Text('Daily saving reminder',
                      style: AppTextStyles.subtitle
                          .copyWith(color: palette.textPrimary)),
                  subtitle: Text(
                    _formatHour(settings.reminderHour),
                    style: AppTextStyles.caption
                        .copyWith(color: palette.textSecondary),
                  ),
                  trailing:
                      Icon(Icons.chevron_right_rounded, color: palette.textSecondary),
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(hour: settings.reminderHour, minute: 0),
                    );
                    if (picked != null) {
                      await controller.setReminderHour(picked.hour);
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppConstants.spaceLg),

          
          const SectionHeader(
            title: 'AI Assistant',
            subtitle: 'The brain behind the Penny chat',
          ),
          AppCard(
            onTap: () => _editAiSettings(context, ref),
            child: Row(
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: geminiReady
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : palette.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    pennyAiGlyph,
                    color: geminiReady
                        ? AppColors.primaryDark
                        : palette.textSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        geminiReady ? 'Gemini connected' : 'Offline coach',
                        style: AppTextStyles.subtitle
                            .copyWith(color: palette.textPrimary),
                      ),
                      Text(
                        geminiReady
                            ? 'Penny answers with Google Gemini'
                            : 'Add an API key to use Gemini',
                        style: AppTextStyles.caption
                            .copyWith(color: palette.textSecondary),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: palette.textSecondary),
              ],
            ),
          ),

          const SizedBox(height: AppConstants.spaceLg),

          
          const SectionHeader(title: 'About', subtitle: 'Tap to learn more'),
          AppCard(
            onTap: () => context.push(AppRoutes.about),
            child: Column(
              children: [
                _InfoRow(label: 'App', value: AppConstants.appName),
                Divider(color: palette.divider),
                _InfoRow(label: 'Tagline', value: AppConstants.tagline),
                Divider(color: palette.divider),
                _InfoRow(label: 'Version', value: AppConfig.appVersion),
                Divider(color: palette.divider),
                _InfoRow(label: 'Backend', value: 'Firebase Firestore'),
                Divider(color: palette.divider),
                Row(
                  children: [
                    Expanded(
                      child: Text('About PennyPal',
                          style: AppTextStyles.subtitle
                              .copyWith(color: palette.textPrimary)),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: palette.textSecondary),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppConstants.spaceLg),
          AppCard(
            onTap: () => context.push(AppRoutes.support),
            child: Row(
              children: [
                const Icon(Icons.support_agent_rounded,
                    color: AppColors.primaryDark),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Help & Support',
                      style: AppTextStyles.subtitle
                          .copyWith(color: palette.textPrimary)),
                ),
                Icon(Icons.chevron_right_rounded, color: palette.textSecondary),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spaceMd),
          AppCard(
            onTap: () async {
              final bool confirmed = await AppDialog.confirm(
                context,
                title: 'Log out?',
                message: 'You will need to sign in again.',
                confirmLabel: 'Log Out',
                destructive: true,
              );
              if (confirmed) {
                await ref.read(authProvider.notifier).signOut();
              }
            },
            color: AppColors.danger.withValues(alpha: 0.07),
            child: Row(
              children: [
                const Icon(Icons.logout_rounded, color: AppColors.danger),
                const SizedBox(width: 12),
                Text('Log Out',
                    style: AppTextStyles.subtitle
                        .copyWith(color: AppColors.danger)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatHour(int hour) {
    final int display = hour % 12 == 0 ? 12 : hour % 12;
    final String suffix = hour < 12 ? 'AM' : 'PM';
    return 'Every day at $display:00 $suffix';
  }

  Future<void> _editAiSettings(BuildContext context, WidgetRef ref) async {
    final SettingsState settings = ref.read(settingsProvider);
    final _AiKeyResult? result = await showDialog<_AiKeyResult>(
      context: context,
      builder: (_) => _ApiKeyDialog(
        initialKey: settings.aiApiKey ?? '',
        initialModel: settings.aiModel ?? GeminiConfig.defaultModel,
      ),
    );
    if (result == null) return;
    final SettingsController controller = ref.read(settingsProvider.notifier);
    await controller.setAiApiKey(result.apiKey);
    await controller.setAiModel(result.model);
  }
}

class _AiKeyResult {
  const _AiKeyResult({this.apiKey, this.model});

  final String? apiKey;
  final String? model;
}

class _ApiKeyDialog extends StatefulWidget {
  const _ApiKeyDialog({required this.initialKey, required this.initialModel});

  final String initialKey;
  final String initialModel;

  @override
  State<_ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends State<_ApiKeyDialog> {
  late final TextEditingController _key =
      TextEditingController(text: widget.initialKey);
  late final TextEditingController _model =
      TextEditingController(text: widget.initialModel);
  bool _obscure = true;

  @override
  void dispose() {
    _key.dispose();
    _model.dispose();
    super.dispose();
  }

  void _save() {
    final String key = _key.text.trim();
    final String model = _model.text.trim();
    Navigator.of(context).pop(_AiKeyResult(
      apiKey: key.isEmpty ? null : key,
      model: model.isEmpty ? null : model,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return AlertDialog(
      title: const Text('Penny AI'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste a Google Gemini API key so Penny can answer with Gemini. '
              'Leave it empty to use the built-in offline coach.',
              style:
                  AppTextStyles.caption.copyWith(color: palette.textSecondary),
            ),
            const SizedBox(height: AppConstants.spaceMd),
            TextField(
              controller: _key,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: 'Gemini API key',
                hintText: 'AIza…',
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show' : 'Hide',
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spaceMd),
            TextField(
              controller: _model,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Model',
                hintText: 'gemini-flash-latest',
              ),
            ),
            const SizedBox(height: AppConstants.spaceSm),
            Text(
              'Your questions and a summary of your numbers are sent to Google '
              'when Gemini is enabled.',
              style:
                  AppTextStyles.caption.copyWith(color: palette.textSecondary),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(const _AiKeyResult()),
          child: const Text('Clear'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.last = false,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          onTap: onTap,
          leading: Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : palette.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: selected ? AppColors.primaryDark : palette.textSecondary,
              size: 20,
            ),
          ),
          title: Text(label,
              style: AppTextStyles.subtitle.copyWith(color: palette.textPrimary)),
          subtitle: Text(subtitle,
              style:
                  AppTextStyles.caption.copyWith(color: palette.textSecondary)),
          trailing: Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
            color: selected ? AppColors.primary : palette.textSecondary,
          ),
        ),
        if (!last) Divider(color: palette.divider),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style:
                    AppTextStyles.body.copyWith(color: palette.textSecondary)),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style:
                  AppTextStyles.subtitle.copyWith(color: palette.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
