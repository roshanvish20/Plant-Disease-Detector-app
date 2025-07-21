// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';

// class ProfilePage extends StatefulWidget {
//   const ProfilePage({super.key});

//   @override
//   State<ProfilePage> createState() => _ProfilePageState();
// }

// class _ProfilePageState extends State<ProfilePage> {
//   final _supabase = Supabase.instance.client;
//   final _picker = ImagePicker();

//   String? _profileImageUrl;
//   String _userName = 'Fetching...';
//   String _email = 'Fetching...';
//   bool _isEmailVisible = false;
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadUserProfile(); // Fetch user data on page load
//   }

//   /// Fetches user profile data from Supabase
//   Future<void> _loadUserProfile() async {
//     try {
//       setState(() => _isLoading = true);

//       final user = _supabase.auth.currentUser;
//       if (user == null) {
//         debugPrint('No user found');
//         return;
//       }

//       // Fetch profile data from Supabase
//       final response = await _supabase
//           .from('profiles')
//           .select('full_name, avatar_url')
//           .eq('id', user.id)
//           .single();

//       if (response != null) {
//         setState(() {
//           _userName = response['full_name'] ?? 'No Name';
//           _profileImageUrl = response['avatar_url'];
//           _email = user.email ?? 'No Email';
//         });
//       } else {
//         debugPrint('Profile not found');
//       }
//     } catch (e) {
//       debugPrint('Error loading profile: $e');
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   /// Updates and uploads a new profile image to Supabase Storage
//   Future<void> _updateProfileImage() async {
//     final XFile? image = await _picker.pickImage(
//       source: ImageSource.gallery,
//       maxWidth: 1200, // Reduce image size
//       imageQuality: 85, // Compress image
//     );

//     if (image == null) return;

//     try {
//       setState(() => _isLoading = true);

//       final file = File(image.path);
//       final fileExt = image.path.split('.').last;
//       final userId = _supabase.auth.currentUser!.id;
//       final fileName =
//           '$userId/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

//       // Upload to Supabase storage
//       await _supabase.storage.from('avatars').upload(fileName, file);

//       // Get the new public URL
//       final newImageUrl =
//           _supabase.storage.from('avatars').getPublicUrl(fileName);

//       // Update the avatar_url in the database
//       await _supabase
//           .from('profiles')
//           .update({'avatar_url': newImageUrl}).eq('id', userId);

