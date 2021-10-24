import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:yelo_date_range_calendar/date_util.dart';
import 'dart:ui';

@pragma("vm:entry-point")
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(chooseRoute(window.defaultRouteName));
}

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

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  AppLifecycleState? appLifecycleState;
  DateTime? minDate, maxDate, selectedPickupDate, selectedDropOffDate;

  final methodChannel = const MethodChannel('yelo.calendar/rangeCalendar2');

  final sendSelectedDateRangesMethodName = "sendSelectedDateRangesMethodName";

  final receiveMinMaxDatesMethodName = "receiveMinMaxDatesMethodName";

  final resetCalendarMethodName = "resetCalendarMethodName";

  final START_DATE = "START_DATE";

  final END_DATE = "END_DATE";

  final MINIMUM_DATE = "minimum_pickup_date";

  final MAXIMUM_DATE = "maximum_drop_off_date";

  final CHOSEN_START_DATE = "chosen_start_date";

  final CHOSEN_END_DATE = "chosen_end_date";

  DateRangePickerController _controller = DateRangePickerController();

  @override
  void initState() {
    WidgetsBinding.instance!.addObserver(this);
    super.initState();
    onReceiveMinMaxDates();
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      appLifecycleState = state;
    });
  }

  void onReceiveMinMaxDates() async {

    methodChannel.setMethodCallHandler((call) async {
      if (call.method == receiveMinMaxDatesMethodName &&
          call.arguments != null &&
          call.arguments.isNotEmpty) {
        var channelResultMap =
        jsonDecode(call.arguments) as Map<String, dynamic>;

          setState(() {
            if (channelResultMap[MINIMUM_DATE] != null &&
                channelResultMap[MINIMUM_DATE]
                    .toString()
                    .isNotEmpty) {
              minDate = DateUtil.parseStringToDate(
                  channelResultMap[MINIMUM_DATE], DateUtil.dashLongDateFormat);
            }
            if (channelResultMap[MAXIMUM_DATE] != null &&
                channelResultMap[MAXIMUM_DATE]
                    .toString()
                    .isNotEmpty) {
              maxDate = DateUtil.parseStringToDate(
                  channelResultMap[MAXIMUM_DATE], DateUtil.dashLongDateFormat);
            }
            if (channelResultMap[CHOSEN_START_DATE] != null &&
                channelResultMap[CHOSEN_START_DATE]
                    .toString()
                    .isNotEmpty) {
              selectedPickupDate = DateUtil.parseStringToDate(
                  channelResultMap[CHOSEN_START_DATE].toString(),
                  DateUtil.dashLongDateFormat);
            }
            if (channelResultMap[CHOSEN_END_DATE] != null &&
                channelResultMap[CHOSEN_END_DATE]
                    .toString()
                    .isNotEmpty) {
              selectedDropOffDate = DateUtil.parseStringToDate(
                  channelResultMap[CHOSEN_END_DATE].toString(),
                  DateUtil.dashLongDateFormat);
            }
            if (selectedPickupDate != null && selectedDropOffDate != null) {
              setState(() {
                SchedulerBinding.instance!
                    .addPostFrameCallback((Duration duration) {
                  _controller.selectedRange =
                      PickerDateRange(selectedPickupDate, selectedDropOffDate);
                });
              });
            }

          });
      }else  if (call.method == resetCalendarMethodName) {
        resetCalendar();
      }
    });
  }

  void resetCalendar() {
        setState(() {
          SchedulerBinding.instance!
              .addPostFrameCallback((Duration duration) {
            _controller.selectedRange = null;
          });
        });
      }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          body: SafeArea(
            child: Container(
              child: SfDateRangePicker(
                controller: _controller,
                view: DateRangePickerView.month,
                selectionMode: DateRangePickerSelectionMode.range,
                rangeSelectionColor: const Color(0xff50266F),
                selectionRadius: 17,
                backgroundColor: Colors.white,
                rangeTextStyle: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
                headerStyle: const DateRangePickerHeaderStyle(
                    backgroundColor: Color(0xffFAFAFA),
                    textStyle: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    )),
                startRangeSelectionColor: const Color(0xff50266F),
                endRangeSelectionColor: const Color(0xff50266F),
                viewSpacing: 1,
                navigationDirection:
                DateRangePickerNavigationDirection.vertical,
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
              ),
            ),
          ),
        ),
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
      START_DATE: startDate != null
          ? DateUtil.formatDate(DateUtil.dashLongDateFormatWithZ, startDate)
          : null,
      END_DATE: endDate != null
          ? DateUtil.formatDate(DateUtil.dashLongDateFormatWithZ, endDate)
          : null
    });
  }
}
