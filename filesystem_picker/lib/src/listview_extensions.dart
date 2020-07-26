import 'package:flutter/material.dart';
import 'dart:math' as math;

extension ListViewExtended on ListView {
  /// Creates a fixed-length scrollable linear array of list "items" separated
  /// by list item "separators".
  ///
  /// This constructor is appropriate for list views with a large number of
  /// item and separator children because the builders are only called for
  /// the children that are actually visible.
  ///
  /// The `itemBuilder` callback will be called with indices greater than
  /// or equal to zero and less than `itemCount`.
  ///
  /// Separators only appear between list items: separator 0 appears after item
  /// 0 and the last separator appears before the last item.
  ///
  /// The `separatorBuilder` callback will be called with indices greater than
  /// or equal to zero and less than `itemCount - 1`.
  ///
  /// The `itemBuilder` and `separatorBuilder` callbacks should actually create
  /// widget instances when called. Avoid using a builder that returns a
  /// previously-constructed widget; if the list view's children are created in
  /// advance, or all at once when the [ListView] itself is created, it is more
  /// efficient to use [new ListView].
  ///
  /// {@tool sample}
  ///
  /// This example shows how to create [ListView] whose [ListTile] list items
  /// are separated by [Divider]s.
  ///
  /// ```dart
  /// ListView.separatedWithHeaderFooter(
  ///   itemCount: 25,
  ///   separatorBuilder: (BuildContext context, int index) => Divider(),
  ///   itemBuilder: (BuildContext context, int index) {
  ///     return ListTile(
  ///       title: Text('item $index'),
  ///     );
  ///   },
  /// )
  /// ```
  /// {@end-tool}
  ///
  /// The `addAutomaticKeepAlives` argument corresponds to the
  /// [SliverChildBuilderDelegate.addAutomaticKeepAlives] property. The
  /// `addRepaintBoundaries` argument corresponds to the
  /// [SliverChildBuilderDelegate.addRepaintBoundaries] property. The
  /// `addSemanticIndexes` argument corresponds to the
  /// [SliverChildBuilderDelegate.addSemanticIndexes] property. None may be
  /// null.
  static ListView separatedWithHeaderFooter({
    Key key,
    Axis scrollDirection = Axis.vertical,
    bool reverse = false,
    ScrollController controller,
    bool primary,
    ScrollPhysics physics,
    bool shrinkWrap = false,
    EdgeInsetsGeometry padding,
    @required IndexedWidgetBuilder itemBuilder,
    @required IndexedWidgetBuilder separatorBuilder,
    WidgetBuilder headerBuilder,
    WidgetBuilder footerBuilder,
    @required int itemCount,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    double cacheExtent,
  }) {
    assert(itemBuilder != null);
    assert(separatorBuilder != null);
    assert(itemCount != null && itemCount >= 0);
    final int childCount =
        _computeSemanticChildCount(itemCount, headerBuilder, footerBuilder);

    SliverChildBuilderDelegate childrenDelegate = SliverChildBuilderDelegate(
      (BuildContext context, int index) {
        // final int itemIndex = (index ~/ 2);
        final int delta = ((headerBuilder != null) ? 1 : 0);
        final int itemIndex = (index - delta) ~/ 2;
        Widget widget;
        if ((headerBuilder != null) && (index == 0)) {
          widget = headerBuilder(context);
        } else if ((footerBuilder != null) && (index == (childCount - 1))) {
          widget = footerBuilder(context);
        } else if ((index - delta).isEven) {
          widget = itemBuilder(context, itemIndex);
        } else {
          widget = separatorBuilder(context, itemIndex);
          assert(() {
            if (widget == null) {
              throw FlutterError('separatorBuilder cannot return null.');
            }
            return true;
          }());
        }
        return widget;
      },
      childCount: childCount,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      addSemanticIndexes: addSemanticIndexes,
      semanticIndexCallback: (Widget _, int index) {
        return index.isEven
            ? ((((headerBuilder != null) ? 1 : 0) + index) ~/ 2)
            : null;
      },
    );
    return ListView.custom(
      key: key,
      scrollDirection: scrollDirection,
      reverse: reverse,
      controller: controller,
      primary: primary,
      physics: physics,
      shrinkWrap: shrinkWrap,
      padding: padding,
      itemExtent: null,
      childrenDelegate: childrenDelegate,
      semanticChildCount: childCount,
    );
  }

  // Helper method to compute the semantic child count for the separated constructor.
  static int _computeSemanticChildCount(
      int itemCount, WidgetBuilder headerBuilder, WidgetBuilder footerBuilder) {
    return math.max(0, itemCount * 2 - 1) +
        ((headerBuilder != null) ? 1 : 0) +
        ((footerBuilder != null) ? 1 : 0);
  }
}
