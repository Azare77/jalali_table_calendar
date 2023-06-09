import 'package:flutter/rendering.dart';
import 'dart:math' as math;

import 'CalendarDayPicker.dart';

class DayPickerGridDelegate extends SliverGridDelegate {
  const DayPickerGridDelegate();

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    const int columnCount = DateTime.daysPerWeek;
    final double tileWidth = constraints.crossAxisExtent / columnCount;
    final double tileHeight = constraints.viewportMainAxisExtent / (kMaxDayPickerRowCount+1);
    final double childTileHeight = math.max(kDayPickerRowHeight-5,
        constraints.viewportMainAxisExtent / (kMaxDayPickerRowCount+6));

    return SliverGridRegularTileLayout(
      crossAxisCount: columnCount,
      mainAxisStride: tileHeight,
      crossAxisStride: tileWidth,
      childMainAxisExtent: childTileHeight,
      childCrossAxisExtent: tileWidth,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(DayPickerGridDelegate oldDelegate) => false;
}