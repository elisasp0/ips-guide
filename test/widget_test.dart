import 'package:flutter_test/flutter_test.dart';

import 'package:ips_guide/app/app.dart';

void main() {
  testWidgets('Aplikasi tampil dengan judul IPS-Guide', (tester) async {
    await tester.pumpWidget(const IpsGuideApp());

    expect(find.text('IPS-Guide'), findsOneWidget);
    expect(
      find.text('Aplikasi Panduan Interaktif Layanan Administrasi Kelurahan'),
      findsOneWidget,
    );
  });
}
