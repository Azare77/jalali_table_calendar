import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:jalali_table_calendar/src/persian_date.dart';

/// Initial display mode of the date picker calendar.
///
/// Date picker UI mode for either showing a list of available years or a
/// monthly calendar initially in the calendar shown by calling [showDatePicker].
///
/// Also see:
///
///  * <https://material.io/guidelines/components/pickers.html#pickers-date-pickers>
enum DatePickerModeCalendar {
  /// Show a date picker UI for choosing a month and day.
  day,

  /// Show a date picker UI for choosing a year.
  year,
}

bool calendarInitialized = false;
//callback function when user change day
typedef void OnDaySelected(DateTime day);
//callback function for create marker
typedef MarkerBuilder = Widget Function(DateTime date, List? events);

const double _kDatePickerHeaderPortraitHeight = 100.0;
const double _kDatePickerHeaderLandscapeWidth = 168.0;

const Duration _kMonthScrollDuration = Duration(milliseconds: 200);
const double _kDayPickerRowHeight = 50.0;
const int _kMaxDayPickerRowCount = 6; // A 31 day month that starts on Saturday.
// Two extra rows: one for the day-of-week header and one for the month header.
const double _kMaxDayPickerHeight =
    _kDayPickerRowHeight * (_kMaxDayPickerRowCount + 2);

class _DayPickerGridDelegate extends SliverGridDelegate {
  const _DayPickerGridDelegate();

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    const int columnCount = DateTime.daysPerWeek;
    final double tileWidth = constraints.crossAxisExtent / columnCount;
    final double tileHeight = math.min(_kDayPickerRowHeight,
        constraints.viewportMainAxisExtent / (_kMaxDayPickerRowCount + 1));
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
  bool shouldRelayout(_DayPickerGridDelegate oldDelegate) => false;
}

