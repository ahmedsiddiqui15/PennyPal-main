import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/formatters.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.imagePath,
    this.imageBytes,
    this.size = 48,
    this.onTap,
    this.showEditBadge = false,
  });

  final String name;
  final String? imageUrl;
  final String? imagePath;
  final Uint8List? imageBytes;
  final double size;
  final VoidCallback? onTap;
  final bool showEditBadge;

  bool get _hasBytes => imageBytes != null && imageBytes!.isNotEmpty;

  bool get _hasLocalPath {
    final String? path = imagePath;
    if (path == null || path.isEmpty) return false;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return false;
    }
    return true;
  }

  bool get _hasNetworkUrl {
    final String? url = imageUrl;
    if (url == null || url.isEmpty) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final bool hasImage = _hasBytes || _hasLocalPath || _hasNetworkUrl;

    final Widget avatar = Container(
      height: size,
      width: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: hasImage ? null : AppColors.amberGradient,
        shape: BoxShape.circle,
      ),
      child: _buildImage(context),
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

  Widget _buildImage(BuildContext context) {
    if (_hasBytes) {
      return Image.memory(
        imageBytes!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    }
    if (_hasLocalPath) {
      return Image.file(
        File(imagePath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    }
    if (_hasNetworkUrl) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    }
    return _fallback(context);
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
