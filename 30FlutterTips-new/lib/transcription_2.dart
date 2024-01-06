import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';

class TranscriptionPage2 extends StatefulWidget {
  final String GroupID;
  const TranscriptionPage2({
    Key? key,
    required this.GroupID,
  }) : super(key: key);

  @override
  State<TranscriptionPage2> createState() => _TranscriptionPage2State();
}

class _TranscriptionPage2State extends State<TranscriptionPage2> {
  var text = "123";
  String translatedText = '';
  List<DocumentSnapshot> subCollectionDocuments = [];
  CollectionReference messagesCollection =
  FirebaseFirestore.instance.collection('messages');

  @override
  void initState() {
    super.initState();
  }

  Future<String> convertSpeechToTextFromUrl(String url) async {
    const apiKey = "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";
    var apiUrl = Uri.https("api.openai.com", "v1/audio/transcriptions/url");
    var requestBody = jsonEncode({
      "model": "whisper-1",
      "language": "en",
      "url": url,
    });

    // show circular progress indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      var response = await http.post(apiUrl,
          headers: {"Content-Type": "application/json", "Authorization": "Bearer $apiKey"},
          body: requestBody);
      var responseData = json.decode(response.body);
      String transcribedText = responseData['text'];

      CollectionReference messagesCollection = FirebaseFirestore.instance.collection('messages');
      messagesCollection.add({
        'text': transcribedText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return transcribedText;
    } catch (e) {
      // hide progress indicator
      Navigator.of(context).pop();

      // handle error
      print('Error transcribing audio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error transcribing audio.'),
        ),
      );
      return '';
    } finally {
      // hide progress indicator
      Navigator.of(context).pop();
    }
  }

  Future<String> convertSpeechToTextFromFile(String filePath) async {
    const apiKey = "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";
    var apiUrl = Uri.https("api.openai.com", "v1/audio/transcriptions");
    var request = http.MultipartRequest('POST', apiUrl);
    request.headers.addAll(({"Authorization": "Bearer $apiKey"}));
    request.fields["model"] = "whisper-1";
    request.fields["language"] = "en";
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

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

    Navigator.of(context).pop();

    String transcribedText = responseData['text'];

    CollectionReference messagesCollection =
    FirebaseFirestore.instance.collection('messages');
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
        child: ElevatedButton(child: Text("Transcribe from URL"),
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            TextEditingController urlController =
            TextEditingController();
            return AlertDialog(
              title: Text("Transcribe from URL"),
              content: TextField(
                controller: urlController,
                decoration:
                InputDecoration(hintText: "Enter audio URL here"),
              ),
              actions: [
                ElevatedButton(
                  child: Text("Transcribe"),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    String transcribedText = await convertSpeechToTextFromUrl(
                        urlController.text.trim());
                    setState(() {
                      text = transcribedText;
                    });
                    var translation = GoogleTranslator().translate(
                        transcribedText, to: 'hi');
                    setState(() {
                      translatedText = translation.toString();
                    });
                  },
                ),
                ElevatedButton(
                  child: Text("Cancel"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    ),
    ),
    SizedBox(height: 20),
    Container(
    child: ElevatedButton(
    child: Text("Transcribe from file"),
    onPressed: () async {
    FilePickerResult? result =
    await FilePicker.platform.pickFiles();
    if (result != null) {
    String filePath = result.files.single.path!;
    String transcribedText =
    await convertSpeechToTextFromFile(filePath);
    setState(() {
    text = transcribedText;
    });
    var translation =
    GoogleTranslator().translate(transcribedText, to: 'pt');
    setState(() {
    translatedText = translation.toString();
    });
    }
    },
    ),
    ),
    SizedBox(height: 20),
    Container(
    child: Text(
    text,
    style: TextStyle(fontSize: 20),
    ),
    ),
    SizedBox(height: 20),
    Container(
    child: Text(
    translatedText,
    style: TextStyle(fontSize: 20),
    ),
    ),
        ],
    ),
    );
  }
}
