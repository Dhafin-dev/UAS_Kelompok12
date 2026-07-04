import 'package:flutter_test/flutter_test.dart';
import 'package:obesity_prediction_app/main.dart';

void main() {
  testWidgets('App should render without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(ObesityPredictionApp());
    expect(find.text('AI Obesity Predictor'), findsOneWidget);
  });
}
