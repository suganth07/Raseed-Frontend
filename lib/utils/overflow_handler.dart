import 'package:flutter/material.dart';

/// A widget that gracefully handles overflow by clipping content
class OverflowSafeWidget extends StatelessWidget {
  final Widget child;
  final Clip clipBehavior;

  const OverflowSafeWidget({
    Key? key,
    required this.child,
    this.clipBehavior = Clip.hardEdge,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}

/// A text widget that automatically handles overflow
class SafeText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow overflow;
  final TextAlign? textAlign;

  const SafeText(
    this.text, {
    Key? key,
    this.style,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.textAlign,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}

/// A flex widget that gracefully handles overflow
class SafeFlex extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final Axis direction;

  const SafeFlex({
    Key? key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.direction = Axis.horizontal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Flex(
      direction: direction,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children.map((child) {
        return Flexible(child: child);
      }).toList(),
    );
  }
}

/// A container that ensures content fits within screen bounds
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const ResponsiveContainer({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: padding,
          margin: margin,
          constraints: BoxConstraints(
            maxWidth: constraints.maxWidth,
            maxHeight: constraints.maxHeight,
          ),
          child: SingleChildScrollView(
            child: child,
          ),
        );
      },
    );
  }
}
