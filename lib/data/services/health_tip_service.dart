import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

class HealthTipService {
  // URLs for pet health websites
  final String _petMdUrl = 'https://www.petmd.com/dog/care/responsible-pet-owners-checklist-taking-care-pet';
  final String _akc_url = 'https://www.akc.org/expert-advice/health/general-tips-for-keeping-your-dog-healthy/';
  final String _avma_url = 'https://www.avma.org/resources-tools/pet-owners/petcare/pet-health';
  
  Future<List<HealthTip>> getHealthTips() async {
    try {
      // Fetch health tips from well-known pet sites
      List<HealthTip> tips = [];
      
      // Try to fetch from PetMD
      try {
        final petMdTips = await _fetchFromPetMD();
        tips.addAll(petMdTips);
      } catch (e) {
        print('Error fetching from PetMD: $e');
      }
      
      // If we couldn't fetch or got no results, fall back to hardcoded tips
      if (tips.isEmpty) {
        tips = _getHardcodedHealthTips();
      }
      
      return tips;
    } catch (e) {
      print('Error getting health tips: $e');
      // Fall back to hardcoded health tips if there's any error
      return _getHardcodedHealthTips();
    }
  }
  
  Future<List<HealthTip>> _fetchFromPetMD() async {
    final response = await http.get(Uri.parse(_petMdUrl));
    
    if (response.statusCode != 200) {
      throw Exception('Failed to load tips from PetMD');
    }
    
    // Parse the HTML
    var document = html_parser.parse(response.body);
    
    List<HealthTip> tips = [];
    int idCounter = 1;
    
    // Extract tips from the page (looking for list items or paragraphs)
    var contentElements = document.querySelectorAll('main p, main li, main h2');
    
    String? currentHeading;
    for (var i = 0; i < contentElements.length; i++) {
      var element = contentElements[i];
      
      if (element.localName == 'h2') {
        currentHeading = element.text.trim();
        continue;
      }
      
      // Skip short paragraphs or list items (likely not tips)
      if (element.text.trim().length < 30) continue;
      
      // Get the first image in the article if available
      String? imageUrl;
      var images = document.querySelectorAll('main img');
      if (images.isNotEmpty) {
        var imgElement = images[idCounter % images.length];
        var imgSrc = imgElement.attributes['src'];
        if (imgSrc != null) {
          imageUrl = imgSrc.startsWith('http') ? imgSrc : 'https://www.petmd.com$imgSrc';
        }
      }
      
      tips.add(HealthTip(
        id: idCounter.toString(),
        title: currentHeading ?? 'Pet Care Tip',
        content: element.text.trim(),
        imageUrl: imageUrl ?? 'https://images.unsplash.com/photo-1601758228007-550c9f4e2e76',
        source: 'PetMD',
        sourceUrl: _petMdUrl,
      ));
      
      idCounter++;
      if (tips.length >= 5) break; // Limit to 5 tips
    }
    
    return tips;
  }
  
  List<HealthTip> _getHardcodedHealthTips() {
    return [
      HealthTip(
        id: '1',
        title: 'Healthy Diet for Dogs',
        content: 'Ensure your dog gets a balanced diet with proper proteins, carbohydrates, and vegetables. Avoid feeding chocolate, grapes, and onions as they can be toxic to dogs.',
        imageUrl: 'https://images.unsplash.com/photo-1601758228007-550c9f4e2e76',
        source: 'PetMD',
        sourceUrl: 'https://www.petmd.com/dog/nutrition',
      ),
        HealthTip(
          id: '2',
          title: 'Regular Exercise',
          content: 'Dogs need regular exercise to maintain their physical and mental health. The amount varies by breed, age, and health status. Most dogs benefit from at least 30 minutes of activity daily.',
          imageUrl: 'https://images.unsplash.com/photo-1551730459-92db2a308d6e',
          source: 'AKC',
          sourceUrl: 'https://www.akc.org/expert-advice/health/how-much-exercise-does-dog-need/',
        ),
        HealthTip(
          id: '3',
          title: 'Dental Care',
          content: 'Regular tooth brushing can prevent dental disease in dogs. Aim for daily brushing using dog-specific toothpaste (never human toothpaste).',
          imageUrl: 'https://images.unsplash.com/photo-1588943211346-0908a1fb0b01',
          source: 'AVMA',
          sourceUrl: 'https://www.avma.org/resources-tools/pet-owners/petcare/pet-dental-care',
        ),
        HealthTip(
          id: '4',
          title: 'Parasite Prevention',
          content: 'Maintaining a regular parasite prevention schedule is essential for your dog\'s health. This includes flea, tick, heartworm, and intestinal parasite prevention.',
          imageUrl: 'https://images.unsplash.com/photo-1583337130417-3346a1be7dee',
          source: 'CDC',
          sourceUrl: 'https://www.cdc.gov/healthypets/pets/dogs.html',
        ),
        HealthTip(
          id: '5',
          title: 'Recognizing Signs of Illness',
          content: 'Early detection of illness is important. Watch for changes in appetite, water consumption, energy levels, urination, bowel movements, vomiting, or unusual behaviors.',
          imageUrl: 'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e',
          source: 'VCA Hospitals',
          sourceUrl: 'https://vcahospitals.com/know-your-pet/signs-your-dog-is-sick',
        ),
      ];
    } catch (e) {
      throw Exception('Failed to load health tips: $e');
    }
  }
  
  // Function to fetch real health tips from an external API (not used in this demo)
  Future<List<HealthTip>> _fetchRealHealthTips() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/dogs'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => HealthTip.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load health tips');
      }
    } catch (e) {
      throw Exception('Failed to load health tips: $e');
    }
  }
}

class HealthTip {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final String source;
  final String sourceUrl;

  HealthTip({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.source,
    required this.sourceUrl,
  });

  factory HealthTip.fromJson(Map<String, dynamic> json) {
    return HealthTip(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      imageUrl: json['imageUrl'],
      source: json['source'],
      sourceUrl: json['sourceUrl'],
    );
  }
}
