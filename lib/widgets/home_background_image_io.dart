import 'dart:io';

import 'package:flutter/material.dart';

class HomeBackgroundImage extends StatelessWidget {
  final String path;
  final double opacity;
  final Color? fallbackColor;

  const HomeBackgroundImage({
    super.key,
    required this.path,
    this.opacity = 1.0,
    this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) => Image.file(
    File(path),
    fit: BoxFit.cover,
    opacity: AlwaysStoppedAnimation(opacity),
    errorBuilder: (context, error, stackTrace) => ColoredBox(
      color: fallbackColor ?? Theme.of(context).scaffoldBackgroundColor,
    ),
  );
}
