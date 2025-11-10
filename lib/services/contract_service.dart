// filepath: c:\FlutterProjects\projet_mobile-voiture\lib\services\contract_service.dart
import 'dart:typed_data';
import '../models/contract.dart';
import '../repositories/contract_repository.dart';
import '../utils/pdf_generator.dart';

class ContractService {
  final ContractRepository _repo = ContractRepository();

  Future<int> createContract({
    required String title,
    required String terms,
    required double price,
    required String buyerName,
    required String buyerContact,
    required String sellerName,
    required String sellerContact,
    Map<String, dynamic>? carSnapshot,
    int? buyerId,
    int? sellerId,
    int? carId,
    DateTime? signingDate,
    DateTime? expirationDate,
    String? carMatricule,
  }) async {
    final contract = Contract(
      title: title,
      terms: terms,
      price: price,
      buyerName: buyerName,
      buyerContact: buyerContact,
      sellerName: sellerName,
      sellerContact: sellerContact,
      carSnapshot: carSnapshot,
      buyerId: buyerId,
      sellerId: sellerId,
      carId: carId,
      status: 'Pending',
      signingDate: signingDate,
      expirationDate: expirationDate,
      carMatricule: carMatricule,
    );
    return await _repo.createContract(contract);
  }

  Future<List<Contract>> listContracts() => _repo.getAllContracts();

  Future<Contract?> getContract(int id) => _repo.getContractById(id);

  Future<void> saveSignature(int contractId, {required bool isBuyer, required Uint8List signature}) async {
    final existing = await _repo.getContractById(contractId);
    if (existing == null) throw Exception('Contract not found');
    final updated = isBuyer
        ? existing.copyWith(signatureBuyer: signature, signingDate: DateTime.now())
        : existing.copyWith(signatureSeller: signature, signingDate: DateTime.now());

    String newStatus;
    if (updated.isValidated()) {
      newStatus = 'Validated';
    } else if (updated.isSignedByBuyer() || updated.isSignedBySeller()) {
      newStatus = 'PartiallySigned';
    } else {
      newStatus = 'Pending';
    }

    var finalContract = updated.copyWith(status: newStatus, updatedAt: DateTime.now());
    await _repo.updateContract(finalContract);

    if (finalContract.isValidated()) {
      final pdfPath = await PdfGenerator.generateContractPdf(finalContract);
      finalContract = finalContract.copyWith(pdfPath: pdfPath);
      await _repo.updateContract(finalContract);
    }
  }

  Future<String?> generatePdf(int contractId) async {
    final c = await _repo.getContractById(contractId);
    if (c == null) return null;
    final path = await PdfGenerator.generateContractPdf(c);
    final updated = c.copyWith(pdfPath: path);
    await _repo.updateContract(updated);
    return path;
  }

  Future<void> updateContract(Contract contract) async {
    // Ensure timestamps/status are consistent
    final updated = contract.copyWith(updatedAt: DateTime.now());
    await _repo.updateContract(updated);
  }

  Future<void> deleteContract(int id) async => await _repo.deleteContract(id);

  Future<List<Contract>> getContractsForMatricule(String matricule) async {
    return await _repo.getContractsByMatricule(matricule);
  }
}
