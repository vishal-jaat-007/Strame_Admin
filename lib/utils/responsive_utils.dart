import 'package:flutter/material.dart';

class AppResponsiveUtils {
  // Breakpoints
  static const double mobileBreakpoint = 768;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  // Screen size checks
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  // Responsive values
  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    if (isLargeDesktop(context) && largeDesktop != null) {
      return largeDesktop;
    }
    if (isDesktop(context) && desktop != null) {
      return desktop;
    }
    if (isTablet(context) && tablet != null) {
      return tablet;
    }
    return mobile;
  }

  // Responsive padding
  static EdgeInsets responsivePadding(BuildContext context) {
    return EdgeInsets.all(
      responsive(context, mobile: 16.0, tablet: 20.0, desktop: 24.0),
    );
  }

  // Responsive spacing
  static double responsiveSpacing(BuildContext context) {
    return responsive(context, mobile: 12.0, tablet: 16.0, desktop: 20.0);
  }

  // Responsive font sizes
  static double responsiveFontSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return responsive(
      context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.1,
      desktop: desktop ?? mobile * 1.2,
    );
  }

  // Grid columns - based on screen width for better control
  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < mobileBreakpoint) {
      return 1; // Mobile - single column
    } else if (width < 800) {
      return 2; // Extra small tablet - 2 columns
    } else if (width < 1100) {
      return 2; // Small tablet - 2 columns
    } else if (width < 1400) {
      return 3; // Large tablet/Small desktop - 3 columns
    } else {
      return 4; // Large Desktop - 4 columns
    }
  }

  // Card aspect ratio
  static double getCardAspectRatio(BuildContext context) {
    return responsive(
      context,
      mobile: 1.8,
      tablet: 1.35, // Taller cards for tablet
      desktop: 1.15, // Taller cards for desktop
      largeDesktop: 1.25,
    );
  }
}
