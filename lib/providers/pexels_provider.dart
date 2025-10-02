// lib/providers/pexels_provider.dart
import 'package:flutter/foundation.dart';
import 'package:snapalyze/models/photo_model.dart';
import 'package:snapalyze/services/pexels_service.dart';

class PexelsProvider extends ChangeNotifier {
  final PexelsService pexelsService;

  // Public state
  List<PhotoModel> photos = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  String? errorMessage;

  // Paging/search
  int _page = 1;
  bool _hasNext = true;
  String _activeQuery = '';

  PexelsProvider(this.pexelsService);

  bool get hasNext => _hasNext;
  String get activeQuery => _activeQuery;

  /// Initial curated load or refresh curated
  Future<void> loadCurated({int perPage = 40}) async {
    isLoading = true;
    errorMessage = null;
    _page = 1;
    _hasNext = true;
    _activeQuery = '';
    photos = [];
    notifyListeners();

    try {
      final PexelsSearchResponse res = await pexelsService.curated(
        page: 1,
        perPage: perPage,
      );

      photos = res.photos;
      _page = res.page;
      _hasNext = (res.nextPage != null) && res.photos.isNotEmpty;
    } catch (e) {
      errorMessage = 'Failed to load photos';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Start a fresh search. Empty query falls back to curated.
  Future<void> search(String query, {int perPage = 40}) async {
    final q = query.trim();
    if (q.isEmpty) {
      await loadCurated(perPage: perPage);
      return;
    }

    isLoading = true;
    errorMessage = null;
    _page = 1;
    _hasNext = true;
    _activeQuery = q;
    photos = [];
    notifyListeners();

    try {
      final res = await pexelsService.search(q, page: 1, perPage: perPage);
      photos = res.photos;
      _page = res.page;
      _hasNext = (res.nextPage != null) && res.photos.isNotEmpty;
    } catch (e) {
      errorMessage = 'Search failed. Please try again.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Load next page (works for both curated and search)
  Future<void> loadMore({int perPage = 40}) async {
    if (isLoading || isLoadingMore || !_hasNext) return;

    isLoadingMore = true;
    notifyListeners();

    try {
      final next = _page + 1;
      final res = (_activeQuery.isEmpty)
          ? await pexelsService.curated(page: next, perPage: perPage)
          : await pexelsService.search(
              _activeQuery,
              page: next,
              perPage: perPage,
            );

      photos.addAll(res.photos);
      _page = res.page;
      _hasNext = (res.nextPage != null) && res.photos.isNotEmpty;
    } catch (_) {
      // optional: set a non-blocking toast/snackbar message
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (errorMessage != null) {
      errorMessage = null;
      notifyListeners();
    }
  }

  void clear() {
    photos = [];
    _activeQuery = '';
    _page = 1;
    _hasNext = true;
    errorMessage = null;
    notifyListeners();
  }
}
