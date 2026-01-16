import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lens_fix/services/gemini_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  File? _selectedImage;
  String _analysisResult = "";
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Auto-open camera when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pickImage();
    });
  }

  Future<void> _pickImage() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _selectedImage = File(photo.path);
        _analysisResult = ""; 
      });
    } else {
      // If user cancels camera, go back to home
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() { _isLoading = true; });

    // Call the AI Service
    String result = await GeminiService.analyzeIssue(_selectedImage!.path);

    setState(() {
      _isLoading = false;
      _analysisResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("ISSUE SCANNER", style: TextStyle(letterSpacing: 2)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. THE IMAGE PREVIEW
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF00F0FF), width: 2), // Neon Cyan Border
                borderRadius: BorderRadius.circular(20),
                image: _selectedImage != null 
                    ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                    : null,
              ),
              child: _selectedImage == null 
                  ? const Center(child: Text("Launch Camera...", style: TextStyle(color: Colors.white)))
                  : null,
            ),
          ),

          // 2. THE CONTROLS
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF1E212B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // LOADING STATE
                if (_isLoading) ...[
                  const LinearProgressIndicator(color: Color(0xFF00F0FF)),
                  const SizedBox(height: 10),
                  const Text("AI ANALYSIS IN PROGRESS...", style: TextStyle(color: Color(0xFF00F0FF), letterSpacing: 1.5)),
                  const SizedBox(height: 20),
                ],

                // RESULT CARD (If analysis is done)
                if (_analysisResult.isNotEmpty && !_isLoading)
                  FadeInUp(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        border: Border.all(color: Colors.greenAccent),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _analysisResult,
                        style: const TextStyle(color: Colors.white, height: 1.5, fontFamily: 'Courier'),
                      ),
                    ),
                  ),

                // BUTTONS
                if (!_isLoading)
                  Row(
                    children: [
                      // Retake Button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _pickImage,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text("RETAKE", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Analyze / Submit Button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _analysisResult.isEmpty 
                              ? _analyzeImage 
                              : () { Navigator.pop(context); }, // Submit Action
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _analysisResult.isEmpty ? const Color(0xFF00F0FF) : Colors.greenAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          icon: Icon(_analysisResult.isEmpty ? Icons.analytics : Icons.check),
                          label: Text(
                            _analysisResult.isEmpty ? "ANALYZE ISSUE" : "SUBMIT REPORT",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}