import 'package:flutter_test/flutter_test.dart';
import 'package:yatraki_mobile/main.dart';

void main() {
  testWidgets('BookYourGuideApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BookYourGuideApp());
    expect(find.text('Your Himalayan Guide'), findsWidgets);
  });
}
