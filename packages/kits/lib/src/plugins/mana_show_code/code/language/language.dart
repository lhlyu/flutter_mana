abstract class ProgramLanguage {
  final String name;

  const ProgramLanguage(this.name);

  bool containsKeywords(String word);

  bool containsInTypes(String word);

  List<String> get keywords;

  List<String> get inTypes;
}
