class City {
  final String name;
  final double lat;
  final double lon;
  final String country;
  final String? state;

  City({
    required this.name,
    required this.lat,
    required this.lon,
    required this.country,
    this.state,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      name: json['name'],
      lat: json['lat'],
      lon: json['lon'],
      country: json['country'],
      state: json['state'],
    );
  }

  String get displayName {
    if (state != null) {
      return '$name, $state, $country';
    }
    return '$name, $country';
  }
}
