import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:xpath/xpath.dart';

import 'package:stad/models.dart';
import 'package:stad/utilities/database.dart';

abstract class RealTimeAPI {

  Future<List<Timing>> getTimings(String stopCode);
}

class DublinBusAPI implements RealTimeAPI {

  Future<ETree> _getRealTimeStopDataTree(String stopCode) async {
    var envelope =
    '''<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
    <soap:Body>
    <GetRealTimeStopData xmlns="http://dublinbus.ie/">
    <forceRefresh>false</forceRefresh>
    <stopId>$stopCode</stopId>
    </GetRealTimeStopData>
    </soap:Body>
    </soap:Envelope>''';

    http.Response response =
      await http.post('http://rtpi.dublinbus.ie/DublinBusRTPIService.asmx',
        headers: {
          "Content-Type": "text/xml; charset=utf-8",
          "SOAPAction": "http://dublinbus.ie/GetRealTimeStopData",
          "Host": "rtpi.dublinbus.ie",
          "User-Agent": "okhttp/3.11.0"
        },
        body: envelope);

    final respBody = response.body.substring(response.body.indexOf('>') + 1); // Removes the xml artifact from the start of the response so it can be parsed
    return ETree.fromString(respBody);
  }

  @override
  Future<List<Timing>> getTimings(String stopCode) async {
    var tree = await _getRealTimeStopDataTree(stopCode);
    final xmlStopData = tree.xpath('/soap/soap/GetRealTimeStopDataResponse/GetRealTimeStopDataResult/diffgr/DocumentElement/StopData');
    var timings;
    if (xmlStopData != null) {
      timings = xmlStopData.map(getDetailsFromStopDataXml).toList();
    }
    return timings;
  }

  static Timing getDetailsFromStopDataXml(element) {
    Timing details = new Timing();
    details.route = element.xpath('/MonitoredVehicleJourney_PublishedLineName/text()')[0].name;
    details.heading = element.xpath('/MonitoredVehicleJourney_DestinationName/text()')[0].name;
    details.dueMins = DateTime.parse(
        element.xpath('/MonitoredCall_ExpectedDepartureTime/text()')[0].name)
        .difference(DateTime.now()).inMinutes;
    details.inbound = element.xpath('/MonitoredVehicleJourney_DirectionRef/text()')[0].name == "Inbound" ? 1 : 0;
    details.realTime = element.xpath('/MonitoredVehicleJourney_Monitored/text()')[0].name == "true" ? true : false;
    final journeyElement = element.xpath('/MonitoredVehicleJourney_VehicleRef/text()');
    if (journeyElement != null) details.journeyReference = journeyElement[0].name;
    return details;
  }

  Future<bool> stopHasJourneyDue(String stopCode, String journeyRef) async {
    final tree = await _getRealTimeStopDataTree(stopCode);
    final xmlStopData = tree.xpath('/soap/soap/GetRealTimeStopDataResponse/GetRealTimeStopDataResult/diffgr/DocumentElement/StopData/MonitoredVehicleJourney_VehicleRef/text()');
    if (xmlStopData != null) {
      for (final element in xmlStopData) {
        final journeyReference = element.name;
        if (journeyReference == journeyRef) return true;
      }
    }
    print("no journey ref for " + stopCode + " - " + journeyRef);
    return false;
  }

  Future<List<StopVisited>> searchForBus(int left, int right, List<StopVisited> stopList, String journeyRef, Function callback) async {
    int curr = ((left + right) / 2).floor();
    final stop = stopList[curr];
    bool isDue = await stopHasJourneyDue(stop.stopCode, journeyRef);
    StopState state;
    if (isDue) {
      right = curr - 1;
      state = StopState.UNVISITED;
      callback(curr, stopList.length-1, state);
    } else {
      left = curr + 1;
      state = StopState.VISITED;
      callback(0, curr, state);
    }
    if (left > right) return stopList;
    return searchForBus(left, right, stopList, journeyRef, callback);
  }

}

class IarnrodEireannAPI  implements RealTimeAPI {
  
  Future<ETree> _getRealTimeStopDataTree(String stopCode) async {
    http.Response response = await http.get('http://api.irishrail.ie/realtime/realtime.asmx/getStationDataByCodeXML?StationCode=$stopCode');
    final respBody = response.body.substring(response.body.indexOf('>') + 1); // Removes the xml artifact from the start of the response so it can be parsed
    return ETree.fromString(respBody);
  }

