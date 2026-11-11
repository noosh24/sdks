import 'dart:io';

import 'package:noosh24/noosh24.dart';

Future<void> main() async {
  final noosh = Noosh24Client(Platform.environment['NOOSH24_API_KEY'] ?? '');
  try {
    final me = await noosh.whoami();
    stdout.writeln('${me.restaurant?.name} ${me.key?.scopes}');

    final page = await noosh.menu.listProducts(
      where: Where().eq('category', 'Salads').eq('available', true),
      sort: 'price desc',
      limit: 50,
    );
    for (final product in page.items) {
      stdout.writeln('${product.name} ${product.price}');
    }
    stdout.writeln('${page.total} products match');
  } on Noosh24Exception catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  } finally {
    noosh.close();
  }
}
