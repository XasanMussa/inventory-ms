class EnvironmentReading {
  final String id;
  final double temperature;
  final double humidity;

  EnvironmentReading({
    required this.id,
    required this.temperature,
    required this.humidity,
  });

  factory EnvironmentReading.fromMap(Map<String, dynamic> map) {
    return EnvironmentReading(
      id: map['id'] as String,
      temperature: (map['temperature'] as num).toDouble(),
      humidity: (map['humidity'] as num).toDouble(),
    );
  }
}
