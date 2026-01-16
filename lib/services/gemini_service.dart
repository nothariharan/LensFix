import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:lens_fix/utils/api_constants.dart';

class GeminiService {
  static Future<String> analyzeIssue(String imagePath) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-pro',
        apiKey: ApiConstants.geminiApiKey,
      );

      final imageBytes = await File(imagePath).readAsBytes();
      
      // The Prompt: We tell the AI exactly how to behave
      final content = [
        Content.multi([
          TextPart("You are an AI maintenance assistant for a college campus. "
              "Analyze this image. Identify the issue (e.g., Pothole, Broken Light, Garbage). "
              "If it is not a maintenance issue, say 'No Issue Detected'. "
              "Format your response exactly like this:\n"
              "TITLE: [Short 3-word title]\n"
              "SEVERITY: [Low/Medium/High]\n"
              "DESCRIPTION: [1 sentence explanation]\n"
              "FIX: [1 short suggestion]"),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await model.generateContent(content);
      return response.text ?? "Error: AI returned no text.";
      } catch (e) {
    print("CRITICAL GEMINI ERROR: $e"); // Prints to your VS Code Debug Console
    return "Error: $e"; // Shows on the phone screen
  }
  }
}