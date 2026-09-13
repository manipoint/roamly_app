final class MediaAsset {
  const MediaAsset({
    required this.id,
    required this.uri,
    required this.altText,
    required this.caption,
    required this.width,
    required this.height,
  });

  final String id;
  final Uri uri;
  final String altText;
  final String? caption;
  final int? width;
  final int? height;

  double? get aspectRatio {
    final imageWidth = width;
    final imageHeight = height;
    if (imageWidth == null || imageHeight == null) return null;
    return imageWidth / imageHeight;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaAsset &&
          id == other.id &&
          uri == other.uri &&
          altText == other.altText &&
          caption == other.caption &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => Object.hash(id, uri, altText, caption, width, height);
}
