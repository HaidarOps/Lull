import 'package:flutter/material.dart';
import 'package:meditation/shared/app_components.dart';
import 'package:meditation/shared/app_layout.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const authRedirectUrl = 'io.seren.meditation://auth-callback';
const _authBackground = Color(0xFF101715);
const _authSurface = Color(0xFF192320);
const _authText = Color(0xFFF5F7F3);
const _authAccent = Color(0xFFA8D7C6);

ThemeData _authTheme(BuildContext context) => Theme.of(context).copyWith(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: _authAccent,
    surface: _authSurface,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: _authSurface,
    labelStyle: const TextStyle(color: _authAccent),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF43534C)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _authAccent),
    ),
  ),
);

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _controller = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_controller.text.length < 6 || _busy) {
      setState(() => _error = 'Use at least 6 characters.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _controller.text),
      );
      widget.onComplete();
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not update password. Try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _authTheme(context),
      child: ResponsivePage(
        backgroundColor: _authBackground,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 72),
            const Text(
              'New password',
              style: TextStyle(
                fontSize: 29,
                color: _authText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFAC4A4A)),
                ),
              ),
            const SizedBox(height: 28),
            AppPrimaryButton(
              label: 'Save password',
              onPressed: _busy ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

class SetupErrorPage extends StatelessWidget {
  const SetupErrorPage({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ResponsivePage(
      backgroundColor: _authBackground,
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _authText, fontSize: 18),
        ),
      ),
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({
    super.key,
    required this.onExplore,
    this.startWithSignUp = false,
  });

  final VoidCallback onExplore;
  final bool startWithSignUp;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late bool _signUp = widget.startWithSignUp;
  bool _busy = false;
  bool _hidePassword = true;
  String? _message;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final auth = Supabase.instance.client.auth;
      if (_signUp) {
        final response = await auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          emailRedirectTo: authRedirectUrl,
          data: {'display_name': _nameController.text.trim()},
        );
        if (mounted && response.session == null) {
          setState(
            () => _message =
                'Check your email to confirm your account, then sign in.',
          );
        }
      } else {
        await auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'Could not connect. Check your internet connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      setState(() => _message = 'Enter your email address first.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: authRedirectUrl,
      );
      if (mounted) {
        setState(
          () => _message = 'Password reset link sent. Check your email.',
        );
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Could not connect. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gap = AppLayout.clampedHeightValue(
      context,
      factor: 0.045,
      min: 22,
      max: 46,
    );
    return Theme(
      data: _authTheme(context),
      child: ResponsivePage(
        backgroundColor: _authBackground,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: gap),
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFDAE6EC),
                  ),
                  child: Image.asset('assets/icons/branch.png'),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Seren',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 44,
                  color: _authText,
                ),
              ),
              SizedBox(height: gap),
              Text(
                _signUp ? 'Create your account' : 'Welcome back',
                style: const TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.w600,
                  color: _authText,
                ),
              ),
              const SizedBox(height: 22),
              if (_signUp) ...[
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  decoration: const InputDecoration(labelText: 'Your name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter your name'
                      : null,
                ),
                const SizedBox(height: 14),
              ],
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) =>
                    value == null ||
                        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(value.trim())
                    ? 'Enter a valid email'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                obscureText: _hidePassword,
                autofillHints: [
                  if (_signUp)
                    AutofillHints.newPassword
                  else
                    AutofillHints.password,
                ],
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    tooltip: _hidePassword ? 'Show password' : 'Hide password',
                    onPressed: () =>
                        setState(() => _hidePassword = !_hidePassword),
                    icon: Icon(
                      _hidePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) => value == null || value.length < 6
                    ? 'Use at least 6 characters'
                    : null,
                onFieldSubmitted: (_) => _submit(),
              ),
              if (!_signUp)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _busy ? null : _resetPassword,
                    child: const Text('Forgot password?'),
                  ),
                ),
              if (_message != null) ...[
                const SizedBox(height: 12),
                Text(
                  _message!,
                  style: const TextStyle(color: Color(0xFFAC4A4A)),
                ),
              ],
              SizedBox(height: gap),
              AppPrimaryButton(
                label: _signUp ? 'Create account' : 'Sign in',
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        _signUp = !_signUp;
                        _message = null;
                        _formKey.currentState?.reset();
                      }),
                child: Text(
                  _signUp
                      ? 'Already have an account? Sign in'
                      : 'New to Seren? Create an account',
                ),
              ),
              TextButton(
                onPressed: widget.onExplore,
                child: const Text('Explore the introduction'),
              ),
              SizedBox(height: gap),
            ],
          ),
        ),
      ),
    );
  }
}
