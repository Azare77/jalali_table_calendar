import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:jalali_table_calendar/jalali_table_calendar.dart';

import 'calendar_day_picker.dart';
import 'calendar_month_picker.dart';
import 'calendar_year_picker.dart';

const double _kMaxDayPickerHeight =
    kDayPickerRowHeight * (kMaxDayPickerRowCount + 2);

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
    this.marker,
    this.events,
    this.hour24Format,
    this.contextLocale,
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

  //day marker
  final MarkerBuilder? marker;

  /// `Map` of events.
  /// Each `DateTime` inside this `Map` should get its own `List` of objects (i.e. events).
  final Map<DateTime, List>? events;

  /// Called whenever any day gets tapped.
  final OnDaySelected? onDaySelected;

  @override
  State<DatePickerCalendar> createState() => _DatePickerCalendarState();
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

  // void _handleModeChanged(DatePickerModeCalendar mode) {
  //   _vibrate();
  //   setState(() {
  //     _mode = mode;
  //     if (_mode == DatePickerModeCalendar.day) {
  //       SemanticsService.announce(
  //           localizations.formatMonthYear(_selectedDate!), textDirection);
  //     } else {
  //       SemanticsService.announce(
  //           localizations.formatYear(_selectedDate!), textDirection);
  //     }
  //   });
  // }

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
          //TODO:create landscape view
          return picker;
      }
    });
    return calendar;
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
        return null;
    }
  }
}
