import 'package:flutter_test/flutter_test.dart';
import 'package:instockavailio/main.dart';

void main() {
  testWidgets('Login screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(isLoggedIn: false));
    expect(find.text('Login'), findsOneWidget);
  });
}