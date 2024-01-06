import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_30_tips/tips2/userList.dart';
import 'UI/post_screen/mainscreen.dart';


class UserSearchPage extends StatefulWidget {
  const UserSearchPage({Key? key}) : super(key: key);

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage>
    with WidgetsBindingObserver {
  Map<String, dynamic>? userMap;
  bool isLoading = false;
  final TextEditingController nameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    setStatus("Online");
  }

  void setStatus(String status) async {
    await _firestore.collection('Patient_Data').doc(_auth.currentUser!.uid).update(
        {
          "status": status,
        });
  }

  Future<void> searchUser() async {
    setState(() {
      isLoading = true;
    });

    await FirebaseFirestore.instance
        .collection('Patient_Data')
        .where('name', isEqualTo: nameController.text)
        .get()
        .then((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        setState(() {
          userMap = {
            'name': doc['name'],
            'mobile number': doc['mobile number'],
          };
          isLoading = false;
        });

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => UserList(tips: '4') ,),
        );
      } else {
        setState(() {
          userMap = null;
          isLoading = false;
        });

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PostScreen(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Find the user'),
      ),
      body: Column(
        children: [
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              hintText: 'Enter name',
            ),
          ),
          ElevatedButton(
            onPressed: () => searchUser(),
            child: Text('Search'),
          ),
          if (isLoading) CircularProgressIndicator(),
          if (userMap != null)
            Text('Name: ${userMap!['name']}\nID: ${userMap!['mobile number']}'),
        ],
      ),
    );
  }
}