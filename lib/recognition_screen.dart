import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/services.dart';

class RecognitionScreen extends StatefulWidget {
  final File image;
  const RecognitionScreen(this.image, {super.key});

  @override
  State<RecognitionScreen> createState() => _RecognitionScreenState();
}

class _RecognitionScreenState extends State<RecognitionScreen> {
  late TextRecognizer textRecognizer;
  String recognizedText = '';
  bool isProcessing = true;

  @override
  void initState() {
    super.initState();
    textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    doTextRecognition();
  }

  @override
  void dispose() {
    textRecognizer.close();
    super.dispose();
  }

  doTextRecognition() async {
    try {
      final InputImage inputImage = InputImage.fromFile(widget.image);
      final RecognizedText result =
          await textRecognizer.processImage(inputImage);

      setState(() {
        recognizedText = result.text;
        isProcessing = false;
      });
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengenali teks!')),
      );
      setState(() {
        isProcessing = false;
      });
    }
  }

  void copyToClipboard() {
    Clipboard.setData(ClipboardData(text: recognizedText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Teks berhasil disalin ke clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Result',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  widget.image,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              isProcessing
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 50,
                              height: 50,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blueAccent),
                                strokeWidth: 5,
                              ),
                            ),
                            SizedBox(height: 24),
                            Text(
                              'Mengidentifikasi Text...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : recognizedText.isNotEmpty
                      ? Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.white,
                                    blurRadius: 1,
                                  )
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hasil:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white.withOpacity(0.4),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SelectableText(
                                      recognizedText,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        height: 1.5,
                                      ),
                                      textAlign: TextAlign.justify,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 0,
                              child: ElevatedButton(
                                onPressed: copyToClipboard,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Icon(Icons.copy, size: 20),
                              ),
                            ),
                          ],
                        )
                      : const Center(
                          child: Text(
                            'Teks tidak ditemukan!',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
            ],
          ),
        ),
      ),
    );
  }
}
