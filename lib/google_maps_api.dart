library google_maps_api;

import 'package:flutter/material.dart';
import 'package:meta/meta.dart' show required;
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:google_maps_api/src/google_direction.dart';
export 'package:google_maps_api/src/google_direction.dart';

/// A Calculator.
class GoogleMapsAPI {
  String _apiKey;

  GoogleMapsAPI(this._apiKey);

  Future<List<dynamic>> searchPlace(String searchText) async {
    try {
      final url =
          "https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=${Uri.encodeFull(searchText)}&inputtype=textquery&fields=formatted_address,name,geometry&key=$_apiKey&language=es";

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        print(response.body);

        if (parsed['status'] == 'OK') {
          final result = parsed['candidates'];
          return result;
        }
        return null;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// gets the address and  city from one Location
  Future<dynamic> reverseGeocode(dynamic location) async {
    try {
      final url =
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=${location['latitude']},${location['longitude']}&key=$_apiKey';
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        if (parsed['status'] == 'OK') {
          final result = parsed['results'][0];
          final List<dynamic> address_components = result['address_components'];
          final city = getCity(address_components);
          final String address = result['formatted_address'];

          return {'address': address, 'city': city};
        }
        return null;
      }
      print("error getAddress null");
      return null;
    } catch (e) {
      print("error getAddress ${e.toString()}");
      return null;
    }
  }

  static String getCity(List<dynamic> address_components) {
    var city;

    for (var i = 0; i < address_components.length; i++) {
      final item = address_components[i];
      final List<dynamic> types = item['types'];
      final index = types.indexWhere((e) => e == 'locality');
      if (index != -1) {
        city = item['long_name'];
        break;
      }
    }
    // console.log('getCity', city);
    return city;
  }

  /// returns the best google direction for one especific origin and destination
  /// return [List<GoogleDirection>]
  Future<List<GoogleDirection>> getTravelData(
      {@required dynamic origin,
      @required dynamic destination,
      String mode = 'driving',
      bool alternatives = false,
      String language = 'es'}) async {
    List<GoogleDirection> routes = List();
    try {
      print(_apiKey);
      final url =
          'https://maps.googleapis.com/maps/api/directions/json?origin=${origin['latitude']},${origin['longitude']}&destination=${destination['latitude']},${destination['longitude']}&mode=$mode&alternatives=$alternatives&language=$language&key=$_apiKey';

      print(url);

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        print(data['status']);

        if (data['status'] == 'OK') {
          for (dynamic route in data['routes']) {
            final dynamic leg = route['legs'][0];

            final start_address = leg['start_address'] as String;
            final end_address = leg['end_address'] as String;

            final distance = leg['distance']['value'] as int;
            final duration = leg['duration']['value'] as int;

            final encodedPolyline = route["overview_polyline"]["points"];
            final polylinePoints = decodeEncodedPolyline(encodedPolyline);

            routes.add(GoogleDirection(
                start_address: start_address,
                end_address: end_address,
                distance: distance,
                duration: duration,
                encodedPolyline: encodedPolyline,
                polylinePoints: polylinePoints));
          }
        }
      }
      return routes;
    } catch (e) {
      print("error getTravelData ${e.toString()}");
      return routes;
    }
  }

  ///decode the google encoded string using Encoded Polyline Algorithm Format
  /// for more info about the algorithm check https://developers.google.com/maps/documentation/utilities/polylinealgorithm
  ///
  ///return [List]
  static List<math.Point> decodeEncodedPolyline(String encoded) {
    List<math.Point> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      math.Point p =
          new math.Point((lat / 1E5).toDouble(), (lng / 1E5).toDouble());
      poly.add(p);
    }
    return poly;
  }

  /// calculates the center of one array of coords
  static dynamic averageGeolocation(List<dynamic> coords) {
    if (coords.length == 1) {
      return coords[0];
    }

    var x = 0.0, y = 0.0, z = 0.0;

    for (var coord in coords) {
      final latitude = coord['latitude'] * math.pi / 180;
      final longitude = coord['longitude'] * math.pi / 180;

      x += math.cos(latitude) * math.cos(longitude);
      y += math.cos(latitude) * math.sin(longitude);
      z += math.sin(latitude);
    }

    final total = coords.length;

    x = x / total;
    y = y / total;
    z = z / total;

    final centralLongitude = math.atan2(y, x);
    final centralSquareRoot = math.sqrt(x * x + y * y);
    final centralLatitude = math.atan2(z, centralSquareRoot);

    return {
      'latitude': centralLatitude * 180 / math.pi,
      'longitude': centralLongitude * 180 / math.pi
    };
  }

  /// parse degrees to radians
  static double deg2rad(deg) {
    return deg * (math.pi / 180);
  }

  /// calculates the distance between two coords in km
  static double getDistanceInKM(dynamic position1, dynamic position2) {
    final lat1 = position1['latitude'];
    final lon1 = position1['longitude'];
    final lat2 = position2['latitude'];
    final lon2 = position2['longitude'];

    final R = 6371; // Radius of the earth in km
    final dLat = deg2rad(lat2 - lat1); // deg2rad below
    final dLon = deg2rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(deg2rad(lat1)) *
            math.cos(deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final d = R * c; // Distance in km

    return d;
  }

  ///
  static dynamic fitToCoordinates(List<dynamic> coords) {
    final centerMap = GoogleMapsAPI.averageGeolocation(coords);

    final linearDistance =
        GoogleMapsAPI.getDistanceInKM(coords[0], coords[coords.length - 1]);

    double radius = linearDistance / 2;
    double scale = radius / 0.3;
    final zoom = (16 - math.log(scale) / math.log(2));

    return {'center': centerMap, 'zoom': zoom};
  }
}
