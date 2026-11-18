import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newsly/core/constants/api_endpoints.dart';
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

  FakeApiClient({this.responseData, this.exceptionToThrow});

  @override
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    callCount++;
    lastEndpoint = endpoint;
    lastQueryParams = queryParameters;

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
      expect(article.publishedAt, isA<DateTime>());
      expect(article.updatedAt, isNull);
      expect(article.featured, false);
      expect(article.launches.length, 1);
      expect(article.launches.first.launchId, 'launch-1');
      expect(article.events.length, 1);
      expect(article.events.first.eventId, 300);
    });

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
  });

  group('4. ApiException Mapping', () {
    test('Maps connection timeouts to ApiExceptionType.timeout', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/articles/'),
        type: DioExceptionType.connectionTimeout,
      );

      final apiException = ApiException.fromDioException(dioException);

      expect(apiException.type, ApiExceptionType.timeout);
      expect(apiException.message, contains('connection timed out'));
    });

    test('Maps connection error to ApiExceptionType.network', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/articles/'),
        type: DioExceptionType.connectionError,
      );

      final apiException = ApiException.fromDioException(dioException);

      expect(apiException.type, ApiExceptionType.network);
      expect(apiException.message, contains('No internet connection'));
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
      expect(apiException.message, contains('not found'));
    });

    test('Maps HTTP 500 bad response to ApiExceptionType.server', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/articles/'),
        response: Response(
          requestOptions: RequestOptions(path: '/articles/'),
          statusCode: 500,
          data: {'message': 'Internal Server Error'},
        ),
        type: DioExceptionType.badResponse,
      );

      final apiException = ApiException.fromDioException(dioException);

      expect(apiException.type, ApiExceptionType.server);
      expect(apiException.statusCode, 500);
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
  });

  group('6. ArticleViewModel State & Pagination Verification', () {
    test(
      'State transitions: initial -> loading -> loaded on success',
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

        expect(viewModel.state, ViewState.initial);
        expect(viewModel.articles, isEmpty);

        final future = viewModel.fetchArticles();
        expect(viewModel.isLoading, isTrue);

        await future;

        expect(viewModel.state, ViewState.loaded);
        expect(viewModel.isLoading, isFalse);
        expect(viewModel.articles.length, 1);
        expect(viewModel.hasError, isFalse);
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
  });

  group('7. BlogViewModel State & Pagination Verification', () {
    test(
      'State transitions: initial -> loading -> loaded on success',
      () async {
        final fakeClient = FakeApiClient(
          responseData: {
            'count': 1,
            'next': null,
            'previous': null,
            'results': [
              {
                'id': 10,
                'title': 'Blog Post 10',
                'authors': [],
                'url': 'https://example.com/10',
                'image_url': '',
                'news_site': 'Blog Site',
                'summary': 'Summary',
                'published_at': '2026-01-01T00:00:00Z',
              },
            ],
          },
        );

        final repository = BlogRepositoryImpl(apiClient: fakeClient);
        final viewModel = BlogViewModel(repository);

        expect(viewModel.state, ViewState.initial);
        await viewModel.fetchBlogs();

        expect(viewModel.state, ViewState.loaded);
        expect(viewModel.blogs.length, 1);
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
  });
}
