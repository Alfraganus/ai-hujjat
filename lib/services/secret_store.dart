import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

/// Encrypts small secrets (the API token) for storage in preferences.
///
/// On Windows this uses DPAPI (CryptProtectData): the ciphertext can only be
/// decrypted by the same Windows user on the same machine, and it needs no
/// extra native build tools. Other platforms are not supported yet and fall
/// back to base64 (obfuscation only) so the app still runs.
abstract class SecretStore {
  String encrypt(String plain);
  String? decrypt(String stored);

  static SecretStore create() => Platform.isWindows ? _DpapiStore() : _Base64Store();
}

class _Base64Store implements SecretStore {
  @override
  String encrypt(String plain) => base64Encode(utf8.encode(plain));

  @override
  String? decrypt(String stored) {
    try {
      return utf8.decode(base64Decode(stored));
    } catch (_) {
      return null;
    }
  }
}

final class _DataBlob extends Struct {
  @Uint32()
  external int cbData;
  external Pointer<Uint8> pbData;
}

typedef _ProtectNative = Int32 Function(Pointer<_DataBlob>, Pointer<Utf16>, Pointer<_DataBlob>, Pointer<Void>, Pointer<Void>, Uint32, Pointer<_DataBlob>);
typedef _ProtectDart = int Function(Pointer<_DataBlob>, Pointer<Utf16>, Pointer<_DataBlob>, Pointer<Void>, Pointer<Void>, int, Pointer<_DataBlob>);
typedef _UnprotectNative = Int32 Function(Pointer<_DataBlob>, Pointer<Pointer<Utf16>>, Pointer<_DataBlob>, Pointer<Void>, Pointer<Void>, Uint32, Pointer<_DataBlob>);
typedef _UnprotectDart = int Function(Pointer<_DataBlob>, Pointer<Pointer<Utf16>>, Pointer<_DataBlob>, Pointer<Void>, Pointer<Void>, int, Pointer<_DataBlob>);
typedef _LocalFreeNative = Pointer<Void> Function(Pointer<Void>);
typedef _LocalFreeDart = Pointer<Void> Function(Pointer<Void>);

class _DpapiStore implements SecretStore {
  static const _uiForbidden = 0x1; // CRYPTPROTECT_UI_FORBIDDEN

  final _crypt32 = DynamicLibrary.open('crypt32.dll');
  final _kernel32 = DynamicLibrary.open('kernel32.dll');

  late final _protect = _crypt32.lookupFunction<_ProtectNative, _ProtectDart>('CryptProtectData');
  late final _unprotect = _crypt32.lookupFunction<_UnprotectNative, _UnprotectDart>('CryptUnprotectData');
  late final _localFree = _kernel32.lookupFunction<_LocalFreeNative, _LocalFreeDart>('LocalFree');

  @override
  String encrypt(String plain) {
    final out = _transform(utf8.encode(plain), protect: true);
    if (out == null) throw StateError('CryptProtectData failed');
    return base64Encode(out);
  }

  @override
  String? decrypt(String stored) {
    try {
      final out = _transform(base64Decode(stored), protect: false);
      return out == null ? null : utf8.decode(out);
    } catch (_) {
      return null;
    }
  }

  Uint8List? _transform(List<int> input, {required bool protect}) {
    final inBlob = calloc<_DataBlob>();
    final outBlob = calloc<_DataBlob>();
    final buffer = calloc<Uint8>(input.isEmpty ? 1 : input.length);
    try {
      buffer.asTypedList(input.length).setAll(0, input);
      inBlob.ref
        ..cbData = input.length
        ..pbData = buffer;
      final ok = protect
          ? _protect(inBlob, nullptr, nullptr, nullptr, nullptr, _uiForbidden, outBlob)
          : _unprotect(inBlob, nullptr, nullptr, nullptr, nullptr, _uiForbidden, outBlob);
      if (ok == 0) return null;
      final result = Uint8List.fromList(outBlob.ref.pbData.asTypedList(outBlob.ref.cbData));
      _localFree(outBlob.ref.pbData.cast());
      return result;
    } finally {
      calloc.free(buffer);
      calloc.free(inBlob);
      calloc.free(outBlob);
    }
  }
}
