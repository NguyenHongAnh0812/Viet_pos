class PaginationHelper<T> {
  final List<T> _items = [];
  final int _pageSize;
  int _currentPage = 0;
  bool _hasMore = true;

  PaginationHelper(this._pageSize);

  List<T> get currentItems => _items;

  bool get hasMore => _hasMore;

  void addItems(List<T> newItems) {
    _items.addAll(newItems);
    _hasMore = newItems.length >= _pageSize;
  }

  List<T> getPage(int page) {
    final startIndex = page * _pageSize;
    final endIndex = startIndex + _pageSize;
    return _items.sublist(startIndex, endIndex > _items.length ? _items.length : endIndex);
  }

  void reset() {
    _items.clear();
    _currentPage = 0;
    _hasMore = true;
  }
}

// Comment out ProductCategoryOptimizedService related code
// class CategoryPaginationService {
//   final ProductCategoryOptimizedService _categoryService = ProductCategoryOptimizedService();
//   final PaginationHelper<ProductCategoryOptimized> _paginationHelper = PaginationHelper(20);
//
//   Future<List<ProductCategoryOptimized>> loadMoreCategories() async {
//     if (!_paginationHelper.hasMore) return [];
//     
//     final categories = await _categoryService.getAllCategories();
//     _paginationHelper.addItems(categories);
//     
//     return _paginationHelper.getPage(_paginationHelper._currentPage++);
//   }
// }
