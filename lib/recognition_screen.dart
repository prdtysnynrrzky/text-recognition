import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_fonts/google_fonts.dart';
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
  bool isError = false;

  @override
  void initState() {
    super.initState();
    textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    _doTextRecognition();
  }

  @override
  void dispose() {
    textRecognizer.close();
    super.dispose();
  }

  Future<void> _doTextRecognition() async {
    try {
      final inputImage = InputImage.fromFile(widget.image);
      final result = await textRecognizer.processImage(inputImage);

      if (mounted) {
        setState(() {
          recognizedText = result.text;
          isProcessing = false;
          isError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isProcessing = false;
          isError = true;
        });
      }
      _showSnackbar("Gagal mengenali teks: $e");
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(fontSize: 14)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  void _copyToClipboard() {
    if (recognizedText.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: recognizedText));
      _showSnackbar("Teks berhasil disalin!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Hasil Pemindaian",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isProcessing
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(widget.image, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 10),
                  isError
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Terjadi kesalahan saat memindai teks!",
                              style: GoogleFonts.poppins(
                                  color: Colors.red, fontSize: 16),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: _doTextRecognition,
                              icon: const Icon(Icons.refresh,
                                  color: Colors.white),
                              label: Text("Coba Lagi",
                                  style: GoogleFonts.poppins()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            ElevatedButton.icon(
                              onPressed: recognizedText.isNotEmpty
                                  ? _copyToClipboard
                                  : null,
                              icon: const Icon(Icons.copy, color: Colors.white),
                              label: Text("Salin Teks",
                                  style: GoogleFonts.poppins()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: recognizedText.isNotEmpty
                                    ? Colors.blueAccent
                                    : Colors.grey,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            recognizedText.isNotEmpty
                                ? Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: SingleChildScrollView(
                                      child: Text(
                                        recognizedText,
                                        style:
                                            GoogleFonts.poppins(fontSize: 16),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      "Teks Tidak Ditemukan!",
                                      style: GoogleFonts.poppins(
                                          color: Colors.red, fontSize: 16),
                                    ),
                                  ),
                          ],
                        ),
                ],
              ),
            ),
    );
  }
}
