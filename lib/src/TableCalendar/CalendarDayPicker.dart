import 'package:flutter/material.dart';
import 'package:jalali_table_calendar/jalali_table_calendar.dart';

import 'DayPickerGridDelegate.dart';

// const double _kDatePickerHeaderPortraitHeight = 100.0;
// const double _kDatePickerHeaderLandscapeWidth = 168.0;

// const Duration _kMonthScrollDuration = Duration(milliseconds: 200);
late double kDayPickerRowHeight = 50.0;
const int kMaxDayPickerRowCount = 6; // A 31 day month that starts on Saturday.
// Two extra rows: one for the day-of-week header and one for the month header.

const DayPickerGridDelegate _kDayPickerGridDelegate = DayPickerGridDelegate();
typedef RangeChangedCallback = void Function(DateTime start, DateTime end);

/// Displays the days of a given month and allows choosing a day.
///
/// The days are arranged in a rectangular grid with one column for each day of
/// the week.
///
/// The day picker widget is rarely used directly. Instead, consider using
/// [showDatePicker], which creates a date picker calendar.
///
/// See also:
///
///  * [showDatePicker].
///  * <https://material.google.com/components/pickers.html#pickers-date-pickers>
// ignore: must_be_immutable
class CalendarDayPicker extends StatefulWidget {
  CalendarDayPicker({
    Key? key,
    required this.selectedDate,
    required this.currentDate,
    required this.onDayChanged,
    required this.onRangeChanged,
    required this.firstDate,
    required this.lastDate,
    required this.displayedMonth,
    this.isRange = false,
    this.contextLocale,
    this.marker,
    this.events,
    this.selectableDayPredicate,
  })  : assert(!firstDate.isAfter(lastDate)),
        assert(selectedDate.isAfter(firstDate) ||
            selectedDate.isAtSameMomentAs(firstDate)),
        super(key: key);

  //days marker
  final MarkerBuilder? marker;

  /// `Map` of events.
  /// Each `DateTime` inside this `Map` should get its own `List` of objects (i.e. events).
  final Map<DateTime, List>? events;

  /// The currently selected date.
  ///
  /// This date is highlighted in the picker.
  final DateTime selectedDate;

  /// The current date at the time the picker is displayed.
  final DateTime currentDate;

  /// Called when the user picks a day.
  final ValueChanged<DateTime> onDayChanged;

  /// Called when the user picks a day.
  final RangeChangedCallback onRangeChanged;

  bool isRange;

  /// The earliest date the user is permitted to pick.
  final DateTime firstDate;

  /// The latest date the user is permitted to pick.
  final DateTime lastDate;

  /// The month whose days are displayed by this picker.
  final DateTime displayedMonth;

  /// Optional user supplied predicate function to customize selectable days.
  final CalendarSelectableDayPredicate? selectableDayPredicate;

  final Locale? contextLocale;

  @override
  State<CalendarDayPicker> createState() => _CalendarDayPickerState();
}

class _CalendarDayPickerState extends State<CalendarDayPicker> {
  late TextStyle? itemStyle;

  DateTime? startRange;

  static List<String> dayShort = const [
    'شنبه',
    'یکشنبه',
    'دوشنبه',
    'سه شنبه',
    'چهارشنبه',
    'پنج شنبه',
    'جمعه',
  ];

  List<String> dayH = const [
    'ش',
    'ی',
    'د',
    'س',
    'چ',
    'پ',
    'ج',
  ];
  List<String> dayEn = const [
    'St',
    'Su',
    'Mo',
    'Tu',
    'Wn',
    'Th',
    'Fr',
  ];

  List<Widget> _getDayHeaders() {
    final List<Widget> result = <Widget>[];
    Color color;
    TextStyle headerStyle = itemStyle!;
    for (String dayHeader in dayHeader()) {
      color = (dayHeader == 'ج' || dayHeader == 'Su'
          ? Colors.red
          : itemStyle!.color)!;
      result.add(ExcludeSemantics(
        child: Center(
            child: Text(dayHeader, style: headerStyle.copyWith(color: color))),
      ));
    }
    return result;
  }

