import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newsly/core/constants/api_endpoints.dart';
import 'package:newsly/core/constants/app_strings.dart';
import 'package:newsly/core/errors/api_exception.dart';
import 'package:newsly/core/network/api_client.dart';
import 'package:newsly/models/article_model.dart';
import 'package:newsly/models/blog_model.dart';
import 'package:newsly/repositories/article_repository.dart';
import 'package:newsly/repositories/blog_repository.dart';
import 'package:newsly/viewmodels/article_view_model.dart';
import 'package:newsly/viewmodels/blog_view_model.dart';

/// Controllable fake [ApiClient] that intercepts requests and returns mock payloads.
class FakeApiClient extends ApiClient {
  dynamic responseData;
  ApiException? exceptionToThrow;
  String? lastEndpoint;
  Map<String, dynamic>? lastQueryParams;
  int callCount = 0;
  Future<dynamic> Function(String endpoint, Map<String, dynamic>? queryParams)?
  requestHandler;

  FakeApiClient({
    this.responseData,
    this.exceptionToThrow,
    this.requestHandler,
  });

  @override
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    callCount++;
    lastEndpoint = endpoint;
    lastQueryParams = queryParameters;

    if (requestHandler != null) {
      return await requestHandler!(endpoint, queryParameters);
    }

    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return responseData;
  }
}

