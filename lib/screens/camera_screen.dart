import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lens_fix/services/gemini_service.dart';
import 'package:lens_fix/services/database_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';

class CameraScreen extends StatefulWidget {
  // 1. Accept Escalation Flag
  final bool isEscalation; 
  const CameraScreen({super.key, this.isEscalation = false});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  File? _selectedImage;
  Map<String, dynamic>? _analysisData;
  bool _isLoading = false;
  String _statusMessage = "";
  
  final ImagePicker _picker = ImagePicker();
  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pickImage();
    });
  }

  Future<void> _pickImage() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 30, 
    );
    
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
    
    setState(() { 
      _isLoading = true; 
      _statusMessage = "ANALYZING STRUCTURAL INTEGRITY...";
    });

    try {
      Map<String, dynamic> result = await GeminiService.analyzeIssue(_selectedImage!.path);
      setState(() {
        _analysisData = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("AI Error: $e")));
    }
  }

  void _editReport() {
    if (_analysisData == null) return;
    TextEditingController titleCtrl = TextEditingController(text: _analysisData!['title']);
    TextEditingController descCtrl = TextEditingController(text: _analysisData!['description']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text("Edit Report Details", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Title", labelStyle: TextStyle(color: Colors.grey), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24))),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Description", labelStyle: TextStyle(color: Colors.grey), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24))),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
            TextButton(onPressed: () {
                setState(() {
                  _analysisData!['title'] = titleCtrl.text;
                  _analysisData!['description'] = descCtrl.text;
                });
                Navigator.pop(context);
              }, child: const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
        );
      },
    );
  }

  Future<void> _submitReport() async {
    if (_selectedImage == null || _analysisData == null) return;

    setState(() { _isLoading = true; _statusMessage = "COMPRESSING EVIDENCE..."; });

    try {
      _statusMessage = "ACQUIRING GPS COORDINATES..."; setState(() {});
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception("Location permissions denied");
      }
      
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      _statusMessage = "ENCODING DATA..."; setState(() {});
      String imageBase64 = await _dbService.convertImageToBase64(_selectedImage!);

      _statusMessage = "FINALIZING REPORT..."; setState(() {});
      await _dbService.reportIssue(
        aiData: _analysisData!, 
        imageBase64: imageBase64, 
        position: position,
        isEscalation: widget.isEscalation, // 2. Pass Flag to DB
      );

      if (!mounted) return;
      Navigator.pop(context, true); 

    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent));
    }
  }

  Color _getSeverityColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'high': return Colors.redAccent;
      case 'medium': return Colors.orangeAccent;
      case 'low': return Colors.greenAccent;
      default: return Colors.white; 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        // 3. Change Title based on mode
        title: Text(widget.isEscalation ? "ESCALATION MODE" : "ISSUE SCANNER", style: GoogleFonts.bebasNeue(letterSpacing: 2, fontSize: 24, color: widget.isEscalation ? Colors.orangeAccent : Colors.white)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: widget.isEscalation ? Colors.orangeAccent : Colors.white, width: 1), 
                borderRadius: BorderRadius.circular(20),
                image: _selectedImage != null ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover) : null,
              ),
              child: _selectedImage == null ? const Center(child: Text("Launch Camera...", style: TextStyle(color: Colors.white))) : null,
            ),
          ),
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF111111), 
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLoading) ...[
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 15),
                      Text(_statusMessage, style: const TextStyle(color: Colors.white, letterSpacing: 1.2, fontSize: 12)),
                    ],
                    if (_analysisData != null && !_isLoading)
                      Expanded(
                        child: FadeInUp(
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(), 
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(_analysisData!['title'] ?? "Unknown Issue", style: GoogleFonts.bebasNeue(color: Colors.white, fontSize: 28, letterSpacing: 1)),
                                    ),
                                    IconButton(onPressed: _editReport, icon: const Icon(Icons.edit, color: Colors.white54, size: 20)),
                                  ],
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _getSeverityColor(_analysisData!['severity']).withOpacity(0.1),
                                      border: Border.all(color: _getSeverityColor(_analysisData!['severity'])),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text((_analysisData!['severity'] ?? "INFO").toUpperCase(), style: TextStyle(color: _getSeverityColor(_analysisData!['severity']), fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                Text("OBSERVATION:", style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 5),
                                Text(_analysisData!['description'] ?? "No description available.", style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.build_circle_outlined, color: Colors.white, size: 30),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text("RECOMMENDED FIX:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                                            const SizedBox(height: 4),
                                            Text(_analysisData!['fix'] ?? "No fix suggested.", style: const TextStyle(color: Colors.grey, fontSize: 13)),
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
                    
                    const SizedBox(height: 15), 

                    if (!_isLoading)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _pickImage,
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: const Text("RETAKE", style: TextStyle(color: Colors.white)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: _analysisData == null ? _analyzeImage : _submitReport,
                              style: ElevatedButton.styleFrom(backgroundColor: widget.isEscalation ? Colors.orangeAccent : Colors.white, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              icon: Icon(_analysisData == null ? Icons.analytics : Icons.cloud_upload, color: Colors.black),
                              label: Text(_analysisData == null ? "ANALYZE ISSUE" : (widget.isEscalation ? "ESCALATE REPORT" : "SUBMIT REPORT"), style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}