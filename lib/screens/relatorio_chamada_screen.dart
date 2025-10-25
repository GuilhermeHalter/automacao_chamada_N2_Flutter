import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;

class RelatorioChamadaScreen extends StatelessWidget {
  const RelatorioChamadaScreen({super.key});

  // --- Método híbrido para exportar CSV ---
  Future<void> _exportarCSV(BuildContext context, List<Map<String, dynamic>> alunos) async {
  try {
    // Cabeçalho
    String csvData = 'NOME;RODADA 1;RODADA 2;RODADA 3;RODADA 4;TOTAL\n';

    for (var aluno in alunos) {
      List<bool> rodadas = List<bool>.from(aluno["rodadas"] as List);
      int totalPresencas = rodadas.where((p) => p).length;
      double percentual = (totalPresencas / rodadas.length) * 100;

      String linha =
          '${aluno["nome"]};'
          '${rodadas[0] ? "Presente" : "Falta"};'
          '${rodadas[1] ? "Presente" : "Falta"};'
          '${rodadas[2] ? "Presente" : "Falta"};'
          '${rodadas[3] ? "Presente" : "Falta"};'
          '$totalPresencas/${rodadas.length} (${percentual.toStringAsFixed(1)}%)\n';

      csvData += linha;
    }

    if (kIsWeb) {
      final bytes = utf8.encode(csvData);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'relatorio_chamada.csv')
        ..click();

      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arquivo CSV baixado com sucesso (Web)!')),
      );
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/relatorio_chamada.csv';
      final file = File(path);
      await file.writeAsString(csvData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Arquivo salvo em: $path')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro ao exportar CSV: $e')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    final alunos = [
      {"nome": "Ana Silva", "rodadas": [true, true, true, true]},
      {"nome": "Bruno Costa", "rodadas": [true, true, true, false]},
      {"nome": "Carlos Mendes", "rodadas": [true, false, true, true]},
      {"nome": "Diana Oliveira", "rodadas": [true, true, true, true]},
      {"nome": "Eduardo Santos", "rodadas": [false, false, true, false]},
      {"nome": "Fernanda Lima", "rodadas": [true, true, true, true]},
      {"nome": "Gabriel Rocha", "rodadas": [false, true, false, true]},
      {"nome": "Helena Martins", "rodadas": [true, false, false, false]},
    ];

    const presencaMedia = 87.5;
    const rodadasCompletas = "4/4";

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Relatório da Chamada",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exportar CSV',
            onPressed: () => _exportarCSV(context, alunos),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: const [
                Icon(Icons.calendar_today, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  "Chamada de 20 de Outubro de 2025",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              "Disciplina: Sistemas Distribuídos  •  Turma: CC-301",
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),

            // Tabela
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                ],
              ),
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                columnSpacing: 18,
                columns: const [
                  DataColumn(label: Text("ALUNO", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("RODADA 1")),
                  DataColumn(label: Text("RODADA 2")),
                  DataColumn(label: Text("RODADA 3")),
                  DataColumn(label: Text("RODADA 4")),
                  DataColumn(label: Text("TOTAL")),
                ],
                rows: alunos.map((aluno) {
                  final List<bool> rodadas = List<bool>.from(aluno["rodadas"] as List);
                  int totalPresencas = rodadas.where((p) => p == true).length;
                  return DataRow(
                    cells: [
                      DataCell(Text(aluno["nome"] as String)),
                      for (bool presente in rodadas)
                        DataCell(Icon(
                          presente ? Icons.check_circle : Icons.cancel,
                          color: presente ? Colors.green : Colors.red,
                        )),
                      DataCell(Text("$totalPresencas/4")),
                    ],
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Estatísticas
            Row(
              children: [
                _buildStatCard("TOTAL DE ALUNOS", "${alunos.length}", Colors.grey.shade200, Colors.black87),
                const SizedBox(width: 8),
                _buildStatCard("PRESENÇA MÉDIA", "$presencaMedia%", Colors.green.shade50, Colors.green.shade800),
                const SizedBox(width: 8),
                _buildStatCard("RODADAS COMPLETAS", rodadasCompletas, Colors.purple.shade50, Colors.purple.shade800),
              ],
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
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: textColor.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
