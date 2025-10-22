import 'package:flutter/material.dart';

class RelatorioChamadaScreen extends StatelessWidget {
  const RelatorioChamadaScreen({super.key});

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
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.download),
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
                headingRowColor:
                    MaterialStateProperty.all(Colors.grey.shade100),
                columnSpacing: 18,
                columns: const [
                  DataColumn(
                      label: Text("ALUNO",
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("RODADA 1")),
                  DataColumn(label: Text("RODADA 2")),
                  DataColumn(label: Text("RODADA 3")),
                  DataColumn(label: Text("RODADA 4")),
                  DataColumn(label: Text("TOTAL")),
                ],
                rows: alunos.map((aluno) {
                  final List<bool> rodadas =
                      List<bool>.from(aluno["rodadas"] as List);
                  int totalPresencas =
                      rodadas.where((p) => p == true).length;
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
                _buildStatCard(
                    "TOTAL DE ALUNOS", "${alunos.length}", Colors.grey.shade200, Colors.black87),
                const SizedBox(width: 8),
                _buildStatCard(
                    "PRESENÇA MÉDIA", "$presencaMedia%", Colors.green.shade50, Colors.green.shade800),
                const SizedBox(width: 8),
                _buildStatCard(
                    "RODADAS COMPLETAS", rodadasCompletas, Colors.purple.shade50, Colors.purple.shade800),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, Color bgColor, Color textColor) {
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
