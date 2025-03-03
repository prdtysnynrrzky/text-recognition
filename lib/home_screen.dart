import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';

import 'recognition_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  late ImagePicker _imagePicker;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _imagePicker = ImagePicker();
    _checkPermissionsAndInitialize();
  }

  Future<void> _checkPermissionsAndInitialize() async {
    final cameraStatus = await Permission.camera.request();

    if (cameraStatus.isGranted) {
      _initializeCamera();
    } else {
      _showPermissionDialog();
    }
  }

  Future<void> _initializeCamera() async {
    if (_isCameraInitialized) return;

    if (await Permission.camera.isDenied ||
        await Permission.camera.isPermanentlyDenied) {
      _showPermissionDialog();
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception("Tidak ada kamera tersedia");

      _cameraController = CameraController(
        cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
            orElse: () => cameras.first),
        ResolutionPreset.high,
      );

      _initializeControllerFuture = _cameraController!.initialize();

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      _showSnackbar("Kamera tidak tersedia: $e");
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? xFile =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (xFile != null) {
        _navigateToRecognitionScreen(File(xFile.path));
      }
    } catch (e) {
      _showSnackbar("Gagal memilih gambar: $e");
    }
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showSnackbar("Kamera belum siap.");
      return;
    }

    try {
      await _initializeControllerFuture;
      final image = await _cameraController!.takePicture();
      _navigateToRecognitionScreen(File(image.path));
    } catch (e) {
      _showSnackbar("Gagal mengambil gambar: $e");
    }
  }

  void _navigateToRecognitionScreen(File imageFile) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RecognitionScreen(imageFile)),
    );
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

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Izin Diperlukan",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: const Text(
            "Aktifkan izin kamera dan penyimpanan untuk pengalaman terbaik!"),
        actions: [
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text("Buka Pengaturan",
                style: TextStyle(color: Colors.blueAccent)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Tutup", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _cameraController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Scan Teks",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (_cameraController == null) {
                  return Center(
                      child: Text("Kamera tidak tersedia",
                          style: GoogleFonts.poppins()));
                }
                if (snapshot.connectionState == ConnectionState.done) {
                  return CameraPreview(_cameraController!);
                }
                return const Center(
                    child: CircularProgressIndicator(color: Colors.blueAccent));
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: _initializeCamera,
                  icon: const Icon(Icons.refresh,
                      size: 30, color: Colors.blueAccent),
                  tooltip: "Reload Kamera",
                ),
                FloatingActionButton(
                  onPressed: _captureImage,
                  backgroundColor: Colors.blueAccent,
                  child: const Icon(Icons.camera_alt,
                      size: 30, color: Colors.white),
                ),
                IconButton(
                  onPressed: _pickImageFromGallery,
                  icon: const Icon(Icons.image_outlined,
                      size: 30, color: Colors.blueAccent),
                  tooltip: "Pilih dari Galeri",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
