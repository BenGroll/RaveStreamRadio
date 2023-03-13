import 'package:flutter/material.dart';
import 'package:ravestreamradioapp/screens/draftscreen.dart';
import 'package:ravestreamradioapp/screens/mainscreens/calendar.dart';
import 'package:ravestreamradioapp/shared_state.dart';

/// Calendar that only shows your drafted Events
/// 
/// Easily modifyable to other modes
class DraftCalendar extends StatelessWidget {
  const DraftCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    return EventCalendar(
        loggedinas: currently_loggedin_as.value, mode: CalendarMode.drafts);
  }
}
