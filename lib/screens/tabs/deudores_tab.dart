import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detalle_deudor_screen.dart';

class DeudoresTab extends StatefulWidget {
  const DeudoresTab({super.key});

  @override
  State<DeudoresTab> createState() => _DeudoresTabState();
}

class _DeudoresTabState extends State<DeudoresTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ==================== BUSCADOR ====================
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() => _searchQuery = value.toLowerCase());
            },
            decoration: InputDecoration(
              hintText: "Buscar deudor...",
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),

        // ==================== LISTA DE DEUDORES ====================
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('movimientos')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No hay movimientos registrados"));
              }

              // Agrupar por deudor
              final Map<String, Map<String, dynamic>> deudoresMap = {};

              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final nombre = (data['nombreDeudor'] ?? '').toString().toLowerCase();
                final valor = (data['valor'] ?? 0).toInt();
                final tipo = (data['tipo'] ?? '').toString().toLowerCase();

                if (nombre.isEmpty) continue;

                deudoresMap.putIfAbsent(nombre, () => {
                  'nombre': nombre,
                  'multas': 0,
                  'pagos': 0,
                });

                if (tipo == 'multa') {
                  deudoresMap[nombre]!['multas'] += valor;
                } else if (tipo == 'pago') {
                  deudoresMap[nombre]!['pagos'] += valor;
                }
              }

              // Filtrar por búsqueda
              var deudoresList = deudoresMap.values.toList();

              if (_searchQuery.isNotEmpty) {
                deudoresList = deudoresList.where((d) {
                  return d['nombre'].toString().contains(_searchQuery);
                }).toList();
              }

              // Ordenar por saldo (mayor deuda primero)
              deudoresList.sort((a, b) {
                final saldoA = a['multas'] - a['pagos'];
                final saldoB = b['multas'] - b['pagos'];
                return saldoB.compareTo(saldoA);
              });

              if (deudoresList.isEmpty) {
                return const Center(child: Text("No se encontraron deudores"));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: deudoresList.length,
                itemBuilder: (context, index) {
                  final deudor = deudoresList[index];
                  final saldo = deudor['multas'] - deudor['pagos'];
                  final nombreMostrar = deudor['nombre'].toString().toUpperCase();

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    color: saldo > 0 ? Colors.red[50] : Colors.green[50],
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                      title: Text(nombreMostrar, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        "Multas: \$${deudor['multas']} | Pagos: \$${deudor['pagos']}",
                        style: const TextStyle(fontSize: 13),
                      ),
                      trailing: Text(
                        "\$$saldo",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: saldo > 0 ? Colors.red : Colors.green,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetalleDeudorScreen(nombreDeudor: deudor['nombre']),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}