import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Fungsi untuk login
  Future<User?> loginWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;  // Mengembalikan user jika login berhasil
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  // Fungsi untuk register
  Future<User?> registerWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;  // Mengembalikan user jika registrasi berhasil
    } catch (e) {
      print('Register error: $e');
      return null;
    }
  }

  // Fungsi untuk logout
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }
}
