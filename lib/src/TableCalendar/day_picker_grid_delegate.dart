import 'package:flutter/rendering.dart';
import 'dart:math' as math;

import 'calendar_day_picker.dart';

class DayPickerGridDelegate extends SliverGridDelegate {
  const DayPickerGridDelegate();

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    const int columnCount = DateTime.daysPerWeek;
    final double tileWidth = constraints.crossAxisExtent / columnCount;
    final double tileHeight = math.min(kDayPickerRowHeight,
        constraints.viewportMainAxisExtent / (kMaxDayPickerRowCount + 1));
    return SliverGridRegularTileLayout(
      crossAxisCount: columnCount,
      mainAxisStride: tileHeight,
      crossAxisStride: tileWidth,
      childMainAxisExtent: tileHeight,
      childCrossAxisExtent: tileWidth,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(DayPickerGridDelegate oldDelegate) => false;
}
