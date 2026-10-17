import 'dart:ui';
import 'package:splitzo/ads/src/multi_ads_factory.dart';


class Constants {
  // https://drive.google.com/file/d/1gWamF1pYxBEZ2Ilj1GcJg0-qgRExIy1_/view?usp=drive_link
  static const jsonConfigUrl =
      'https://drive.google.com/uc?export=download&id=1gWamF1pYxBEZ2Ilj1GcJg0-qgRExIy1_';

  static Color mainColor = const Color(0xff33FD24);
}

// Variable globale des publicités (initialisée après téléchargement depuis Drive)
MultiAds? gAds;
bool isInterShowed = false;