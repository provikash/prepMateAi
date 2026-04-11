class CanvasElement {
  final String id;
  final String text;
  final double x;
  final double y;
  final double fontSize;
  final String colorHex;
  final int fontWeight;

  CanvasElement({
    required this.id,
    required this.text,
    required this.x,
    required this.y,
    this.fontSize = 16.0,
    this.colorHex = "#1F2937", // A professional dark slate default
    this.fontWeight = 400, // 400 = Normal, 700 = Bold
  });

  // ==========================================
  // RIVERPOD MUTATION SUPPORT
  // ==========================================
  // Riverpod Notifiers require immutable state. We never change the existing
  // object; we create a copy with only the modified fields updated.
  CanvasElement copyWith({
    String? id,
    String? text,
    double? x,
    double? y,
    double? fontSize,
    String? colorHex,
    int? fontWeight,
  }) {
    return CanvasElement(
      id: id ?? this.id,
      text: text ?? this.text,
      x: x ?? this.x,
      y: y ?? this.y,
      fontSize: fontSize ?? this.fontSize,
      colorHex: colorHex ?? this.colorHex,
      fontWeight: fontWeight ?? this.fontWeight,
    );
  }

  // ==========================================
  // DJANGO API SERIALIZATION
  // ==========================================
  // Converts the Dart object into a JSON map to send via Dio
  // Notice we use snake_case for the keys to match Python/Django standards
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'x': x,
      'y': y,
      'font_size': fontSize,
      'color_hex': colorHex,
      'font_weight': fontWeight,
    };
  }

  // Parses the JSON map from your Django API into a Dart object.
  // We use `as num` before calling `.toDouble()` because JSON numbers
  // without decimals (like 50) might be parsed as int instead of double.
  factory CanvasElement.fromJson(Map<String, dynamic> json) {
    return CanvasElement(
      id: json['id'] as String,
      text: json['text'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      fontSize: (json['font_size'] as num?)?.toDouble() ?? 16.0,
      colorHex: json['color_hex'] as String? ?? "#1F2937",
      fontWeight: json['font_weight'] as int? ?? 400,
    );
  }
}
