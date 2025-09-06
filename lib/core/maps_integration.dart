import 'package:url_launcher/url_launcher.dart';

class MapsIntegration {
  /// Launch Google Maps with coordinates
  static Future<void> openLocation(String location) async {
    final coords = location.split(',');
    if (coords.length != 2) {
      throw ArgumentError('Invalid location format. Expected "lat,lng"');
    }

    final lat = double.tryParse(coords[0].trim());
    final lng = double.tryParse(coords[1].trim());

    if (lat == null || lng == null) {
      throw ArgumentError('Invalid coordinates. Could not parse lat/lng');
    }

    await openCoordinates(lat, lng);
  }

  /// Launch Google Maps with specific coordinates
  static Future<void> openCoordinates(double lat, double lng) async {
    final url = Uri.parse('https://maps.google.com/?q=$lat,$lng');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch Google Maps');
    }
  }

  /// Launch Google Maps with search query
  static Future<void> searchLocation(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    final url = Uri.parse('https://maps.google.com/search/$encodedQuery');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch Google Maps');
    }
  }

  /// Launch directions from current location to destination
  static Future<void> getDirections(String destination) async {
    final encodedDestination = Uri.encodeComponent(destination);
    final url = Uri.parse(
        'https://maps.google.com/dir/?api=1&destination=$encodedDestination');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch Google Maps');
    }
  }

  /// Launch directions between two specific locations
  static Future<void> getDirectionsBetween(
      String origin, String destination) async {
    final encodedOrigin = Uri.encodeComponent(origin);
    final encodedDestination = Uri.encodeComponent(destination);
    final url = Uri.parse(
        'https://maps.google.com/dir/?api=1&origin=$encodedOrigin&destination=$encodedDestination');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch Google Maps');
    }
  }
}
