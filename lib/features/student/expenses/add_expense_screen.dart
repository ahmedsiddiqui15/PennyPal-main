import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading_bar.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_success.dart';
import '../../../core/widgets/category_avatar.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../models/expense_model.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/finance_providers.dart';
import '../../../providers/service_providers.dart';
import '../../../providers/settings_providers.dart';
import '../../../services/ocr/receipt_ocr.dart';
import '../../../services/voice_service.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _amount = TextEditingController();
  final TextEditingController _description = TextEditingController();

  ExpenseCategory _category = ExpenseCategory.food;
  DateTime _date = DateTime.now();
  EntrySource _source = EntrySource.manual;
  String? _receiptUrl;
  bool _saving = false;

  
  XFile? _receiptImage;
  ParsedReceipt? _parsed;
  bool _scanning = false;

  
  bool _listening = false;
  String _transcript = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final String? mode =
        GoRouterState.of(context).uri.queryParameters['mode'];
    if (mode == 'receipt') _tabs.index = 1;
    if (mode == 'voice') _tabs.index = 2;
  }

  @override
  void dispose() {
    _tabs.dispose();
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  
  void _applyParsed(ParsedReceipt parsed, EntrySource source) {
    setState(() {
      if (parsed.amount > 0) {
        _amount.text = parsed.amount == parsed.amount.roundToDouble()
            ? parsed.amount.toStringAsFixed(0)
            : parsed.amount.toStringAsFixed(2);
      }
      _category = parsed.category;
      _description.text = parsed.merchant;
      _date = parsed.date ?? DateTime.now();
      _source = source;
    });
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (BuildContext context, Widget? child) => Theme(
        data: Theme.of(context),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      _tabs.animateTo(0);
      return;
    }

    setState(() => _saving = true);
    final String symbol = ref.read(currencySymbolProvider);
    final double parsedAmount = double.parse(_amount.text.trim());

    final ExpenseModel expense = ExpenseModel(
      id: '',
      userId: ref.read(currentUserIdProvider),
      amount: parsedAmount,
      category: _category,
      description: _description.text.trim().isEmpty
          ? _category.label
          : _description.text.trim(),
      date: _date,
      receiptUrl: _receiptUrl,
      source: _source,
    );

    final String? error =
        await ref.read(financeProvider.notifier).addExpense(expense);

    if (!mounted) return;
    setState(() => _saving = false);

    if (error != null) {
      AppSnackbar.error(context, error);
      return;
    }

    await showSuccessOverlay(
      context,
      title: 'Expense saved!',
      message: '${Formatters.money(parsedAmount, symbol: symbol)} '
          'added to ${_category.label}.',
      buttonLabel: 'Great',
    );
    if (mounted) context.pop();
  }

  
  Future<void> _scanReceipt(ImageSource source) async {
    final ReceiptOcrService ocr = ref.read(ocrServiceProvider);
    if (!ocr.isSupported) {
      AppSnackbar.warning(
        context,
        'Receipt scanning needs Android or iOS. Enter the expense manually.',
      );
      _tabs.animateTo(0);
      return;
    }

    try {
      final XFile? image =
          await ImagePicker().pickImage(source: source, imageQuality: 85);
      if (image == null) return;

      setState(() {
        _receiptImage = image;
        _scanning = true;
      });

      final ParsedReceipt parsed = await ocr.parse(image.path);
      if (!mounted) return;
      setState(() {
        _parsed = parsed;
        _scanning = false;
      });
      _applyParsed(parsed, EntrySource.receipt);

      if (!parsed.isValid || parsed.amount <= 0) {
        AppSnackbar.warning(
          context,
          'Could not read an amount. Check the photo or enter it manually.',
        );
        _tabs.animateTo(0);
      } else {
        AppSnackbar.success(
          context,
          'Receipt read — please check the details.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _scanning = false);
      AppSnackbar.error(context, 'Could not read that receipt. Try again.');
    }
  }

  
  Future<void> _toggleListening() async {
    final VoiceCaptureService voice = ref.read(voiceServiceProvider);

    if (_listening) {
      await voice.stop();
      if (mounted) setState(() => _listening = false);
      if (_transcript.isNotEmpty) _applyVoice(_transcript);
      return;
    }

    setState(() {
      _listening = true;
      _transcript = '';
    });

    await voice.start(
      onResult: (String words) {
        if (!mounted) return;
        setState(() => _transcript = words);
      },
      onError: (String error) {
        if (!mounted) return;
        setState(() => _listening = false);
        AppSnackbar.error(context, error);
        
        _tabs.animateTo(0);
      },
    );
  }

  void _applyVoice(String sentence) {
    final ParsedVoiceExpense parsed = parseVoiceExpense(sentence);
    setState(() {
      _amount.text =
          parsed.amount > 0 ? parsed.amount.toStringAsFixed(0) : _amount.text;
      _category = parsed.category;
      _description.text = parsed.description;
      _source = EntrySource.voice;
    });
    AppSnackbar.info(context, 'Heard you — confirm and save.');
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.edit_note_rounded), text: 'Manual'),
            Tab(icon: Icon(Icons.document_scanner_outlined), text: 'Scan'),
            Tab(icon: Icon(Icons.mic_none_rounded), text: 'Voice'),
          ],
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: TabBarView(
            controller: _tabs,
            children: [
              _manualTab(palette),
              _scanTab(palette),
              _voiceTab(palette),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spaceMd),
          child: PrimaryButton(
            label: 'Save Expense',
            icon: Icons.check_rounded,
            isLoading: _saving,
            onPressed: _save,
          ),
        ),
      ),
    );
  }

  
  Widget _manualTab(AppPalette palette) {
    return ListView(
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      children: [
        _AmountCard(controller: _amount),
        const SizedBox(height: AppConstants.spaceLg),
        Text('Category',
            style: AppTextStyles.subtitle.copyWith(color: palette.textPrimary)),
        const SizedBox(height: AppConstants.spaceSm),
        _CategoryGrid(
          selected: _category,
          onSelect: (ExpenseCategory c) => setState(() {
            _category = c;
            _source = EntrySource.manual;
          }),
        ),
        const SizedBox(height: AppConstants.spaceLg),
        AppCard(
          onTap: _pickDate,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spaceMd,
            vertical: 14,
          ),
          radius: AppConstants.radiusMd,
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  Formatters.date(_date),
                  style: AppTextStyles.body.copyWith(color: palette.textPrimary),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: palette.textSecondary),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.spaceMd),
        AppTextField(
          label: 'Description',
          hint: 'e.g. Lunch with friends',
          controller: _description,
          icon: Icons.notes_rounded,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 2,
        ),
        const SizedBox(height: AppConstants.spaceXl),
      ],
    );
  }

  Widget _scanTab(AppPalette palette) {
    final ReceiptOcrService ocr = ref.read(ocrServiceProvider);

    return ListView(
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppConstants.spaceLg),
          child: Column(
            children: [
              Container(
                height: 92,
                width: 92,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.document_scanner_outlined,
                    size: 42, color: AppColors.primary),
              ),
              const SizedBox(height: AppConstants.spaceMd),
              Text('Scan a receipt',
                  style: AppTextStyles.title.copyWith(color: palette.textPrimary)),
              const SizedBox(height: 6),
              Text(
                ocr.isSupported
                    ? 'Take a photo of a receipt or bill QR. PennyPal reads '
                        'the total from the text and from payment QR codes.'
                    : 'Receipt scanning requires Android or iOS. '
                        'Use Manual entry on this device.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: palette.textSecondary),
              ),
              const SizedBox(height: AppConstants.spaceLg),
              if (_scanning)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: AppLoadingBar(),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: 'Camera',
                        icon: Icons.camera_alt_rounded,
                        enabled: ocr.isSupported,
                        onPressed: () => _scanReceipt(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spaceMd),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Gallery',
                        icon: Icons.photo_library_outlined,
                        outlined: true,
                        enabled: ocr.isSupported,
                        onPressed: () => _scanReceipt(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (_receiptImage != null) ...[
          const SizedBox(height: AppConstants.spaceLg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scanned receipt',
                    style: AppTextStyles.subtitle
                        .copyWith(color: palette.textPrimary)),
                const SizedBox(height: AppConstants.spaceMd),
                if (!kIsWeb && _receiptImage != null)
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMd),
                    child: Image.file(
                      File(_receiptImage!.path),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                if (_parsed != null) ...[
                  const SizedBox(height: AppConstants.spaceMd),
                  _ParsedSummary(
                    amount: _parsed!.amount,
                    category: _parsed!.category,
                    merchant: _parsed!.merchant,
                    confidence: _parsed!.confidence,
                    symbol: ref.watch(currencySymbolProvider),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _voiceTab(AppPalette palette) {
    return ListView(
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppConstants.spaceLg),
          child: Column(
            children: [
              GestureDetector(
                onTap: _toggleListening,
                child: Container(
                  height: 130,
                  width: 130,
                  decoration: BoxDecoration(
                    gradient: _listening
                        ? AppColors.dangerGradient
                        : AppColors.amberGradient,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.amber,
                  ),
                  child: Icon(
                    _listening ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 52,
                  ),
                )
                    .animate(target: _listening ? 1 : 0)
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.06, 1.06),
                      duration: 600.ms,
                    ),
              ),
              const SizedBox(height: AppConstants.spaceLg),
              Text(
                _listening ? 'Listening…' : 'Tap to speak',
                style: AppTextStyles.title.copyWith(color: palette.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Try: "I spent 500 on lunch"',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: palette.textSecondary),
              ),
              if (_transcript.isNotEmpty) ...[
                const SizedBox(height: AppConstants.spaceLg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppConstants.spaceMd),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMd),
                  ),
                  child: Text(
                    '"$_transcript"',
                    style: AppTextStyles.body.copyWith(color: palette.textPrimary),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppConstants.spaceLg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Parsed preview',
                  style: AppTextStyles.subtitle.copyWith(color: palette.textPrimary)),
              const SizedBox(height: AppConstants.spaceMd),
              Row(
                children: [
                  CategoryAvatar(expenseCategory: _category, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _amount.text.isEmpty
                              ? 'Amount not set'
                              : '${ref.watch(currencySymbolProvider)}${_amount.text}',
                          style: AppTextStyles.subtitle
                              .copyWith(color: palette.textPrimary),
                        ),
                        Text(
                          _category.label,
                          style: AppTextStyles.caption
                              .copyWith(color: palette.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AmountCard extends ConsumerWidget {
  const _AmountCard({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = context.palette;
    final String symbol = ref.watch(currencySymbolProvider);

    return AppCard(
      padding: const EdgeInsets.all(AppConstants.spaceLg),
      color: AppColors.primary.withValues(alpha: 0.07),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Amount',
              style: AppTextStyles.caption.copyWith(color: palette.textSecondary)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: Validators.amount,
            style: AppTextStyles.display.copyWith(color: palette.textPrimary),
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              prefixText: '$symbol ',
              prefixStyle:
                  AppTextStyles.display.copyWith(color: AppColors.primaryDark),
              hintText: '0',
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.selected, required this.onSelect});

  final ExpenseCategory selected;
  final ValueChanged<ExpenseCategory> onSelect;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return Wrap(
      spacing: AppConstants.spaceSm,
      runSpacing: AppConstants.spaceSm,
      children: ExpenseCategory.values.map((ExpenseCategory c) {
        final bool isSelected = c == selected;
        return GestureDetector(
          onTap: () => onSelect(c),
          child: AnimatedContainer(
            duration: AppConstants.durationFast,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? c.color.withValues(alpha: 0.14) : palette.card,
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              border: Border.all(
                color: isSelected ? c.color : palette.border,
                width: isSelected ? 1.6 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(c.icon, size: 17, color: isSelected ? c.color : palette.textSecondary),
                const SizedBox(width: 8),
                Text(
                  c.label,
                  style: AppTextStyles.caption.copyWith(
                    color: isSelected ? c.color : palette.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ParsedSummary extends StatelessWidget {
  const _ParsedSummary({
    required this.amount,
    required this.category,
    required this.merchant,
    required this.confidence,
    required this.symbol,
  });

  final double amount;
  final ExpenseCategory category;
  final String merchant;
  final double confidence;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return Row(
      children: [
        CategoryAvatar(expenseCategory: category, size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(merchant,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.subtitle
                      .copyWith(color: palette.textPrimary)),
              Text(
                '${category.label} • ${(confidence * 100).round()}% confidence',
                style: AppTextStyles.caption
                    .copyWith(color: palette.textSecondary),
              ),
            ],
          ),
        ),
        Text(
          Formatters.money(amount, symbol: symbol),
          style: AppTextStyles.subtitle.copyWith(color: palette.textPrimary),
        ),
      ],
    );
  }
}