void main() {
  group('1. Article Model JSON Parsing', () {
    test('Parses complete Spaceflight News API (v4) article', () {
      final json = {
        'id': 24001,
        'title': 'Artemis II Orion Spacecraft Undergoes Final Tests',
        'authors': [
          {
            'name': 'Sarah Connor',
            'socials': {'x': 'https://x.com/sarah', 'youtube': null},
          },
        ],
        'url': 'https://example.com/artemis-2',
        'image_url': 'https://example.com/images/orion.jpg',
        'news_site': 'NASA Spaceflight',
        'summary': 'The spacecraft passed thermal testing successfully.',
        'published_at': '2026-06-15T10:30:00Z',
        'updated_at': '2026-06-15T11:00:00Z',
        'featured': true,
        'launches': [
          {
            'launch_id': '45a8e0f1-6789-4bc2-9901-abcdef123456',
            'provider': 'Launch Library 2',
          },
        ],
        'events': [
          {'event_id': 502, 'provider': 'Launch Library 2'},
        ],
      };

      final article = Article.fromJson(json);

      expect(article.id, 24001);
      expect(
        article.title,
        'Artemis II Orion Spacecraft Undergoes Final Tests',
      );
      expect(article.authors.length, 1);
      expect(article.authors.first.name, 'Sarah Connor');
      expect(article.authors.first.socials?['x'], 'https://x.com/sarah');
      expect(article.url, 'https://example.com/artemis-2');
      expect(article.imageUrl, 'https://example.com/images/orion.jpg');
      expect(article.newsSite, 'NASA Spaceflight');
      expect(
        article.summary,
        'The spacecraft passed thermal testing successfully.',
      );
      expect(article.publishedAt, DateTime.parse('2026-06-15T10:30:00Z'));
      expect(article.updatedAt, DateTime.parse('2026-06-15T11:00:00Z'));
      expect(article.featured, true);
      expect(article.launches.length, 1);
      expect(
        article.launches.first.launchId,
        '45a8e0f1-6789-4bc2-9901-abcdef123456',
      );
      expect(article.events.length, 1);
      expect(article.events.first.eventId, 502);

      // Verify serialization round-trip
      final serialized = article.toJson();
      expect(serialized['id'], 24001);
      expect(serialized['featured'], true);
      expect(serialized['launches'].length, 1);
    });

    test('Safely handles missing, null, and malformed fields in Article', () {
      final incompleteJson = <String, dynamic>{
        'id': '999', // string instead of int
        'title': null,
        'authors': [
          null,
          'invalid author',
          {'name': 'Valid Author'},
        ],
        'url': null,
        'image_url': null, // null image URL
        'news_site': null,
        'summary': null,
        'published_at': 'invalid-date-string', // corrupted date
        'updated_at': null,
        'featured': null,
        'launches': [
          null,
          {'launch_id': 'launch-1', 'provider': 'Provider 1'},
        ],
        'events': [
          null,
          {'event_id': '300', 'provider': 'Provider 2'},
        ],
      };

      final article = Article.fromJson(incompleteJson);

      expect(article.id, 999);
      expect(article.title, '');
      expect(article.authors.length, 1);
      expect(article.authors.first.name, 'Valid Author');
      expect(article.url, '');
      expect(article.imageUrl, '');
      expect(article.newsSite, 'Spaceflight News');
      expect(article.summary, '');
      expect(article.publishedAt, isNull);
      expect(article.updatedAt, isNull);
      expect(article.featured, false);
      expect(article.launches.length, 1);
      expect(article.launches.first.launchId, 'launch-1');
      expect(article.events.length, 1);
      expect(article.events.first.eventId, 300);
    });

    test(
      'Article publication date handling: valid, missing, null, empty, invalid, serialization',
      () {
        // 1. Valid date
        final validJson = {
          'id': 1,
          'title': 'Test Article',
          'published_at': '2026-06-15T10:30:00Z',
        };
        final validArticle = Article.fromJson(validJson);
        expect(
          validArticle.publishedAt,
          DateTime.parse('2026-06-15T10:30:00Z'),
        );

        // 2. Missing published_at key
        final missingJson = {'id': 2, 'title': 'Test Article'};
        final missingArticle = Article.fromJson(missingJson);
        expect(missingArticle.publishedAt, isNull);

        // 3. Null published_at
        final nullJson = {
          'id': 3,
          'title': 'Test Article',
          'published_at': null,
        };
        final nullArticle = Article.fromJson(nullJson);
        expect(nullArticle.publishedAt, isNull);

        // 4. Empty published_at
        final emptyJson = {
          'id': 4,
          'title': 'Test Article',
          'published_at': '',
        };
        final emptyArticle = Article.fromJson(emptyJson);
        expect(emptyArticle.publishedAt, isNull);

        // 4b. Whitespace published_at
        final whitespaceJson = {
          'id': 5,
          'title': 'Test Article',
          'published_at': '   ',
        };
        final whitespaceArticle = Article.fromJson(whitespaceJson);
        expect(whitespaceArticle.publishedAt, isNull);

        // 5. Invalid published_at
        final invalidJson = {
          'id': 6,
          'title': 'Test Article',
          'published_at': 'corrupted-timestamp',
        };
        final invalidArticle = Article.fromJson(invalidJson);
        expect(invalidArticle.publishedAt, isNull);

        // 6. Serialization when publishedAt is null
        final serializedNull = nullArticle.toJson();
        expect(serializedNull['published_at'], isNull);

        // Serialization when publishedAt is valid
        final serializedValid = validArticle.toJson();
        expect(serializedValid['published_at'], '2026-06-15T10:30:00.000Z');
      },
    );

    test('Parses empty JSON object {} and applies documented defaults', () {
      final article = Article.fromJson(const {});

      expect(article.id, 0);
      expect(article.title, '');
      expect(article.authors, isEmpty);
      expect(article.url, '');
      expect(article.imageUrl, '');
      expect(article.newsSite, 'Spaceflight News');
      expect(article.summary, '');
      expect(article.publishedAt, isNull);
      expect(article.updatedAt, isNull);
      expect(article.featured, isFalse);
      expect(article.launches, isEmpty);
      expect(article.events, isEmpty);
    });

    test('Safely ignores unexpected and unmodeled API fields', () {
      final jsonWithExtras = {
        'id': 101,
        'title': 'Extra Fields Article',
        'url': 'https://example.com/extra',
        'image_url': 'https://example.com/extra.jpg',
        'news_site': 'Space News',
        'summary': 'Summary with extras',
        'published_at': '2026-01-01T12:00:00Z',
        'unknown_field': 'unexpected_value',
        'extra_nested': {'custom_flag': true, 'score': 99.5},
        'tags': ['space', 'nasa'],
      };

      final article = Article.fromJson(jsonWithExtras);

      expect(article.id, 101);
      expect(article.title, 'Extra Fields Article');
      expect(article.publishedAt, DateTime.parse('2026-01-01T12:00:00Z'));
      expect(article.newsSite, 'Space News');
    });

    test(
      'Full Article.fromJson(article.toJson()) serialization round trip preserves all fields',
      () {
        final original = Article(
          id: 777,
          title: 'Round Trip Article',
          authors: const [
            Author(
              name: 'Dr. Jane Space',
              socials: {'x': 'https://x.com/janespace', 'mastodon': null},
            ),
          ],
          url: 'https://example.com/round-trip',
          imageUrl: 'https://example.com/round-trip.png',
          newsSite: 'Cosmic Dispatch',
          summary: 'Testing full round trip fidelity.',
          publishedAt: DateTime.parse('2026-07-20T14:30:45.123Z'),
          updatedAt: DateTime.parse('2026-07-21T09:15:00.000Z'),
          featured: true,
          launches: const [
            LaunchInfo(launchId: 'launch-uuid-123', provider: 'LaunchCorp'),
          ],
          events: const [EventInfo(eventId: 88, provider: 'EventCorp')],
        );

        final json = original.toJson();
        final reconstructed = Article.fromJson(json);

        expect(reconstructed.id, original.id);
        expect(reconstructed.title, original.title);
        expect(reconstructed.authors.length, 1);
        expect(reconstructed.authors.first.name, 'Dr. Jane Space');
        expect(
          reconstructed.authors.first.socials?['x'],
          'https://x.com/janespace',
        );
        expect(reconstructed.url, original.url);
        expect(reconstructed.imageUrl, original.imageUrl);
        expect(reconstructed.newsSite, original.newsSite);
        expect(reconstructed.summary, original.summary);
        expect(reconstructed.publishedAt, original.publishedAt);
        expect(reconstructed.updatedAt, original.updatedAt);
        expect(reconstructed.featured, isTrue);
        expect(reconstructed.launches.length, 1);
        expect(reconstructed.launches.first.launchId, 'launch-uuid-123');
        expect(reconstructed.launches.first.provider, 'LaunchCorp');
        expect(reconstructed.events.length, 1);
        expect(reconstructed.events.first.eventId, 88);
        expect(reconstructed.events.first.provider, 'EventCorp');
        expect(reconstructed, equals(original));
      },
    );

    test(
      'Parses publication dates with fractional seconds and timezone offsets',
      () {
        // Milliseconds
        final millisArticle = Article.fromJson({
          'id': 1,
          'published_at': '2026-06-15T10:30:00.123Z',
        });
        expect(
          millisArticle.publishedAt,
          DateTime.parse('2026-06-15T10:30:00.123Z'),
        );

        // Microseconds
        final microsArticle = Article.fromJson({
          'id': 2,
          'published_at': '2026-06-15T10:30:00.123456Z',
        });
        expect(
          microsArticle.publishedAt,
          DateTime.parse('2026-06-15T10:30:00.123456Z'),
        );

        // Positive timezone offset (+05:00)
        final posOffsetArticle = Article.fromJson({
          'id': 3,
          'published_at': '2026-06-15T15:30:00+05:00',
        });
        expect(
          posOffsetArticle.publishedAt?.toUtc(),
          DateTime.parse('2026-06-15T10:30:00Z'),
        );

        // Negative timezone offset (-04:00)
        final negOffsetArticle = Article.fromJson({
          'id': 4,
          'published_at': '2026-06-15T06:30:00-04:00',
        });
        expect(
          negOffsetArticle.publishedAt?.toUtc(),
          DateTime.parse('2026-06-15T10:30:00Z'),
        );
      },
    );

    test(
      'Safely parses supported primitive type variations for numeric and string IDs',
      () {
        // Floating-point number coerced to integer
        final floatIdArticle = Article.fromJson({
          'id': 42.0,
          'events': [
            {'event_id': 105.0, 'provider': 'Provider A'},
          ],
        });
        expect(floatIdArticle.id, 42);
        expect(floatIdArticle.events.first.eventId, 105);

        // Numeric string coerced to integer
        final stringIdArticle = Article.fromJson({
          'id': '999',
          'events': [
            {'event_id': '333', 'provider': 'Provider B'},
          ],
        });
        expect(stringIdArticle.id, 999);
        expect(stringIdArticle.events.first.eventId, 333);

        // Non-numeric string falls back to 0
        final nonNumericArticle = Article.fromJson({
          'id': 'invalid-id',
          'events': [
            {'event_id': 'invalid-event', 'provider': 'Provider C'},
          ],
        });
        expect(nonNumericArticle.id, 0);
        expect(nonNumericArticle.events.first.eventId, 0);

        // Numeric launch ID coerced to string
        final numLaunchArticle = Article.fromJson({
          'id': 1,
          'launches': [
            {'launch_id': 12345, 'provider': 'Provider D'},
          ],
        });
        expect(numLaunchArticle.launches.first.launchId, '12345');
      },
    );

    test('Article equality and hashCode are based on id', () {
      final article1 = Article(
        id: 42,
        title: 'Title A',
        authors: const [],
        url: 'https://example.com/a',
        imageUrl: '',
        newsSite: 'Source',
        summary: '',
        publishedAt: DateTime.now(),
      );

      final article2 = Article(
        id: 42,
        title: 'Title B (Updated)',
        authors: const [],
        url: 'https://example.com/b',
        imageUrl: '',
        newsSite: 'Source',
        summary: '',
        publishedAt: DateTime.now(),
      );

      expect(article1 == article2, isTrue);
      expect(article1.hashCode, article2.hashCode);
    });
  });

  group('2. Blog Model JSON Parsing', () {
    test('Parses complete Spaceflight News API (v4) blog', () {
      final json = {
        'id': 1050,
        'title': 'Commercial Space Exploration Perspectives',
        'authors': [
          {'name': 'Alex Vance', 'socials': null},
        ],
        'url': 'https://example.com/blogs/1050',
        'image_url': 'https://example.com/images/blog.png',
        'news_site': 'Space News Weekly',
        'summary': 'An analysis of commercial space transport trends.',
        'published_at': '2026-05-20T08:00:00Z',
        'updated_at': null,
        'featured': true,
        'launches': [],
        'events': [],
      };

      final blog = Blog.fromJson(json);

      expect(blog.id, 1050);
      expect(blog.title, 'Commercial Space Exploration Perspectives');
      expect(blog.authors.first.name, 'Alex Vance');
      expect(blog.imageUrl, 'https://example.com/images/blog.png');
      expect(blog.newsSite, 'Space News Weekly');
      expect(blog.publishedAt, DateTime.parse('2026-05-20T08:00:00Z'));
      expect(blog.updatedAt, isNull);
      expect(blog.featured, isTrue);

      // Verify serialization round-trip
      final serialized = blog.toJson();
      expect(serialized['id'], 1050);
      expect(serialized['featured'], isTrue);
    });

    test('Safely handles missing and null fields in Blog', () {
      final incompleteJson = <String, dynamic>{
        'id': 0,
        'image_url': null,
        'published_at': null,
      };

      final blog = Blog.fromJson(incompleteJson);

      expect(blog.id, 0);
      expect(blog.title, '');
      expect(blog.imageUrl, '');
      expect(blog.publishedAt, isNull);
      expect(blog.featured, isFalse);
      expect(blog.launches, isEmpty);
      expect(blog.events, isEmpty);
    });

    test('Blog equality and hashCode are based on id', () {
      final blog1 = Blog(
        id: 77,
        title: 'Blog 1',
        authors: const [],
        url: '',
        imageUrl: '',
        newsSite: '',
        summary: '',
        publishedAt: DateTime.now(),
      );

      final blog2 = Blog(
        id: 77,
        title: 'Blog 2',
        authors: const [],
        url: '',
        imageUrl: '',
        newsSite: '',
        summary: '',
        publishedAt: DateTime.now(),
      );

      expect(blog1 == blog2, isTrue);
      expect(blog1.hashCode, blog2.hashCode);
    });
  });

  group('3. Paginated Responses Parsing', () {
    test('PaginatedArticles.fromJson handles valid list with next URL', () {
      final json = {
        'count': 100,
        'next':
            'https://api.spaceflightnewsapi.net/v4/articles/?limit=10&offset=10',
        'previous': null,
        'results': [
          {
            'id': 1,
            'title': 'Article 1',
            'url': 'https://example.com/1',
            'image_url': '',
            'news_site': 'Source',
            'summary': '',
            'published_at': '2026-01-01T00:00:00Z',
          },
        ],
      };

      final paginated = PaginatedArticles.fromJson(json);

      expect(paginated.count, 100);
      expect(paginated.next, contains('offset=10'));
      expect(paginated.previous, isNull);
      expect(paginated.results.length, 1);
      expect(paginated.results.first.id, 1);
    });

    test('PaginatedArticles.fromJson handles empty results list', () {
      final json = {'count': 0, 'next': null, 'previous': null, 'results': []};

      final paginated = PaginatedArticles.fromJson(json);

      expect(paginated.count, 0);
      expect(paginated.next, isNull);
      expect(paginated.results, isEmpty);
    });

    test(
      'PaginatedArticles.fromJson handles missing or null results, count formats, and serialization',
      () {
        // Missing results key
        final missingResults = PaginatedArticles.fromJson(const {'count': 0});
        expect(missingResults.results, isEmpty);
        expect(missingResults.count, 0);
        expect(missingResults.next, isNull);
        expect(missingResults.previous, isNull);

        // Null results key
        final nullResults = PaginatedArticles.fromJson(const {
          'count': 5,
          'results': null,
        });
        expect(nullResults.results, isEmpty);
        expect(nullResults.count, 5);

        // Count as float / num
        final floatCount = PaginatedArticles.fromJson(const {
          'count': 12.0,
          'results': [],
        });
        expect(floatCount.count, 12);

        // Missing or non-num count defaults to 0
        final invalidCount = PaginatedArticles.fromJson(const {
          'count': 'not-a-number',
          'results': [],
        });
        expect(invalidCount.count, 0);

        // Filters out non-map items in results list
        final dirtyResults = PaginatedArticles.fromJson(const {
          'count': 1,
          'results': [
            null,
            'not-a-map',
            42,
            {'id': 10, 'title': 'Valid Article'},
          ],
        });
        expect(dirtyResults.results.length, 1);
        expect(dirtyResults.results.first.id, 10);
        expect(dirtyResults.results.first.title, 'Valid Article');

        // Full serialization round-trip
        final paginated = PaginatedArticles(
          count: 1,
          next: 'https://api.example.com/articles/?page=2',
          previous: null,
          results: const [
            Article(
              id: 50,
              title: 'Paged Item',
              authors: [],
              url: 'https://example.com/paged',
              imageUrl: '',
              newsSite: 'Space News',
              summary: 'Paged summary',
            ),
          ],
        );
        final roundTrip = PaginatedArticles.fromJson(paginated.toJson());
        expect(roundTrip.count, 1);
        expect(roundTrip.next, 'https://api.example.com/articles/?page=2');
        expect(roundTrip.previous, isNull);
        expect(roundTrip.results.length, 1);
        expect(roundTrip.results.first.id, 50);
        expect(roundTrip.results.first.title, 'Paged Item');
      },
    );
  });

  group('4. ApiException Mapping', () {
    test('Maps connection timeouts to ApiExceptionType.timeout', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/articles/'),
        type: DioExceptionType.connectionTimeout,
      );

      final apiException = ApiException.fromDioException(dioException);

      expect(apiException.type, ApiExceptionType.timeout);
      expect(apiException.message, AppStrings.timeoutError);
      expect(apiException.originalError, same(dioException));
    });

    test('Maps sendTimeout and receiveTimeout to ApiExceptionType.timeout', () {
      final sendTimeoutEx = DioException(
        requestOptions: RequestOptions(path: '/articles/'),
        type: DioExceptionType.sendTimeout,
      );
      final apiSendEx = ApiException.fromDioException(sendTimeoutEx);
      expect(apiSendEx.type, ApiExceptionType.timeout);
      expect(apiSendEx.message, AppStrings.timeoutError);
      expect(apiSendEx.originalError, same(sendTimeoutEx));

      final receiveTimeoutEx = DioException(
        requestOptions: RequestOptions(path: '/articles/'),
        type: DioExceptionType.receiveTimeout,
      );
      final apiReceiveEx = ApiException.fromDioException(receiveTimeoutEx);
      expect(apiReceiveEx.type, ApiExceptionType.timeout);
      expect(apiReceiveEx.message, AppStrings.timeoutError);
      expect(apiReceiveEx.originalError, same(receiveTimeoutEx));
    });

    test('Maps connection error to ApiExceptionType.network', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/articles/'),
        type: DioExceptionType.connectionError,
      );

      final apiException = ApiException.fromDioException(dioException);

      expect(apiException.type, ApiExceptionType.network);
      expect(apiException.message, AppStrings.networkError);
      expect(apiException.originalError, same(dioException));
    });

    test('Maps badCertificate to ApiExceptionType.network', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/articles/'),
        type: DioExceptionType.badCertificate,
      );

      final apiException = ApiException.fromDioException(dioException);

      expect(apiException.type, ApiExceptionType.network);
      expect(apiException.message, 'Certificate verification failed.');
      expect(apiException.originalError, same(dioException));
    });

    test('Maps request cancellation to ApiExceptionType.cancelled', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/articles/'),
        type: DioExceptionType.cancel,
      );

      final apiException = ApiException.fromDioException(dioException);

      expect(apiException.type, ApiExceptionType.cancelled);
      expect(apiException.message, 'Request was cancelled.');
      expect(apiException.originalError, same(dioException));
    });

    test('Maps HTTP 400 with custom detail message to badRequest', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/articles/'),
        response: Response(
          requestOptions: RequestOptions(path: '/articles/'),
          statusCode: 400,
          data: {'detail': 'Invalid query parameter: limit must be positive.'},
        ),
        type: DioExceptionType.badResponse,
      );

      final apiException = ApiException.fromDioException(dioException);

      expect(apiException.type, ApiExceptionType.badRequest);
      expect(apiException.statusCode, 400);
      expect(
        apiException.message,
        'Invalid query parameter: limit must be positive.',
      );
      expect(apiException.originalError, same(dioException));
    });

    test('Maps HTTP 400 without custom message to badRequest fallback', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/articles/'),
        response: Response(
          requestOptions: RequestOptions(path: '/articles/'),
          statusCode: 400,
          data: null,
        ),
        type: DioExceptionType.badResponse,
      );

      final apiException = ApiException.fromDioException(dioException);

      expect(apiException.type, ApiExceptionType.badRequest);
      expect(apiException.statusCode, 400);
      expect(
        apiException.message,
        'Invalid request. Please check your parameters.',
      );
      expect(apiException.originalError, same(dioException));
    });

    test('Maps HTTP 401 and 403 to ApiExceptionType.unauthorized', () {
      final dio401 = DioException(
        requestOptions: RequestOptions(path: '/articles/'),
        response: Response(
          requestOptions: RequestOptions(path: '/articles/'),
          statusCode: 401,
        ),
        type: DioExceptionType.badResponse,
      );
      final api401 = ApiException.fromDioException(dio401);
      expect(api401.type, ApiExceptionType.unauthorized);
      expect(api401.statusCode, 401);
      expect(api401.message, AppStrings.unauthorizedError);
      expect(api401.originalError, same(dio401));

      final dio403 = DioException(
        requestOptions: RequestOptions(path: '/articles/'),
        response: Response(
          requestOptions: RequestOptions(path: '/articles/'),
          statusCode: 403,
        ),
        type: DioExceptionType.badResponse,
      );
      final api403 = ApiException.fromDioException(dio403);
      expect(api403.type, ApiExceptionType.unauthorized);
      expect(api403.statusCode, 403);
      expect(api403.message, AppStrings.unauthorizedError);
      expect(api403.originalError, same(dio403));
    });

    test('Maps HTTP 404 bad response to ApiExceptionType.notFound', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/articles/999/'),
        response: Response(
          requestOptions: RequestOptions(path: '/articles/999/'),
          statusCode: 404,
          data: {'detail': 'Not found.'},
        ),
        type: DioExceptionType.badResponse,
      );

      final apiException = ApiException.fromDioException(dioException);

      expect(apiException.type, ApiExceptionType.notFound);
      expect(apiException.statusCode, 404);
      expect(apiException.message, AppStrings.notFoundError);
      expect(apiException.originalError, same(dioException));
    });

    test('Maps HTTP 429 with and without message payload', () {
      // With throttling detail payload
      final dioThrottled = DioException(
        requestOptions: RequestOptions(path: '/articles/'),
        response: Response(
          requestOptions: RequestOptions(path: '/articles/'),
          statusCode: 429,
          data: {
            'detail': 'Request was throttled. Expected available in 5 seconds.',
          },
        ),
        type: DioExceptionType.badResponse,
      );
      final apiThrottled = ApiException.fromDioException(dioThrottled);
      expect(apiThrottled.type, ApiExceptionType.unknown);
      expect(apiThrottled.statusCode, 429);
      expect(
        apiThrottled.message,
        'Request was throttled. Expected available in 5 seconds.',
      );
      expect(apiThrottled.originalError, same(dioThrottled));

      // Without detail payload
      final dioRateLimited = DioException(
        requestOptions: RequestOptions(path: '/articles/'),
        response: Response(
          requestOptions: RequestOptions(path: '/articles/'),
          statusCode: 429,
          data: null,
        ),
        type: DioExceptionType.badResponse,
      );
      final apiRateLimited = ApiException.fromDioException(dioRateLimited);
      expect(apiRateLimited.type, ApiExceptionType.unknown);
      expect(apiRateLimited.statusCode, 429);
      expect(apiRateLimited.message, 'Received unexpected status code: 429');
      expect(apiRateLimited.originalError, same(dioRateLimited));
    });

    test(
      'Maps HTTP 500, 502, and 503 bad response to ApiExceptionType.server',
      () {
        final codes = [500, 502, 503];
        for (final code in codes) {
          final dioException = DioException(
            requestOptions: RequestOptions(path: '/articles/'),
            response: Response(
              requestOptions: RequestOptions(path: '/articles/'),
              statusCode: code,
              data: {'message': 'Server Error'},
            ),
            type: DioExceptionType.badResponse,
          );

          final apiException = ApiException.fromDioException(dioException);

          expect(apiException.type, ApiExceptionType.server);
          expect(apiException.statusCode, code);
          expect(apiException.message, AppStrings.serverError);
          expect(apiException.originalError, same(dioException));
        }
      },
    );

    test('Maps unknown DioException to ApiExceptionType.unknown', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/articles/'),
        type: DioExceptionType.unknown,
      );

      final apiException = ApiException.fromDioException(dioException);

      expect(apiException.type, ApiExceptionType.unknown);
      expect(apiException.message, AppStrings.genericError);
      expect(apiException.originalError, same(dioException));
    });
  });

  group('5. Repository Implementation with Mocked ApiClient', () {
    test(
      'ArticleRepositoryImpl passes correct query parameters on getArticles',
      () async {
        final fakeClient = FakeApiClient(
          responseData: {
            'count': 1,
            'next': null,
            'previous': null,
            'results': [
              {
                'id': 10,
                'title': 'Test Article',
                'url': 'https://example.com/10',
                'image_url': '',
                'news_site': 'Source',
                'summary': 'Summary',
                'published_at': '2026-01-01T00:00:00Z',
              },
            ],
          },
        );

        final repository = ArticleRepositoryImpl(apiClient: fakeClient);
        final result = await repository.getArticles(
          limit: 5,
          offset: 15,
          search: 'NASA',
        );

        expect(fakeClient.lastEndpoint, ApiEndpoints.articles);
        expect(fakeClient.lastQueryParams?['limit'], 5);
        expect(fakeClient.lastQueryParams?['offset'], 15);
        expect(fakeClient.lastQueryParams?['search'], 'NASA');
        expect(result.results.length, 1);
        expect(result.results.first.id, 10);
      },
    );

    test(
      'ArticleRepositoryImpl throws typed ApiException on invalid response format',
      () async {
        final fakeClient = FakeApiClient(responseData: 'not a json map');
        final repository = ArticleRepositoryImpl(apiClient: fakeClient);

        expect(
          () => repository.getArticles(),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              contains('Invalid response format'),
            ),
          ),
        );
      },
    );

    test(
      'ArticleRepositoryImpl.getArticles handles malformed responses (null, empty string, list, primitive)',
      () async {
        final fakeClient = FakeApiClient();
        final repository = ArticleRepositoryImpl(apiClient: fakeClient);

        final malformedPayloads = [null, '', <dynamic>[], 123, true];
        for (final payload in malformedPayloads) {
          fakeClient.responseData = payload;
          expect(
            () => repository.getArticles(),
            throwsA(
              isA<ApiException>()
                  .having((e) => e.type, 'type', ApiExceptionType.unknown)
                  .having(
                    (e) => e.message,
                    'message',
                    'Invalid response format received from server.',
                  ),
            ),
          );
        }
      },
    );

    test(
      'ArticleRepositoryImpl.getArticles propagates ApiException without mutation',
      () async {
        final fakeClient = FakeApiClient(
          exceptionToThrow: const ApiException(
            message: 'Server failure during article fetch',
            statusCode: 503,
            type: ApiExceptionType.server,
          ),
        );
        final repository = ArticleRepositoryImpl(apiClient: fakeClient);

        expect(
          () => repository.getArticles(),
          throwsA(
            isA<ApiException>()
                .having((e) => e.statusCode, 'statusCode', 503)
                .having((e) => e.type, 'type', ApiExceptionType.server)
                .having(
                  (e) => e.message,
                  'message',
                  'Server failure during article fetch',
                ),
          ),
        );
      },
    );

    test(
      'ArticleRepositoryImpl.getArticleById fetches article and uses correct endpoint',
      () async {
        final fakeClient = FakeApiClient(
          responseData: {
            'id': 42,
            'title': 'Single Article',
            'authors': [],
            'url': 'https://example.com/42',
            'image_url': '',
            'news_site': 'Source',
            'summary': 'Article summary',
            'published_at': '2026-03-01T12:00:00Z',
          },
        );
        final repository = ArticleRepositoryImpl(apiClient: fakeClient);
        final article = await repository.getArticleById(42);

        expect(fakeClient.lastEndpoint, ApiEndpoints.articleDetails(42));
        expect(article.id, 42);
        expect(article.title, 'Single Article');
        expect(article.newsSite, 'Source');
      },
    );

    test(
      'ArticleRepositoryImpl.getArticleById propagates 404 notFound ApiException',
      () async {
        final fakeClient = FakeApiClient(
          exceptionToThrow: const ApiException(
            message: AppStrings.notFoundError,
            statusCode: 404,
            type: ApiExceptionType.notFound,
          ),
        );
        final repository = ArticleRepositoryImpl(apiClient: fakeClient);

        expect(
          () => repository.getArticleById(999),
          throwsA(
            isA<ApiException>()
                .having((e) => e.statusCode, 'statusCode', 404)
                .having((e) => e.type, 'type', ApiExceptionType.notFound)
                .having((e) => e.message, 'message', AppStrings.notFoundError),
          ),
        );
        expect(fakeClient.lastEndpoint, ApiEndpoints.articleDetails(999));
      },
    );

    test(
      'ArticleRepositoryImpl.getArticleById handles malformed responses (null, empty string, list, primitive)',
      () async {
        final fakeClient = FakeApiClient();
        final repository = ArticleRepositoryImpl(apiClient: fakeClient);

        final malformedPayloads = [null, '', <dynamic>[], 42, false];
        for (final payload in malformedPayloads) {
          fakeClient.responseData = payload;
          expect(
            () => repository.getArticleById(1),
            throwsA(
              isA<ApiException>()
                  .having((e) => e.type, 'type', ApiExceptionType.unknown)
                  .having(
                    (e) => e.message,
                    'message',
                    'Invalid response format received from server.',
                  ),
            ),
          );
        }
      },
    );

    test(
      'ArticleRepositoryImpl with non-string map keys throws TypeError exposing production risk',
      () async {
        final fakeClient = FakeApiClient(responseData: {123: 'non-string-key'});
        final repository = ArticleRepositoryImpl(apiClient: fakeClient);

        expect(() => repository.getArticleById(1), throwsA(isA<TypeError>()));
      },
    );

    test(
      'BlogRepositoryImpl.getBlogs passes correct query parameters and parses PaginatedBlogs',
      () async {
        final fakeClient = FakeApiClient(
          responseData: {
            'count': 1,
            'next': 'https://example.com/blogs/?offset=20',
            'previous': null,
            'results': [
              {
                'id': 201,
                'title': 'Blog Entry 201',
                'authors': [],
                'url': 'https://example.com/blog/201',
                'image_url': '',
                'news_site': 'Space News Blog',
                'summary': 'Summary of 201',
                'published_at': '2026-04-01T00:00:00Z',
              },
            ],
          },
        );

        final repository = BlogRepositoryImpl(apiClient: fakeClient);
        final result = await repository.getBlogs(
          limit: 8,
          offset: 12,
          search: 'Falcon',
        );

        expect(fakeClient.lastEndpoint, ApiEndpoints.blogs);
        expect(fakeClient.lastQueryParams?['limit'], 8);
        expect(fakeClient.lastQueryParams?['offset'], 12);
        expect(fakeClient.lastQueryParams?['search'], 'Falcon');
        expect(result.count, 1);
        expect(result.next, 'https://example.com/blogs/?offset=20');
        expect(result.results.length, 1);
        expect(result.results.first.id, 201);
      },
    );

    test(
      'BlogRepositoryImpl.getBlogs handles malformed responses (null, empty string, list, primitive)',
      () async {
        final fakeClient = FakeApiClient();
        final repository = BlogRepositoryImpl(apiClient: fakeClient);

        final malformedPayloads = [null, '', <dynamic>[], 999, false];
        for (final payload in malformedPayloads) {
          fakeClient.responseData = payload;
          expect(
            () => repository.getBlogs(),
            throwsA(
              isA<ApiException>()
                  .having((e) => e.type, 'type', ApiExceptionType.unknown)
                  .having(
                    (e) => e.message,
                    'message',
                    'Invalid response format received from server.',
                  ),
            ),
          );
        }
      },
    );

    test(
      'BlogRepositoryImpl.getBlogs propagates ApiException without mutation',
      () async {
        final fakeClient = FakeApiClient(
          exceptionToThrow: const ApiException(
            message: AppStrings.networkError,
            type: ApiExceptionType.network,
          ),
        );
        final repository = BlogRepositoryImpl(apiClient: fakeClient);

        expect(
          () => repository.getBlogs(),
          throwsA(
            isA<ApiException>()
                .having((e) => e.type, 'type', ApiExceptionType.network)
                .having((e) => e.message, 'message', AppStrings.networkError),
          ),
        );
      },
    );

    test('BlogRepositoryImpl fetches single blog by id correctly', () async {
      final fakeClient = FakeApiClient(
        responseData: {
          'id': 99,
          'title': 'Blog Single',
          'authors': [],
          'url': 'https://example.com/blog/99',
          'image_url': '',
          'news_site': 'Blog Source',
          'summary': 'Summary of blog',
          'published_at': '2026-02-02T00:00:00Z',
        },
      );

      final repository = BlogRepositoryImpl(apiClient: fakeClient);
      final blog = await repository.getBlogById(99);

      expect(fakeClient.lastEndpoint, ApiEndpoints.blogDetails(99));
      expect(blog.id, 99);
      expect(blog.title, 'Blog Single');
    });

    test(
      'BlogRepositoryImpl.getBlogById propagates 404 notFound ApiException',
      () async {
        final fakeClient = FakeApiClient(
          exceptionToThrow: const ApiException(
            message: AppStrings.notFoundError,
            statusCode: 404,
            type: ApiExceptionType.notFound,
          ),
        );
        final repository = BlogRepositoryImpl(apiClient: fakeClient);

        expect(
          () => repository.getBlogById(888),
          throwsA(
            isA<ApiException>()
                .having((e) => e.statusCode, 'statusCode', 404)
                .having((e) => e.type, 'type', ApiExceptionType.notFound)
                .having((e) => e.message, 'message', AppStrings.notFoundError),
          ),
        );
        expect(fakeClient.lastEndpoint, ApiEndpoints.blogDetails(888));
      },
    );

    test(
      'BlogRepositoryImpl.getBlogById handles malformed responses (null, empty string, list, primitive)',
      () async {
        final fakeClient = FakeApiClient();
        final repository = BlogRepositoryImpl(apiClient: fakeClient);

        final malformedPayloads = [null, '', <dynamic>[], 777, true];
        for (final payload in malformedPayloads) {
          fakeClient.responseData = payload;
          expect(
            () => repository.getBlogById(1),
            throwsA(
              isA<ApiException>()
                  .having((e) => e.type, 'type', ApiExceptionType.unknown)
                  .having(
                    (e) => e.message,
                    'message',
                    'Invalid response format received from server.',
                  ),
            ),
          );
        }
      },
    );

    test(
      'BlogRepositoryImpl with non-string map keys throws TypeError exposing production risk',
      () async {
        final fakeClient = FakeApiClient(responseData: {456: 'non-string-key'});
        final repository = BlogRepositoryImpl(apiClient: fakeClient);

        expect(() => repository.getBlogById(1), throwsA(isA<TypeError>()));
      },
    );
  });

  group('6. ArticleViewModel State & Pagination Verification', () {
    test(
      'Complete initial state exposes expected default values and flags',
      () {
        final fakeClient = FakeApiClient();
        final repository = ArticleRepositoryImpl(apiClient: fakeClient);
        final viewModel = ArticleViewModel(repository);

        expect(viewModel.state, ViewState.initial);
        expect(viewModel.articles, isEmpty);
        expect(viewModel.totalCount, 0);
        expect(viewModel.isLoading, isFalse);
        expect(viewModel.isLoadingMore, isFalse);
        expect(viewModel.hasError, isFalse);
        expect(viewModel.isEmpty, isFalse);
        expect(viewModel.hasMore, isFalse);
        expect(viewModel.errorMessage, isNull);
        expect(viewModel.paginationError, isNull);
        expect(viewModel.searchQuery, isNull);
      },
    );

    test(
      'Intermediate loading state transitions to loaded state with controlled Completer',
      () async {
        final completer = Completer<dynamic>();
        final fakeClient = FakeApiClient(
          requestHandler: (endpoint, queryParams) => completer.future,
        );
        final repository = ArticleRepositoryImpl(apiClient: fakeClient);
        final viewModel = ArticleViewModel(repository);

        final future = viewModel.fetchArticles();
        expect(viewModel.isLoading, isTrue);
        expect(viewModel.state, ViewState.loading);
        expect(viewModel.hasError, isFalse);

        completer.complete({
          'count': 1,
          'next': null,
          'previous': null,
          'results': [
            {
              'id': 1,
              'title': 'Controlled Article',
              'url': 'https://example.com/1',
              'image_url': '',
              'news_site': 'Source',
              'summary': '',
              'published_at': '2026-01-01T00:00:00Z',
            },
          ],
        });

        await future;

        expect(viewModel.isLoading, isFalse);
        expect(viewModel.state, ViewState.loaded);
        expect(viewModel.hasError, isFalse);
        expect(viewModel.articles.length, 1);
        expect(viewModel.totalCount, 1);
        expect(viewModel.hasMore, isFalse);
      },
    );

    test(
      'State transitions: loading -> empty when results are empty',
      () async {
        final fakeClient = FakeApiClient(
          responseData: {
            'count': 0,
            'next': null,
            'previous': null,
            'results': [],
          },
        );

        final repository = ArticleRepositoryImpl(apiClient: fakeClient);
        final viewModel = ArticleViewModel(repository);

        await viewModel.fetchArticles();

        expect(viewModel.state, ViewState.empty);
        expect(viewModel.isEmpty, isTrue);
        expect(viewModel.articles, isEmpty);
      },
    );

    test(
      'State transitions: loading -> error when repository throws ApiException',
      () async {
        final fakeClient = FakeApiClient(
          exceptionToThrow: const ApiException(
            message: 'Server unreachable',
            type: ApiExceptionType.network,
          ),
        );

        final repository = ArticleRepositoryImpl(apiClient: fakeClient);
        final viewModel = ArticleViewModel(repository);

        await viewModel.fetchArticles();

        expect(viewModel.state, ViewState.error);
        expect(viewModel.hasError, isTrue);
        expect(viewModel.errorMessage, 'Server unreachable');
        expect(viewModel.articles, isEmpty);
      },
    );

    test('Prevents duplicate in-flight fetchArticles requests', () async {
      final fakeClient = FakeApiClient(
        responseData: {
          'count': 1,
          'next': null,
          'previous': null,
          'results': [
            {
              'id': 1,
              'title': 'Article 1',
              'url': 'https://example.com/1',
              'image_url': '',
              'news_site': 'Source',
              'summary': '',
              'published_at': '2026-01-01T00:00:00Z',
            },
          ],
        },
      );

      final repository = ArticleRepositoryImpl(apiClient: fakeClient);
      final viewModel = ArticleViewModel(repository);

      // Trigger first fetch
      final future1 = viewModel.fetchArticles();
      // Trigger second fetch while first is in-flight
      final future2 = viewModel.fetchArticles();

      await Future.wait([future1, future2]);

      // Only one API request should have been dispatched
      expect(fakeClient.callCount, 1);
    });

    test(
      'Refresh success replaces existing articles and resets offset',
      () async {
        final fakeClient = FakeApiClient(
          responseData: {
            'count': 2,
            'next': 'https://api.example.com/articles/?offset=1',
            'previous': null,
            'results': [
              {
                'id': 1,
                'title': 'Article 1',
                'url': 'https://example.com/1',
                'image_url': '',
                'news_site': 'Source',
                'summary': '',
                'published_at': '2026-01-01T00:00:00Z',
              },
            ],
          },
        );
        final repository = ArticleRepositoryImpl(apiClient: fakeClient);
        final viewModel = ArticleViewModel(repository);

        await viewModel.fetchArticles();
        expect(viewModel.articles.length, 1);
        expect(viewModel.hasMore, isTrue);

        // Load next page
        fakeClient.responseData = {
          'count': 2,
          'next': null,
          'previous': null,
          'results': [
            {
              'id': 2,
              'title': 'Article 2',
              'url': 'https://example.com/2',
              'image_url': '',
              'news_site': 'Source',
              'summary': '',
              'published_at': '2026-01-02T00:00:00Z',
            },
          ],
        };
        await viewModel.loadMore();
        expect(viewModel.articles.length, 2);

        // Refresh
        fakeClient.responseData = {
          'count': 1,
          'next': null,
          'previous': null,
          'results': [
            {
              'id': 99,
              'title': 'Refreshed Single Article',
              'url': 'https://example.com/99',
              'image_url': '',
              'news_site': 'Source',
              'summary': '',
              'published_at': '2026-02-01T00:00:00Z',
            },
          ],
        };
        await viewModel.fetchArticles(refresh: true);

        expect(fakeClient.lastQueryParams?['offset'], 0);
        expect(viewModel.articles.length, 1);
        expect(viewModel.articles.first.id, 99);
        expect(viewModel.totalCount, 1);
        expect(viewModel.state, ViewState.loaded);
      },
    );

    test(
      'Refresh failure preserves loaded state and existing articles in memory (Scenario 4)',
      () async {
        final fakeClient = FakeApiClient(
          responseData: {
            'count': 1,
            'next': null,
            'previous': null,
            'results': [
              {
                'id': 1,
                'title': 'Article 1',
                'url': 'https://example.com/1',
                'image_url': '',
                'news_site': 'Source',
                'summary': '',
                'published_at': '2026-01-01T00:00:00Z',
              },
            ],
          },
        );
        final repository = ArticleRepositoryImpl(apiClient: fakeClient);
        final viewModel = ArticleViewModel(repository);

        await viewModel.fetchArticles();
        expect(viewModel.state, ViewState.loaded);
        expect(viewModel.articles.length, 1);

        // Simulate refresh failure
        fakeClient.exceptionToThrow = const ApiException(
          message: 'Refresh network failure',
          type: ApiExceptionType.network,
        );

        await viewModel.fetchArticles(refresh: true);

        // Bug 2 fix: loaded state is preserved with existing articles so user feed is not replaced with full-page error
        expect(viewModel.state, ViewState.loaded);
        expect(viewModel.hasError, isFalse);
        expect(viewModel.errorMessage, 'Refresh network failure');
        expect(viewModel.articles.length, 1);
        expect(viewModel.articles.first.id, 1);
      },
    );

    test(
      'loadMore appends new items and accurately updates pagination metadata',
      () async {
        final fakeClient = FakeApiClient(
          responseData: {
            'count': 2,
            'next':
                'https://api.spaceflightnewsapi.net/v4/articles/?limit=1&offset=1',
            'previous': null,
            'results': [
              {
                'id': 1,
                'title': 'Article 1',
                'url': 'https://example.com/1',
                'image_url': '',
                'news_site': 'Source',
                'summary': '',
                'published_at': '2026-01-01T00:00:00Z',
              },
            ],
          },
        );

        final repository = ArticleRepositoryImpl(apiClient: fakeClient);
        final viewModel = ArticleViewModel(repository);

        await viewModel.fetchArticles();
        expect(viewModel.articles.length, 1);
        expect(viewModel.hasMore, isTrue);

        // Setup response for next page
        fakeClient.responseData = {
          'count': 2,
          'next': null, // last page
          'previous':
              'https://api.spaceflightnewsapi.net/v4/articles/?limit=1&offset=0',
          'results': [
            {
              'id': 2,
              'title': 'Article 2',
              'url': 'https://example.com/2',
              'image_url': '',
              'news_site': 'Source',
              'summary': '',
              'published_at': '2026-01-02T00:00:00Z',
            },
          ],
        };

        await viewModel.loadMore();

        expect(viewModel.articles.length, 2);
        expect(viewModel.articles[1].id, 2);
        expect(viewModel.hasMore, isFalse);
      },
    );

    test('loadMore prevents duplicate records with identical IDs', () async {
      final fakeClient = FakeApiClient(
        responseData: {
          'count': 2,
          'next':
              'https://api.spaceflightnewsapi.net/v4/articles/?limit=1&offset=1',
          'previous': null,
          'results': [
            {
              'id': 100,
              'title': 'Article 100',
              'url': 'https://example.com/100',
              'image_url': '',
              'news_site': 'Source',
              'summary': '',
              'published_at': '2026-01-01T00:00:00Z',
            },
          ],
        },
      );

      final repository = ArticleRepositoryImpl(apiClient: fakeClient);
      final viewModel = ArticleViewModel(repository);

      await viewModel.fetchArticles();
      expect(viewModel.articles.length, 1);

      // Return page containing an overlapping item with identical ID 100
      fakeClient.responseData = {
        'count': 2,
        'next': null,
        'previous': null,
        'results': [
          {
            'id': 100, // duplicate ID
            'title': 'Article 100 Duplicate',
            'url': 'https://example.com/100',
            'image_url': '',
            'news_site': 'Source',
            'summary': '',
            'published_at': '2026-01-01T00:00:00Z',
          },
          {
            'id': 101, // unique ID
            'title': 'Article 101',
            'url': 'https://example.com/101',
            'image_url': '',
            'news_site': 'Source',
            'summary': '',
            'published_at': '2026-01-02T00:00:00Z',
          },
        ],
      };

      await viewModel.loadMore();

      // Should contain 2 items total (100 and 101), NOT 3
      expect(viewModel.articles.length, 2);
      expect(viewModel.articles.map((a) => a.id).toList(), [100, 101]);
    });

    test(
      'loadMore failure isolates paginationError, preserves loaded articles, and can be retried',
      () async {
        final fakeClient = FakeApiClient(
          responseData: {
            'count': 2,
            'next': 'https://api.example.com/articles/?offset=1',
            'previous': null,
            'results': [
              {
                'id': 1,
                'title': 'Article 1',
                'url': 'https://example.com/1',
                'image_url': '',
                'news_site': 'Source',
                'summary': '',
                'published_at': '2026-01-01T00:00:00Z',
              },
            ],
          },
        );
        final repository = ArticleRepositoryImpl(apiClient: fakeClient);
        final viewModel = ArticleViewModel(repository);

        await viewModel.fetchArticles();
        expect(viewModel.articles.length, 1);
        expect(viewModel.state, ViewState.loaded);

        // Simulate failure on loadMore
        fakeClient.exceptionToThrow = const ApiException(
          message: 'Pagination network failure',
          type: ApiExceptionType.network,
        );

        await viewModel.loadMore();

        // Verify pagination error is isolated
        expect(viewModel.paginationError, 'Pagination network failure');
        expect(viewModel.errorMessage, isNull);
        expect(viewModel.state, ViewState.loaded);
        expect(viewModel.isLoadingMore, isFalse);
        expect(viewModel.articles.length, 1);

        // Retry via retryLoadMore()
        fakeClient.exceptionToThrow = null;
        fakeClient.responseData = {
          'count': 2,
          'next': null,
          'previous': null,
          'results': [
            {
              'id': 2,
              'title': 'Article 2',
              'url': 'https://example.com/2',
              'image_url': '',
              'news_site': 'Source',
              'summary': '',
              'published_at': '2026-01-02T00:00:00Z',
            },
          ],
        };

        await viewModel.retryLoadMore();

        expect(viewModel.paginationError, isNull);
        expect(viewModel.articles.length, 2);
        expect(viewModel.state, ViewState.loaded);
      },
    );

    test(
      'Active search query is preserved during loadMore pagination',
      () async {
        final fakeClient = FakeApiClient(
          responseData: {
            'count': 2,
            'next': 'https://api.example.com/articles/?offset=1&search=NASA',
            'previous': null,
            'results': [
              {
                'id': 10,
                'title': 'NASA Article 10',
                'url': 'https://example.com/10',
                'image_url': '',
                'news_site': 'NASA',
                'summary': '',
                'published_at': '2026-01-01T00:00:00Z',
              },
            ],
          },
        );
        final repository = ArticleRepositoryImpl(apiClient: fakeClient);
        final viewModel = ArticleViewModel(repository);

        await viewModel.fetchArticles(search: 'NASA');
        expect(viewModel.searchQuery, 'NASA');
        expect(fakeClient.lastQueryParams?['search'], 'NASA');
        expect(fakeClient.lastQueryParams?['offset'], 0);

        fakeClient.responseData = {
          'count': 2,
          'next': null,
          'previous': null,
          'results': [
            {
              'id': 11,
              'title': 'NASA Article 11',
              'url': 'https://example.com/11',
              'image_url': '',
              'news_site': 'NASA',
              'summary': '',
              'published_at': '2026-01-02T00:00:00Z',
            },
          ],
        };

        await viewModel.loadMore();

        expect(fakeClient.lastQueryParams?['search'], 'NASA');
        expect(fakeClient.lastQueryParams?['offset'], 1);
        expect(viewModel.articles.length, 2);
      },
    );

    test(
      'Whitespace search strings are normalized to null and trimmed',
      () async {
        final fakeClient = FakeApiClient(
          responseData: {'count': 0, 'results': []},
        );
        final repository = ArticleRepositoryImpl(apiClient: fakeClient);
        final viewModel = ArticleViewModel(repository);

        await viewModel.fetchArticles(search: '   ');
        expect(viewModel.searchQuery, isNull);
        expect(fakeClient.lastQueryParams?['search'], isNull);

        await viewModel.fetchArticles(search: '');
        expect(viewModel.searchQuery, isNull);
        expect(fakeClient.lastQueryParams?['search'], isNull);

        await viewModel.fetchArticles(search: '  James Webb  ');
        expect(viewModel.searchQuery, 'James Webb');
        expect(fakeClient.lastQueryParams?['search'], 'James Webb');
      },
    );

    test(
      'Prevents duplicate loadMore requests while in-flight or when hasMore is false',
      () async {
        final fakeClient = FakeApiClient(
          responseData: {
            'count': 1,
            'next': null, // hasMore will be false
            'previous': null,
            'results': [
              {
                'id': 1,
                'title': 'Article 1',
                'url': 'https://example.com/1',
                'image_url': '',
                'news_site': 'Source',
                'summary': '',
                'published_at': '2026-01-01T00:00:00Z',
              },
            ],
          },
        );

        final repository = ArticleRepositoryImpl(apiClient: fakeClient);
        final viewModel = ArticleViewModel(repository);

        await viewModel.fetchArticles();
        expect(fakeClient.callCount, 1);
        expect(viewModel.hasMore, isFalse);

        // Calling loadMore when hasMore is false should not trigger API request
        await viewModel.loadMore();
        expect(fakeClient.callCount, 1);
      },
    );

    test(
      'loadMore is prevented while initial fetchArticles is in-flight',
      () async {
        final completer = Completer<dynamic>();
        final fakeClient = FakeApiClient(
          requestHandler: (endpoint, queryParams) => completer.future,
        );
        final repository = ArticleRepositoryImpl(apiClient: fakeClient);
        final viewModel = ArticleViewModel(repository);

        final fetchFuture = viewModel.fetchArticles();
        expect(viewModel.isLoading, isTrue);

        // Attempt loadMore while fetch is in-flight
        await viewModel.loadMore();

        // Only 1 call dispatched
        expect(fakeClient.callCount, 1);

        completer.complete({'count': 0, 'results': []});
        await fetchFuture;
      },
    );

    test('clearSearch resets query and reloads default articles', () async {
      final fakeClient = FakeApiClient(
        responseData: {
          'count': 1,
          'next': null,
          'previous': null,
          'results': [
            {
              'id': 5,
              'title': 'Filtered by SpaceX',
              'url': 'https://example.com/5',
              'image_url': '',
              'news_site': 'Source',
              'summary': '',
              'published_at': '2026-01-01T00:00:00Z',
            },
          ],
        },
      );

      final repository = ArticleRepositoryImpl(apiClient: fakeClient);
      final viewModel = ArticleViewModel(repository);

      await viewModel.fetchArticles(search: 'SpaceX');
      expect(viewModel.searchQuery, 'SpaceX');
      expect(fakeClient.lastQueryParams?['search'], 'SpaceX');

      // Clear search
      await viewModel.clearSearch();
      expect(viewModel.searchQuery, isNull);
      expect(fakeClient.lastQueryParams?['search'], isNull);
    });

    test(
      'Disposing ViewModel prevents subsequent notifyListeners calls',
      () async {
        final fakeClient = FakeApiClient(
          responseData: {
            'count': 1,
            'next': null,
            'previous': null,
            'results': [
              {
                'id': 1,
                'title': 'Article 1',
                'url': 'https://example.com/1',
                'image_url': '',
                'news_site': 'Source',
                'summary': '',
                'published_at': '2026-01-01T00:00:00Z',
              },
            ],
          },
        );

        final repository = ArticleRepositoryImpl(apiClient: fakeClient);
        final viewModel = ArticleViewModel(repository);

        final future = viewModel.fetchArticles();
        viewModel.dispose();

        // Should complete without throwing "A ChangeNotifier was used after being disposed"
        await expectLater(future, completes);
      },
    );

    test(
      'Disposing ViewModel while loadMore is in-flight completes safely without error',
      () async {
        final completer = Completer<dynamic>();
        final fakeClient = FakeApiClient(
          requestHandler: (endpoint, queryParams) {
            final offset = queryParams?['offset'] ?? 0;
            if (offset == 0) {
              return Future.value({
                'count': 2,
                'next': 'https://api.example.com/articles/?offset=1',
                'results': [
                  {
                    'id': 1,
                    'title': 'Article 1',
                    'url': 'https://example.com/1',
                    'image_url': '',
                    'news_site': 'Source',
                    'summary': '',
                    'published_at': '2026-01-01T00:00:00Z',
                  },
                ],
              });
            }
            return completer.future;
          },
        );
        final repository = ArticleRepositoryImpl(apiClient: fakeClient);
        final viewModel = ArticleViewModel(repository);

        await viewModel.fetchArticles();
        expect(viewModel.articles.length, 1);

        final loadMoreFuture = viewModel.loadMore();
        viewModel.dispose();

        completer.complete({
          'count': 2,
          'next': null,
          'results': [
            {
              'id': 2,
              'title': 'Article 2',
              'url': 'https://example.com/2',
              'image_url': '',
              'news_site': 'Source',
              'summary': '',
              'published_at': '2026-01-02T00:00:00Z',
            },
          ],
        });

        await expectLater(loadMoreFuture, completes);
      },
    );

    test(
      'Scenario 1: Pagination request completes after successful refresh: obsolete loadMore is discarded and fresh loadMore works',
      () async {
        final completerPage2 = Completer<dynamic>();
        final completerRefresh = Completer<dynamic>();

        final fakeClient = FakeApiClient(
          requestHandler: (endpoint, queryParams) async {
            final offset = queryParams?['offset'] ?? 0;
            final search = queryParams?['search'];
            if (offset == 0 && search == 'refresh_tag') {
              return completerRefresh.future;
            } else if (offset == 0) {
              return {
                'count': 2,
                'next': 'https://api.example.com/articles/?offset=1',
                'results': [
                  {
                    'id': 1,
                    'title': 'Original Page 1 Item',
                    'url': 'https://example.com/1',
                    'image_url': '',
                    'news_site': 'Source',
                    'summary': '',
                    'published_at': '2026-01-01T00:00:00Z',
                  },
                ],
              };
            } else if (offset == 1) {
              if (!completerPage2.isCompleted) {
                return completerPage2.future;
              }
              return {
                'count': 2,
                'next': null,
                'results': [
                  {
                    'id': 101,
                    'title': 'Refreshed Page 2 Item',
                    'url': 'https://example.com/101',
                    'image_url': '',
                    'news_site': 'Source',
                    'summary': '',
                    'published_at': '2026-02-02T00:00:00Z',
                  },
                ],
              };
            }
            return {'count': 0, 'results': []};
          },
        );

        final repository = ArticleRepositoryImpl(apiClient: fakeClient);
        final viewModel = ArticleViewModel(repository);

        // 1. Initial fetch of Page 1
        await viewModel.fetchArticles();
        expect(viewModel.articles.map((a) => a.id).toList(), [1]);

        // 2. Trigger loadMore (Page 2) - in-flight
        final loadMoreFuture = viewModel.loadMore();

        // 3. User triggers fetchArticles(refresh: true, search: 'refresh_tag') while loadMore is still in-flight
        final refreshFuture = viewModel.fetchArticles(
          refresh: true,
          search: 'refresh_tag',
        );

        // Complete refresh first with new item 100
        completerRefresh.complete({
          'count': 2,
          'next':
              'https://api.example.com/articles/?offset=1&search=refresh_tag',
          'results': [
            {
              'id': 100,
              'title': 'Refreshed Item 100',
              'url': 'https://example.com/100',
              'image_url': '',
              'news_site': 'Source',
              'summary': '',
              'published_at': '2026-02-01T00:00:00Z',
            },
          ],
        });
        await refreshFuture;

        // At this point, refresh succeeded: articles has [100]
        expect(viewModel.articles.map((a) => a.id).toList(), [100]);
        expect(viewModel.hasMore, isTrue);

        // 4. Now the delayed loadMore resolves with OLD page 2 data
        completerPage2.complete({
          'count': 2,
          'next': null,
          'results': [
            {
              'id': 2,
              'title': 'Old Page 2 Item',
              'url': 'https://example.com/2',
              'image_url': '',
              'news_site': 'Source',
              'summary': '',
              'published_at': '2026-01-02T00:00:00Z',
            },
          ],
        });
        await loadMoreFuture;

        // VERIFICATION OF FIX:
        // In-flight loadMore was invalidated by the refresh request generation.
        // Stale item 2 was NOT appended to the refreshed list.
        expect(viewModel.articles.map((a) => a.id).toList(), [100]);
        expect(viewModel.hasMore, isTrue);
        expect(viewModel.isLoadingMore, isFalse);

        // Normal pagination on the refreshed feed continues working
        await viewModel.loadMore();
        expect(viewModel.articles.map((a) => a.id).toList(), [100, 101]);
        expect(viewModel.hasMore, isFalse);
      },
    );

    test(
      'Scenario 2: Pagination request completes after failed refresh: obsolete response is discarded',
      () async {
        final completerPage2 = Completer<dynamic>();
        final completerRefresh = Completer<dynamic>();

        final fakeClient = FakeApiClient(
          requestHandler: (endpoint, queryParams) async {
            final offset = queryParams?['offset'] ?? 0;
            if (queryParams?['search'] == 'fail_refresh') {
              return completerRefresh.future;
            } else if (offset == 0) {
              return {
                'count': 2,
                'next': 'https://api.example.com/articles/?offset=1',
                'results': [
                  {
                    'id': 1,
                    'title': 'Original Item 1',
                    'url': 'https://example.com/1',
                    'image_url': '',
                    'news_site': 'Source',
                    'summary': '',
                    'published_at': '2026-01-01T00:00:00Z',
                  },
                ],
              };
            } else if (offset == 1) {
              return completerPage2.future;
            }
            return {'count': 0, 'results': []};
          },
        );

        final repository = ArticleRepositoryImpl(apiClient: fakeClient);
        final viewModel = ArticleViewModel(repository);

        // 1. Initial fetch
        await viewModel.fetchArticles();
        expect(viewModel.articles.length, 1);

        // 2. Start loadMore
        final loadMoreFuture = viewModel.loadMore();

        // 3. Start refresh
        final refreshFuture = viewModel.fetchArticles(
          refresh: true,
          search: 'fail_refresh',
        );

        // Fail refresh
        completerRefresh.completeError(
          const ApiException(
            message: 'Refresh failed',
            type: ApiExceptionType.network,
          ),
        );
        await refreshFuture;

        // Feed is preserved, state is loaded, error is stored
        expect(viewModel.articles.map((a) => a.id).toList(), [1]);
        expect(viewModel.state, ViewState.loaded);
        expect(viewModel.errorMessage, 'Refresh failed');

        // 4. Complete obsolete loadMore
        completerPage2.complete({
          'count': 2,
          'next': null,
          'results': [
            {
              'id': 2,
              'title': 'Old Page 2 Item',
              'url': 'https://example.com/2',
              'image_url': '',
              'news_site': 'Source',
              'summary': '',
              'published_at': '2026-01-02T00:00:00Z',
            },
          ],
        });
        await loadMoreFuture;

        // Obsolete loadMore response is discarded
        expect(viewModel.articles.map((a) => a.id).toList(), [1]);
        expect(viewModel.isLoadingMore, isFalse);
        expect(viewModel.state, ViewState.loaded);
      },
    );

    test(
      'Scenario 3: Obsolete pagination response cannot change refreshed feed or pagination state',
      () async {
        final completerPage2 = Completer<dynamic>();
        final fakeClient = FakeApiClient(
          requestHandler: (endpoint, queryParams) async {
            final offset = queryParams?['offset'] ?? 0;
            if (offset == 0) {
              return {
                'count': 10,
                'next': 'https://api.example.com/articles/?offset=1',
                'results': [
                  {
                    'id': 1,
                    'title': 'Original Page 1',
                    'url': 'https://example.com/1',
                    'image_url': '',
                    'news_site': 'Source',
                    'summary': '',
                    'published_at': '2026-01-01T00:00:00Z',
                  },
                ],
              };
            }
            return completerPage2.future;
          },
        );

        final repository = ArticleRepositoryImpl(apiClient: fakeClient);
        final viewModel = ArticleViewModel(repository);

        await viewModel.fetchArticles();
        expect(viewModel.totalCount, 10);
        expect(viewModel.hasMore, isTrue);

        // Start loadMore
        final loadMoreFuture = viewModel.loadMore();

        // Perform synchronous refresh returning final page with 1 item
        fakeClient.requestHandler = null;
        fakeClient.responseData = {
          'count': 1,
          'next': null,
          'results': [
            {
              'id': 99,
              'title': 'Refreshed Only 99',
              'url': 'https://example.com/99',
              'image_url': '',
              'news_site': 'Source',
              'summary': '',
              'published_at': '2026-02-01T00:00:00Z',
            },
          ],
        };
        await viewModel.fetchArticles(refresh: true);

        expect(viewModel.articles.map((a) => a.id).toList(), [99]);
        expect(viewModel.totalCount, 1);
        expect(viewModel.hasMore, isFalse);

        // Obsolete loadMore resolves with contradictory metadata
        completerPage2.complete({
          'count': 50,
          'next': 'https://api.example.com/articles/?offset=2',
          'results': [
            {
              'id': 2,
              'title': 'Old Item 2',
              'url': 'https://example.com/2',
              'image_url': '',
              'news_site': 'Source',
              'summary': '',
              'published_at': '2026-01-02T00:00:00Z',
            },
          ],
        });
        await loadMoreFuture;

        // Metadata must remain that of the refreshed feed
        expect(viewModel.articles.map((a) => a.id).toList(), [99]);
        expect(viewModel.totalCount, 1);
        expect(viewModel.hasMore, isFalse);
        expect(viewModel.isLoadingMore, isFalse);
        expect(viewModel.paginationError, isNull);
      },
    );

    test(
      'Scenario 7: Loading flags remain correct after overlapping refresh and pagination requests',
      () async {
        final completerPage2 = Completer<dynamic>();
        final completerRefresh = Completer<dynamic>();

        final fakeClient = FakeApiClient(
          requestHandler: (endpoint, queryParams) async {
            final offset = queryParams?['offset'] ?? 0;
            if (queryParams?['search'] == 'overlap') {
              return completerRefresh.future;
            } else if (offset == 0) {
              return {
                'count': 2,
                'next': 'https://api.example.com/articles/?offset=1',
                'results': [
                  {
                    'id': 1,
                    'title': 'Original 1',
                    'url': 'https://example.com/1',
                    'image_url': '',
                    'news_site': 'Source',
                    'summary': '',
                    'published_at': '2026-01-01T00:00:00Z',
                  },
                ],
              };
            }
            return completerPage2.future;
          },
        );

        final repository = ArticleRepositoryImpl(apiClient: fakeClient);
        final viewModel = ArticleViewModel(repository);

        await viewModel.fetchArticles();

        // 1. Start loadMore
        final loadMoreFuture = viewModel.loadMore();
        expect(viewModel.isLoadingMore, isTrue);
        expect(viewModel.isLoading, isFalse);

        // 2. Start refresh: isLoadingMore is reset to false, isLoading becomes true
        final refreshFuture = viewModel.fetchArticles(
          refresh: true,
          search: 'overlap',
        );
        expect(viewModel.isLoading, isTrue);
        expect(viewModel.isLoadingMore, isFalse);

        // 3. Obsolete loadMore resolves while refresh is still in-flight
        completerPage2.complete({
          'count': 2,
          'next': null,
          'results': [
            {
              'id': 2,
              'title': 'Old 2',
              'url': 'https://example.com/2',
              'image_url': '',
              'news_site': 'Source',
              'summary': '',
              'published_at': '2026-01-02T00:00:00Z',
            },
          ],
        });
        await loadMoreFuture;

        // Flags during in-flight refresh must remain correct (loadMore must not flip flags)
        expect(viewModel.isLoading, isTrue);
        expect(viewModel.isLoadingMore, isFalse);

        // 4. Refresh completes
        completerRefresh.complete({
          'count': 1,
          'next': null,
          'results': [
            {
              'id': 500,
              'title': 'Fresh 500',
              'url': 'https://example.com/500',
              'image_url': '',
              'news_site': 'Source',
              'summary': '',
              'published_at': '2026-02-01T00:00:00Z',
            },
          ],
        });
        await refreshFuture;

        expect(viewModel.isLoading, isFalse);
        expect(viewModel.isLoadingMore, isFalse);
        expect(viewModel.articles.map((a) => a.id).toList(), [500]);
      },
    );
  });

  group('7. BlogViewModel State & Pagination Verification', () {
    test(
      'Complete initial state exposes expected default values and flags for BlogViewModel',
      () {
        final fakeClient = FakeApiClient();
        final repository = BlogRepositoryImpl(apiClient: fakeClient);
        final viewModel = BlogViewModel(repository);

        expect(viewModel.state, ViewState.initial);
        expect(viewModel.blogs, isEmpty);
        expect(viewModel.totalCount, 0);
        expect(viewModel.isLoading, isFalse);
        expect(viewModel.isLoadingMore, isFalse);
        expect(viewModel.hasError, isFalse);
        expect(viewModel.isEmpty, isFalse);
        expect(viewModel.hasMore, isFalse);
        expect(viewModel.errorMessage, isNull);
        expect(viewModel.paginationError, isNull);
        expect(viewModel.searchQuery, isNull);
      },
    );

    test(
      'Intermediate loading state transitions to loaded state with controlled Completer for BlogViewModel',
      () async {
        final completer = Completer<dynamic>();
        final fakeClient = FakeApiClient(
          requestHandler: (endpoint, queryParams) => completer.future,
        );
        final repository = BlogRepositoryImpl(apiClient: fakeClient);
        final viewModel = BlogViewModel(repository);

        final future = viewModel.fetchBlogs();
        expect(viewModel.isLoading, isTrue);
        expect(viewModel.state, ViewState.loading);
        expect(viewModel.hasError, isFalse);

        completer.complete({
          'count': 1,
          'next': null,
          'previous': null,
          'results': [
            {
              'id': 10,
              'title': 'Controlled Blog Post 10',
              'authors': [],
              'url': 'https://example.com/10',
              'image_url': '',
              'news_site': 'Blog Site',
              'summary': 'Summary',
              'published_at': '2026-01-01T00:00:00Z',
            },
          ],
        });

        await future;

        expect(viewModel.state, ViewState.loaded);
        expect(viewModel.isLoading, isFalse);
        expect(viewModel.hasError, isFalse);
        expect(viewModel.blogs.length, 1);
        expect(viewModel.totalCount, 1);
        expect(viewModel.hasMore, isFalse);
      },
    );

    test(
      'Initial fetch failure transitions to error state and populates error getters',
      () async {
        final fakeClient = FakeApiClient(
          exceptionToThrow: const ApiException(
            message: 'Blog network error',
            type: ApiExceptionType.network,
          ),
        );
        final repository = BlogRepositoryImpl(apiClient: fakeClient);
        final viewModel = BlogViewModel(repository);

        await viewModel.fetchBlogs();

        expect(viewModel.state, ViewState.error);
        expect(viewModel.hasError, isTrue);
        expect(viewModel.errorMessage, 'Blog network error');
        expect(viewModel.blogs, isEmpty);
      },
    );

    test(
      'Empty response sets ViewState.empty and updates isEmpty flag',
      () async {
        final fakeClient = FakeApiClient(
          responseData: {
            'count': 0,
            'next': null,
            'previous': null,
            'results': [],
          },
        );
        final repository = BlogRepositoryImpl(apiClient: fakeClient);
        final viewModel = BlogViewModel(repository);

        await viewModel.fetchBlogs();

        expect(viewModel.state, ViewState.empty);
        expect(viewModel.isEmpty, isTrue);
        expect(viewModel.blogs, isEmpty);
        expect(viewModel.hasMore, isFalse);
      },
    );

    test(
      'Refresh success replaces blogs and resets offset, and refresh failure preserves loaded blogs',
      () async {
        final fakeClient = FakeApiClient(
          responseData: {
            'count': 2,
            'next': 'https://api.example.com/blogs/?offset=1',
            'results': [
              {
                'id': 1,
                'title': 'Blog 1',
                'authors': [],
                'url': 'https://example.com/1',
                'image_url': '',
                'news_site': 'Blog Site',
                'summary': '',
                'published_at': '2026-01-01T00:00:00Z',
              },
            ],
          },
        );
        final repository = BlogRepositoryImpl(apiClient: fakeClient);
        final viewModel = BlogViewModel(repository);

        await viewModel.fetchBlogs();
        expect(viewModel.blogs.length, 1);

        // Refresh success
        fakeClient.responseData = {
          'count': 1,
          'next': null,
          'results': [
            {
              'id': 20,
              'title': 'Refreshed Blog 20',
              'authors': [],
              'url': 'https://example.com/20',
              'image_url': '',
              'news_site': 'Blog Site',
              'summary': '',
              'published_at': '2026-02-01T00:00:00Z',
            },
          ],
        };
        await viewModel.fetchBlogs(refresh: true);
        expect(fakeClient.lastQueryParams?['offset'], 0);
        expect(viewModel.blogs.length, 1);
        expect(viewModel.blogs.first.id, 20);

        // Refresh failure preserves loaded state and existing blogs (Scenario 4)
        fakeClient.exceptionToThrow = const ApiException(
          message: 'Refresh failed',
          type: ApiExceptionType.network,
        );
        await viewModel.fetchBlogs(refresh: true);
        expect(viewModel.state, ViewState.loaded);
        expect(viewModel.hasError, isFalse);
        expect(viewModel.errorMessage, 'Refresh failed');
        expect(viewModel.blogs.length, 1);
        expect(viewModel.blogs.first.id, 20);
      },
    );

    test(
      'Search filters blogs, preserves query on loadMore, and clearSearch resets to default',
      () async {
        final fakeClient = FakeApiClient(
          responseData: {
            'count': 2,
            'next': 'https://api.example.com/blogs/?offset=1&search=Mars',
            'results': [
              {
                'id': 100,
                'title': 'Mars Exploration',
                'authors': [],
                'url': 'https://example.com/100',
                'image_url': '',
                'news_site': 'Source',
                'summary': '',
                'published_at': '2026-01-01T00:00:00Z',
              },
            ],
          },
        );
        final repository = BlogRepositoryImpl(apiClient: fakeClient);
        final viewModel = BlogViewModel(repository);

        await viewModel.fetchBlogs(search: 'Mars');
        expect(viewModel.searchQuery, 'Mars');
        expect(fakeClient.lastQueryParams?['search'], 'Mars');

        fakeClient.responseData = {
          'count': 2,
          'next': null,
          'results': [
            {
              'id': 101,
              'title': 'Mars Rover',
              'authors': [],
              'url': 'https://example.com/101',
              'image_url': '',
              'news_site': 'Source',
              'summary': '',
              'published_at': '2026-01-02T00:00:00Z',
            },
          ],
        };
        await viewModel.loadMore();
        expect(fakeClient.lastQueryParams?['search'], 'Mars');
        expect(fakeClient.lastQueryParams?['offset'], 1);
        expect(viewModel.blogs.length, 2);

        // Clear search
        await viewModel.clearSearch();
        expect(viewModel.searchQuery, isNull);
        expect(fakeClient.lastQueryParams?['search'], isNull);
      },
    );

    test(
      'Prevents duplicate in-flight fetchBlogs and duplicate loadMore requests',
      () async {
        final fakeClient = FakeApiClient(
          responseData: {
            'count': 1,
            'next': null,
            'results': [
              {
                'id': 1,
                'title': 'Blog 1',
                'authors': [],
                'url': 'https://example.com/1',
                'image_url': '',
                'news_site': 'Source',
                'summary': '',
                'published_at': '2026-01-01T00:00:00Z',
              },
            ],
          },
        );
        final repository = BlogRepositoryImpl(apiClient: fakeClient);
        final viewModel = BlogViewModel(repository);

        final f1 = viewModel.fetchBlogs();
        final f2 = viewModel.fetchBlogs();
        await Future.wait([f1, f2]);

        expect(fakeClient.callCount, 1);
        expect(viewModel.hasMore, isFalse);

        // Gated when hasMore is false
        await viewModel.loadMore();
        expect(fakeClient.callCount, 1);
      },
    );

    test('loadMore prevents duplicate records in BlogViewModel', () async {
      final fakeClient = FakeApiClient(
        responseData: {
          'count': 2,
          'next':
              'https://api.spaceflightnewsapi.net/v4/blogs/?limit=1&offset=1',
          'previous': null,
          'results': [
            {
              'id': 50,
              'title': 'Blog 50',
              'authors': [],
              'url': 'https://example.com/50',
              'image_url': '',
              'news_site': 'Blog Site',
              'summary': '',
              'published_at': '2026-01-01T00:00:00Z',
            },
          ],
        },
      );

      final repository = BlogRepositoryImpl(apiClient: fakeClient);
      final viewModel = BlogViewModel(repository);

      await viewModel.fetchBlogs();
      expect(viewModel.blogs.length, 1);

      // Return page with duplicate ID 50 and unique ID 51
      fakeClient.responseData = {
        'count': 2,
        'next': null,
        'previous': null,
        'results': [
          {
            'id': 50,
            'title': 'Blog 50 Duplicate',
            'authors': [],
            'url': 'https://example.com/50',
            'image_url': '',
            'news_site': 'Blog Site',
            'summary': '',
            'published_at': '2026-01-01T00:00:00Z',
          },
          {
            'id': 51,
            'title': 'Blog 51',
            'authors': [],
            'url': 'https://example.com/51',
            'image_url': '',
            'news_site': 'Blog Site',
            'summary': '',
            'published_at': '2026-01-02T00:00:00Z',
          },
        ],
      };

      await viewModel.loadMore();

      expect(viewModel.blogs.length, 2);
      expect(viewModel.blogs.map((b) => b.id).toList(), [50, 51]);
    });

    test(
      'loadMore failure isolates paginationError and preserves loaded blogs',
      () async {
        final fakeClient = FakeApiClient(
          responseData: {
            'count': 2,
            'next':
                'https://api.spaceflightnewsapi.net/v4/blogs/?limit=1&offset=1',
            'previous': null,
            'results': [
              {
                'id': 1,
                'title': 'Blog 1',
                'authors': [],
                'url': 'https://example.com/1',
                'image_url': '',
                'news_site': 'Source',
                'summary': '',
                'published_at': '2026-01-01T00:00:00Z',
              },
            ],
          },
        );

        final repository = BlogRepositoryImpl(apiClient: fakeClient);
        final viewModel = BlogViewModel(repository);

        await viewModel.fetchBlogs();
        expect(viewModel.blogs.length, 1);
        expect(viewModel.state, ViewState.loaded);
        expect(viewModel.paginationError, isNull);
        expect(viewModel.errorMessage, isNull);

        // Simulate failure on pagination
        fakeClient.exceptionToThrow = const ApiException(
          message: 'Pagination network failure',
          type: ApiExceptionType.network,
        );

        await viewModel.loadMore();

        // Verify pagination error is isolated
        expect(viewModel.paginationError, 'Pagination network failure');
        expect(viewModel.errorMessage, isNull);
        expect(viewModel.state, ViewState.loaded);
        expect(viewModel.blogs.length, 1);

        // Clear exception and retry
        fakeClient.exceptionToThrow = null;
        fakeClient.responseData = {
          'count': 2,
          'next': null,
          'previous': null,
          'results': [
            {
              'id': 2,
              'title': 'Blog 2',
              'authors': [],
              'url': 'https://example.com/2',
              'image_url': '',
              'news_site': 'Source',
              'summary': '',
              'published_at': '2026-01-02T00:00:00Z',
            },
          ],
        };

        await viewModel.retryLoadMore();

        expect(viewModel.paginationError, isNull);
        expect(viewModel.blogs.length, 2);
      },
    );

    test(
      'Disposing BlogViewModel while fetch or loadMore is in-flight completes safely',
      () async {
        final completer = Completer<dynamic>();
        final fakeClient = FakeApiClient(
          requestHandler: (endpoint, queryParams) => completer.future,
        );
        final repository = BlogRepositoryImpl(apiClient: fakeClient);
        final viewModel = BlogViewModel(repository);

        final future = viewModel.fetchBlogs();
        viewModel.dispose();

        completer.complete({
          'count': 1,
          'next': null,
          'results': [
            {
              'id': 1,
              'title': 'Blog 1',
              'authors': [],
              'url': 'https://example.com/1',
              'image_url': '',
              'news_site': 'Source',
              'summary': '',
              'published_at': '2026-01-01T00:00:00Z',
            },
          ],
        });

        await expectLater(future, completes);
      },
    );

    test(
      'Scenario 1: Pagination request completes after successful refresh: obsolete loadMore is discarded for BlogViewModel',
      () async {
        final completerPage2 = Completer<dynamic>();
        final completerRefresh = Completer<dynamic>();

        final fakeClient = FakeApiClient(
          requestHandler: (endpoint, queryParams) async {
            final offset = queryParams?['offset'] ?? 0;
            final search = queryParams?['search'];
            if (offset == 0 && search == 'refresh_tag') {
              return completerRefresh.future;
            } else if (offset == 0) {
              return {
                'count': 2,
                'next': 'https://api.spaceflightnewsapi.net/v4/blogs/?offset=1',
                'results': [
                  {
                    'id': 1,
                    'title': 'Original Page 1 Blog',
                    'authors': [],
                    'url': 'https://example.com/1',
                    'image_url': '',
                    'news_site': 'Source',
                    'summary': '',
                    'published_at': '2026-01-01T00:00:00Z',
                  },
                ],
              };
            } else if (offset == 1) {
              if (!completerPage2.isCompleted) {
                return completerPage2.future;
              }
              return {
                'count': 2,
                'next': null,
                'results': [
                  {
                    'id': 201,
                    'title': 'Refreshed Page 2 Blog',
                    'authors': [],
                    'url': 'https://example.com/201',
                    'image_url': '',
                    'news_site': 'Source',
                    'summary': '',
                    'published_at': '2026-02-02T00:00:00Z',
                  },
                ],
              };
            }
            return {'count': 0, 'results': []};
          },
        );

        final repository = BlogRepositoryImpl(apiClient: fakeClient);
        final viewModel = BlogViewModel(repository);

        // 1. Initial fetch of Page 1
        await viewModel.fetchBlogs();
        expect(viewModel.blogs.map((b) => b.id).toList(), [1]);

        // 2. Trigger loadMore (Page 2) - in-flight
        final loadMoreFuture = viewModel.loadMore();

        // 3. User triggers fetchBlogs(refresh: true, search: 'refresh_tag') while loadMore is still in-flight
        final refreshFuture = viewModel.fetchBlogs(
          refresh: true,
          search: 'refresh_tag',
        );

        // Complete refresh first with new item 200
        completerRefresh.complete({
          'count': 2,
          'next':
              'https://api.spaceflightnewsapi.net/v4/blogs/?offset=1&search=refresh_tag',
          'results': [
            {
              'id': 200,
              'title': 'Refreshed Blog 200',
              'authors': [],
              'url': 'https://example.com/200',
              'image_url': '',
              'news_site': 'Source',
              'summary': '',
              'published_at': '2026-02-01T00:00:00Z',
            },
          ],
        });
        await refreshFuture;

        // At this point, refresh succeeded: blogs has [200]
        expect(viewModel.blogs.map((b) => b.id).toList(), [200]);
        expect(viewModel.hasMore, isTrue);

        // 4. Delayed loadMore resolves with OLD page 2 data
        completerPage2.complete({
          'count': 2,
          'next': null,
          'results': [
            {
              'id': 2,
              'title': 'Old Page 2 Blog',
              'authors': [],
              'url': 'https://example.com/2',
              'image_url': '',
              'news_site': 'Source',
              'summary': '',
              'published_at': '2026-01-02T00:00:00Z',
            },
          ],
        });
        await loadMoreFuture;

        // VERIFICATION OF FIX:
        // In-flight loadMore was invalidated by the refresh request generation.
        // Stale item 2 was NOT appended to the refreshed list.
        expect(viewModel.blogs.map((b) => b.id).toList(), [200]);
        expect(viewModel.hasMore, isTrue);
        expect(viewModel.isLoadingMore, isFalse);

        // Normal pagination on the refreshed feed continues working
        await viewModel.loadMore();
        expect(viewModel.blogs.map((b) => b.id).toList(), [200, 201]);
        expect(viewModel.hasMore, isFalse);
      },
    );

    test(
      'Scenario 2: Pagination request completes after failed refresh: obsolete response is discarded for BlogViewModel',
      () async {
        final completerPage2 = Completer<dynamic>();
        final completerRefresh = Completer<dynamic>();

        final fakeClient = FakeApiClient(
          requestHandler: (endpoint, queryParams) async {
            final offset = queryParams?['offset'] ?? 0;
            if (queryParams?['search'] == 'fail_refresh') {
              return completerRefresh.future;
            } else if (offset == 0) {
              return {
                'count': 2,
                'next': 'https://api.spaceflightnewsapi.net/v4/blogs/?offset=1',
                'results': [
                  {
                    'id': 1,
                    'title': 'Original Blog 1',
                    'authors': [],
                    'url': 'https://example.com/1',
                    'image_url': '',
                    'news_site': 'Source',
                    'summary': '',
                    'published_at': '2026-01-01T00:00:00Z',
                  },
                ],
              };
            } else if (offset == 1) {
              return completerPage2.future;
            }
            return {'count': 0, 'results': []};
          },
        );

        final repository = BlogRepositoryImpl(apiClient: fakeClient);
        final viewModel = BlogViewModel(repository);

        // 1. Initial fetch
        await viewModel.fetchBlogs();
        expect(viewModel.blogs.length, 1);

        // 2. Start loadMore
        final loadMoreFuture = viewModel.loadMore();

        // 3. Start refresh
        final refreshFuture = viewModel.fetchBlogs(
          refresh: true,
          search: 'fail_refresh',
        );

        // Fail refresh
        completerRefresh.completeError(
          const ApiException(
            message: 'Refresh failed',
            type: ApiExceptionType.network,
          ),
        );
        await refreshFuture;

        // Feed is preserved, state is loaded, error is stored
        expect(viewModel.blogs.map((b) => b.id).toList(), [1]);
        expect(viewModel.state, ViewState.loaded);
        expect(viewModel.errorMessage, 'Refresh failed');

        // 4. Complete obsolete loadMore
        completerPage2.complete({
          'count': 2,
          'next': null,
          'results': [
            {
              'id': 2,
              'title': 'Old Page 2 Blog',
              'authors': [],
              'url': 'https://example.com/2',
              'image_url': '',
              'news_site': 'Source',
              'summary': '',
              'published_at': '2026-01-02T00:00:00Z',
            },
          ],
        });
        await loadMoreFuture;

        // Obsolete loadMore response is discarded
        expect(viewModel.blogs.map((b) => b.id).toList(), [1]);
        expect(viewModel.isLoadingMore, isFalse);
        expect(viewModel.state, ViewState.loaded);
      },
    );

    test(
      'Scenario 3: Obsolete pagination response cannot change refreshed feed or pagination state for BlogViewModel',
      () async {
        final completerPage2 = Completer<dynamic>();
        final fakeClient = FakeApiClient(
          requestHandler: (endpoint, queryParams) async {
            final offset = queryParams?['offset'] ?? 0;
            if (offset == 0) {
              return {
                'count': 10,
                'next': 'https://api.spaceflightnewsapi.net/v4/blogs/?offset=1',
                'results': [
                  {
                    'id': 1,
                    'title': 'Original Page 1 Blog',
                    'authors': [],
                    'url': 'https://example.com/1',
                    'image_url': '',
                    'news_site': 'Source',
                    'summary': '',
                    'published_at': '2026-01-01T00:00:00Z',
                  },
                ],
              };
            }
            return completerPage2.future;
          },
        );

        final repository = BlogRepositoryImpl(apiClient: fakeClient);
        final viewModel = BlogViewModel(repository);

        await viewModel.fetchBlogs();
        expect(viewModel.totalCount, 10);
        expect(viewModel.hasMore, isTrue);

        // Start loadMore
        final loadMoreFuture = viewModel.loadMore();

        // Perform synchronous refresh returning final page with 1 item
        fakeClient.requestHandler = null;
        fakeClient.responseData = {
          'count': 1,
          'next': null,
          'results': [
            {
              'id': 199,
              'title': 'Refreshed Only 199',
              'authors': [],
              'url': 'https://example.com/199',
              'image_url': '',
              'news_site': 'Source',
              'summary': '',
              'published_at': '2026-02-01T00:00:00Z',
            },
          ],
        };
        await viewModel.fetchBlogs(refresh: true);

        expect(viewModel.blogs.map((b) => b.id).toList(), [199]);
        expect(viewModel.totalCount, 1);
        expect(viewModel.hasMore, isFalse);

        // Obsolete loadMore resolves with contradictory metadata
        completerPage2.complete({
          'count': 50,
          'next': 'https://api.spaceflightnewsapi.net/v4/blogs/?offset=2',
          'results': [
            {
              'id': 2,
              'title': 'Old Blog 2',
              'authors': [],
              'url': 'https://example.com/2',
              'image_url': '',
              'news_site': 'Source',
              'summary': '',
              'published_at': '2026-01-02T00:00:00Z',
            },
          ],
        });
        await loadMoreFuture;

        // Metadata must remain that of the refreshed feed
        expect(viewModel.blogs.map((b) => b.id).toList(), [199]);
        expect(viewModel.totalCount, 1);
        expect(viewModel.hasMore, isFalse);
        expect(viewModel.isLoadingMore, isFalse);
        expect(viewModel.paginationError, isNull);
      },
    );

    test(
      'Scenario 7: Loading flags remain correct after overlapping refresh and pagination requests for BlogViewModel',
      () async {
        final completerPage2 = Completer<dynamic>();
        final completerRefresh = Completer<dynamic>();

        final fakeClient = FakeApiClient(
          requestHandler: (endpoint, queryParams) async {
            final offset = queryParams?['offset'] ?? 0;
            if (queryParams?['search'] == 'overlap') {
              return completerRefresh.future;
            } else if (offset == 0) {
              return {
                'count': 2,
                'next': 'https://api.spaceflightnewsapi.net/v4/blogs/?offset=1',
                'results': [
                  {
                    'id': 1,
                    'title': 'Original 1',
                    'authors': [],
                    'url': 'https://example.com/1',
                    'image_url': '',
                    'news_site': 'Source',
                    'summary': '',
                    'published_at': '2026-01-01T00:00:00Z',
                  },
                ],
              };
            }
            return completerPage2.future;
          },
        );

        final repository = BlogRepositoryImpl(apiClient: fakeClient);
        final viewModel = BlogViewModel(repository);

        await viewModel.fetchBlogs();

        // 1. Start loadMore
        final loadMoreFuture = viewModel.loadMore();
        expect(viewModel.isLoadingMore, isTrue);
        expect(viewModel.isLoading, isFalse);

        // 2. Start refresh: isLoadingMore is reset to false, isLoading becomes true
        final refreshFuture = viewModel.fetchBlogs(
          refresh: true,
          search: 'overlap',
        );
        expect(viewModel.isLoading, isTrue);
        expect(viewModel.isLoadingMore, isFalse);

        // 3. Obsolete loadMore resolves while refresh is still in-flight
        completerPage2.complete({
          'count': 2,
          'next': null,
          'results': [
            {
              'id': 2,
              'title': 'Old 2',
              'authors': [],
              'url': 'https://example.com/2',
              'image_url': '',
              'news_site': 'Source',
              'summary': '',
              'published_at': '2026-01-02T00:00:00Z',
            },
          ],
        });
        await loadMoreFuture;

        // Flags during in-flight refresh must remain correct (loadMore must not flip flags)
        expect(viewModel.isLoading, isTrue);
        expect(viewModel.isLoadingMore, isFalse);

        // 4. Refresh completes
        completerRefresh.complete({
          'count': 1,
          'next': null,
          'results': [
            {
              'id': 600,
              'title': 'Fresh 600',
              'authors': [],
              'url': 'https://example.com/600',
              'image_url': '',
              'news_site': 'Source',
              'summary': '',
              'published_at': '2026-02-01T00:00:00Z',
            },
          ],
        });
        await refreshFuture;

        expect(viewModel.isLoading, isFalse);
        expect(viewModel.isLoadingMore, isFalse);
        expect(viewModel.blogs.map((b) => b.id).toList(), [600]);
      },
    );
  });
}
