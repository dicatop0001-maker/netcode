import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import 'home_screen.dart';

class NicknameScreen extends StatefulWidget {
  const NicknameScreen({super.key});
  @override State<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> {
  final _ctrl = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _loading = false;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    await StorageService.saveNickname(_ctrl.text.trim());
    if (!mounted) return;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 48),
            const Icon(Icons.wifi_tethering_rounded, size: 52, color: AppTheme.primary),
            const SizedBox(height: 16),
            const Text('Boas-vindas!', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Escolha um apelido para entrar na rede local.',
                style: TextStyle(fontSize: 15, color: AppTheme.textSecondary)),
            const SizedBox(height: 48),
            TextFormField(
              controller: _ctrl, autofocus: true, maxLength: 20,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              decoration: const InputDecoration(
                labelText: 'Apelido (nickname)', counterText: '',
                prefixIcon: Icon(Icons.person_outline)),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Digite um apelido';
                if (v.trim().length < 2) return 'Minimo 2 caracteres';
                return null;
              }),
            const SizedBox(height: 12),
            const Text('Sem conta. Sem senha. Sem e-mail.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic)),
            const Spacer(),
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading
                  ? const SizedBox(width: 24, height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('Entrar na rede'))),
          ])),
        ),
      ),
    );
  }
}
