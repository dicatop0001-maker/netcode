import 'dart:io';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';

class ProductCard extends StatelessWidget {
    final ProductModel product;
    final bool isOwner;
    final VoidCallback? onEdit;
    final VoidCallback? onDelete;

    const ProductCard({
          super.key,
          required this.product,
          this.isOwner = false,
          this.onEdit,
          this.onDelete,
    });

    @override
    Widget build(BuildContext context) {
          return Card(
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                            children: [
                                        Column(
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
                                                                                                                                  if (product.bairro.isNotEmpty || product.cidade.isNotEmpty)
                                                                                                                                    Row(children: [
                                                                                                                                                              const Icon(Icons.location_on, size: 10, color: AppTheme.textSecondary),
                                                                                                                                                              const SizedBox(width: 2),
                                                                                                                                                              Expanded(child: Text(
                                                                                                                                                                                          [if (product.bairro.isNotEmpty) product.bairro,
                                                                                                                                                                                                                      if (product.cidade.isNotEmpty) product.cidade].join(', '),
                                                                                                                                                                                          style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
                                                                                                                                                                                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                                                                                                                                                            ]),
                                                                                                                                  Text(product.sellerNick,
                                                                                                                                                             style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                                                                                                                                ],
                                                                                                          ),
                                                                                      ),
                                                                    ],
                                                    ),
                                        // Botoes de acao para o dono do anuncio
                                        if (isOwner)
                                          Positioned(
                                                          top: 4,
                                                          right: 4,
                                                          child: Container(
                                                                            decoration: BoxDecoration(
                                                                                                color: Colors.black54,
                                                                                                borderRadius: BorderRadius.circular(8)),
                                                                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                                                                                                GestureDetector(
                                                                                                                      onTap: onEdit,
                                                                                                                      child: const Padding(
                                                                                                                                              padding: EdgeInsets.all(4),
                                                                                                                                              child: Icon(Icons.edit, size: 16, color: Colors.white))),
                                                                                                GestureDetector(
                                                                                                                      onTap: onDelete,
                                                                                                                      child: const Padding(
                                                                                                                                              padding: EdgeInsets.all(4),
                                                                                                                                              child: Icon(Icons.delete_outline, size: 16, color: Colors.redAccent))),
                                                                                              ]),
                                                                          ),
                                                        ),
                                      ],
                          ),
                );
    }
}
