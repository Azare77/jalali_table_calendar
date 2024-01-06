import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jalali_table_calendar/jalali_table_calendar.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _State createState() => new _State();
}

class _State extends State<MyApp> {
  String _datetime = '';
  String _format = 'yyyy-mm-dd';
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

  late DateTime today;
  late Map<DateTime, List<dynamic>> events;

  @override
  void initState() {
    DateTime now = DateTime.now();
    today = DateTime(now.year, now.month, now.day);
    events = {
      today: ['sample event', 66546],
      today.add(Duration(days: 1)): [6, 5, 465, 1, 66546],
      today.add(Duration(days: 2)): [6, 5, 465, 66546],
    };
    super.initState();
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
    if (persianNumber)
      numbers.forEach((key, value) => number = number.replaceAll(key, value));
    return number;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Jalil Table Calendar'),
        centerTitle: true,
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            Flexible(
              child: JalaliTableCalendar(
                  context: context,
                  locale: Locale('fa'),
                  // add the events for each day
                  events: events,
                  //make marker for every day that have some events
                  marker: (date, events) {
                    return Positioned(
                      left: 0,
                      top: -3,
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.blue[200], shape: BoxShape.circle),
                        padding: const EdgeInsets.all(6.0),
                        child: Center(
                          child: Text(numberFormatter(
                              (events?.length).toString(), true)),
                        ),
                      ),
                    );
                  },
                  onMonthChanged: (DateTime date) {
                    print(date);
                  },
                  onRangeChanged: (List<DateTime> stEndRange) {
                    print(stEndRange[0]);
                    print(stEndRange[1]);
                  },
                  onDaySelected: (DateTime selectDate) {
                    print(selectDate);
                    print(events[selectDate]?[0]);
                  }),
            ),
            Text('  مبدّل تاریخ و زمان ,‌ تاریخ هجری شمسی '),
            Text(' تقویم شمسی '),
            Text('date picker شمسی '),
            new ElevatedButton(
              onPressed: _selectDate,
              child: new Text('نمایش تقویم'),
            ),
            new ElevatedButton(
              onPressed: _showDatePicker,
              child: new Text('نمایش دیت پیکر'),
            ),
            Divider(),
            Text(
              "تقویم ",
              textAlign: TextAlign.center,
            ),
            Text(
              _value,
              textAlign: TextAlign.center,
            ),
            Divider(),
            Text(
              _valuePiker,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Display date picker.
  void _showDatePicker() async {
    final bool showTitleActions = false;
    DatePicker.showDatePicker(context,
        minYear: 1300,
        maxYear: 1450,
        confirm: Text(
          'تایید',
          style: TextStyle(color: Colors.red),
        ),
        cancel: Text(
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
          " تاریخ ترکیبی : $_datetime  \n سال : $year \n  ماه :   $month \n  روز :  $day";
    });
  }

  void _changeDatetime(int year, int month, int day) {
    setState(() {
      _datetime = '$year-$month-$day';
    });
  }
}
