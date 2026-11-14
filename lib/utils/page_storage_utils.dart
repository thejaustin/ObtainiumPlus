import 'package:flutter/widgets.dart';

extension ExpansionBodyPageStorage on List<Widget> {
  /// ExpansionTile saves its open/closed state in PageStorage under the chain
  /// of PageStorageKeys above it, its own key included. A scrollable in the
  /// tile's body (a list, a row of chips, a TextField) gets the same chain
  /// unless another PageStorageKey sits in between, so the two overwrite each
  /// other and crash on restore: a bool read as a scroll offset, or a scroll
  /// offset read as a bool. Giving each body child its own key keeps the
  /// body's entries separate from the tile's.
  List<Widget> withOwnPageStorage() => [
    for (var i = 0; i < length; i++)
      KeyedSubtree(
        key: PageStorageKey<String>('expansion_body_$i'),
        child: this[i],
      ),
  ];
}
