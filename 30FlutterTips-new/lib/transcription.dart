import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';

// void main() => runApp(MaterialApp(
//   home: MyApp(),
// ));

class TranscriptionPage extends StatefulWidget {
  final String GroupID;
  const TranscriptionPage({ Key? key,
     required this.GroupID,
  }) : super(key: key);



  @override
  State<TranscriptionPage> createState() => _TranscriptionPageState();
}

class _TranscriptionPageState extends State<TranscriptionPage> {
  var text = "123";
  String translatedText = '';
  List<DocumentSnapshot> subCollectionDocuments = [];
  CollectionReference messagesCollection = FirebaseFirestore.instance.collection('messages');



  @override
  void initState() {
    super.initState();
    // Add any initialization logic here that needs to be run when the widget is created
  }

  Future<String> convertSpeechToText(String filePath) async {
    const apiKey = "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";
    var url = Uri.https("api.openai.com", "v1/audio/transcriptions");
    var request = http.MultipartRequest('POST', url);
    request.headers.addAll(({"Authorization": "Bearer $apiKey"}));
    request.fields["model"] = "whisper-1";
    request.fields["language"] = "en";
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    // Show circular progress indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    var response = await request.send();
    var newresponse = await http.Response.fromStream(response);
    final responseData = json.decode(newresponse.body);

    // Close progress indicator dialog
    Navigator.of(context).pop();

    String transcribedText = responseData['text'];

    // Add the transcribed text to Firestore
    CollectionReference messagesCollection = FirebaseFirestore.instance.collection('messages');
    messagesCollection.add({
      'text': transcribedText,
      'timestamp': FieldValue.serverTimestamp(),
    });

    return transcribedText;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ChatGPT Flutter"),
      ),
      body: content(),
    );
  }

  Widget content() {
    return Container(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
              child: ElevatedButton(
                onPressed: () async {

                  FilePickerResult? result = await FilePicker.platform.pickFiles();
                  if (result != null) {
                    //call openai's transcription api
                    convertSpeechToText(result.files.single.path!).then((value) {
                      setState(() {
                        text = value;
                      });
                    });
                  }
                },
                child: Text(" Pick File "),
              )),
          SizedBox(
            height: 20,
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: MediaQuery.of(context).size.height / 3,
                  width: MediaQuery.of(context).size.width,
                  color: Colors.grey,
                  child: SingleChildScrollView(
                    child: Text(
                      "Speech to Text : $text",
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                Container(
                  child: ElevatedButton(
                    onPressed: () async {
                      print(widget.GroupID);
                      String translation = await translateText(text);
                      setState(() {
                        translatedText = translation;
                      });
                    },
                    child: Text('press to translate'),
                  ),
                ),
                Container(
                  child: ElevatedButton(
                    onPressed: () async {
                      print(widget.GroupID);
                      DocumentReference groupDocRef = messagesCollection.doc(widget.GroupID);
                      CollectionReference groupSubCollectionRef = groupDocRef.collection(widget.GroupID);
                      QuerySnapshot subCollectionSnapshot = await groupSubCollectionRef.get();
                      subCollectionSnapshot.docs.forEach((doc) {
                        // Access the data for each document using doc.data()

                        print(doc.data());
                      });

                    },
                    child: Text('press'),
                  ),
                ),
                Container(
                  height: MediaQuery.of(context).size.height / 2.5,
                  width: MediaQuery.of(context).size.width,
                  color: Colors.green,
                  child: Center(
                    child: SingleChildScrollView(child: Text(translatedText)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<String> translateText(String text) async {
    final translator = GoogleTranslator();

    try {
      final translation =
      await translator.translate(text, to: 'hi',from:'en');
      return translation.text;
    } catch (e) {
      // handle translation error
      return 'Translation failed';
    }
  }

}

