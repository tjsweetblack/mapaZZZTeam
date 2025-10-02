class WordLevel {
  final String title;
  final List<String> words;
  WordLevel({required this.title, required this.words});
}

// Renomeie 'levels' para 'wordLevels' para manter consistência com 'home_screen.dart'
final List<WordLevel> wordLevels = [
  WordLevel(
    title: 'Nível 1 - Fácil', 
    words: [ 'REDE', 'RIR']),
  WordLevel(
    title: 'Nível 2 - Médio',
    words: ['PARASITA', 'SINTOMA', 'POSTO', 'REPELENTE'],
  ),
  WordLevel(
    title: 'Nível 3 - Difícil',
    words: ['ANOPHELES', 'PALUDISMO', 'PROFILAXIA', 'HEMATOLOGIA', 'INFECCAO'],
  ),
];
