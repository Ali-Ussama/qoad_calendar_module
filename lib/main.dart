import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:yelo_date_range_calendar/date_util.dart';
import 'dart:ui';

void main() => runApp(chooseRoute(window.defaultRouteName));

Widget chooseRoute(String route) {
  switch (route) {
    case 'calendar':
      return MyApp();
    default:
      return MyApp();
  }
}

class MyApp extends StatefulWidget {

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  DateTime? minDate, maxDate;

  final methodChannel = const MethodChannel('yelo.calendar/rangeCalendar2');

  final sendSelectedDateRangesMethodName = "sendSelectedDateRangesMethodName";

  final receiveMinMaxDatesMethodName = "receiveMinMaxDatesMethodName";

  final START_DATE = "START_DATE";

  final END_DATE = "END_DATE";

  final MIN_DATE = "MIN_DATE";

  final MAX_DATE = "MAX_DATE";

  @override
  void initState() {
    super.initState();
    print("Flutter: MyApp: initState");

    getMinMaxDates();
  }

  void getMinMaxDates() async {
    print("Flutter: MyApp: getMinMaxDates");

    await methodChannel.invokeMethod(receiveMinMaxDatesMethodName)
        .then((channelResult) {
      if (channelResult != null && channelResult.toString().isNotEmpty) {
        var channelResultMap =
            jsonDecode(channelResult) as Map<String, dynamic>;
          if (channelResultMap[MIN_DATE] != null && channelResultMap[MIN_DATE].toString().isNotEmpty) {
            setState(() {
              print("Flutter: MyApp: getMinMaxDates: setState");
              minDate = DateUtil.parseStringToDate(
                channelResultMap[MIN_DATE].toString(),
                DateUtil.dashLongDateFormat);
            maxDate = DateUtil.parseStringToDate(
                channelResultMap[MAX_DATE].toString(),
                DateUtil.dashLongDateFormat);
            });
          }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: Scaffold(
        body: SafeArea(
            child: SfDateRangePicker(
          view: DateRangePickerView.month,
          selectionMode: DateRangePickerSelectionMode.range,
          rangeSelectionColor: const Color(0xff50266F),
          selectionRadius: 17,
          backgroundColor: Colors.white,
          rangeTextStyle:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          headerStyle: const DateRangePickerHeaderStyle(
              backgroundColor: Color(0xffFAFAFA),
              textStyle: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              )),
          startRangeSelectionColor: const Color(0xff50266F),
          endRangeSelectionColor: const Color(0xff50266F),
          viewSpacing: 1,
          navigationDirection: DateRangePickerNavigationDirection.vertical,
          showNavigationArrow: false,
          allowViewNavigation: true,
          enableMultiView: true,
          showActionButtons: false,
          minDate: minDate,
          maxDate: maxDate,
          navigationMode: DateRangePickerNavigationMode.scroll,
          monthViewSettings:
              const DateRangePickerMonthViewSettings(dayFormat: "EEE"),
          onSelectionChanged: _onSelectionChanged,
        )),
      ),
    );
  }

  void _onSelectionChanged(DateRangePickerSelectionChangedArgs args) {
    if (args.value is PickerDateRange) {
      DateTime? rangeStartDate = args.value.startDate;
      DateTime? rangeEndDate = args.value.endDate;
      sendDateRangesToNative(startDate: rangeStartDate, endDate: rangeEndDate);
    } else if (args.value is DateTime) {
      final DateTime selectedDate = args.value;
    } else if (args.value is List) {
      final List selectedDates = args.value;
    } else {
      final dynamic selectedRanges = args.value;
    }
  }

  void sendDateRangesToNative(
      {required DateTime? startDate, required DateTime? endDate}) {
    methodChannel.invokeMethod(sendSelectedDateRangesMethodName, {
      START_DATE:
          startDate != null ? DateUtil.formatDate(DateUtil.dashLongDateTimeFormatMS, startDate) : null,
      END_DATE: endDate != null ? DateUtil.formatDate(DateUtil.dashLongDateTimeFormatMS, endDate) : null
    });
  }
}
