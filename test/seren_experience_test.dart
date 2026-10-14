import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meditation/app/seren_experience.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'sb_publishable_test',
    );
  });

  testWidgets('Explore categories open a sound player on a compact phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: SerenExperience()));
    await tester.pump();
    expect(find.text('Continue Listening'), findsOneWidget);
    expect(find.text('For You'), findsOneWidget);
    expect(find.text('Quick Start'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);

    await tester.tap(find.text('Explore').last);
    await tester.pump();
    expect(find.text('All Sounds'), findsOneWidget);
    expect(find.text('Deep Focus'), findsOneWidget);
    expect(find.text('Mountain Stream'), findsOneWidget);
    expect(find.text('Cozy Fireplace'), findsOneWidget);

    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -140),
    );
    await tester.pumpAndSettle();
    expect(find.text('All Sounds'), findsOneWidget);
    expect(find.text('A steady rhythm to calm the mind.'), findsOneWidget);

    await tester.dragFrom(const Offset(160, 100), const Offset(0, 180));
    await tester.pumpAndSettle();
    expect(find.text('All Sounds'), findsOneWidget);

    await tester.tap(find.text('Focus').first);
    await tester.pump();
    expect(find.text('Clear sounds. A sharper mind.'), findsOneWidget);
    expect(find.text('Urban'), findsWidgets);

    await tester.tap(find.text('Forest Rain'));
    await tester.pump();
    expect(find.text('Nature\'s rhythm. A calmer mind.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Explore and Profile remain usable at tablet width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(834, 1112);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: SerenExperience()));
    expect(find.text('Continue Listening'), findsOneWidget);
    await tester.tap(find.text('Explore').last);
    await tester.pump();
    expect(find.text('All Sounds'), findsOneWidget);
    await tester.tap(find.text('Profile').last);
    await tester.pump();
    expect(find.text('Sign out'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
