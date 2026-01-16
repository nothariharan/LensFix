import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:lens_fix/utils/api_constants.dart';

class GeminiService {
  static Future<String> analyzeIssue(String imagePath) async {
    try {
      // We are using the EXACT name from your list
      final model = GenerativeModel(
        model: 'gemini-flash-latest', 
        apiKey: ApiConstants.geminiApiKey,
      );

      final imageFile = File(imagePath);
      if (!await imageFile.exists()) return "Error: Image file not found.";
      
      final imageBytes = await imageFile.readAsBytes();
      
      final content = [
        Content.multi([
          TextPart("You are an AI maintenance assistant. Analyze this image. "
              "Identify the issue (e.g., Pothole, Broken Light, Garbage). "
              "If no issue, say 'No Issue'. "
              "Format: TITLE: [3 words] - SEVERITY: [Low/High] - FIX: [1 sentence]"),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await model.generateContent(content);
      return response.text ?? "Error: AI returned no text.";
    } catch (e) {
      print("❌ GEMINI ERROR: $e");
      return "Error: $e";
    }
  }
}