import 'package:flutter_test/flutter_test.dart';
import 'package:newsly/models/report_model.dart';

void main() {
  group('Report Model JSON Parsing & Serialization', () {
    final completeReportJson = {
      'id': 5001,
      'title': 'ISS Daily Summary Report - Expedition 71',
      'authors': [
        {
          'name': 'NASA ISS Operations',
          'socials': {'x': 'https://x.com/Space_Station'},
        },
      ],
      'url': 'https://blogs.nasa.gov/stationreport/2026/11/20/iss-daily-summary/',
      'image_url': 'https://images.nasa.gov/iss_cupola.jpg',
      'news_site': 'NASA',
      'summary': 'Astronauts conducted fluid physics experiments and spacewalk prep.',
      'published_at': '2026-11-20T14:30:00Z',
      'updated_at': '2026-11-20T15:00:00Z',
    };

    test('1. Successful parsing of a complete report JSON object', () {
      final report = Report.fromJson(completeReportJson);

      expect(report.id, 5001);
      expect(report.title, 'ISS Daily Summary Report - Expedition 71');
      expect(report.url, 'https://blogs.nasa.gov/stationreport/2026/11/20/iss-daily-summary/');
      expect(report.imageUrl, 'https://images.nasa.gov/iss_cupola.jpg');
      expect(report.newsSite, 'NASA');
      expect(report.summary, 'Astronauts conducted fluid physics experiments and spacewalk prep.');
      expect(report.publishedAt, DateTime.parse('2026-11-20T14:30:00Z'));
      expect(report.updatedAt, DateTime.parse('2026-11-20T15:00:00Z'));
      expect(report.authors.length, 1);
      expect(report.authors.first.name, 'NASA ISS Operations');
    });

    test('2. Correct mapping of image_url, news_site, and date fields', () {
      final report = Report.fromJson({
        'id': 100,
        'title': 'ESA Mission Update',
        'image_url': 'https://esa.int/banner.png',
        'news_site': 'ESA',
        'published_at': '2026-05-10T08:00:00Z',
        'updated_at': '2026-05-10T09:30:00Z',
      });

      expect(report.imageUrl, 'https://esa.int/banner.png');
      expect(report.newsSite, 'ESA');
      expect(report.publishedAt, DateTime.utc(2026, 5, 10, 8, 0, 0));
      expect(report.updatedAt, DateTime.utc(2026, 5, 10, 9, 30, 0));
    });

    test('3. Nullable image handling defaults safely to empty string', () {
      final jsonWithNullImage = {
        'id': 101,
        'title': 'No Image Report',
        'image_url': null,
      };

      final report = Report.fromJson(jsonWithNullImage);
      expect(report.imageUrl, '');
    });

    test('4. Missing or empty summary handling', () {
      final jsonNullSummary = {'id': 102, 'title': 'Test', 'summary': null};
      final report1 = Report.fromJson(jsonNullSummary);
      expect(report1.summary, '');

      final jsonEmptySummary = {'id': 103, 'title': 'Test', 'summary': ''};
      final report2 = Report.fromJson(jsonEmptySummary);
      expect(report2.summary, '');
    });

    test('5. Missing or empty authors defaults safely to empty list', () {
      final jsonNoAuthors = {'id': 104, 'title': 'No Authors'};
      final report1 = Report.fromJson(jsonNoAuthors);
      expect(report1.authors, isEmpty);

      final jsonNullAuthors = {'id': 105, 'title': 'Null Authors', 'authors': null};
      final report2 = Report.fromJson(jsonNullAuthors);
      expect(report2.authors, isEmpty);

      final jsonEmptyAuthors = {'id': 106, 'title': 'Empty Authors', 'authors': []};
      final report3 = Report.fromJson(jsonEmptyAuthors);
      expect(report3.authors, isEmpty);
    });

    test('6. Correct author parsing using the existing Author model', () {
      final json = {
        'id': 107,
        'title': 'Multi Author Report',
        'authors': [
          {'name': 'Commander Hansen', 'socials': null},
          {'name': 'Flight Engineer Koch', 'socials': {'x': 'https://x.com/koch'}},
        ],
      };

      final report = Report.fromJson(json);
      expect(report.authors.length, 2);
      expect(report.authors[0], isA<Author>());
      expect(report.authors[0].name, 'Commander Hansen');
      expect(report.authors[0].socials, isNull);
      expect(report.authors[1].name, 'Flight Engineer Koch');
      expect(report.authors[1].socials?['x'], 'https://x.com/koch');
    });

    test('7. Invalid or missing optional date handling', () {
      final jsonInvalidDate = {
        'id': 108,
        'title': 'Invalid Date',
        'published_at': 'not-a-valid-date',
        'updated_at': 'malformed',
      };
      final report1 = Report.fromJson(jsonInvalidDate);
      expect(report1.publishedAt, isNull);
      expect(report1.updatedAt, isNull);

      final jsonWhitespaceDate = {
        'id': 109,
        'title': 'Whitespace Date',
        'published_at': '   ',
        'updated_at': null,
      };
      final report2 = Report.fromJson(jsonWhitespaceDate);
      expect(report2.publishedAt, isNull);
      expect(report2.updatedAt, isNull);
    });

    test('8. Correct serialization round-trip via toJson', () {
      final originalReport = Report.fromJson(completeReportJson);
      final serialized = originalReport.toJson();

      expect(serialized['id'], 5001);
      expect(serialized['title'], 'ISS Daily Summary Report - Expedition 71');
      expect(serialized['url'], 'https://blogs.nasa.gov/stationreport/2026/11/20/iss-daily-summary/');
      expect(serialized['image_url'], 'https://images.nasa.gov/iss_cupola.jpg');
      expect(serialized['news_site'], 'NASA');
      expect(serialized['summary'], 'Astronauts conducted fluid physics experiments and spacewalk prep.');
      expect(serialized['published_at'], '2026-11-20T14:30:00.000Z');
      expect(serialized['updated_at'], '2026-11-20T15:00:00.000Z');
      expect(serialized['authors'], isA<List>());
      expect((serialized['authors'] as List).length, 1);
      expect((serialized['authors'] as List).first['name'], 'NASA ISS Operations');

      final reconstructed = Report.fromJson(serialized);
      expect(reconstructed, equals(originalReport));
      expect(reconstructed.hashCode, equals(originalReport.hashCode));
    });

    test('9. PaginatedReports parsing with multiple results', () {
      final paginatedJson = {
        'count': 2,
        'next': 'https://api.spaceflightnewsapi.net/v4/reports/?limit=10&offset=10',
        'previous': null,
        'results': [
          completeReportJson,
          {
            'id': 5002,
            'title': 'Second Report',
            'url': 'https://example.com/report2',
            'image_url': 'https://example.com/img2.jpg',
            'news_site': 'ESA',
            'summary': 'Second summary',
            'published_at': '2026-11-19T10:00:00Z',
            'authors': [],
          },
        ],
      };

      final paginated = PaginatedReports.fromJson(paginatedJson);
      expect(paginated.count, 2);
      expect(paginated.next, 'https://api.spaceflightnewsapi.net/v4/reports/?limit=10&offset=10');
      expect(paginated.previous, isNull);
      expect(paginated.results.length, 2);
      expect(paginated.results[0].id, 5001);
      expect(paginated.results[1].id, 5002);

      final serialized = paginated.toJson();
      expect(serialized['count'], 2);
      expect(serialized['results'], hasLength(2));
    });

    test('10. Empty pagination results and null next/previous', () {
      final emptyJson = {
        'count': 0,
        'next': null,
        'previous': null,
        'results': [],
      };

      final paginated = PaginatedReports.fromJson(emptyJson);
      expect(paginated.count, 0);
      expect(paginated.next, isNull);
      expect(paginated.previous, isNull);
      expect(paginated.results, isEmpty);

      // Verify null / missing fields fallback
      final malformedPagination = <String, dynamic>{};
      final fallback = PaginatedReports.fromJson(malformedPagination);
      expect(fallback.count, 0);
      expect(fallback.next, isNull);
      expect(fallback.previous, isNull);
      expect(fallback.results, isEmpty);
    });

    test('11. String ID and count fallback handling', () {
      final report = Report.fromJson({'id': '9999', 'title': 'String ID'});
      expect(report.id, 9999);

      final paginated = PaginatedReports.fromJson({'count': '42', 'results': []});
      expect(paginated.count, 0); // num check, safe default
    });
  });
}
