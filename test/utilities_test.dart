
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:stad/models.dart';
import 'package:stad/utilities.dart';

import 'package:xpath/xpath.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class MockDateTime extends Mock implements DateTime {}
class MockDublinBusAPI extends Mock implements DublinBusAPI {}

void main() {
  test('Dublin Bus Stop Data should be parsed', () {
    var tree = journeyDue.xpath('/soap/soap/GetRealTimeStopDataResponse/GetRealTimeStopDataResult/diffgr/DocumentElement/StopData')[0];
    var timing = RealTimeUtilities.getDetailsFromStopDataXml(tree);
    expect(timing.dueMins, DateTime.parse("2019-03-24T17:34:55+00:00")
        .difference(DateTime.now()).inMinutes);
  });
  test('Dublin Bus Stop Data should be parsed', () {
    var tree = journeyDue.xpath('/soap/soap/GetRealTimeStopDataResponse/GetRealTimeStopDataResult/diffgr/DocumentElement/StopData')[0];
    var timing = RealTimeUtilities.getDetailsFromStopDataXml(tree);
    expect(timing.dueMins, DateTime.parse("2019-03-24T17:34:55+00:00")
        .difference(DateTime.now()).inMinutes);
  });
  test('Verify Binary Search (searchForBus) correctly finishes for NNYY', () async {
    final dbApi = MockDublinBusAPI();
    when(dbApi.getRealTimeStopDataTree("3980")).thenAnswer((_) async => journeyNotDue);
    when(dbApi.getRealTimeStopDataTree("6089")).thenAnswer((_) async => journeyNotDue);
    when(dbApi.getRealTimeStopDataTree("3981")).thenAnswer((_) async => journeyDue);
    when(dbApi.getRealTimeStopDataTree("3982")).thenAnswer((_) async => journeyDue);
    String journey = "123";
    final dublinBus = RealTimeUtilities();
    final newStopList = await dublinBus.searchForBus(0, 3, stopList, journey, _setAllInRangeToState, dbApi);
    expect(newStopList[0].state, StopState.VISITED, reason: "3980");
    expect(newStopList[1].state, StopState.VISITED, reason: "6089");
    expect(newStopList[2].state, StopState.UNVISITED, reason: "3981");
    expect(newStopList[3].state, StopState.UNVISITED, reason: "3982");
  });
  test('Verify Binary Search (searchForBus) correctly finishes for YYYY', () async {
    final dbApi = MockDublinBusAPI();
    when(dbApi.getRealTimeStopDataTree("3980")).thenAnswer((_) async => journeyDue);
    when(dbApi.getRealTimeStopDataTree("6089")).thenAnswer((_) async => journeyDue);
    when(dbApi.getRealTimeStopDataTree("3981")).thenAnswer((_) async => journeyDue);
    when(dbApi.getRealTimeStopDataTree("3982")).thenAnswer((_) async => journeyDue);
    String journey = "123";
    final dublinBus = RealTimeUtilities();
    final newStopList = await dublinBus.searchForBus(0, 3, stopList, journey, _setAllInRangeToState, dbApi);
    expect(newStopList[0].state, StopState.UNVISITED, reason: "3980 YYYY");
    expect(newStopList[1].state, StopState.UNVISITED, reason: "6089 YYYY");
    expect(newStopList[2].state, StopState.UNVISITED, reason: "3981 YYYY");
    expect(newStopList[3].state, StopState.UNVISITED, reason: "3982 YYYY");
  });
  test('Verify Binary Search (searchForBus) correctly finishes for NNNN', () async {
    final dbApi = MockDublinBusAPI();
    when(dbApi.getRealTimeStopDataTree("3980")).thenAnswer((_) async => journeyNotDue);
    when(dbApi.getRealTimeStopDataTree("6089")).thenAnswer((_) async => journeyNotDue);
    when(dbApi.getRealTimeStopDataTree("3981")).thenAnswer((_) async => journeyNotDue);
    when(dbApi.getRealTimeStopDataTree("3982")).thenAnswer((_) async => journeyNotDue);
    String journey = "123";
    final dublinBus = RealTimeUtilities();
    final newStopList = await dublinBus.searchForBus(0, 3, stopList, journey, _setAllInRangeToState, dbApi);
    expect(newStopList[0].state, StopState.VISITED, reason: "3980 NNNN");
    expect(newStopList[1].state, StopState.VISITED, reason: "6089 NNNN");
    expect(newStopList[2].state, StopState.VISITED, reason: "3981 NNNN");
    expect(newStopList[3].state, StopState.VISITED, reason: "3982 NNNN");
  });
}


