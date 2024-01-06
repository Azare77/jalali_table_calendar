import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:jalali_table_calendar/jalali_table_calendar.dart';
import 'CalendarDayPicker.dart';
import 'CalendarMonthPicker.dart';
import 'CalendarYearPicker.dart';

class DatePickerCalendar extends StatefulWidget {
  const DatePickerCalendar({
    Key? key,
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
    this.onMonthChanged,
    this.marker,
    this.events,
    this.hour24Format,
    this.contextLocale,
    this.showArrows,
    this.onRangeChanged,
    required this.isRange,
  }) : super(key: key);

  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final Locale? contextLocale;
  final CalendarSelectableDayPredicate? selectableDayPredicate;
  final DatePickerModeCalendar? initialDatePickerMode;
  final String? selectedFormat;
  final bool? convertToGregorian;
  final bool? showTimePicker;
  final bool? hour24Format;
  final TimeOfDay? initialTime;

  final bool? showArrows;
  final bool isRange;

  //day marker
  final MarkerBuilder? marker;

  /// `Map` of events.
  /// Each `DateTime` inside this `Map` should get its own `List` of objects (i.e. events).
  final Map<DateTime, List>? events;

  /// Called whenever any day gets tapped.
  final OnDaySelected? onDaySelected;
  final OnRangeChanged? onRangeChanged;
  final OnMonthChanged? onMonthChanged;

  @override
  _DatePickerCalendarState createState() => _DatePickerCalendarState();
}

class _DatePickerCalendarState extends State<DatePickerCalendar> {
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

  void _handleMonthChanged(DateTime value) {
    if (widget.onMonthChanged != null) widget.onMonthChanged!(value);
    _vibrate();
    // setState(() {
    //
    // });
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

  void _handleRangeChanged(List<DateTime> value) {
    if (widget.onRangeChanged != null) widget.onRangeChanged!(value);
  }

  @override
  Widget build(BuildContext context) {
    final Widget picker = SizedBox(
      //it's too dirty  i know!!!
      height: MediaQuery.of(context).size.height - kDayPickerRowHeight - 6,
      child: _buildWidget(),
    );
    final Widget calendar = OrientationBuilder(
        builder: (BuildContext context, Orientation orientation) {
      switch (orientation) {
        case Orientation.portrait:
          return picker;
        case Orientation.landscape:
          //TODO:create landscape view
          return picker;
      }
    });
    return calendar;
  }

  Widget _buildWidget() {
    assert(_mode != null);
    switch (_mode) {
      case DatePickerModeCalendar.day:
        return CalendarMonthPicker(
          key: _pickerKey,
          selectedDate: _selectedDate!,
          onDayChanged: _handleDayChanged,
          onRangeChanged: _handleRangeChanged,
          onMonthChanged: _handleMonthChanged,
          isRange: widget.isRange,
          marker: widget.marker,
          events: widget.events,
          firstDate: widget.firstDate!,
          showArrows: widget.showArrows!,
          contextLocale: widget.contextLocale,
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
        return SizedBox();
    }
  }
}
