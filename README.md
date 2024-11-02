# TravelEase

**TravelEase** es una innovadora aplicación móvil desarrollada en Flutter que facilita la navegación en el transporte público de Huancayo, Junín, Perú. Con el objetivo de mejorar la movilidad urbana y contribuir al ODS 11, la aplicación permite a los usuarios ingresar su ubicación actual y destino, ofreciendo rutas óptimas de transporte público y opciones de caminata. Esto no solo simplifica la experiencia de los usuarios, sino que también fomenta un sistema de transporte más inclusivo, seguro y sostenible, vital para el desarrollo de ciudades resilientes.

![Captura de Pantalla de TravelEase](https://github.com/Kenss12345/travel_ease/blob/main/WhatsApp%20Image%202024-11-02%20at%202.19.14%20AM%20(1).jpeg?raw=true)

![Captura de Pantalla de TravelEase](https://github.com/Kenss12345/travel_ease/blob/main/WhatsApp%20Image%202024-11-02%20at%202.19.14%20AM.jpeg?raw=true)

![Captura de Pantalla de TravelEase](https://github.com/Kenss12345/travel_ease/blob/main/WhatsApp%20Image%202024-11-02%20at%202.19.13%20AM%20(1).jpeg?raw=true)

![Captura de Pantalla de TravelEase](https://github.com/Kenss12345/travel_ease/blob/main/WhatsApp%20Image%202024-11-02%20at%202.19.13%20AM.jpeg?raw=true)

## Funcionalidades

- **Localización del Usuario:** La aplicación utiliza servicios de ubicación para determinar la posición actual del usuario.
- **Rutas de Transporte Público:** Accede a una base de datos de rutas de transporte público, mostrando la mejor ruta disponible y su duración.
- **Caminos de Acceso:** Calcula y muestra las rutas a pie desde la ubicación del usuario hasta la parada de transporte más cercana, así como desde la última parada de transporte hasta el destino.
- **Interfaz Intuitiva:** La interfaz es fácil de usar y permite una rápida selección de la ubicación de inicio y destino.

## Tecnologías Utilizadas

- **Flutter:** Framework para el desarrollo de aplicaciones móviles.
- **Google Maps API:** Para la visualización de mapas y rutas.
- **Firebase Firestore:** Base de datos en tiempo real para almacenar y gestionar datos de rutas.
- **Geolocator:** Para obtener la ubicación actual del usuario.

## Instalación

1. Clona este repositorio:
   ```bash
   git clone https://github.com/Kenss12345/travel_ease.git
   cd travelease

2. Asegúrate de tener Flutter instalado. Luego, ejecuta:
   ```bash
   flutter pub get

3. Reemplaza 'TU_API_KEY' en el archivo correspondiente para habilitar el uso de Google Maps API.

4. Ejecuta la aplicación:
    ```bash
    flutter run

## Contribuciones

Las contribuciones son bienvenidas. Si deseas mejorar este proyecto, por favor crea un fork del repositorio y envía un pull request.

## Licencia

Este proyecto está bajo la Licencia MIT. Consulta el archivo LICENSE para más información.

## Contacto

Si tienes alguna pregunta, no dudes en contactarme a través de [72195486@continental.edu.pe.com].


### Documentación Técnica

#### 1. **Introducción**

TravelEase es una solución diseñada para mejorar la experiencia de movilidad de los usuarios en Huancayo. La aplicación permite una navegación eficiente y conveniente en el transporte público, integrando funcionalidades de geolocalización y visualización de rutas.

#### 2. **Arquitectura del Proyecto**

- **Frontend:** Implementado con Flutter, permite el desarrollo de una interfaz atractiva y funcional que se adapta a diferentes dispositivos móviles.
- **Backend:** Utiliza Firebase Firestore para el almacenamiento de datos relacionados con las rutas de transporte público y la información del usuario.

#### 3. **Estructura de Datos**

- **Rutas de Transporte Público:**
  - `route_id`: Identificador único (String)
  - `route_name`: Nombre de la ruta (String)
  - `color`: Color en formato hexadecimal (String)
  - `stops`: Array de GeoPoints (List)
  - `transfers`: Array de String (List)

#### 4. **Componentes Clave**

- **GoogleMap Widget:** Utilizado para mostrar el mapa y las rutas.
- **Polyline:** Para visualizar las rutas en el mapa.
- **Geolocator:** Para obtener la ubicación actual del usuario.

#### 5. **Funciones Principales**

- **_getWalkingRoute:** Calcula la ruta de caminata entre dos puntos.
- **_getOptimalTransportRoutes:** Recupera las rutas de transporte público más eficaces.
- **_getNearestStop:** Encuentra la parada de transporte público más cercana al usuario.

#### 6. **Instalación y Configuración**

Para instalar y configurar la aplicación, sigue las instrucciones proporcionadas en la sección de instalación del README.

#### 7. **Despliegue**

La aplicación está diseñada para ser ejecutada en dispositivos móviles a través de la herramienta Flutter. Se recomienda probar en dispositivos reales para garantizar la funcionalidad del GPS y la visualización del mapa.

#### 8. **Pruebas**

Se implementaron pruebas manuales para verificar la funcionalidad de la ubicación del usuario, la visualización de rutas y la precisión de los datos de Firebase.

#### 9. **Conclusión**

TravelEase busca mejorar la movilidad urbana al ofrecer una herramienta accesible y fácil de usar para los usuarios del transporte público en Huancayo, alineándose con el ODS 11. Su enfoque en la eficiencia y la usabilidad no solo transforma la manera en que las personas navegan por la ciudad, sino que también promueve un transporte sostenible. Al facilitar el acceso y uso de las rutas de transporte público, la aplicación contribuye a crear entornos urbanos más inclusivos y resilientes, fundamentales para el desarrollo sostenible de la comunidad.

---

