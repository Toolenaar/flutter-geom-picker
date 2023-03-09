import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:geojson_vi/geojson_vi.dart';
import 'package:latlong2/latlong.dart';

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
