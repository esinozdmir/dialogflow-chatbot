import 'package:bubble/bubble.dart';
import 'package:chatbotkou/firebase_services.dart';
import 'package:chatbotkou/full_image_screen.dart';
import 'package:chatbotkou/settings_screen.dart';
import 'package:chatbotkou/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dialogflow_flutter/dialogflowFlutter.dart';
import 'package:dialogflow_flutter/googleAuth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatBotScreen extends StatefulWidget {
  @override
  _ChatBotScreenState createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  FirebaseServices services = FirebaseServices();
  final messageInsert = TextEditingController();
  bool isAutoSpeakEnabled = true;
  List<Map<String, dynamic>> messages = []; // Mesajları saklayacağımız liste
  String userGender = "Kadın";

  stt.SpeechToText speech = stt.SpeechToText();
  bool _isListening = false;
  String _text = "";
  FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    speech = stt.SpeechToText();
    _fetchUserGender();
    _sendWelcomeMessage();
    _loadSettings();
  }

  // Sesli okuma ayarını yükleme
  _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isAutoSpeakEnabled = prefs.getBool('isAutoSpeakEnabled') ?? false;
    });
  }

  // İlk hoş geldin mesajı
  void _sendWelcomeMessage() async {
    String welcomeMessage =
        "Merhaba Hoş Geldin.\nBen Biyorobot, biyoloji dersinde sana yardımcı olmak için programlandım. Biyoloji dersinde yapmak istediğin aşağıdakilerden hangisidir.\nEğer doğrudan bir şey öğrenmek istiyorsan lütfen yaz. Ben cevaplayabilirim.";

    // Firestore'a hoş geldin mesajını kaydet
    String? documentId = await _saveMessageToFirestore({
      'message': welcomeMessage,
      'sender': 'bot',
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() {
      messages.insert(0, {"data": 0, "message": welcomeMessage});
      if (isAutoSpeakEnabled) {
        _speak(welcomeMessage);
      }
    });

    if (documentId != null) {
      // Hoş geldin mesajına uygun yanıt almak için Dialogflow'a gönder
      response(welcomeMessage, documentId);
    }
  }

  Future<void> _fetchUserGender() async {
    try {
      if (services.user != null) {
        UserModel user = await services.getUserById(services.user!.uid);
        if (user != null) {
          setState(() {
            userGender = user.gender;
          });
        }
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
            if (val.hasConfidenceRating && val.confidence > 0) {
              messageInsert.text = _text;
              _sendMessage(); // Metni Dialogflow'a gönder
            }
          }),
          localeId: "tr_TR",
          listenFor: Duration(seconds: 10),
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
  // Dialogflow'dan yanıt alma fonksiyonu
  void response(String query, String documentId) async {
    try {
      AuthGoogle authGoogle =
          await AuthGoogle(fileJson: "assets/cred.json").build();
      DialogFlow dialogflow =
          DialogFlow(authGoogle: authGoogle, language: "tr-TR");

      AIResponse aiResponse = await dialogflow.detectIntent(query);

      var messagesFromAI = aiResponse.getListMessage();

      if (messagesFromAI != null && messagesFromAI.isNotEmpty) {
        var firstMessage = messagesFromAI[0];

        if (firstMessage != null && firstMessage is Map) {
          if (firstMessage.containsKey("payload")) {
            var payload = firstMessage["payload"];

            if (payload.containsKey("chatbot-flutter")) {
              var flutterPayload = payload["chatbot-flutter"];

              if (flutterPayload.containsKey("response")) {
                var response = flutterPayload["response"];
                String? messageText =
                    response["text"]; // text opsiyonel olabilir
                    

                // Yeni yapıyı kontrol et
                if (response.containsKey("title") &&
                    response.containsKey("subtitle") &&
                    response.containsKey("image_url")) {
                  // Yeni yapı için title, subtitle, image_url ekleniyor
                  String title = response["title"];
                  String subtitle = response["subtitle"];
                  String imageUrl = response["image_url"];
                  String? messageText = response["text"]; // Text opsiyonel

                  var buttons = response["reply_markup"] != null
                      ? response["reply_markup"]["inline_keyboard"]
                      : null;

                  setState(() {
                    messages.insert(0, {
                      "data": 0,
                      "title": title,
                      "subtitle": subtitle,
                      "image_url": imageUrl,
                      "message": messageText ??
                          "", // Text varsa ekliyoruz, yoksa boş string
                      "buttons": buttons,
                      "documentId": documentId, // documentId ekleniyor
                    });
                  });

                  // Firestore'da aynı documentId'yi güncelleme
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .collection('messages')
                      .doc(documentId)
                      .update({
                    'bot_message': messageText,
                    'buttons': buttons,
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  if (isAutoSpeakEnabled &&
                      messageText != null &&
                      messageText.isNotEmpty) {
                    _speak(messageText);
                  }
                }
                // Eski yapıyı kontrol et
                else if (response.containsKey("reply_markup") &&
                    response["reply_markup"].containsKey("inline_keyboard")) {
                  var inlineKeyboard =
                      response["reply_markup"]["inline_keyboard"];

                  setState(() {
                    messages.insert(0, {
                      "data": 0,
                      "message": messageText ?? "", // Text varsa ekliyoruz
                      "buttons": inlineKeyboard
                    });
                  });

                  if (isAutoSpeakEnabled &&
                      messageText != null &&
                      messageText.isNotEmpty) {
                    _speak(messageText);
                  }
                }
                // Eğer buton yoksa, sadece text mesajı ekle
                else if (messageText != null && messageText.isNotEmpty) {
                  setState(() {
                    messages.insert(0, {
                      "data": 0,
                      "message": messageText,
                      "documentId": documentId, // documentId ekleniyor
                    });
                  });

                  // Firestore'da sadece bot mesajını güncelle
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .collection('messages')
                      .doc(documentId)
                      .update({
                    'bot_message': messageText,
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                }

                if (isAutoSpeakEnabled &&
                    messageText != null &&
                    messageText.isNotEmpty) {
                  _speak(messageText);
                }
              }
            }
          }
        }
      } else {
        print("Error: No messages received or getListMessage() returned null.");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<String?> _saveMessageToFirestore(Map<String, dynamic> messageData) async {
  try {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Mesaj verilerini Firestore'a kaydediyoruz ve document ID alıyoruz
      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('messages')
          .add(messageData); // Map olarak mesaj verilerini gönderiyoruz

      return docRef.id; // documentId döndürüyoruz
    }
  } catch (e) {
    print("Mesaj kaydedilirken hata oluştu: $e");
  }
  return null; // Hata durumunda null döndürüyoruz
}


  Future<String?> _getUserDisplayName(String uid) async {
  try {
    // Firestore'da kullanıcı bilgilerini al
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (userDoc.exists) {
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      return userData?['username']; // 'username' alanını döndür
    }
  } catch (e) {
    print("Kullanıcı adı alınırken hata: $e");
  }
  return "Bilinmeyen Kullanıcı"; // Hata durumunda veya username yoksa bu değeri döndür
}

void _sendMessage() async {
  if (messageInsert.text.isEmpty) {
    print("boş mesaj");
  } else {
    // FirebaseAuth kullanarak mevcut kullanıcıyı al
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Kullanıcı adını Firestore'dan alıyoruz
      String username = await _getUserDisplayName(user.uid) ?? "Bilinmeyen Kullanıcı";

      // Kullanıcının mesajını kaydediyoruz ve mesaj ID'sini alıyoruz
      String userMessage = messageInsert.text;
      _saveMessageToFirestore({
        'user_response': userMessage, // Kullanıcı cevabı
        'bot_response': '', // Bot cevabı daha sonra güncellenecek
        'selected_option': '', // Seçilen şık
        'sender': username, // Kullanıcı adı ekleniyor
        'timestamp': FieldValue.serverTimestamp(),
      }).then((documentId) {
        if (documentId != null) {
          setState(() {
            messages.insert(0, {
              'data': 1,
              'message': userMessage,
              'documentId': documentId,
              'username': username, // UI'de de kullanıcının adı gösterilebilir
            });
          });

          // Botun yanıtını al ve dokümanı güncelle
          response(userMessage, documentId);
          messageInsert.clear();
        }
      });
    }
  }
}



  // Text-to-Speech fonksiyonu
  void _speak(String text) async {
    if (isAutoSpeakEnabled && text.isNotEmpty) {
      await flutterTts.setLanguage("tr-TR");
      await flutterTts.setPitch(1.0);
      await flutterTts.speak(text);
    }
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
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
              // Settings ekranından dönüldükten sonra ayarları yeniden yükle
              _loadSettings();
            },
          ),
        ],
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            Flexible(
              child: ListView.builder(
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  String documentId = messages[index]['documentId'] ?? '';
                  if (messages[index]["buttons"] != null) {
                    return _buildMessageWithButtons(
                        messages[index], documentId);
                  }
                  return GestureDetector(
                    onTap: () {
                      if (messages[index]["data"] == 0) {
                        _speak(messages[index]["message"].toString());
                      }
                    },
                    child: chat(
                      messages[index]["message"].toString(),
                      messages[index]["data"],
                      messages[index]["image"],
                    ),
                  );
                },
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

  Widget _buildMessageWithButtons(
      Map<String, dynamic> message, String documentId) {
    if (message.containsKey("title") &&
        message.containsKey("subtitle") &&
        message.containsKey("image_url")) {
      String title = message["title"];
      String subtitle = message["subtitle"];
      String imageUrl = message["image_url"];
      String? messageText = message["message"]; // text varsa ekleyeceğiz
      var buttons = message["buttons"];

      // Sesli okuma fonksiyonu çağrısı
      if (!message.containsKey('hasBeenSpoken') ||
          message['hasBeenSpoken'] == false) {
        if (isAutoSpeakEnabled) {
          _speak("$title. $subtitle ${messageText ?? ''}");
        }
        message['hasBeenSpoken'] = true;
      }

      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Bubble(
          radius: Radius.circular(10.0),
          color: Colors.blue,
          elevation: 0.0,
          alignment: Alignment.topLeft,
          nip: BubbleNip.leftBottom,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.volume_up, color: Colors.white),
                    onPressed: () {
                      _speak("$title. $subtitle ${messageText ?? ''}");
                    },
                  ),
                ],
              ),
              if (imageUrl != null && imageUrl.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    // Resme tıklanınca FullImageScreen'e yönlendirilir
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullImageScreen(
                          imageUrl: imageUrl,
                          title: title, // Başlık bilgisi
                          subtitle: subtitle, // Alt başlık bilgisi
                          messageText: messageText,
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                        15.0), // Baloncuğun köşelerine uyar
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain, // Resmi baloncuğa tam sığdırır
                      height: MediaQuery.of(context).size.height * 0.3,
                      width: MediaQuery.of(context).size.width * 0.9,
                    ),
                  ),
                ),
              if (imageUrl != null && imageUrl.isNotEmpty) SizedBox(height: 10),
              // Title
              if (title != null && title.isNotEmpty)
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              if (title != null && title.isNotEmpty) SizedBox(height: 5),
              // Subtitle
              if (subtitle != null && subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.white70,
                  ),
                ),
              if (subtitle != null && subtitle.isNotEmpty) SizedBox(height: 10),
              // Text (message varsa gösterilecek)
              if (messageText != null && messageText.isNotEmpty)
                Text(
                  messageText,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              if (messageText != null && messageText.isNotEmpty)
                SizedBox(height: 10),
              // Resim (tam ekran açılacak şekilde GestureDetector ile sarıldı)

              // Buttons (URL açılacak)
              if (buttons != null)
                Wrap(
                  spacing: 8.0, // Butonlar arasındaki yatay boşluk
                  runSpacing: 4.0, // Satırlar arasındaki dikey boşluk
                  children: (buttons as List).map<Widget>((buttonRow) {
                    return Row(
                      mainAxisSize: MainAxisSize.max,
                      children: buttonRow.map<Widget>((button) {
                        return Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: button["callback_data"] == "launch"
                              ? GestureDetector(
                                  onTap: () {
                                    if (button["text"]
                                        .toString()
                                        .startsWith("http")) {
                                      _launchUrl(button["text"]);
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      if (button["text"] != null &&
                                          button["text"].isNotEmpty)
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.78,
                                          child: Text(
                                            button["text"],
                                            style:
                                                TextStyle(color: Colors.white),
                                            maxLines:
                                                2, // Maksimum satır sayısı
                                            overflow: TextOverflow
                                                .ellipsis, // Taşma durumunda "..." ekler
                                          ),
                                        ),
                                      if (button["text"] != null &&
                                          button["text"].isNotEmpty)
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.white,
                                        ),
                                    ],
                                  ),
                                )
                              : ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: 100, // Minimum genişlik
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                            0.85, // Maksimum genişlik
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20.0),
                                      ),
                                    ),
                                    onPressed: () {
                                      _handleButtonPress(
                                          button["callback_data"], documentId);
                                    },
                                    child: Text(
                                      button["text"],
                                      style: TextStyle(color: Colors.black),
                                      textAlign: TextAlign.start,
                                      maxLines: 10, // Maksimum 2 satır
                                      overflow: TextOverflow
                                          .ellipsis, // Uzun metinlerde taşma yerine "..." gösterir
                                    ),
                                  ),
                                ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      );
    }

    // Eski yapı çalışmaya devam eder (Text ve image_url yoksa)
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Bubble(
        radius: Radius.circular(10.0),
        color: Colors.blue,
        elevation: 0.0,
        alignment: Alignment.topLeft,
        nip: BubbleNip.leftBottom,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundImage: AssetImage("assets/bot.png"),
            ),
            SizedBox(width: 10.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message["message"],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10.0),
                  Wrap(
                    children:
                        (message["buttons"] as List).map<Widget>((buttonRow) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: buttonRow.map<Widget>((button) {
                          return Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shadowColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                              ),
                              onPressed: () {
                                _handleButtonPress(
                                    button["callback_data"], documentId);
                              },
                              child: Text(
                                button["text"],
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// URL açma fonksiyonu
  Future<void> _launchUrl(String url) async {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url'; // Default olarak https ekleyin
    }

    final Uri uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  void _handleButtonPress(String callbackData, String documentId) {
  // callbackData'yı küçük harfe çevirerek büyük/küçük harf farkını ortadan kaldırıyoruz
  String normalizedData = callbackData.toLowerCase(); 

  // Eğer callback_data bir cevap (örn: doğru/yanlış) ise mevcut belgeyi güncelle
  if (normalizedData == 'doğru' || normalizedData == 'yanlış'|| normalizedData == 'Doğru' || normalizedData == 'Yanlış') {
    FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('messages')
        .doc(documentId)
        .update({
      'selected_option': callbackData, // Kullanıcının verdiği doğru/yanlış cevabı
      'timestamp': FieldValue.serverTimestamp(),
    }).then((_) {
      setState(() {
        // UI'daki mesajı güncelle
        messages = messages.map((message) {
          if (message['documentId'] == documentId) {
            message['selected_option'] = callbackData; // Doğru/yanlış cevabı UI'da güncelle
          }
          return message;
        }).toList();
      });

      // Doğru/yanlış cevabının ardından bot yanıtını al
      response(callbackData, documentId);
    }).catchError((error) {
      print("Cevap güncellenirken hata oluştu: $error");
    });
  } 
  // Eğer callback_data yeni bir işlem (örn: Soy_2) ise yeni belge oluştur
  else {
    // Yeni belge oluştur
    _saveMessageToFirestore({
      'user_response': '', // Yeni intent ile kullanıcı yanıtı boş kalır
      'bot_response': callbackData, // Yeni işlem/soru bilgisi
      'selected_option': '', // Henüz bir cevap yok
      'sender': 'bot',
      'timestamp': FieldValue.serverTimestamp(),
    }).then((newDocumentId) {
      if (newDocumentId != null) {
        setState(() {
          // Yeni mesajı mesajlar listesine ekle
          messages.insert(0, {
            'data': 0,
            'message': callbackData,
            'documentId': newDocumentId,
          });
        });

        // Yeni intent ile bot yanıtını al ve yeni belge üzerinde işlem yap
        response(callbackData, newDocumentId);
      }
    }).catchError((error) {
      print("Yeni işlem/soru kaydedilirken hata oluştu: $error");
    });
  }
}



  // Mesajların gösterileceği widget
  Widget chat(String message, int data, String? imageUrl) {
    String avatarImage;
    if (data == 0) {
      avatarImage = "assets/bot.png";
    } else {
      avatarImage =
          userGender == "Erkek" ? "assets/menuser.png" : "assets/womanuser.png";
    }

    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            data == 0 ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Bubble(
            radius: Radius.circular(15.0),
            color: data == 0 ? Colors.blue : Colors.orangeAccent,
            elevation: 0.0,
            alignment: data == 0 ? Alignment.topLeft : Alignment.topRight,
            nip: data == 0 ? BubbleNip.leftBottom : BubbleNip.rightTop,
            child: Padding(
              padding: EdgeInsets.all(2.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
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
                      ),
                    ],
                  ),
                  if (imageUrl != null)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                FullImageScreen(imageUrl: imageUrl),
                          ),
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.only(top: 5.0),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.fill,
                          height: MediaQuery.of(context).size.height * 0.2,
                          width: MediaQuery.of(context).size.width * 0.9,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
