import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jalali_table_calendar/jalali_table_calendar.dart';
import 'package:persian_date/persian_date.dart' as pDate;

void main() {
  runApp(new MaterialApp(
    debugShowCheckedModeBanner: false,
    home: new MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  @override
  _State createState() => new _State();
}

class _State extends State<MyApp> {
  pDate.PersianDate persianDate =
      pDate.PersianDate(format: "yyyy/mm/dd  \n DD  , d  MM  ");
  String _datetime = '';
  String _format = 'yyyy-mm-dd';
  String _value = '';
  String _valuePiker = '';
  DateTime selectedDate = DateTime.now();

  Future _selectDate() async {
    String picked = await jalaliCalendarPicker(
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
        "Parse TO Format ${persianDate.gregorianToJalali("2019-02-20T00:19:54.000Z", "yyyy-m-d hh:nn")}");
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Jalili Table Calendar'),
        centerTitle: true,
      ),
      body: new Container(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Center(
                child: Column(
                  children: <Widget>[
                    jalaliCalendar(
                        context: context,
                        // add the events for each day
                        events: {
                          today: ['sample event', 66546],
                          today.add(Duration(days: 1)): [6, 5, 465, 1, 66546],
                          today.add(Duration(days: 2)): [6, 5, 465, 66546],
                        },
                        //make marker for every day that have some events
                        marker: (date, events) {
                          return Positioned(
                            top: -4,
                            left: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.blue[200],
                                  shape: BoxShape.circle),
                              padding: const EdgeInsets.all(6.0),
                              child: Text((events?.length).toString()),
                            ),
                          );
                        },
                        onDaySelected: (date) {
                          print(date);
                        }),
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
                    Text(
                      "\nزمان و تاریخ فعلی سیستم :  ${persianDate.now}",
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
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
              )
              // Expanded(child: ShowCalender())
            ],
          ),
        ),
      ),
    );
  }

  /// Display date picker.
  void _showDatePicker() async {
    await showDialog(
        context: context,
        builder: (context) => DateRangePickerDialog(
              firstDate: DateTime.now().subtract(Duration(days: 3650)),
              lastDate: DateTime.now(),
            ));
    final bool showTitleActions = false;
    DatePicker.showDatePicker(context,
        minYear: 1300,
        maxYear: 1450,
/*      initialYear: 1368,
      initialMonth: 05,
      initialDay: 30,*/
        confirm: Text(
          'تایید',
          style: TextStyle(color: Colors.red),
        ),
        cancel: Text(
          'لغو',
          style: TextStyle(color: Colors.cyan),
        ),
        dateFormat: _format, onChanged: (year, month, day) {
      if (!showTitleActions) {
        _changeDatetime(year, month, day);
      }
    }, onConfirm: (year, month, day) {
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
