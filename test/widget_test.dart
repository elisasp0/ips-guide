import 'package:flutter_test/flutter_test.dart';
import 'package:ips_guide/app/app.dart';

import 'support/widget_utils.dart';

void main() {
  setUpAll(siapkanRepository);

  testWidgets('Beranda tampil sebagai halaman awal setelah masuk',
      (tester) async {
    await tester.pumpWidget(bungkusAplikasi(const IpsGuideApp()));
    await tunggu(tester, find.text('Mulai Panduan'));

    expect(find.text('IPS-Guide'), findsOneWidget);
    expect(find.textContaining('Selamat datang'), findsOneWidget);
  });
}
