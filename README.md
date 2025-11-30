# Sistema Automatizado de Chamada

Um aplicativo móvel desenvolvido em Flutter para automatizar a verificação de presença em sala de aula, utilizando a simulação de proximidade Bluetooth Low Energy (BLE) para garantir que a verificação se baseie na presença física dos alunos.

O projeto visa entregar uma solução que automatiza totalmente o processo de chamada, eliminando a necessidade de intervenção manual do professor e mitigando fraudes.

## Funcionalidades Chave

* **Automatização da Chamada:** O sistema é programado para disparar automaticamente **4 rodadas** de verificação de presença por aula, controladas por um Timer interno.
* **Intervalos Fixos:** As rodadas são espaçadas por um **intervalo fixo de 50 minutos**.
* **Janela de Registro Curta:** Cada rodada tem uma **janela de 5 minutos** para o registro de presença, fora da qual o registro é rejeitado.
* **Prova de Proximidade (Simulada):** A lógica de registro é acionada apenas quando a simulação indicar **sinal forte de proximidade (RSSI)** do professor, implementando o critério anti-fraude.
* **Unicidade de Presença:** É permitido apenas **um registro de presença por aluno por rodada**.
* **Monitoramento em Tempo Real (Professor):** O professor visualiza uma lista de presença atualizada dos alunos na rodada corrente na tela de Chamada Ativa.
* **Autenticação:** O sistema possui telas de **Login** e **Cadastro** de Alunos, e uma **Tela de Seleção de Perfil** para iniciar a simulação como Professor ou Aluno.

## Tecnologias e Dependências

| Categoria | Pacote/Tecnologia | Uso no Projeto |
| :--- | :--- | :--- |
| **Framework** | [Flutter](https://flutter.dev/) (Dart) | Desenvolvimento do aplicativo móvel multiplataforma. |
| **Backend & DB** | `supabase_flutter` | Persistência de dados (alunos, chamadas e presenças) e funcionalidades em tempo real. |
| **Estado** | `provider` | Gerenciamento de estado global da aplicação (`ChamadaTimerService`). |
| **Formatação** | `intl` | Formatação de datas e horas (ex: no relatório). |
| **Exportação** | `path_provider`, `universal_html`, `share_plus` | Previsão e suporte para funcionalidade de exportação de relatórios para CSV. |
