# CLAUDE.md — SaloonManager App Codebase Guide

Bu dosya AI asistanların ve yeni geliştiricilerin projeyi hızlıca anlaması için hazırlanmıştır.

---

## Proje Kimliği

Flutter monorepo: `flutter_base_kit_workspace`
- **Pub workspaces** + **Melos** ile orchestrate edilir
- 3 flavor: `dev`, `staging`, `prod`
- Ana uygulama: `apps/mobile/`
- Paylaşılan paketler: `packages/flutter_kit_*/`

---

## Paket Bağımlılık Grafiği

```
flutter_kit_core        (bağımsız — BLoC base, validator)
flutter_kit_network     (bağımsız — Dio, interceptors, Result<T,E>)
flutter_kit_ui          (bağımsız — tema, design tokens)
flutter_kit_firebase    (bağımsız — FCM, deep link callback)
flutter_kit_auth        (network + core'a bağımlı)
apps/mobile             (5 paketin hepsine bağımlı)
```

**Kural:** `flutter_kit_firebase` → `flutter_kit_auth` bağımlılığı yasak (circular). Deep link routing callback pattern ile çözülür (aşağıya bak).

---

## Kritik Pattern 1: Coordinator

Her feature, `<feature>_coordinator.dart` dosyasına sahiptir. Bu dosya:
- `GoRoute` tanımını içerir
- `show()` static metoduyla navigation API'si sunar
- `AppCoordinator.instance`'a kaydedilir

```dart
// Kullanım — feature'ı açmak için:
DashboardCoordinator.show(context);

// Asla doğrudan context.go('/dashboard') çağırma —
// path string'i tek bir yerde (coordinator'da) yaşamalı.
```

`AppCoordinator` (singleton): tüm coordinator'ları toplar ve GoRouter'a route listesini verir. `redirect()` metodu auth guard'ı yönetir.

---

## Kritik Pattern 2: Result\<T, E\>

`flutter_kit_network` paketinden. Tüm async operasyonlar exception fırlatmak yerine `Result` döner.

```dart
// Doğru kullanım
final result = await getDashboardUseCase();
result.when(
  ok: (summary) => emit(state.copyWith(summary: summary, isLoading: false)),
  err: (error) => emit(state.copyWith(errorMessage: error.message, isLoading: false)),
);

// Yaygın hata: err branch'te emit unutmak — state askıda kalır
result.when(
  ok: (data) => emit(state.copyWith(data: data)),
  err: (_) {},  // ← BUG: isLoading asla false olmaz
);
```

`ApiError` alanları: `statusCode` (nullable int), `message` (String).

Use case'ler Result'ı doğrudan propagate eder — try/catch sarmaz:
```dart
@override
Future<Result<DashboardSummary, ApiError>> call() =>
    _repository.getDashboard(); // repository sonucu aynen geçir
```

---

## Kritik Pattern 3: BaseBloc + BaseBlocView Lifecycle

```
BaseBlocView.initState()
  └── bloc = create()          ← factory'den oluşturulur
      └── BaseBloc constructor → on<Event> kayıtları yapılır

BaseBlocView: post-frame callback
  └── bloc.onReady()           ← ilk veri yükleme buraya
      örn: add(DashboardLoadRequested())

BaseBlocView.dispose()
  └── bloc.close()             ← stream temizlenir
```

`BaseBlocView`, blocu hem oluşturur hem de lifecycle'ını yönetir.  
Widget içinde `Bloc()` constructor çağırma — her zaman `BaseBlocView` kullan.

---

## Kritik Pattern 4: safeEmit

`BaseCubit`'in `safeEmit(state)` metodu, cubit kapatıldıktan sonra gelen async callback'lerde `emit()` çağrısının crash yapmasını önler.

```dart
// Cubit içinde emit yerine safeEmit kullan:
void doSomething() async {
  final result = await someApi();
  safeEmit(state.copyWith(data: result)); // cubit kapandıysa sessizce ignore eder
}
```

---

## Kritik Pattern 5: DI Modül Sırası

`Injection.init()` içinde bu sıra **zorunludur**:

```
1. setupNetworkModule   → FlutterSecureStorage, TokenStore, ApiManager
2. setupAuthModule      → AuthRemoteDataSource, AuthRepository, AuthManager, AuthBloc
                          (ApiManager ve TokenStore'a ihtiyaç duyar)
3. setupNavigationModule → GoRouter, AuthRouterNotifier
                           (AuthBloc'a ihtiyaç duyar)
```

Sıra değişirse `Object not registered` hatası alınır.

---

## Kritik Pattern 6: Callback-Based Deep Link

