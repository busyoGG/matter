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
  Widget build(BuildContext context) =>
      ColoredBox(color: Theme.of(context).scaffoldBackgroundColor);
}
