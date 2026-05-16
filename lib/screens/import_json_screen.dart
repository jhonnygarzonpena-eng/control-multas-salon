import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ImportJsonScreen extends StatefulWidget {
  const ImportJsonScreen({super.key});

  @override
  State<ImportJsonScreen> createState() => _ImportJsonScreenState();
}

class _ImportJsonScreenState extends State<ImportJsonScreen> {
  final TextEditingController _jsonController = TextEditingController();
  bool _isLoading = false;
  String _mensaje = '';

  Future<void> _importarJson() async {
    if (_jsonController.text.trim().isEmpty) {
      setState(() => _mensaje = "❌ Pega el JSON primero");
      return;
    }

    setState(() { 
      _isLoading = true; 
      _mensaje = "Importando..."; 
    });

    try {
      final dynamic decoded = jsonDecode(_jsonController.text);
      
      // Soporta ambos formatos: array directo o { "registros": [...] }
      List<dynamic> multas = [];
      
      if (decoded is Map && decoded['registros'] != null) {
        multas = decoded['registros'];
      } else if (decoded is List) {
        multas = decoded;
      } else {
        multas = [decoded];
      }

      int count = 0;

      for (var m in multas) {
        await FirebaseFirestore.instance.collection('movimientos').add({
          'nombreDeudor': (m['nombre'] ?? '').toString().toLowerCase().trim(),
          'valor': (m['valor'] ?? 0).toInt(),
          'descripcion': m['descripcion'] ?? m['descripion'] ?? '',
          'motivo': m['motivo'] ?? 'Sin motivo',
          'tipo': m['tipo'] ?? 'multa',
          'fecha': Timestamp.now(),
          'registradoPor': 'importado_admin',
          'id_original': m['id'],
        });
        count++;
      }

      setState(() {
        _mensaje = "✅ $count multas importadas correctamente";
      });
    } catch (e) {
      setState(() => _mensaje = "❌ Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Importar JSON"),
        backgroundColor: Colors.amber,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _jsonController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Pega aquí todo tu JSON completo...',
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _importarJson,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("IMPORTAR TODAS LAS MULTAS", style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 20),
            Text(_mensaje, 
                 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                 textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}