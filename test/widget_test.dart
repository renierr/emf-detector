import 'package:flutter_test/flutter_test.dart';
import 'package:emf_detector/main.dart';
import 'package:emf_detector/state/detector_state.dart';

void main() {
  testWidgets('EMF Scanner Pro UI Smoke Test', (WidgetTester tester) async {
    // Instantiate our custom state manager
    final detectorState = DetectorState();

    // Build our app and trigger a frame
    await tester.pumpWidget(MyApp(state: detectorState));

    // Verify that our main EMF Scanner dashboard is loaded
    expect(find.textContaining('EMF SCANNER'), findsOneWidget);
  });
}
