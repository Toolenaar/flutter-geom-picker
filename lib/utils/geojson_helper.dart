import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:geojson_vi/geojson_vi.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

Map<String, dynamic> testData = {
  'type': 'Polygon',
  'coordinates': [
    [
      [4.805216981866778, 51.7845616244648],
      [4.478334753476645, 51.51500925665596],
      [5.417816315900325, 51.276473496523494],
      [5.763031518782213, 51.755082721977544],
      [4.805216981866778, 51.7845616244648]
    ]
  ]
};

class GeoJsonHelper {
  static bool isPointInPolygon(LatLng point, List<LatLng> vertices) {
    int intersectCount = 0;
    for (int i = 0; i < vertices.length; i += 1) {
      final LatLng vertB = i == vertices.length - 1 ? vertices[0] : vertices[i + 1];
      if (GeoJsonHelper.rayCastIntersect(point, vertices[i], vertB)) {
        intersectCount += 1;
      }
    }
    return (intersectCount % 2) == 1;
  }

  /// Ray-Casting algorithm implementation
  /// Calculate whether a horizontal ray cast eastward from [point]
  /// will intersect with the line between [vertA] and [vertB]
  /// Refer to `https://en.wikipedia.org/wiki/Point_in_polygon` for more explanation
  /// or the example comment bloc at the end of this file
  static bool rayCastIntersect(LatLng point, LatLng vertA, LatLng vertB) {
    final double aY = vertA.latitude;
    final double bY = vertB.latitude;
    final double aX = vertA.longitude;
    final double bX = vertB.longitude;
    final double pY = point.latitude;
    final double pX = point.longitude;

    if ((aY > pY && bY > pY) || (aY < pY && bY < pY) || (aX < pX && bX < pX)) {
      // The case where the ray does not possibly pass through the polygon edge,
      // because both points A and B are above/below the line,
      // or both are to the left/west of the starting point
      // (as the line travels eastward into the polygon).
      // Therefore we should not perform the check and simply return false.
      // If we did not have this check we would get false positives.
      return false;
    }

    // y = mx + b : Standard linear equation
    // (y-b)/m = x : Formula to solve for x

    // M is rise over run -> the slope or angle between vertices A and B.
    final double m = (aY - bY) / (aX - bX);
    // B is the Y-intercept of the line between vertices A and B
    final double b = ((aX * -1) * m) + aY;
    // We want to find the X location at which a flat horizontal ray at Y height
    // of pY would intersect with the line between A and B.
    // So we use our rearranged Y = MX+B, but we use pY as our Y value
    final double x = (pY - b) / m;

    // If the value of X
    // (the x point at which the ray intersects the line created by points A and B)
    // is "ahead" of the point's X value, then the ray can be said to intersect with the polygon.
    return x > pX;
  }

  static LatLng getBBoxCenter(List<double> points) {
    var point1 = LatLng(points[1], points[0]);
    var point2 = LatLng(points[3], points[2]);

    var midLat = (point1.latitude + point2.latitude) / 2;

    var midLng = (point1.longitude + point2.longitude) / 2;
    return LatLng(midLat, midLng);
  }

  static LatLng getCenterLatLong(List<LatLng> latLongList) {
    double pi = math.pi / 180;
    double xpi = 180 / math.pi;
    double x = 0, y = 0, z = 0;

    if (latLongList.length == 1) {
      return latLongList[0];
    }
    for (int i = 0; i < latLongList.length; i++) {
      double latitude = latLongList[i].latitude * pi;
      double longitude = latLongList[i].longitude * pi;
      double c1 = math.cos(latitude);
      x = x + c1 * math.cos(longitude);
      y = y + c1 * math.sin(longitude);
      z = z + math.sin(latitude);
    }

    int total = latLongList.length;
    x = x / total;
    y = y / total;
    z = z / total;

    double centralLongitude = math.atan2(y, x);
    double centralSquareRoot = math.sqrt(x * x + y * y);
    double centralLatitude = math.atan2(z, centralSquareRoot);

    return LatLng(centralLatitude * xpi, centralLongitude * xpi);
  }

  static GeoJSONPolygon parsePolygons(Map<String, dynamic> data) {
    return GeoJSONPolygon.fromMap(data);
  }

  static GeoJSONPolygon polygonFromLatLngs(List<LatLng> latLngs) {
    var coords = latLngs.map((e) => [e.longitude, e.latitude]).toList();

    var data = {
      'type': 'Polygon',
      'coordinates': [coords]
    };

    return GeoJSONPolygon.fromMap(data);
  }

  static GeoJSONPolygon polygonFromLatLngsList(List<List<LatLng>> latLngsList) {
    var coordsList = <List<List<dynamic>>>[];
    for (var latlngs in latLngsList) {
      coordsList.add(latlngs.map((e) => [e.longitude, e.latitude]).toList());
    }

    var data = {'type': 'Polygon', 'coordinates': coordsList};

    return GeoJSONPolygon.fromMap(data);
  }

  static List<List<LatLng>> latLngListFromPolygon(GeoJSONPolygon poly) {
    var coordsList = <List<LatLng>>[];

    for (var coords in poly.coordinates) {
      coordsList.add(coords.map((e) => LatLng(e[1], e[0])).toList());
    }

    return coordsList;
  }

  static List<Polygon> createMapPolygons(GeoJSONPolygon pointsList, {Color? color}) {
    var polygons = <Polygon>[];
    for (var points in pointsList.coordinates) {
      var coords = points.map((e) => LatLng(e[1], e[0])).toList();
      polygons.add(GeoJsonHelper.createMapPolygon(points: coords, color: color ?? Colors.red));
    }
    return polygons;
  }

  static Polygon createMapPolygon(
      {required List<LatLng> points,
      Color color = Colors.red,
      double borderWidth = 2.0,
      List<List<LatLng>>? holePointsList,
      Color borderColor = Colors.black}) {
    return Polygon(
        points: points,
        color: color,
        isFilled: true,
        borderStrokeWidth: borderWidth,
        borderColor: borderColor,
        holePointsList: holePointsList);
  }
}

class PolygonCreator {
  List<List<LatLng>> polygons = [];

  List<LatLng> currentPolygon = [];

  GeoJSONPolygon addPoint(LatLng latLng) {
    currentPolygon.add(latLng);
    return GeoJsonHelper.polygonFromLatLngs(currentPolygon);
  }

  GeoJSONPolygon previewPolygon(LatLng latLng) {
    return GeoJsonHelper.polygonFromLatLngs([...currentPolygon, latLng]);
  }

  GeoJSONPolygon createPolygon() {
    polygons.add(currentPolygon);
    currentPolygon = [];
    return GeoJsonHelper.polygonFromLatLngsList(polygons);
  }

  GeoJSONPolygon setupFromJson(String json) {
    var polygon = GeoJSONPolygon.fromJSON(json);
    polygons = GeoJsonHelper.latLngListFromPolygon(polygon);
    return polygon;
  }

  clear() {
    polygons = [];
    currentPolygon = [];
  }
}

class Area {
  final String id;
  final String name;
  final String geometry;
  late final GeoJSONPolygon polygon;

  Area({required this.name, required this.geometry, required this.id}) {
    polygon = GeoJSONPolygon.fromJSON(geometry);
  }

  bool pointIsWithinPolygon(LatLng latLng) {
    bool isWithin = false;
    isWithin =
        GeoJsonHelper.isPointInPolygon(latLng, polygon.coordinates.first.map((e) => LatLng(e[1], e[0])).toList());
    return isWithin;
  }
}
