// filepath: c:\FlutterProjects\projet_mobile-voiture\lib\screens\contracts_for_car_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/contract.dart';
import '../services/contract_service.dart';
import 'contract_details_screen.dart';

class ContractsForCarScreen extends StatefulWidget {
  final String matricule;
  const ContractsForCarScreen({super.key, required this.matricule});

  @override
  State<ContractsForCarScreen> createState() => _ContractsForCarScreenState();
}

class _ContractsForCarScreenState extends State<ContractsForCarScreen> {
  final ContractService _service = ContractService();
  late Future<List<Contract>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getContractsForMatricule(widget.matricule);
  }

  Future<void> _refresh() async {
    setState(() => _future = _service.getContractsForMatricule(widget.matricule));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Contracts for ${widget.matricule}')),
      body: FutureBuilder<List<Contract>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final list = snap.data ?? [];
          if (list.isEmpty) return Center(child: Text('No contracts for ${widget.matricule}'));
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, i) {
                final c = list[i];
                return ListTile(
                  title: Text(c.title),
                  subtitle: Text('${c.buyerName} ↔ ${c.sellerName} • ${c.status}'),
                  trailing: Text('\$${c.price.toStringAsFixed(2)}'),
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => ContractDetailsScreen(contractId: c.id!)));
                    _refresh();
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

