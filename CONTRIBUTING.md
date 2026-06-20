# Contributing Guide

## Başlarken

**Gereksinimler:**
- Flutter SDK (stable channel, `3.32.x` veya üstü)
- Dart SDK (`^3.9.0`)
- Melos: `dart pub global activate melos`

**İlk kurulum:**
```bash
git clone <repo-url>
cd SaloonManager_App
melos bootstrap
```

`melos bootstrap` tüm paketlerdeki bağımlılıkları çözer ve pub workspaces bağlantılarını kurar. Sadece `flutter pub get` **çalıştırmayın** — workspace bağlantıları kurulmaz.

---

## Branch Adlandırma

| Tür | Prefix | Örnek |
|-----|--------|-------|
| Yeni özellik | `feat/` | `feat/app-card-component` |
| Bug fix | `fix/` | `fix/login-validation-crash` |
| Altyapı / config | `chore/` | `chore/upgrade-flutter-3-32` |
| Dokümantasyon | `docs/` | `docs/architecture-diagram` |
| Refactoring | `refactor/` | `refactor/dashboard-extract-widgets` |

Branch her zaman `main`'den açılır.

---

## Commit Stili — Conventional Commits

```
<type>(<scope>): <kısa açıklama>
```

**Tipler:** `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `ci`

**Scope örnekleri:** `mobile`, `network`, `auth`, `ui`, `firebase`, `core`

```bash
# Örnekler
feat(mobile): add AppCard component
fix(network): retry on 503 status code
chore(ci): add code quality workflow
test(mobile): add DashboardBloc unit tests
docs(core): document PaginatedBloc pattern
```

---

## Pull Request Süreci

1. Branch açın ve değişikliklerinizi yapın
2. Yerel olarak tüm kontrolleri çalıştırın:
   ```bash
   melos format       # Kodu formatla
   melos analyze      # Lint kontrolü
   melos test         # Testleri çalıştır
   ```
3. PR açın — `.github/pull_request_template.md` otomatik yüklenir
4. CI'da `Analyze & Test` workflow'u yeşil olmalı
5. En az 1 reviewer onayı gereklidir
6. Merge: **Squash and Merge** (temiz commit history için)

---

## Melos Script Referansı

| Komut | Ne yapar | Ne zaman çalıştırılır |
|-------|----------|-----------------------|
| `melos bootstrap` | Bağımlılıkları kurar, workspace bağlantılarını kurar | İlk kurulumda veya pubspec değiştiğinde |
| `melos analyze` | Tüm paketlerde `dart analyze` çalıştırır | Her commit öncesi |
| `melos test` | Tüm paketlerde `flutter test` çalıştırır | Her commit öncesi |
| `melos format` | Tüm kodu `dart format` ile formatlar | Commit öncesi (edit sonrası) |
| `melos format:check` | Format kontrolü yapar, dosya değiştirmez | CI'da kullanılır |

---

## Yeni Feature Ekleme

```
apps/mobile/lib/features/<feature_name>/
├── bloc/
│   ├── <feature>_bloc.dart      # extends BaseBloc<Event, State>
│   ├── <feature>_event.dart     # Sealed class events
│   └── <feature>_state.dart     # extends BaseState, copyWith pattern
├── view/
│   └── <feature>_screen.dart    # extends StatelessWidget, BaseBlocView ile sarılır
└── <feature>_coordinator.dart   # GoRoute tanımı + show() metodu
```

**Adımlar:**
1. `feat/<feature>` branch açın
2. Yukarıdaki yapıya göre dosyaları oluşturun
3. `AppCoordinator`'a yeni coordinator'ı kaydedin
4. Gerekli use case / repository / datasource'u `apps/mobile/lib/core/` altına ekleyin
5. DI modülüne kayıt ekleyin (gerekiyorsa)
6. `apps/mobile/test/features/<feature>/` altına test dosyası ekleyin
7. `melos test` ile testleri doğrulayın

---

## Yeni Paket Ekleme

1. `packages/flutter_kit_<name>/` dizini oluşturun
2. `pubspec.yaml` ekleyin (name: `flutter_kit_<name>`, `publish_to: none`)
3. Root `pubspec.yaml`'daki `workspace:` listesine ekleyin
4. `apps/mobile/pubspec.yaml`'a path dependency ekleyin:
   ```yaml
   flutter_kit_<name>:
     path: ../../packages/flutter_kit_<name>
   ```
5. `melos bootstrap` çalıştırın
6. Package README.md ekleyin

**Paket izolasyon kuralı:** Paketler arasındaki bağımlılık yönü:
`network ← auth`, `core ← auth`, diğerleri bağımsız. `firebase` → `auth` bağımlılığı yasaktır (circular dependency).

---

## Code Style

- `analysis_options.yaml` kuralları CI'da zorlanır — yerel `melos analyze` ile kontrol edin
- String literals: `prefer_single_quotes` aktif (çift tırnak yerine tek tırnak)
- `avoid_print`: `debugPrint` veya `log` kullanın
- `prefer_const_constructors`: mümkün olduğunda `const` kullanın
- Yorum sadece WHY için: neden yapıldığı belli değilse ekleyin, ne yapıldığını açıklamayın

---

## Test Gereksinimleri

- Her yeni `Bloc` ve `Cubit` sınıfı için `_test.dart` dosyası zorunludur
- Pattern referansı: `packages/flutter_kit_auth/test/manager/auth_manager_test.dart`
- Mock üretimi: `@GenerateMocks([ClassName])` + `dart run build_runner build --delete-conflicting-outputs`
- Her test `group()` içinde organize edilmeli, açıklayıcı test isimleri kullanılmalı
- `provideDummy<Result<T,E>>(...)` Mockito generic type uyarılarını önler

---

## Sorular

Mimari veya pattern hakkında sorularınız için önce şu dosyaları okuyun:
- `CLAUDE.md` — pattern'ların kısa açıklaması
- `docs/ARCHITECTURE.md` — katman diyagramı ve veri akışı
- `docs/RESULT_PATTERN.md` — Result<T,E> quick-start
- Her paketin `README.md`'si
