// lib/utils/text_constants.dart
import 'package:flutter/material.dart';
import 'responsive_utils.dart';

class TextConstants {
  // Base text sizes (for mobile)
  static const double kAppBarTitleSize = 20.0;
  static const double kTabLabelSize = 14.0;
  static const double kSearchBarTextSize = 16.0;
  static const double kCardTitleSize = 16.0;
  static const double kCardSubtitleSize = 14.0;
  static const double kCardDetailsSize = 12.0;
  static const double kButtonTextSize = 14.0;
  
  // Extended sizes for responsive design
  static const double kAppBarTitleSizeTablet = 22.0;
  static const double kAppBarTitleSizeDesktop = 24.0;
  
  static const double kTabLabelSizeTablet = 15.0;
  static const double kTabLabelSizeDesktop = 16.0;
  
  static const double kSearchBarTextSizeTablet = 17.0;
  static const double kSearchBarTextSizeDesktop = 18.0;
  
  static const double kCardTitleSizeTablet = 18.0;
  static const double kCardTitleSizeDesktop = 20.0;
  
  static const double kCardSubtitleSizeTablet = 15.0;
  static const double kCardSubtitleSizeDesktop = 16.0;
  
  static const double kCardDetailsSizeTablet = 13.0;
  static const double kCardDetailsSizeDesktop = 14.0;
  
  static const double kButtonTextSizeTablet = 15.0;
  static const double kButtonTextSizeDesktop = 16.0;
  
  // Helper methods to get responsive text sizes
  static double getAppBarTitleSize(BuildContext context) {
    return ResponsiveUtils.valueForLayoutType(
      context: context,
      mobile: kAppBarTitleSize,
      tablet: kAppBarTitleSizeTablet,
      desktop: kAppBarTitleSizeDesktop,
    );
  }
  
  static double getTabLabelSize(BuildContext context) {
    return ResponsiveUtils.valueForLayoutType(
      context: context,
      mobile: kTabLabelSize,
      tablet: kTabLabelSizeTablet,
      desktop: kTabLabelSizeDesktop,
    );
  }
  
  static double getSearchBarTextSize(BuildContext context) {
    return ResponsiveUtils.valueForLayoutType(
      context: context,
      mobile: kSearchBarTextSize,
      tablet: kSearchBarTextSizeTablet,
      desktop: kSearchBarTextSizeDesktop,
    );
  }
  
  static double getCardTitleSize(BuildContext context) {
    return ResponsiveUtils.valueForLayoutType(
      context: context,
      mobile: kCardTitleSize,
      tablet: kCardTitleSizeTablet,
      desktop: kCardTitleSizeDesktop,
    );
  }
  
  static double getCardSubtitleSize(BuildContext context) {
    return ResponsiveUtils.valueForLayoutType(
      context: context,
      mobile: kCardSubtitleSize,
      tablet: kCardSubtitleSizeTablet,
      desktop: kCardSubtitleSizeDesktop,
    );
  }
  
  static double getCardDetailsSize(BuildContext context) {
    return ResponsiveUtils.valueForLayoutType(
      context: context,
      mobile: kCardDetailsSize,
      tablet: kCardDetailsSizeTablet,
      desktop: kCardDetailsSizeDesktop,
    );
  }
  
  static double getButtonTextSize(BuildContext context) {
    return ResponsiveUtils.valueForLayoutType(
      context: context,
      mobile: kButtonTextSize,
      tablet: kButtonTextSizeTablet,
      desktop: kButtonTextSizeDesktop,
    );
  }
}