import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrarMultaTab extends StatefulWidget {
  const RegistrarMultaTab({super.key});

  @override
  State<RegistrarMultaTab> createState() => _RegistrarMultaTabState();
}

class _RegistrarMultaTabState extends State<RegistrarMultaTab> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _motivoController = TextEditingController();

  String? _categoriaSeleccionada = "Otra";

  // Buscar deudores existentes directamente desde Firestore de forma limpia
  Future<List<String>> _obtenerSugerenciasFirebase(String query) async {
    if (query.length < 2) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('movimientos')
        .where('nombreDeudor', isGreaterThanOrEqualTo: query.toLowerCase())
        .where('nombreDeudor', isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
        .limit(15) // Un margen extra antes de remover duplicados
        .get();

    return snapshot.docs
        .map((doc) => (doc.data()['nombreDeudor'] as String).toUpperCase())
        .toSet() // Remueve duplicados automáticamente
        .toList();
  }

  Future<void> _guardarMulta() async {
    if (_nombreController.text.trim().isEmpty || _valorController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nombre y valor son obligatorios")),
      );
      return;
    }

    final valor = int.tryParse(_valorController.text) ?? 0;

    await FirebaseFirestore.instance.collection('movimientos').add({
      'tipo': 'multa',
      'nombreDeudor': _nombreController.text.trim().toLowerCase(),
      'valor': valor,
      'descripcion': _categoriaSeleccionada,
      'motivo': _motivoController.text.trim().isEmpty 
          ? _categoriaSeleccionada 
          : _motivoController.text.trim(),
      'fecha': Timestamp.now(),
      'registradoPor': 'admin',
    });

    _nombreController.clear();
    _valorController.clear();
    _motivoController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Multa registrada correctamente"), 
          backgroundColor: Colors.green
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Nueva Multa", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),

          const SizedBox(height: 20),

          // BUSCADOR CON AUTOCOMPLETAR REESTRUCTURADO
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) async {
              if (textEditingValue.text.length < 2) {
                return const Iterable<String>.empty();
              }
              // Llama a la base de datos de manera limpia y síncrona para el Widget
              return await _obtenerSugerenciasFirebase(textEditingValue.text);
            },
            onSelected: (String selection) {
              _nombreController.text = selection;
            },
            fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
              // Sincronizamos el controlador interno del Autocomplete con el nuestro global
              if (_nombreController.text != textController.text && _nombreController.text.isEmpty) {
                textController.text = _nombreController.text;
              }
              
              return TextField(
                controller: textController,
                focusNode: focusNode,
                onChanged: (val) {
                  _nombreController.text = val;
                },
                decoration: const InputDecoration(
                  labelText: "Nombre del Aprendiz",
                  prefixIcon: Icon(Icons.person_search),
                  border: OutlineInputBorder(),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _categoriaSeleccionada,
            decoration: const InputDecoration(
              labelText: "Categoría de la Multa",
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: "Uniforme", child: Text("Uniforme")),
              DropdownMenuItem(value: "Aseo", child: Text("Aseo")),
              DropdownMenuItem(value: "Grosería", child: Text("Grosería")),
              DropdownMenuItem(value: "Otra", child: Text("Otra")),
            ],
            onChanged: (value) => setState(() => _categoriaSeleccionada = value),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _valorController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Valor (COP)",
              prefixText: "\$ ",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _motivoController,
            decoration: const InputDecoration(
              labelText: "Motivo adicional (Opcional)",
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: _guardarMulta,
              icon: const Icon(Icons.save),
              label: const Text("GUARDAR REGISTRO", style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}