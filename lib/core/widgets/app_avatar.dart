import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/formatters.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.imageBytes,
    this.size = 48,
    this.onTap,
    this.showEditBadge = false,
  });

  final String name;

  
  final String? imageUrl;

  
  
  final Uint8List? imageBytes;

  final double size;
  final VoidCallback? onTap;
  final bool showEditBadge;

  @override
  Widget build(BuildContext context) {
    final bool hasBytes = imageBytes != null && imageBytes!.isNotEmpty;
    final bool hasUrl = imageUrl != null && imageUrl!.isNotEmpty;

    final Widget avatar = Container(
      height: size,
      width: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: (hasBytes || hasUrl) ? null : AppColors.amberGradient,
        shape: BoxShape.circle,
      ),
      child: hasBytes
          ? Image.memory(
              imageBytes!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(context),
            )
          : hasUrl
              ? Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallback(context),
                )
              : _fallback(context),
    );

    final Widget withBadge = showEditBadge
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              avatar,
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.palette.card, width: 2),
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    size: size * 0.2,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          )
        : avatar;

    if (onTap == null) return withBadge;
    return GestureDetector(onTap: onTap, child: withBadge);
  }

  Widget _fallback(BuildContext context) => Center(
        child: Text(
          Formatters.initials(name),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.34,
          ),
        ),
      );
}