void _setAllInRangeToState(int start, int finish, StopState state) {
  for(int i = start; i <= finish; i++) {
    stopList[i].state = state;
  }
}

var stopList = <StopVisited>[
  StopVisited("3980", "A", "B", LatLng(1,2)),
  StopVisited("6089", "C", "D", LatLng(3,4)),
  StopVisited("3981", "E", "F", LatLng(5,6)),
  StopVisited("3982", "G", "H", LatLng(7,8)),
];

final journeyDue = ETree.fromString(_testSingleStopData);
final journeyNotDue = ETree.fromString(_testOtherStopData);

final _testSingleStopData = """
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <soap:Body>
        <GetRealTimeStopDataResponse xmlns="http://dublinbus.ie/">
            <GetRealTimeStopDataResult>
              <diffgr:diffgram xmlns:msdata="urn:schemas-microsoft-com:xml-msdata" xmlns:diffgr="urn:schemas-microsoft-com:xml-diffgram-v1">
                    <DocumentElement xmlns="">
                          <StopData diffgr:id="StopData1" msdata:rowOrder="0">
                            <ServiceDelivery_ResponseTimestamp>2019-03-24T17:18:21.763+00:00</ServiceDelivery_ResponseTimestamp>
                            <ServiceDelivery_ProducerRef>bac</ServiceDelivery_ProducerRef>
                            <ServiceDelivery_Status>true</ServiceDelivery_Status>
                            <ServiceDelivery_MoreData>false</ServiceDelivery_MoreData>
                            <StopMonitoringDelivery_Version>1.0</StopMonitoringDelivery_Version>
                            <StopMonitoringDelivery_ResponseTimestamp>2019-03-24T17:18:21.763+00:00</StopMonitoringDelivery_ResponseTimestamp>
                            <StopMonitoringDelivery_RequestMessageRef />
                            <MonitoredStopVisit_RecordedAtTime>2019-03-24T17:18:21.763+00:00</MonitoredStopVisit_RecordedAtTime>
                            <MonitoredStopVisit_MonitoringRef>3982</MonitoredStopVisit_MonitoringRef>
                            <MonitoredVehicleJourney_LineRef>26</MonitoredVehicleJourney_LineRef>
                            <MonitoredVehicleJourney_DirectionRef>Inbound</MonitoredVehicleJourney_DirectionRef>
                            <FramedVehicleJourneyRef_DataFrameRef>2019-03-24</FramedVehicleJourneyRef_DataFrameRef>
                            <FramedVehicleJourneyRef_DatedVehicleJourneyRef>15621</FramedVehicleJourneyRef_DatedVehicleJourneyRef>
                            <MonitoredVehicleJourney_PublishedLineName>66</MonitoredVehicleJourney_PublishedLineName>
                            <MonitoredVehicleJourney_OperatorRef>bac</MonitoredVehicleJourney_OperatorRef>
                            <MonitoredVehicleJourney_DestinationRef>7387</MonitoredVehicleJourney_DestinationRef>
                            <MonitoredVehicleJourney_DestinationName>Merrion Sq via Palmerstown</MonitoredVehicleJourney_DestinationName>
                            <MonitoredVehicleJourney_Monitored>true</MonitoredVehicleJourney_Monitored>
                            <MonitoredVehicleJourney_InCongestion>false</MonitoredVehicleJourney_InCongestion>
                            <MonitoredVehicleJourney_BlockRef>66004</MonitoredVehicleJourney_BlockRef>
                            <MonitoredVehicleJourney_VehicleRef>123</MonitoredVehicleJourney_VehicleRef>
                            <MonitoredCall_VisitNumber>4</MonitoredCall_VisitNumber>
                            <MonitoredCall_VehicleAtStop>false</MonitoredCall_VehicleAtStop>
                            <MonitoredCall_AimedArrivalTime>2019-03-24T17:34:55+00:00</MonitoredCall_AimedArrivalTime>
                            <MonitoredCall_ExpectedArrivalTime>2019-03-24T17:34:55+00:00</MonitoredCall_ExpectedArrivalTime>
                            <MonitoredCall_AimedDepartureTime>2019-03-24T17:34:55+00:00</MonitoredCall_AimedDepartureTime>
                            <MonitoredCall_ExpectedDepartureTime>2019-03-24T17:34:55+00:00</MonitoredCall_ExpectedDepartureTime>
                            <Timestamp>2019-03-24T17:18:22.347+00:00</Timestamp>
                            <LineNote />
                        </StopData>
                    </DocumentElement>
                </diffgr:diffgram>
            </GetRealTimeStopDataResult>
        </GetRealTimeStopDataResponse>
    </soap:Body>
</soap:Envelope> 
""";

