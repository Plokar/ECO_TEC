import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import '../theme/tokens.dart';
import '../widgets.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _register = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
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
          // Name, city and avatar are collected by the walkthrough right after
          // this, where they come with an explanation of what they do. Asking
          // for the name here as well only made people type it twice.
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

  /// Sends the reset mail. Says the same thing whether or not the address is
  /// registered — confirming which emails have accounts is an enumeration leak.
  Future<void> _reset() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Enter your email first, then tap this.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await auth.sendPasswordReset(email);
    } on FirebaseAuthException catch (e) {
      if (e.code != 'user-not-found') {
        setState(() => _error = _friendly(e));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('If $email has an account, a reset link is on its way.')),
      );
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
    backgroundColor: Colors.transparent,
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
                    style: display(size: 34),
                  ),
                  const SizedBox(height: Tokens.s8),
                  Row(
                    children: [
                      const Flower(size: 18),
                      const SizedBox(width: Tokens.s8),
                      Expanded(
                        child: Text(
                          'Pick up real litter, roll for rare finds, and take '
                          'your city up the table.',
                          style: ui(size: 14, color: Tokens.inkDim),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Tokens.s24),

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

                  // Password reset is not optional in a real app: without it,
                  // a forgotten password is a lost account and a support email.
                  if (!_register)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _busy ? null : _reset,
                        child: const Text('Forgot password?'),
                      ),
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
                              strokeWidth: 2.5,
                              color: Tokens.ink,
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
  Widget build(BuildContext context) =>
      const Align(alignment: Alignment.centerLeft, child: Wordmark(size: 38));
}
