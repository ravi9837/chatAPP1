import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_30_tips/UI/post_screen/mainscreen.dart';
import 'UI/splash_screen.dart';
import 'firebase_services/splash_services.dart';


void main() async{

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MedOnGo',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const SplashScreen()
      );
  }
}

