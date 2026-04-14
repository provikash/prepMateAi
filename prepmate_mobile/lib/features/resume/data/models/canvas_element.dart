class CanvasElement {
  final String id;
  final String text;
  final double x;
  final double y;
  final double fontSize;

  CanvasElement({
    required this.id,
    required this.text,
    required this.x,
    required this.y,
    this.fontSize = 16.0,
  });

  CanvasElement copyWith({
    String? id,
    String? text,
    double? x,
    double? y,
    double? fontSize,
  }) {
    return CanvasElement(
      id: id ?? this.id,
      text: text ?? this.text,
      x: x ?? this.x,
      y: y ?? this.y,
      fontSize: fontSize ?? this.fontSize,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'text': text, 'x': x, 'y': y, 'font_size': fontSize};
  }

  factory CanvasElement.fromJson(Map<String, dynamic> json) {
    return CanvasElement(
      id: json['id'],
      text: json['text'],
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      fontSize: (json['font_size'] as num).toDouble(),
    );
  }
}
