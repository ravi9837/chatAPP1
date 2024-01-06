import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_30_tips/chatfetch.dart';

import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import '../../Utils/utils.dart';
import '../../widgets/round_button.dart';
import '../auth/login_screen.dart';



class PostScreen extends StatefulWidget {
  @override
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {


  firebase_storage.FirebaseStorage storage = firebase_storage.FirebaseStorage.instance ;
  final firestore = FirebaseFirestore.instance.collection('patientData');
  final _formKey = GlobalKey<FormState>();
  final auth = FirebaseAuth.instance;

  bool loading = false;
  final ref = FirebaseDatabase.instance.ref('Post');

  final nameController =TextEditingController();
  String genderText = "male";

  //var ageText = TextEditingController();
  var yearController = TextEditingController();
  var monthController = TextEditingController();
  var mobilenumbercontroller = TextEditingController();



  File _image = File('');
  final ImagePicker picker = ImagePicker();

  Future getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Center(child: Text('MedOnGo Profile')),
          backgroundColor: Colors.green,
          actions: [
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Confirm Logout'),
                      content: Text('Are you sure you want to logout?'),
                      actions: <Widget>[
                        TextButton(
                          child: Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: Text('Logout'),
                          onPressed: () {
                            auth.signOut().then((value) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => LoginScreen()));
                            }).onError((error, stackTrace) {
                              Utils().toastMessage(error.toString());
                            });
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              icon: Icon(Icons.logout),
            ),
            const SizedBox(
              width: 10,
            )
          ],
        ),
        body: SingleChildScrollView(
          child: Form(
              key: _formKey,
              child: Column(children: [
                Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: EdgeInsets.only(bottom: 15),
                      ),
                      CircleAvatar(
                        radius: 100,
                        foregroundImage: _image != null
                            ? Image.file(_image!).image
                            : Image.asset('assets/Images/profile.png').image,
                        backgroundColor: Colors.grey.shade200,
                        child: Icon(
                          Icons.person,
                          size: 180,
                          color: Colors.white,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 2),
                        child: Center(
                          child: ElevatedButton(
                            onPressed: () {

                              getImage();

                            },
                            child: Text(
                              'Capture Image',
                              style: TextStyle(
                                fontSize: 20.0,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15),
                            child: TextFormField(
                              controller: nameController,
                              decoration: InputDecoration(
                                hintText: 'Enter your name',
                              ),
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15),
                                  child: TextFormField(
                                    controller: yearController,
                                    decoration: InputDecoration(
                                      hintText: 'Enter age (years)',
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value!.isEmpty) {
                                        return 'Please enter your age in years';
                                      }
                                      if (int.tryParse(value) == null || int.parse(value) < 0) {
                                        return 'Please enter a valid age in years';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15),
                                  child: TextFormField(
                                    controller: monthController,
                                    decoration: InputDecoration(
                                      hintText: 'Enter age (month)',
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value!.isEmpty) {
                                        return 'Please enter your age in month';
                                      }
                                      if (int.tryParse(value) == null || int.parse(value) > 12) {
                                        return 'Please enter a valid age in month';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),

                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                            child: TextFormField(
                              controller: mobilenumbercontroller,
                              decoration: InputDecoration(
                                hintText: 'Enter your Mobile number',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Please enter your mobile number';
                                }
                                if (value.length < 10) {
                                  return 'Please enter a 10-digit mobile number';
                                }
                                return null;
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                RadioListTile(
                                  title: Text(
                                    "Male",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 20.0,
                                    ),
                                  ),
                                  activeColor: Colors.grey.shade600,
                                  selectedTileColor: Colors.grey,
                                  value: "male",
                                  groupValue: genderText,
                                  onChanged: (value) {
                                    setState(() {
                                      genderText = value.toString();
                                    });
                                  },
                                ),
                                RadioListTile(
                                  title: Text(
                                    "Female",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 20.0,
                                    ),
                                  ),
                                  activeColor: Colors.grey.shade600,
                                  selectedTileColor: Colors.grey,
                                  value: "female",
                                  groupValue: genderText,
                                  onChanged: (value) {
                                    setState(() {
                                      genderText = value.toString();
                                    });
                                  },
                                ),
                                RadioListTile(
                                  title: Text(
                                    "Other",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 20.0,
                                    ),
                                  ),
                                  activeColor: Colors.grey.shade600,
                                  selectedTileColor: Colors.grey,
                                  value: "other",
                                  groupValue: genderText,
                                  onChanged: (value) {
                                    setState(() {
                                      genderText = value.toString();
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20),
                                    child: RoundButton(
                                      title: 'Submit',
                                      onTap: () {
                                        loading = true;
                                        firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance.ref('/images/' + DateTime.now().millisecondsSinceEpoch.toString());
                                        firebase_storage.UploadTask uploadTask = ref.putFile(_image!.absolute);

                                        Future.value(uploadTask).then((value) async {
                                          var newUrl = await ref.getDownloadURL();

                                          if (_formKey.currentState!.validate()) {
                                            firestore.doc(mobilenumbercontroller.text.toString()).set({
                                              'gender': genderText.toString(),
                                              'age(month)': monthController.text.toString(),
                                              'age(year)': yearController.text.toString(),
                                              'name': nameController.text.toString(),
                                              'mobile_number' : mobilenumbercontroller.text.toString(),
                                              'id': DateTime.now().millisecondsSinceEpoch.toString(),
                                              'image': newUrl.toString()
                                            }).then((value) {
                                              Utils().toastMessage('Data Added Successfully');
                                              setState(() {
                                                loading = false;
                                              });
                                              Navigator.push(context, MaterialPageRoute(builder: (context) => ChatFetch(mobile:mobilenumbercontroller.text,ageYear:yearController.text,ageMonth:monthController.text,gender:genderText)));
                                            }).onError((error, stackTrace) {
                                              Utils().toastMessage(error.toString());
                                              setState(() {
                                                loading = false;
                                              });
                                            });
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ]
                          ),
                        ],
                      ),
                    ])
              ])),
        ));
  }
}
