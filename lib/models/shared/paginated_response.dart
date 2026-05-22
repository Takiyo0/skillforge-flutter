class PaginatedResponse<T> {
  PaginatedResponse({required this.data, this.pagination});

  final List<T> data;
  final Map<String, dynamic>? pagination;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parser,
  ) {
    final values = (json['data'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(parser)
        .toList();
    final pagination = json['pagination'] as Map<String, dynamic>?;
    return PaginatedResponse<T>(
      data: values,
      pagination:
          pagination ??
          {
            if (json['page'] != null) 'page': json['page'],
            if (json['limit'] != null) 'limit': json['limit'],
            if (json['total'] != null) 'total': json['total'],
            if (json['totalPages'] != null) 'totalPages': json['totalPages'],
          },
    );
  }
}