`flutter_kit_firebase`, GoRouter'ı **import etmez** — import etseydi `firebase → navigation → auth → firebase` döngüsü oluşurdu.

Çözüm: `NotificationDeepLinkHandler.onNavigate` statik callback, uygulama başlangıcında app layer tarafından set edilir:

```dart
// main_*.dart içinde, GoRouter kurulduktan sonra:
NotificationDeepLinkHandler.onNavigate = (path, params) {
  router.go(path, extra: params);
};
```

---

## Kritik Pattern 7: ActiveCubitHelper

Aynı screen türü navigation stack'te **ikiden fazla** açıksa (örn: iki farklı kullanıcı profil sayfası), cubit'i GetIt'te ayırt etmek için `activeKey` kullanılır.

```dart
// Screen'i açarken unique key ver:
BaseBlocView<ProfileCubit, ProfileState>(
  activeKey: userId,
  create: () => ProfileCubit(userId: userId),
  ...
)

// Başka bir widget'tan erişmek için:
final cubit = getActive<ProfileCubit>(key: userId);
```

Key verilmezse `_default_ProfileCubit` kullanılır — aynı tipten tek instance varsayılır.

---

## Kritik Pattern 8: PaginatedBloc

Infinite-scroll listeler için `PaginatedBloc` mixin'i kullanılır. Subclass sadece `fetchPage()` ve `paginatedState()` implement eder, pagination logic'i mixin tarafından yönetilir.

```dart
// Düz BaseBloc yeter:
class DashboardBloc extends BaseBloc<DashboardEvent, DashboardState> { ... }

// Sayfalama gereken listeler için mixin ekle:
class AppointmentBloc extends BaseBloc<AppointmentEvent, AppointmentState>
    with PaginatedBloc<Appointment, AppointmentEvent, AppointmentState> {

  @override
  Future<(List<Appointment>, bool, int)> fetchPage(int offset, int size) =>
      _useCase(offset: offset, size: size);

  @override
  AppointmentState paginatedState({...}) => state.copyWith(...);
}
```

---

## Test Pattern Özeti

```dart
@GenerateMocks([AuthManager, SomeUseCase])
void main() {
  late MockAuthManager mockAuthManager;
  late LoginBloc loginBloc;

  setUp(() {
    // Mockito generic type uyarısını önler:
    provideDummy<Result<AuthTokens, ApiError>>(
      Ok(AuthTokens(accessToken: '', refreshToken: null)),
    );
    mockAuthManager = MockAuthManager();
    loginBloc = LoginBloc(authManager: mockAuthManager);
  });

  tearDown(() async => loginBloc.close());

  group('LoginSubmitted — success', () {
    test('emits isLoading then isSuccess', () async {
      when(mockAuthManager.login(any, any))
          .thenAnswer((_) async => Ok(AuthTokens(...)));
      // ...
    });
  });
}
```

Mock dosyaları üretmek için:
```bash
cd apps/mobile
dart run build_runner build --delete-conflicting-outputs
```

---

## Dosya Adlandırma Sözleşmeleri

| Dosya | Adı |
|-------|-----|
| Bloc | `feature_bloc.dart` |
| Event | `feature_event.dart` |
| State | `feature_state.dart` |
| Screen | `feature_screen.dart` |
| Coordinator | `feature_coordinator.dart` |
| Test | `feature_bloc_test.dart` |
| Mocks | `feature_bloc_test.mocks.dart` (auto-generated) |

---

## Melos Komutları

```bash
melos bootstrap       # Bağımlılıkları kur (ilk kurulum veya pubspec değişikliği)
melos analyze         # Tüm paketlerde lint kontrolü
melos test            # Tüm paketlerde testleri çalıştır
melos format          # Kodu formatla
melos format:check    # Format kontrolü (CI'da kullanılır, dosya değiştirmez)
```

---

## YAPMA Listesi

| Yasak | Neden |
|-------|-------|
| `context.go('/dashboard')` doğrudan çağırma | Path string'i dağılır — `DashboardCoordinator.show(context)` kullan |
| Widget içinde `Bloc()` construct etme | `BaseBlocView` lifecycle'ı yönetir — her zaman onu kullan |
| `ApiManager` veya `AuthManager`'ı `BaseBloc`'a field eklemek | Paket izolasyonunu bozar — use case inject et |
| Repository impl'e path string hard-code etmek | Test edilemez ve ortama göre değişemez — constructor'a default param ekle |
| `firebase` paketinde `auth` veya `router` import etmek | Circular dependency — callback pattern kullan |
| Async callback'te `emit()` doğrudan çağırmak | Cubit kapandıktan sonra crash — `safeEmit()` kullan |
