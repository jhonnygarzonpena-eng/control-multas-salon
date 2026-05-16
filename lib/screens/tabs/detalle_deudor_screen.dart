import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';

class DetalleDeudorScreen extends StatefulWidget {
  final String nombreDeudor;
  const DetalleDeudorScreen({super.key, required this.nombreDeudor});

  @override
  State<DetalleDeudorScreen> createState() => _DetalleDeudorScreenState();
}

class _DetalleDeudorScreenState extends State<DetalleDeudorScreen> {
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _notaController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  Future<void> _registrarPago() async {
    if (_valorController.text.isEmpty) return;
    final valor = int.tryParse(_valorController.text) ?? 0;
    if (valor <= 0) return;

    try {
      await FirebaseFirestore.instance.collection('movimientos').add({
        'tipo': 'pago',
        'nombreDeudor': widget.nombreDeudor.toLowerCase(),
        'valor': valor,
        'descripcion': _notaController.text.trim().isEmpty ? 'EFECTIVO' : _notaController.text.trim(),
        'motivo': 'Pago registrado',
        'fecha': Timestamp.now(),
        'registradoPor': 'admin',
      });

      _valorController.clear();
      _notaController.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Pago registrado"), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error al registrar pago: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _eliminarMovimiento(String docId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAdmin) return;

    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Eliminar este movimiento?"),
        content: const Text("Esta acción no se puede deshacer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    // GUARDIA DE CONTEXTO ASÍNCRONO
    if (!mounted) return;

    final TextEditingController passController = TextEditingController();
    
    final bool? verified = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar con contraseña"),
        content: TextField(
          controller: passController,
          obscureText: true,
          decoration: const InputDecoration(labelText: "Tu contraseña de administrador"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Confirmar")),
        ],
      ),
    );

    if (verified != true) {
      passController.dispose(); // Liberar memoria si cancela
      return;
    }

    try {
      await auth.reAutenticar(passController.text);
      await FirebaseFirestore.instance.collection('movimientos').doc(docId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Movimiento eliminado"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Contraseña incorrecta"), backgroundColor: Colors.red),
        );
      }
    } finally {
      passController.dispose(); // Liberar memoria al terminar el proceso
    }
  }

  @override
  void dispose() {
    _valorController.dispose();
    _notaController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nombreDeudor.toUpperCase()),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('movimientos')
            .where('nombreDeudor', isEqualTo: widget.nombreDeudor.toLowerCase())
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay movimientos para este deudor"));
          }

          final allItems = snapshot.data!.docs;
          final items = allItems.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final desc = (data['descripcion'] ?? '').toString().toLowerCase();
            final mot = (data['motivo'] ?? '').toString().toLowerCase();
            return desc.contains(_searchQuery.toLowerCase()) ||
                   mot.contains(_searchQuery.toLowerCase());
          }).toList();

          int totalMultas = 0;
          int totalPagos = 0;

          for (var doc in items) {
            final data = doc.data() as Map<String, dynamic>;
            
            // SOLUCIÓN AL ERROR DE ASIGNACIÓN NUM -> INT
            final int valor = (data['valor'] ?? 0).toInt();
            final tipo = (data['tipo'] ?? '').toString().toLowerCase();

            if (tipo == 'multa') {
              totalMultas += valor;
            } else if (tipo == 'pago') {
              totalPagos += valor;
            }
          }

          final saldo = totalMultas - totalPagos;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.amber[50],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummary("TOTAL MULTAS", "\$$totalMultas", Colors.orange),
                    _buildSummary("TOTAL PAGADO", "\$$totalPagos", Colors.green),
                    _buildSummary("SALDO", "\$$saldo", saldo > 0 ? Colors.red : Colors.green),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: "Buscar en historial...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _valorController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: "Valor a pagar"),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _notaController,
                                decoration: const InputDecoration(labelText: "Nota"),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _registrarPago,
                            icon: const Icon(Icons.payment),
                            label: const Text("Registrar Pago"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.all(12),
                child: Text("Historial del Deudor", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text("No se encontraron resultados"))
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final doc = items[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final esPago = data['tipo'] == 'pago';
                          final fecha = (data['fecha'] as Timestamp?)?.toDate() ?? DateTime.now();
                          final fechaFormateada = DateFormat('dd/MM/yyyy HH:mm').format(fecha);

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            color: esPago ? Colors.green[50] : Colors.red[50],
                            child: ListTile(
                              leading: Icon(
                                esPago ? Icons.arrow_downward : Icons.arrow_upward,
                                color: esPago ? Colors.green : Colors.red,
                              ),
                              title: Text(data['descripcion'] ?? data['motivo'] ?? ''),
                              subtitle: Text(fechaFormateada),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "${esPago ? '-' : '+'}\$${data['valor']}",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: esPago ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  if (auth.isAdmin)
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _eliminarMovimiento(doc.id),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummary(String title, String amount, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(amount, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}