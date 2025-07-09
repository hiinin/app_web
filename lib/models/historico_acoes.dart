import 'package:flutter/material.dart';

class HistoricoAcoes {
  final int id;
  final String tabelaAfetada;
  final String acao;
  final int? registroId;
  final Map<String, dynamic>? dadosAnteriores;
  final Map<String, dynamic>? dadosNovos;
  final int? usuarioId;
  final DateTime dataHora;
  final String? detalhes;

  HistoricoAcoes({
    required this.id,
    required this.tabelaAfetada,
    required this.acao,
    this.registroId,
    this.dadosAnteriores,
    this.dadosNovos,
    this.usuarioId,
    required this.dataHora,
    this.detalhes,
  });

  factory HistoricoAcoes.fromMap(Map<String, dynamic> map) {
    try {
      return HistoricoAcoes(
        id: map['id'] ?? 0,
        tabelaAfetada: map['tabela_afetada'] ?? '',
        acao: map['acao'] ?? '',
        registroId: map['registro_id'],
        dadosAnteriores: map['dados_anteriores'],
        dadosNovos: map['dados_novos'],
        usuarioId: map['usuario_id'],
        dataHora:
            map['data_hora'] != null
                ? DateTime.parse(map['data_hora'].toString())
                : DateTime.now(),
        detalhes: map['detalhes'],
      );
    } catch (e) {
      print('Erro ao criar HistoricoAcoes: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tabela_afetada': tabelaAfetada,
      'acao': acao,
      'registro_id': registroId,
      'dados_anteriores': dadosAnteriores,
      'dados_novos': dadosNovos,
      'usuario_id': usuarioId,
      'data_hora': dataHora.toIso8601String(),
      'detalhes': detalhes,
    };
  }

  String get acaoFormatada {
    switch (acao) {
      case 'INSERT':
        return 'Criação';
      case 'INSERT_MULTIPLE':
        return 'Criação Múltipla';
      case 'UPDATE':
        return 'Alteração';
      case 'DELETE':
        return 'Exclusão';
      case 'DELETE_MULTIPLE':
        return 'Exclusão Múltipla';
      default:
        return acao;
    }
  }

  String get tabelaFormatada {
    switch (tabelaAfetada) {
      case 'agendamento':
        return 'Agendamento';
      case 'salas':
        return 'Sala';
      case 'cursos':
        return 'Curso';
      case 'materias':
        return 'Matéria';
      case 'professores':
        return 'Professor';
      default:
        return tabelaAfetada;
    }
  }

  Color get corAcao {
    switch (acao) {
      case 'INSERT':
      case 'INSERT_MULTIPLE':
        return Colors.green;
      case 'UPDATE':
        return Colors.orange;
      case 'DELETE':
      case 'DELETE_MULTIPLE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get iconeAcao {
    switch (acao) {
      case 'INSERT':
        return Icons.add_circle;
      case 'INSERT_MULTIPLE':
        return Icons.add_circle_outline;
      case 'UPDATE':
        return Icons.edit;
      case 'DELETE':
        return Icons.delete;
      case 'DELETE_MULTIPLE':
        return Icons.delete_outline;
      default:
        return Icons.info;
    }
  }
}
