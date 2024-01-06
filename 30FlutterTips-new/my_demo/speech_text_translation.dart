// import 'package:flutter/material.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt;
// import 'package:translator/translator.dart';
//
// void main() {
//   runApp(MyApp());
// }
//
// class MyApp extends StatefulWidget {
//   @override
//   _MyAppState createState() => _MyAppState();
// }
//
// class _MyAppState extends State<MyApp> {
//   final stt.SpeechToText _speech = stt.SpeechToText();
//   bool _isListening = false;
//   String _text = '';
//
//   final translator = GoogleTranslator();
//
//   Future<String> translateText(String text, String langCode) async {
//     Translation translation = await translator.translate(text,from: 'en', to: langCode);
//     return translation.text;
//   }
//
//   void _listen() async {
//     if (!_isListening) {
//       bool available = await _speech.initialize(
//           onStatus: (val) => print('onStatus: $val'),
//           onError: (val) => print('onError: $val'));
//       if (available) {
//         setState(() {
//           _isListening = true;
//         });
//         _speech.listen(
//           onResult: (val) async {
//             setState(() {
//               _text = val.recognizedWords;
//             });
//             // String englishText = await translateText(_text, 'en');
//             // String hindiText = await translateText(_text, 'hi');
//             // setState(() {
//             //   _text = hindiText;
//             // });
//           },
//         );
//       }
//     } else {
//       setState(() {
//         _isListening = false;
//         _speech.stop();
//       });
//     }
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           title: Text('Speech to Text and Translation'),
//         ),
//         body: Column(
//           children: [
//             Expanded(
//               child: Container(
//                 padding: EdgeInsets.symmetric(horizontal: 16.0),
//                 child: SingleChildScrollView(
//                   child: TextField(
//                     decoration: InputDecoration(
//                       hintText: _isListening ? "listening" : 'Speak something...',
//                     ),
//                     readOnly: true,
//                     controller: TextEditingController(text: _text),
//                     maxLines: null,
//                     style: TextStyle(fontSize: 24.0),
//                   ),
//                 ),
//               ),
//             ),
//             FloatingActionButton(
//               onPressed: _listen,
//               child: AnimatedContainer(
//                 duration: Duration(milliseconds: 500),
//                 curve: Curves.easeInOut,
//                 child: Icon(
//                   _isListening ? Icons.mic : Icons.mic_none,
//                   size: 36.0,
//                 ),
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: _isListening ? Colors.redAccent : Colors.blue,
//                 ),
//               ),
//             ),
//             // ElevatedButton(
//             //   onPressed: () async {
//             //     String translatedText = await translateText(_text, 'fr');
//             //     setState(() {
//             //       _text = translatedText;
//             //     });
//             //   },
//             //   child: Text('Translate to French'),
//             // ),
//             // ElevatedButton(
//             //   onPressed: () async {
//             //     String translatedText = await translateText(_text, 'es');
//             //     setState(() {
//             //       _text = translatedText;
//             //     });
//             //   },
//             //   child: Text('Translate to Spanish'),
//             // ),
//             ElevatedButton(
//               onPressed: () async {
//                 String translatedText = await translateText(_text, "hi");
//                 setState(() {
//                   _text = translatedText;
//                 });
//               },
//               child: Text('Translate to hindi'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
