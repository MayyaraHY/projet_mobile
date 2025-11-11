import 'package:flutter/material.dart';
import '../../models/insurance.dart';
import 'package:gestion_assurance_mobile_project/widgets/logo_renderer_io.dart'
    if (dart.library.html) 'package:gestion_assurance_mobile_project/widgets/logo_renderer_web.dart';
import '../../services/insurance_service.dart';
import '../details/insurance_details.dart';
import 'AddInsuranceScreen.dart';
import 'EditInsuranceScreen.dart';

class InsuranceListAdmin extends StatefulWidget {
  final InsuranceService service; // ✅ Service global

  const InsuranceListAdmin({Key? key, required this.service}) : super(key: key);

  @override
  State<InsuranceListAdmin> createState() => _InsuranceListAdminState();
}

class _InsuranceListAdminState extends State<InsuranceListAdmin> {
  late List<Insurance> _insuranceList; // ✅ Liste directe

  @override
  void initState() {
    super.initState();
    _insuranceList = [];
    _loadInsurances();
  }

  Future<void> _loadInsurances() async {
    await widget.service.loadFromDB(); // 🔹 Charge depuis SQLite
    setState(() {
      _insuranceList = widget.service.insurances;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Insurance Management"),
        backgroundColor: const Color(0xFF036074),
        centerTitle: true,
      ),
      body: _insuranceList.isEmpty
          ? const Center(
        child: Text(
          "No insurance offers yet.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView.builder(
          itemCount: _insuranceList.length,
          itemBuilder: (context, index) {
            final insurance = _insuranceList[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        InsuranceDetails(insurance: insurance),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: buildInsuranceLogo(
                      insurance.logoUrl,
                      width: 65,
                      height: 65,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(
                    insurance.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "${insurance.pricePerYear.toStringAsFixed(0)} DT/an",
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        icon:
                        const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () async {
                          final updated = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditInsuranceScreen(
                                insurance: insurance,
                                onEdit: (updatedInsurance) async {
                                  await widget.service.updateInsurance(
                                      insurance.id, updatedInsurance);
                                  _loadInsurances();
                                },
                              ),
                            ),
                          );
                          if (updated != null) _loadInsurances();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            color: Colors.redAccent),
                        onPressed: () async {
                          await widget.service
                              .deleteInsurance(insurance.id);
                          _loadInsurances();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "Insurance deleted successfully ✅"),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final newInsurance = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddInsuranceScreen()),
          );
          if (newInsurance != null && newInsurance is Insurance) {
            await widget.service.addInsurance(newInsurance);
            _loadInsurances();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("New insurance added successfully ✅"),
              ),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Insurance"),
        backgroundColor: const Color(0xFF036074),
      ),
    );
  }
}
