import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrarMultaTab extends StatefulWidget {
  const RegistrarMultaTab({super.key});

  @override
  State<RegistrarMultaTab> createState() => _RegistrarMultaTabState();
}

class _RegistrarMultaTabState extends State<RegistrarMultaTab> {
  // Controladores con valores iniciales
  final _nombreController = TextEditingController();
  final _valorController = TextEditingController(text: "2000");
  final _motivoController = TextEditingController();

  String _tipoMulta = "Grosería";
  final List<String> _tipos = ["Grosería", "Llegó tarde", "Falta de respeto", "Otra"];

  // Función para mostrar mensajes sin repetir código
  void _mostrarSnackBar(String mensaje, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
      ),
    );
  }

  Future<void> _registrarMulta() async {
    final nombre = _nombreController.text.trim();
    final motivo = _motivoController.text.trim();
    final valor = int.tryParse(_valorController.text) ?? 0;

    // Validaciones iniciales
    if (nombre.isEmpty) {
      _mostrarSnackBar("Ingrese el nombre del deudor", color: Colors.red);
      return;
    }

    if (valor <= 0) {
      _mostrarSnackBar("Ingrese un valor válido", color: Colors.red);
      return;
    }

    try {
      // Operación asíncrona
      await FirebaseFirestore.instance.collection('movimientos').add({
        'tipo': 'multa',
        'nombreDeudor': nombre.toLowerCase(),
        'valor': valor,
        'descripcion': _tipoMulta,
        'motivo': motivo.isEmpty ? 'Sin motivo' : motivo,
        'fecha': Timestamp.now(),
        'registradoPor': "admin",
      });

      // GUARDIA: Verificación de montaje después del await
      if (!mounted) return;

      _mostrarSnackBar("✅ Multa registrada correctamente", color: Colors.green);

      // Limpiar formulario tras éxito
      setState(() {
        _nombreController.clear();
        _motivoController.clear();
        _valorController.text = "2000";
        _tipoMulta = "Grosería";
      });

    } catch (e) {
      // GUARDIA: Verificación de montaje en caso de error
      if (!mounted) return;
      _mostrarSnackBar("Error al registrar: $e", color: Colors.red);
    }
  }

  @override
  void dispose() {
    // Es buena práctica liberar los controladores
    _nombreController.dispose();
    _valorController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Nueva Multa",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: "Nombre del Aprendiz",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              initialValue: _tipoMulta,
              decoration: const InputDecoration(
                labelText: "Categoría de la Multa",
                border: OutlineInputBorder(),
              ),
              items: _tipos.map((String tipo) {
                return DropdownMenuItem(value: tipo, child: Text(tipo));
              }).toList(),
              onChanged: (nuevoValor) {
                setState(() {
                  _tipoMulta = nuevoValor!;
                });
              },
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _valorController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Valor (COP)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _motivoController,
              decoration: const InputDecoration(
                labelText: "Motivo adicional (Opcional)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              onPressed: _registrarMulta,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.save),
              label: const Text("GUARDAR REGISTRO"),
            ),
          ],
        ),
      ),
    );
  }
}