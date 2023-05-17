import 'package:flutter/rendering.dart';

class MonthPickerSortKey extends OrdinalSortKey {
  const MonthPickerSortKey(double order) : super(order);

  static const MonthPickerSortKey previousMonth = MonthPickerSortKey(1.0);
  static const MonthPickerSortKey nextMonth = MonthPickerSortKey(2.0);
  static const MonthPickerSortKey calendar = MonthPickerSortKey(3.0);
}