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
  Widget build(BuildContext context) =>
      ColoredBox(color: Theme.of(context).scaffoldBackgroundColor);
}
