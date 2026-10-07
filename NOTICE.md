# Uchinchi tomon komponentlari (Third-party notices)

AI Hujjat o'zining kodi uchun [MIT litsenziyasi](LICENSE) ostida tarqatiladi. U quyidagi
ochiq komponentlardan foydalanadi; ularning har biri o'z litsenziyasi bilan keladi.
Tarqatilgan installerga ular birga kiradi.

## Model

| Komponent | Litsenziya | Manba |
|---|---|---|
| **multilingual-e5-small** (matnni vektorga aylantirish modeli) | MIT | [intfloat/multilingual-e5-small](https://huggingface.co/intfloat/multilingual-e5-small) |
| int8 ONNX o'girmasi (`model_quantized.onnx`, `tokenizer.json`) | o'girma sahifasida alohida litsenziya ko'rsatilmagan; u MIT litsenziyali asl modeldan olingan | [Xenova/multilingual-e5-small](https://huggingface.co/Xenova/multilingual-e5-small) |

Model repozitoriyga **qo'shilmagan**: uni `tool/download_model.ps1` (yoki `.sh`) yuklab oladi.
Modelning mualliflari: *Multilingual E5 Text Embeddings: A Technical Report* (Liang Wang va boshq.).

## Mahalliy kutubxonalar (installer ichida)

| Komponent | Litsenziya |
|---|---|
| [ONNX Runtime](https://github.com/microsoft/onnxruntime) (`onnxruntime.dll`) | MIT |
| [PDFium](https://pdfium.googlesource.com/pdfium/) (`pdfium.dll`) | Apache-2.0 |
| [SQLite](https://www.sqlite.org/copyright.html) (`sqlite3.dll`) | Public domain |
| [Flutter engine](https://github.com/flutter/flutter) (`flutter_windows.dll`) | BSD-3-Clause |
| Microsoft Visual C++ runtime (`msvcp140.dll`, `vcruntime140*.dll`) | Microsoft qayta tarqatish shartlari |

## Dart / Flutter paketlari

Asosiylari (to'liq ro'yxat va versiyalar uchun `pubspec.lock` ga qarang; har bir paketning
litsenziyasi uning o'z `LICENSE` faylida):

| Paket | Litsenziya |
|---|---|
| `flutter_onnxruntime` | MIT |
| `dart_sentencepiece_tokenizer` | MIT |
| `pdfrx`, `pdfrx_engine`, `pdfium_dart` | MIT |
| `sqlite3` | MIT |
| `archive`, `xml`, `file_picker` | MIT |
| `http`, `intl`, `ffi`, `path` | BSD-3-Clause (Dart mualliflari) |
| `shared_preferences`, `path_provider` | BSD-3-Clause (Flutter mualliflari) |

## Savol-javob xizmatlari

Ilova foydalanuvchining **o'z API kaliti** bilan Anthropic yoki OpenAI (yoki ular bilan mos server)
xizmatlariga murojaat qiladi. Bu xizmatlar o'z foydalanish shartlariga ega va ular loyihaga
kirmaydi. "Anthropic", "Claude", "OpenAI", "GPT" nomlari ularning egalariga tegishli.
