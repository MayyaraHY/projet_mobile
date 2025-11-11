import 'package:flutter/material.dart';
import '../../models/insurance.dart';
import 'package:gestion_assurance_mobile_project/widgets/logo_renderer_io.dart'
    if (dart.library.html) 'package:gestion_assurance_mobile_project/widgets/logo_renderer_web.dart';
import '../../services/insurance_service.dart';

class InsuranceListClient extends StatefulWidget {
  final InsuranceService service;

  const InsuranceListClient({Key? key, required this.service}) : super(key: key);

  @override
  State<InsuranceListClient> createState() => _InsuranceListClientState();
}

class _InsuranceListClientState extends State<InsuranceListClient> {
  late Future<List<Insurance>> _insuranceFuture;
  List<Insurance> _filteredInsurances = [];
  String _searchQuery = '';
  String _sortOption = 'Aucun';

  @override
  void initState() {
    super.initState();
    _loadInsurances();
  }

  Future<void> _loadInsurances() async {
    await widget.service.loadFromDB(); // 🔹 Charge depuis SQLite
    setState(() {
      _filteredInsurances = widget.service.insurances;
      _insuranceFuture = Future.value(widget.service.insurances);
    });
  }

  void _searchInsurance(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredInsurances = widget.service.insurances.where((insurance) {
        return insurance.name.toLowerCase().contains(_searchQuery) ||
            insurance.type.toLowerCase().contains(_searchQuery);
      }).toList();
    });
  }

  void _sortInsurances(String option) {
    setState(() {
      _sortOption = option;
      if (option == 'Prix croissant') {
        _filteredInsurances.sort((a, b) => a.pricePerYear.compareTo(b.pricePerYear));
      } else if (option == 'Prix décroissant') {
        _filteredInsurances.sort((a, b) => b.pricePerYear.compareTo(a.pricePerYear));
      } else if (option == 'Type') {
        _filteredInsurances.sort((a, b) => a.type.compareTo(b.type));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Offres d’assurance"),
        backgroundColor: const Color(0xFF036074),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Insurance>>(
        future: _insuranceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Erreur : ${snapshot.error}"),
            );
          }

          if (_filteredInsurances.isEmpty) {
            return const Center(
              child: Text(
                "Aucune offre d’assurance disponible pour le moment.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return Column(
            children: [
              // 🔍 Barre de recherche
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  onChanged: _searchInsurance,
                  decoration: InputDecoration(
                    hintText: "Rechercher une assurance...",
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF036074)),
                    filled: true,
                    fillColor: const Color(0xFFF6F6F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // 🔽 Menu de tri
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DropdownButtonFormField<String>(
                  value: _sortOption,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Aucun', child: Text("Aucun tri")),
                    DropdownMenuItem(value: 'Prix croissant', child: Text("Prix croissant")),
                    DropdownMenuItem(value: 'Prix décroissant', child: Text("Prix décroissant")),
                    DropdownMenuItem(value: 'Type', child: Text("Par type")),
                  ],
                  onChanged: (value) {
                    if (value != null) _sortInsurances(value);
                  },
                ),
              ),

              // 🧩 Grille d'assurances
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(14),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: _filteredInsurances.length,
                  itemBuilder: (context, index) {
                    final insurance = _filteredInsurances[index];
                    return _buildInsuranceCard(insurance);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 🔹 Carte stylisée d’assurance
  Widget _buildInsuranceCard(Insurance insurance) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: buildInsuranceLogo(
              insurance.logoUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            insurance.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            "${insurance.pricePerYear.toStringAsFixed(0)} DT/an",
            style: const TextStyle(
              color: Color(0xFF036074),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            insurance.type,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
