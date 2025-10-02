class PhotoModel {
  final int id, width, height, photographerId;
  final String url, photographer, photographerUrl, avgColor, alt;
  final PexelsPhotoSrc src;
  const PhotoModel({
    required this.id,
    required this.width,
    required this.height,
    required this.url,
    required this.photographer,
    required this.photographerUrl,
    required this.photographerId,
    required this.avgColor,
    required this.src,
    required this.alt,
  });
  factory PhotoModel.fromJson(Map<String, dynamic> j) => PhotoModel(
    id: j['id'] ?? 0,
    width: j['width'] ?? 0,
    height: j['height'] ?? 0,
    url: (j['url'] ?? '').toString().trim(),
    photographer: j['photographer'] ?? '',
    photographerUrl: (j['photographer_url'] ?? '').toString().trim(),
    photographerId: j['photographer_id'] ?? 0,
    avgColor: j['avg_color'] ?? '#CCCCCC',
    src: PexelsPhotoSrc.fromJson(j['src'] ?? const {}),
    alt: j['alt'] ?? '',
  );
}

class PexelsSearchResponse {
  final List<PhotoModel> photos;
  final int page, perPage;
  final int? totalResults;
  final String? nextPage, prevPage;
  const PexelsSearchResponse({
    required this.photos,
    required this.page,
    required this.perPage,
    this.totalResults,
    this.nextPage,
    this.prevPage,
  });
  factory PexelsSearchResponse.fromJson(Map<String, dynamic> j) =>
      PexelsSearchResponse(
        photos: (j['photos'] as List? ?? [])
            .map((e) => PhotoModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        page: j['page'] ?? 1,
        perPage: j['per_page'] ?? 15,
        totalResults: j['total_results'],
        nextPage: j['next_page'],
        prevPage: j['prev_page'],
      );
}

class PexelsPhotoSrc {
  final String original,
      large2x,
      large,
      medium,
      small,
      portrait,
      landscape,
      tiny;
  const PexelsPhotoSrc({
    required this.original,
    required this.large2x,
    required this.large,
    required this.medium,
    required this.small,
    required this.portrait,
    required this.landscape,
    required this.tiny,
  });
  factory PexelsPhotoSrc.fromJson(Map<String, dynamic> j) => PexelsPhotoSrc(
    original: j['original'] ?? '',
    large2x: j['large2x'] ?? '',
    large: j['large'] ?? '',
    medium: j['medium'] ?? '',
    small: j['small'] ?? '',
    portrait: j['portrait'] ?? '',
    landscape: j['landscape'] ?? '',
    tiny: j['tiny'] ?? '',
  );
}