  static const List<int> _daysInMonth = <int>[
    31,
    31,
    31,
    31,
    31,
    31,
    30,
    30,
    30,
    30,
    30,
    -1
  ];

// if mode year on 33 equal one of kabise array year is kabise
  static const List<int> _kabise = <int>[1, 5, 9, 13, 17, 22, 26, 30];

  static int getDaysInMonth(int year, int? month) {
    var modeYear = year % 33;
    if (month == 12) return _kabise.indexOf(modeYear) != -1 ? 30 : 29;

    return _daysInMonth[month! - 1];
  }

  final PersianDate date = PersianDate.pDate();

  String _digits(int? value, int length) {
    String ret = '$value';
    if (ret.length < length) {
      ret = '0' * (length - ret.length) + ret;
    }
    return ret;
  }

  String numberFormatter(String number) {
    Map numbers = const {
      '0': '۰',
      '1': '۱',
      '2': '۲',
      '3': '۳',
      '4': '۴',
      '5': '۵',
      '6': '۶',
      '7': '۷',
      '8': '۸',
      '9': '۹',
    };
    if (widget.contextLocale == Locale('fa', 'IR') ||
        widget.contextLocale == Locale('fa'))
      numbers.forEach((key, value) => number = number.replaceAll(key, value));
    return number;
  }

  List<String> dayHeader() {
    if (widget.contextLocale == Locale('fa', 'IR') ||
        widget.contextLocale == Locale('fa'))
      return dayH;
    else
      return dayEn;
  }

  late bool isRange;

