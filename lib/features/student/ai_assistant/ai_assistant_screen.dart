import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/penny_ai_icon.dart';
import '../../../models/ai_message_model.dart';
import '../../../providers/content_providers.dart';
import '../../../providers/settings_providers.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _send([String? preset]) async {
    final String text = preset ?? _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    _scrollToBottom();
    await ref.read(chatProvider.notifier).send(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final List<ChatMessage> messages = ref.watch(chatProvider);
    final bool busy = messages.isNotEmpty && messages.last.isTyping;
    final bool geminiReady = ref.watch(effectiveAiApiKeyProvider).isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            PennyAiIcon(size: 34),
            SizedBox(width: 10),
            Text('Penny AI'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Clear chat',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(chatProvider.notifier).clear(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!geminiReady)
              _OfflineCoachBanner(
                onTap: () => context.push(AppRoutes.settings),
              ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(AppConstants.spaceMd),
                itemCount: messages.length,
                itemBuilder: (BuildContext context, int i) => _Bubble(
                  message: messages[i],
                ),
              ),
            ),
            if (messages.length <= 1)
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spaceMd,
                  ),
                  children: [
                    for (final String prompt in _suggestions)
                      Padding(
                        padding: const EdgeInsets.only(
                          right: AppConstants.spaceSm,
                        ),
                        child: ActionChip(
                          avatar: Icon(
                            pennyAiGlyph,
                            size: 16,
                            color: AppColors.primaryDark,
                          ),
                          label: Text(prompt),
                          onPressed: () => _send(prompt),
                          backgroundColor: palette.surfaceMuted,
                          side: BorderSide(color: palette.border),
                          labelStyle: AppTextStyles.caption
                              .copyWith(color: palette.textPrimary),
                        ),
                      ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spaceMd,
                AppConstants.spaceSm,
                AppConstants.spaceMd,
                AppConstants.spaceMd,
              ),
              decoration: BoxDecoration(
                color: palette.card,
                border: Border(top: BorderSide(color: palette.divider)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      style: AppTextStyles.body
                          .copyWith(color: palette.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Ask about your money…',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spaceSm),
                  SizedBox(
                    height: 54,
                    width: 54,
                    child: FilledButton(
                      onPressed: busy ? null : () => _send(),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusMd,
                          ),
                        ),
                      ),
                      child: busy
                          ? const _SendLoadingPlaceholder()
                          : const Icon(Icons.send_rounded, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const List<String> _suggestions = [
    'How can I save money?',
    'Where am I overspending?',
    'Create a budget for me',
    'How much will I spend next month?',
  ];
}

class _OfflineCoachBanner extends StatelessWidget {
  const _OfflineCoachBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spaceMd,
          vertical: 10,
        ),
        color: palette.surfaceMuted,
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded,
                size: 16, color: palette.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Offline coach — add a Gemini key in Settings for smarter answers.',
                style:
                    AppTextStyles.caption.copyWith(color: palette.textSecondary),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: palette.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final bool isUser = message.isUser;

    final Widget bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.76,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: isUser ? AppColors.amberGradient : null,
        color: isUser ? null : palette.card,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(AppConstants.radiusLg),
          topRight: const Radius.circular(AppConstants.radiusLg),
          bottomLeft: Radius.circular(isUser ? AppConstants.radiusLg : 4),
          bottomRight: Radius.circular(isUser ? 4 : AppConstants.radiusLg),
        ),
        border: isUser ? null : Border.all(color: palette.border),
      ),
      child: message.isTyping
          ? const _TypingIndicator()
          : Text(
              message.text,
              style: AppTextStyles.body.copyWith(
                color: isUser ? Colors.white : palette.textPrimary,
                height: 1.4,
              ),
            ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spaceMd),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const PennyAiIcon(size: 30),
            const SizedBox(width: 8),
          ],
          Flexible(child: bubble),
        ],
      )
          .animate()
          .fadeIn(duration: const Duration(milliseconds: 260))
          .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmerBar(width: 72),
          const SizedBox(height: 6),
          _shimmerBar(width: 48),
        ],
      ),
    );
  }

  Widget _shimmerBar({required double width}) {
    return Container(
      height: 8,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppConstants.radiusPill),
      ),
    )
        .animate(onPlay: (AnimationController c) => c.repeat(reverse: true))
        .fade(begin: 0.35, end: 1, duration: 700.ms);
  }
}

class _SendLoadingPlaceholder extends StatelessWidget {
  const _SendLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusPill),
        child: const LinearProgressIndicator(
          minHeight: 3,
          backgroundColor: Colors.white24,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }
}
