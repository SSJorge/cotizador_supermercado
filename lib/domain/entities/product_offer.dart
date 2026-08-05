class ProductOffer {
  final String id;
  final String name;
  final int price;
  final double quantity;
  final String unit;
  final String brand;
  final String supermarket;
  final String? note;

  const ProductOffer({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.unit,
    required this.brand,
    required this.supermarket,
    this.note,
  });

  String get normalizedName => name.trim().toLowerCase();

  String get measurementType {
    switch (unit) {
      case 'g':
      case 'kg':
        return 'mass';
      case 'ml':
      case 'L':
        return 'volume';
      case 'un':
        return 'unit';
      default:
        return unit;
    }
  }

  /// Normaliza kg -> g y L -> ml.
  double get baseQuantity {
    switch (unit) {
      case 'kg':
      case 'L':
        return quantity * 1000;
      default:
        return quantity;
    }
  }

  /// CLP por g, ml o unidad.
  double get pricePerBaseUnit => price / baseQuantity;

  /// Métrica amigable para mostrar:
  /// $/100g, $/100ml o $/unidad.
  double get comparisonPrice {
    if (measurementType == 'unit') return pricePerBaseUnit;
    return pricePerBaseUnit * 100;
  }

  String get comparisonDenominator {
    switch (measurementType) {
      case 'mass':
        return '100 g';
      case 'volume':
        return '100 ml';
      case 'unit':
        return 'unidad';
      default:
        return unit;
    }
  }

  /// Cantidad base obtenida por cada $1 gastado.
  double get quantityPerPeso => baseQuantity / price;

  String get baseUnit {
    switch (measurementType) {
      case 'mass':
        return 'g';
      case 'volume':
        return 'ml';
      case 'unit':
        return 'un';
      default:
        return unit;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name.trim(),
      'normalizedName': normalizedName,
      'price': price,
      'quantity': quantity,
      'unit': unit,
      'brand': brand.trim(),
      'supermarket': supermarket.trim(),
      'note': note?.trim(),
    };
  }

  factory ProductOffer.fromMap(String id, Map<String, dynamic> map) {
    return ProductOffer(
      id: id,
      name: (map['name'] as String? ?? '').trim(),
      price: (map['price'] as num? ?? 0).toInt(),
      quantity: (map['quantity'] as num? ?? 0).toDouble(),
      unit: map['unit'] as String? ?? 'g',
      brand: (map['brand'] as String? ?? '').trim(),
      supermarket: (map['supermarket'] as String? ?? '').trim(),
      note: (map['note'] as String?)?.trim(),
    );
  }
}
