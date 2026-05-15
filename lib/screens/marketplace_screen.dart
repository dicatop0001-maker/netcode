import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../theme/app_theme.dart';
import '../models/product_model.dart';
import 'add_product_screen.dart';
import '../widgets/product_card.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Marketplace Local'), automaticallyImplyLeading: false),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<ProductModel>('products').listenable(),
        builder: (_, box, __) {
          final products = (box as Box<ProductModel>).values
              .where((p) => !p.isExpired && p.available)
              .toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          if (products.isEmpty) return Center(child: Column(
            mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.storefront_outlined, size: 60, color: AppTheme.textSecondary),
              const SizedBox(height: 16),
              const Text('Nenhum produto ainda',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Anuncie algo para sua comunidade!',
                  style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 24),
              ElevatedButton.icon(icon: const Icon(Icons.add),
                label: const Text('Anunciar Produto'),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AddProductScreen()))),
            ]));
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, childAspectRatio: 0.75,
                crossAxisSpacing: 10, mainAxisSpacing: 10),
            itemCount: products.length,
            itemBuilder: (_, i) => ProductCard(product: products[i]));
        }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddProductScreen())),
        icon: const Icon(Icons.add), label: const Text('Anunciar')),
    );
  }
}
