import 'package:flutter/material.dart';
import '../../models/insurance.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:gestion_assurance_mobile_project/widgets/logo_renderer_io.dart'
    if (dart.library.html) 'package:gestion_assurance_mobile_project/widgets/logo_renderer_web.dart';

class AddInsuranceScreen extends StatefulWidget {
  const AddInsuranceScreen({Key? key}) : super(key: key);

  @override
  State<AddInsuranceScreen> createState() => _AddInsuranceScreenState();
}

class _AddInsuranceScreenState extends State<AddInsuranceScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController logoController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController typeController = TextEditingController();
  final TextEditingController coverageController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  String? _pickedImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Add New Insurance",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.more_vert, color: Colors.black54),
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 120),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🖤 Carte d'assurance complète et visible
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: double.infinity,
                height: 210,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: const DecorationImage(
                    image: NetworkImage(
                      "https://i.imgur.com/8fQfGgM.png", // ✅ Fond stylé “carte noire”
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    const Positioned(
                      left: 20,
                      top: 25,
                      child: Text(
                        "Karhabti",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 20,
                      top: 20,
                      child: SizedBox(
                        width: 55,
                        height: 55,
                        child: _pickedImage == null
                            ? const Icon(Icons.image, color: Colors.white)
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: buildInsuranceLogo(
                                  _pickedImage!,
                                  width: 55,
                                  height: 55,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                    ),
                    const Positioned(
                      left: 20,
                      bottom: 50,
                      child: Text(
                        "Insurance Holder",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                    const Positioned(
                      left: 20,
                      bottom: 25,
                      child: Text(
                        "•••• •••• •••• ••••",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // 🔹 Formulaire clair
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Logo"),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.photo_library),
                          label: const Text("Choose Image"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _pickedImage == null ? 'No image selected' : _pickedImage!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      ],
                    ),

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
                    _buildMultilineField(descriptionController,
                        "Assurance complète pour véhicules particuliers..."),

                    _buildLabel("Contact"),
                    _buildTextField(contactController, "contact@assurance.com"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // 🔘 Bouton noir fixe en bas
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final insurance = Insurance(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text,
                logoUrl: (_pickedImage != null && _pickedImage!.isNotEmpty)
                    ? _pickedImage!
                    : logoController.text,
                pricePerYear: double.tryParse(priceController.text) ?? 0,
                description: descriptionController.text,
                type: typeController.text,
                coverage: coverageController.text,
                contact: contactController.text,
              );
              Navigator.pop(context, insurance);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 8,
          ),
          child: const Text(
            "Add",
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (kIsWeb && file.bytes != null) {
      final ext = (file.extension ?? 'png').toLowerCase();
      final b64 = base64Encode(file.bytes!);
      setState(() {
        _pickedImage = 'data:image/$ext;base64,$b64';
      });
    } else if (file.path != null) {
      setState(() {
        _pickedImage = file.path!;
      });
    }
  }

  // 🧩 Champ simple
  Widget _buildTextField(TextEditingController controller, String hint,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black38),
          filled: true,
          fillColor: const Color(0xFFF7F7F7),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
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

  // 🧩 Champ multiligne pour “Description”
  Widget _buildMultilineField(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: controller,
        maxLines: 3, // 👈 Permet d’afficher tout le texte
        keyboardType: TextInputType.multiline,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black38),
          filled: true,
          fillColor: const Color(0xFFF7F7F7),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
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

  // 🧩 Label
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Color(0xFF036074),
        ),
      ),
    );
  }
}
