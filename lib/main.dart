import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'forca_painter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const JogoForcaApp());
}

class JogoForcaApp extends StatelessWidget {
  const JogoForcaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jogo da Forca',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const JogoForca(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class JogoForca extends StatefulWidget {
  const JogoForca({super.key});

  @override
  State<JogoForca> createState() => _JogoForcaState();
}

class _JogoForcaState extends State<JogoForca>
    with SingleTickerProviderStateMixin {
  final Map<int, List<String>> palavras = {
    1: [
      "algoritmo",
      "sequencia",
      "repeticao",
      "condicao",
      "variavel",
      "dados",
      "logica",
      "teste",
      "erro",
      "debug",
    ],
    2: [
      "abstracao",
      "decomposicao",
      "padrao",
      "sequenciamento",
      "iteracao",
      "recursao",
      "funcao",
      "parametro",
      "retorno",
      "entrada",
    ],
    3: [
      "pensamento_computacional",
      "resolucao_problemas",
      "representacao_dados",
      "automatizacao",
      "generalizacao",
      "otimizacao",
      "simulacao",
      "modelagem",
      "verificacao",
      "validacao",
    ],
  };

  final Map<String, String> dicas = {
    "algoritmo": "Sequência de passos para resolver um problema.",
    "sequencia": "Ordem em que as ações acontecem.",
    "repeticao": "Quando algo se repete várias vezes.",
    "condicao": "Uma decisão baseada em uma regra.",
    "variavel": "Espaço para guardar um valor.",
    "dados": "Informações que podem ser processadas.",
    "logica": "Raciocínio para resolver problemas.",
    "teste": "Verificar se algo está funcionando.",
    "erro": "Quando algo não sai como esperado.",
    "debug": "Procurar e corrigir erros.",
    "abstracao": "Simplificar um problema, focando no essencial.",
    "decomposicao": "Dividir um problema em partes menores.",
    "padrao": "Solução que pode ser reutilizada.",
    "sequenciamento": "Organizar ações em ordem.",
    "iteracao": "Repetir um conjunto de ações.",
    "recursao": "Quando uma função chama a si mesma.",
    "funcao": "Bloco de código que executa uma tarefa.",
    "parametro": "Valor passado para uma função.",
    "retorno": "Valor devolvido por uma função.",
    "entrada": "Informação recebida pelo programa.",
    "pensamento_computacional":
        "Habilidade de resolver problemas usando conceitos da computação.",
    "resolucao_problemas": "Buscar soluções para desafios.",
    "representacao_dados": "Como as informações são organizadas.",
    "automatizacao": "Fazer tarefas automaticamente.",
    "generalizacao": "Aplicar uma solução para vários casos.",
    "otimizacao": "Melhorar uma solução.",
    "simulacao": "Imitar situações reais.",
    "modelagem": "Criar representações de problemas.",
    "verificacao": "Checar se está correto.",
    "validacao": "Confirmar se atende ao objetivo."
  };

  String palavra = "";
  Set<String> letrasCorretas = {};
  Set<String> letrasErradas = {};
  int tentativas = 6;
  int nivel = 1;
  int pontuacao = 0;
  List<String> historico = [];
  DateTime? tempoInicio;
  int tempoLimite = 0;
  Timer? timer;
  bool jogoIniciado = false;
  bool jogoFinalizado = false;
  bool dicaUsada = false;
  String dicaAtual = "";

  // Estatísticas
  int totalAcertos = 0;
  int totalDicas = 0;
  int totalErros = 0;
  List<Map<String, dynamic>> ranking = [];
  String nomeAluno = "";

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.delayed(Duration.zero, () async {
      await carregarEstatisticas();
      pedirNomeAluno();
    });
  }

  Future<void> carregarEstatisticas() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      totalAcertos = prefs.getInt('totalAcertos_$nomeAluno') ?? 0;
      totalDicas = prefs.getInt('totalDicas_$nomeAluno') ?? 0;
      totalErros = prefs.getInt('totalErros_$nomeAluno') ?? 0;
      pontuacao = prefs.getInt('pontuacao_$nomeAluno') ?? 0;

      final rankingString = prefs.getString('ranking') ?? '[]';
      try {
        final List<dynamic> rankingList = jsonDecode(rankingString);
        ranking = rankingList
            .map<Map<String, dynamic>>(
                (e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } catch (e) {
        ranking = [];
      }
    });
  }

  Future<void> salvarEstatisticas() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('totalAcertos_$nomeAluno', totalAcertos);
    await prefs.setInt('totalDicas_$nomeAluno', totalDicas);
    await prefs.setInt('totalErros_$nomeAluno', totalErros);
    await prefs.setInt('pontuacao_$nomeAluno', pontuacao);

    final alunoAtual = {
      'nome': nomeAluno,
      'pontuacao': pontuacao,
      'acertos': totalAcertos,
      'dicas': totalDicas,
      'erros': totalErros,
    };

    ranking.removeWhere((r) => r['nome'] == nomeAluno);
    ranking.add(alunoAtual);
    ranking.sort(
        (a, b) => (b['pontuacao'] as int).compareTo(a['pontuacao'] as int));

    await prefs.setString('ranking', jsonEncode(ranking));
  }

  void pedirNomeAluno() async {
    String nome = "";
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Digite seu nome"),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: "Nome do aluno"),
            onChanged: (value) => nome = value,
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (nome.trim().isEmpty) return;
                setState(() {
                  nomeAluno = nome.trim();
                });
                await carregarEstatisticas();
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
    if (nomeAluno.isEmpty) {
      setState(() {
        nomeAluno = "Aluno";
      });
    }
    await carregarEstatisticas();
  }

  @override
  void dispose() {
    timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void adicionarHistorico(String mensagem) {
    setState(() {
      historico.insert(
        0,
        "${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second} - $mensagem",
      );
    });
  }

  String mostrarPalavra() {
    return palavra
        .split('')
        .map((letra) => letrasCorretas.contains(letra) ? letra : '_')
        .join(' ');
  }

  void iniciarJogo(int nivelEscolhido) {
    setState(() {
      nivel = nivelEscolhido;
      palavra = palavras[nivel]![Random().nextInt(palavras[nivel]!.length)];
      letrasCorretas.clear();
      letrasErradas.clear();
      tentativas = 6;
      tempoLimite = {1: 120, 2: 180, 3: 240}[nivel]!;
      tempoInicio = DateTime.now();
      jogoIniciado = true;
      jogoFinalizado = false;
      dicaUsada = false;
      dicaAtual = "";
      if (nivel == 3) {
        pontuacao = 0;
      }
    });

    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (tempoInicio != null) {
        final tempoDecorrido =
            DateTime.now().difference(tempoInicio!).inSeconds;
        if (tempoDecorrido >= tempoLimite) {
          timer.cancel();
          mostrarMensagem("Tempo Esgotado", "Seu tempo acabou!");
          reiniciarJogo();
        }
      }
    });

    adicionarHistorico("Iniciou jogo no nível $nivel");
  }

  void usarDica() {
    if (!jogoIniciado || jogoFinalizado || dicaUsada) return;

    setState(() {
      dicaUsada = true;
      dicaAtual = dicas[palavra] ?? "Sem dica disponível";
      pontuacao = max(0, pontuacao - 15);
      totalDicas++;
      salvarEstatisticas();
    });
  }

  void verificarLetra(String letra) {
    if (!jogoIniciado || jogoFinalizado) return;

    setState(() {
      if (palavra.contains(letra)) {
        letrasCorretas.add(letra);
        if (!letrasCorretas.contains(letra)) {
          pontuacao += 10;
          totalAcertos++;
          salvarEstatisticas();
        }
      } else {
        letrasErradas.add(letra);
        tentativas--;
        pontuacao = max(0, pontuacao - 5);
        totalErros++;
        salvarEstatisticas();
      }
    });

    verificarFimJogo();
  }

  void verificarFimJogo() {
    if (palavra.split('').every((letra) => letrasCorretas.contains(letra))) {
      setState(() {
        pontuacao += 100;
        totalAcertos++;
      });
      salvarEstatisticas();
      adicionarHistorico("Venceu! Palavra: $palavra");
      mostrarMensagem(
        "Parabéns!",
        "Você ganhou! A palavra era: $palavra\nPontuação: $pontuacao",
      );
      jogoFinalizado = true;
      timer?.cancel();
    } else if (tentativas == 0) {
      totalErros++;
      salvarEstatisticas();
      adicionarHistorico("Perdeu! Palavra: $palavra");
      mostrarMensagem(
        "Game Over",
        "Você perdeu! A palavra era: $palavra\nPontuação: $pontuacao",
      );
      jogoFinalizado = true;
      timer?.cancel();
    }
  }

  void reiniciarJogo() {
    setState(() {
      tempoInicio = null;
      timer?.cancel();
      jogoIniciado = false;
      jogoFinalizado = false;
      letrasCorretas.clear();
      letrasErradas.clear();
      tentativas = 6;
      palavra = "";
      dicaUsada = false;
      dicaAtual = "";
    });
  }

  void mostrarMensagem(String titulo, String mensagem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Widget buildTeclado() {
    const letras = [
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
      'G',
      'H',
      'I',
      'J',
      'K',
      'L',
      'M',
      'N',
      'O',
      'P',
      'Q',
      'R',
      'S',
      'T',
      'U',
      'V',
      'W',
      'X',
      'Y',
      'Z'
    ];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: letras.map((l) {
        final letra = l.toLowerCase();
        Color cor;
        if (letrasCorretas.contains(letra)) {
          cor = Colors.green;
        } else if (letrasErradas.contains(letra)) {
          cor = Colors.red;
        } else {
          cor = Colors.blue.shade200;
        }
        return ElevatedButton(
          onPressed: (!jogoIniciado ||
                  jogoFinalizado ||
                  letrasCorretas.contains(letra) ||
                  letrasErradas.contains(letra))
              ? null
              : () => verificarLetra(letra),
          style: ElevatedButton.styleFrom(
            backgroundColor: cor,
            minimumSize: const Size(40, 40),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(l, style: const TextStyle(fontWeight: FontWeight.bold)),
        );
      }).toList(),
    );
  }

  Widget buildEstatisticas() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Estatísticas do Aluno: $nomeAluno",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text("Palavras acertadas: $totalAcertos"),
            Text("Dicas usadas: $totalDicas"),
            Text("Palavras erradas: $totalErros"),
            const SizedBox(height: 24),
            const Text(
              "Ranking Local",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ranking.isEmpty
                  ? const Center(child: Text("Nenhum aluno jogou ainda."))
                  : ListView.builder(
                      itemCount: ranking.length,
                      itemBuilder: (context, index) {
                        final r = ranking[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(child: Text("#${index + 1}")),
                            title: Text(r['nome']?.toString() ?? 'Aluno'),
                            subtitle: Text(
                              "Pontos: ${r['pontuacao'] ?? 0} | Acertos: ${r['acertos'] ?? 0} | Dicas: ${r['dicas'] ?? 0} | Erros: ${r['erros'] ?? 0}",
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: pedirNomeAluno,
                icon: const Icon(Icons.person),
                label: const Text("Trocar de Aluno"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Jogo da Forca - Pensamento Computacional"),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: "Jogo"),
              Tab(text: "Estatísticas"),
            ],
          ),
        ),
        backgroundColor: Colors.grey[200],
        body: TabBarView(
          controller: _tabController,
          children: [
            // Jogo
            Center(
              child: SingleChildScrollView(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 700),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.1 * 255).toInt()),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Título do jogo
                      const Text(
                        "Jogo da Forca - Pensamento Computacional",
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      // Informações sobre Pensamento Computacional
                      const Text(
                        "Pensamento Computacional é a habilidade de resolver problemas de forma lógica, usando conceitos da computação como decomposição, abstração, reconhecimento de padrões e algoritmos. Desenvolver essa habilidade ajuda a encontrar soluções criativas e eficientes para desafios do dia a dia!",
                        style: TextStyle(fontSize: 13, color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              SizedBox(
                                width: 150,
                                height: 200,
                                child: Stack(
                                  children: [
                                    CustomPaint(
                                      painter: ForcaPainter(tentativas),
                                      size: const Size(150, 200),
                                    ),
                                    if (jogoIniciado)
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        bottom: 0,
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: ElevatedButton.icon(
                                            onPressed:
                                                dicaUsada ? null : usarDica,
                                            icon: const Icon(
                                                Icons.lightbulb_outline),
                                            label: const Text("Dica"),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: dicaUsada
                                                  ? Colors.grey
                                                  : Colors.yellow[700],
                                              foregroundColor: Colors.black,
                                              minimumSize: const Size(120, 36),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (dicaUsada && dicaAtual.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Container(
                                    width: 140,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.yellow[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      dicaAtual,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontStyle: FontStyle.italic),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              const CircleAvatar(
                                radius: 32,
                                backgroundColor: Colors.amber,
                                child: Icon(Icons.person,
                                    size: 40, color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              Text("Pontuação: $pontuacao",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              children: [
                                if (jogoIniciado)
                                  Text(
                                    "Tempo: ${tempoInicio != null ? DateTime.now().difference(tempoInicio!).inSeconds : 0}s",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 8),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: palavra.isNotEmpty
                                          ? palavra.split('').map((letra) {
                                              final visivel = letrasCorretas
                                                  .contains(letra);
                                              return Container(
                                                width: 32,
                                                height: 40,
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[100],
                                                  border: Border(
                                                      bottom: BorderSide(
                                                          width: 2,
                                                          color: Colors.blue)),
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  visivel
                                                      ? letra.toUpperCase()
                                                      : '',
                                                  style: const TextStyle(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              );
                                            }).toList()
                                          : [],
                                    ),
                                  ),
                                ),
                                if (jogoIniciado) buildTeclado(),
                                if (!jogoIniciado)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    child: Column(
                                      children: [
                                        const Text(
                                          "Escolha o nível para começar:",
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            ElevatedButton(
                                              onPressed: () => iniciarJogo(1),
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.green),
                                              child: const Text("Fácil"),
                                            ),
                                            const SizedBox(width: 12),
                                            ElevatedButton(
                                              onPressed: () => iniciarJogo(2),
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.orange),
                                              child: const Text("Médio"),
                                            ),
                                            const SizedBox(width: 12),
                                            ElevatedButton(
                                              onPressed: () => iniciarJogo(3),
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red),
                                              child: const Text("Difícil"),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                if (jogoIniciado && jogoFinalizado)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    child: ElevatedButton.icon(
                                      onPressed: () => iniciarJogo(nivel),
                                      icon: const Icon(Icons.refresh),
                                      label: const Text("Jogar Novamente"),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue),
                                    ),
                                  ),
                                if (jogoIniciado && !jogoFinalizado)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        ElevatedButton(
                                          onPressed: reiniciarJogo,
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.grey),
                                          child: const Text("Sair"),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Column(
                            children: [
                              const CircleAvatar(
                                radius: 32,
                                backgroundColor: Colors.lightBlue,
                                child: Icon(Icons.child_care,
                                    size: 40, color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              Text("Erros: ${letrasErradas.length}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          itemCount: historico.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Text(historico[index],
                                  style: const TextStyle(fontSize: 12)),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Estatísticas
            buildEstatisticas(),
          ],
        ),
      ),
    );
  }
}
