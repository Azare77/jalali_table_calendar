import 'package:flutter/material.dart';
import 'package:jalali_table_calendar/jalali_table_calendar.dart';

import 'DayPickerGridDelegate.dart';

// const double _kDatePickerHeaderPortraitHeight = 100.0;
// const double _kDatePickerHeaderLandscapeWidth = 168.0;

// const Duration _kMonthScrollDuration = Duration(milliseconds: 200);
const double kDayPickerRowHeight = 50.0;
const int kMaxDayPickerRowCount = 6; // A 31 day month that starts on Saturday.
// Two extra rows: one for the day-of-week header and one for the month header.

const DayPickerGridDelegate _kDayPickerGridDelegate = DayPickerGridDelegate();

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
class CalendarDayPicker extends StatelessWidget {
  /// Creates a day picker.
  ///
  /// Rarely used directly. Instead, typically used as part of a [CalendarMonthPicker].
  CalendarDayPicker({
    Key? key,
    required this.selectedDate,
    required this.currentDate,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    required this.displayedMonth,
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
  final ValueChanged<DateTime> onChanged;

  /// The earliest date the user is permitted to pick.
  final DateTime firstDate;

  /// The latest date the user is permitted to pick.
  final DateTime lastDate;

  /// The month whose days are displayed by this picker.
  final DateTime displayedMonth;

  /// Optional user supplied predicate function to customize selectable days.
  final CalendarSelectableDayPredicate? selectableDayPredicate;

  final Locale? contextLocale;

  /// Builds widgets showing abbreviated days of week. The first widget in the
  /// returned list corresponds to the first day of week for the current locale.
  ///
  /// Examples:
  ///
  /// ```
  /// ┌ Sunday is the first day of week in the US (en_US)
  /// |
  /// S M T W T F S  <-- the returned list contains these widgets
  /// _ _ _ _ _ 1 2
  /// 3 4 5 6 7 8 9
  ///
  /// ┌ But it's Monday in the UK (en_GB)
  /// |
  /// M T W T F S S  <-- the returned list contains these widgets
  /// _ _ _ _ 1 2 3
  /// 4 5 6 7 8 9 10
  /// ```
  ///
  ///
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
    for (String dayHeader in dayHeader()) {
      color = dayHeader == 'ج' || dayHeader == 'Su' ? Colors.red : Colors.black;
      result.add(ExcludeSemantics(
        child: Center(child: Text(dayHeader, style: TextStyle(color: color))),
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

  /// Computes the offset from the first day of week that the first day of the
  /// [month] falls on.
  ///
  /// For example, September 1, 2017 falls on a Friday, which in the calendar
  /// localized for United States English appears as:
  ///
  /// ```
  /// S M T W T F S
  /// _ _ _ _ _ 1 2
  /// ```
  ///
  /// The offset for the first day of the months is the number of leading blanks
  /// in the calendar, i.e. 5.
  ///
  /// The same date localized for the Russian calendar has a different offset,
  /// because the first day of week is Monday rather than Sunday:
  ///
  /// ```
  /// M T W T F S S
  /// _ _ _ _ 1 2 3
  /// ```
  ///
  /// So the offset is 4, rather than 5.
  ///
  /// This code consolidates the following:
  ///
  /// - [DateTime.weekday] provides a 1-based index into days of week, with 1
  ///   falling on Monday.
  /// - [MaterialLocalizations.firstDayOfWeekIndex] provides a 0-based index
  ///   into the [MaterialLocalizations.narrowWeekdays] list.
  /// - [MaterialLocalizations.narrowWeekdays] list provides localized names of
  ///   days of week, always starting with Sunday and ending with Saturday.
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
    if (contextLocale == Locale('fa', 'IR') || contextLocale == Locale('fa'))
      numbers.forEach((key, value) => number = number.replaceAll(key, value));
    return number;
  }

  List<String> dayHeader() {
    if (contextLocale == Locale('fa', 'IR') || contextLocale == Locale('fa'))
      return dayH;
    else
      return dayEn;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
    final int year = displayedMonth.year;
    final int month = displayedMonth.month;
    final int mDay = displayedMonth.day;

    final PersianDate getPearData =
        PersianDate.pDate(gregorian: displayedMonth.toString());
    final PersianDate selectedPersianDate =
        PersianDate.pDate(gregorian: selectedDate.toString());

    final PersianDate currentPDate =
        PersianDate.pDate(gregorian: currentDate.toString());

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

        final bool disabled = dayToBuild.isAfter(lastDate) ||
            dayToBuild.isBefore(firstDate) ||
            (selectableDayPredicate != null &&
                !selectableDayPredicate!(dayToBuild));

        BoxDecoration? decoration;
        TextStyle? itemStyle = themeData.textTheme.bodyText1;

        final bool isSelectedDay =
            selectedPersianDate.year == getPearData.year &&
                selectedPersianDate.month == getPearData.month &&
                selectedPersianDate.day == day;
        if (isSelectedDay) {
          // The selected day gets a circle background highlight, and a contrasting text color.
          itemStyle = themeData.textTheme.bodyText2
              ?.copyWith(color: themeData.scaffoldBackgroundColor);
          decoration = BoxDecoration(
              color: themeData.primaryColor, shape: BoxShape.circle);
        } else if (disabled) {
          itemStyle = themeData.textTheme.bodyText2!
              .copyWith(color: themeData.disabledColor);
        } else if (currentPDate.year == getPearData.year &&
            currentPDate.month == getPearData.month &&
            currentPDate.day == day) {
          // The current day gets a different text color.
          itemStyle = themeData.textTheme.bodyText2!
              .copyWith(color: themeData.primaryColor);
        } else if (getHoliday.isHoliday) {
          // The current day gets a different text color.
          itemStyle =
              themeData.textTheme.bodyText2!.copyWith(color: Colors.red);
        }

        // prepare to events to return to view
        List? dayEvents = [];
        if (events![dayToBuild] != null) dayEvents = events![dayToBuild];
        //get Marker for day
        Widget mark = marker!(dayToBuild, dayEvents);
        Widget dayWidget = Container(
          decoration: decoration,
          child: Stack(
            children: [
              Center(
                child: Semantics(
                  // We want the day of month to be spoken first irrespective of the
                  // locale-specific preferences or TextDirection. This is because
                  // an accessibility user is more likely to be interested in the
                  // day of month before the rest of the date, as they are looking
                  // for the day of month. To do that we prepend day of month to the
                  // formatted full date.
                  label:
                      '${localizations.formatDecimal(day)}, ${localizations.formatFullDate(dayToBuild)}',
                  selected: isSelectedDay,
                  child: ExcludeSemantics(
                    child:
                        Text(numberFormatter(day.toString()), style: itemStyle),
                  ),
                ),
              ),
              if (marker != null &&
                  events != null &&
                  events![dayToBuild] != null)
                mark
            ],
          ),
        );

        if (!disabled) {
          dayWidget = GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              onChanged(dayToBuild);
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
          child: Column(
            children: <Widget>[
              Container(
                height: kDayPickerRowHeight,
                child: Center(
                  child: ExcludeSemantics(
                    child: Text(
                      "${pDate.monthname}  ${numberFormatter(pDate.year.toString())}",
                      style: themeData.textTheme.headline5,
                    ),
                  ),
                ),
              ),
              Flexible(
                child: GridView.custom(
                  gridDelegate: _kDayPickerGridDelegate,
                  childrenDelegate: SliverChildListDelegate(labels,
                      addRepaintBoundaries: false),
                ),
              ),
            ],
          )),
    );
  }
}
