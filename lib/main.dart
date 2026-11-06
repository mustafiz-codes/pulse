import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'app/bootstrap.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  runApp(const PulseBootstrap());
}
