import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class SecondScreen extends StatefulWidget {
  const SecondScreen({super.key});

  @override
  State<SecondScreen> createState() => _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen> {
  late GoogleMapController mapController;
  LatLng _currentPosition = const LatLng(-12.04318, -77.02824); // Coordenadas iniciales de ejemplo
  Marker? _startMarker;
  Marker? _destinationMarker;
  Set<Polyline> _polylines = {}; // Almacena las rutas que se mostrarán en el mapa

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _loadRoutes();
  }

  // Función para cargar rutas desde Firebase
  Future<void> _loadRoutes() async {
    final routes = await fetchRoutes();
    Set<Polyline> polylines = {};

    for (var route in routes) {
      List<LatLng> stops = (route['stops'] as List)
          .map((stop) => LatLng(stop.latitude, stop.longitude))
          .toList();

      polylines.add(Polyline(
        polylineId: PolylineId(route['route_id']),
        points: stops,
        color: Color(int.parse("0xFF${route['color'].substring(1)}")), // Convierte el color hex a formato Flutter
        width: 5,
      ));
    }

    setState(() {
      _polylines = polylines;
    });
  }

  // Función para obtener rutas desde Firestore
  Future<List<Map<String, dynamic>>> fetchRoutes() async {
    final snapshot = await FirebaseFirestore.instance.collection('public_transport_routes').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // Obtiene la ubicación actual del usuario
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
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });
  }

  // Configura el controlador del mapa
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  // Configura la ubicación de inicio con un marcador
  void _setStartLocation(LatLng location) {
    setState(() {
      _startMarker = Marker(
        markerId: const MarkerId('start'),
        position: location,
        infoWindow: const InfoWindow(title: 'Ubicación de Inicio'),
      );
    });
  }

  // Configura la ubicación de destino con un marcador
  void _setDestinationLocation(LatLng location) {
    setState(() {
      _destinationMarker = Marker(
        markerId: const MarkerId('destination'),
        position: location,
        infoWindow: const InfoWindow(title: 'Ubicación de Destino'),
      );
    });
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
            polylines: _polylines, // Muestra las rutas cargadas como polilíneas
            myLocationEnabled: true,
            onTap: (LatLng position) {
              // Aquí puedes decidir si establecer inicio o destino basado en lógica.
              _setStartLocation(position);
            },
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Configura el marcador de inicio
                    print('Establecer Ubicación de Inicio');
                    _setStartLocation(_currentPosition);
                  },
                  child: const Text('Ubicación de Inicio'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    // Configura el marcador de destino
                    print('Establecer Ubicación de Destino');
                    _setDestinationLocation(_currentPosition);
                  },
                  child: const Text('Ubicación de Destino'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    // Lógica para buscar la ruta entre inicio y destino
                    print('Buscar Ruta');
                    // Aquí se podría implementar lógica de búsqueda entre inicio y destino
                  },
                  child: const Text('Buscar Ruta'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /*final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pantalla 2'),
      ),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _kGooglePlex,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
      ),
    );
  }*/
}