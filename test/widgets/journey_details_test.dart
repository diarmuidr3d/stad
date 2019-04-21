//import 'package:google_maps_flutter/google_maps_flutter.dart';
////import 'package:stad/models.dart';
////import 'package:stad/widgets/journey_details.dart';
////
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:stad/models.dart';
import 'package:stad/utilities.dart';
import 'package:stad/widgets/journey_details.dart';
import 'package:mockito/mockito.dart';
////
////class MockFinderState extends Mock implements FinderState {}
////
////Timing timing = Timing()..journeyReference = "12";
////
////final stopsBefore = <StopVisited>[
////  StopVisited("1", "A", "B", LatLng(5, -6)),
////  StopVisited("2", "C", "D", LatLng(7, -8)),
////  StopVisited("3", "E", "F", LatLng(9, -10)),
////  StopVisited("4", "G", "H", LatLng(11, -12)),
////];
////
////void main() {
////  test('Test searchForBus on even set of data', () async {
////    final finder = MockFinderState();
////    when(finder.stopsBefore).thenAnswer((_) => stopsBefore);
////    when(finder.widget.timing).thenAnswer((_) => timing);
////    when(finder.journeyIsDueAt("1", "12")).thenAnswer((_) async => false);
////    when(finder.journeyIsDueAt("2", "12")).thenAnswer((_) async => false);
////    when(finder.journeyIsDueAt("3", "12")).thenAnswer((_) async => true);
////    when(finder.journeyIsDueAt("4", "12")).thenAnswer((_) async => true);
////
////    int index = await finder.searchForBus(0, 3);
////    expect(index, 2);
////    expect(stopsBefore[0].state, StopState.VISITED);
////    expect(stopsBefore[1].state, StopState.VISITED);
////    expect(stopsBefore[2].state, StopState.UNVISITED);
////    expect(stopsBefore[3].state, StopState.UNVISITED);
////  });
////}

class MockRouteDB extends Mock implements RouteDB {}

void main() {
  // Define a test. The TestWidgets function will also provide a WidgetTester
  // for us to work with. The WidgetTester will allow us to build and interact
  // with Widgets in the test environment.
  testWidgets('JourneyDetails returns all the previous stops', (WidgetTester tester) async {
    // Create the Widget tell the tester to build it
    MockRouteDB db = MockRouteDB();
    when(db.getPreviousStops("66", "3982", 1)).thenAnswer((_) async => stopsBefore);
    await tester.pumpWidget(JourneyDetails(Timing(route:"66", inbound:1, journeyReference: "1234"), "3982", db));
    await tester.pumpAndSettle();
    expect(find.text("3980"), findsOneWidget);
    expect(find.text("6089"), findsOneWidget);
    expect(find.text("3981"), findsOneWidget);
  });
}

final stopsBefore = <StopVisited>[
  StopVisited("3980", "A", "B", LatLng(1,2)),
  StopVisited("6089", "C", "D", LatLng(3,4)),
  StopVisited("3981", "E", "F", LatLng(5,6)),
];