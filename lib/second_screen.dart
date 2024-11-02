import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/directions.dart' as directions;

class SecondScreen extends StatefulWidget {
  const SecondScreen({super.key});

  @override
  State<SecondScreen> createState() => _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen> {
  late GoogleMapController mapController;
  LatLng _currentPosition = const LatLng(-12.04318, -77.02824);
  Marker? _startMarker;
  Marker? _destinationMarker;
  Set<Polyline> _polylines = {};
  bool _startSelected = false;
  bool _destinationSelected = false;
  bool _isSearchEnabled = false;
  List<String> _walkingDirectionsStart = [];
  List<String> _walkingDirectionsEnd = [];
  String _routeName = "";
  bool _isDirectionsVisible = true; // Controla la visibilidad del widget de direcciones

  final directions.GoogleMapsDirections _directions =
      directions.GoogleMapsDirections(apiKey: 'AIzaSyDvuGaBnucJOW_EvD-e4yNKj553jEiynSs');

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Los servicios de ubicación están deshabilitados.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Los permisos de ubicación han sido denegados.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Los permisos de ubicación han sido denegados permanentemente.');
    }

    Position position = await Geolocator.getCurrentPosition();
    _currentPosition = LatLng(position.latitude, position.longitude);
    mapController.animateCamera(
      CameraUpdate.newLatLngZoom(_currentPosition, 14),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _setStartLocation(LatLng location) {
    setState(() {
      _startMarker = Marker(
        markerId: const MarkerId('start'),
        position: location,
        infoWindow: const InfoWindow(title: 'Ubicación de Inicio'),
      );
      _startSelected = true;
    });
  }

  void _setDestinationLocation(LatLng location) {
    setState(() {
      _destinationMarker = Marker(
        markerId: const MarkerId('destination'),
        position: location,
        infoWindow: const InfoWindow(title: 'Ubicación de Destino'),
      );
      _destinationSelected = true;
      _isSearchEnabled = true;
    });
  }

  Future<void> _showRoute() async {
  if (!_startSelected || !_destinationSelected) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seleccione ambas ubicaciones de inicio y destino')),
    );
    return;
  }

  Set<Polyline> polylines = {};

  final nearestStop = await _getNearestStop();

  // Obtener direcciones de caminata hacia la parada más cercana
  final walkToStartRoute = await _getWalkingRoute(_currentPosition, nearestStop);
  if (walkToStartRoute != null) {
    _walkingDirectionsStart = await _getWalkingDirections(_currentPosition, nearestStop);
    polylines.add(walkToStartRoute);
  }

  // Obtener rutas de transporte público y el nombre de la ruta
  final transportRoutes = await _getOptimalTransportRoutes(nearestStop, _destinationMarker!.position);
  polylines.addAll(transportRoutes);

  if (transportRoutes.isNotEmpty) {
    _routeName = await _getRouteName(transportRoutes.first.polylineId.value);
  }

  // Obtener direcciones de caminata desde la última parada hasta el destino
  final finalWalk = await _getWalkingRoute(transportRoutes.last.points.last, _destinationMarker!.position);
  if (finalWalk != null) {
    _walkingDirectionsEnd = await _getWalkingDirections(transportRoutes.last.points.last, _destinationMarker!.position);
    polylines.add(finalWalk);
  }

  setState(() {
    _polylines = polylines;
  });
}

Future<List<String>> _getWalkingDirections(LatLng start, LatLng end) async {
  final response = await _directions.directionsWithLocation(
    directions.Location(lat: start.latitude, lng: start.longitude),
    directions.Location(lat: end.latitude, lng: end.longitude),
    travelMode: directions.TravelMode.walking,
  );

  if (response.isOkay) {
    return response.routes.first.legs.first.steps
        .map((step) => step.htmlInstructions.replaceAll(RegExp(r'<[^>]*>'), ''))
        .toList();
  } else {
    print("Error en la respuesta de Directions API: ${response.errorMessage}");
    return [];
  }
}

