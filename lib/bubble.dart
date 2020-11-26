library bubble;

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

enum BubbleNip {
  no,
  leftTop,
  leftBottom,
  rightTop,
  rightBottom,
  leftCenter,
  topRight,
  topLeft,
}

/// Class BubbleEdges is an analog of EdgeInsets, but default values are null.
class BubbleEdges {
  const BubbleEdges.fromLTRB(this.left, this.top, this.right, this.bottom);

  const BubbleEdges.all(double value)
      : left = value,
        top = value,
        right = value,
        bottom = value;

  const BubbleEdges.only({
    this.left, // = null
    this.top, // = null
    this.right, // = null
    this.bottom, // = null
  });

  const BubbleEdges.symmetric({
    double vertical, // = null
    double horizontal, // = null
  })  : left = horizontal,
        top = vertical,
        right = horizontal,
        bottom = vertical;

  final double left;
  final double top;
  final double right;
  final double bottom;

  static get zero => BubbleEdges.all(0);

  EdgeInsets get edgeInsets =>
      EdgeInsets.fromLTRB(left ?? 0, top ?? 0, right ?? 0, bottom ?? 0);

  @override
  String toString() => 'BubbleEdges($left, $top, $right, $bottom)';
}

class BubbleStyle {
  const BubbleStyle({
    this.radius,
    this.nip,
    this.nipWidth,
    this.nipHeight,
    this.nipOffset,
    this.nipRadius,
    this.stick,
    this.color,
    this.elevation,
    this.shadowColor,
    this.padding,
    this.margin,
    this.alignment,
    this.borderColor,
    this.borderWidth,
  });

  final Radius radius;
  final BubbleNip nip;
  final double nipHeight;
  final double nipWidth;
  final double nipOffset;
  final double nipRadius;
  final bool stick;
  final Color color;
  final double elevation;
  final Color shadowColor;
  final BubbleEdges padding;
  final BubbleEdges margin;
  final Alignment alignment;
  final Color borderColor;
  final double borderWidth;
}

class BubbleClipper extends CustomClipper<Path> {
  BubbleClipper({
    this.radius,
    this.nip,
    this.nipWidth,
    this.nipHeight,
    this.nipOffset,
    this.nipRadius,
    this.stick,
    this.padding,
  })  : assert(nipWidth > 0.0),
        assert(nipHeight > 0.0),
        assert(nipRadius >= 0.0),
        assert(nipRadius <= nipWidth / 2.0 && nipRadius <= nipHeight / 2.0),
        assert(nipOffset >= 0.0),
//        assert(radius <= nipHeight + nipOffset),
        assert(padding != null),
        assert(padding.left != null),
        assert(padding.top != null),
        assert(padding.right != null),
        assert(padding.bottom != null),
        super() {
    _startOffset = _endOffset = nipWidth;

    var k = nipHeight / nipWidth;
    var a = atan(k);

    _nipCX = (nipRadius + sqrt(nipRadius * nipRadius * (1 + k * k))) / k;
    var nipStickOffset = (_nipCX - nipRadius).floorToDouble();

    _nipCX -= nipStickOffset;
    _nipCY = nipRadius;
    _nipPX = _nipCX - nipRadius * sin(a);
    _nipPY = _nipCY + nipRadius * cos(a);
    _startOffset -= nipStickOffset;
    _endOffset -= nipStickOffset;

    if (stick) _endOffset = 0.0;
  }

  final Radius radius;
  final BubbleNip nip;
  final double nipHeight;
  final double nipWidth;
  final double nipOffset;
  final double nipRadius;
  final bool stick;
  final BubbleEdges padding;

  double _startOffset; // Offsets of the bubble
  double _endOffset;
  double _nipCX; // The center of the circle
  double _nipCY;
  double _nipPX; // The point of contact of the nip with the circle
  double _nipPY;

  get edgeInsets {
    if (nip == BubbleNip.topRight || nip == BubbleNip.topLeft) {
      return EdgeInsets.only(
        left: padding.left,
        top: padding.top + _startOffset,
        right: padding.right,
        bottom: padding.bottom + _endOffset,
      );
    }
    return nip == BubbleNip.leftTop ||
            nip == BubbleNip.leftBottom ||
            nip == BubbleNip.leftCenter
        ? EdgeInsets.only(
            left: _startOffset + padding.left,
            top: padding.top,
            right: _endOffset + padding.right,
            bottom: padding.bottom)
        : nip == BubbleNip.rightTop || nip == BubbleNip.rightBottom
            ? EdgeInsets.only(
                left: _endOffset + padding.left,
                top: padding.top,
                right: _startOffset + padding.right,
                bottom: padding.bottom)
            : EdgeInsets.only(
                left: _endOffset + padding.left,
                top: padding.top,
                right: _endOffset + padding.right,
                bottom: padding.bottom);
  }

