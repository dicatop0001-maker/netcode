import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_theme.dart';
import '../models/product_model.dart';
import '../services/storage_service.dart';

class AddProductScreen extends StatefulWidget {
    final ProductModel? editProduct;
    const AddProductScreen({super.key, this.editProduct});
    @override State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
    final _form = GlobalKey<FormState>();
    final _ttl = TextEditingController();
    final _dsc = TextEditingController();
    final _prc = TextEditingController();
    final _bairro = TextEditingController();
    final _cidade = TextEditingController();
    final _pick = ImagePicker();
    List<String> _imgs = [];
    String _cat = 'Geral';
    bool _saving = false;
    static const _cats = ['Geral','Alimentos','Roupas','Eletronicos','Servicos','Imoveis','Veiculos','Outros'];

    @override
    void initState() {
          super.initState();
          if (widget.editProduct != null) {
                  final p = widget.editProduct!;
                  _ttl.text = p.title;
                  _dsc.text = p.description;
                  _prc.text = p.price.toStringAsFixed(2);
                  _bairro.text = p.bairro;
                  _cidade.text = p.cidade;
                  _cat = p.category;
                  _imgs = List.from(p.imagePaths);
          }
    }

    Future<void> _addImg() async {
          if (_imgs.length >= 3) return;
          final xf = await _pick.pickImage(source: ImageSource.gallery,
                                                 maxWidth: 1024, maxHeight: 1024, imageQuality: 70);
          if (xf == null) return;
          final dir = await getTemporaryDirectory();
          final out = '${dir.path}/p${const Uuid().v4().substring(0,8)}.jpg';
          final res = await FlutterImageCompress.compressAndGetFile(xf.path, out, quality: 60);
          if (res != null) setState(() => _imgs.add(res.path));
    }

    Future<void> _save() async {
          if (!_form.currentState!.validate()) return;
          setState(() => _saving = true);
          final rm = StorageService.getCurrentRoom();
          final box = Hive.box<ProductModel>('products');

          if (widget.editProduct != null) {
                  // Editar produto existente
                  final p = widget.editProduct!;
                  p.title = _ttl.text.trim();
                  p.description = _dsc.text.trim();
                  p.price = double.tryParse(_prc.text.replaceAll(',', '.')) ?? 0;
                  p.category = _cat;
                  p.imagePaths = _imgs;
                  p.bairro = _bairro.text.trim();
                  p.cidade = _cidade.text.trim();
                  await p.save();
          } else {
                  // Novo produto
                  await box.add(ProductModel(
                            id: const Uuid().v4(), roomId: rm?.id ?? 'global',
                            sellerId: StorageService.getDeviceId(),
                            sellerNick: StorageService.getNickname() ?? 'User',
                            title: _ttl.text.trim(), description: _dsc.text.trim(),
                            price: double.tryParse(_prc.text.replaceAll(',', '.')) ?? 0,
                            createdAt: DateTime.now(),
                            expiresAt: DateTime.now().add(const Duration(hours: 48)),
                            imagePaths: _imgs, category: _cat,
                            bairro: _bairro.text.trim(), cidade: _cidade.text.trim()));
          }
          setState(() => _saving = false);
          if (mounted) Navigator.pop(context);
    }

    @override void dispose() {
          _ttl.dispose(); _dsc.dispose(); _prc.dispose();
          _bairro.dispose(); _cidade.dispose(); super.dispose();
    }

