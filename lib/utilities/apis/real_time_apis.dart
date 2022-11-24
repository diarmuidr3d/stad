import 'dart:core';

import 'package:http/http.dart' as http;
import 'package:stad/models/locatable.dart';
import 'package:xpath/xpath.dart';

import 'package:stad/models/models.dart';

import '../../models/trip.dart';
import 'bus_eireann.dart';

abstract class RealTimeAPI {

  Future<List<Timing>> getTimings(String stopCode);

  Future<GeoLocation?> getVehicleLocationForTrip(Trip trip);
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
    
    final dublinBusRTPI = Uri.http('rtpi.dublinbus.ie', '/DublinBusRTPIService.asmx');

    http.Response response =
      await http.post(dublinBusRTPI,
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
    Timing details = new Timing(
      route: element.xpath('/MonitoredVehicleJourney_PublishedLineName/text()')[0].name,
      heading: element.xpath('/MonitoredVehicleJourney_DestinationName/text()')[0].name,
      dueMins: DateTime.parse(
            element.xpath('/MonitoredCall_ExpectedDepartureTime/text()')[0].name)
            .difference(DateTime.now()).inMinutes,
      inbound: element.xpath('/MonitoredVehicleJourney_DirectionRef/text()')[0].name == "Inbound" ? 1 : 0,
      realTime: element.xpath('/MonitoredVehicleJourney_Monitored/text()')[0].name == "true" ? true : false,
    );
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

  @override
  Future<GeoLocation?> getVehicleLocationForTrip(Trip trip) {
    // TODO: implement getVehicleLocation
    throw UnimplementedError();
  }

}

class IarnrodEireannAPI  implements RealTimeAPI {
  
  Future<ETree> _getRealTimeStopDataTree(String stopCode) async {
    final irishRailRTPI = Uri.http(
        'api.irishrail.ie',
        '/realtime/realtime.asmx/getStationDataByCodeXML',
        {'StationCode': stopCode}
    );
    http.Response response = await http.get(irishRailRTPI);
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
        Timing details = new Timing(
          route: element.xpath('/Traincode/text()')[0].name,
          heading: element.xpath('/Destination/text()')[0].name,
          journeyReference: element.xpath('/Traincode/text()')[0].name,
          dueMins: int.parse(element.xpath('/Duein/text()')[0].name),
        );
//        TODO: Figure out how to parse direction for irish rail
//        details.inbound = element.xpath('/MonitoredVehicleJourney_DirectionRef/text()')[0].name == "Inbound" ? 1 : 0;
        return details;
      }).toList();
    }
    return timings;
  }

  @override
  Future<GeoLocation?> getVehicleLocationForTrip(Trip trip) {
    // TODO: implement getVehicleLocation
    throw UnimplementedError();
  }

}



class LuasAPI  implements RealTimeAPI {

  Future<ETree> _getRealTimeStopDataTree(String stopCode) async {
    final luasRTPI = Uri.http(
        'luasforecasts.rpa.ie',
        '/xml/get.ashx',
        {
          'action': 'forecast',
          'encrypt': 'false',
          'stop': stopCode,
        }
    );
    http.Response response = await http.get(luasRTPI);
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

  @override
  Future<GeoLocation?> getVehicleLocationForTrip(Trip trip) {
    // TODO: implement getVehicleLocation
    throw UnimplementedError();
  }

}

class RealTimeUtilities {

  static Future<RealTimeStopData> getStopTimings(Stop stop) async {
    final stopData = RealTimeStopData(stop: stop);
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
        case null:
          throw Exception("No operator for stop ${stop.stopCode}");
      }
    } catch (SocketException) {}
    if (stopData.timings != null) stopData.timings!.sort((a, b) => a.dueMins.compareTo(b.dueMins));
    return stopData;
  }

  Future<List<StopVisited>> searchForBus(int left, int right, List<StopVisited> stopList, String journeyRef, Function callback) async {
    return DublinBusAPI().searchForBus(left, right, stopList, journeyRef, callback);
  }
}
