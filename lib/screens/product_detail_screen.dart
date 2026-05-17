import 'dart:io';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import 'add_product_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = product.sellerId == StorageService.getDeviceId();
    return Scaffold(
      appBar: AppBar(
        title: Text(product.title, overflow: TextOverflow.ellipsis),
        actions: [
          if (isOwner) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar',
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AddProductScreen(editProduct: product)));
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Apagar',
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Galeria de imagens
            if (product.imagePaths.isNotEmpty)
              SizedBox(
                height: 260,
                child: PageView.builder(
                  itemCount: product.imagePaths.length,
                  itemBuilder: (_, i) => Image.file(
                    File(product.imagePaths[i]),
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppTheme.surfaceLight,
                      child: const Center(child: Icon(Icons.broken_image_outlined, size: 60))),
                  ),
                ),
              )
            else
              Container(
                height: 180,
                color: AppTheme.surfaceLight,
                child: Center(
                  child: Icon(Icons.image_outlined, size: 60, color: AppTheme.textSecondary)),
              ),
            if (product.imagePaths.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(child: Text(
                  '${product.imagePaths.length} fotos - deslize para ver mais',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary))),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categoria
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6)),
                    child: Text(product.category,
                      style: const TextStyle(fontSize: 11, color: AppTheme.primary,
                        fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 8),

                  // Titulo
                  Text(product.title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  // Preco
                  Text('R$ ${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900,
                      color: AppTheme.primary)),
                  const SizedBox(height: 16),

                  // Localização
                  if (product.bairro.isNotEmpty || product.cidade.isNotEmpty) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.location_on_outlined, color: AppTheme.primary, size: 20),
                      const SizedBox(width: 6),
                      Expanded(child: Text(
                        [if (product.bairro.isNotEmpty) product.bairro,
                          if (product.cidade.isNotEmpty) product.cidade].join(', '),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
                    ]),
                    const SizedBox(height: 8),
                  ],

                  // Descricao
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('Descricao', style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  Text(product.description,
                    style: const TextStyle(fontSize: 15, height: 1.5)),
                  const SizedBox(height: 16),

                  // Vendedor / Contato
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('Contato', style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  Row(children: [
                    const CircleAvatar(radius: 18,
                      backgroundColor: AppTheme.primary,
                      child: Icon(Icons.person_outline, color: Colors.white, size: 20)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.sellerNick,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('Anunciante na rede local',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      ],
                    )),
                  ]),
                  const SizedBox(height: 16),

                  // Data e expiracao
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.access_time_outlined, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Publicado em ${_formatDate(product.createdAt)}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    const Spacer(),
                    const Icon(Icons.timer_outlined, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Expira em ${_formatDate(product.expiresAt)}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ]),
                  const SizedBox(height: 24),

                  // Botoes de acao do dono
                  if (isOwner) ...[
                    Row(children: [
                      Expanded(child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar Anuncio'),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => AddProductScreen(editProduct: product)));
                        },
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          foregroundColor: Colors.red),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Apagar'),
                        onPressed: () => _confirmDelete(context),
                      )),
                    ]),
                    const SizedBox(height: 8),
                    Center(child: Text('Apenas voce pode editar ou apagar este anuncio',
                      style: TextStyle(fontSize: 10, color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic))),
                  ],
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Apagar Anuncio?'),
        content: Text('Deseja apagar o anuncio "${product.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              await product.delete();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: const Text('Apagar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