const _DayPickerGridDelegate _kDayPickerGridDelegate = _DayPickerGridDelegate();

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

  static List<String> dayH = const [
    'ش',
    'ی',
    'د',
    'س',
    'چ',
    'پ',
    'ج',
  ];

  List<Widget> _getDayHeaders() {
    final List<Widget> result = <Widget>[];
    for (String dayHader in dayH) {
      result.add(ExcludeSemantics(
        child: Center(child: Text(dayHader)),
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
    var modeyear = year % 33;
    if (month == 12) return _kabise.indexOf(modeyear) != -1 ? 30 : 29;

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
    final PersianDate selectedPersainDate =
        PersianDate.pDate(gregorian: selectedDate.toString());

    final PersianDate currentPDate =
        PersianDate.pDate(gregorian: currentDate.toString());

    final List<Widget> labels = <Widget>[];

    var pDay = _digits(mDay, 2);
    var gMonth = _digits(month, 2);

    var parseP = date.parse("$year-$gMonth-$pDay");
    var jtgData = date.jalaliToGregorian(parseP[0], parseP[1], 01);

    var pMonth = _digits(jtgData[1], 2);

    PersianDate pdate =
        PersianDate.pDate(gregorian: "${jtgData[0]}-$pMonth-${jtgData[2]}");
    var daysInMonth = getDaysInMonth(pdate.year!, pdate.month);
    var startday = dayShort.indexOf(pdate.weekdayname);

    labels.addAll(_getDayHeaders());
    for (int i = 0; true; i += 1) {
      final int day = i - startday + 1;
      if (day > daysInMonth) break;
      if (day < 1) {
        labels.add(Container());
      } else {
        var pDay = _digits(day, 2);
        var jtgData = date.jalaliToGregorian(
            getPearData.year!, getPearData.month!, int.parse(pDay));
        final DateTime dayToBuild =
            DateTime(jtgData[0], jtgData[1], jtgData[2]);
        final PersianDate getHolidy =
            PersianDate.pDate(gregorian: dayToBuild.toString());

        final bool disabled = dayToBuild.isAfter(lastDate) ||
            dayToBuild.isBefore(firstDate) ||
            (selectableDayPredicate != null &&
                !selectableDayPredicate!(dayToBuild));

        BoxDecoration? decoration;
        TextStyle? itemStyle = themeData.textTheme.bodyText1;

        final bool isSelectedDay =
            selectedPersainDate.year == getPearData.year &&
                selectedPersainDate.month == getPearData.month &&
                selectedPersainDate.day == day;
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
        } else if (getHolidy.isHoliday) {
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
                    child: Text(day.toString(), style: itemStyle),
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
                height: _kDayPickerRowHeight,
                child: Center(
                  child: ExcludeSemantics(
                    child: Text(
                      "${pdate.monthname}  ${pdate.year}",
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

/// A scrollable list of months to allow picking a month.
///
/// Shows the days of each month in a rectangular grid with one column for each
/// day of the week.
///
/// The month picker widget is rarely used directly. Instead, consider using
/// [showDatePicker], which creates a date picker calendar.
///
/// See also:
///
///  * [showDatePicker]
///  * <https://material.google.com/components/pickers.html#pickers-date-pickers>
class CalendarMonthPicker extends StatefulWidget {
  /// Creates a month picker.
  ///
  /// Rarely used directly. Instead, typically used as part of the calendar shown
  /// by [showDatePicker].
  CalendarMonthPicker({
    Key? key,
    required this.selectedDate,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.marker,
    this.events,
    this.selectableDayPredicate,
  })  : assert(!firstDate.isAfter(lastDate)),
        assert(selectedDate.isAfter(firstDate) ||
            selectedDate.isAtSameMomentAs(firstDate)),
        super(key: key);

  //day marker
  final MarkerBuilder? marker;

  /// `Map` of events.
  /// Each `DateTime` inside this `Map` should get its own `List` of objects (i.e. events).
  final Map<DateTime, List>? events;

  /// The currently selected date.
  ///
  /// This date is highlighted in the picker.
  final DateTime selectedDate;

  /// Called when the user picks a month.
  final ValueChanged<DateTime> onChanged;

  /// The earliest date the user is permitted to pick.
  final DateTime firstDate;

  /// The latest date the user is permitted to pick.
  final DateTime lastDate;

  /// Optional user supplied predicate function to customize selectable days.
  final CalendarSelectableDayPredicate? selectableDayPredicate;

  @override
  _CalendarMonthPickerState createState() => _CalendarMonthPickerState();
}

class _CalendarMonthPickerState extends State<CalendarMonthPicker>
    with SingleTickerProviderStateMixin {
  static final Animatable<double> _chevronOpacityTween =
      Tween<double>(begin: 1.0, end: 0.0)
          .chain(CurveTween(curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    // Initially display the pre-selected date.
    final int monthPage = _monthDelta(widget.firstDate, widget.selectedDate);
    _dayPickerController = PageController(initialPage: monthPage);
    _handleMonthPageChanged(monthPage);
    _updateCurrentDate();

    // Setup the fade animation for chevrons
    _chevronOpacityController = AnimationController(
        duration: const Duration(milliseconds: 250), vsync: this);
    _chevronOpacityAnimation =
        _chevronOpacityController.drive(_chevronOpacityTween);
  }

  @override
  void didUpdateWidget(CalendarMonthPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      final int monthPage = _monthDelta(widget.firstDate, widget.selectedDate);
      _dayPickerController = PageController(initialPage: monthPage);
      _handleMonthPageChanged(monthPage);
    }
  }

  late MaterialLocalizations localizations;
  late TextDirection textDirection;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    localizations = MaterialLocalizations.of(context);
    textDirection = Directionality.of(context);
  }

  late DateTime _todayDate;
  late DateTime _currentDisplayedMonthDate;
  Timer? _timer;
  PageController? _dayPickerController;
  late AnimationController _chevronOpacityController;
  late Animation<double> _chevronOpacityAnimation;

  void _updateCurrentDate() {
    _todayDate = DateTime.now();
    final DateTime tomorrow =
        DateTime(_todayDate.year, _todayDate.month, _todayDate.day + 1);
    Duration timeUntilTomorrow = tomorrow.difference(_todayDate);
    timeUntilTomorrow +=
        const Duration(seconds: 1); // so we don't miss it by rounding
    _timer?.cancel();
    _timer = Timer(timeUntilTomorrow, () {
      setState(() {
        _updateCurrentDate();
      });
    });
  }

  static int _monthDelta(DateTime startDate, DateTime endDate) {
    return (endDate.year - startDate.year) * 12 +
        endDate.month -
        startDate.month;
  }

  /// Add months to a month truncated date.
  DateTime _addMonthsToMonthDate(DateTime monthDate, int monthsToAdd) {
    return DateTime(
        monthDate.year + monthsToAdd ~/ 12, monthDate.month + monthsToAdd % 12);
  }

  Widget _buildItems(BuildContext context, int index) {
    DateTime month = _addMonthsToMonthDate(widget.firstDate, index);

    final PersianDate selectedPersainDate = PersianDate.pDate(
        gregorian: widget.selectedDate.toString()); // To Edit Month Displaye

    if (selectedPersainDate.day! >= 1 &&
        selectedPersainDate.day! < 12 &&
        !calendarInitialized) {
      month = _addMonthsToMonthDate(widget.firstDate, index + 1);
      _handleNextMonth(initialized: false);
    }

    // if (!widget.isSelected && !changed) {
    // }
    calendarInitialized = true;
    return CalendarDayPicker(
      selectedDate: widget.selectedDate,
      currentDate: _todayDate,
      onChanged: widget.onChanged,
      firstDate: widget.firstDate,
      marker: widget.marker,
      lastDate: widget.lastDate,
      events: widget.events,
      displayedMonth: month,
      selectableDayPredicate: widget.selectableDayPredicate,
    );
  }

  void _handleNextMonth({initialized = true}) async {
    if (!_isDisplayingLastMonth) {
      SemanticsService.announce(
          localizations.formatMonthYear(_nextMonthDate), textDirection);
      _dayPickerController!.nextPage(
          duration:
              initialized ? _kMonthScrollDuration : Duration(milliseconds: 1),
          curve: Curves.ease);
    }
  }

  void _handlePreviousMonth() {
    if (!_isDisplayingFirstMonth) {
      SemanticsService.announce(
          localizations.formatMonthYear(_previousMonthDate), textDirection);
      _dayPickerController!
          .previousPage(duration: _kMonthScrollDuration, curve: Curves.ease);
    }
  }

  /// True if the earliest allowable month is displayed.
  bool get _isDisplayingFirstMonth {
    return !_currentDisplayedMonthDate
        .isAfter(DateTime(widget.firstDate.year, widget.firstDate.month));
  }

  /// True if the latest allowable month is displayed.
  bool get _isDisplayingLastMonth {
    return !_currentDisplayedMonthDate
        .isBefore(DateTime(widget.lastDate.year, widget.lastDate.month));
  }

  late DateTime _previousMonthDate;
  late DateTime _nextMonthDate;

  void _handleMonthPageChanged(int monthPage) {
    setState(() {
      _previousMonthDate =
          _addMonthsToMonthDate(widget.firstDate, monthPage - 1);
      _currentDisplayedMonthDate =
          _addMonthsToMonthDate(widget.firstDate, monthPage);
      _nextMonthDate = _addMonthsToMonthDate(widget.firstDate, monthPage + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Semantics(
          sortKey: _MonthPickerSortKey.calendar,
          child: NotificationListener<ScrollStartNotification>(
            onNotification: (_) {
              _chevronOpacityController.forward();
              return false;
            },
            child: NotificationListener<ScrollEndNotification>(
              onNotification: (_) {
                _chevronOpacityController.reverse();
                return false;
              },
              child: PageView.builder(
                controller: _dayPickerController,
                scrollDirection: Axis.horizontal,
                itemCount: _monthDelta(widget.firstDate, widget.lastDate) + 1,
                itemBuilder: _buildItems,
                onPageChanged: _handleMonthPageChanged,
              ),
            ),
          ),
        ),
        PositionedDirectional(
          top: 0.0,
          start: 8.0,
          child: Semantics(
            sortKey: _MonthPickerSortKey.previousMonth,
            child: FadeTransition(
              opacity: _chevronOpacityAnimation,
              child: IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: _isDisplayingFirstMonth
                    ? null
                    : '${localizations.previousMonthTooltip} ${localizations.formatMonthYear(_previousMonthDate)}',
                onPressed:
                    _isDisplayingFirstMonth ? null : _handlePreviousMonth,
              ),
            ),
          ),
        ),
        PositionedDirectional(
          top: 0.0,
          end: 8.0,
          child: Semantics(
            sortKey: _MonthPickerSortKey.nextMonth,
            child: FadeTransition(
              opacity: _chevronOpacityAnimation,
              child: IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: _isDisplayingLastMonth
                    ? null
                    : '${localizations.nextMonthTooltip} ${localizations.formatMonthYear(_nextMonthDate)}',
                onPressed: _isDisplayingLastMonth ? null : _handleNextMonth,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dayPickerController?.dispose();
    calendarInitialized = false;
    super.dispose();
  }
}

// Defines semantic traversal order of the top-level widgets inside the month
// picker.
class _MonthPickerSortKey extends OrdinalSortKey {
  const _MonthPickerSortKey(double order) : super(order);

  static const _MonthPickerSortKey previousMonth = _MonthPickerSortKey(1.0);
  static const _MonthPickerSortKey nextMonth = _MonthPickerSortKey(2.0);
  static const _MonthPickerSortKey calendar = _MonthPickerSortKey(3.0);
}

/// A scrollable list of years to allow picking a year.
///
/// The year picker widget is rarely used directly. Instead, consider using
/// [showDatePicker], which creates a date picker calendar.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * [showDatePicker]
///  * <https://material.google.com/components/pickers.html#pickers-date-pickers>
class CalendarYearPicker extends StatefulWidget {
  /// Creates a year picker.
  ///
  /// The [selectedDate] and [onChanged] arguments must not be null. The
  /// [lastDate] must be after the [firstDate].
  ///
  /// Rarely used directly. Instead, typically used as part of the calendar shown
  /// by [showDatePicker].
  CalendarYearPicker({
    Key? key,
    required this.selectedDate,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
  })  : assert(!firstDate.isAfter(lastDate)),
        super(key: key);

  /// The currently selected date.
  ///
  /// This date is highlighted in the picker.
  final DateTime selectedDate;

  /// Called when the user picks a year.
  final ValueChanged<DateTime> onChanged;

  /// The earliest date the user is permitted to pick.
  final DateTime firstDate;

  /// The latest date the user is permitted to pick.
  final DateTime lastDate;

  @override
  _CalendarYearPickerState createState() => _CalendarYearPickerState();
}

class _CalendarYearPickerState extends State<CalendarYearPicker> {
  static const double _itemExtent = 50.0;
  ScrollController? scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController(
      // Move the initial scroll position to the currently selected date's year.
      initialScrollOffset:
          (widget.selectedDate.year - widget.firstDate.year) * _itemExtent,
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final ThemeData themeData = Theme.of(context);
    final TextStyle? style = themeData.textTheme.bodyText1;

    return ListView.builder(
      controller: scrollController,
      itemExtent: _itemExtent,
      itemCount: widget.lastDate.year - widget.firstDate.year + 1,
      itemBuilder: (BuildContext context, int index) {
        final int year = widget.firstDate.year + index;
        final bool isSelected = year == widget.selectedDate.year;
        var dateee =
            DateTime(year, widget.selectedDate.month, widget.selectedDate.day);
        var pYear = PersianDate.pDate(gregorian: dateee.toString());
        final TextStyle? itemStyle = isSelected
            ? themeData.textTheme.headline1!
                .copyWith(color: themeData.primaryColor)
            : style;
        return InkWell(
          key: ValueKey<int>(year),
          onTap: () {
            widget.onChanged(DateTime(
                year, widget.selectedDate.month, widget.selectedDate.day));
          },
          child: Center(
            child: Semantics(
              selected: isSelected,
              child: Text(pYear.year.toString(), style: itemStyle),
            ),
          ),
        );
      },
    );
  }
}

class _DatePickerCalendar extends StatefulWidget {
  const _DatePickerCalendar(
      {Key? key,
      this.initialDate,
      this.firstDate,
      this.lastDate,
      this.selectableDayPredicate,
      this.initialDatePickerMode,
      this.selectedFormat,
      this.showTimePicker,
      this.convertToGregorian,
      this.initialTime,
      this.onDaySelected,
      this.marker,
      this.events,
      this.hore24Format})
      : super(key: key);

  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final CalendarSelectableDayPredicate? selectableDayPredicate;
  final DatePickerModeCalendar? initialDatePickerMode;
  final String? selectedFormat;
  final bool? convertToGregorian;
  final bool? showTimePicker;
  final bool? hore24Format;
  final TimeOfDay? initialTime;

  //day marker
  final MarkerBuilder? marker;

  /// `Map` of events.
  /// Each `DateTime` inside this `Map` should get its own `List` of objects (i.e. events).
  final Map<DateTime, List>? events;

  /// Called whenever any day gets tapped.
  final OnDaySelected? onDaySelected;

  @override
  _DatePickerCalendarState createState() => _DatePickerCalendarState();
}

class _DatePickerCalendarState extends State<_DatePickerCalendar> {
  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _mode = widget.initialDatePickerMode;
  }

  bool _announcedInitialDate = false;

  late MaterialLocalizations localizations;
  late TextDirection textDirection;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    localizations = MaterialLocalizations.of(context);
    textDirection = Directionality.of(context);
    if (!_announcedInitialDate) {
      _announcedInitialDate = true;
      SemanticsService.announce(
        localizations.formatFullDate(_selectedDate!),
        textDirection,
      );
    }
  }

  DateTime? _selectedDate;
  DatePickerModeCalendar? _mode;
  final GlobalKey _pickerKey = GlobalKey();

  void _vibrate() {
    switch (Theme.of(context).platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        HapticFeedback.vibrate();
        break;
      case TargetPlatform.iOS:
        break;
      default:
        break;
    }
  }

  void _handleModeChanged(DatePickerModeCalendar mode) {
    _vibrate();
    setState(() {
      _mode = mode;
      if (_mode == DatePickerModeCalendar.day) {
        SemanticsService.announce(
            localizations.formatMonthYear(_selectedDate!), textDirection);
      } else {
        SemanticsService.announce(
            localizations.formatYear(_selectedDate!), textDirection);
      }
    });
  }

  void _handleYearChanged(DateTime value) {
    _vibrate();
    setState(() {
      _mode = DatePickerModeCalendar.day;
      _selectedDate = value;
    });
  }

  void _handleDayChanged(DateTime value) {
    if (widget.onDaySelected != null) widget.onDaySelected!(value);
    _vibrate();
    setState(() {
      _selectedDate = value;
    });
  }

  Widget? _buildWidget() {
    assert(_mode != null);
    switch (_mode) {
      case DatePickerModeCalendar.day:
        return CalendarMonthPicker(
          key: _pickerKey,
          selectedDate: _selectedDate!,
          onChanged: _handleDayChanged,
          marker: widget.marker,
          events: widget.events,
          firstDate: widget.firstDate!,
          lastDate: widget.lastDate!,
          selectableDayPredicate: widget.selectableDayPredicate,
        );
      case DatePickerModeCalendar.year:
        return CalendarYearPicker(
          key: _pickerKey,
          selectedDate: _selectedDate!,
          onChanged: _handleYearChanged,
          firstDate: widget.firstDate!,
          lastDate: widget.lastDate!,
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget picker = SizedBox(
      height: _kMaxDayPickerHeight,
      child: _buildWidget(),
    );

    final Widget calendar = OrientationBuilder(
        builder: (BuildContext context, Orientation orientation) {
      switch (orientation) {
        case Orientation.portrait:
          return picker;
        case Orientation.landscape:
          return picker;
      }
    });
    // _handleDayChanged(widget.initialDate);
    return calendar;
  }
}

/// Signature for predicating dates for enabled date selections.
///
/// See [showDatePicker].
typedef CalendarSelectableDayPredicate = bool Function(DateTime day);

/// Shows a dialog containing a material design date picker.
///
/// The returned [Future] resolves to the date selected by the user when the
/// user closes the dialog. If the user cancels the dialog, null is returned.
///
/// An optional [selectableDayPredicate] function can be passed in to customize
/// the days to enable for selection. If provided, only the days that
/// [selectableDayPredicate] returned true for will be selectable.
///
/// An optional [initialDatePickerMode] argument can be used to display the
/// date picker initially in the year or month+day picker mode. It defaults
/// to month+day, and must not be null.
///
/// An optional [locale] argument can be used to set the locale for the date
/// picker. It defaults to the ambient locale provided by [Localizations].
///
/// An optional [textDirection] argument can be used to set the text direction
/// (RTL or LTR) for the date picker. It defaults to the ambient text direction
/// provided by [Directionality]. If both [locale] and [textDirection] are not
/// null, [textDirection] overrides the direction chosen for the [locale].
///
/// The `context` argument is passed to [showDialog], the documentation for
/// which discusses how it is used.
///
/// See also:
///
///  * [showTimePicker]
///  * <https://material.google.com/components/pickers.html#pickers-date-pickers>
Widget jalaliCalendar({
  required BuildContext context,
  CalendarSelectableDayPredicate? selectableDayPredicate,
  DatePickerModeCalendar initialDatePickerMode = DatePickerModeCalendar.day,
  String? selectedFormat,
  bool? toArray,
  Locale? locale,
  TextDirection textDirection = TextDirection.rtl,
  bool convertToGregorian = false,
  bool showTimePicker = false,
  bool hore24Format = false,
  TimeOfDay? initialTime,
  MarkerBuilder? marker,
  Map<DateTime, List>? events,
  OnDaySelected? onDaySelected,
}) {
  DateTime initialDate = DateTime.now();
  DateTime firstDate = DateTime(1700);
  DateTime lastDate = DateTime(2200);
  if (events != null) {
    Map<DateTime, List>? newEvents = {};
    events.forEach((key, value) {
      newEvents[DateTime(key.year, key.month, key.day)] = value;
    });
    events = newEvents;
  }

  assert(!initialDate.isBefore(firstDate),
      'initialDate must be on or after firstDate');
  assert(!initialDate.isAfter(lastDate),
      'initialDate must be on or before lastDate');
  assert(
      !firstDate.isAfter(lastDate), 'lastDate must be on or after firstDate');
  assert(selectableDayPredicate == null || selectableDayPredicate(initialDate),
      'Provided initialDate must satisfy provided selectableDayPredicate');
  // assert(context != null);
  // assert(debugCheckHasMaterialLocalizations(context));

  Widget child = _DatePickerCalendar(
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    selectableDayPredicate: selectableDayPredicate,
    initialDatePickerMode: initialDatePickerMode,
    selectedFormat: selectedFormat ?? "yyyy-mm-dd HH:nn:ss",
    hore24Format: hore24Format,
    showTimePicker: showTimePicker,
    marker: marker,
    events: events,
    onDaySelected: onDaySelected,
    convertToGregorian: convertToGregorian,
    initialTime: initialTime ?? TimeOfDay.now(),
  );

  child = Directionality(
    textDirection: textDirection,
    child: child,
  );

  if (locale != null) {
    child = Localizations.override(
      context: context,
      locale: locale,
      child: child,
    );
  }

  return child;
}
