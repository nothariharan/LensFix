import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lens_fix/services/gemini_service.dart';
import 'package:google_fonts/google_fonts.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  File? _selectedImage;
  Map<String, dynamic>? _analysisData;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pickImage();
    });
  }

  Future<void> _pickImage() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _selectedImage = File(photo.path);
        _analysisData = null; 
      });
    } else {
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;
    setState(() { _isLoading = true; });
    Map<String, dynamic> result = await GeminiService.analyzeIssue(_selectedImage!.path);
    setState(() {
      _isLoading = false;
      _analysisData = result;
    });
  }

  Color _getSeverityColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'high': return Colors.redAccent;
      case 'medium': return Colors.orangeAccent;
      case 'low': return Colors.greenAccent;
      default: return Colors.white; // Default to white in mono theme
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // NOIR THEME: Pure Black
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text("ISSUE SCANNER", style: GoogleFonts.bebasNeue(letterSpacing: 2, fontSize: 24, color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 1. THE IMAGE PREVIEW
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 1), // NOIR THEME: Thin White Border
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

          // 2. THE CONTROLS & RESULTS
          Expanded(
            flex: _analysisData != null ? 5 : 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF111111), // NOIR THEME: Matte Dark Grey Surface
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // LOADING STATE
                  if (_isLoading) ...[
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 15),
                    const Text("ANALYZING STRUCTURAL INTEGRITY...", 
                      style: TextStyle(color: Colors.white, letterSpacing: 1.2, fontSize: 12)),
                  ],

                  // RESULT CARD
                  if (_analysisData != null && !_isLoading)
                    Expanded(
                      child: FadeInUp(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _analysisData!['title'] ?? "Unknown Issue",
                                      style: GoogleFonts.bebasNeue(color: Colors.white, fontSize: 28, letterSpacing: 1),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      // Keep Severity Colors as they are functional alerts
                                      color: _getSeverityColor(_analysisData!['severity']).withOpacity(0.1),
                                      border: Border.all(color: _getSeverityColor(_analysisData!['severity'])),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      (_analysisData!['severity'] ?? "INFO").toUpperCase(),
                                      style: TextStyle(
                                        color: _getSeverityColor(_analysisData!['severity']),
                                        fontWeight: FontWeight.bold, fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              
                              Text("OBSERVATION:", style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 5),
                              Text(
                                _analysisData!['description'] ?? "No description available.",
                                style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                              ),

                              const SizedBox(height: 20),

                              // Fix Card - Monochrome Style
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.build_circle_outlined, color: Colors.white, size: 30),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text("RECOMMENDED FIX:", 
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                                          const SizedBox(height: 4),
                                          Text(
                                            _analysisData!['fix'] ?? "No fix suggested.",
                                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const Spacer(),

                  // BUTTONS
                  if (!_isLoading)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _pickImage,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("RETAKE", style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _analysisData == null 
                                ? _analyzeImage 
                                : () { Navigator.pop(context, _analysisData); },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white, // NOIR THEME: White Button
                              foregroundColor: Colors.black, // Black Text
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: Icon(_analysisData == null ? Icons.analytics : Icons.check, color: Colors.black),
                            label: Text(
                              _analysisData == null ? "ANALYZE ISSUE" : "SUBMIT REPORT",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
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