import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:jalali_table_calendar/jalali_table_calendar.dart';

import 'CalendarDayPicker.dart';
import 'MonthPickerSortKey.dart';

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
    this.contextLocale,
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
  final Locale? contextLocale;

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
  void dispose() {
    _timer?.cancel();
    _dayPickerController?.dispose();
    calendarInitialized = false;
    super.dispose();
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

    final PersianDate selectedPersianDate = PersianDate.pDate(
        gregorian: widget.selectedDate.toString()); // To Edit Month Display

    if (selectedPersianDate.day! >= 1 &&
        selectedPersianDate.day! < 12 &&
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
      contextLocale: widget.contextLocale,
      events: widget.events,
      displayedMonth: month,
      selectableDayPredicate: widget.selectableDayPredicate,
    );
  }

  Future<void> _handleNextMonth({initialized = true}) async {
    try {
      if (!_isDisplayingLastMonth) {
        SemanticsService.announce(
            localizations.formatMonthYear(_nextMonthDate), textDirection);
        _dayPickerController!.nextPage(
            duration:
            initialized ? kMonthScrollDuration : Duration(milliseconds: 1),
            curve: Curves.ease);
      }
    } catch (e) {
      await Future.delayed(Duration(microseconds: 1));
      await _handleNextMonth(initialized: initialized);
    }
  }

  void _handlePreviousMonth() {
    if (!_isDisplayingFirstMonth) {
      SemanticsService.announce(
          localizations.formatMonthYear(_previousMonthDate), textDirection);
      _dayPickerController!
          .previousPage(duration: kMonthScrollDuration, curve: Curves.ease);
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
          sortKey: MonthPickerSortKey.calendar,
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
            sortKey: MonthPickerSortKey.previousMonth,
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
            sortKey: MonthPickerSortKey.nextMonth,
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

}