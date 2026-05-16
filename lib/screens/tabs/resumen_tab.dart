import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResumenTab extends StatefulWidget {
  const ResumenTab({super.key});

  @override
  State<ResumenTab> createState() => _ResumenTabState();
}

class _ResumenTabState extends State<ResumenTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('movimientos')
          .orderBy('fecha', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        final Map<String, Map<String, dynamic>> deudores = {};

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final nombreRaw = data['nombreDeudor'] ?? '';
          final nombre = nombreRaw.toString().trim().toUpperCase();
          if (nombre.isEmpty) continue;

          deudores.putIfAbsent(nombre, () => {'multas': 0, 'pagos': 0, 'nombre': nombre});

          final valor = (data['valor'] ?? 0).toInt();
          final tipo = (data['tipo'] ?? 'multa').toString().toLowerCase();

          if (tipo == 'multa') {
            deudores[nombre]!['multas'] += valor;
          } else if (tipo == 'pago') {
            deudores[nombre]!['pagos'] += valor;
          }
        }

        // Filtrar por buscador
        final listaDeudores = deudores.values
            .map((d) {
              final saldo = d['multas'] - d['pagos'];
              return {...d, 'saldo': saldo};
            })
            .where((d) => d['nombre'].toString().toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList()
          ..sort((a, b) => (b['saldo'] as int).compareTo(a['saldo'] as int));

        double totalMultas = 0;
        double totalPagos = 0;

        for (var d in listaDeudores) {
          totalMultas += d['multas'] as int;
          totalPagos += d['pagos'] as int;
        }
        final saldoTotal = totalMultas - totalPagos;

        return Column(
          children: [
            // Tarjetas de totales
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(child: _buildTotalCard("Total Recaudado", "\$${totalPagos.toInt()}", Colors.green)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTotalCard("Saldo Pendiente", "\$${saldoTotal.toInt()}", Colors.red)),
                ],
              ),
            ),

            // Buscador
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: "Buscar deudor...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 8),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text("Detalle por Deudor", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),

            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.amber[700]),
                    columns: const [
                      DataColumn(label: Text('Deudor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Multas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Pagos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Saldo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    ],
                    rows: listaDeudores.map((d) {
                      final saldo = d['saldo'] as int;
                      return DataRow(
                        cells: [
                          DataCell(Text(d['nombre'])),
                          DataCell(Text("\$${d['multas']}")),
                          DataCell(Text("\$${d['pagos']}")),
                          DataCell(Text(
                            "\$$saldo",
                            style: TextStyle(
                              color: saldo > 0 ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTotalCard(String title, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(25),        // ← Corrección de withOpacity
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(amount, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}