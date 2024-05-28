import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';

void main() {
  runApp(MaterialApp(home: FullMap()));
}

class FullMap extends StatefulWidget {
  const FullMap();

  @override
  State createState() => FullMapState();
}

class FullMapState extends State<FullMap> {
  MapboxMap? mapboxMap;
  PointAnnotationManager? pointAnnotationManager;
  List<PointAnnotation> currentAnnotations = [];
  List<List<dynamic>> points = [];
  Timer? timer;

  @override
  void initState() {
    super.initState();
    fetchFlightData();
    timer = Timer.periodic(Duration(seconds: 10), (Timer t) => fetchFlightData());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> fetchFlightData() async {
    final url = Uri.parse('https://opensky-network.org/api/states/all');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final states = data['states'];

        if (states != null && states.isNotEmpty) {
          setState(() {
            points = states.map<List<dynamic>>((state) => [state[5], state[6]]).toList();
            updatePointAnnotations();
          });
        }
      } else {
        throw Exception('Failed to load flight data');
      }
    } catch (e) {
      print('Error fetching flight data: $e');
    }
  }

  Future<void> updatePointAnnotations() async {
    if (pointAnnotationManager == null || mapboxMap == null) return;

    // Clear existing annotations
    await pointAnnotationManager!.deleteAll();
    currentAnnotations.clear();

    // Load the image for the annotation
    final ByteData bytes = await rootBundle.load('assets/flight.png');
    final Uint8List list = bytes.buffer.asUint8List();

    // Add new annotations
    for (var point in points) {
      if (point[0] != null && point[1] != null) {
        PointAnnotationOptions pointOptions = PointAnnotationOptions(
          geometry: Point(coordinates: Position(point[0], point[1])).toJson(),
          image: list,
        );
        var annotation = await pointAnnotationManager!.create(pointOptions);
        currentAnnotations.add(annotation);
      }
    }
  }

  _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;
    pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    updatePointAnnotations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MapWidget(
        key: ValueKey("mapWidget"),
        onMapCreated: _onMapCreated,
        cameraOptions: CameraOptions(
          center: Point(coordinates: Position( 55.2708,25.2048,)).toJson(),
          zoom: 8.0,
        ),
        styleUri: "mapbox://styles/mapbox/streets-v9/",
      ),
    );
  }
}