final _testOtherStopData = """
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <soap:Body>
        <GetRealTimeStopDataResponse xmlns="http://dublinbus.ie/">
            <GetRealTimeStopDataResult>
              <diffgr:diffgram xmlns:msdata="urn:schemas-microsoft-com:xml-msdata" xmlns:diffgr="urn:schemas-microsoft-com:xml-diffgram-v1">
                    <DocumentElement xmlns="">
                        <StopData diffgr:id="StopData1" msdata:rowOrder="0">
                            <ServiceDelivery_ResponseTimestamp>2019-03-24T17:18:21.763+00:00</ServiceDelivery_ResponseTimestamp>
                            <ServiceDelivery_ProducerRef>bac</ServiceDelivery_ProducerRef>
                            <ServiceDelivery_Status>true</ServiceDelivery_Status>
                            <ServiceDelivery_MoreData>false</ServiceDelivery_MoreData>
                            <StopMonitoringDelivery_Version>1.0</StopMonitoringDelivery_Version>
                            <StopMonitoringDelivery_ResponseTimestamp>2019-03-24T17:18:21.763+00:00</StopMonitoringDelivery_ResponseTimestamp>
                            <StopMonitoringDelivery_RequestMessageRef />
                            <MonitoredStopVisit_RecordedAtTime>2019-03-24T17:18:21.763+00:00</MonitoredStopVisit_RecordedAtTime>
                            <MonitoredStopVisit_MonitoringRef>3982</MonitoredStopVisit_MonitoringRef>
                            <MonitoredVehicleJourney_LineRef>26</MonitoredVehicleJourney_LineRef>
                            <MonitoredVehicleJourney_DirectionRef>Inbound</MonitoredVehicleJourney_DirectionRef>
                            <FramedVehicleJourneyRef_DataFrameRef>2019-03-24</FramedVehicleJourneyRef_DataFrameRef>
                            <FramedVehicleJourneyRef_DatedVehicleJourneyRef>15621</FramedVehicleJourneyRef_DatedVehicleJourneyRef>
                            <MonitoredVehicleJourney_PublishedLineName>66</MonitoredVehicleJourney_PublishedLineName>
                            <MonitoredVehicleJourney_OperatorRef>bac</MonitoredVehicleJourney_OperatorRef>
                            <MonitoredVehicleJourney_DestinationRef>7387</MonitoredVehicleJourney_DestinationRef>
                            <MonitoredVehicleJourney_DestinationName>Merrion Sq via Palmerstown</MonitoredVehicleJourney_DestinationName>
                            <MonitoredVehicleJourney_Monitored>true</MonitoredVehicleJourney_Monitored>
                            <MonitoredVehicleJourney_InCongestion>false</MonitoredVehicleJourney_InCongestion>
                            <MonitoredVehicleJourney_BlockRef>66004</MonitoredVehicleJourney_BlockRef>
                            <MonitoredVehicleJourney_VehicleRef>4444</MonitoredVehicleJourney_VehicleRef>
                            <MonitoredCall_VisitNumber>4</MonitoredCall_VisitNumber>
                            <MonitoredCall_VehicleAtStop>false</MonitoredCall_VehicleAtStop>
                            <MonitoredCall_AimedArrivalTime>2019-03-24T17:34:55+00:00</MonitoredCall_AimedArrivalTime>
                            <MonitoredCall_ExpectedArrivalTime>2019-03-24T17:34:55+00:00</MonitoredCall_ExpectedArrivalTime>
                            <MonitoredCall_AimedDepartureTime>2019-03-24T17:34:55+00:00</MonitoredCall_AimedDepartureTime>
                            <MonitoredCall_ExpectedDepartureTime>2019-03-24T17:34:55+00:00</MonitoredCall_ExpectedDepartureTime>
                            <Timestamp>2019-03-24T17:18:22.347+00:00</Timestamp>
                            <LineNote />
                        </StopData>
                    </DocumentElement>
                </diffgr:diffgram>
            </GetRealTimeStopDataResult>
        </GetRealTimeStopDataResponse>
    </soap:Body>
</soap:Envelope> 
""";