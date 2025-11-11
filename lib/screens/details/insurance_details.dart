import 'package:flutter/material.dart';
import '../../models/insurance.dart';
import 'package:gestion_assurance_mobile_project/widgets/logo_renderer_io.dart'
    if (dart.library.html) 'package:gestion_assurance_mobile_project/widgets/logo_renderer_web.dart';

class InsuranceDetails extends StatelessWidget {
  final Insurance insurance;

  const InsuranceDetails({Key? key, required this.insurance}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(insurance.name),
        backgroundColor: const Color(0xFF036074),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🔹 Carte visuelle de l’assurance
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(
                  image: NetworkImage(
                    "https://upload.wikimedia.org/wikipedia/commons/6/6a/Black_Card_Background.png",
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 20,
                    top: 20,
                    child: Text(
                      insurance.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 20,
                    top: 20,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: buildInsuranceLogo(
                        insurance.logoUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: 25,
                    child: Text(
                      "${insurance.pricePerYear.toStringAsFixed(0)} DT / an",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: 50,
                    child: Text(
                      insurance.type,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // 🔹 Section détails
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailTile("Type d’assurance", insurance.type),
                  _detailTile("Prix annuel", "${insurance.pricePerYear} DT / an"),
                  _detailTile("Couverture", insurance.coverage),

                  const SizedBox(height: 10),
                  const Text(
                    "Description",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF036074),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    insurance.description,
                    style: const TextStyle(fontSize: 15),
                  ),

                  const SizedBox(height: 18),
                  const Text(
                    "Contact",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF036074),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined,
                          color: Color(0xFF036074), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          insurance.contact,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Widget pour les lignes de détails
  Widget _detailTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              "$label :",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
