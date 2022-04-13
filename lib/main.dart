import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:yelo_date_range_calendar/color_utils.dart';
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
  DateTime? minDate = DateTime.now(),
      maxDate,
      selectedPickupDate,
      selectedDropOffDate;
  Color? calendarBackgroundColor,
      calendarTextColor,
      selectedRangeBackgroundColor,
      selectedRangeTextColor;
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

  final CALENDAR_BACKGROUND_COLOR = "calendar_background_color";

  final CALENDAR_TEXT_COLOR = "calendar_text_color";

  final SELECTED_RANGE_BACKGROUND_COLOR = "selected_range_background_color";

  final SELECTED_RANGE_TEXT_COLOR = "selected_range_text_color";

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
          parseColorsConfigurations(channelResultMap);

          parseDateConfigurations(channelResultMap);
        });
      } else if (call.method == resetCalendarMethodName) {
        resetCalendar();
      }
    });
  }

  void resetCalendar() {
    setState(() {
      SchedulerBinding.instance!.addPostFrameCallback((Duration duration) {
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
                monthFormat: "MMM",
                rangeSelectionColor: selectedRangeBackgroundColor ??
                    ColorUtils.rangeSelectionColor,
                todayHighlightColor: selectedRangeBackgroundColor ??
                    ColorUtils.rangeSelectionColor,
                selectionRadius: 17,
                backgroundColor: calendarBackgroundColor ??
                    ColorUtils.calendarBackgroundColor,
                rangeTextStyle: TextStyle(
                    color: selectedRangeTextColor ??
                        ColorUtils.rangeSelectionTextColor,
                    fontWeight: FontWeight.bold),
                headerStyle: DateRangePickerHeaderStyle(
                    backgroundColor: calendarBackgroundColor ??
                        ColorUtils.calendarBackgroundColor,
                    textStyle: TextStyle(
                      color: calendarTextColor ?? ColorUtils.calendarTextColor,
                      fontWeight: FontWeight.bold,
                    )),
                startRangeSelectionColor: selectedRangeBackgroundColor ??
                    ColorUtils.rangeSelectionColor,
                endRangeSelectionColor: selectedRangeBackgroundColor ??
                    ColorUtils.rangeSelectionColor,
                selectionTextStyle: TextStyle(
                    color: selectedRangeTextColor ??
                        ColorUtils.rangeSelectionTextColor),
                viewSpacing: 1,
                navigationDirection:
                    DateRangePickerNavigationDirection.vertical,
                showNavigationArrow: false,
                allowViewNavigation: true,
                enableMultiView: true,
                showActionButtons: false,
                minDate: minDate,
                maxDate: maxDate,
                monthCellStyle: DateRangePickerMonthCellStyle(
                  textStyle: TextStyle(
                      color: calendarTextColor ?? ColorUtils.calendarTextColor),
                  disabledDatesTextStyle: const TextStyle(color: Colors.grey),
                ),
                navigationMode: DateRangePickerNavigationMode.scroll,
                monthViewSettings: const DateRangePickerMonthViewSettings(
                  dayFormat: "EEE",
                ),
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

  void parseColorsConfigurations(Map<String, dynamic> channelResultMap) {
    try {
      if (channelResultMap[CALENDAR_BACKGROUND_COLOR] != null &&
          channelResultMap[CALENDAR_BACKGROUND_COLOR].toString().isNotEmpty) {
        calendarBackgroundColor = ColorUtils.fromHex(
            channelResultMap[CALENDAR_BACKGROUND_COLOR].toString());
      }

      if (channelResultMap[CALENDAR_TEXT_COLOR] != null &&
          channelResultMap[CALENDAR_TEXT_COLOR].toString().isNotEmpty) {
        calendarTextColor = ColorUtils.fromHex(
            channelResultMap[CALENDAR_TEXT_COLOR].toString());
      }

      if (channelResultMap[SELECTED_RANGE_BACKGROUND_COLOR] != null &&
          channelResultMap[SELECTED_RANGE_BACKGROUND_COLOR]
              .toString()
              .isNotEmpty) {
        selectedRangeBackgroundColor = ColorUtils.fromHex(
            channelResultMap[SELECTED_RANGE_BACKGROUND_COLOR].toString());
      }

      if (channelResultMap[SELECTED_RANGE_TEXT_COLOR] != null &&
          channelResultMap[SELECTED_RANGE_TEXT_COLOR].toString().isNotEmpty) {
        selectedRangeTextColor = ColorUtils.fromHex(
            channelResultMap[SELECTED_RANGE_TEXT_COLOR].toString());
      }
    } catch (e) {
      log(e.toString());
    }
  }

  void parseDateConfigurations(Map<String, dynamic> channelResultMap) {
    try {
      if (channelResultMap[MINIMUM_DATE] != null &&
          channelResultMap[MINIMUM_DATE].toString().isNotEmpty) {
        minDate = DateUtil.parseStringToDate(
            channelResultMap[MINIMUM_DATE], DateUtil.dashLongDateFormat);
      }
      if (channelResultMap[MAXIMUM_DATE] != null &&
          channelResultMap[MAXIMUM_DATE].toString().isNotEmpty) {
        maxDate = DateUtil.parseStringToDate(
            channelResultMap[MAXIMUM_DATE], DateUtil.dashLongDateFormat);
      }
      if (channelResultMap[CHOSEN_START_DATE] != null &&
          channelResultMap[CHOSEN_START_DATE].toString().isNotEmpty) {
        selectedPickupDate = DateUtil.parseStringToDate(
            channelResultMap[CHOSEN_START_DATE].toString(),
            DateUtil.dashLongDateFormat);
      }
      if (channelResultMap[CHOSEN_END_DATE] != null &&
          channelResultMap[CHOSEN_END_DATE].toString().isNotEmpty) {
        selectedDropOffDate = DateUtil.parseStringToDate(
            channelResultMap[CHOSEN_END_DATE].toString(),
            DateUtil.dashLongDateFormat);
      }
      if (selectedPickupDate != null && selectedDropOffDate != null) {
        setState(() {
          SchedulerBinding.instance!.addPostFrameCallback((Duration duration) {
            _controller.selectedRange =
                PickerDateRange(selectedPickupDate, selectedDropOffDate);
          });
        });
      }
    } catch (e) {
      log(e.toString());
    }
  }
}
