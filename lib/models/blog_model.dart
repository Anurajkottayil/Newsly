import 'article_model.dart';

/// Models representing Spaceflight News API (v4) blogs and associated metadata.
class Blog {
  final int id;
  final String title;
  final List<Author> authors;
  final String url;
  final String imageUrl;
  final String newsSite;
  final String summary;
  final DateTime publishedAt;
  final DateTime? updatedAt;
  final List<LaunchInfo> launches;
  final List<EventInfo> events;

  const Blog({
    required this.id,
    required this.title,
    required this.authors,
    required this.url,
    required this.imageUrl,
    required this.newsSite,
    required this.summary,
    required this.publishedAt,
    this.updatedAt,
    this.launches = const [],
    this.events = const [],
  });

  factory Blog.fromJson(Map<String, dynamic> json) {
    final idVal = json['id'];
    return Blog(
      id: idVal is num
          ? idVal.toInt()
          : int.tryParse(idVal?.toString() ?? '') ?? 0,
      title: json['title'] as String? ?? '',
      authors:
          (json['authors'] as List<dynamic>?)
              ?.whereType<Map>()
              .map(
                (author) => Author.fromJson(Map<String, dynamic>.from(author)),
              )
              .toList() ??
          const [],
      url: json['url'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      newsSite: json['news_site'] as String? ?? 'Spaceflight Blog',
      summary: json['summary'] as String? ?? '',
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      launches:
          (json['launches'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((l) => LaunchInfo.fromJson(Map<String, dynamic>.from(l)))
              .toList() ??
          const [],
      events:
          (json['events'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((e) => EventInfo.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'authors': authors.map((a) => a.toJson()).toList(),
    'url': url,
    'image_url': imageUrl,
    'news_site': newsSite,
    'summary': summary,
    'published_at': publishedAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'launches': launches.map((l) => l.toJson()).toList(),
    'events': events.map((e) => e.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Blog && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Paginated response envelope for blogs.
class PaginatedBlogs {
  final int count;
  final String? next;
  final String? previous;
  final List<Blog> results;

  const PaginatedBlogs({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedBlogs.fromJson(Map<String, dynamic> json) {
    final countVal = json['count'];
    return PaginatedBlogs(
      count: countVal is num ? countVal.toInt() : 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results:
          (json['results'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((item) => Blog.fromJson(Map<String, dynamic>.from(item)))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'count': count,
    'next': next,
    'previous': previous,
    'results': results.map((r) => r.toJson()).toList(),
  };
}
