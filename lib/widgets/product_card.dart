import 'dart:io';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: product.imagePaths.isNotEmpty
                ? Image.file(File(product.imagePaths.first),
                    width: double.infinity, fit: BoxFit.cover)
                : Container(
                    color: AppTheme.surfaceLight,
                    child: Center(
                      child: Icon(Icons.image_outlined,
                          size: 40, color: AppTheme.textSecondary))),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('R\$ ${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppTheme.primary,
                        fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 2),
                Text(product.sellerNick,
                    style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
