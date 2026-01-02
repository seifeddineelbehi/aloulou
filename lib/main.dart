import 'package:firebase_core/firebase_core.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Core services
import 'core/services/storage_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/ai_config_service.dart';
import 'core/services/ai_service_manager.dart';

// ViewModels
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/viewmodels/chat_history_viewmodel.dart';
import 'presentation/viewmodels/chat_viewmodel.dart';
import 'presentation/viewmodels/onboarding_viewmodel.dart';

// Repositories
import 'data/repositories/chat_repository.dart';
import 'data/repositories/user_repository.dart';

// Widgets
import 'widgets/common/loading_screen.dart';
import 'widgets/common/error_app.dart';

// App
import 'app/app.dart';
import 'widgets/common/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await _configureSystemUI();
  
  try {
    print('🚀 Initializing Aloulou Application...');
    await _initializeServices();
    runApp(_buildApp());
    print('✅ Aloulou Application started successfully');
  } catch (e, stackTrace) {
    print('❌ Fatal error during app initialization: $e');
    print('📍 Stack trace: $stackTrace');
    runApp(ErrorApp(error: e));
  }
}

/// Configure system UI overlay and status bar
Future<void> _configureSystemUI() async {
  try {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    print('✅ System UI configured successfully');
  } catch (e) {
    print('⚠️ Failed to configure system UI: $e');
  }
}

/// Initialize all required services in proper order
Future<void> _initializeServices() async {
  print('🔧 Initializing core services...');
  
  final stopwatch = Stopwatch()..start();

  try {
    await _initializeHive();
    await _initializeFirebase();
    await _initializeStorage();
    await _initializeAIConfig();

    stopwatch.stop();
    print('✅ All core services initialized successfully in ${stopwatch.elapsedMilliseconds}ms');
  } catch (e) {
    stopwatch.stop();
    print('❌ Service initialization failed after ${stopwatch.elapsedMilliseconds}ms: $e');
    rethrow;
  }
}

/// Initialize Hive local database
Future<void> _initializeHive() async {
  try {
    print('📦 Initializing Hive local database...');
    await Hive.initFlutter();
    print('✅ Hive database initialized successfully');
  } catch (e) {
    print('❌ Critical: Hive initialization failed: $e');
    rethrow;
  }
}

