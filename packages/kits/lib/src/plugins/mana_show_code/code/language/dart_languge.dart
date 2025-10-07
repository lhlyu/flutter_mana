import 'language.dart';

class DartLanguage extends ProgramLanguage {
  const DartLanguage() : super('Dart');

  static const List<String> _kDartKeywords = [
    'abstract',
    'as',
    'assert',
    'async',
    'await',
    'base',
    'break',
    'case',
    'catch',
    'class',
    'const',
    'continue',
    'covariant',
    'default',
    'deferred',
    'do',
    'dynamic',
    'else',
    'enum',
    'export',
    'extends',
    'extension',
    'external',
    'factory',
    'false',
    'final',
    'finally',
    'for',
    'get',
    'hide',
    'if',
    'implements',
    'import',
    'in',
    'interface',
    'is',
    'late',
    'library',
    'mixin',
    'new',
    'null',
    'of',
    'on',
    'part',
    'required',
    'rethrow',
    'return',
    'sealed',
    'set',
    'show',
    'static',
    'super',
    'switch',
    'sync',
    'this',
    'throw',
    'true',
    'try',
    'type',
    'typedef',
    'var',
    'void',
    'when',
    'while',
    'with',
    'yield',
  ];

  static const List<String> _kDartInTypes = ['int', 'double', 'num', 'bool'];

  @override
  List<String> get keywords => _kDartKeywords;

  @override
  List<String> get inTypes => <String>['int', 'double', 'num', 'bool'];

  @override
  bool containsInTypes(String word) => _kDartKeywords.contains(word);

  @override
  bool containsKeywords(String word) => _kDartInTypes.contains(word);
}
