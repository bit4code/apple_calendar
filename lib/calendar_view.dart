import 'dart:developer';

import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CalendarsView extends StatefulWidget {
  const CalendarsView({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _CalendarsViewState createState() {
    return _CalendarsViewState();
  }
}

class _CalendarsViewState extends State<CalendarsView> {
  late DeviceCalendarPlugin _deviceCalendarPlugin;
  List<Calendar> _calendars = [];
  List<Event> calendarEvents = [];
  List<Calendar> get _writableCalendars =>
      _calendars.where((c) => c.isReadOnly == false).toList();

  List<Calendar> get _readOnlyCalendars =>
      _calendars.where((c) => c.isReadOnly == true).toList();

  _CalendarsViewState() {
    _deviceCalendarPlugin = DeviceCalendarPlugin();
  }

  Future<void> retrieveCalendarEvents(Calendar calendar) async {
    final startDate = DateTime.now().add(const Duration(days: -30));
    final endDate = DateTime.now().add(const Duration(days: 30));
    var calendarEventsResult = await _deviceCalendarPlugin.retrieveEvents(
        calendar.id,
        RetrieveEventsParams(startDate: startDate, endDate: endDate));
    setState(() {
      calendarEvents = calendarEventsResult.data as List<Event>;
    });
  }

  @override
  void initState() {
    super.initState();
    _retrieveCalendars();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Apple calendar'),centerTitle: true,),
      body: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10), color: Colors.white),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Center(
              child: Text(
                "Apple Calendar",
              ),
            ),
            Center(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: Get.width * 0.05),
                child: const Text(
                  "By click on sync button please sync your calendar.",
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: ListView.builder(
                itemCount: _calendars.length,
                itemBuilder: (BuildContext context, int index) {
                  if (_calendars[index].isDefault!) {
                    return Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                  flex: 1,
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _calendars[index].name!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle1,
                                        ),
                                        Text(
                                            "Account: ${_calendars[index].accountName!}"),
                                      ])),
                              Container(
                                width: 15,
                                height: 15,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(_calendars[index].color!)),
                              ),
                              const SizedBox(width: 10),
                              if (_calendars[index].isDefault!)
                                Container(
                                  margin:
                                      const EdgeInsets.fromLTRB(0, 0, 5.0, 0),
                                  padding: const EdgeInsets.all(5.0),
                                  decoration: BoxDecoration(
                                      border:
                                          Border.all(color: Colors.blueAccent),
                                      borderRadius: BorderRadius.circular(20)),
                                  child: const Text('Default'),
                                ),
                              Icon(_calendars[index].isReadOnly == true
                                  ? Icons.lock
                                  : Icons.lock_open)
                            ],
                          ),
                          Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                  key: Key(_calendars[index].isReadOnly == true
                                      ? 'readOnlyCalendar${_readOnlyCalendars.indexWhere((c) => c.id == _calendars[index].id)}'
                                      : 'writableCalendar${_writableCalendars.indexWhere((c) => c.id == _calendars[index].id)}'),
                                  onTap: () async {
                                    retrieveCalendarEvents(_calendars[index]);
                                  },
                                  child: Container(
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          color: Colors.blue),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: Get.width * 0.02,
                                            vertical: Get.height * 0.005),
                                        child: const Text(
                                          "Sync Now",
                                        ),
                                      ))))
                        ],
                      ),
                    );
                  } else {
                    return Container();
                  }
                },
              ),
            ),
            Expanded(
                flex: 1,
                child: ListView.builder(
                  itemCount: calendarEvents.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        children: [
                          Text(
                              "start : ${calendarEvents[index].start!.toLocal()}"),
                          Text("end : ${calendarEvents[index].end!.toLocal()}"),
                        ],
                      ),
                    );
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _retrieveCalendars() async {
    try {
      var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
      if (permissionsGranted.isSuccess &&
          (permissionsGranted.data == null ||
              permissionsGranted.data == false)) {
        permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
        if (!permissionsGranted.isSuccess ||
            permissionsGranted.data == null ||
            permissionsGranted.data == false) {
          return;
        }
      }

      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      setState(() {
        _calendars = calendarsResult.data as List<Calendar>;
      });
    } on PlatformException catch (e) {
      log(e.toString());
    }
  }
}
