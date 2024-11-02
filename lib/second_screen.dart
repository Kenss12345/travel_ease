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

  final directions.GoogleMapsDirections _directions =
      directions.GoogleMapsDirections(apiKey: 'TU_API_KEY');

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
        SnackBar(content: Text('Seleccione ambas ubicaciones de inicio y destino')),
      );
      return;
    }

    Set<Polyline> polylines = {};

    final nearestStop = await _getNearestStop();
    final walkToStartRoute = await _getWalkingRoute(_currentPosition, nearestStop);
    
    if (walkToStartRoute != null) {
      polylines.add(walkToStartRoute);
    } else {
      print("No se pudo obtener la ruta caminando hacia la parada más cercana.");
    }

    final transportRoutes = await _getOptimalTransportRoutes(nearestStop, _destinationMarker!.position);
    polylines.addAll(transportRoutes);

    final finalWalk = await _getWalkingRoute(transportRoutes.last.points.last, _destinationMarker!.position);
    if (finalWalk != null) {
      polylines.add(finalWalk);
    } else {
      print("No se pudo obtener la ruta caminando desde la última parada hasta el destino.");
    }

    setState(() {
      _polylines = polylines;
    });
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
    // Decodificación de la latitud
    int b, shift = 0, result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lat += dlat;

    // Decodificación de la longitud
    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lng += dlng;

    // Agregar el nuevo punto a la lista
    poly.add(LatLng(lat / 1E5, lng / 1E5));
  }

  return poly;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Ruta'),
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
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: !_startSelected
                      ? () => _setStartLocation(_currentPosition)
                      : null,
                  child: const Text('Fijar Ubicación de Inicio'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _startSelected && !_destinationSelected
                      ? () => _setDestinationLocation(_currentPosition)
                      : null,
                  child: const Text('Fijar Ubicación de Destino'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _isSearchEnabled ? _showRoute : null,
                  child: const Text('Buscar Ruta'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
