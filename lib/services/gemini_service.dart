import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:lens_fix/utils/api_constants.dart';
import 'dart:typed_data';
import 'dart:io' as io; // Safe import for mobile only checks

class GeminiService {
  /// analyzeIssue now accepts dynamic 'input'. 
  /// Pass String path for mobile, Uint8List for web.
  static Future<Map<String, dynamic>> analyzeIssue(dynamic input) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-flash-latest', 
        apiKey: ApiConstants.geminiApiKey,
      );

      Uint8List imageBytes;

      // WEB SAFE LOGIC: Avoid using 'io.File' on Web
      if (kIsWeb) {
        debugPrint("DEBUG: GeminiService processing bytes for Web");
        imageBytes = input as Uint8List;
      } else {
        debugPrint("DEBUG: GeminiService processing file path for Mobile");
        final imageFile = io.File(input as String);
        if (!await imageFile.exists()) {
          return {'error': "Image file not found."};
        }
        imageBytes = await imageFile.readAsBytes();
      }
      
      final content = [
        Content.multi([
          TextPart(
            "You are an AI maintenance assistant for a college. Analyze this image. "
            "1. Identify the issue. "
            "2. Classify it into exactly ONE of these categories: ['Electrical', 'Plumbing', 'Furniture', 'IT', 'Structural', 'Cleaning', 'Security', 'Other']. "
            "IMPORTANT: Return the response strictly as a RAW JSON object with these keys: "
            "1. 'title' (Short 2-4 word summary) "
            "2. 'severity' (Low, Medium, or High) "
            "3. 'category' (Must be one of the categories listed above) "
            "4. 'description' (A clear 1-sentence explanation) "
            "5. 'fix' (Recommended solution to that problem with regard to the category considering this is a college too so not extraordinary fixes, 1 sentence)"
          ),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await model.generateContent(content);
      final responseText = response.text;

      if (responseText == null) return {'error': "AI returned no text."};

      String cleanJson = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      return jsonDecode(cleanJson);

    } catch (e) {
      debugPrint("❌ GEMINI ERROR: $e");
      return {
        'title': 'Error',
        'severity': 'Unknown',
        'category': 'Other',
        'description': 'Could not analyze image due to a connection error.',
        'fix': 'Please try again.',
        'error': e.toString()
      };
    }
  }
}