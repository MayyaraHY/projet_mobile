import '../models/insurance.dart';
import 'database_helper.dart';
import 'package:flutter/foundation.dart';

class InsuranceService extends ChangeNotifier {
  final List<Insurance> _insurances = [];

  List<Insurance> get insurances => _insurances;

  // 🔹 Charger les données SQLite au démarrage
  Future<void> loadFromDB() async {
    final data = await DatabaseHelper().getAllInsurances();
    _insurances.clear();
    _insurances.addAll(data);
    notifyListeners();
  }

  // 🔹 Ajouter une assurance (enregistre aussi dans la DB)
  Future<void> addInsurance(Insurance insurance) async {
    await DatabaseHelper().insertInsurance(insurance);
    _insurances.add(insurance);
    notifyListeners();
  }

  // 🔹 Mettre à jour une assurance
  Future<void> updateInsurance(String id, Insurance newData) async {
    await DatabaseHelper().updateInsurance(newData);
    final index = _insurances.indexWhere((i) => i.id == id);
    if (index != -1) {
      _insurances[index] = newData;
      notifyListeners();
    }
  }

  // 🔹 Supprimer une assurance
  Future<void> deleteInsurance(String id) async {
    await DatabaseHelper().deleteInsurance(id);
    _insurances.removeWhere((i) => i.id == id);
    notifyListeners();
  }
}
