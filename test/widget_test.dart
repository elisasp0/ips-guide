import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ips_guide/app/app.dart';

void main() {
  testWidgets('Beranda tampil sebagai halaman awal', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: IpsGuideApp()));
    await tester.pumpAndSettle();

    expect(find.text('IPS-Guide'), findsOneWidget);
    expect(find.text('Selamat datang'), findsOneWidget);
    expect(find.text('Mulai Panduan'), findsOneWidget);
  });
}
