import 'package:flutter_test/flutter_test.dart';
import 'package:nuxie_flutter_example/main.dart';

void main() {
  testWidgets('renders nuxie example controls', (WidgetTester tester) async {
    await tester.pumpWidget(const ExampleApp());

    expect(find.text('Nuxie Flutter Example'), findsOneWidget);
    expect(find.text('Initialize'), findsOneWidget);
    expect(find.text('Identify'), findsOneWidget);
    expect(find.text('Trigger'), findsOneWidget);
    expect(find.text('Show Flow'), findsOneWidget);
  });
}
