import 'package:equatable/equatable.dart';

/// Available sort criteria for search results.
enum SortCriteria {
  /// Sort by publication date (default).
  date,

  /// Sort by total file size.
  size,

  /// Sort by number of seeders.
  seeders,
}

/// Represents a Ygg search query with optional filter and sort.
class YggSearchQuery extends Equatable {
  const YggSearchQuery({
    required this.term,
    this.categoryFilter,
    this.sortCriteria = SortCriteria.date,
    this.sortDescending = true,
  });

  /// Search term (must not be empty — FR-010).
  final String term;

  /// Category ID filter for client-side filtering (null = all).
  final String? categoryFilter;

  /// Sort criterion applied client-side on loaded results.
  final SortCriteria sortCriteria;

  /// Sort direction (true = descending, default).
  final bool sortDescending;

  YggSearchQuery copyWith({
    String? term,
    String? Function()? categoryFilter,
    SortCriteria? sortCriteria,
    bool? sortDescending,
  }) {
    return YggSearchQuery(
      term: term ?? this.term,
      categoryFilter: categoryFilter != null ? categoryFilter() : this.categoryFilter,
      sortCriteria: sortCriteria ?? this.sortCriteria,
      sortDescending: sortDescending ?? this.sortDescending,
    );
  }

  @override
  List<Object?> get props => [term, categoryFilter, sortCriteria, sortDescending];
}
