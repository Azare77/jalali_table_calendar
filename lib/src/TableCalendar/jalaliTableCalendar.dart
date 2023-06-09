import 'dart:async';
import 'package:flutter/material.dart';
import 'DatePickerCalendar.dart';

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
//callback function when user change month
typedef void OnMonthChanged(DateTime monthsToAdd);
//callback function for create marker
typedef MarkerBuilder = Widget Function(DateTime date, List? events);

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
class JalaliTableCalendar extends StatefulWidget {
  final BuildContext context;
  final CalendarSelectableDayPredicate? selectableDayPredicate;
  final DatePickerModeCalendar initialDatePickerMode;
  final String? selectedFormat;
  final Locale? locale;
  final TextDirection textDirection;
  final bool convertToGregorian;
  final bool showTimePicker;
  final bool hour24Format;
  final TimeOfDay? initialTime;
  final MarkerBuilder? marker;
  final Map<DateTime, List>? events;
  final OnDaySelected? onDaySelected;
  final OnMonthChanged? onMonthChanged;

  JalaliTableCalendar(
      {required this.context,
      this.selectableDayPredicate,
      this.selectedFormat,
      this.locale,
      this.initialDatePickerMode = DatePickerModeCalendar.day,
      this.textDirection = TextDirection.rtl,
      this.convertToGregorian = false,
      this.showTimePicker = false,
      this.hour24Format = false,
      this.initialTime,
      this.marker,
      this.events,
      this.onDaySelected,
      this.onMonthChanged});

  @override
  _JalaliTableCalendarState createState() => _JalaliTableCalendarState();
}

class _JalaliTableCalendarState extends State<JalaliTableCalendar> {
  @override
  Widget build(BuildContext context) {
    DateTime initialDate = DateTime.now();
    DateTime firstDate = DateTime(1700);
    DateTime lastDate = DateTime(2200);
    Map<DateTime, List>? formattedEvents = {};
    if (widget.events != null) {
      widget.events!.forEach((key, value) {
        formattedEvents[DateTime(key.year, key.month, key.day)] = value;
      });
    }

    assert(!initialDate.isBefore(firstDate),
        'initialDate must be on or after firstDate');
    assert(!initialDate.isAfter(lastDate),
        'initialDate must be on or before lastDate');
    assert(
        !firstDate.isAfter(lastDate), 'lastDate must be on or after firstDate');
    assert(
        widget.selectableDayPredicate == null ||
            widget.selectableDayPredicate!(initialDate),
        'Provided initialDate must satisfy provided selectableDayPredicate');
    // assert(context != null);
    // assert(debugCheckHasMaterialLocalizations(context));

    return Directionality(
      textDirection: widget.textDirection,
      child: DatePickerCalendar(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        selectableDayPredicate: widget.selectableDayPredicate,
        initialDatePickerMode: widget.initialDatePickerMode,
        selectedFormat: widget.selectedFormat ?? "yyyy-mm-dd HH:nn:ss",
        hour24Format: widget.hour24Format,
        showTimePicker: widget.showTimePicker,
        marker: widget.marker,
        events: formattedEvents,
        contextLocale: widget.locale,
        onDaySelected: widget.onDaySelected,
        onMonthChanged: widget.onMonthChanged,
        convertToGregorian: widget.convertToGregorian,
        initialTime: widget.initialTime ?? TimeOfDay.now(),
      ),
    );
  }
}