  @override
  void initState() {
    isRange = widget.isRange;
    if (isRange) startRange = widget.selectedDate;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    kDayPickerRowHeight = MediaQuery.of(context).size.height / 18;
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
    final int year = widget.displayedMonth.year;
    final int month = widget.displayedMonth.month;
    final int mDay = widget.displayedMonth.day;
    final PersianDate getPearData =
        PersianDate.pDate(gregorian: widget.displayedMonth.toString());
    final PersianDate selectedPersianDate =
        PersianDate.pDate(gregorian: widget.selectedDate.toString());

    final PersianDate currentPDate =
        PersianDate.pDate(gregorian: widget.currentDate.toString());

    final List<Widget> labels = <Widget>[];

    var pDay = _digits(mDay, 2);
    var gMonth = _digits(month, 2);

    var parseP = date.parse("$year-$gMonth-$pDay");
    var jtgData = date.jalaliToGregorian(parseP[0], parseP[1], 01);

    var pMonth = _digits(jtgData[1], 2);

    PersianDate pDate =
        PersianDate.pDate(gregorian: "${jtgData[0]}-$pMonth-${jtgData[2]}");
    var daysInMonth = getDaysInMonth(pDate.year!, pDate.month);
    var startDay = dayShort.indexOf(pDate.weekdayname);
    itemStyle = themeData.textTheme.titleLarge;
    labels.addAll(_getDayHeaders());
    for (int i = 0; true; i += 1) {
      final int day = i - startDay + 1;
      if (day > daysInMonth) break;
      if (day < 1) {
        labels.add(Container());
      } else {
        var pDay = _digits(day, 2);
        var jtgData = date.jalaliToGregorian(
            getPearData.year!, getPearData.month!, int.parse(pDay));
        final DateTime dayToBuild =
            DateTime(jtgData[0], jtgData[1], jtgData[2]);
        final PersianDate getHoliday =
            PersianDate.pDate(gregorian: dayToBuild.toString());

        final bool disabled = dayToBuild.isAfter(widget.lastDate) ||
            dayToBuild.isBefore(widget.firstDate) ||
            (widget.selectableDayPredicate != null &&
                !widget.selectableDayPredicate!(dayToBuild));

        BoxDecoration? decoration;
        itemStyle = themeData.textTheme.titleLarge;
        final bool isSelectedDay =
            selectedPersianDate.year == getPearData.year &&
                selectedPersianDate.month == getPearData.month &&
                selectedPersianDate.day == day;

        if (isSelectedDay) {
          // The selected day gets a circle background highlight, and a contrasting text color.
          itemStyle =
              itemStyle?.copyWith(color: themeData.scaffoldBackgroundColor);
          decoration = BoxDecoration(
            color: themeData.primaryColor,
            shape: BoxShape.circle,
          );
        } else if (disabled) {
          itemStyle = itemStyle!.copyWith(color: themeData.disabledColor);
        } else if (currentPDate.year == getPearData.year &&
            currentPDate.month == getPearData.month &&
            currentPDate.day == day) {
          // The current day gets a different text color.
          itemStyle = itemStyle!.copyWith(color: themeData.primaryColor);
        } else if (getHoliday.isHoliday) {
          // The current day gets a different text color.
          itemStyle = itemStyle!.copyWith(color: Colors.red);
        }
        if (isRange && startRange != null) {
          if (widget.selectedDate.isAfter(startRange!)) {
            if ((dayToBuild.isAfter(startRange!.subtract(Duration(days: 1))) &&
                dayToBuild.isBefore(widget.selectedDate))) {
              itemStyle =
                  itemStyle?.copyWith(color: themeData.scaffoldBackgroundColor);
              decoration = BoxDecoration(
                color: themeData.primaryColor,
                shape: BoxShape.circle,
              );
            }
          } else {
            if ((dayToBuild.isAfter(widget.selectedDate) &&
                    dayToBuild.isBefore(startRange!)) ||
                dayToBuild == startRange) {
              itemStyle =
                  itemStyle?.copyWith(color: themeData.scaffoldBackgroundColor);
              decoration = BoxDecoration(
                color: themeData.primaryColor,
                shape: BoxShape.circle,
              );
            }
          }
        }
        if (getHoliday.isHoliday) {
          // The current day gets a different text color.
          itemStyle = itemStyle!.copyWith(color: Colors.red);
        }
        // prepare to events to return to view
        List? dayEvents = [];
        if (widget.events![dayToBuild] != null)
          dayEvents = widget.events![dayToBuild];
        //get Marker for day
        Widget? mark = widget.marker != null
            ? widget.marker!(dayToBuild, dayEvents)
            : null;
        Widget dayWidget = Container(
          decoration: decoration,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Center(
                child: Semantics(
                  label:
                      '${localizations.formatDecimal(day)}, ${localizations.formatFullDate(dayToBuild)}',
                  selected: isSelectedDay,
                  child: ExcludeSemantics(
                    child:
                        Text(numberFormatter(day.toString()), style: itemStyle),
                  ),
                ),
              ),
              if (widget.marker != null &&
                  mark != null &&
                  widget.events != null &&
                  widget.events![dayToBuild] != null)
                mark
            ],
          ),
        );
        if (!disabled) {
          dayWidget = GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              widget.onDayChanged(dayToBuild);
              if (isRange) widget.onRangeChanged(startRange!, dayToBuild);
            },
            onLongPress: () {
              if (widget.isRange) {
                setState(() {
                  isRange = isRange;
                  startRange = isRange ? dayToBuild : null;
                });
                widget.onDayChanged(dayToBuild);
              }
            },
            child: dayWidget,
          );
        }
        labels.add(dayWidget);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                SizedBox(
                  height: kDayPickerRowHeight,
                  child: Text(
                    "${pDate.monthname}  ${numberFormatter(pDate.year.toString())}",
                    style: themeData.textTheme.headlineSmall,
                  ),
                ),
                Flexible(
                  child: GridView.custom(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: _kDayPickerGridDelegate,
                    childrenDelegate: SliverChildListDelegate(
                      labels,
                      addRepaintBoundaries: false,
                    ),
                  ),
                ),
              ],
            ),
          )),
    );
  }
}
