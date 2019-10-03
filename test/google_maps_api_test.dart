import 'package:flutter_test/flutter_test.dart';

import 'package:google_maps_api/google_maps_api.dart';

void main() {
  final apiKey = 'API_KEY';

  test('adds one to input values', () async {
    final googleMapsAPI = GoogleMapsAPI(apiKey);

    final origin = {"latitude": -0.1813596, "longitude": -78.444548};
    final destination = {"latitude": -0.159386, "longitude": -78.4818357};

    final routes = await googleMapsAPI.getTravelData(
        origin: origin, destination: destination,alternatives: true);


    print("routes ${routes.length}");



//    final calculator = Calculator();
//    expect(calculator.addOne(2), 3);
//    expect(calculator.addOne(-7), -6);
//    expect(calculator.addOne(0), 1);
//    expect(() => calculator.addOne(null), throwsNoSuchMethodError);
  });
}
