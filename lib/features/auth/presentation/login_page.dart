import 'package:flutter/material.dart';

/// H1 Login — kerangka saja; implementasi autentikasi Firebase pada Tahap 5.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Autentikasi email/password dibangun pada Tahap 5.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
