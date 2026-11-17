import 'package:flutter_test/flutter_test.dart';
import 'package:newsly/core/constants/app_strings.dart';
import 'package:newsly/main.dart';

void main() {
  testWidgets('NewslyApp foundation smoke test', (WidgetTester tester) async {
    // Build NewslyApp and trigger a frame.
    await tester.pumpWidget(const NewslyApp());
    await tester.pumpAndSettle();

    // Verify that the application title is displayed in the AppBar.
    expect(find.text(AppStrings.appName), findsOneWidget);

    // Verify navigation tabs for the foundation preview screen.
    expect(find.text('Architecture'), findsOneWidget);
    expect(find.text('Shared UI'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
  });
}
