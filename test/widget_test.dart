import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:taskflow/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders TaskFlow login screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