Future<String> _getRouteName(String routeId) async {
  final doc = await FirebaseFirestore.instance.collection('public_transport_routes').doc(routeId).get();
  return doc.exists ? doc['route_name'] : 'Ruta desconocida';
}


  Future<LatLng> _getNearestStop() async {
    final snapshot = await FirebaseFirestore.instance.collection('public_transport_routes').get();
    LatLng nearestStop = _currentPosition;
    double minDistance = double.infinity;

    for (var doc in snapshot.docs) {
      List<LatLng> stops = (doc['stops'] as List)
          .map((stop) => LatLng((stop as GeoPoint).latitude, (stop as GeoPoint).longitude))
          .toList();

      for (var stop in stops) {
        final distance = Geolocator.distanceBetween(
          _currentPosition.latitude,
          _currentPosition.longitude,
          stop.latitude,
          stop.longitude,
        );
        if (distance < minDistance) {
          minDistance = distance;
          nearestStop = stop;
        }
      }
    }
    return nearestStop;
  }

  Future<Polyline?> _getWalkingRoute(LatLng start, LatLng end) async {
    final response = await _directions.directionsWithLocation(
      directions.Location(lat: start.latitude, lng: start.longitude),
      directions.Location(lat: end.latitude, lng: end.longitude),
      travelMode: directions.TravelMode.walking,
    );

    if (response.isOkay) {
      final points = _convertToLatLng(response.routes[0].overviewPolyline.points);
      return Polyline(
        polylineId: PolylineId('walk_route_${start}_${end}'),
        points: points,
        color: Colors.black,
        patterns: [PatternItem.dot, PatternItem.gap(10)],
        width: 3,
      );
    } else {
      print("Error en la respuesta de Directions API: ${response.errorMessage}");
    }
    return null;
  }

  Future<Set<Polyline>> _getOptimalTransportRoutes(LatLng start, LatLng end) async {
    final snapshot = await FirebaseFirestore.instance.collection('public_transport_routes').get();
    Set<Polyline> optimalRoutes = {};

    for (var doc in snapshot.docs) {
      List<LatLng> routePoints = (doc['stops'] as List)
          .map((stop) => LatLng((stop as GeoPoint).latitude, (stop as GeoPoint).longitude))
          .toList();

      optimalRoutes.add(Polyline(
        polylineId: PolylineId(doc.id),
        points: routePoints,
        color: Color(int.parse("0xFF${doc['color'].substring(1)}")),
        width: 5,
      ));
    }
    return optimalRoutes;
  }

  List<LatLng> _convertToLatLng(String encoded) {
    List<LatLng> poly = [];
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

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Seleccionar Ruta',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blueGrey,
        elevation: 0,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 14.0,
            ),
            markers: {
              if (_startMarker != null) _startMarker!,
              if (_destinationMarker != null) _destinationMarker!,
            },
            polylines: _polylines,
            myLocationEnabled: true,
            onTap: (LatLng position) {
              if (_startSelected && !_destinationSelected) {
                _setDestinationLocation(position);
              } else if (!_startSelected) {
                _setStartLocation(position);
              }
            },
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: !_startSelected
                          ? () => _getUserLocation()
                          : () => _setStartLocation(_currentPosition),
                      icon: const Icon(Icons.my_location, color: Colors.white),
                      label: const Text('Ubicación de Inicio'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: !_destinationSelected
                          ? () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Seleccione destino')),
                              )
                          : _showRoute,
                      icon: const Icon(Icons.directions, color: Colors.white),
                      label: const Text('Mostrar Ruta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Widget de direcciones con funcionalidad de minimizar y expandir
          Positioned(
            bottom: 150,
            left: 20,
            right: 20,
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Direcciones",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: Icon(_isDirectionsVisible
                              ? Icons.expand_less
                              : Icons.expand_more),
                          onPressed: () {
                            setState(() {
                              _isDirectionsVisible = !_isDirectionsVisible;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_isDirectionsVisible) ...[
                      Text("Direcciones hacia la parada más cercana:"),
                      ..._walkingDirectionsStart.map((step) => Text("- $step")),
                      const SizedBox(height: 10),
                      Text("Ruta de transporte público: $_routeName"),
                      const SizedBox(height: 10),
                      Text("Direcciones desde la última parada hasta el destino:"),
                      ..._walkingDirectionsEnd.map((step) => Text("- $step")),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}