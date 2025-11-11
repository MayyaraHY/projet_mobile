import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_assurance_mobile_project/main.dart';

void main() {
  testWidgets('KarhabtiApp starts without crashing', (WidgetTester tester) async {
    // Lance ton application principale
    await tester.pumpWidget(const KarhabtiApp());

    // Vérifie que le titre principal s’affiche dans l’écran d’accueil
    expect(find.text('Karhabti Assurance'), findsOneWidget);

    // Vérifie la présence des deux boutons de rôle
    expect(find.text('Espace Administrateur'), findsOneWidget);
    expect(find.text('Espace Client'), findsOneWidget);
  });
}
