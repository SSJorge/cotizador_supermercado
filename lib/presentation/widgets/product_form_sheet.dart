import 'package:flutter/material.dart';

import '../../domain/entities/product_offer.dart';

class ProductFormSheet extends StatefulWidget {
  final ProductOffer? product;

  const ProductFormSheet({
    super.key,
    this.product,
  });

  @override
  State<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;
  late final TextEditingController _brandController;
  late final TextEditingController _supermarketController;
  late final TextEditingController _noteController;

  late String _unit;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();

    final product = widget.product;

    _nameController = TextEditingController(text: product?.name ?? '');
    _priceController = TextEditingController(
      text: product == null ? '' : product.price.toString(),
    );
    _quantityController = TextEditingController(
      text: product == null ? '' : _formatInitialQuantity(product.quantity),
    );
    _brandController = TextEditingController(text: product?.brand ?? '');
    _supermarketController =
        TextEditingController(text: product?.supermarket ?? '');
    _noteController = TextEditingController(text: product?.note ?? '');

    _unit = product?.unit ?? 'g';
  }

  String _formatInitialQuantity(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _brandController.dispose();
    _supermarketController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obligatorio';
    }
    return null;
  }

  String? _priceValidator(String? value) {
    final clean = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    final parsed = int.tryParse(clean);

    if (parsed == null || parsed <= 0) {
      return 'Ingresa un precio mayor que 0';
    }
    return null;
  }

  String? _quantityValidator(String? value) {
    final parsed = double.tryParse((value ?? '').replaceAll(',', '.'));

    if (parsed == null || parsed <= 0) {
      return 'Ingresa una cantidad mayor que 0';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final price = int.parse(
      _priceController.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );

    final quantity = double.parse(
      _quantityController.text.replaceAll(',', '.'),
    );

    final note = _noteController.text.trim();

    Navigator.of(context).pop(
      ProductOffer(
        id: widget.product?.id ?? '',
        name: _nameController.text.trim(),
        price: price,
        quantity: quantity,
        unit: _unit,
        brand: _brandController.text.trim(),
        supermarket: _supermarketController.text.trim(),
        note: note.isEmpty ? null : note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _isEditing
                                ? 'Editar producto'
                                : 'Agregar producto',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      autofocus: !_isEditing,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Producto',
                        hintText: 'Ej: Leche',
                        border: OutlineInputBorder(),
                      ),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _brandController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Marca',
                        hintText: 'Ej: Colun',
                        border: OutlineInputBorder(),
                      ),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _supermarketController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Supermercado',
                        hintText: 'Ej: Jumbo',
                        border: OutlineInputBorder(),
                      ),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Precio',
                              prefixText: r'$ ',
                              hintText: '900',
                              border: OutlineInputBorder(),
                            ),
                            validator: _priceValidator,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _quantityController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Cantidad',
                              hintText: '1000',
                              border: OutlineInputBorder(),
                            ),
                            validator: _quantityValidator,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _unit,
                      decoration: const InputDecoration(
                        labelText: 'Unidad',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'g', child: Text('gramos (g)')),
                        DropdownMenuItem(
                          value: 'kg',
                          child: Text('kilogramos (kg)'),
                        ),
                        DropdownMenuItem(
                          value: 'ml',
                          child: Text('mililitros (ml)'),
                        ),
                        DropdownMenuItem(value: 'L', child: Text('litros (L)')),
                        DropdownMenuItem(
                          value: 'un',
                          child: Text('unidades (un)'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _unit = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _noteController,
                      minLines: 2,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Nota (opcional)',
                        hintText: 'Ej: Solo comprando 3 o más',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _submit,
                      icon: Icon(_isEditing ? Icons.save : Icons.add),
                      label: Text(_isEditing ? 'Guardar cambios' : 'Agregar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
