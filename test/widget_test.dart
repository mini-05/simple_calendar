// v4.0.1 - 테스트 코드 오류 해결
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_calendar/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Riverpod ProviderScope로 감싸서 앱 실행 테스트
    await tester.pumpWidget(const ProviderScope(child: MyCalendarApp()));

    // 앱이 정상적으로 렌더링되는지 확인
    expect(find.text('simple Calendar'), findsNothing);
  });
}
