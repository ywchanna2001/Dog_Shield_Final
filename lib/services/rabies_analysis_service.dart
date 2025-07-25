import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:image_picker/image_picker.dart';

// A data class to hold the structured response from Gemini
class AnalysisResult {
  final String riskLevel;
  final String explanation;
  final List<String> observedSigns;

  AnalysisResult({required this.riskLevel, required this.explanation, required this.observedSigns});

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      riskLevel: json['risk_level'] ?? 'Unknown',
      explanation: json['explanation'] ?? 'No explanation provided.',
      observedSigns: List<String>.from(json['observed_signs'] ?? []),
    );
  }
}

class RabiesAnalysisService {
  // Initialize the Gemini 2.5 Flash model, which supports video input
  final model = FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash');

  // The detailed prompt you created
  static const String _prompt = """
    
**Role:** You are an expert AI assistant for analyzing animal behavior from video. Your purpose is to identify behaviors that are potential indicators of serious neurological conditions, like rabies, in dogs. You must base your analysis *only* on the visual information in the video. You are a tool for preliminary risk assessment, not a veterinarian, and cannot provide a diagnosis.

**Core Directive:** Adopt a **precautionary principle**. If a behavior is ambiguous but could potentially be a serious neurological sign, it should elevate the risk assessment rather than be dismissed as benign. The safety of humans and other animals is the top priority.

**Task:** Analyze the provided video clip of a dog. Follow the analytical process below to identify potential rabies symptoms, assess a risk level, and generate a JSON output.

**Analytical Process:**
1.  **Observation Log:** First, internally log all notable behaviors, actions, movements, and the dog's general state.
2.  **Symptom Matching:** Compare your log against the list of potential signs. Pay special attention to the **"Red Flag"** signs.
3.  **Risk Synthesis:** Use the refined Risk Level definitions below to determine the final risk level. The presence of even one clear "Red Flag" sign should automatically trigger a "High" risk assessment.

**Potential Signs to Identify (Symptom List):**

*   **Red Flag Signs (High-Impact Indicators):**
    *   Seizures
    *   Significant paralysis, ataxia (severe stumbling, loss of coordination), or inability to stand
    *   Unprovoked, directionless aggression towards inanimate objects or self
    *   Facial paralysis (one side of the face drooping, inability to blink)
    *   Jaw dropping (jaw hanging open limply)
    *   Obvious difficulty swallowing (dysphagia), often visible with hypersalivation

*   **Other Significant Signs (Medium-to-High Impact):**
    *   Excessive drooling or foaming at the mouth (hypersalivation)
    *   Strange, unusual vocalizations (not normal barking/whining)
    *   Extreme restlessness, agitation, or incessant pacing
    *   Disorientation, confusion, or vacant staring ("zombie-like" appearance)
    *   Self-mutilation (biting or chewing at its own body)
    *   Hydrophobia (fear of water - may manifest as panic or aggression when near water)

**Refined Risk Level Definitions:**
*   **Low Risk:** The dog displays no observable signs from the symptom list. Behavior appears normal, context-appropriate (e.g., playful, resting), and neurologically sound.
*   **Medium Risk:** One or more "Other Significant Signs" are observed, but they are either isolated, mild, or somewhat ambiguous. The behavior is clearly abnormal but does not include a definitive "Red Flag" sign. For example, mild agitation or minor stumbling that warrants serious caution.
*   **High Risk:** The dog exhibits **one or more "Red Flag" signs** with moderate to high confidence, OR it displays a **clear combination of multiple "Other Significant Signs"** (e.g., disorientation plus hypersalivation plus strange vocalizations).

**Mandatory Disclaimer:** Your explanation must ALWAYS conclude with the following text, verbatim: "Disclaimer: This analysis is based solely on the provided video and is NOT a veterinary diagnosis. Rabies is a fatal disease. If you have any concerns about this animal's health or behavior, it is critical to contact a qualified veterinarian or local animal control immediately and avoid all contact with the animal."

---
**VERY IMPORTANT OUTPUT INSTRUCTION:**
Your entire response **MUST** be a single, valid JSON object and nothing else. Do not include conversational text, explanations, or markdown fences (like ```json) before or after the JSON object.

**JSON Object Structure:**
{
  "risk_level": "(String: 'Low', 'Medium', or 'High')",
  "explanation": "(String: Your detailed explanation of the observed behaviors that led to the risk assessment, ending with the mandatory disclaimer)",
  "observed_signs": "(List of Strings: Specific signs observed from the symptom list, e.g., ['Seizures', 'Hypersalivation'])"
} """;

  Future<AnalysisResult> analyzeVideo(XFile videoFile) async {
    try {
      final Uint8List videoBytes = await videoFile.readAsBytes();
      final String mimeType = videoFile.mimeType ?? 'video/mp4';
      final videoPart = InlineDataPart(mimeType, videoBytes);

      final response = await model.generateContent([
        Content.multi([videoPart, TextPart(_prompt)]),
      ]);

      String? responseText = response.text;

      // ************ ADD THIS LINE TO PRINT THE RAW RESPONSE ************
      print('--- Raw Gemini Response Text Start ---');
      print(responseText);
      print('--- Raw Gemini Response Text End ---');
      // ****************************************************************

      if (responseText == null || responseText.isEmpty) {
        throw Exception('Gemini returned an empty response.');
      }

      RegExp jsonRegex = RegExp(r'```json\s*(\{.*\})\s*```|```\s*(\{.*\})\s*```', dotAll: true);
      Match? match = jsonRegex.firstMatch(responseText);

      String? jsonString;
      if (match != null) {
        jsonString = match.group(1) ?? match.group(2);
      } else {
        jsonString = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      }

      if (jsonString == null || jsonString.isEmpty) {
        throw Exception('Could not extract JSON from Gemini response: $responseText');
      }

      int jsonStartIndex = jsonString.indexOf('{');
      int jsonEndIndex = jsonString.lastIndexOf('}');

      if (jsonStartIndex != -1 && jsonEndIndex != -1 && jsonEndIndex > jsonStartIndex) {
        jsonString = jsonString.substring(jsonStartIndex, jsonEndIndex + 1);
      } else {
        // If it doesn't look like JSON, throw an error or handle it as plain text.
        // This is where you might catch the "The video shows a deer..." type of output
        // if it's not wrapped in markdown or doesn't even contain JSON.
        throw Exception(
          'Response does not contain a valid JSON object after initial parsing attempt: $jsonString. Full response text: $responseText',
        );
      }

      final decodedJson = json.decode(jsonString);
      return AnalysisResult.fromJson(decodedJson);
    } catch (e) {
      print('Error analyzing video: $e');
      // Re-throw the error to be handled by the UI
      throw Exception('Failed to analyze video. Error: $e');
    }
  }
}
