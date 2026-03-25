import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_theme.dart';

class AvatarWidget extends StatelessWidget {
  final String? photoUrl;
  final double size;

  const AvatarWidget({super.key, this.photoUrl, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceLight,
      ),
      child: ClipOval(
        child: photoUrl != null
            ? CachedNetworkImage(
                imageUrl: photoUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: Text('✈️'),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Text('✈️'),
                ),
              )
            : const Center(
                child: Text('✈️', style: TextStyle(fontSize: 18)),
              ),
      ),
    );
  }
}
