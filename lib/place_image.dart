import 'package:flutter/material.dart';

/// Renders an asset image when [assetPath] is provided. Falls back to
/// [fallback] (the existing painter-based art) so older catalog entries keep
/// working even if their photo cannot be located.
class PlaceImage extends StatelessWidget {
  const PlaceImage({
    required this.assetPath,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    super.key,
  });

  final String? assetPath;
  final Widget fallback;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final path = assetPath;
    if (path == null || path.isEmpty) {
      return fallback;
    }
    return Image.asset(
      path,
      fit: fit,
      alignment: alignment,
      errorBuilder: (context, error, stack) => fallback,
      gaplessPlayback: true,
    );
  }
}
