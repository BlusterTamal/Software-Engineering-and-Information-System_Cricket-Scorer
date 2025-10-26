// lib\utils\responsive_helper.dart

import 'package:flutter/material.dart';

class ResponsiveHelper {

  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static EdgeInsets getResponsivePadding(BuildContext context) {
    final width = screenWidth(context);
    if (width < 360) {
      return const EdgeInsets.all(8);
    } else if (width < 400) {
      return const EdgeInsets.all(12);
    } else {
      return const EdgeInsets.all(16);
    }
  }

  static EdgeInsets getResponsiveHorizontalPadding(BuildContext context) {
    final width = screenWidth(context);
    if (width < 360) {
      return const EdgeInsets.symmetric(horizontal: 8);
    } else if (width < 400) {
      return const EdgeInsets.symmetric(horizontal: 12);
    } else {
      return const EdgeInsets.symmetric(horizontal: 16);
    }
  }

  static double getResponsiveFontSize(BuildContext context, {
    required double small,
    required double medium,
    required double large,
  }) {
    final width = screenWidth(context);
    if (width < 360) {
      return small;
    } else if (width < 400) {
      return medium;
    } else {
      return large;
    }
  }

  static double getResponsiveIconSize(BuildContext context) {
    final width = screenWidth(context);
    if (width < 360) {
      return 16;
    } else if (width < 400) {
      return 20;
    } else {
      return 24;
    }
  }

  static EdgeInsets getResponsiveCardPadding(BuildContext context) {
    final width = screenWidth(context);
    if (width < 360) {
      return const EdgeInsets.all(8);
    } else if (width < 400) {
      return const EdgeInsets.all(12);
    } else {
      return const EdgeInsets.all(16);
    }
  }

  static bool isVerySmallScreen(BuildContext context) {
    return screenWidth(context) < 360;
  }

  static bool isSmallScreen(BuildContext context) {
    return screenWidth(context) < 400;
  }

  static bool isMediumScreen(BuildContext context) {
    return screenWidth(context) >= 400 && screenWidth(context) < 600;
  }

  static bool isLargeScreen(BuildContext context) {
    return screenWidth(context) >= 600;
  }

  static int getResponsiveGridCrossAxisCount(BuildContext context, {
    int small = 2,
    int medium = 3,
    int large = 4,
  }) {
    final width = screenWidth(context);
    if (width < 360) {
      return small;
    } else if (width < 600) {
      return medium;
    } else {
      return large;
    }
  }

  static EdgeInsets getResponsiveSheetPadding(BuildContext context) {
    final width = screenWidth(context);
    final height = screenHeight(context);

    double horizontal = width < 360 ? 8 : width < 400 ? 12 : 16;
    double vertical = height < 700 ? 8 : 12;

    return EdgeInsets.symmetric(
      horizontal: horizontal,
      vertical: vertical,
    );
  }

  static double getResponsiveDialogWidth(BuildContext context) {
    final width = screenWidth(context);
    if (width < 360) {
      return width * 0.95;
    } else if (width < 400) {
      return width * 0.9;
    } else {
      return width * 0.85;
    }
  }

  static double getResponsiveButtonHeight(BuildContext context) {
    final width = screenWidth(context);
    if (width < 360) {
      return 40;
    } else if (width < 400) {
      return 44;
    } else {
      return 48;
    }
  }

  static double getResponsiveTextScale(BuildContext context) {
    final width = screenWidth(context);
    if (width < 360) {
      return 0.85;
    } else if (width < 400) {
      return 0.9;
    } else {
      return 1.0;
    }
  }

  static double getResponsiveBorderRadius(BuildContext context) {
    final width = screenWidth(context);
    if (width < 360) {
      return 8;
    } else if (width < 400) {
      return 12;
    } else {
      return 16;
    }
  }

  static double getResponsiveSpacing(BuildContext context, {
    double small = 8,
    double medium = 12,
    double large = 16,
  }) {
    final width = screenWidth(context);
    if (width < 360) {
      return small;
    } else if (width < 400) {
      return medium;
    } else {
      return large;
    }
  }
}

extension ResponsiveExtension on BuildContext {
  double get screenWidth => ResponsiveHelper.screenWidth(this);
  double get screenHeight => ResponsiveHelper.screenHeight(this);
  bool get isVerySmallScreen => ResponsiveHelper.isVerySmallScreen(this);
  bool get isSmallScreen => ResponsiveHelper.isSmallScreen(this);
  bool get isMediumScreen => ResponsiveHelper.isMediumScreen(this);
  bool get isLargeScreen => ResponsiveHelper.isLargeScreen(this);

  EdgeInsets get rp => ResponsiveHelper.getResponsivePadding(this);
  EdgeInsets get rhp => ResponsiveHelper.getResponsiveHorizontalPadding(this);
}
