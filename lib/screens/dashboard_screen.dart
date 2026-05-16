import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

import 'tabs/registrar_multa_tab.dart';
import 'tabs/deudores_tab.dart';
import 'tabs/historial_tab.dart';
import 'tabs/resumen_tab.dart';
import 'register_user_screen.dart';
import 'import_json_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    final bool esAdmin = auth.isAdmin || auth.isSubAdmin;

    final List<Widget> pantallas = esAdmin
        ? [
            const RegistrarMultaTab(),
            const DeudoresTab(),
            const HistorialTab(),
            const ResumenTab(),
          ]
        : [
            const HistorialTab(),
            const ResumenTab(),
          ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Multas del Salón 💰'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Correo electrónico
                Text(
                  auth.usuarioActual?.email ?? 'Sin correo',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                // Nombre y Rol
                Text(
                  "${(auth.usuarioActual?.nombre ?? 'Usuario').toUpperCase()} (${auth.usuarioActual?.rol.name.toUpperCase()})",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          if (auth.isAdmin)
            IconButton(
              icon: const Icon(Icons.upload_file),
              tooltip: "Importar JSON",
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportJsonScreen())),
            ),

          if (auth.isAdmin)
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: "Crear Usuario",
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterUserScreen())),
            ),

          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),

      body: pantallas[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: esAdmin
            ? const [
                BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Registrar'),
                BottomNavigationBarItem(icon: Icon(Icons.people_alt), label: 'Deudores'),
                BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historial'),
                BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Resumen'),
              ]
            : const [
                BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historial'),
                BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Resumen'),
              ],
      ),
    );
  }
}