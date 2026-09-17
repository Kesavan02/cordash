import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'data/datasources/health_connect_data_source.dart';
import 'data/repositories/health_repository_impl.dart';
import 'data/repositories/permission_repository_impl.dart';
import 'data/services/deduplication_service.dart';
import 'domain/repositories/health_repository.dart';
import 'domain/repositories/permission_repository.dart';
import 'domain/usecases/check_permissions_usecase.dart';
import 'domain/usecases/get_heart_rate_stream_usecase.dart';
import 'domain/usecases/get_steps_stream_usecase.dart';
import 'domain/usecases/request_permissions_usecase.dart';
import 'presentation/providers/health_dashboard_provider.dart';
import 'presentation/providers/performance_hud_provider.dart';
import 'presentation/providers/permission_provider.dart';
import 'presentation/screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Data Layer singletons
  final healthDataSource = HealthConnectDataSource();
  final dedupService = DeduplicationService();
  final HealthRepository healthRepository = HealthRepositoryImpl(
    dataSource: healthDataSource,
    dedupService: dedupService,
  );
  final PermissionRepository permissionRepository = PermissionRepositoryImpl(
    dataSource: healthDataSource,
  );

  // Initialize Domain Use Cases
  final getStepsStreamUseCase = GetStepsStreamUseCase(healthRepository);
  final getHeartRateStreamUseCase = GetHeartRateStreamUseCase(healthRepository);
  final checkPermissionsUseCase = CheckPermissionsUseCase(permissionRepository);
  final requestPermissionsUseCase = RequestPermissionsUseCase(permissionRepository);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => HealthDashboardProvider(
            repository: healthRepository,
            getStepsStream: getStepsStreamUseCase,
            getHeartRateStream: getHeartRateStreamUseCase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => PermissionProvider(
            checkPermissions: checkPermissionsUseCase,
            requestPermissions: requestPermissionsUseCase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => PerformanceHudProvider(),
        ),
      ],
      child: const CorDashApp(),
    ),
  );
}

class CorDashApp extends StatelessWidget {
  const CorDashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CorDash',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0C0E17),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFFFF2A6D),
          surface: Color(0xFF161823),
        ),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}
