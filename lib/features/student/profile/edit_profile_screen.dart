import 'dart:typed_data';

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
import '../../../providers/service_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../../services/cloudinary_service.dart';

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
  bool _uploadingPhoto = false;
  bool _changingCurrency = false;
  String? _photoUrl;

  
  
  Uint8List? _photoBytes;
  bool _initialised = false;

  @override
  void initState() {
    super.initState();
    final UserModel? user = ref.read(currentUserProvider);
    _name = TextEditingController(text: user?.name ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
    _incomeGoal = TextEditingController(
      text: _formatGoal(user?.monthlyIncomeGoal ?? 0),
    );
    _photoUrl = user?.photoUrl;
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

  Future<void> _pickPhoto() async {
    try {
      final XFile? photo = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
      );
      if (photo == null) return;

      final Uint8List bytes = await photo.readAsBytes();
      if (!mounted) return;
      
      setState(() {
        _photoBytes = bytes;
        _uploadingPhoto = true;
      });

      final CloudinaryService cloudinary = ref.read(cloudinaryServiceProvider);
      if (!cloudinary.isConfigured) {
        
        if (!mounted) return;
        setState(() => _uploadingPhoto = false);
        AppSnackbar.info(
          context,
          'Photo shown locally. Add your Cloudinary cloud name and upload '
          'preset to enable uploads.',
        );
        return;
      }

      final String url = await cloudinary.uploadImage(
        bytes: bytes,
        fileName: 'avatar.jpg',
      );
      if (!mounted) return;
      setState(() {
        _photoUrl = url;
        _uploadingPhoto = false;
      });
      AppSnackbar.success(context, 'Photo updated.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      
      
      AppSnackbar.error(context, 'Photo upload failed: $e');
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
      photoUrl: _photoUrl,
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
    if (!_initialised) {
      _initialised = true;
    }

    final AppPalette palette = context.palette;
    final String symbol = ref.watch(currencySymbolProvider);

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
                          imageUrl: _photoUrl,
                          imageBytes: _photoBytes,
                          size: 104,
                          showEditBadge: true,
                          onTap: _uploadingPhoto ? null : _pickPhoto,
                        ),
                        if (_uploadingPhoto)
                          const Positioned(
                            bottom: 0,
                            child: AppLoadingBar(width: 72, height: 3),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: _uploadingPhoto ? null : _pickPhoto,
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
              Text('Preferred currency',
                  style: AppTextStyles.subtitle
                      .copyWith(color: palette.textPrimary)),
              const SizedBox(height: AppConstants.spaceSm),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Column(
                  children: AppConfig.currencies.asMap().entries
                      .map(
                        (MapEntry<int, CurrencyOption> e) => CurrencyTile(
                          option: e.value,
                          selected:
                              ref.watch(settingsProvider).currencyCode ==
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