/// Initialize Firebase services
Future<void> _initializeFirebase() async {
  try {
    print('🔥 Initializing Firebase services...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseService.initialize();
    print('✅ Firebase services initialized successfully');
  } catch (e) {
    print('⚠️ Firebase initialization failed: $e');
    print('📱 Continuing in offline mode - some features may be limited');
  }
}

/// Initialize storage service
Future<void> _initializeStorage() async {
  try {
    print('💾 Initializing Storage Service...');
    await StorageService.init();
    print('✅ Storage Service initialized successfully');
  } catch (e) {
    print('❌ Critical: Storage Service initialization failed: $e');
    rethrow;
  }
}

/// Initialize AI configuration service
Future<void> _initializeAIConfig() async {
  try {
    print('🤖 Initializing AI Configuration Service...');
    await AIConfigService.init();
    print('✅ AI Configuration Service initialized successfully');
  } catch (e) {
    print('⚠️ AI Configuration initialization failed: $e');
    print('🔄 Continuing with default AI configuration');
  }
}

Size getDesignSize(double screenWidth) {
  // Extra small phones (very narrow screens)
  if (screenWidth < 320) {
    return const Size(320, 568);
  }
  // Small phones (iPhone SE, older Android phones)
  else if (screenWidth < 375) {
    return const Size(360, 640);
  }
  // Standard small phones (iPhone 12 mini, Pixel 5)
  else if (screenWidth < 400) {
    return const Size(375, 667);
  }
  // Medium phones (iPhone 12/13/14, most Android phones)
  else if (screenWidth < 430) {
    return const Size(414, 896);
  }
  // Large phones (iPhone 12/13/14 Pro Max, large Android phones)
  else if (screenWidth < 480) {
    return const Size(428, 926);
  }
  // Small tablets / Large phones in landscape
  else if (screenWidth < 600) {
    return const Size(480, 854);
  }
  // Medium tablets (iPad mini, small Android tablets)
  else if (screenWidth < 768) {
    return const Size(600, 960);
  }
  // Standard tablets (iPad, most Android tablets)
  else if (screenWidth < 1024) {
    return const Size(768, 1024);
  }
  // Large tablets (iPad Pro 11")
  else if (screenWidth < 1200) {
    return const Size(834, 1194);
  }
  // Extra large tablets (iPad Pro 12.9")
  else if (screenWidth < 1400) {
    return const Size(1024, 1366);
  }
  // Desktop/Web (small desktop screens)
  else if (screenWidth < 1920) {
    return const Size(1366, 768);
  }
  // Large desktop screens
  else {
    return const Size(1920, 1080);
  }
}

/// Build the main app with provider setup
Widget _buildApp() {
  return ScreenUtilInit(
    // Use a default design size - it will be updated in the builder
    designSize: const Size(414, 896),
    
    // Taille minimale du texte (par défaut: pas de limite)
    minTextAdapt: true,
    
    // Permet à l'écran de se diviser pour le mode split
    splitScreenMode: true,
    
    // Le builder qui construit votre app
    builder: (context, child) {
      // Now context is available inside the builder
      final screenWidth = MediaQuery.of(context).size.width;
      
      return ScreenUtilInit(
        designSize: getDesignSize(screenWidth),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MultiProvider(
            providers: [
              // AI Service Manager
              ChangeNotifierProvider<AIServiceManager>(
                create: (context) {
                  print('🤖 Creating AIServiceManager...');
                  return AIServiceManager();
                },
                lazy: false,
              ),

              // Repositories
              Provider<ChatRepository>(
                create: (context) {
                  print('📊 Creating ChatRepository...');
                  final aiServiceManager = context.read<AIServiceManager>();
                  return ChatRepository(aiServiceManager: aiServiceManager);
                },
                lazy: false,
              ),

              Provider<UserRepository>(
                create: (context) {
                  print('👤 Creating UserRepository...');
                  return UserRepository();
                },
                lazy: false,
              ),

              // ViewModels
              ChangeNotifierProvider<AuthViewModel>(
                create: (context) {
                  print('🔐 Creating AuthViewModel...');
                  return AuthViewModel();
                },
                lazy: false,
              ),

              ChangeNotifierProvider<OnboardingViewModel>(
                create: (context) {
                  print('🚀 Creating OnboardingViewModel...');
                  return OnboardingViewModel();
                },
                lazy: false,
              ),

              ChangeNotifierProxyProvider2<ChatRepository, AIServiceManager, ChatViewModel>(
                create: (context) {
                  print('💬 Creating ChatViewModel...');
                  final chatRepository = context.read<ChatRepository>();
                  final userRepository = context.read<UserRepository>();
                  final aiServiceManager = context.read<AIServiceManager>();
                  
                  return ChatViewModel(
                    chatRepository: chatRepository,
                    userRepository: userRepository,
                    aiServiceManager: aiServiceManager,
                  );
                },
                update: (context, chatRepository, aiServiceManager, previous) {
                  print('🔄 Updating ChatViewModel dependencies...');
                  return previous ?? ChatViewModel(
                    chatRepository: chatRepository,
                    userRepository: context.read<UserRepository>(),
                    aiServiceManager: aiServiceManager,
                  );
                },
                lazy: false,
              ),

              ChangeNotifierProxyProvider2<ChatRepository, UserRepository, ChatHistoryViewModel>(
                create: (context) {
                  print('📜 Creating ChatHistoryViewModel...');
                  return ChatHistoryViewModel(
                    chatRepository: context.read<ChatRepository>(),
                    userRepository: context.read<UserRepository>(),
                  );
                },
                update: (_, chatRepo, userRepo, previous) {
                  print('🔄 Updating ChatHistoryViewModel dependencies...');
                  return previous ?? ChatHistoryViewModel(
                    chatRepository: chatRepo,
                    userRepository: userRepo,
                  );
                },
              ),
            ],
            
            child: Consumer<AuthViewModel>(
              builder: (context, authViewModel, child) {
                if (!authViewModel.isInitialized) {
                  return MaterialApp(
                    title: 'Aloulou - Loading',
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.lightTheme,
                    home: const LoadingScreen(),
                  );
                }
                
                return const AloulouApp();
              },
            ),
          );
        },
      );
    },
  );
}