import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/currency_converter.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading_bar.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../core/widgets/currency_tile.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/currency_providers.dart';
import '../../../providers/profile_image_providers.dart';
import '../../../providers/service_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../../services/profile_image_service.dart';

enum _PhotoAction { gallery, camera, remove }

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _incomeGoal;

  bool _saving = false;
  bool _savingPhoto = false;
  bool _changingCurrency = false;
  String? _localImagePath;

  @override
  void initState() {
    super.initState();
    final UserModel? user = ref.read(currentUserProvider);
    _name = TextEditingController(text: user?.name ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
    _incomeGoal = TextEditingController(
      text: _formatGoal(user?.monthlyIncomeGoal ?? 0),
    );
    _loadLocalImage();
  }

  Future<void> _loadLocalImage() async {
    final UserModel? user = ref.read(currentUserProvider);
    if (user == null) return;
    final String? path =
        await ref.read(profileImageServiceProvider).getLocalImagePath(user.id);
    if (!mounted) return;
    setState(() => _localImagePath = path);
  }

  String _formatGoal(double value) {
    if (value <= 0) return '';
    final String code = ref.read(settingsProvider).currencyCode;
    if (CurrencyConverter.usesDecimals(code)) {
      return value.toStringAsFixed(2);
    }
    return value.round().toString();
  }

  Future<void> _onCurrencyTap(String code) async {
    if (_changingCurrency) return;
    if (ref.read(settingsProvider).currencyCode == code) return;

    setState(() => _changingCurrency = true);
    final String? error =
        await ref.read(currencyControllerProvider).change(code);
    if (!mounted) return;

    final UserModel? user = ref.read(currentUserProvider);
    if (user != null) {
      _incomeGoal.text = _formatGoal(user.monthlyIncomeGoal);
    }

    setState(() => _changingCurrency = false);

    if (error != null) {
      AppSnackbar.error(context, error);
    } else {
      AppSnackbar.success(context, 'Currency updated and amounts converted.');
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _incomeGoal.dispose();
    super.dispose();
  }

  Future<void> _pickAndSave(ImageSource source) async {
    final UserModel? user = ref.read(currentUserProvider);
    if (user == null) return;

    final ProfileImageService service = ref.read(profileImageServiceProvider);

    try {
      final XFile? picked = await service.pickImage(source: source);
      if (picked == null || !mounted) return;

      setState(() => _savingPhoto = true);

      final String path = await service.savePickedImage(
        userId: user.id,
        picked: picked,
      );

      if (!mounted) return;
      setState(() {
        _localImagePath = path;
        _savingPhoto = false;
      });
      ref.invalidate(localProfileImagePathProvider);
      AppSnackbar.success(context, 'Profile photo saved on this device.');
    } on ProfileImageException catch (e) {
      if (!mounted) return;
      setState(() => _savingPhoto = false);
      AppSnackbar.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _savingPhoto = false);
      AppSnackbar.error(context, 'Could not save photo. Please try again.');
    }
  }

  Future<void> _removePhoto() async {
    final UserModel? user = ref.read(currentUserProvider);
    if (user == null || _localImagePath == null) return;

    setState(() => _savingPhoto = true);
    try {
      await ref.read(profileImageServiceProvider).deleteProfileImage(user.id);
      if (!mounted) return;
      setState(() {
        _localImagePath = null;
        _savingPhoto = false;
      });
      ref.invalidate(localProfileImagePathProvider);
      AppSnackbar.success(context, 'Profile photo removed.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _savingPhoto = false);
      AppSnackbar.error(context, 'Could not remove photo.');
    }
  }

  Future<void> _onAvatarTap() async {
    final _PhotoAction? action = await showModalBottomSheet<_PhotoAction>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, _PhotoAction.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(context, _PhotoAction.camera),
              ),
              if (_localImagePath != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.danger,
                  ),
                  title: const Text(
                    'Remove photo',
                    style: TextStyle(color: AppColors.danger),
                  ),
                  onTap: () => Navigator.pop(context, _PhotoAction.remove),
                ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    switch (action) {
      case _PhotoAction.gallery:
        await _pickAndSave(ImageSource.gallery);
      case _PhotoAction.camera:
        await _pickAndSave(ImageSource.camera);
      case _PhotoAction.remove:
        await _removePhoto();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final UserModel? user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _saving = true);

    final UserModel updated = user.copyWith(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      currencyCode: ref.read(settingsProvider).currencyCode,
      currencySymbol: ref.read(settingsProvider).currencySymbol,
      monthlyIncomeGoal: double.tryParse(_incomeGoal.text.trim()) ?? 0,
    );

    await ref.read(authProvider.notifier).updateProfile(updated);

    if (!mounted) return;
    setState(() => _saving = false);
    AppSnackbar.success(context, 'Profile updated.');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final UserModel? user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(body: LoadingView());
    }

    final AppPalette palette = context.palette;
    final String symbol = ref.watch(currencySymbolProvider);
    final AsyncValue<String?> localPath =
        ref.watch(localProfileImagePathProvider);
    final String? displayPath = _localImagePath ?? localPath.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppConstants.spaceMd),
            children: [
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        AppAvatar(
                          name: _name.text.isEmpty ? user.name : _name.text,
                          imagePath: displayPath,
                          imageUrl: displayPath == null ? user.photoUrl : null,
                          size: 104,
                          showEditBadge: true,
                          onTap: _savingPhoto ? null : _onAvatarTap,
                        ),
                        if (_savingPhoto)
                          const Positioned(
                            bottom: 0,
                            child: AppLoadingBar(width: 72, height: 3),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: _savingPhoto ? null : _onAvatarTap,
                      icon: const Icon(Icons.photo_camera_outlined, size: 18),
                      label: const Text('Change photo'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spaceMd),
              AppTextField(
                label: 'Full Name',
                controller: _name,
                icon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
                validator: Validators.name,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppConstants.spaceMd),
              AppTextField(
                label: 'Email Address',
                controller: TextEditingController(text: user.email),
                icon: Icons.alternate_email_rounded,
                enabled: false,
              ),
              const SizedBox(height: AppConstants.spaceMd),
              AppTextField(
                label: 'Mobile Number',
                controller: _phone,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: Validators.phone,
              ),
              const SizedBox(height: AppConstants.spaceMd),
              AppTextField(
                label: 'Monthly income goal',
                hint: 'e.g. 40000',
                controller: _incomeGoal,
                icon: Icons.trending_up_rounded,
                prefixText: '$symbol ',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: AppConstants.spaceLg),
              Text(
                'Preferred currency',
                style: AppTextStyles.subtitle
                    .copyWith(color: palette.textPrimary),
              ),
              const SizedBox(height: AppConstants.spaceSm),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Column(
                  children: AppConfig.currencies.asMap().entries
                      .map(
                        (MapEntry<int, CurrencyOption> e) => CurrencyTile(
                          option: e.value,
                          selected: ref.watch(settingsProvider).currencyCode ==
                              e.value.code,
                          showDivider:
                              e.key != AppConfig.currencies.length - 1,
                          onTap: _changingCurrency
                              ? null
                              : () => _onCurrencyTap(e.value.code),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: AppConstants.spaceXl),
              PrimaryButton(
                label: 'Save Changes',
                icon: Icons.check_rounded,
                isLoading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
