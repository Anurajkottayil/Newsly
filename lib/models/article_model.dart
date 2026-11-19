/// Models representing Spaceflight News API (v4) articles and associated metadata.
library;

class Author {
  final String name;
  final Map<String, dynamic>? socials;

  const Author({required this.name, this.socials});

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      name: json['name'] as String? ?? 'Unknown',
      socials: json['socials'] is Map
          ? Map<String, dynamic>.from(json['socials'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'socials': socials};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Author && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;
}

class LaunchInfo {
  final String launchId;
  final String provider;

  const LaunchInfo({required this.launchId, required this.provider});

  factory LaunchInfo.fromJson(Map<String, dynamic> json) {
    return LaunchInfo(
      launchId: json['launch_id']?.toString() ?? '',
      provider: json['provider']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'launch_id': launchId,
    'provider': provider,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LaunchInfo &&
          runtimeType == other.runtimeType &&
          launchId == other.launchId &&
          provider == other.provider;

  @override
  int get hashCode => launchId.hashCode ^ provider.hashCode;
}

class EventInfo {
  final int eventId;
  final String provider;

  const EventInfo({required this.eventId, required this.provider});

  factory EventInfo.fromJson(Map<String, dynamic> json) {
    final idVal = json['event_id'];
    return EventInfo(
      eventId: idVal is num
          ? idVal.toInt()
          : int.tryParse(idVal?.toString() ?? '') ?? 0,
      provider: json['provider']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'event_id': eventId, 'provider': provider};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventInfo &&
          runtimeType == other.runtimeType &&
          eventId == other.eventId &&
          provider == other.provider;

  @override
  int get hashCode => eventId.hashCode ^ provider.hashCode;
}

class Article {
  final int id;
  final String title;
  final List<Author> authors;
  final String url;
  final String imageUrl;
  final String newsSite;
  final String summary;
  final DateTime? publishedAt;
  final DateTime? updatedAt;
  final bool featured;
  final List<LaunchInfo> launches;
  final List<EventInfo> events;

  const Article({
    required this.id,
    required this.title,
    required this.authors,
    required this.url,
    required this.imageUrl,
    required this.newsSite,
    required this.summary,
    this.publishedAt,
    this.updatedAt,
    this.featured = false,
    this.launches = const [],
    this.events = const [],
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    final idVal = json['id'];
    return Article(
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
      newsSite: json['news_site'] as String? ?? 'Spaceflight News',
      summary: json['summary'] as String? ?? '',
      publishedAt:
          json['published_at'] != null &&
              json['published_at'].toString().trim().isNotEmpty
          ? DateTime.tryParse(json['published_at'].toString().trim())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      featured: json['featured'] as bool? ?? false,
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
    'published_at': publishedAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'featured': featured,
    'launches': launches.map((l) => l.toJson()).toList(),
    'events': events.map((e) => e.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Article && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Paginated response envelope for articles.
class PaginatedArticles {
  final int count;
  final String? next;
  final String? previous;
  final List<Article> results;

  const PaginatedArticles({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedArticles.fromJson(Map<String, dynamic> json) {
    final countVal = json['count'];
    return PaginatedArticles(
      count: countVal is num ? countVal.toInt() : 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results:
          (json['results'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((item) => Article.fromJson(Map<String, dynamic>.from(item)))
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
