import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_geom_picker/map_helper.dart';
import 'package:flutter_geom_picker/utils/geojson_helper.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:geojson_vi/geojson_vi.dart';
import 'package:latlong2/latlong.dart';

class GeomPickerMapView extends StatefulWidget {
  const GeomPickerMapView({super.key});

  @override
  State<GeomPickerMapView> createState() => _GeomPickerMapViewViewState();
}

class _GeomPickerMapViewViewState extends State<GeomPickerMapView> {
  final MapController _mapController = MapController();
  final PolygonCreator _polyCreator = PolygonCreator();
  GeoJSONPolygon? _previewPolygon;

  List<Polygon> _savedPolygons = [];

  LatLng? _currentPoint;
  Polyline? _previewLine;
  List<Polyline> _polyLines = [];
  final Color _polyColor = Colors.red.withOpacity(0.2);
  final Color _lineColor = Colors.black;
  List<Marker> _markers = [];

  List<Polygon>? _previewPolygons;

  GeoJSONPolygon? _savedPolygon;

  @override
  void initState() {
    //_loadData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  center: LatLng(52.11635277208204, 5.080875271082007),
                  //heemskerk
                  //onTap: (_) => _popupLayerController.hidePopup(),
                  onTap: (position, latLng) {
                    _addPoint(latLng);
                  },

                  onPointerHover: (event, latLng) {
                    _drawPreviewLine(latLng);
                  },
                  interactiveFlags: InteractiveFlag.pinchZoom |
                      InteractiveFlag.drag |
                      InteractiveFlag.doubleTapZoom |
                      InteractiveFlag.flingAnimation |
                      InteractiveFlag.pinchMove,
                ),
                children: [
                  TileLayer(
                    urlTemplate: MapHelper.MAPBOX_URL,
                  ),
                  PolygonLayer(polygons: getPolygons()),
                  PolylineLayer(
                    polylines: _previewLine == null ? [] : [_previewLine!],
                  ),
                  MarkerLayer(markers: _markers)
                ],
              ),
              Positioned(
                right: 16,
                top: 16,
                child: IconButton(
                  icon: Icons.delete,
                  onTap: _clearData,
                ),
              )
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: JsonView(
            json: _jsonViewPolygon(),
          ),
        )
      ],
    );
  }

  List<Polygon> getPolygons() {
    var preview = _previewPolygons ?? [];
    return [..._savedPolygons, ...preview];
  }

  // Future _loadData() async {
  //   _polygon = GeoJsonHelper.parsePolygons(testData);

  //   _polygons = GeoJsonHelper.createMapPolygons(
  //     _polygon!,
  //     color: _polyColor,
  //   );
  //   setState(() {});
  // }

  void _addPoint(LatLng latLng) async {
    if (_currentPoint == null) {
      _addStartPointMarker(latLng);
    }
    print('add point');
    _currentPoint = latLng;
    // if (previousPoint != null && _currentPoint != null) {
    //   _polyLines.add(Polyline(color: _lineColor, strokeWidth: 2, points: [previousPoint, _currentPoint!]));
    // }

    _previewPolygon = _polyCreator.addPoint(latLng);
    _previewPolygons = GeoJsonHelper.createMapPolygons(_previewPolygon!, color: Colors.red.withOpacity(0.2));
    setState(() {});
  }

  void _drawPreviewLine(LatLng latLng) {
    if (_currentPoint == null) return;
    _previewLine = Polyline(color: _lineColor, strokeWidth: 2, points: [_currentPoint!, latLng]);

    _previewPolygon = _polyCreator.previewPolygon(latLng);

    _previewPolygons = GeoJsonHelper.createMapPolygons(
      _previewPolygon!,
      color: Colors.red.withOpacity(0.2),
    );
    setState(() {});
  }

  _addStartPointMarker(LatLng latLng) {
    var startMarker = Marker(
      point: latLng,
      width: 16,
      height: 16,
      builder: (context) => StartMarkerView(onTap: _savePolygon),
    );
    _markers = [startMarker];
  }

  _savePolygon() {
    _polyCreator.addPoint(_markers.first.point); //close the polygon
    _savedPolygon = _polyCreator.createPolygon();
    _savedPolygons = GeoJsonHelper.createMapPolygons(_savedPolygon!, color: Colors.red.withOpacity(0.2));
    _currentPoint = null;
    _previewLine = null;
    _previewPolygon = null;
    _previewPolygons = [];
    _markers = [];
    setState(() {});
  }

  _jsonViewPolygon() {
    if (_polyCreator.currentPolygon.isEmpty && _polyCreator.polygons.isEmpty) return;
    if (_polyCreator.currentPolygon.isEmpty) return GeoJsonHelper.polygonFromLatLngsList(_polyCreator.polygons);
    var created = _polyCreator.polygons;
    var current = _polyCreator.currentPolygon;
    return GeoJsonHelper.polygonFromLatLngsList([...created, current]);
  }

  _clearData() {
    _polyCreator.clear();
    _currentPoint = null;
    _previewLine = null;
    _previewPolygon = null;
    _previewPolygons = [];
    _markers = [];
    _savedPolygons = [];
    _savedPolygon = null;
    setState(() {});
  }
}

class JsonView extends StatelessWidget {
  final GeoJSONPolygon? json;
  const JsonView({super.key, required this.json});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      color: Colors.white,
      child: SelectableText(
        json == null ? "" : prettyString(),
      ),
    );
  }

  String prettyString() {
    final object = jsonDecode(json!.toJSON());
    return const JsonEncoder.withIndent('  ').convert(object);
  }
}

class StartMarkerView extends StatelessWidget {
  final Function() onTap;
  const StartMarkerView({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class IconButton extends StatelessWidget {
  final Function() onTap;
  final IconData icon;
  const IconButton({super.key, required this.onTap, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(42),
      child: InkWell(
        borderRadius: BorderRadius.circular(42),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(42)),
          child: Center(
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
