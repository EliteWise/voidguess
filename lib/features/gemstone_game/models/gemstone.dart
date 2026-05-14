class Gemstone {
  final int id;
  final String nameFr;
  final String nameEn;
  final String assetPath;

  const Gemstone({
    required this.id,
    required this.nameFr,
    required this.nameEn,
    required this.assetPath,
  });

  String getName(String locale) => locale == 'fr' ? nameFr : nameEn;
}

const List<Gemstone> gemstones = [
  Gemstone(
    id: 1,
    nameFr: 'Améthyste',
    nameEn: 'Amethyst',
    assetPath: 'assets/gemstones/amethyst.png',
  ),
  Gemstone(
    id: 2,
    nameFr: 'Aigue-marine',
    nameEn: 'Aquamarine',
    assetPath: 'assets/gemstones/aquamarine.png',
  ),
  Gemstone(
    id: 3,
    nameFr: 'Diamant',
    nameEn: 'Diamond',
    assetPath: 'assets/gemstones/diamond.png',
  ),
  Gemstone(
    id: 4,
    nameFr: 'Émeraude',
    nameEn: 'Emerald',
    assetPath: 'assets/gemstones/emerald.png',
  ),
  Gemstone(
    id: 5,
    nameFr: 'Grenat',
    nameEn: 'Garnet',
    assetPath: 'assets/gemstones/garnet.png',
  ),
  Gemstone(
    id: 6,
    nameFr: 'Jade',
    nameEn: 'Jade',
    assetPath: 'assets/gemstones/jade.png',
  ),
  Gemstone(
    id: 7,
    nameFr: 'Opale',
    nameEn: 'Opal',
    assetPath: 'assets/gemstones/opal.png',
  ),
  Gemstone(
    id: 8,
    nameFr: 'Rubis',
    nameEn: 'Ruby',
    assetPath: 'assets/gemstones/ruby.png',
  ),
  Gemstone(
    id: 9,
    nameFr: 'Saphir',
    nameEn: 'Sapphire',
    assetPath: 'assets/gemstones/sapphire.png',
  ),
  Gemstone(
    id: 10,
    nameFr: 'Topaze',
    nameEn: 'Topaz',
    assetPath: 'assets/gemstones/topaz.png',
  ),
  Gemstone(
    id: 11,
    nameFr: 'Turquoise',
    nameEn: 'Turquoise',
    assetPath: 'assets/gemstones/turquoise.png',
  ),
];
