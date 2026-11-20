import 'article_model.dart';
export 'article_model.dart' show Author;

/// Models representing Spaceflight News API (v4) reports and associated metadata.
///
/// Reports represent official agency and mission status reports (such as ISS Daily
/// Status Reports, NASA technical briefings, and ESA mission updates).
/// Note: Unlike articles and blogs, reports do not contain Launch Library 2
/// launch/event relationships or a 'featured' editorial status.
class Report {
  final int id;
  final String title;
  final List<Author> authors;
  final String url;
  final String imageUrl;
  final String newsSite;
  final String summary;
  final DateTime? publishedAt;
  final DateTime? updatedAt;

  const Report({
    required this.id,
    required this.title,
    required this.authors,
    required this.url,
    required this.imageUrl,
    required this.newsSite,
    required this.summary,
    this.publishedAt,
    this.updatedAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    final idVal = json['id'];
    return Report(
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
      newsSite: json['news_site'] as String? ?? 'Spaceflight Report',
      summary: json['summary'] as String? ?? '',
      publishedAt:
          json['published_at'] != null &&
              json['published_at'].toString().trim().isNotEmpty
          ? DateTime.tryParse(json['published_at'].toString().trim())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
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
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Report && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Paginated response envelope for reports.
class PaginatedReports {
  final int count;
  final String? next;
  final String? previous;
  final List<Report> results;

  const PaginatedReports({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedReports.fromJson(Map<String, dynamic> json) {
    final countVal = json['count'];
    return PaginatedReports(
      count: countVal is num ? countVal.toInt() : 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results:
          (json['results'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((item) => Report.fromJson(Map<String, dynamic>.from(item)))
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
