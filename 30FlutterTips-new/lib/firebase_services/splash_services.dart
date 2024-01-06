import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_30_tips/UI/auth/signup_screen.dart';
import '../UI/auth/login_screen.dart';
import '../UI/post_screen/mainscreen.dart';

class SplashServices{
  final FirebaseAuth auth = FirebaseAuth.instance;

  getCurrentUser(){
    return auth.currentUser;
  }

  void isLogin(BuildContext context) {
    final auth = FirebaseAuth.instance;

    final user = auth.currentUser;

    if (user != null) {
      Timer(const Duration(seconds: 1),
              () =>
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => LoginScreen()))
      );
    }
    else {
      Timer(const Duration(seconds: 2),
              () =>
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => SignUpScreen())));
    }
  }}