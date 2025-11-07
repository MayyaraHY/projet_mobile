import 'dart:io';
import 'package:flutter/material.dart';
import '../models/voiture.dart'; // Adjust path if needed

class VoitureDetailsScreen extends StatelessWidget {
  final Voiture voiture;

  const VoitureDetailsScreen({Key? key, required this.voiture}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // This allows the image to go "behind" the app bar
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.black, size: 28),
            onPressed: () {
              // TODO: Handle favorite action
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. Main Car Image ---
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.grey[200], // Placeholder color
              child: voiture.hasImage
                  ? Hero(
                      tag: 'voiture-img-${voiture.matricule}',
                      child: Image.file(
                        File(voiture.image!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildImageErrorPlaceholder(),
                      ),
                    )
                  : _buildImageErrorPlaceholder(),
            ),

            // --- 360° Icon ---
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Chip(
                  label: const Text('360°'),
                  avatar: const Icon(Icons.threesixty),
                  backgroundColor: Colors.grey[200],
                ),
              ),
            ),

            // --- 2. Main Content Padding ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Color Options (Hardcoded) ---
                  _buildColorOptions(),
                  const SizedBox(height: 24),

                  // --- Title ---
                  Text(
                    '${voiture.marque} ${voiture.modele}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // --- Tags (New/Used & Rating) ---
                  Row(
                    children: [
                      _buildConditionTag(voiture),
                      const SizedBox(width: 16),
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      const Text(
                        '4.8 (86 reviews)', // Hardcoded rating
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- Description ---
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    voiture.description ?? 'No description provided for this vehicle.',
                    style: const TextStyle(fontSize: 15, color: Colors.black54, height: 1.5),
                    // For "view more" text, use RichText widget
                  ),
                  const SizedBox(height: 24),

                  // --- Gallery Photos (Hardcoded) ---
                  const Text(
                    'Gallery Photos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // Show main image if it exists
                        if (voiture.hasImage)
                          _buildGalleryImage(File(voiture.image!)),
                        _buildGalleryImage(null), // Placeholder
                        _buildGalleryImage(null), // Placeholder
                        _buildGalleryImage(null), // Placeholder
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Seller Info (Hardcoded) ---
                  _buildSellerInfo(),

                  // Spacer for bottom nav bar
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      // --- 3. Bottom App Bar ---
      bottomNavigationBar: BottomAppBar(
        elevation: 10,
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // --- Price ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Price',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  Text(
                    voiture.prixFormate,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // --- "Make an Offer" Button ---
              SizedBox(
                width: 180,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Handle offer action
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Make an Offer',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildImageErrorPlaceholder() {
    return Container(
      width: double.infinity,
      color: Colors.grey[200],
      child: Icon(
        Icons.directions_car,
        size: 100,
        color: Colors.grey[400],
      ),
    );
  }

  // Re-used from your list screen logic
  Widget _buildConditionTag(Voiture voiture) {
    final bool isNew = voiture.kilometrage < 1000;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isNew ? Colors.blue[50] : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isNew ? 'New' : 'Used',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isNew ? Colors.blue[700] : Colors.grey[700],
        ),
      ),
    );
  }

  // Hardcoded color options
  Widget _buildColorOptions() {
    return Row(
      children: [
        _buildColorDot(Colors.grey.shade400, true),
        const SizedBox(width: 12),
        _buildColorDot(Colors.brown.shade700, false),
        const SizedBox(width: 12),
        _buildColorDot(Colors.grey.shade800, false),
        const SizedBox(width: 12),
        _buildColorDot(Colors.grey.shade600, false),
        const SizedBox(width: 12),
        _buildColorDot(Colors.blue.shade800, false),
      ],
    );
  }

  Widget _buildColorDot(Color color, bool isSelected) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: isSelected
            ? Border.all(color: Colors.blue, width: 3)
            : null,
      ),
      child: isSelected
          ? const Icon(Icons.check, color: Colors.white, size: 18)
          : null,
    );
  }

  // Hardcoded gallery image
  Widget _buildGalleryImage(File? file) {
    return Container(
      width: 80,
      height: 80,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey[200],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: file != null
            ? Image.file(file, fit: BoxFit.cover)
            : Icon(Icons.image, color: Colors.grey[400]),
      ),
    );
  }

  // Hardcoded seller info
  Widget _buildSellerInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            // You could use a network image for the logo
            // backgroundImage: NetworkImage('...url_to_bmw_logo...'),
            backgroundColor: Colors.black,
            child: Text(
              'B',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BMW Store', // Hardcoded
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Official Account of BMW', // Hardcoded
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.chat_bubble_outline, color: Colors.blue[700]),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.call_outlined, color: Colors.blue[700]),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}