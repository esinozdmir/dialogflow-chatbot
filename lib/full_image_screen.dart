import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class FullImageScreen extends StatefulWidget {
  final String imageUrl;
  final String? title;
  final String? subtitle;
  final String? messageText;

  FullImageScreen({
    required this.imageUrl,
    this.title,
    this.subtitle,
    this.messageText,
  });

  @override
  _FullImageScreenState createState() => _FullImageScreenState();
}

class _FullImageScreenState extends State<FullImageScreen> {
  bool _showText = true; // Başlangıçta yazılar görünecek

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? ""),
      ),
      body: GestureDetector(
        onTap: () {
          // Resme tıklandığında yazıları göster/gizle
          setState(() {
            _showText = !_showText;
          });
        },
        child: Stack(
          children: [
            Center(
              child: PhotoView(
                imageProvider: NetworkImage(widget.imageUrl),
                backgroundDecoration: BoxDecoration(
                  color: Colors.white,
                ),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
              ),
            ),
            // Eğer _showText true ise, yazılar gösterilecek
            if (_showText)
              Positioned(
                bottom: 20, // Yazıların resmin altında durması için konumlandırma
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.title != null)
                      Text(
                        widget.title!,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black, // Yazı rengi beyaz olacak
                        ),
                      ),
                    if (widget.subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          widget.subtitle!,
                          style: TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    if (widget.messageText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          widget.messageText!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
