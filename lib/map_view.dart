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

  List<Area> _savedAreas = [];

  LatLng? _currentPoint;
  Polyline? _previewLine;
  final Color _lineColor = Colors.black;
  List<Marker> _markers = [];

  List<Polygon>? _previewPolygons;

  GeoJSONPolygon? _savedPolygon;
  bool _isEditing = false;
  int geomId = 0;
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
                    _onTap(latLng);
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
    var polygons = [];

    if (_savedAreas.isNotEmpty) {
      for (var area in _savedAreas) {
        polygons.addAll(GeoJsonHelper.createMapPolygons(area.polygon, color: Colors.red.withOpacity(0.2)));
      }
    }

    return [...polygons, ...preview];
  }

  // Future _loadData() async {
  //   _polygon = GeoJsonHelper.parsePolygons(testData);

  //   _polygons = GeoJsonHelper.createMapPolygons(
  //     _polygon!,
  //     color: _polyColor,
  //   );
  //   setState(() {});
  // }

  void _onTap(LatLng latLng) async {
    if (_isEditing) {
      _addPoint(latLng);
      return;
    }
    //if within existing poly show name marker
    bool isWithin = false;
    if (_savedAreas.isNotEmpty) {
      for (var area in _savedAreas) {
        if (area.pointIsWithinPolygon(latLng)) {
          isWithin = true;
          //show
          _addNameMarker(area);
        }
      }
    }
    //start new geom
    if (!isWithin) {
      _addPoint(latLng);
    }
  }

  void _addPoint(LatLng latLng) async {
    _isEditing = true;
    if (_currentPoint == null) {
      _addStartPointMarker(latLng);
    }
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
      key: const ValueKey('startMarker'),
      point: latLng,
      width: 16,
      height: 16,
      builder: (context) => StartMarkerView(onTap: _savePolygon),
    );
    _markers = [startMarker];
  }

  _savePolygon() {
    _isEditing = false;
    _polyCreator.addPoint(_markers.first.point); //close the polygon
    _savedPolygon = _polyCreator.createPolygon();

    _savedAreas.add(Area(geometry: _savedPolygon!.toJSON(), name: 'test', id: geomId.toString()));
    geomId += 1;

    _currentPoint = null;
    _previewLine = null;
    _previewPolygon = null;
    _previewPolygons = [];
    _markers = [];
    _polyCreator.clear();
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
    _savedAreas = [];
    _savedPolygon = null;
    setState(() {});
  }

  _addNameMarker(Area area) {
    var exists = _markers.where((e) => e.key == ValueKey(area.id));
    if (exists.isNotEmpty) {
      _markers.remove(exists.first);
    } else {
      var center = GeoJsonHelper.getBBoxCenter(area.polygon.bbox);
      var center2 =
          GeoJsonHelper.getCenterLatLong(area.polygon.coordinates.first.map((e) => LatLng(e[1], e[0])).toList());
      print(center);
      print(center2);
      _markers.add(
        Marker(
          width: 300,
          height: 90,
          anchorPos: AnchorPos.align(AnchorAlign.center),
          key: ValueKey(area.id),
          point: center,
          builder: (context) => NameMarkerView(
            onTap: () {},
            name: area.name,
          ),
        ),
      );
    }

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
        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class NameMarkerView extends StatelessWidget {
  final String name;
  final Function()? onTap;
  const NameMarkerView({super.key, required this.name, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Text(
            name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black),
          ),
        ),
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
