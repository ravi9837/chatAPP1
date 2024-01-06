import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_30_tips/UI/auth/login_screen.dart';
import '../../widgets/round_button.dart';


class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool loading = false ;
  bool _showPassword1 = false;
  bool _showPassword2 = false;
  final _formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final  _auth = FirebaseAuth.instance;

  bool isValidEmail(String email) {
    final pattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
    final regExp = RegExp(pattern);
    return regExp.hasMatch(email);
  }

  @override
  void dispose() {
    super.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
  }

  void togglePasswordVisibility() {
    setState(() {
      _showPassword1 = !_showPassword1;
    });
  }void togglePasswordVisibility2() {
    setState(() {
      _showPassword2 = !_showPassword2;
    });
  }

  void signUp() async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      print('User registered: ${userCredential.user}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Congratulations! Your account has been created successfully.'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        // Handle weak password error
      } else if (e.code == 'email-already-in-use') {
        // Handle email already in use error
      }
    } catch (e) {
      print(e);
    }
    setState(() {
      loading = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('MedOnGo Pvt Ltd.'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Form(
                key: _formKey,
                child: Column(
                  children: [
                      TextFormField(
                        keyboardType: TextInputType.text,
                        controller: usernameController,
                        decoration: const InputDecoration(
                          hintText: 'Username',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Enter username';
                          }
                          return null;
                        },
                      ),
                    const SizedBox(height: 10),
                    TextFormField(
                      keyboardType: TextInputType.emailAddress,
                      controller: emailController,
                      decoration: const  InputDecoration(
                          hintText: 'Email',
                          prefixIcon: Icon(Icons.alternate_email)
                      ),
                      validator: (value){
                        if(value!.isEmpty){
                          return 'Enter email';
                        } else if (!isValidEmail(value)) {
                          return 'Invalid email address';
                        }
                        return null ;
                      },
                    ),
                     SizedBox(height: 10,),
                    TextFormField(
                      keyboardType: TextInputType.text,
                      controller: passwordController,
                      obscureText: !_showPassword1,
                      decoration: InputDecoration(
                          hintText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon: IconButton(
                                icon: Icon(_showPassword1 ? Icons.visibility_off : Icons.visibility),
                                onPressed: togglePasswordVisibility,
                                ),
                              ),
                      validator: (value){
                        if(value!.isEmpty){
                          return 'Enter password';
                        }
                        return null ;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      keyboardType: TextInputType.text,
                      controller: confirmPasswordController,
                      obscureText: !_showPassword2,
                      decoration:  InputDecoration(
                        hintText: 'Confirm Password',
                        prefixIcon: Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_showPassword2 ? Icons.visibility_off : Icons.visibility),
                          onPressed: togglePasswordVisibility2,
                        ),
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Confirm password';
                        } else if (value != passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),

                  ],
                )
            ),
            const SizedBox(height: 50,),
            RoundButton(
              title: 'Sign up',
              loading: loading ,
              onTap: (){
                if(_formKey.currentState!.validate()){
                  signUp();
                }
              },
            ),
            const SizedBox(height: 30,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Already have an account?"),
                TextButton(onPressed: (){
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder:(context) => LoginScreen())
                  );
                },
                    child: Text('Login'))
              ],
            )
          ],
        ),
      ),
    );
  }
}
