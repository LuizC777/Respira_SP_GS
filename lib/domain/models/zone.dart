/// Uma região do território (zona da cidade de São Paulo).
class Zone {
  const Zone({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.population,
    required this.schools,
    required this.healthUnits,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;

  /// Estimativas sintéticas usadas nos indicadores de benefício social.
  final int population;
  final int schools;
  final int healthUnits;
}
