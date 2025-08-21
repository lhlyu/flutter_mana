import 'package:flutter/widgets.dart';

const nil = _Nil();

const nilPosition = Positioned(left: -1, top: -1, child: SizedBox.shrink());

class _Nil extends Widget {
  const _Nil();

  @override
  Element createElement() => _NilElement(this);
}

class _NilElement extends Element {
  _NilElement(_Nil super.widget);

  @override
  void mount(Element? parent, dynamic newSlot) {
    assert(parent is! MultiChildRenderObjectElement, """
        You are using Nil under a MultiChildRenderObjectElement.
        This suggests a possibility that the Nil is not needed or is being used improperly.
        Make sure it can't be replaced with an inline conditional or
        omission of the target widget from a list.
        """);

    super.mount(parent, newSlot);
  }

  @override
  bool get debugDoingBuild => false;

  @override
  void performRebuild() {
    super.performRebuild();
  }
}
