import 'package:flutter/material.dart';
import 'package:getsocio/auth/logic/auth_provider.dart';
import 'package:getsocio/core/nav/main_router.dart';
import 'package:getsocio/core/sychro/sync_provider.dart';
import 'package:getsocio/home/music_lib/lib_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth/logic/username_provider.dart';
import 'firebase_options.dart';
import 'home/music_lib/player_provider.dart';
void main() async{
 
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.getsocio.music.channel.audio',
    androidNotificationChannelName: 'Music Playback',
    androidNotificationOngoing: true,
    androidNotificationIcon: 'mipmap/ic_launcher',
  );
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp (MultiProvider(providers: [
    ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
    ChangeNotifierProvider<UsernameProvider>(create: (_) => UsernameProvider()),
    ChangeNotifierProvider<LibProvider>(create: (_)=> LibProvider()),
    ChangeNotifierProvider<PlayerProvider>(create: (_) => PlayerProvider()),
    ChangeNotifierProxyProvider<PlayerProvider, SyncProvider>(
      create: (_) => SyncProvider(),
      update: (_, player, sync) => sync!..attachPlayer(player),
    ),
    ],
    child: AppRoot(),));
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late GoRouter router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context);
    router = createRouter(authProvider); // reactive router
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme:ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0D0D0D),
          canvasColor: const Color(0xFF0D0D0D)),
      routerConfig: router,
    );
  }
}
