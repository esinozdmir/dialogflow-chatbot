import 'package:chatbotkou/colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserMessagesScreen extends StatelessWidget {
  final String userId;
  final String username;

  UserMessagesScreen({required this.userId, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("$username - Mesajlar"),
        centerTitle: true,
        backgroundColor: AppColors.appBar,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('messages')
            .orderBy('timestamp')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var messages = snapshot.data!.docs;

          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              var messageData = messages[index].data() as Map<String, dynamic>?;

              // Eğer messageData null ise veya beklenen alanlar yoksa varsayılan değerler kullan
              String userResponse = messageData != null && messageData.containsKey('user_response')
                  ? messageData['user_response']
                  : "Yanıt bulunamadı";
              String botResponse = messageData != null && messageData.containsKey('bot_response')
                  ? messageData['bot_response']
                  : "Bot yanıtı bulunamadı";
              String selectedOption = messageData != null && messageData.containsKey('selected_option')
                  ? messageData['selected_option']
                  : "Seçenek bulunamadı";
              String timestamp = messageData != null && messageData.containsKey('timestamp')
                  ? (messageData['timestamp'] as Timestamp).toDate().toString()
                  : "Tarih bulunamadı";
              String sender = messageData != null && messageData.containsKey('sender')
                  ? messageData['sender']
                  : "Kullanıcı bilinmiyor";

              return ListTile(
                title: Text("Kullanıcı: $sender"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Kullanıcı Yanıtı: $userResponse"),
                    Text("Bot Yanıtı: $botResponse"),
                    Text("Seçilen Şık: $selectedOption"),
                    Text("Tarih: $timestamp"),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
