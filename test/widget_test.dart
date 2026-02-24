// v3.5.0
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_calendar/main.dart'; // 💡 내 앱의 메인 파일 import

void main() {
  testWidgets('Calendar app smoke test', (WidgetTester tester) async {
    // 1. 앱을 빌드하고 프레임을 트리거합니다.
    await tester.pumpWidget(const MyCalendarApp());

    // 2. 비동기 렌더링이 완료될 때까지 기다립니다.
    await tester.pumpAndSettle();

    // 3. 앱바에 'My Calendar'라는 텍스트가 정상적으로 나타나는지 확인합니다.
    expect(find.text('My Calendar'), findsWidgets);
  });
}
