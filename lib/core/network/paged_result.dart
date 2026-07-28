/// A paginated page of items, matching the backend's `PagedResult<T>` shape
/// (`items`, `page`, `pageSize`, `totalCount`, `totalPages`).
class PagedResult<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  PagedResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    final items = (json['items'] as List? ?? [])
        .map((e) => itemFromJson(e as Map<String, dynamic>))
        .toList();
    return PagedResult<T>(
      items: items,
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? 20,
      totalCount: json['totalCount'] ?? json['total'] ?? items.length,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}
