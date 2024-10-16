import 'package:chatbotkou/colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int totalResponses = 0;
  int correctAnswers = 0;
  int wrongAnswers = 0;
  List<Map<String, dynamic>> userStatistics = [];
  int totalUsers = 0; // Toplam kullanıcı sayısı

  @override
  void initState() {
    super.initState();
    _fetchStatistics();
  }

  Future<void> _fetchStatistics() async {
    try {
      QuerySnapshot userSnapshots = await FirebaseFirestore.instance.collection('users').get();

      int totalCorrect = 0;
      int totalWrong = 0;
      int totalAnswered = 0;
      int usersCount = userSnapshots.docs.length;

      List<Map<String, dynamic>> stats = [];

      for (var userDoc in userSnapshots.docs) {
        String userId = userDoc.id;
        String username = userDoc['username'] ?? "Bilinmeyen Kullanıcı";

        QuerySnapshot messageSnapshots = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('messages')
            .get();

        int userCorrect = 0;
        int userWrong = 0;

        List<Map<String, dynamic>> userMessages = [];

        for (var messageDoc in messageSnapshots.docs) {
          var messageData = messageDoc.data() as Map<String, dynamic>;

          if (messageData.containsKey('selected_option')) {
            totalAnswered++;
            if (messageData['selected_option'].toLowerCase() == 'doğru') {
              totalCorrect++;
              userCorrect++;
            } else if (messageData['selected_option'].toLowerCase() == 'yanlış') {
              totalWrong++;
              userWrong++;
            }

            // Her mesajı detaylı şekilde ekle
            userMessages.add({
              'question': messageData['user_response'] ?? 'Soru bulunamadı',
              'answer': messageData['bot_response'] ?? 'Cevap bulunamadı',
              'selected_option': messageData['selected_option'],
              'timestamp': (messageData['timestamp'] as Timestamp).toDate(),
            });
          }
        }

        stats.add({
          'username': username,
          'correct': userCorrect,
          'wrong': userWrong,
          'messages': userMessages, // Kullanıcıya ait tüm mesajları ekliyoruz
        });
      }

      setState(() {
        totalResponses = totalAnswered;
        correctAnswers = totalCorrect;
        wrongAnswers = totalWrong;
        userStatistics = stats;
        totalUsers = usersCount;
      });
    } catch (e) {
      print("İstatistikler alınırken hata oluştu: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('İstatistikler'),
        backgroundColor: AppColors.appBar,
        centerTitle: true,
        elevation: 6,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: userStatistics.length,
                itemBuilder: (context, index) {
                  var userStat = userStatistics[index];
                  return _buildUserStatsTile(userStat);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 4,
      color: AppColors.appBar,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Genel İstatistikler",
              style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold, color: AppColors.background),
            ),
            Divider(color: AppColors.background),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _buildStatisticItem("Toplam Kullanıcı", totalUsers.toString(), Icons.people)),
                Expanded(child: _buildStatisticItem("Toplam Cevap", totalResponses.toString(), Icons.question_answer)),
                Expanded(child: _buildStatisticItem("Doğru Cevap", correctAnswers.toString(), Icons.check_circle)),
                Expanded(child: _buildStatisticItem("Yanlış Cevap", wrongAnswers.toString(), Icons.cancel)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: AppColors.background),
        SizedBox(height: 8),
        Text(label,textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.black)),
        SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.background)),
      ],
    );
  }

  Widget _buildUserStatsTile(Map<String, dynamic> userStat) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.appBar,
          child: Text(userStat['username'][0].toUpperCase(), style: TextStyle(color: Colors.white)),
        ),
        title: Text("Kullanıcı: ${userStat['username']}", style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Doğru: ${userStat['correct']} / Yanlış: ${userStat['wrong']}"),
        children: (userStat['messages'] as List).map<Widget>((message) {
          return ListTile(
            title: Text("Soru: ${message['question']}", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 5),
                Text("Cevap: ${message['answer']}"),
                Text("Seçilen Şık: ${message['selected_option']}"),
                Text("Tarih: ${message['timestamp']}"),
              ],
            ),
            trailing: Icon(
              _getIconForSelectedOption(message['selected_option']),
              color: _getIconColorForSelectedOption(message['selected_option']),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MessageDetailScreen(
                    question: message['question'],
                    answer: message['answer'],
                    selectedOption: message['selected_option'],
                    timestamp: message['timestamp'],
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  IconData _getIconForSelectedOption(String selectedOption) {
    if (selectedOption.toLowerCase() == 'doğru') {
      return Icons.check_circle;
    } else if (selectedOption.toLowerCase() == 'yanlış') {
      return Icons.cancel;
    } else {
      return Icons.info_outline; // Bilgi ikonu
    }
  }

  Color _getIconColorForSelectedOption(String selectedOption) {
    if (selectedOption.toLowerCase() == 'doğru') {
      return Colors.green;
    } else if (selectedOption.toLowerCase() == 'yanlış') {
      return Colors.red;
    } else {
      return Colors.blue; // Bilgi ikonu rengi
    }
  }
}

class MessageDetailScreen extends StatelessWidget {
  final String question;
  final String answer;
  final String selectedOption;
  final DateTime timestamp;

  const MessageDetailScreen({
    required this.question,
    required this.answer,
    required this.selectedOption,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mesaj Detayı"),
        backgroundColor: AppColors.appBar,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Soru:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(question, style: TextStyle(fontSize: 16)),
                SizedBox(height: 10),
                Text("Cevap:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(answer, style: TextStyle(fontSize: 16)),
                SizedBox(height: 10),
                Text("Seçilen Şık:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(selectedOption, style: TextStyle(fontSize: 16)),
                SizedBox(height: 10),
                Text("Tarih:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("$timestamp", style: TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
