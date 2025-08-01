import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {
  final double size;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final bool showShadow;

  const LogoWidget({
    super.key,
    this.size = 80,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.showShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBorderRadius = BorderRadius.circular(size * 0.25);
    
    Widget logoImage = ClipRRect(
      borderRadius: borderRadius ?? defaultBorderRadius,
      child: Image.asset(
        'assets/images/raseed_logo.jpg',
        width: size,
        height: size,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: borderRadius ?? defaultBorderRadius,
          ),
          child: Icon(
            Icons.receipt_long,
            size: size * 0.5,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );

    if (showShadow) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? defaultBorderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: logoImage,
      );
    }

    return logoImage;
  }
}

class AppLogoWidget extends StatelessWidget {
  const AppLogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const LogoWidget(
      size: 120,
      showShadow: true,
    );
  }
}

class AppBarLogoWidget extends StatelessWidget {
  const AppBarLogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const LogoWidget(
      size: 32,
      borderRadius: BorderRadius.all(Radius.circular(8)),
    );
  }
}
