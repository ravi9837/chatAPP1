import 'dart:io';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'api_services.dart';
import 'chat_modal.dart';


class VoiceAssistant extends StatefulWidget {
  const VoiceAssistant({Key? key}) : super(key: key);

  @override
  State<VoiceAssistant> createState() => _VoiceAssistantState();
}

class _VoiceAssistantState extends State<VoiceAssistant> {
  FlutterSound flutterSound = new FlutterSound();
  FlutterTts flutterTts = FlutterTts();
  var _speechToText = stt.SpeechToText();
  var text = "Hello ☺ 👋 ";
  var isListening = false;

  final List<ChatMessage> messages = [];
  var scrollController = ScrollController();

  scrollMethod(){
    scrollController.animateTo(scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut);
  }

  void listen() async{
    if(!isListening){
      bool available = await _speechToText.initialize(
        onStatus: (status) => print("status"),
        onError: (errorNotification) => print("errorNotification"),
      );
      if(available){
        setState(() {
          isListening =true;
        });
        _speechToText.listen(
          onResult: (result) => setState(() {
            text = result.recognizedWords;
          }),
          listenFor: const Duration(seconds: 60),
          pauseFor: const Duration(seconds: 5),
        );
      }
    }else{
      setState(() {
        isListening = false;
      });
      await _speechToText.stop();
      if(text.isNotEmpty && text != "") {
        messages.add(ChatMessage(text: text, type: ChatMessageType.user));
        var msg = await ApiServices.sendMessage(text);
        setState(() {
          messages.add(ChatMessage(text: msg, type: ChatMessageType.bot ));
        });
       flutterTts.speak("$msg");
      }else{
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Faild to process , Try again...")));
      }
    }
  }
  final recorder = FlutterSoundRecorder();

  Future initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw 'Permission not granted';
    }
    await recorder.openRecorder();
    recorder.setSubscriptionDuration(const Duration(milliseconds: 500));
  }

  Future startRecord() async {
    await recorder.startRecorder(toFile: "audio");
  }

  Future stopRecorder() async {
    final filePath = await recorder.stopRecorder();
    final file= File(filePath!);
    print('Recorded file path: $filePath');
  }

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    initRecorder();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink.shade100,
        title: const Text("Nurse Patient Voice Assistant",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 10),
            child: Column(
              children: [
                Text(text,
                  style: TextStyle(fontSize: 24, color: isListening
                      ? Colors.green : Colors.black87,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16 , vertical: 12),
                    decoration: BoxDecoration(
                        color: Colors.teal.shade100,
                        borderRadius : BorderRadius.circular(12),
                    ),
                    child: ListView.builder(
                        physics:  const BouncingScrollPhysics(),
                        controller: scrollController,
                        shrinkWrap: true,
                        itemCount :messages.length,
                        itemBuilder: (BuildContext context , int index) {
                          var chat = messages[index];
                          return chatBubble( chattext: chat.text, type: chat.type);
                        }),
                  )
                )
              ]
            )
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton:
        AvatarGlow(
        endRadius: 75.0,
        animate: isListening,
        duration: const Duration(milliseconds: 1000),
        glowColor: Colors.orange,
        repeat: true,
        repeatPauseDuration: const Duration(milliseconds: 50),
        showTwoGlows: true,
        child: Row(
          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: GestureDetector(
                child: FloatingActionButton(
                  onPressed: () {
                    listen();
                  },
                  child: Icon(isListening? Icons.mic : Icons.mic_none),
                ),
              ),
            ),
        FloatingActionButton(
          onPressed: () {
            startRecord();
          },
          child: Icon(Icons.record_voice_over),
        ),
            FloatingActionButton(
              onPressed: () {
                stopRecorder();
              },
              child: const Text('🤫',style: TextStyle(fontSize: 40),),
            )
          ],
        )
        )
      );
  }
  Widget chatBubble({required chattext, required ChatMessageType? type}) {
  return Row(
    children: [
       CircleAvatar(
        backgroundColor: Colors.deepPurple,
        child: type == ChatMessageType.bot
            ? Image.asset("assets/nurse.webp")
            :Image.asset("assets/27.png"),
      ),
      const SizedBox(width: 12),
      Expanded(child: Container(
        padding: const EdgeInsets.all(12),
        margin : const EdgeInsets.only(bottom: 12),
        decoration:  BoxDecoration(
          color: type == ChatMessageType.bot ? Colors.pink.shade100: Colors.teal.shade300,
          borderRadius:const BorderRadius.only(
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
            bottomLeft: Radius.circular(12)
          )
        ),
        child: Text(
          "$chattext",
          style:  TextStyle(
            color: Colors.black,
            fontWeight: type == ChatMessageType.bot ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
    ),
    ]
    );
  }
}


