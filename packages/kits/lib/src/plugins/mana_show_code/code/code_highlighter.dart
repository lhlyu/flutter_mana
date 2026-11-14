import 'package:flutter/widgets.dart';

import '../../../ui/kit_ui.dart';

/// Stateless highlighting: every token covers a contiguous part of the source.
TextSpan highlightDart(String source) {
  final spans = <TextSpan>[];
  var index = 0;
  var plainStart = 0;
  final identifier = RegExp(r'[a-zA-Z_$][\w$]*');
  final number = RegExp(
    r'(?:0[xX][\da-fA-F_]+|\d[\d_]*(?:\.\d[\d_]*)?(?:[eE][+-]?\d[\d_]*)?)',
  );
  const keywords = {
    'abstract',
    'as',
    'assert',
    'async',
    'augment',
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
    'Function',
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
    'operator',
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
  };
  while (index < source.length) {
    final start = index;
    Color? color;
    if (source.startsWith('//', index)) {
      final end = source.indexOf('\n', index);
      index = end < 0 ? source.length : end;
      color = KitStyle.muted;
    } else if (source.startsWith('/*', index)) {
      index += 2;
      var depth = 1;
      while (index < source.length && depth > 0) {
        if (source.startsWith('/*', index)) {
          depth++;
          index += 2;
        } else if (source.startsWith('*/', index)) {
          depth--;
          index += 2;
        } else {
          index++;
        }
      }
      color = KitStyle.muted;
    } else {
      final raw =
          source[index] == 'r' &&
          index + 1 < source.length &&
          (source[index + 1] == "'" || source[index + 1] == '"');
      final quoteIndex = raw ? index + 1 : index;
      final quote = source[quoteIndex];
      if (quote == "'" || quote == '"') {
        final triple = source.startsWith(quote * 3, quoteIndex);
        final delimiter = quote * (triple ? 3 : 1);
        index = quoteIndex + delimiter.length;
        while (index < source.length) {
          if (!raw && source[index] == '\\') {
            index = (index + 2).clamp(0, source.length);
          } else if (source.startsWith(delimiter, index)) {
            index += delimiter.length;
            break;
          } else {
            index++;
          }
        }
        color = KitStyle.success;
      } else if (number.matchAsPrefix(source, index) case final match?) {
        index = match.end;
        color = KitStyle.warning;
      } else if (identifier.matchAsPrefix(source, index) case final match?) {
        index = match.end;
        if (keywords.contains(match[0])) color = KitStyle.accent;
      } else {
        index++;
      }
    }
    if (color != null) {
      if (plainStart < start) {
        spans.add(TextSpan(text: source.substring(plainStart, start)));
      }
      spans.add(
        TextSpan(
          text: source.substring(start, index),
          style: TextStyle(color: color),
        ),
      );
      plainStart = index;
    }
  }
  if (plainStart < source.length) {
    spans.add(TextSpan(text: source.substring(plainStart)));
  }
  return TextSpan(style: KitStyle.code, children: spans);
}
