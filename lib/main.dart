import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'services/audio_service.dart';
import 'services/print_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init locale Indonesia
  await initializeDateFormatting('id', null);

  // Lock orientasi ke portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Init services
  await AudioService.instance.init();
  await PrintService.instance.tryAutoConnect();

  runApp(const KopiJalananApp());
}
