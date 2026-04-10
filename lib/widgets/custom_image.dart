import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

class CustomNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? height;
  final double? width;
  final BoxFit fit;
  final double borderRadius;

  const CustomNetworkImage({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: AppTheme.washedOutGreen,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: const Icon(Icons.broken_image, color: AppTheme.primaryGreen),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        height: height,
        width: width,
        fit: fit,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: Colors.grey.shade200,
          highlightColor: Colors.white,
          child: Container(
            height: height ?? double.infinity,
            width: width ?? double.infinity,
            color: Colors.white,
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: AppTheme.washedOutGreen,
          child: const Icon(Icons.broken_image, color: AppTheme.primaryGreen),
        ),
      ),
    );
  }
}

class CustomAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final IconData placeholderIcon;
  final bool isOnline;

  const CustomAvatar({
    super.key,
    this.imageUrl,
    this.radius = 24,
    this.placeholderIcon = Icons.person,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF57AB74), Color(0xFF8BC4A2)],
            ),
          ),
          child: CircleAvatar(
            radius: radius,
            backgroundColor: Colors.white,
            child: ClipOval(
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      width: radius * 2,
                      height: radius * 2,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey.shade200,
                        highlightColor: Colors.white,
                        child: Container(
                          width: radius * 2,
                          height: radius * 2,
                          color: Colors.white,
                        ),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        placeholderIcon,
                        size: radius,
                        color: AppTheme.primaryGreen,
                      ),
                    )
                  : Icon(
                      placeholderIcon,
                      size: radius,
                      color: AppTheme.primaryGreen,
                    ),
            ),
          ),
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.6,
              height: radius * 0.6,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
