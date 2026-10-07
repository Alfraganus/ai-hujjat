import 'dart:io';

import 'package:ai_hujjat/services/secret_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('token round-trips and is not stored as plain text', () {
    final store = SecretStore.create();
    const token = 'sk-ant-test-123';
    final stored = store.encrypt(token);
    expect(stored.contains(token), isFalse);
    expect(store.decrypt(stored), token);
    expect(store.decrypt('not-valid-data'), isNull);
  }, skip: !Platform.isWindows ? 'DPAPI is Windows-only' : false);
}
