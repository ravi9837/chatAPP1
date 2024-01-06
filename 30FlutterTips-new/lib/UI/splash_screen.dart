import 'package:flutter/material.dart';
import '../firebase_services/splash_services.dart';




class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  SplashServices splashScreen = SplashServices();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    splashScreen.isLogin(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox( height: 200,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 10 ),
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/medongo.png'),
                    fit: BoxFit.fill
              )
            ),
          ),
        ),
      ),
    );
  }
}
