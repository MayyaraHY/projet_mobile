import 'package:flutter/material.dart';
import '../../models/insurance.dart';
import 'package:gestion_assurance_mobile_project/widgets/logo_renderer_io.dart'
    if (dart.library.html) 'package:gestion_assurance_mobile_project/widgets/logo_renderer_web.dart';

class EditInsuranceScreen extends StatefulWidget {
  final Insurance insurance;
  final Function(Insurance) onEdit;

  const EditInsuranceScreen({
    Key? key,
    required this.insurance,
    required this.onEdit,
  }) : super(key: key);

  @override
  State<EditInsuranceScreen> createState() => _EditInsuranceScreenState();
}

class _EditInsuranceScreenState extends State<EditInsuranceScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController logoController;
  late TextEditingController priceController;
  late TextEditingController descriptionController;
  late TextEditingController typeController;
  late TextEditingController coverageController;
  late TextEditingController contactController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.insurance.name);
    logoController = TextEditingController(text: widget.insurance.logoUrl);
    priceController =
        TextEditingController(text: widget.insurance.pricePerYear.toString());
    descriptionController =
        TextEditingController(text: widget.insurance.description);
    typeController = TextEditingController(text: widget.insurance.type);
    coverageController = TextEditingController(text: widget.insurance.coverage);
    contactController = TextEditingController(text: widget.insurance.contact);
  }

  void _saveEdit() {
    if (_formKey.currentState!.validate()) {
      final updatedInsurance = Insurance(
        id: widget.insurance.id,
        name: nameController.text,
        logoUrl: logoController.text,
        pricePerYear: double.tryParse(priceController.text) ?? 0.0,
        description: descriptionController.text,
        type: typeController.text,
        coverage: coverageController.text,
        contact: contactController.text,
      );
      widget.onEdit(updatedInsurance);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Insurance"),
        backgroundColor: const Color(0xFF036074),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Carte visuelle en haut
            Center(
              child: Container(
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
                        widget.insurance.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
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
                          widget.insurance.logoUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 20,
                      bottom: 40,
                      child: Text(
                        "Insurance Holder Name",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),
                    const Positioned(
                      left: 20,
                      bottom: 20,
                      child: Text(
                        "•••• •••• •••• ••••",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 🔹 Formulaire
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("Insurance Name"),
                  _buildTextField(nameController, "e.g. COMAR"),

                  _buildLabel("Logo URL"),
                  _buildTextField(logoController, "https://..."),

                  _buildLabel("Annual Price (DT)"),
                  _buildTextField(priceController, "950", isNumber: true),

                  _buildLabel("Type"),
                  _buildTextField(typeController, "Tous risques"),

                  _buildLabel("Coverage"),
                  _buildTextField(
                      coverageController, "Vol, incendie, dépannage, RC..."),

                  _buildLabel("Description"),
                  _buildTextField(descriptionController,
                      "Assurance complète pour véhicules particuliers..."),

                  _buildLabel("Contact"),
                  _buildTextField(contactController, "contact@assurance.com"),

                  const SizedBox(height: 25),

                  // 🔹 Bouton Sauvegarder
                  Center(
                    child: ElevatedButton(
                      onPressed: _saveEdit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        "Save Changes",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Widgets utilitaires
  Widget _buildTextField(TextEditingController controller, String hint,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "This field is required";
          }
          return null;
        },
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF036074),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    logoController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    typeController.dispose();
    coverageController.dispose();
    contactController.dispose();
    super.dispose();
  }
}