  @override
  Future<List<Timing>> getTimings(String stopCode) async {
    var tree = await _getRealTimeStopDataTree(stopCode);
    final xmlStopData = tree.xpath('/ArrayOfObjStationData/objStationData');
    var timings;
    if (xmlStopData != null) {
      timings = xmlStopData.map((element){
        Timing details = new Timing();
        details.route = element.xpath('/Traincode/text()')[0].name;
        details.heading = element.xpath('/Destination/text()')[0].name;
        details.journeyReference = element.xpath('/Traincode/text()')[0].name;
        details.dueMins = int.parse(element.xpath('/Duein/text()')[0].name);
//        TODO: Figure out how to parse direction for irish rail
//        details.inbound = element.xpath('/MonitoredVehicleJourney_DirectionRef/text()')[0].name == "Inbound" ? 1 : 0;
        return details;
      }).toList();
    }
    return timings;
  }

}

class BusEireannAPI  implements RealTimeAPI {

  Future<Map<String, dynamic>> _getRealTimeStopDataTree(String stopCode) async {
    HttpClient client = new HttpClient();
    client.badCertificateCallback =((X509Certificate cert, String host, int port) => true);
    HttpClientRequest request = await client.openUrl("GET", Uri.parse('http://buseireann.ie/inc/proto/stopPassageTdi.php?stop_point=$stopCode'));
    HttpClientResponse response = await request.close();
    String reply = await response.transform(utf8.decoder).join();
    return jsonDecode(reply)["stopPassageTdi"];
  }

  @override
  Future<List<Timing>> getTimings(String stopCode) async {
    print(stopCode);
    var stopMap = await _getRealTimeStopDataTree(stopCode);
    print(stopMap);
    var timings = <Timing>[];
    for (var v in stopMap.values) {
      if (v != 0 && v["departure_data"] != null) {
        final departureData = v["departure_data"];
        if (departureData == null) break; // TODO: handle arrivals
        final routeNum = await RouteDB().getRouteNumForApiNum(
            v["route_duid"]["duid"]);
        final realTime = departureData["actual_passage_time_utc"] != null;
        final dueTime = realTime ? departureData["actual_passage_time_utc"] : departureData["scheduled_passage_time_utc"];
        final dueIn = DateTime.fromMillisecondsSinceEpoch(dueTime * 1000)
            .difference(DateTime.now()).inMinutes;
        if (dueIn > 0)
          timings.add(Timing(
            dueMins: dueIn,
            heading: departureData["multilingual_direction_text"]["defaultValue"],
            journeyReference: v["trip_duid"]["duid"],
            route: routeNum,
            realTime: realTime
          ));
      }
    }
    return timings;
  }

}

class LuasAPI  implements RealTimeAPI {

  Future<ETree> _getRealTimeStopDataTree(String stopCode) async {
    http.Response response = await http.get('http://luasforecasts.rpa.ie/xml/get.ashx?action=forecast&encrypt=false&stop=$stopCode');
    print(response.body);
    return ETree.fromString(response.body);
  }

  @override
  Future<List<Timing>> getTimings(String stopCode) async {
    var tree = await _getRealTimeStopDataTree(stopCode);
    final xmlStopData = tree.xpath('/stopInfo/direction/tram');
    var timings = <Timing>[];
    if (xmlStopData != null) {
      for (var element in xmlStopData) {
        if(element.attributes["dueMins"] != "") {
          final dueMins = element.attributes["dueMins"] == "DUE" ? 0 : int.parse(element.attributes["dueMins"]);
          Timing details = new Timing(
            heading: element.attributes["destination"],
            dueMins: dueMins,
          );
//        TODO: Figure out how to parse direction, journey, route for luas
          timings.add(details);
        }
      };
    }
    return timings;
  }

}

class RealTimeUtilities {

  static Future<RealTimeStopData> getStopTimings(Stop stop) async {
    final stopData = RealTimeStopData(stop: stop);
    if (stop.operator == null) throw Exception("No operator for stop ${stop.stopCode}");
    try {
      switch (stop.operator) {
        case Operator.BusEireann:
          stopData.timings = await BusEireannAPI().getTimings(stop.apiStopCode);
          break;
        case Operator.DublinBus:
          stopData.timings = await DublinBusAPI().getTimings(stop.stopCode);
          break;
        case Operator.IarnrodEireann:
          stopData.timings =
          await IarnrodEireannAPI().getTimings(stop.stopCode);
          break;
        case Operator.Luas:
          stopData.timings = await LuasAPI().getTimings(stop.stopCode);
          break;
      }
    } catch (SocketException) {}
    if (stopData.timings != null) stopData.timings.sort((a, b) => a.dueMins.compareTo(b.dueMins));
    return stopData;
  }

  Future<List<StopVisited>> searchForBus(int left, int right, List<StopVisited> stopList, String journeyRef, Function callback) async {
    return DublinBusAPI().searchForBus(left, right, stopList, journeyRef, callback);
  }
}
