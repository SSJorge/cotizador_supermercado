import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/product_offer.dart';
import '../providers/product_providers.dart';
import '../widgets/product_form_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();

  final _money = NumberFormat.currency(
    locale: 'es_CL',
    symbol: r'$',
    decimalDigits: 0,
  );

  final _decimal = NumberFormat.decimalPattern('es_CL');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(productsProvider);

    try {
      await ref.read(productsProvider.future);
    } catch (_) {
      // El provider mostrará el error en pantalla.
    }
  }

  Future<void> _openProductForm({ProductOffer? product}) async {
    final result = await showModalBottomSheet<ProductOffer>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => ProductFormSheet(product: product),
    );

    if (result == null) return;

    try {
      final repository = ref.read(productRepositoryProvider);

      if (product == null) {
        await repository.create(result);
      } else {
        await repository.update(result);
      }

      ref.invalidate(productsProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            product == null
                ? 'Producto agregado'
                : 'Producto actualizado',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    }
  }

  Future<void> _deleteProduct(ProductOffer product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text(
          '¿Eliminar "${product.name} - ${product.brand}" de '
          '${product.supermarket}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(productRepositoryProvider).delete(product.id);
      ref.invalidate(productsProvider);
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $error'),
      ),
    );
  }

  List<ProductOffer> _filterAndSort(List<ProductOffer> source) {
    final query = _searchController.text.trim().toLowerCase();

    final products = source.where((product) {
      if (query.isEmpty) return true;
      return product.normalizedName.contains(query);
    }).toList();

    products.sort((a, b) {
      if (query.isEmpty) {
        final byName =
            a.normalizedName.compareTo(b.normalizedName);
        if (byName != 0) return byName;
      }

      final byType =
          a.measurementType.compareTo(b.measurementType);
      if (byType != 0) return byType;

      final byValue =
          a.pricePerBaseUnit.compareTo(b.pricePerBaseUnit);
      if (byValue != 0) return byValue;

      return a.price.compareTo(b.price);
    });

    return products;
  }

  Map<String, double> _bestPriceByMeasurement(
    List<ProductOffer> products,
  ) {
    final result = <String, double>{};

    for (final product in products) {
      final current = result[product.measurementType];

      if (current == null ||
          product.pricePerBaseUnit < current) {
        result[product.measurementType] =
            product.pricePerBaseUnit;
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final searching = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cotizador supermercado'),
        actions: [
          IconButton(
            tooltip: 'Actualizar datos',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openProductForm(),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: productsAsync.when(
          loading: () => const _ScrollableLoading(),
          error: (error, _) => _ScrollableError(
            error: error,
            onRetry: _refresh,
          ),
          data: (source) {
            final products = _filterAndSort(source);
            final bestByType =
                _bestPriceByMeasurement(products);

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Buscar producto, ej: leche',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon:
                            _searchController.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Limpiar',
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.clear),
                                  ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            searching
                                ? '${products.length} resultado(s), ordenados por conveniencia'
                                : '${products.length} registro(s)',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.sync),
                          label: const Text('Actualizar'),
                        ),
                      ],
                    ),
                  ),
                ),
                if (searching && products.isNotEmpty) ...[
                  Center(
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: 800),
                      child: const Card(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'La comparación usa precio por cantidad: '
                                  '$/100 g, $/100 ml o $/unidad. '
                                  'Kg y L se normalizan automáticamente.',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                if (products.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 64),
                    child: Center(
                      child: Text(
                        'No hay productos para mostrar.',
                      ),
                    ),
                  )
                else
                  ...products.map((product) {
                    final best =
                        bestByType[product.measurementType];

                    final isBest = searching &&
                        best != null &&
                        (product.pricePerBaseUnit - best).abs() <
                            0.000000001;

                    return Center(
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(maxWidth: 800),
                        child: Padding(
                          padding:
                              const EdgeInsets.only(bottom: 10),
                          child: _ProductCard(
                            product: product,
                            isBest: isBest,
                            money: _money,
                            decimal: _decimal,
                            onEdit: () =>
                                _openProductForm(product: product),
                            onDelete: () =>
                                _deleteProduct(product),
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductOffer product;
  final bool isBest;
  final NumberFormat money;
  final NumberFormat decimal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.isBest,
    required this.money,
    required this.decimal,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatYield(double value) {
    if (value >= 10) return value.toStringAsFixed(1);
    if (value >= 1) return value.toStringAsFixed(2);
    return value.toStringAsFixed(3);
  }

  @override
  Widget build(BuildContext context) {
    final note = product.note;

    return Card(
      elevation: isBest ? 2 : 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment:
                            WrapCrossAlignment.center,
                        children: [
                          Text(
                            product.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (isBest)
                            const Chip(
                              avatar:
                                  Icon(Icons.star, size: 18),
                              label: Text('MEJOR COMPRA'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${product.brand} · ${product.supermarket}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Editar'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline),
                        title: Text('Eliminar'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _Metric(
                  label: 'Precio',
                  value: money.format(product.price),
                ),
                _Metric(
                  label: 'Cantidad',
                  value:
                      '${decimal.format(product.quantity)} ${product.unit}',
                ),
                _Metric(
                  label: 'Comparación',
                  value:
                      '${money.format(product.comparisonPrice)} / ${product.comparisonDenominator}',
                ),
                _Metric(
                  label: 'Cantidad / precio',
                  value:
                      '${_formatYield(product.quantityPerPeso)} ${product.baseUnit} / $1',
                ),
              ],
            ),
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(note)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 145),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ScrollableLoading extends StatelessWidget {
  const _ScrollableLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 220),
        Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _ScrollableError extends StatelessWidget {
  final Object error;
  final Future<void> Function() onRetry;

  const _ScrollableError({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.error_outline, size: 48),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'No se pudieron cargar los datos.',
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            error.toString(),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ),
      ],
    );
  }
}
