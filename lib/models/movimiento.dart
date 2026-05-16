import 'package:cloud_firestore/cloud_firestore.dart';

class Movimiento {
  final String id;
  final String nombreDeudor;
  final String tipo; // 'multa' o 'pago'
  final int valor;
  final String descripcion;
  final String? motivo;
  final DateTime fecha;
  final String registradoPor;

  Movimiento({
    required this.id,
    required this.nombreDeudor,
    required this.tipo,
    required this.valor,
    required this.descripcion,
    this.motivo,
    required this.fecha,
    required this.registradoPor,
  });

  factory Movimiento.fromMap(Map<String, dynamic> map, String id) {
    return Movimiento(
      id: id,
      nombreDeudor: map['nombreDeudor'] ?? '',
      tipo: map['tipo'] ?? 'multa',
      valor: map['valor'] ?? 0,
      descripcion: map['descripcion'] ?? '',
      motivo: map['motivo'],
      fecha: (map['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
      registradoPor: map['registradoPor'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombreDeudor': nombreDeudor.toLowerCase(),
      'tipo': tipo,
      'valor': valor,
      'descripcion': descripcion,
      'motivo': motivo,
      'fecha': Timestamp.fromDate(fecha),
      'registradoPor': registradoPor,
    };
  }
}