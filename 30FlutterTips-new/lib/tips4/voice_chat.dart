// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_30_tips/tips3/image.dart';
import 'package:flutter_30_tips/tips4/audioController.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:music_visualizer/music_visualizer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record_mp3/record_mp3.dart';
import '../home.dart';
import '../tips2/chatController.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:translator/translator.dart';
import '../transcription.dart';
import '../transcription_2.dart';
import '../voice_assistant.dart';

class VoiceChat extends StatefulWidget {
  final QueryDocumentSnapshot<Object?> data;
  const VoiceChat({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  _VoiceChatState createState() => _VoiceChatState();
}

class _VoiceChatState extends State<VoiceChat> {
  RecorderController recorderController = RecorderController();
  TextEditingController messageController = TextEditingController();
  TextEditingController textEditingController = TextEditingController();
  TextEditingController textController = TextEditingController();
  var _isListening = false;
  GoogleTranslator translator = GoogleTranslator();
  var transcribedText = 'hiiii';
  var _text;

  var _speechToText = stt.SpeechToText();
  late ChatProvider chatProvider;
  bool temp = false;
  bool audio = false;
  var output;
  int _limit = 20;
  int _limitIncrement = 20;
  List<QueryDocumentSnapshot> listMessage = [];

  final List<Color> colors = [
    Colors.red[900]!,
    Colors.green[900]!,
    Colors.blue[900]!,
    Colors.brown[900]!
  ];

  final List<int> duration_of_wave = [900, 700, 600, 800, 500];


  Stream<QuerySnapshot>? chatMessageStream;
  final ScrollController _scrollController = ScrollController();
  String groupChatId = "";
  bool isShowSticker = false;
  final FocusNode focusNode = FocusNode();
  String currentUserId = "";

  AudioController audioController = Get.put(AudioController());
  AudioPlayer audioPlayer = AudioPlayer();
  String audioURL = "";

  // Future<String> convertSpeechToText(String filePath) async {
  //   const apiKey = "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";
  //   var url = Uri.https("api.openai.com", "v1/audio/transcriptions");
  //   var request = http.MultipartRequest('POST', url);
  //   request.headers.addAll(({"Authorization": "Bearer $apiKey"}));
  //   request.fields["model"] = "whisper-1";
  //   request.fields["language"] = "en";
  //   request.files.add(await http.MultipartFile.fromString('file', filePath));
  //
  //   // Show circular progress indicator
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (BuildContext context) {
  //       return  Center(
  //         child: CircularProgressIndicator(),
  //       );
  //     },
  //   );
  //
  //   var response = await request.send();
  //   var newresponse = await http.Response.fromStream(response);
  //   final responseData = json.decode(newresponse.body);
  //
  //   // Close progress indicator dialog
  //   Navigator.of(context).pop();
  //
  //   return responseData['text'];
  // }



  Future<bool> checkPermission() async {
    if (!await Permission.microphone.isGranted) {
      PermissionStatus status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        return false;
      }
    }
    return true;
  }

  void startRecord() async {
    bool hasPermission = await checkPermission();
    if (hasPermission) {
      recordFilePath = await getFilePath();
      RecordMp3.instance.start(recordFilePath, (type) {
        setState(() {});
      });
    } else {}
    setState(() {});
  }

  void stopRecord() async {
    bool stop = RecordMp3.instance.stop();
    audioController.end.value = DateTime.now();
    audioController.calcDuration();
    var ap = AudioPlayer();
    await ap.play(AssetSource("Notification.mp3"));
    ap.onPlayerComplete.listen((a) {});
    if (stop) {
      audioController.isRecording.value = false;
      audioController.isSending.value = true;
      await uploadAudio();
    }
  }

  int i = 0;

  Future<String> getFilePath() async {
    Directory storageDirectory = await getApplicationDocumentsDirectory();
    String sdPath =
        "${storageDirectory.path}/record${DateTime
        .now()
        .microsecondsSinceEpoch}.acc";
    var d = Directory(sdPath);
    if (!d.existsSync()) {
      d.createSync(recursive: true);
    }
    return "$sdPath/test_${i++}.mp3";
  }

  uploadAudio() async {
    UploadTask uploadTask = chatProvider.uploadAudio(File(recordFilePath),
        "audio/${DateTime
            .now()
            .millisecondsSinceEpoch
            .toString()}");
    try {
      TaskSnapshot snapshot = await uploadTask;
      audioURL = await snapshot.ref.getDownloadURL();
      String strVal = audioURL.toString();
      setState(() {
        audioController.isSending.value = false;
        onSendMessage(strVal, TypeMessage.audio,
            duration: audioController.total);
      });
    } on FirebaseException catch (e) {
      setState(() {
        audioController.isSending.value = false;
      });
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }

  late String recordFilePath;


  void readLocal() async {
    var a = await FirebaseFirestore.instance.collection('Patient_Data').get();
    setState(() {
      currentUserId = widget.data.id == "1236987450"
          ? a.docs[0].id
          : a.docs[1].id;
    });
    String peerId =
    widget.data.id != "1236987450" ? a.docs[0].id : a.docs[1].id;
    if (currentUserId.compareTo(peerId) > 0) {
      groupChatId = '$currentUserId-$peerId';
    } else {
      groupChatId = '$peerId-$currentUserId';
    }
    chatProvider.updateDataFirestore(
      'Patient_Data',
      currentUserId,
      {'chattingwith': peerId},
    );
  }
  void listen() async {
    if (!_isListening) {
      bool available = await _speechToText.initialize(
        debugLogging: true,
        // finalTimeout: Duration(hours: 1),
        onStatus: (status) => print("status"),
        onError: (errorNotification) => print("errorNotification"),
      );

      if (available) {
        setState(() {
          _isListening = true;
        });
        _speechToText.listen(
            listenFor: const Duration(minutes: 10),
            pauseFor: const Duration(seconds: 10),
            onResult: (result) =>
                setState(() {
                  _text = result.recognizedWords;
                  messageController.text = result.recognizedWords;
                  translator.translate(
                      messageController.text, to: "hi", from: "en").then((
                      value) {
                    setState(() {
                      output = value;
                      textEditingController.text = "$value";
                    }
                    );
                  }
                  );
                }
                )
        );
      }
    } else {
      setState(() {
        _isListening = false;
      });
      _speechToText.stop();
    }
  }


  void onSendMessage(String content, int type, {String? duration = ""}) {
    if (content
        .trim()
        .isNotEmpty) {
      messageController.clear();
      chatProvider.sendMessage(
          content, type, groupChatId, currentUserId, widget.data.id.toString(),
          duration: duration!);
      _scrollController.animateTo(0,
          duration: Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      Fluttertoast.showToast(
          msg: 'Nothing to send', backgroundColor: Colors.grey);
    }
  }

  void onSendMessageAgain(String content, int type, {String? duration = ""}) {
    if (content
        .trim()
        .isNotEmpty) {
      textEditingController.clear();
      chatProvider.sendMessage(
          content, type, groupChatId, currentUserId, widget.data.id.toString(),
          duration: duration!);
      _scrollController.animateTo(0,
          duration: Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      Fluttertoast.showToast(
          msg: 'type a message to send', backgroundColor: Colors.grey);
    }
  }

  @override
  void initState() {
    super.initState();
    chatProvider = Get.put(ChatProvider(
        firebaseFirestore: FirebaseFirestore.instance,
        firebaseStorage: FirebaseStorage.instance));
    focusNode.addListener(onFocusChange);
    _scrollController.addListener(_scrollListener);
    readLocal();
    _speechToText = stt.SpeechToText();
    _isListening = false;
  }

  _scrollListener() {
    if (_scrollController.offset >=
        _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange &&
        _limit <= listMessage.length) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  void onFocusChange() {
    if (focusNode.hasFocus) {
      // Hide sticker when keyboard appear
      setState(() {
        isShowSticker = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.data['name']),
        actions: [
          IconButton(
            icon: Icon(Icons.navigate_next),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TranscriptionPage2(GroupID: groupChatId,)),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          Column(
            children: [
              buildListMessage(),
              Obx(
                    () =>
                audioController.isSending.value
                    ? Text(
                  "Uploading Audio...",
                  style: TextStyle(color: Colors.black),
                )
                    : isLoading
                    ? Text(
                  "Uploading Image...",
                  style: TextStyle(color: Colors.black),
                )
                    : buildInput(),
              )
            ],
          ),
          buildLoading()
        ],
      ),
    );
  }

  Widget buildLoading() {
    return Positioned(
      child: audioController.isSending.value
          ? Center(
        child: CircularProgressIndicator(),
      )
          : SizedBox.shrink(),
    );
  }

  _incomingMSG(String a) {
    return Align(
      alignment: (Alignment.topLeft),
      child: Container(
        width: (MediaQuery
            .of(context)
            .size
            .width * 2 / 3),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.only(topRight: Radius.elliptical(12, 12),
              bottomLeft: Radius.elliptical(12, 12),
              bottomRight: Radius.elliptical(12, 12),),
            color: Colors.teal),
        padding: const EdgeInsets.fromLTRB(18, 9, 18, 9),
        child: Text(
          a,
          style: TextStyle(fontSize: 12, color: Colors.black),
        ),
      ),
    );
  }

  File? imageFile;
  bool isLoading = false;
  String imageUrl = "";

  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();
    final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      imageFile = File(pickedFile.path);
      if (imageFile != null) {
        setState(() {
          isLoading = true;
        });
        uploadFile();
      }
    }
  }

  Future uploadFile() async {
    UploadTask uploadTask = chatProvider.uploadFile(imageFile!,
        "image/${DateTime
            .now()
            .millisecondsSinceEpoch
            .toString()}");
    try {
      TaskSnapshot snapshot = await uploadTask;
      imageUrl = await snapshot.ref.getDownloadURL();
      setState(() {
        isLoading = false;
        onSendMessage(imageUrl, TypeMessage.image);
      });
    } on FirebaseException catch (e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }

  Widget buildInput() {
    return Align(
        alignment: Alignment.bottomLeft,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.25),
                    borderRadius: BorderRadius.all(Radius.circular(10))),
                //height: 50,
                child: TextFormField(
                  maxLines: 2,
                  onFieldSubmitted: (value) {
                    onSendMessage(messageController.text, TypeMessage.text);
                  },
                  controller: messageController,
                  // focusNode: focusNode,
                  decoration: InputDecoration(
                      prefixIcon: SizedBox(
                        width: 142,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                            ),
                            GestureDetector(
                              child: Icon(Icons.photo, color: Colors.black),
                              onTap: () {
                                getImage();
                              },
                            ),
                            SizedBox(
                              width: 20,
                            ),
                            GestureDetector(
                              child: Icon(audioController.isRecording.value ==
                                  true ? Icons.mic : Icons.mic_none,
                                  color: Colors.black),
                              onLongPress: () async {
                                var audioPlayer = AudioPlayer();
                                await audioPlayer.play(
                                    AssetSource("Notification.mp3"));
                                audioPlayer.onPlayerComplete.listen((a) {
                                  audioController.start.value = DateTime.now();
                                  startRecord();
                                  // listen();
                                  audioController.isRecording.value = true;
                                });
                              },
                              onLongPressEnd: (details) {
                                stopRecord();
                              },
                            ),
                            SizedBox(
                              width: 20,
                            ),
                            GestureDetector(
                              child: Icon(_isListening ? Icons.hearing : Icons
                                  .hearing_disabled, color: Colors.black),
                              onLongPress: () {
                                listen();
                              },
                            ),
                          ],
                        ),
                      ),
                      suffixIcon: Container(
                        margin: EdgeInsets.symmetric(horizontal: 8),
                        child: GestureDetector(
                          child: Icon(Icons.send, color: Colors.black),
                          onTap: () =>
                              onSendMessage(
                                  messageController.text, TypeMessage.text),
                        ),
                      ),
                      hintText
                          : _isListening ? 'speech' : "Your message...",
                      contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                      hintStyle: TextStyle(
                          color: Color(0xff8A8A8A), fontSize: 15),
                      border: InputBorder.none),
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.25),
                    borderRadius: BorderRadius.all(Radius.circular(10))),
                child: TextField(
                  maxLines: 2,
                  onSubmitted: (value) {
                    onSendMessageAgain(
                        textEditingController.text, TypeMessage.text);
                  },
                  controller: textEditingController,
                  // focusNode: focusNode,
                  decoration: InputDecoration(
                    // labelText: "Translated text",
                      suffixIcon: Container(
                        margin: EdgeInsets.symmetric(horizontal: 8),
                        child: GestureDetector(
                          child: Icon(Icons.send, color: Colors.black),
                          onTap: () =>
                              onSendMessageAgain(
                                  textEditingController.text, TypeMessage.text),
                        ),
                      ),
                      prefixIcon: Container(
                        width: 100,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                            ),
                            GestureDetector(
                              onTap: (){
                                print(groupChatId);
                              },
                              child: Icon(Icons.translate, color: Colors.black),
                            ),
                            SizedBox(
                              width: 20,
                            ),
                            GestureDetector(
                              child: Icon(Icons.back_hand_rounded,
                                  color: Colors.black),
                              onTap: () {
                                Navigator
                                    .push(context,
                                    MaterialPageRoute(builder: (context) =>
                                        VoiceAssistant()));
                              },
                            ),
                          ],
                        ),
                      ),
                      hintText: 'transcribedText',
                      border: InputBorder.none
                  ),
                ),
              ),
            ],
          ),
        )
    );
  }

  _outgoingMSG(String a) {
    return Align(
      alignment: Alignment.topRight,
      child: Expanded(
        child: Container(
          width: (MediaQuery
              .of(context)
              .size
              .width * 2 / 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(topRight: Radius.elliptical(12, 12),
                bottomLeft: Radius.elliptical(12, 12),
                topLeft: Radius.elliptical(12, 12)
            ),
            color: Colors.pink.shade100,
          ),
          padding: const EdgeInsets.fromLTRB(18, 9, 18, 9),
          child: Text(
            a,
            style: TextStyle(fontSize: 14, color: Colors.black),
          ),
        ),
      ),
    );
  }

  Widget buildListMessage() {
    return Flexible(
      child: groupChatId.isNotEmpty
          ? StreamBuilder<QuerySnapshot>(
        stream: chatProvider.getChatStream(groupChatId, _limit),
        builder: (BuildContext context,
            AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasData) {
            listMessage = snapshot.data!.docs;
            if (listMessage.isNotEmpty) {
              return ListView.builder(
                padding: EdgeInsets.fromLTRB(10, 10, 10, 40),
                itemBuilder: (context, index) =>
                    buildItem(index, snapshot.data?.docs[index]),
                itemCount: snapshot.data?.docs.length,
                reverse: true,
                controller: _scrollController,
              );
            } else {
              return Center(
                  child: Text(
                    "No message here yet...",
                    style: TextStyle(color: Colors.black),
                  ));
            }
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      )
          : Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _audio({
    required String message,
    required bool isCurrentUser,
    required int index,
    required String time,
    required String duration,
  }) {
    return Container(
      width: MediaQuery
          .of(context)
          .size
          .width * 0.5,
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.pink.shade100 : mainColor.withOpacity(
            0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              audioController.onPressedPlayButton(index, message);
              // audioController.changeProg();
            },
            onSecondaryTap: () {
              audioPlayer.stop();
              // audioController.completedPercentage.value = 0.0;
            },
            child: Obx(
                  () =>
              (audioController.isRecordPlaying &&
                  audioController.currentId == index)
                  ? Icon(
                Icons.pause,
                color: isCurrentUser ? Colors.black : mainColor,
              )
                  : Icon(
                Icons.play_arrow,
                color: isCurrentUser ? Colors.black : mainColor,
              ),
            ),
          ),
          Obx(() =>
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        audioController.isRecordPlaying &&
                            audioController.currentId == index
                            ? MusicVisualizer(
                            barCount: 30,
                            colors: colors,
                            duration: duration_of_wave)
                            : LinearProgressIndicator(
                          value: 0,
                        ),

                      ]),
                ),
              ),
          ),
          SizedBox(
            width: 10,
          ),
          GestureDetector(
            onTap:  () async {

            },
              child: Icon(Icons.translate)
          )
          // Text(
          //   duration,
          //   style: TextStyle(
          //       fontSize: 12, color: isCurrentUser ? Colors.black : mainColor),
          // ),
        ],
      ),
    );
  }

  Widget buildItem(int index, DocumentSnapshot? document) {
    if (document != null) {
      MessageChat messageChat = MessageChat.fromDocument(document);
      if (messageChat.idFrom == currentUserId) {
        // Right (my message)
        return Container(
          margin: EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Text
              if (messageChat.type == TypeMessage.text)
                _outgoingMSG(messageChat.content),
              // Image
              if (messageChat.type == TypeMessage.image)
                Container(
                  margin: EdgeInsets.only(
                      bottom: isLastMessageRight(index) ? 20 : 10, right: 10),
                  child: ImageContainer(
                    messageChat: messageChat,
                  ),
                ),
              if (messageChat.type == TypeMessage.audio)
                _audio(
                    message: messageChat.content,
                    isCurrentUser: messageChat.idFrom == currentUserId,
                    index: index,
                    time: messageChat.timestamp.toString(),
                    duration: messageChat.duration.toString())
            ],
          ),
        );
      } else {
        // Left (peer message)
        return Container(
          margin: EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: <Widget>[
                  isLastMessageLeft(index)
                      ? Material(
                    borderRadius: BorderRadius.all(
                      Radius.circular(18),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Container(color: mainColor),
                  )
                      : Container(width: 35),
                  if (messageChat.type == TypeMessage.text)
                    _incomingMSG(messageChat.content),
                  if (messageChat.type == TypeMessage.image)
                    ImageContainer(messageChat: messageChat),
                  if (messageChat.type == TypeMessage.audio)
                    _audio(
                        message: messageChat.content,
                        isCurrentUser: messageChat.idFrom == currentUserId,
                        index: index,
                        time: messageChat.timestamp.toString(),
                        duration: messageChat.duration.toString())
                ],
              ),

              // Time
              isLastMessageLeft(index)
                  ? Container(
                margin: EdgeInsets.only(left: 50, top: 5, bottom: 5),
                child: Text(
                  DateFormat('dd MMM kk:mm').format(
                      DateTime.fromMillisecondsSinceEpoch(
                          int.parse(messageChat.timestamp))),
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontStyle: FontStyle.italic),
                ),
              )
                  : SizedBox.shrink()
            ],
          ),
        );
      }
    } else {
      return SizedBox.shrink();
    }
  }

  bool isLastMessageLeft(int index) {
    if ((index > 0 && listMessage[index - 1].get("idFrom") == currentUserId) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  bool isLastMessageRight(int index) {
    if ((index > 0 && listMessage[index - 1].get("idFrom") != currentUserId) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }
}