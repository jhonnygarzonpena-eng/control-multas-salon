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
  List<Map<String, dynamic>> _sugerencias = [];

  // Normalizar texto (para manejar ñ, acentos, etc.)
  String _normalizar(String texto) {
    return texto
        .toLowerCase()
        .replaceAll('ñ', 'n')
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u');
  }

  // Buscador potente
  Future<void> _buscarDeudores(String query) async {
    if (query.length < 2) {
      setState(() => _sugerencias = []);
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('movimientos')
        .limit(50)
        .get();

    final Map<String, Map<String, dynamic>> tempMap = {};
    final String queryNormal = _normalizar(query);

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final String nombreRaw = (data['nombreDeudor'] as String? ?? '').trim();
      if (nombreRaw.isEmpty) continue;

      final String nombreNormal = _normalizar(nombreRaw);
      final String nombreMostrar = nombreRaw.toUpperCase();

      // Busca si coincide con la consulta normalizada
      if (!nombreNormal.contains(queryNormal)) continue;

      if (!tempMap.containsKey(nombreMostrar)) {
        tempMap[nombreMostrar] = {
          'nombre': nombreMostrar,
          'multas': 0,
          'pagos': 0,
        };
      }

      final valor = (data['valor'] ?? 0).toInt();
      if (data['tipo'] == 'multa') {
        tempMap[nombreMostrar]!['multas'] += valor;
      } else if (data['tipo'] == 'pago') {
        tempMap[nombreMostrar]!['pagos'] += valor;
      }
    }

    setState(() {
      _sugerencias = tempMap.values.toList();
    });
  }

  Future<void> _guardarMulta() async {
    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty || _valorController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nombre y valor son obligatorios")),
      );
      return;
    }

    final valor = int.tryParse(_valorController.text) ?? 0;

    await FirebaseFirestore.instance.collection('movimientos').add({
      'tipo': 'multa',
      'nombreDeudor': nombre.toLowerCase(),
      'valor': valor,
      'descripcion': _categoriaSeleccionada,
      'motivo': _motivoController.text.trim().isEmpty
          ? _categoriaSeleccionada ?? 'Sin motivo'
          : _motivoController.text.trim(),
      'fecha': Timestamp.now(),
      'registradoPor': 'admin',
    });

    _valorController.clear();
    _motivoController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Multa registrada correctamente"), backgroundColor: Colors.green),
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

          // BUSCADOR CON TARJETAS
          Autocomplete<Map<String, dynamic>>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.length < 2) return const Iterable.empty();
              return _sugerencias.where((deudor) =>
                  deudor['nombre'].toString().toLowerCase().contains(textEditingValue.text.toLowerCase()));
            },
            displayStringForOption: (deudor) => deudor['nombre'],
            onSelected: (Map<String, dynamic> deudor) {
              _nombreController.text = deudor['nombre'];
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: _buscarDeudores,
                decoration: const InputDecoration(
                  labelText: "Nombre del Aprendiz",
                  hintText: "Escribe nombre o apellido...",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.92,
                    constraints: const BoxConstraints(maxHeight: 350),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final deudor = options.elementAt(index);
                        final saldo = deudor['multas'] - deudor['pagos'];

                        return ListTile(
                          leading: Icon(
                            saldo > 0 ? Icons.warning_amber_rounded : Icons.paid,
                            color: saldo > 0 ? Colors.red : Colors.green,
                          ),
                          title: Text(deudor['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            "Multas: \$${deudor['multas']} | Pagos: \$${deudor['pagos']}",
                          ),
                          trailing: Text(
                            "\$$saldo",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: saldo > 0 ? Colors.red : Colors.green,
                            ),
                          ),
                          onTap: () => onSelected(deudor),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

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