  @override
  Path getClip(Size size) {
    var radiusX = radius.x;
    var radiusY = radius.y;
    var maxRadiusX = size.width / 2;
    var maxRadiusY = size.height / 2;

    if (radiusX > maxRadiusX) {
      radiusY *= maxRadiusX / radiusX;
      radiusX = maxRadiusX;
    }
    if (radiusY > maxRadiusY) {
      radiusX *= maxRadiusY / radiusY;
      radiusY = maxRadiusY;
    }

    switch (nip) {
      case BubbleNip.leftTop:
        Path path1 = Path();
        path1.addRRect(RRect.fromLTRBR(
            _startOffset, 0, size.width - _endOffset, size.height, radius));

        Path path2 = Path();

        path2.moveTo(_startOffset + radiusX, nipOffset);

        path2.lineTo(_startOffset + radiusX, nipOffset + nipHeight);
        path2.lineTo(_startOffset, nipOffset + nipHeight);
        if (nipRadius == 0) {
          path2.lineTo(0, nipOffset);
        } else {
          path2.lineTo(_nipPX, nipOffset + _nipPY);
          path2.arcToPoint(Offset(_nipCX, nipOffset),
              radius: Radius.circular(nipRadius));
        }
        path2.close();
        return Path.combine(PathOperation.union, path1, path2);

      case BubbleNip.leftCenter:
        Path path1 = Path();
        path1.addRRect(RRect.fromLTRBR(
            _startOffset, 0, size.width - _endOffset, size.height, radius));

        Path path2 = new Path();

        path2.moveTo(_startOffset + radiusX, size.height / 2 - nipHeight);
        path2.lineTo(_startOffset + radiusX, size.height / 2 + nipHeight);
        path2.lineTo(_startOffset, size.height / 2 + nipHeight);
        if (nipRadius == 0) {
          path2.lineTo(0, size.height / 2 + nipHeight);
        } else {
          path2.lineTo(_nipPX, size.height / 2 + _nipPY);
          path2.arcToPoint(Offset(_nipCX, nipOffset + size.height / 2),
              radius: Radius.circular(nipRadius));
        }
        path2.close();
        return Path.combine(PathOperation.union, path1, path2);

      case BubbleNip.leftBottom:
        Path path1 = Path();
        path1.addRRect(RRect.fromLTRBR(
            _startOffset, 0, size.width - _endOffset, size.height, radius));

        Path path2 = Path();
        path2.moveTo(_startOffset + radiusX, size.height - nipOffset);
        path2.lineTo(
            _startOffset + radiusX, size.height - nipOffset - nipHeight);
        path2.lineTo(_startOffset, size.height - nipOffset - nipHeight);
        if (nipRadius == 0) {
          path2.lineTo(0, size.height - nipOffset);
        } else {
          path2.lineTo(_nipPX, size.height - nipOffset - _nipPY);
          path2.arcToPoint(Offset(_nipCX, size.height - nipOffset),
              radius: Radius.circular(nipRadius), clockwise: false);
        }
        path2.close();
        return Path.combine(PathOperation.union, path1, path2);

      case BubbleNip.rightTop:
        Path path1 = Path();
        path1.addRRect(RRect.fromLTRBR(
            _endOffset, 0, size.width - _startOffset, size.height, radius));

        Path path2 = Path();
        path2.moveTo(size.width - _startOffset - radiusX, nipOffset);
        path2.lineTo(
            size.width - _startOffset - radiusX, nipOffset + nipHeight);
        path2.lineTo(size.width - _startOffset, nipOffset + nipHeight);
        if (nipRadius == 0) {
          path2.lineTo(size.width, nipOffset);
        } else {
          path2.lineTo(size.width - _nipPX, nipOffset + _nipPY);
          path2.arcToPoint(Offset(size.width - _nipCX, nipOffset),
              radius: Radius.circular(nipRadius), clockwise: false);
        }
        path2.close();
        return Path.combine(PathOperation.union, path1, path2);

      case BubbleNip.topRight:
        Path path1 = Path();
        path1.addRRect(RRect.fromLTRBR(
            0, _startOffset, size.width, size.height - _endOffset, radius));

        Path path2 = Path();
        path2.moveTo(size.width - nipOffset, _startOffset + radiusX);
        path2.lineTo(
            size.width - nipOffset - nipHeight, _startOffset + radiusX);
        path2.lineTo(size.width - nipOffset - nipHeight, _startOffset);
        if (nipRadius == 0) {
          path2.lineTo(size.width - nipOffset, 0);
        } else {
          path2.lineTo(size.width - nipOffset - _nipPY, _nipPX);
          path2.arcToPoint(Offset(size.width - nipOffset, _nipCX),
              radius: Radius.circular(nipRadius));
        }
        path2.close();
        return Path.combine(PathOperation.union, path1, path2);

      case BubbleNip.topLeft:
        Path path1 = Path();
        path1.addRRect(RRect.fromLTRBR(
            0, _startOffset, size.width, size.height - _endOffset, radius));

        Path path2 = Path();
        path2.moveTo(nipOffset, _startOffset + radiusX);
        path2.lineTo(nipOffset + nipHeight, _startOffset + radiusX);
        path2.lineTo(nipOffset + nipHeight, _startOffset);
        if (nipRadius == 0) {
          path2.lineTo(nipOffset, 0);
        } else {
          path2.lineTo(nipOffset + _nipPY, _nipPX);
          path2.arcToPoint(
            Offset(nipOffset, _nipCX),
            radius: Radius.circular(nipRadius),
            clockwise: false,
          );
        }
        path2.close();
        return Path.combine(PathOperation.union, path1, path2);

      case BubbleNip.rightBottom:
        Path path1 = Path();
        path1.addRRect(RRect.fromLTRBR(
            _endOffset, 0, size.width - _startOffset, size.height, radius));

        Path path2 = Path();
        path2.moveTo(
            size.width - _startOffset - radiusX, size.height - nipOffset);
        path2.lineTo(size.width - _startOffset - radiusX,
            size.height - nipOffset - nipHeight);
        path2.lineTo(
            size.width - _startOffset, size.height - nipOffset - nipHeight);
        if (nipRadius == 0) {
          path2.lineTo(size.width, size.height - nipOffset);
        } else {
          path2.lineTo(size.width - _nipPX, size.height - nipOffset - _nipPY);
          path2.arcToPoint(Offset(size.width - _nipCX, size.height - nipOffset),
              radius: Radius.circular(nipRadius));
        }
        path2.close();
        return Path.combine(PathOperation.union, path1, path2);

      case BubbleNip.no:
        Path path = Path();
        path.addRRect(RRect.fromLTRBR(
            _endOffset, 0, size.width - _endOffset, size.height, radius));
        return path;
      default:
        return Path();
    }
  }

