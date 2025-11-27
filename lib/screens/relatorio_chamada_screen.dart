import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_html/html.dart' as html;

class RelatorioChamadaScreen extends StatefulWidget {
  const RelatorioChamadaScreen({super.key});

  @override
  State<RelatorioChamadaScreen> createState() => _RelatorioChamadaScreenState();
}

class _RelatorioChamadaScreenState extends State<RelatorioChamadaScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _alunosProcessados = [];
  double _presencaMedia = 0.0;
  int _totalAlunos = 0;

  @override
  void initState() {
    super.initState();
    _fetchDadosRelatorio();
  }

  Future<void> _fetchDadosRelatorio() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final data = await _supabase
          .from('presencas')
          .select()
          .gte('created_at', startOfDay.toIso8601String())
          .lte('created_at', endOfDay.toIso8601String())
          .order('nome_aluno', ascending: true);

      final Map<String, Map<String, dynamic>> agrupado = {};

      for (var registro in data) {
        final ra = registro['ra_aluno'];
        final nome = registro['nome_aluno'];
        final rodada = registro['rodada'] as int;

        if (!agrupado.containsKey(ra)) {
          agrupado[ra] = {
            'ra': ra,
            'nome': nome,
            'rodadas': List<bool>.filled(4, false), 
          };
        }

        if (rodada >= 1 && rodada <= 4) {
          agrupado[ra]!['rodadas'][rodada - 1] = true;
        }
      }

      final listaFinal = agrupado.values.toList();
      
      int totalPresencasGerais = 0;
      int totalPossivel = listaFinal.length * 4;

      for (var aluno in listaFinal) {
        List<bool> r = aluno['rodadas'];
        totalPresencasGerais += r.where((p) => p).length;
      }

      setState(() {
        _alunosProcessados = listaFinal;
        _totalAlunos = listaFinal.length;
        _presencaMedia = totalPossivel > 0 
            ? (totalPresencasGerais / totalPossivel) * 100 
            : 0.0;
        _isLoading = false;
      });

    } catch (e) {
      debugPrint('Erro ao buscar relatório: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _exportarCSV() async {
    if (_alunosProcessados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não há dados para exportar.')),
      );
      return;
    }

    try {
      String csvData = 'RA;NOME;DATA;RODADA 1;RODADA 2;RODADA 3;RODADA 4;TOTAL\n';
      final hoje = DateFormat('dd/MM/yyyy').format(DateTime.now());

      for (var aluno in _alunosProcessados) {
        List<bool> rodadas = aluno["rodadas"];
        int totalPresencas = rodadas.where((p) => p).length;
        double percentual = (totalPresencas / 4) * 100;

        String linha =
            '${aluno["ra"]};'
            '${aluno["nome"]};'
            '$hoje;'
            '${rodadas[0] ? "P" : "F"};'
            '${rodadas[1] ? "P" : "F"};'
            '${rodadas[2] ? "P" : "F"};'
            '${rodadas[3] ? "P" : "F"};'
            '$totalPresencas/4 (${percentual.toStringAsFixed(0)}%)\n';

        csvData += linha;
      }

      if (kIsWeb) {
        final bytes = utf8.encode(csvData);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'relatorio_chamada_$hoje.csv')
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/relatorio_chamada.csv';
        final file = File(path);
        await file.writeAsString(csvData);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('CSV salvo em: $path')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro na exportação: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hojeFormatado = DateFormat('dd ' 'de' ' MMMM ' 'de' ' yyyy', 'pt_BR').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Relatório da Chamada", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exportar CSV',
            onPressed: _isLoading ? null : _exportarCSV,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _fetchDadosRelatorio,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alunosProcessados.isEmpty
              ? const Center(
                  child: Text(
                    "Nenhum registro de presença encontrado hoje.",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.deepPurple),
                          const SizedBox(width: 8),
                          Text(
                            "Chamada de $hojeFormatado",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Disciplina: Sistemas Distribuídos  •  Turma: CC-301", // Estático por enquanto
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          _buildStatCard("TOTAL DE ALUNOS", "$_totalAlunos", Colors.grey.shade200, Colors.black87),
                          const SizedBox(width: 8),
                          _buildStatCard("PRESENÇA MÉDIA", "${_presencaMedia.toStringAsFixed(1)}%", Colors.green.shade50, Colors.green.shade800),
                          const SizedBox(width: 8),
                          _buildStatCard("RODADAS PREVISTAS", "4", Colors.purple.shade50, Colors.purple.shade800),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                            columnSpacing: 12,
                            horizontalMargin: 12,
                            columns: const [
                              DataColumn(label: Text("RA / ALUNO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              DataColumn(label: Text("R1", style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text("R2", style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text("R3", style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text("R4", style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text("TOT", style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: _alunosProcessados.map((aluno) {
                              final List<bool> rodadas = aluno["rodadas"];
                              int total = rodadas.where((p) => p).length;
                              
                              return DataRow(
                                cells: [
                                  DataCell(Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(aluno["nome"], style: const TextStyle(fontWeight: FontWeight.w500)),
                                      Text(aluno["ra"], style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                    ],
                                  )),
                                  ...rodadas.map((presente) => DataCell(
                                    Center(
                                      child: Icon(
                                        presente ? Icons.check_circle : Icons.cancel,
                                        color: presente ? Colors.green : Colors.grey.shade300,
                                        size: 18,
                                      ),
                                    ),
                                  )),
                                  DataCell(Text("$total/4", style: const TextStyle(fontWeight: FontWeight.bold))),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatCard(String label, String value, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.7), fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}