import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:math';
import 'forca_painter.dart';

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
        useMaterial3: true,
      ),
      home: const JogoForca(),
    );
  }
}

class JogoForca extends StatefulWidget {
  const JogoForca({super.key});

  @override
  State<JogoForca> createState() => _JogoForcaState();
}

class _JogoForcaState extends State<JogoForca> {
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
      "debug"
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
      "entrada"
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
      "validacao"
    ]
  };

  final Map<int, String> descricoes = {
    1: "Conceitos básicos do Pensamento Computacional, como algoritmos, sequências e lógica de programação.",
    2: "Conceitos intermediários que ajudam a organizar e estruturar o pensamento computacional.",
    3: "Conceitos avançados que integram diferentes aspectos do Pensamento Computacional."
  };

  final Map<String, String> dicas = {
    "algoritmo": "É uma sequência de passos para resolver um problema",
    "sequencia": "Ordem em que as ações são executadas",
    "repeticao": "Quando um conjunto de ações se repete",
    "condicao": "Decisão baseada em uma situação",
    "variavel": "Local para armazenar informações",
    "dados": "Informações que o computador processa",
    "logica": "Raciocínio para resolver problemas",
    "teste": "Verificação se algo funciona",
    "erro": "Quando algo não funciona como esperado",
    "debug": "Processo de encontrar e corrigir erros",
    "abstracao": "Simplificar um problema complexo",
    "decomposicao": "Dividir um problema em partes menores",
    "padrao": "Identificar regularidades",
    "sequenciamento": "Organizar ações em ordem",
    "iteracao": "Repetir um processo",
    "recursao": "Função que chama a si mesma",
    "funcao": "Conjunto de instruções com nome",
    "parametro": "Informação passada para uma função",
    "retorno": "Resultado de uma função",
    "entrada": "Dados que o programa recebe",
    "pensamento_computacional":
        "Forma de resolver problemas como um computador",
    "resolucao_problemas": "Processo de encontrar soluções",
    "representacao_dados": "Como organizar informações",
    "automatizacao": "Fazer tarefas automaticamente",
    "generalizacao": "Aplicar soluções em diferentes situações",
    "otimizacao": "Melhorar a eficiência",
    "simulacao": "Imitar situações reais",
    "modelagem": "Criar representações simplificadas",
    "verificacao": "Confirmar se está correto",
    "validacao": "Garantir que funciona como esperado"
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
  final AudioPlayer audioPlayer = AudioPlayer();
  final TextEditingController letraController = TextEditingController();
  bool mostrarInstrucoes = true;

  @override
  void dispose() {
    timer?.cancel();
    audioPlayer.dispose();
    letraController.dispose();
    super.dispose();
  }

  void tocarSom(String tipo) async {
    try {
      await audioPlayer.play(AssetSource('sounds/$tipo.wav'));
    } catch (e) {
      // Ignora erros de som
    }
  }

  void adicionarHistorico(String mensagem) {
    setState(() {
      historico.insert(0,
          "${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second} - $mensagem");
    });
  }

  String mostrarPalavra() {
    return palavra
        .split('')
        .map((letra) => letrasCorretas.contains(letra) ? letra : '_')
        .join(' ');
  }

  void pedirDica() {
    if (palavra.isNotEmpty) {
      setState(() {
        pontuacao = max(0, pontuacao - 20); // Perde 20 pontos por dica
      });
      mostrarMensagem("Dica", dicas[palavra] ?? "Sem dica disponível");
    }
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
      letraController.clear();
      mostrarInstrucoes = false;
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

  void tentarLetra() {
    final letra = letraController.text.toLowerCase();
    letraController.clear();

    if (letra.length != 1 || !RegExp(r'[a-zà-ú]').hasMatch(letra)) {
      mostrarMensagem("Aviso", "Por favor, digite apenas uma letra válida.");
      return;
    }

    if (letrasCorretas.contains(letra) || letrasErradas.contains(letra)) {
      mostrarMensagem("Aviso", "Você já tentou esta letra. Tente outra.");
      return;
    }

    setState(() {
      if (palavra.contains(letra)) {
        letrasCorretas.add(letra);
        tocarSom("acerto");
        pontuacao += 10 * nivel;
        adicionarHistorico("Acertou a letra $letra");
      } else {
        letrasErradas.add(letra);
        tentativas--;
        tocarSom("erro");
        pontuacao = pontuacao - 5 < 0 ? 0 : pontuacao - 5;
        adicionarHistorico("Errou a letra $letra");
      }
    });

    if (palavra.split('').every((letra) => letrasCorretas.contains(letra))) {
      tocarSom("vitoria");
      setState(() {
        pontuacao += 100 * nivel;
      });
      adicionarHistorico("Venceu! Palavra: $palavra");
      mostrarMensagem("Parabéns!",
          "Você ganhou! A palavra era: $palavra\nPontuação: $pontuacao");
      reiniciarJogo();
    } else if (tentativas == 0) {
      tocarSom("derrota");
      adicionarHistorico("Perdeu! Palavra: $palavra");
      mostrarMensagem("Game Over",
          "Você perdeu! A palavra era: $palavra\nPontuação: $pontuacao");
      reiniciarJogo();
    }
  }

  void reiniciarJogo() {
    setState(() {
      tempoInicio = null;
      timer?.cancel();
      mostrarInstrucoes = true;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Jogo da Forca - Pensamento Computacional"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade100,
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (mostrarInstrucoes) ...[
                  const Card(
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Bem-vindo ao Jogo da Forca!",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Este jogo vai te ajudar a aprender sobre Pensamento Computacional!",
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Pensamento Computacional é uma forma de resolver problemas usando conceitos da computação, como:",
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                              "• Decomposição: dividir problemas em partes menores"),
                          Text("• Padrões: identificar regularidades"),
                          Text("• Abstração: focar no que é importante"),
                          Text(
                              "• Algoritmos: criar passos para resolver problemas"),
                          SizedBox(height: 16),
                          Text(
                            "Escolha um nível e comece a jogar!",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Pontuação: $pontuacao",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Tempo: ${tempoInicio != null ? DateTime.now().difference(tempoInicio!).inSeconds : 0}s",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed:
                          tempoInicio == null ? () => iniciarJogo(1) : null,
                      icon: const Icon(Icons.star_border),
                      label: const Text("Fácil"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed:
                          tempoInicio == null ? () => iniciarJogo(2) : null,
                      icon: const Icon(Icons.star_half),
                      label: const Text("Médio"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed:
                          tempoInicio == null ? () => iniciarJogo(3) : null,
                      icon: const Icon(Icons.star),
                      label: const Text("Difícil"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (palavra.isNotEmpty) ...[
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 200,
                            child: CustomPaint(
                              painter: ForcaPainter(tentativas),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            mostrarPalavra(),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Tentativas restantes: $tentativas",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Letras erradas: ${letrasErradas.join(' ')}",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 50,
                                child: TextField(
                                  controller: letraController,
                                  maxLength: 1,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 24),
                                  decoration: const InputDecoration(
                                    counterText: "",
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                onPressed: tentarLetra,
                                icon: const Icon(Icons.send),
                                label: const Text("Tentar"),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                onPressed: pedirDica,
                                icon: const Icon(Icons.lightbulb_outline),
                                label: const Text("Dica (-20)"),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  backgroundColor: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Container(
                  constraints: const BoxConstraints(
                    maxHeight: 150,
                  ),
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Histórico de Jogadas",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.builder(
                              itemCount: historico.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Text(
                                    historico[index],
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
