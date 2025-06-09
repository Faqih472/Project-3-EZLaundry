import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:golaundry/pages/home.dart';
import 'register.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  void _loadSavedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    emailController.text = prefs.getString('email') ?? '';
    passwordController.text = prefs.getString('password') ?? '';
  }

  Future<void> login() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', emailController.text.trim());
        await prefs.setString('password', passwordController.text.trim());

        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (doc.exists && doc.data()!.containsKey('role')) {
          final role = doc['role'];

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MyHomePage(role: role)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Data pengguna tidak ditemukan di Firestore atau peran tidak ada")),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login gagal: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F2F7), // Latar belakang biru muda lembut
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0), // Padding horizontal sedikit dikurangi
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- Bagian Logo dan Judul Aplikasi ---
              Image.asset(
                'assets/icon/app_icon.png',
                height: 90, // Ukuran ikon disesuaikan, tidak terlalu besar
              ),
              const SizedBox(height: 24), // Spasi yang pas
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                child: Text(
                  "EZLaundry",
                  style: GoogleFonts.poppins(
                    fontSize: 42, // **UKURAN FONT JUDUL DIKURANGI**
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        offset: Offset(2.0, 2.0), // Bayangan lebih halus
                        blurRadius: 4.0,
                        color: Colors.black45,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16), // Spasi yang pas
              Text(
                "🧺 Layanan laundry terpercaya untuk pakaian bersih dan rapi Anda.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15, // **UKURAN FONT TEKS SAMBUTAN DIKURANGI**
                  fontWeight: FontWeight.w500,
                  color: Colors.blueGrey[700],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 48), // Spasi yang cukup sebelum form

              // --- Bagian Form Login ---
              Container(
                padding: const EdgeInsets.all(28), // Padding container disesuaikan
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18), // Sudut lebih proporsional
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08), // Bayangan lebih tipis
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Alamat Email",
                        hintText: "example@email.com",
                        prefixIcon: Icon(Icons.email_outlined, color: Colors.blue.shade700),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10), // Sudut input field disesuaikan
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.blue.shade50,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16), // Padding input field
                      ),
                      style: GoogleFonts.poppins(fontSize: 14), // **UKURAN FONT INPUT DIKURANGI**
                    ),
                    const SizedBox(height: 20), // Spasi antar input
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Kata Sandi",
                        hintText: "Minimal 6 karakter",
                        prefixIcon: Icon(Icons.lock_outline, color: Colors.blue.shade700),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.blue.shade50,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      ),
                      style: GoogleFonts.poppins(fontSize: 14), // **UKURAN FONT INPUT DIKURANGI**
                    ),
                    const SizedBox(height: 30), // Spasi sebelum tombol login
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: login,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18), // Padding tombol disesuaikan
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15), // Sudut tombol disesuaikan
                          ),
                          backgroundColor: Colors.blue.shade800,
                          foregroundColor: Colors.white,
                          elevation: 6, // Elevasi tombol sedikit dikurangi
                          shadowColor: Colors.blue.shade900.withOpacity(0.3), // Warna bayangan tombol lebih lembut
                        ),
                        child: Text(
                          "MASUK",
                          style: GoogleFonts.poppins(
                            fontSize: 18, // **UKURAN FONT TOMBOL DIKURANGI**
                            fontWeight: FontWeight.w700, // Bobot font tetap tebal
                            letterSpacing: 0.6, // Spasi antar huruf sedikit dikurangi
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16), // Spasi setelah tombol login
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RegisterPage()),
                        );
                      },
                      child: Text(
                        "Belum punya akun? Daftar Sekarang!",
                        style: GoogleFonts.poppins(
                          fontSize: 14, // **UKURAN FONT TEKS DAFTAR DIKURANGI**
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}