    @override
    Widget build(BuildContext context) {
          final isEdit = widget.editProduct != null;
          return Scaffold(
                  appBar: AppBar(title: Text(isEdit ? 'Editar Anuncio' : 'Anunciar Produto')),
                  body: SingleChildScrollView(padding: const EdgeInsets.all(20),
                                                      child: Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                                                  const Text('Fotos (max 3)', style: TextStyle(fontWeight: FontWeight.w600,
                                                                                                                           color: AppTheme.textSecondary, fontSize: 13)),
                                                                  const SizedBox(height: 8),
                                                                  SizedBox(height: 100, child: ListView(scrollDirection: Axis.horizontal, children: [
                                                                                ..._imgs.map((p) => Stack(children: [
                                                                                                Container(width: 90, height: 90, margin: const EdgeInsets.only(right: 8),
                                                                                                                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                                                                                                                                                                      image: DecorationImage(image: FileImage(File(p)), fit: BoxFit.cover))),
                                                                                                Positioned(top: 2, right: 10,
                                                                                                                           child: GestureDetector(onTap: () => setState(() => _imgs.remove(p)),
                                                                                                                                                                    child: Container(padding: const EdgeInsets.all(2),
                                                                                                                                                                                                         decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                                                                                                                                                                                         child: const Icon(Icons.close, size: 14, color: Colors.white)))),
                                                                                              ])),
                                                                                if (_imgs.length < 3)
                                                                                  GestureDetector(onTap: _addImg,
                                                                                                                  child: Container(width: 90, height: 90,
                                                                                                                                                     decoration: BoxDecoration(color: AppTheme.surfaceLight,
                                                                                                                                                                                                   borderRadius: BorderRadius.circular(10),
                                                                                                                                                                                                   border: Border.all(color: AppTheme.primary.withOpacity(0.4))),
                                                                                                                                                     child: const Icon(Icons.add_photo_alternate_outlined,
                                                                                                                                                                                           color: AppTheme.primary, size: 32))),
                                                                              ])),
                                                                  const SizedBox(height: 16),
                                                                  DropdownButtonFormField<String>(value: _cat,
                                                                                                              decoration: const InputDecoration(labelText: 'Categoria'),
                                                                                                              items: _cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                                                                                              onChanged: (v) => setState(() => _cat = v!)),
                                                                  const SizedBox(height: 12),
                                                                  TextFormField(controller: _ttl,
                                                                                            decoration: const InputDecoration(labelText: 'Titulo do produto'),
                                                                                            validator: (v) => v?.trim().isEmpty == true ? 'Obrigatorio' : null),
                                                                  const SizedBox(height: 12),
                                                                  TextFormField(controller: _dsc, maxLines: 3,
                                                                                            decoration: const InputDecoration(labelText: 'Descricao',
                                                                                                                                            hintText: 'Descreva brevemente...'),
                                                                                            validator: (v) => v?.trim().isEmpty == true ? 'Obrigatorio' : null),
                                                                  const SizedBox(height: 12),
                                                                  TextFormField(controller: _prc,
                                                                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                                                            decoration: const InputDecoration(labelText: 'Preco (R\$)', prefixText: 'R\$ '),
                                                                                            validator: (v) {
                                                                                                            if (v == null || v.isEmpty) return 'Informe o preco';
                                                                                                            if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Invalido';
                                                                                                            return null;
                                                                                            }),
                                                                  const SizedBox(height: 12),
                                                                  const Divider(),
                                                                  const SizedBox(height: 8),
                                                                  const Text('Localizacao do anuncio', style: TextStyle(
                                                                                fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textSecondary)),
                                                                  const SizedBox(height: 10),
                                                                  TextFormField(
                                                                                controller: _bairro,
                                                                                decoration: const InputDecoration(
                                                                                                labelText: 'Bairro',
                                                                                                hintText: 'Ex: Centro, Vila Nova...',
                                                                                                prefixIcon: Icon(Icons.location_city_outlined)),
                                                                              ),
                                                                  const SizedBox(height: 12),
                                                                  TextFormField(
                                                                                controller: _cidade,
                                                                                decoration: const InputDecoration(
                                                                                                labelText: 'Cidade',
                                                                                                hintText: 'Ex: Sao Paulo, Rio de Janeiro...',
                                                                                                prefixIcon: Icon(Icons.map_outlined)),
                                                                              ),
                                                                  const SizedBox(height: 32),
                                                                  SizedBox(width: double.infinity, child: ElevatedButton.icon(
                                                                                icon: const Icon(Icons.check),
                                                                                label: Text(isEdit ? 'Salvar Alteracoes' : 'Publicar Anuncio'),
                                                                                onPressed: _saving ? null : _save)),
                                                                  const SizedBox(height: 8),
                                                                  if (!isEdit)
                                                                    Center(child: Text('Expira em 48h automaticamente',
                                                                                                     style: TextStyle(fontSize: 11, color: AppTheme.textSecondary,
                                                                                                                                      fontStyle: FontStyle.italic))),
                                                                ]))),
                );
    }
}
