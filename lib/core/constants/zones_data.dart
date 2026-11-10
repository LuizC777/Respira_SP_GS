import '../../domain/models/zone.dart';

/// Zonas do território monitorado.
///
/// Coordenadas: pontos de referência aproximados de cada zona.
/// População, escolas e UBSs: ESTIMATIVAS SINTÉTICAS para fins acadêmicos
/// (ordem de grandeza inspirada em dados públicos, não são valores oficiais).
const kZones = <Zone>[
  Zone(
    id: 'centro',
    name: 'Centro',
    latitude: -23.5505,
    longitude: -46.6333,
    population: 450000,
    schools: 160,
    healthUnits: 25,
  ),
  Zone(
    id: 'norte',
    name: 'Zona Norte',
    latitude: -23.4800,
    longitude: -46.6200,
    population: 2300000,
    schools: 780,
    healthUnits: 110,
  ),
  Zone(
    id: 'sul',
    name: 'Zona Sul',
    latitude: -23.6500,
    longitude: -46.7000,
    population: 2600000,
    schools: 900,
    healthUnits: 125,
  ),
  Zone(
    id: 'leste',
    name: 'Zona Leste',
    latitude: -23.5400,
    longitude: -46.4700,
    population: 4000000,
    schools: 1350,
    healthUnits: 170,
  ),
  Zone(
    id: 'oeste',
    name: 'Zona Oeste',
    latitude: -23.5700,
    longitude: -46.7200,
    population: 1100000,
    schools: 380,
    healthUnits: 50,
  ),
];

Zone zoneById(String id) =>
    kZones.firstWhere((z) => z.id == id, orElse: () => kZones.first);
