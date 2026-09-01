import 'dart:io';

import 'package:flutter/material.dart';

class HomeBackgroundImage extends StatelessWidget {
  final String path;
  final double opacity;

  const HomeBackgroundImage({
    super.key,
    required this.path,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) => Image.file(
    File(path),
    fit: BoxFit.cover,
    opacity: AlwaysStoppedAnimation(opacity),
    errorBuilder: (context, error, stackTrace) =>
        ColoredBox(color: Theme.of(context).scaffoldBackgroundColor),
  );
}
