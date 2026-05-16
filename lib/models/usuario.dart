enum Rol {
  admin,
  subadmin,
  usuario,
}

class AppUsuario {
  final String uid;
  final String nombre;
  final String email;
  final Rol rol;

  AppUsuario({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.rol,
  });

  // Convertir desde Firestore
  factory AppUsuario.fromMap(Map<String, dynamic> map, String uid) {
    return AppUsuario(
      uid: uid,
      nombre: map['nombre'] ?? 'Sin nombre',
      email: map['email'] ?? '',
      rol: _parseRol(map['rol']),
    );
  }

  // Convertir a Firestore
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'email': email,
      'rol': rol.name,   // Guarda como string: "admin", "subadmin", "usuario"
    };
  }

  static Rol _parseRol(dynamic rol) {
    if (rol == null) return Rol.usuario;
    switch (rol.toString().toLowerCase()) {
      case 'admin':
        return Rol.admin;
      case 'subadmin':
        return Rol.subadmin;
      default:
        return Rol.usuario;
    }
  }
}