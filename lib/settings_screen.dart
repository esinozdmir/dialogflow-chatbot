import 'package:chatbotkou/firebase_services.dart';
import 'package:chatbotkou/main.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  FirebaseServices services = FirebaseServices();
  bool isAutoSpeakEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Ayarları yüklemek için
  _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isAutoSpeakEnabled = prefs.getBool('isAutoSpeakEnabled') ?? false;
    });
  }

  // Ayarları kaydetmek için
  _saveSettings(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isAutoSpeakEnabled', value);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSettings(); // Ekrana geri döndüğünde ayarları güncelle
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ayarlar"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: Text("Sesli Okuma Otomatik"),
              value: isAutoSpeakEnabled,
              onChanged: (bool value) {
                setState(() {
                  isAutoSpeakEnabled = value;
                  _saveSettings(value);
                });
              },
            ),
            ElevatedButton(
                onPressed: () {

                  services.auth.signOut();
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                      (Route<dynamic> route) => false);
                },
                child: Text("Çıkış Yap"))
          ],
        ),
      ),
    );
  }
}
