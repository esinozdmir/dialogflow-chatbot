import 'dart:ui';

import 'package:bubble/bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dialogflow_flutter/dialogflowFlutter.dart';
import 'package:dialogflow_flutter/googleAuth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class ChatBotScreen extends StatefulWidget {
  @override
  _ChatBotScreenState createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final messageInsert = TextEditingController();
  List<Map> messsages = [];
  String userGender = "Kadın"; // Bu değeri veritabanınızdan veya API'den alabilirsiniz.

  stt.SpeechToText speech = stt.SpeechToText();
  bool _isListening = false; // Mikrofonun aktif olup olmadığını kontrol eder
  String _text = ""; // Sesli girdi sonrası metin
  FlutterTts flutterTts = FlutterTts(); // Text-to-Speech motoru

  @override
  void initState() {
    super.initState();
    speech = stt.SpeechToText();
    _fetchUserGender();
  }

  Future<void> _fetchUserGender() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            userGender = userDoc['gender'] ?? "Kadın"; // Varsayılan olarak "Kadın"
          });
        }
      } else {
        print("Kullanıcı oturum açmamış.");
      }
    } catch (e) {
      print("Cinsiyet bilgisi alınırken hata oluştu: $e");
    }
  }

  // Sesli girdi başlatma fonksiyonu
  void _listen() async {
    if (!_isListening) {
      bool available = await speech.initialize(
        onStatus: (val) => print('Durum: $val'),
        onError: (val) => print('Hata: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
            print("Alınan metin: $_text"); // Alınan metni yazdır
            if (val.hasConfidenceRating && val.confidence > 0) {
              messageInsert.text = _text;
              _sendMessage(); // Metni Dialogflow'a gönder
            }
          }),
          localeId: "tr_TR", // Türkçe desteği
          listenFor: Duration(seconds: 10), // Dinleme süresini uzatmak
        );
      }
    } else {
      setState(() {
        _isListening = false;
      });
      speech.stop();
    }
  }

  // Dialogflow'dan yanıt alma fonksiyonu
  void response(String query) async {
    try {
      AuthGoogle authGoogle =
          await AuthGoogle(fileJson: "assets/cred.json").build();
      DialogFlow dialogflow =
          DialogFlow(authGoogle: authGoogle, language: "tr");
      AIResponse aiResponse = await dialogflow.detectIntent(query);

      var messages = aiResponse.getListMessage();
      if (messages != null && messages.isNotEmpty) {
        var firstMessage = messages[0];
        if (firstMessage != null && firstMessage is Map) {
          var text = firstMessage["text"];
          if (text != null && text is Map) {
            var textList = text["text"];
            if (textList != null && textList is List && textList.isNotEmpty) {
              setState(() {
                messsages
                    .insert(0, {"data": 0, "message": textList[0].toString()});
              });
            } else {
              print("Error: Unexpected format for 'text' in response.");
            }
          } else {
            print("Error: 'text' is null or not a Map.");
          }
        } else {
          print("Error: First message is null or not a Map.");
        }
      } else {
        print("Error: No messages received or getListMessage() returned null.");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  void _sendMessage() {
    if (messageInsert.text.isEmpty) {
      print("boş mesaj");
    } else {
      setState(() {
        messsages.insert(0, {"data": 1, "message": messageInsert.text});
      });
      response(messageInsert.text);
      messageInsert.clear();
    }
  }

  // Text-to-Speech fonksiyonu
  void _speak(String text) async {
    await flutterTts.setLanguage("tr-TR"); // Türkçe dil ayarı
    await flutterTts.setPitch(1.0); // Ses tonu ayarı
    await flutterTts.speak(text); // Metni okutma
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 70,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        elevation: 10,
        title: Text("Dialog Flow Chatbot"),
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            Flexible(
              child: ListView.builder(
                reverse: true,
                itemCount: messsages.length,
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () {
                    if (messsages[index]["data"] == 0) {
                      _speak(messsages[index]["message"].toString());
                    }
                  },
                  child: chat(
                      messsages[index]["message"].toString(),
                      messsages[index]["data"]),
                ),
              ),
            ),
            Divider(
              height: 6.0,
            ),
            Container(
              padding: EdgeInsets.only(left: 15.0, right: 15.0, bottom: 20),
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: <Widget>[
                  Flexible(
                    child: TextField(
                      controller: messageInsert,
                      decoration: InputDecoration.collapsed(
                          hintText: "Mesajınızı gönderin",
                          hintStyle: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18.0)),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.mic,
                      size: 30.0,
                    ),
                    onPressed: _listen,
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 4.0),
                    child: IconButton(
                      icon: Icon(
                        Icons.send,
                        size: 30.0,
                      ),
                      onPressed: _sendMessage,
                    ),
                  )
                ],
              ),
            ),
            SizedBox(
              height: 15.0,
            )
          ],
        ),
      ),
    );
  }

  Widget chat(String message, int data) {
    String avatarImage;
    if (data == 0) {
      avatarImage = "assets/bot.png";
    } else {
      // Kullanıcı cinsiyetine göre avatarı belirleme
      avatarImage =
          userGender == "Erkek" ? "assets/menuser.png" : "assets/womanuser.png";
    }

    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Bubble(
        radius: Radius.circular(15.0),
        color: data == 0 ? Colors.blue : Colors.orangeAccent,
        elevation: 0.0,
        alignment: data == 0 ? Alignment.topLeft : Alignment.topRight,
        nip: data == 0 ? BubbleNip.leftBottom : BubbleNip.rightTop,
        child: Padding(
          padding: EdgeInsets.all(2.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CircleAvatar(
                backgroundImage: AssetImage(avatarImage),
              ),
              SizedBox(
                width: 10.0,
              ),
              Flexible(
                child: Text(
                  message,
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
