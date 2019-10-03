
import 'dart:math';
class GoogleDirection {
  final String start_address;
  final String end_address;
  final int distance;
  final int duration;
  final List<Point> polylinePoints;

  GoogleDirection(
      {this.start_address,
        this.end_address,
        this.distance,
        this.duration,
        this.polylinePoints});
}
