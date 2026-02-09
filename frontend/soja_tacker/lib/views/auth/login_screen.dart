// lib/views/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../routes/app_routes.dart';
import '../../viewmodels/auth/auth_vm.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();

  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final vm = context.read<AuthVM>();
    final token = await vm.login(
      email: _emailCtrl.text.trim(),
      senha: _senhaCtrl.text,
    );

    if (!mounted) return;

    if (token != null) {
      // Depois do login, o fluxo decide farms/shell.
      Navigator.pushReplacementNamed(context, AppRoutes.farms);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Consumer<AuthVM>(
      builder: (_, vm, __) {
        final disabled = vm.loading;

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),

                      // Header
                      _HeaderBrand(
                        title: 'Trader Soja',
                        subtitle: 'Acesse sua conta para continuar',
                      ),

                      const SizedBox(height: 18),

                      // Error banner
                      if (vm.error != null) ...[
                        _ErrorBanner(message: vm.error!.message),
                        const SizedBox(height: 12),
                      ],

                      // Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Entrar',
                                  style: t.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Informe seus dados de acesso.',
                                  style: t.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 18),

                                // Email
                                TextFormField(
                                  controller: _emailCtrl,
                                  enabled: !disabled,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    hintText: 'seuemail@exemplo.com',
                                    prefixIcon: Icon(Icons.mail_outline),
                                  ),
                                  validator: (v) {
                                    final s = (v ?? '').trim();
                                    if (s.isEmpty) return 'Informe o email.';
                                    if (!s.contains('@') || !s.contains('.')) {
                                      return 'Email inválido.';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 12),

                                // Senha
                                TextFormField(
                                  controller: _senhaCtrl,
                                  enabled: !disabled,
                                  obscureText: _obscure,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.password],
                                  onFieldSubmitted: (_) => disabled ? null : _doLogin(),
                                  decoration: InputDecoration(
                                    labelText: 'Senha',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
                                      onPressed: disabled
                                          ? null
                                          : () => setState(() => _obscure = !_obscure),
                                      icon: Icon(
                                        _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                  validator: (v) {
                                    final s = (v ?? '');
                                    if (s.isEmpty) return 'Informe a senha.';
                                    if (s.length < 4) return 'Senha muito curta.';
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 16),

                                // CTA
                                SizedBox(
                                  height: 48,
                                  child: FilledButton(
                                    onPressed: disabled ? null : _doLogin,
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 150),
                                      child: disabled
                                          ? const SizedBox(
                                              key: ValueKey('loading'),
                                              height: 18,
                                              width: 18,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : const Text(
                                              'Entrar',
                                              key: ValueKey('text'),
                                            ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Secondary actions
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: disabled
                                            ? null
                                            : () => Navigator.pushNamed(context, AppRoutes.register),
                                        icon: const Icon(Icons.person_add_alt_1_outlined),
                                        label: const Text('Criar conta'),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  'Ao entrar, você poderá selecionar uma fazenda e acessar o painel.',
                                  style: t.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Footer
                      Text(
                        '© ${DateTime.now().year} Trader Soja',
                        textAlign: TextAlign.center,
                        style: t.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// ----------------------------
/// Header brand
/// ----------------------------
class _HeaderBrand extends StatelessWidget {
  final String title;
  final String subtitle;

  const _HeaderBrand({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.grass, color: cs.onPrimaryContainer),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: t.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// ----------------------------
/// Error banner
/// ----------------------------
class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.error.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: cs.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: cs.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
