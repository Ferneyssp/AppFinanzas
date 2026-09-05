import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'providers/finance_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/main_navigation.dart';
import 'services/notificacion_service.dart';
import 'services/preferencias_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar fechas en español.
  await initializeDateFormatting('es');

  // Inicializar notificaciones.
  await NotificacionService.instance.inicializar();

  // Cargar las preferencias antes de iniciar la interfaz.
  final settingsProvider = SettingsProvider();
  await settingsProvider.cargar();

  runApp(
    FinanzasStudentApp(
      settingsProvider: settingsProvider,
    ),
  );
}

class FinanzasStudentApp extends StatelessWidget {
  final SettingsProvider settingsProvider;

  const FinanzasStudentApp({
    super.key,
    required this.settingsProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: settingsProvider,
        ),
        ChangeNotifierProvider(
          create: (_) => FinanceProvider()..cargar(),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Finanzas Student',
            debugShowCheckedModeBanner: false,

            theme: AppTheme.claro(settings.paleta),

            darkTheme: AppTheme.oscuro(settings.paleta),

            themeMode: settings.tema == ModoTema.oscuro
                ? ThemeMode.dark
                : ThemeMode.light,

            home: const MainNavigation(),
          );
        },
      ),
    );
  }
}