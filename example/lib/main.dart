import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jalali_table_calendar/jalali_table_calendar.dart';
import 'package:shamsi_date/shamsi_date.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _State();
}

class _State extends State<MyApp> {
  String _datetime = '';
  final String _format = 'yyyy-mm-dd';
  String _value = '';
  String _valuePiker = '';
  DateTime selectedDate = DateTime.now();

  Future _selectDate() async {
    String? picked = await jalaliCalendarPicker(
        context: context,
        convertToGregorian: false,
        showTimePicker: true,
        hore24Format: true);
    if (picked != null) setState(() => _value = picked);
  }

  DateTime today = DateTime.now();

  @override
  void initState() {
    super.initState();
    print(
        'Parse TO Format ${Gregorian(2019, 02, 20, 00, 19, 54, 000).toJalali()}');
  }

  String numberFormatter(String number, bool persianNumber) {
    Map numbers = {
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
    if (persianNumber) {
      numbers.forEach((key, value) => number = number.replaceAll(key, value));
    }
    return number;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jalil Table Calendar'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Center(
              child: Column(
                children: <Widget>[
                  JalaliTableCalendar(
                    context: context,
                    locale: const Locale('fa'),
                    // add the events for each day
                    events: {
                      today: const ['sample event', 66546],
                      today.add(const Duration(days: 1)): const [
                        6,
                        5,
                        465,
                        1,
                        66546
                      ],
                      today.add(const Duration(days: 2)): const [
                        6,
                        5,
                        465,
                        66546
                      ],
                    },
                    //make marker for every day that have some events
                    marker: (date, events) {
                      return Positioned(
                        top: -4,
                        left: 0,
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.blue[200], shape: BoxShape.circle),
                          padding: const EdgeInsets.all(6.0),
                          child: Text(numberFormatter(
                              (events?.length).toString(), true)),
                        ),
                      );
                    },
                    onDaySelected: (date) {
                      print(date);
                    },
                    onMonthPageChanged: (date) {
                      print(date);
                    },
                  ),
                  const Text('  مبدّل تاریخ و زمان ,‌ تاریخ هجری شمسی '),
                  const Text(' تقویم شمسی '),
                  const Text('date picker شمسی '),
                  ElevatedButton(
                    onPressed: _selectDate,
                    child: const Text('نمایش تقویم'),
                  ),
                  ElevatedButton(
                    onPressed: _showDatePicker,
                    child: const Text('نمایش دیت پیکر'),
                  ),
                  Text(
                    '\nزمان و تاریخ فعلی سیستم :  ${Jalali.now()}',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                  const Divider(),
                  const Text(
                    'تقویم ',
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    _value,
                    textAlign: TextAlign.center,
                  ),
                  const Divider(),
                  Text(
                    _valuePiker,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
            // Expanded(child: ShowCalender())
          ],
        ),
      ),
    );
  }

  /// Display date picker.
  void _showDatePicker() async {
    await showDialog(
        context: context,
        builder: (context) => DateRangePickerDialog(
              firstDate: DateTime.now().subtract(const Duration(days: 3650)),
              lastDate: DateTime.now(),
            ));
    const bool showTitleActions = false;
    if (!mounted) return;
    DatePicker.showDatePicker(context,
        minYear: 1300,
        maxYear: 1450,
/*      initialYear: 1368,
      initialMonth: 05,
      initialDay: 30,*/
        confirm: const Text(
          'تایید',
          style: TextStyle(color: Colors.red),
        ),
        cancel: const Text(
          'لغو',
          style: TextStyle(color: Colors.cyan),
        ),
        dateFormat: _format, onChanged: (year, month, day) {
      if (year == null || month == null || day == null) return;
      if (!showTitleActions) {
        _changeDatetime(year, month, day);
      }
    }, onConfirm: (year, month, day) {
      if (year == null || month == null || day == null) return;
      _changeDatetime(year, month, day);
      _valuePiker =
          ' تاریخ ترکیبی : $_datetime  \n سال : $year \n  ماه :   $month \n  روز :  $day';
    });
  }

  void _changeDatetime(int year, int month, int day) {
    setState(() {
      _datetime = '$year-$month-$day';
    });
  }
}
