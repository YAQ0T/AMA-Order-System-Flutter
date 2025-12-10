import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_notifier.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  static const String routeName = '/signup';

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'maker';

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthNotifier auth) async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await auth.signup(_usernameController.text.trim(), _passwordController.text, _role);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created. Awaiting approval if required.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();

    return Scaffold(
      appBar: AppBar(title: const Text('Sign up')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Username'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Username is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: (value) =>
                          value == null || value.length < 6 ? 'Min 6 characters' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _role,
                      items: const [
                        DropdownMenuItem(value: 'maker', child: Text('Maker')),
                        DropdownMenuItem(value: 'taker', child: Text('Taker')),
                        DropdownMenuItem(value: 'accounter', child: Text('Accounter')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      ],
                      onChanged: (value) => setState(() => _role = value ?? 'maker'),
                      decoration: const InputDecoration(labelText: 'Role'),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: auth.isLoading ? null : () => _submit(auth),
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Create account'),
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
