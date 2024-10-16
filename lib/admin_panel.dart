import 'package:chatbotkou/colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_messages_screen.dart'; // Kullanıcı mesajlarını gösterecek ekran

class AdminPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(229, 222, 204, 1),
      appBar: AppBar(
        title: Text(
          "Kullanıcılar",
          style: TextStyle(
            color: Colors.black,
            fontSize: 22, // Yazı tipi boyutu
            fontWeight: FontWeight.bold, // Yazı tipi kalınlığı
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.appBar,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var userData = users[index];
              String userId = userData.id; // Kullanıcının ID'si
              String username = userData['username']; // Kullanıcının ismi

              return ListTile(
                title: Text("Kullanıcı: $username"),
                onTap: () {
                  // Kullanıcıya tıklayınca mesajları göstermek için yönlendir
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserMessagesScreen(
                          userId: userId, username: username),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
