import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import '../theme/tokens.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _city = TextEditingController();

  bool _register = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_register) {
        await auth.register(
          email: _email.text,
          password: _password.text,
          displayName: _name.text,
          city: _city.text.trim().isEmpty ? null : _city.text.trim(),
          // ponytail: country is inferred from the city on the server later;
          // asking for both at sign-up costs more drop-off than it's worth.
        );
      } else {
        await auth.signIn(_email.text, _password.text);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendly(e));
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _guest() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await auth.continueAsGuest();
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static String _friendly(FirebaseAuthException e) => switch (e.code) {
    'invalid-email' => 'That email address doesn\'t look right.',
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'Wrong email or password.',
    'email-already-in-use' => 'That email already has an account. Sign in instead.',
    'weak-password' => 'Pick a password of at least 6 characters.',
    'network-request-failed' => 'No connection. Try again when you have signal.',
    'too-many-requests' => 'Too many attempts. Wait a minute and try again.',
    _ => e.message ?? 'Something went wrong. Try again.',
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Tokens.s24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Wordmark(),
                  const SizedBox(height: Tokens.s12),
                  Text(
                    'Save the planet.\nBeat your friends.',
                    style: display(size: 32),
                  ),
                  const SizedBox(height: Tokens.s32),

                  if (_register) ...[
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(hintText: 'Display name'),
                      validator: (v) => (v == null || v.trim().length < 2)
                          ? 'At least 2 characters'
                          : null,
                    ),
                    const SizedBox(height: Tokens.s12),
                    TextFormField(
                      controller: _city,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'City (for your league)',
                      ),
                    ),
                    const SizedBox(height: Tokens.s12),
                  ],

                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(hintText: 'Email'),
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Enter your email'
                        : null,
                  ),
                  const SizedBox(height: Tokens.s12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: const InputDecoration(hintText: 'Password'),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'At least 6 characters'
                        : null,
                    onFieldSubmitted: (_) => _submit(),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: Tokens.s16),
                    Text(_error!, style: ui(size: 14, color: Tokens.alertRed)),
                  ],

                  const SizedBox(height: Tokens.s24),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Tokens.deepForest,
                            ),
                          )
                        : Text(_register ? 'Create account' : 'Sign in'),
                  ),
                  const SizedBox(height: Tokens.s8),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _register = !_register;
                            _error = null;
                          }),
                    child: Text(
                      _register
                          ? 'I already have an account'
                          : 'Create an account',
                      style: ui(size: 14, color: Tokens.questGreen),
                    ),
                  ),
                  const Divider(height: Tokens.s32),
                  OutlinedButton(
                    onPressed: _busy ? null : _guest,
                    child: const Text('Try it without an account'),
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

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text('eco', style: ui(size: 26, weight: FontWeight.w600)),
      Text('Quest', style: display(size: 26, color: Tokens.questGreen)),
    ],
  );
}
