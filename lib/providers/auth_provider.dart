import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/usuario.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppUsuario? _usuarioActual;
  AppUsuario? get usuarioActual => _usuarioActual;

  bool get isLoggedIn => _usuarioActual != null;
  bool get isAdmin => _usuarioActual?.rol == Rol.admin;
  bool get isSubAdmin => _usuarioActual?.rol == Rol.admin || _usuarioActual?.rol == Rol.subadmin;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _loadUserData(user.uid);
      } else {
        _usuarioActual = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection('usuarios').doc(uid).get();
      if (doc.exists) {
        _usuarioActual = AppUsuario.fromMap(doc.data()!, uid);
      }
      notifyListeners();
    } catch (e) {
      // Error silencioso (mejor práctica)
      _usuarioActual = null;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<void> registrarUsuario({
    required String email,
    required String password,
    required String nombre,
    required Rol rol,
  }) async {
    final credencial = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final nuevoUsuario = AppUsuario(
      uid: credencial.user!.uid,
      nombre: nombre,
      email: email.trim(),
      rol: rol,
    );

    await _firestore.collection('usuarios').doc(credencial.user!.uid).set(nuevoUsuario.toMap());
  }

  Future<void> reAutenticar(String password) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No hay usuario autenticado");

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}