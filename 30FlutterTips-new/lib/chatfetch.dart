import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ChatFetch extends StatefulWidget {
  final String mobile,ageYear,ageMonth,gender;
  const ChatFetch({Key? key ,required this.mobile,required this.ageYear, required this.ageMonth,required this.gender}) : super(key: key);

  @override
  State<ChatFetch> createState() => _ChatFetchState();

}

class _ChatFetchState extends State<ChatFetch> {
  late double age=18;
  List _data = [];
  int currentQuestionIndex = 0;
  Map<String, dynamic> answers = {};
  final TextEditingController controller = TextEditingController();
  int qcount=0;
  final ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    age = double.parse(widget.ageYear) + double.parse(widget.ageMonth) / 12;
    fetchQuestions();
  }
  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> fetchQuestions() async {

    String dataKey;
    if(age>0 && age<1){
      dataKey='neonatal';
    }
    else if(age<19 && age>=1) {
      dataKey = 'kid';
    }
    else if(age>18 && age<=40 && widget.gender=="female"){
      dataKey='fadult';
    }
    else{
      dataKey='madult';
    }
    try {
      // Get a reference to the "questions" node in the database
      final dataKeyRef = FirebaseDatabase.instance.ref().child(dataKey);
      // Listen for changes to the data at the "questions" node
      dataKeyRef.onValue.listen((event) {
        // Extract the data from the event's DataSnapshot
        final dataSnapshot = event.snapshot;
        final data = dataSnapshot.value as List<dynamic>;

        setState(() {
          _data = data;
        });
      });
    } catch (e) {
      Text('Error getting data from Realtime Database: $e');
    }
  }

  Future<void> saveAnswers() async {
    final answersCollection = FirebaseFirestore.instance.collection('patientData').doc(widget.mobile);
    final answersToSave = answers.entries.map((e) => {'question': _data[int.parse(e.key)]['text'], 'answer': e.value}).toList();
    await answersCollection.update({'answers': answersToSave});
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'PATIENT TAB',
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(9.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 10),
                    ListView.builder(
                      controller: _scrollController,
                      shrinkWrap: true,
                      reverse: false,
                      itemCount: answers.length,
                      itemBuilder: (context, index) {
                        final int questionIndex = int.tryParse(answers.keys.elementAt(index)) ?? 0;
                        if (questionIndex < _data.length) {
                          return ListTile(
                            title: Text(_data[questionIndex]['text']),
                            subtitle: Text(answers.values.elementAt(index)),
                            onTap: () {
                              // show dialog to get new answer
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  String newAnswer = ''; // initialize with current answer
                                  return AlertDialog(
                                    title: Text('Edit Answer'),
                                    content: TextField(
                                      onChanged: (value) {
                                        newAnswer = value;
                                      },
                                      decoration: InputDecoration(
                                        labelText: 'Answer',
                                        hintText: 'Enter new answer',
                                        border: OutlineInputBorder(),
                                      ),
                                      controller: TextEditingController(text: answers.values.elementAt(index)),
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        child: Text('Cancel'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                      TextButton(
                                        child: Text('Save'),
                                        onPressed: () {
                                          setState(() {
                                            answers[questionIndex.toString()] = newAnswer;
                                          });
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                    SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(9.0),
            child: Column(
              children: [
                load(currentQuestionIndex, _data, answers),
                SizedBox(height: 20),
                Visibility(
                  visible: _data[currentQuestionIndex]["text"] == "Press on submit button",
                  child: ElevatedButton(
                    onPressed: submitAnswers,
                    child: const Center(child: Text("Submit")),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget load(int x, List data, Map<String, dynamic> answers) {
    if (data.isNotEmpty && x < data.length) {
      bool isLastQuestion = (x == data.length - 1);
      return Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.blueGrey[50],
            ),
            child: Text(
              data[x]["text"],
              style: TextStyle(fontSize: 18),
            ),
          ),
          if (!isLastQuestion && data[x]["options"][0] == 'yes') ...{
            Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.green,
                    ),
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          qcount+=1;
                          answers[x.toString()] = "Yes";
                          currentQuestionIndex = data[x]["branches"]["yes"];
                        });
                      },
                      child: const Text(
                        "Yes",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.red,
                    ),
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          qcount+=1;
                          answers[x.toString()] = "No";
                          currentQuestionIndex = data[x]["branches"]["no"];
                        });
                      },
                      child: const Text(
                        "No",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          } else if (!isLastQuestion) ...{
            Row(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: (text) {
                      setState(() {
                        answers[x.toString()] = text;
                      });
                    },
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      currentQuestionIndex = data[x]["branches"]["yes"];
                      controller.text = '';
                      _scrollToBottom();
                    });
                  },
                  icon: Icon(Icons.send),
                ),
              ],
            ),
          }
        ],
      );
    } else {
      return Container();
    }
  }



  void submitAnswers() async {
    // Check if all questions have been answered
    if (answers.length < qcount) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Incomplete Form'),
            content: const Text('Please answer all questions before submitting.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      return;
    }

    // Get a reference to the 'patientData' collection in Firestore
    final patientDataCollectionRef = FirebaseFirestore.instance.collection('patientData').doc(widget.mobile);

    // Create a new map to store the answers for this questionnaire
    Map<String, dynamic> questionnaireAnswers = {};

    // Iterate over the entries in the 'answers' map and add each question and its answer to the 'questionnaireAnswers' map
    for (final entry in answers.entries) {
      final int questionIndex = int.tryParse(entry.key) ?? 0;
      if (questionIndex < _data.length) {
        questionnaireAnswers[_data[questionIndex]['text']] = entry.value;
      }
    }

    // Create a new document in the 'patientData' collection and set its data to the questionnaire answers
    try {
      await patientDataCollectionRef.update({
        'questionnaireAnswers': questionnaireAnswers,
      });
      print('Data saved successfully.');
    } catch (e) {
      print('Error saving data: $e');
    }

    // Show a success dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Form Submitted'),
          content: const Text('Your form has been submitted.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


}