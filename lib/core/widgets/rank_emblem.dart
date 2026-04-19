import 'package:flutter/cupertino.dart';

class RankEmblem extends StatelessWidget {
  final int rankIndex;
  final double size;

  const RankEmblem({
    super.key,
    required this.rankIndex,
    this.size = 32,
  });

  static const List<String> _assets = [
    'assets/images/ranks/void.png',
    'assets/images/ranks/bronze.png',
    'assets/images/ranks/silver.png',
    'assets/images/ranks/gold.png',
    'assets/images/ranks/platinum.png',
    'assets/images/ranks/diamond.png',
    'assets/images/ranks/master.png',
    'assets/images/ranks/voidmaster.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _assets[rankIndex],
      width: size,
      height: size,
    );
  }
}