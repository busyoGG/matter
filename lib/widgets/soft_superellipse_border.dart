import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A smooth superellipse border with a configurable exponent.
///
/// The exponent controls the corner profile. Values above 2 keep the shape a
/// superellipse instead of a plain rounded rectangle, with higher values
/// becoming gradually squarer. The default is a smooth 2.5 superellipse.
class SoftSuperellipseBorder extends OutlinedBorder {
  static const defaultExponent = 2.5;

  final BorderRadiusGeometry borderRadius;
  final double exponent;

  const SoftSuperellipseBorder({
    super.side,
    this.borderRadius = BorderRadius.zero,
    this.exponent = defaultExponent,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  ShapeBorder scale(double t) => SoftSuperellipseBorder(
    side: side.scale(t),
    borderRadius: borderRadius * t,
    exponent: exponent,
  );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is SoftSuperellipseBorder) {
      return SoftSuperellipseBorder(
        side: BorderSide.lerp(a.side, side, t),
        borderRadius: BorderRadiusGeometry.lerp(
          a.borderRadius,
          borderRadius,
          t,
        )!,
        exponent: ui.lerpDouble(a.exponent, exponent, t)!,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is SoftSuperellipseBorder) {
      return SoftSuperellipseBorder(
        side: BorderSide.lerp(side, b.side, t),
        borderRadius: BorderRadiusGeometry.lerp(
          borderRadius,
          b.borderRadius,
          t,
        )!,
        exponent: ui.lerpDouble(exponent, b.exponent, t)!,
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  SoftSuperellipseBorder copyWith({
    BorderSide? side,
    BorderRadiusGeometry? borderRadius,
    double? exponent,
  }) {
    return SoftSuperellipseBorder(
      side: side ?? this.side,
      borderRadius: borderRadius ?? this.borderRadius,
      exponent: exponent ?? this.exponent,
    );
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return _buildPath(rect, borderRadius.resolve(textDirection).topLeft.x);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    final inset = rect.deflate(side.width);
    return _buildPath(
      inset,
      math.max(0, borderRadius.resolve(textDirection).topLeft.x - side.width),
    );
  }

  Path _buildPath(Rect rect, double requestedRadius) {
    if (rect.isEmpty) return Path();
    final radius = math.min(requestedRadius, rect.shortestSide / 2);
    final power = 2 / math.max(1.01, exponent);
    const steps = 32;
    final path = Path()..moveTo(rect.left + radius, rect.top);

    void corner(Offset center, double start, double end) {
      for (var index = 1; index <= steps; index++) {
        final angle = start + (end - start) * index / steps;
        final cosine = math.cos(angle);
        final sine = math.sin(angle);
        final x =
            center.dx + radius * math.pow(cosine.abs(), power) * cosine.sign;
        final y = center.dy + radius * math.pow(sine.abs(), power) * sine.sign;
        path.lineTo(x, y);
      }
    }

    path.lineTo(rect.right - radius, rect.top);
    corner(Offset(rect.right - radius, rect.top + radius), -math.pi / 2, 0);
    path.lineTo(rect.right, rect.bottom - radius);
    corner(Offset(rect.right - radius, rect.bottom - radius), 0, math.pi / 2);
    path.lineTo(rect.left + radius, rect.bottom);
    corner(
      Offset(rect.left + radius, rect.bottom - radius),
      math.pi / 2,
      math.pi,
    );
    path.lineTo(rect.left, rect.top + radius);
    corner(
      Offset(rect.left + radius, rect.top + radius),
      math.pi,
      math.pi * 1.5,
    );
    return path..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || rect.isEmpty) return;
    canvas.drawPath(
      getOuterPath(rect, textDirection: textDirection),
      side.toPaint(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SoftSuperellipseBorder &&
        other.side == side &&
        other.borderRadius == borderRadius &&
        other.exponent == exponent;
  }

  @override
  int get hashCode => Object.hash(side, borderRadius, exponent);
}
