import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

const gitClientId = 'Ov23liFPLhhHgjmTWG9G';
const gitClientSecret = '013201df3400ee3daf67060d1232fcdea37a6e76';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lab 3 Autentificare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AuthSelectionScreen(),
    );
  }
}

class AuthSelectionScreen extends StatefulWidget {
  const AuthSelectionScreen({super.key});

  @override
  State<AuthSelectionScreen> createState() => _AuthSelectionScreenState();
}

class _AuthSelectionScreenState extends State<AuthSelectionScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    // Salvăm un PIN default în storage la pornirea aplicației pentru a-l putea testa
    _setInitialPin();
  }

  Future<void> _setInitialPin() async {
    await storage.write(key: "pin", value: "1234");
  }

  // --- 1. AUTENTIFICARE GITHUB OAUTH ---
  Future<void> signInWithGitHub() async {
    const redirectUri = "lab3://callback";

    try {
      final result = await FlutterWebAuth2.authenticate(
        url: "https://github.com/login/oauth/authorize?client_id=$gitClientId&redirect_uri=$redirectUri",
        callbackUrlScheme: "lab3",
      );

      final code = Uri.parse(result).queryParameters['code'];

      final response = await http.post(
        Uri.parse("https://github.com/login/oauth/access_token"),
        headers: {'Accept': 'application/json'},
        body: {
          'client_id': gitClientId,
          'client_secret': gitClientSecret,
          'code': code,
        },
      );

      final accessToken = jsonDecode(response.body)['access_token'];
      _showMessage("GitHub Autentificare reușită! Token: $accessToken");
    } catch (e) {
      _showMessage("Eroare GitHub: $e");
    }
  }

  // --- 2. AUTENTIFICARE BIOMETRICĂ ---
  Future<void> authenticateBiometric() async {
    try {
      bool authenticated = await auth.authenticate(
        localizedReason: 'Scanează amprenta pentru autentificare',
        biometricOnly: true, // Punem parametrul direct, cum cere versiunea veche
      );

      if (authenticated) {
        _showMessage("Autentificare biometrică reușită!");
      } else {
        _showMessage("Autentificare biometrică respinsă.");
      }
    } catch (e) {
      _showMessage("Eroare biometrică: $e");
    }
  }

  // --- 3. AUTENTIFICARE CU PIN ---
  Future<void> authenticateWithPin() async {
    // În mod normal, aici ai avea un TextField unde utilizatorul introduce PIN-ul.
    // Pentru simplitate în laborator, vom simula introducerea PIN-ului corect:
    const enteredPin = "1234"; 
    
    final savedPin = await storage.read(key: "pin");
    
    if (enteredPin == savedPin) {
      _showMessage("Autentificare cu PIN ($enteredPin) reușită!");
    } else {
      _showMessage("PIN incorect!");
    }
  }

  // Funcție utilitară pentru a afișa mesaje pe ecran
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metode de Autentificare'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: signInWithGitHub,
              icon: const Icon(Icons.code),
              label: const Text('Autentificare GitHub (OAuth)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: authenticateBiometric,
              icon: const Icon(Icons.fingerprint),
              label: const Text('Autentificare Biometrică'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: authenticateWithPin,
              icon: const Icon(Icons.password),
              label: const Text('Autentificare cu PIN'),
            ),
          ],
        ),
      ),
    );
  }
}