//       setState(() {
//         _profileImageUrl = newImageUrl;
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//             content: Text('Profile image updated!'),
//             backgroundColor: Colors.green),
//       );
//     } catch (e) {
//       debugPrint('Error updating profile image: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//             content: Text('Error updating profile image: ${e.toString()}'),
//             backgroundColor: Colors.red),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   /// Handles user logout
//   Future<void> _signOut() async {
//     try {
//       setState(() => _isLoading = true);
//       await _supabase.auth.signOut();
//       if (mounted) {
//         Navigator.of(context).pushReplacementNamed('/signin');
//       }
//     } catch (e) {
//       debugPrint('Error signing out: $e');
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Profile', style: TextStyle(color: Colors.white)),
//         backgroundColor: Colors.lightBlue.shade700,
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Center(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(20.0),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     GestureDetector(
//                       onTap: _updateProfileImage,
//                       child: Stack(
//                         children: [
//                           CircleAvatar(
//                             radius: 60,
//                             backgroundColor: Colors.grey.shade200,
//                             backgroundImage: _profileImageUrl != null
//                                 ? NetworkImage(
//                                     "$_profileImageUrl?timestamp=${DateTime.now().millisecondsSinceEpoch}")
//                                 : null,
//                             child: _profileImageUrl == null
//                                 ? const Icon(Icons.person, size: 60)
//                                 : null,
//                           ),
//                           Positioned(
//                             bottom: 0,
//                             right: 0,
//                             child: Container(
//                               padding: const EdgeInsets.all(4),
//                               decoration: BoxDecoration(
//                                 color: Colors.lightBlue.shade700,
//                                 shape: BoxShape.circle,
//                               ),
//                               child: const Icon(Icons.edit,
//                                   color: Colors.white, size: 20),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     Text(
//                       _userName,
//                       style: const TextStyle(
//                           fontSize: 24, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 10),
//                     ElevatedButton(
//                       onPressed: () {
//                         setState(() => _isEmailVisible = !_isEmailVisible);
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.lightBlue.shade700,
//                         foregroundColor: Colors.white,
//                       ),
//                       child:
//                           Text(_isEmailVisible ? 'Hide Email' : 'Show Email'),
//                     ),
//                     if (_isEmailVisible)
//                       Padding(
//                         padding: const EdgeInsets.only(top: 8.0),
//                         child: Text(
//                           _email,
//                           style:
//                               const TextStyle(fontSize: 14, color: Colors.grey),
//                         ),
//                       ),
//                     const SizedBox(height: 40),
//                     ElevatedButton.icon(
//                       icon: const Icon(Icons.logout, color: Colors.white),
//                       label: const Text('Sign Out',
//                           style: TextStyle(color: Colors.white)),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.redAccent,
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 32, vertical: 12),
//                         shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10)),
//                       ),
//                       onPressed: _signOut,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }
// }



















//  final remediesData = [
//     // Apple remedies
//     {
//       'plant_name': 'Apple',
//       'disease_name': 'Healthy',
//       'remedy': 'Regularly prune branches to improve air circulation.\nWater deeply but infrequently to encourage strong roots.\nApply organic mulch to maintain soil moisture.\nUse disease-resistant apple varieties.'
//     },
//     {
//       'plant_name': 'Apple',
//       'disease_name': 'Scab',
//       'remedy': 'Remove and destroy infected leaves to prevent fungal spread.\nApply sulfur or copper-based fungicides in early spring.\nUse disease-resistant apple varieties.\nAvoid overhead watering to keep leaves dry.'
//     },
//     {
//       'plant_name': 'Apple',
//       'disease_name': 'Black_Rot',
//       'remedy': 'Prune and remove infected branches immediately.\nSpray with copper-based fungicides during early growth stages.\nKeep the orchard clean and remove fallen fruit.'
//     },
//     {
//       'plant_name': 'Apple',
//       'disease_name': 'Cedar_Apple_Rust',
//       'remedy': 'Remove nearby juniper or cedar trees that may carry spores.\nApply fungicides containing myclobutanil or sulfur before buds open.\nImprove air circulation by pruning excess foliage.'
//     },
    
//     // Cherry remedies
//     {
//       'plant_name': 'Cherry',
//       'disease_name': 'Healthy',
//       'remedy': 'Provide good spacing to allow airflow.\nWater at the base to avoid wetting the leaves.\nApply organic compost to nourish the tree.'
//     },
//     {
//       'plant_name': 'Cherry',
//       'disease_name': 'Powdery_Mildew',
//       'remedy': 'Spray with sulfur-based fungicides at the first sign of infection.\nPrune branches to improve air circulation.\nWater at the base to avoid wetting leaves.'
//     },
    
//     // Chili remedies
//     {
//       'plant_name': 'Chili',
//       'disease_name': 'Healthy',
//       'remedy': 'Plant in full sunlight with well-draining soil.\nUse organic fertilizers rich in potassium and phosphorus.\nAvoid excessive nitrogen fertilizers to prevent weak growth.'
//     },
//     {
//       'plant_name': 'Chili',
//       'disease_name': 'Leaf_Curl',
//       'remedy': 'Apply neem oil to manage insect pests that spread the virus.\nAvoid over-fertilization, especially nitrogen-rich fertilizers.\nUse reflective mulches to deter pests.'
//     },
//     {
//       'plant_name': 'Chili',
//       'disease_name': 'Leaf_Spot',
//       'remedy': 'Remove affected leaves and dispose of them away from the garden.\nApply a copper-based fungicide.\nImprove soil drainage to reduce fungal growth.'
//     },
//     {
//       'plant_name': 'Chili',
//       'disease_name': 'Whitefly',
//       'remedy': 'Introduce natural predators like ladybugs.\nUse yellow sticky traps to catch adult whiteflies.\nSpray neem oil or insecticidal soap to control pests.'
//     },
//     {
//       'plant_name': 'Chili',
//       'disease_name': 'Yellowish',
//       'remedy': 'Apply balanced fertilizers rich in nitrogen and iron.\nEnsure proper watering—avoid overwatering or drought stress.\nCheck for root damage and pests affecting nutrient uptake.'
//     },
    
//     // Coffee remedies
//     {
//       'plant_name': 'Coffee',
//       'disease_name': 'Healthy',
//       'remedy': 'Grow in well-drained, slightly acidic soil.\nProvide shade to reduce stress.\nWater consistently but avoid waterlogging.'
//     },
//     {
//       'plant_name': 'Coffee',
//       'disease_name': 'Rust',
//       'remedy': 'Remove and destroy infected leaves.\nApply copper-based fungicides regularly.\nMaintain proper shade and avoid overcrowding.'
//     },
//     {
//       'plant_name': 'Coffee',
//       'disease_name': 'Red_Spider_Mites',
//       'remedy': 'Wash leaves with water to remove mites.\nIntroduce predatory mites to control the population.\nUse neem oil as a natural insecticide.'
//     },
    
//     // Corn remedies
//     {
//       'plant_name': 'Corn',
//       'disease_name': 'Healthy',
//       'remedy': 'Rotate crops yearly to improve soil health.\nPlant in full sunlight and ensure proper spacing.\nWater deeply and evenly to avoid stress.'
//     },
//     {
//       'plant_name': 'Corn',
//       'disease_name': 'Gray_Leaf_Spot',
//       'remedy': 'Rotate crops yearly to break the disease cycle.\nApply fungicides containing strobilurins or triazoles.\nIncrease plant spacing to improve airflow.'
//     },
//     {
//       'plant_name': 'Corn',
//       'disease_name': 'Common_Rust',
//       'remedy': 'Grow rust-resistant corn varieties.\nRemove infected plant debris after harvest.\nSpray with sulfur-based fungicides at early stages.'
//     },
//     {
//       'plant_name': 'Corn',
//       'disease_name': 'Northern_Leaf_Blight',
//       'remedy': 'Apply copper-based fungicides before symptoms appear.\nImprove air circulation and reduce humidity.\nUse nitrogen-rich fertilizers to boost plant resistance.'
//     },
    
//     // Grape remedies
//     {
//       'plant_name': 'Grape',
//       'disease_name': 'Healthy',
//       'remedy': 'Prune vines regularly to improve air circulation.\nProvide support with trellises to prevent overcrowding.\nRemove fallen leaves and debris from the vineyard.'
//     },
//     {
//       'plant_name': 'Grape',
//       'disease_name': 'Black_Rot',
//       'remedy': 'Remove infected fruit and prune vines regularly.\nApply fungicides containing myclobutanil or mancozeb.\nEnsure proper spacing for good air circulation.'
//     },
//     {
//       'plant_name': 'Grape',
//       'disease_name': 'Esca_Black_Measles',
//       'remedy': 'Avoid injuring vines during pruning.\nUse systemic fungicides and improve soil nutrition.\nRemove severely infected vines to prevent spread.'
//     },
//     {
//       'plant_name': 'Grape',
//       'disease_name': 'Leaf_Blight',
//       'remedy': 'Apply copper-based fungicides before bud break.\nRemove fallen leaves and maintain vineyard hygiene.\nPrune excess foliage to reduce humidity.'
//     },
    
//     // Peach remedies
//     {
//       'plant_name': 'Peach',
//       'disease_name': 'Healthy',
//       'remedy': 'Water early in the morning and avoid wetting leaves.\nApply a layer of mulch around the base to retain moisture.\nPrune branches to improve sunlight penetration.'
//     },
//     {
//       'plant_name': 'Peach',
//       'disease_name': 'Bacterial_Spot',
//       'remedy': 'Remove and destroy affected leaves and fruits.\nApply copper-based fungicides during early growth stages.\nUse resistant peach varieties to prevent infection.'
//     },
    
//     // Bell Pepper remedies
//     {
//       'plant_name': 'Bell_Pepper',
//       'disease_name': 'Healthy',
//       'remedy': 'Plant in full sunlight with well-draining soil.\nUse organic fertilizers rich in potassium and phosphorus.\nAvoid excessive nitrogen fertilizers to prevent weak growth.'
//     },
//     {
//       'plant_name': 'Bell_Pepper',
//       'disease_name': 'Bacterial_Spot',
//       'remedy': 'Avoid overhead watering and keep foliage dry.\nRemove and destroy infected leaves.\nUse copper-based bactericides at early signs of infection.'
//     },
    
//     // Potato remedies
//     {
//       'plant_name': 'Potato',
//       'disease_name': 'Healthy',
//       'remedy': 'Rotate crops yearly to improve soil health.\nUse organic mulch to retain soil moisture.\nPlant in well-drained soil and avoid excessive moisture.'
//     },
//     {
//       'plant_name': 'Potato',
//       'disease_name': 'Early_Blight',
//       'remedy': 'Remove infected leaves and apply organic fungicides.\nAvoid excessive nitrogen fertilizer to prevent weak growth.\nRotate crops yearly to prevent disease buildup.'
//     },
//     {
//       'plant_name': 'Potato',
//       'disease_name': 'Late_Blight',
//       'remedy': 'Apply copper-based fungicides during wet weather.\nDestroy infected plants to prevent spread.\nImprove drainage to reduce excess moisture.'
//     },
    
//     // Strawberry remedies
//     {
//       'plant_name': 'Strawberry',
//       'disease_name': 'Healthy',
//       'remedy': 'Grow in well-drained soil with full sunlight exposure.\nAvoid planting in areas where strawberries were previously grown.\nUse straw mulch to prevent soil-borne diseases.'
//     },
//     {
//       'plant_name': 'Strawberry',
//       'disease_name': 'Leaf_Scorch',
//       'remedy': 'Avoid overhead watering and water at the base.\nRemove infected leaves to prevent further spread.\nApply fungicides containing myclobutanil or mancozeb.'
//     },
    
//     // Tomato remedies
//     {
//       'plant_name': 'Tomato',
//       'disease_name': 'Healthy',
//       'remedy': 'Ensure plants get at least 6 hours of direct sunlight daily.\nSpace plants properly to allow air circulation and reduce moisture buildup.\nApply organic compost and rotate crops yearly.'
//     },
//     {
//       'plant_name': 'Tomato',
//       'disease_name': 'Bacterial_Spot',
//       'remedy': 'Remove affected leaves and avoid working in wet conditions.\nApply copper-based fungicides for disease control.\nUse resistant tomato varieties if available.'
//     },
//     {
//       'plant_name': 'Tomato',
//       'disease_name': 'Early_Blight',
//       'remedy': 'Prune lower leaves to reduce fungal spores.\nApply fungicides like chlorothalonil.\nSpace plants properly to improve air circulation.'
//     },
//     {
//       'plant_name': 'Tomato',
//       'disease_name': 'Late_Blight',
//       'remedy': 'Remove infected plants immediately.\nApply fungicides containing copper hydroxide.\nAvoid excessive humidity in greenhouses.'
//     },
//     {
//       'plant_name': 'Tomato',
//       'disease_name': 'Leaf_Mold',
//       'remedy': 'Improve air circulation and reduce humidity levels.\nApply sulfur-based fungicides.\nWater early in the morning to allow leaves to dry.'
//     },
//     {
//       'plant_name': 'Tomato',
//       'disease_name': 'Septoria_Leaf_Spot',
//       'remedy': 'Remove infected leaves as soon as possible.\nApply fungicides containing chlorothalonil or mancozeb.\nKeep leaves dry and avoid overhead watering.'
//     },
//     {
//       'plant_name': 'Tomato',
//       'disease_name': 'Spider_Mites',
//       'remedy': 'Spray water to dislodge mites from leaves.\nUse neem oil or insecticidal soap.\nIntroduce predatory mites for biological control.'
//     },
//     {
//       'plant_name': 'Tomato',
//       'disease_name': 'Target_Spot',
//       'remedy': 'Remove affected leaves and dispose of them.\nApply copper-based fungicides before symptoms worsen.\nKeep plants spaced well to allow airflow.'
//     },
//     {
//       'plant_name': 'Tomato',
//       'disease_name': 'Yellow_Leaf_Curl_Virus',
//       'remedy': 'Remove infected plants immediately.\nControl whiteflies using insecticidal soap.\nUse virus-resistant tomato varieties.'
//     },
//     {
//       'plant_name': 'Tomato',
//       'disease_name': 'Mosaic_Virus',
//       'remedy': 'Avoid handling plants if symptoms appear.\nSanitize gardening tools regularly.\nRemove and destroy infected plants.'
//     }
//   ];
  