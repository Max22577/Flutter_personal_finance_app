
class Category {
  final String id;
  final String name;
  final int? iconCode;   // Store IconData.codePoint
  final int? colorValue; // Store Color.value
  final bool isCustom;

  Category({
    required this.id, 
    required this.name, 
    this.iconCode, 
    this.colorValue, 
    this.isCustom = false
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          iconCode == other.iconCode &&
          colorValue == other.colorValue;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ iconCode.hashCode ^ colorValue.hashCode;

  /// Factory constructor to create a Category from a Firestore Document Snapshot.
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Unnamed Category',
      iconCode: (map['icon_code'] as num?)?.toInt(),
      colorValue: (map['color_value'] as num?)?.toInt(),
      isCustom: map['isCustom'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'icon_code': iconCode,
      'color_value': colorValue,
      'isCustom': isCustom,
    };
  }
  Map<String, dynamic> toMap() => toFirestore();
}
  