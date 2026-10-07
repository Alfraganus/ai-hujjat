# Hissa qo'shish

Loyihaga qo'shgan hissangiz uchun rahmat! Xato topsangiz, taklifingiz bo'lsa yoki kod
yozmoqchi bo'lsangiz, quyidagilar yordam beradi.

## Xato haqida xabar berish

[Issues](../../issues) bo'limida yangi masala oching va quyidagilarni yozing:

- nima qilgansiz va nima kutgansiz, nima bo'ldi;
- Windows versiyasi va AI provayderi/modeli (token **kerak emas**, uni hech qachon yubormang);
- ilova jurnali: `%APPDATA%\uz.aihujjat\AI Hujjat\app.log` (maxfiy narsa bo'lmasa, oxirgi satrlarini qo'shing).

> Hujjatlaringiz yoki API tokeningizni masalaga yopishtirmang.

## Ishlab chiqish muhiti

```bash
git clone https://github.com/Alfraganus/ai-hujjat.git
cd ai-hujjat
powershell -ExecutionPolicy Bypass -File tool/download_model.ps1   # embedding modeli (~135 MB)
flutter pub get
flutter run -d windows
```

Kerak bo'ladi: Flutter (3.41 yoki yangiroq), Visual Studio Build Tools ("Desktop development
with C++" ish yuki). Model fayllarisiz ilova ishlaydi, lekin faqat so'z bo'yicha qidiradi.

## Pull request yuborishdan oldin

```bash
flutter analyze        # xatolarsiz bo'lishi kerak
flutter test           # barcha testlar o'tishi kerak
```

- Yangi xususiyat yoki xato tuzatish uchun test yozing (`test/` papkasida namunalar bor).
- Kod uslubi mavjud kodga o'xshash bo'lsin: izohlar qisqa, "nima uchun" ni tushuntirsin.
- Matnlar uch tilda (`lib/l10n/app_en.arb`, `app_uz.arb`, `app_ru.arb`) bo'lishi kerak:
  yangi satr qo'shsangiz, uchalasiga ham qo'shing, keyin `flutter gen-l10n` ishga tushiring.
- Interfeysni o'zgartirsangiz, skrinshot oling:
  `UI_SHOTS=1 flutter test test/ui_screenshots_test.dart` (natija `build/ui_shots/` da).
- Bitta PR bitta mavzuga bag'ishlansin.

## Litsenziya

Hissa qo'shish bilan siz kodingiz [MIT litsenziyasi](LICENSE) ostida tarqatilishiga rozilik bildirasiz.
