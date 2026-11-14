import 'package:flutter/foundation.dart';

void reportManaError(
  Object error,
  StackTrace stack,
  void Function(Object, StackTrace)? handler,
) {
  try {
    if (handler != null) {
      handler(error, stack);
    } else {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'flutter_mana',
        ),
      );
    }
  } catch (handlerError, handlerStack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: handlerError,
        stack: handlerStack,
        library: 'flutter_mana',
        context: ErrorDescription('while reporting a runtime error'),
        informationCollector: () => [
          DiagnosticsProperty<Object>('Original error', error),
        ],
      ),
    );
  }
}
