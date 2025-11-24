import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

// Enum untuk State Tampilan
enum AuthState { welcome, login, register }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  AuthState _authState = AuthState.welcome;

  void _switchState(AuthState newState) {
    setState(() {
      _authState = newState;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface, // PERBAIKAN 1: Ganti background jadi surface
              colorScheme.surface,
              colorScheme.surface, // PERBAIKAN 1: Gunakan surface agar konsisten di M3
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  _buildLogo(colorScheme),
                  const SizedBox(height: 48),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.2, 0.0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: _buildContent(_authState),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(ColorScheme colors) {
    return Column(
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ],
          ), // Tutup BoxDecoration di sini
          // Pindahkan child ke sini (milik Container)
          child: const Icon(Icons.work_outline, size: 50, color: Color(0xFFD90429)),
        ),
        const SizedBox(height: 24),
        Text(
          "SITEKAD",
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: colors.primary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Sistem Informasi Tenaga Kerja Ahli Daya",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: colors.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(AuthState state) {
    switch (state) {
      case AuthState.welcome:
        return WelcomeButtons(
          onLoginClick: () => _switchState(AuthState.login),
          onRegisterClick: () => _switchState(AuthState.register),
        );
      case AuthState.login:
        return LoginForm(onBackClick: () => _switchState(AuthState.welcome));
      case AuthState.register:
        return RegisterForm(
          onBackClick: () => _switchState(AuthState.welcome),
          onRegisterSuccess: () => _switchState(AuthState.login),
        );
    }
  }
}

class WelcomeButtons extends StatelessWidget {
  final VoidCallback onLoginClick;
  final VoidCallback onRegisterClick;

  const WelcomeButtons({
    super.key,
    required this.onLoginClick,
    required this.onRegisterClick,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onLoginClick,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                child: const Text("LOGIN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: onRegisterClick,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Theme.of(context).colorScheme.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("REGISTRASI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  final VoidCallback onBackClick;

  const LoginForm({super.key, required this.onBackClick});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                "Selamat Datang Kembali",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: "Username",
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) => value!.isEmpty ? "Username tidak boleh kosong" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
                textInputAction: TextInputAction.done,
                validator: (value) => value!.isEmpty ? "Password tidak boleh kosong" : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            final success = await authProvider.login(
                              _usernameController.text,
                              _passwordController.text,
                            );
                            if (!success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(authProvider.errorMessage ?? "Gagal Login"), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: authProvider.isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("MASUK", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              TextButton(
                onPressed: widget.onBackClick,
                child: Text("Kembali", 
                  // PERBAIKAN 2: Ganti .withOpacity jadi .withValues
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterForm extends StatefulWidget {
  final VoidCallback onBackClick;
  final VoidCallback onRegisterSuccess;

  const RegisterForm({super.key, required this.onBackClick, required this.onRegisterSuccess});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nitadController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                "Buat Akun Baru",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nitadController,
                decoration: const InputDecoration(
                  labelText: "NITAD / Nama Lengkap",
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) => value!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: "Username",
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) => value!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
                textInputAction: TextInputAction.done,
                validator: (value) => value!.length < 4 ? "Password minimal 4 karakter" : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            final success = await authProvider.register(
                              _nitadController.text,
                              _usernameController.text,
                              _passwordController.text,
                            );
                            
                            if (context.mounted) {
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Registrasi Berhasil! Silakan Login"), backgroundColor: Colors.green),
                                );
                                widget.onRegisterSuccess();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(authProvider.errorMessage ?? "Registrasi Gagal"), backgroundColor: Colors.red),
                                );
                              }
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: authProvider.isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("DAFTAR", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: widget.onBackClick,
                child: Text("Kembali", 
                  // PERBAIKAN 2: Ganti .withOpacity jadi .withValues
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}