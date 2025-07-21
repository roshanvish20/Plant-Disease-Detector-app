import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

// Get Supabase client
final supabase = Supabase.instance.client;

Future<String?> fetchRemedy(String plantName, String diseaseName) async {   
  try {
    // Clean up plant and disease names
    final cleanPlantName = plantName.replaceAll('_', ' ').trim();
    final cleanDiseaseName = diseaseName.trim();
    
    debugPrint('Fetching remedy for plant: $cleanPlantName, disease: $cleanDiseaseName');
    
    final response = await supabase
        .from('remedies')
        .select('remedy')
        .ilike('plant_name', cleanPlantName)
        .ilike('disease_name', cleanDiseaseName)
        .maybeSingle();  

    if (response != null && response['remedy'] != null) {       
      debugPrint('Remedy found: ${response['remedy']}'); 
      return response['remedy'] as String;       
    } else {
      debugPrint('No remedy found for $cleanPlantName with $cleanDiseaseName');
      return 'No specific remedy found for this condition. Consider consulting with a plant specialist for personalized advice.';       
    }   
  } catch (e) {     
    debugPrint('Error fetching remedy: $e');   
    return 'Error fetching remedy information. Please try again later.';
  } 
}