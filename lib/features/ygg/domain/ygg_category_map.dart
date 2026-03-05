/// Ygg torrent category map extracted from U2P Client source.
///
/// Maps category ID → {label, parentId}.
/// Parent categories have null parentId.
class YggCategory {
  const YggCategory(this.label, {this.parentId});

  final String label;
  final int? parentId;
}

const Map<int, YggCategory> yggCategoryMap = {
  // Parents
  2145: YggCategory('Film/Vidéo'),
  2139: YggCategory('Audio'),
  2144: YggCategory('Application'),
  2142: YggCategory('Jeu vidéo'),
  2140: YggCategory('eBook'),

  // Film/Vidéo
  2178: YggCategory('Animation', parentId: 2145),
  2179: YggCategory('Animation Série', parentId: 2145),
  2180: YggCategory('Concert', parentId: 2145),
  2181: YggCategory('Documentaire', parentId: 2145),
  2182: YggCategory('Émission TV', parentId: 2145),
  2183: YggCategory('Film', parentId: 2145),
  2184: YggCategory('Série TV', parentId: 2145),
  2185: YggCategory('Spectacle', parentId: 2145),
  2186: YggCategory('Sport', parentId: 2145),

  // Audio
  2147: YggCategory('Karaoké', parentId: 2139),
  2148: YggCategory('Musique', parentId: 2139),
  2150: YggCategory('Podcast Radio', parentId: 2139),

  // eBook
  2151: YggCategory('Audio', parentId: 2140),
  2152: YggCategory('BD', parentId: 2140),
  2153: YggCategory('Comics', parentId: 2140),
  2154: YggCategory('Livres', parentId: 2140),
  2155: YggCategory('Mangas', parentId: 2140),
  2156: YggCategory('Presse', parentId: 2140),
};

/// Resolve a category ID to a human-readable label.
/// Returns the subcategory label if found, otherwise the parent label,
/// or the raw ID as fallback.
String resolveCategoryLabel(String? categoryId) {
  if (categoryId == null || categoryId.isEmpty) return 'Inconnu';
  final id = int.tryParse(categoryId);
  if (id == null) return categoryId;
  final category = yggCategoryMap[id];
  return category?.label ?? 'Catégorie $categoryId';
}
