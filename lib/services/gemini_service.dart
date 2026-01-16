import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:lens_fix/utils/api_constants.dart';

class GeminiService {
  static Future<Map<String, dynamic>> analyzeIssue(String imagePath) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-flash-latest', // Ensure you use a valid model name
        apiKey: ApiConstants.geminiApiKey,
      );

      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        return {'error': "Image file not found."};
      }
      
      final imageBytes = await imageFile.readAsBytes();
      
      final content = [
        Content.multi([
          TextPart(
            "You are an AI maintenance assistant. Analyze this image. "
            "Identify the maintenance or technical issue (e.g., Pothole, Broken Light, Garbage, Graffiti,Wifi Problem). "
            "If the image is unclear or has no issue, return 'No Issue' in the title. "
            "IMPORTANT: Return the response strictly as a RAW JSON object (no markdown, no code blocks) with the following keys: "
            "1. 'title' (Short 2-4 word summary) "
            "2. 'severity' (Low, Medium, or High) "
            "3. 'description' (A clear 1-sentence explanation) "
            "4. 'fix' (Recommended technical solution, 1 sentence)"
          ),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await model.generateContent(content);
      final responseText = response.text;

      if (responseText == null) return {'error': "AI returned no text."};

      // Clean the response in case Gemini adds markdown code blocks (```json ... ```)
      String cleanJson = responseText.replaceAll('```json', '').replaceAll('```', '').trim();

      return jsonDecode(cleanJson);

    } catch (e) {
      print("❌ GEMINI ERROR: $e");
      return {
        'title': 'Error',
        'severity': 'Unknown',
        'description': 'Could not analyze image due to a connection error.',
        'fix': 'Please try again.',
        'error': e.toString()
      };
    }
  }
}