  @override
  bool shouldReclip(BubbleClipper oldClipper) => false;
}

class Bubble extends StatelessWidget {
  Bubble({
    this.child,
    Radius radius,
    BubbleNip nip,
    double nipWidth,
    double nipHeight,
    double nipOffset,
    double nipRadius,
    bool stick,
    Color color,
    double elevation,
    Color shadowColor,
    BubbleEdges padding,
    BubbleEdges margin,
    Alignment alignment,
    BubbleStyle style,
    final Color borderColor,
    final double borderWidth,
  })  : color = color ?? style?.color ?? Colors.white,
        elevation = elevation ?? style?.elevation ?? 1.0,
        shadowColor = shadowColor ?? style?.shadowColor ?? Colors.black,
        borderColor = borderColor ?? style?.borderColor ?? Colors.black,
        borderWidth = borderWidth ?? style?.borderWidth ?? 0.0,
        margin = BubbleEdges.only(
          left: margin?.left ?? style?.margin?.left ?? 0.0,
          top: margin?.top ?? style?.margin?.top ?? 0.0,
          right: margin?.right ?? style?.margin?.right ?? 0.0,
          bottom: margin?.bottom ?? style?.margin?.bottom ?? 0.0,
        ),
        alignment = alignment ?? style?.alignment ?? null,
        bubbleClipper = BubbleClipper(
          radius: radius ?? style?.radius ?? Radius.circular(6.0),
          nip: nip ?? style?.nip ?? BubbleNip.no,
          nipWidth: nipWidth ?? style?.nipWidth ?? 8.0,
          nipHeight: nipHeight ?? style?.nipHeight ?? 10.0,
          nipOffset: nipOffset ?? style?.nipOffset ?? 0.0,
          nipRadius: nipRadius ?? style?.nipRadius ?? 1.0,
          stick: stick ?? style?.stick ?? false,
          padding: BubbleEdges.only(
            left: padding?.left ?? style?.padding?.left ?? 8.0,
            top: padding?.top ?? style?.padding?.top ?? 6.0,
            right: padding?.right ?? style?.padding?.right ?? 8.0,
            bottom: padding?.bottom ?? style?.padding?.bottom ?? 6.0,
          ),
        );

  final Widget child;
  final Color color;
  final double elevation;
  final Color shadowColor;
  final BubbleEdges margin;
  final Alignment alignment;
  final BubbleClipper bubbleClipper;
  final Color borderColor;
  final double borderWidth;

  Widget build(context) {
    return Container(
      alignment: alignment,
      margin: margin?.edgeInsets,
      child: CustomPaint(
        painter: BubblePainter(
          clipper: bubbleClipper,
          color: color,
          elevation: elevation,
          shadowColor: shadowColor,
          borderColor: borderColor,
          borderWidth: borderWidth,
        ),
        child: Container(padding: bubbleClipper.edgeInsets, child: child),
      ),
    );
  }
}

class BubblePainter extends CustomPainter {
  final CustomClipper<Path> clipper;
  final Color color;
  final double elevation;
  final Color shadowColor;
  final Color borderColor;
  final double borderWidth;

  BubblePainter({
    this.clipper,
    this.color,
    this.elevation,
    this.shadowColor,
    this.borderColor,
    this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    if (elevation != 0.0) {
      canvas.drawShadow(clipper.getClip(size), shadowColor, elevation, false);
    }

    canvas.drawPath(clipper.getClip(Size(size.width, size.height)), paint);

    if (borderWidth > 0.0) {
      canvas.drawPath(
          clipper.getClip(size),
          Paint()
            ..color = borderColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = borderWidth);
    }
  }

  @override
  bool shouldRepaint(CustomPainter old) {
    return false;
  }
}
