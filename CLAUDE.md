# CLAUDE.md — Flutter Base Kit Monorepo Guide

This file is prepared for AI assistants and new developers to understand the project codebase quickly.

---

## Project Identity

Flutter monorepo: `flutter_base_kit_workspace`
- Orchestrated via **Pub workspaces** + **Melos**
- 3 flavors: `dev`, `staging`, `prod`
- Main application: `apps/mobile/`
- Shared packages: `packages/flutter_kit_*/`

---

## Package Dependency Graph

```
flutter_kit_core        (independent — BLoC base, validator)
flutter_kit_network     (independent — Dio, interceptors, Result<T,E>)
flutter_kit_ui          (independent — theme, design tokens)
flutter_kit_firebase    (independent — FCM, deep link callback)
flutter_kit_auth        (dependent on network + core)
apps/mobile             (dependent on all 5 packages)
```

**Rule:** `flutter_kit_firebase` → `flutter_kit_auth` dependency is forbidden (circular). Resolved via the deep link routing callback pattern (see below).

---

## Critical Pattern 1: Navigator

Each feature has a `<feature>_navigator.dart` file. This file:
- Contains the `GoRoute` definition
- Exposes the navigation API via a static `show()` method
- Is registered in `AppNavigator.instance`

```dart
// Usage — to open a feature:
DashboardNavigator.show(context);

// Never call context.go('/dashboard') directly —
// the path string must live only in one place (the navigator).
```

`AppNavigator` (singleton): collects all navigators and provides the route list to GoRouter. The `redirect()` method manages the auth guard.

---

## Critical Pattern 2: Result\<T, E\>

From the `flutter_kit_network` package. All async operations return a `Result` instead of throwing exceptions.

```dart
// Correct usage
final result = await getDashboardUseCase();
result.when(
  ok: (summary) => emit(state.copyWith(summary: summary, isLoading: false)),
  err: (error) => emit(state.copyWith(errorMessage: error.message, isLoading: false)),
);

// Common mistake: forgetting to emit in the err branch — the state hangs
result.when(
  ok: (data) => emit(state.copyWith(data: data)),
  err: (_) {},  // ← BUG: isLoading never becomes false
);
```

`ApiError` fields: `statusCode` (nullable int), `message` (String).

Use cases propagate the Result directly — do not wrap them in try/catch:
```dart
@override
Future<Result<DashboardSummary, ApiError>> call() =>
    _repository.getDashboard(); // pass the repository result as is
```

---

## Critical Pattern 3: BaseBloc + BaseBlocView Lifecycle

```
BaseBlocView.initState()
  └── bloc = create()          ← created from the factory
      └── BaseBloc constructor → on<Event> registrations are made

BaseBlocView: post-frame callback
  └── bloc.onReady()           ← initial data loading goes here
      e.g.: add(DashboardLoadRequested())

BaseBlocView.dispose()
  └── bloc.close()             ← stream is cleared
```

`BaseBlocView` both creates the bloc and manages its lifecycle.  
Do not invoke the `Bloc()` constructor inside a widget — always use `BaseBlocView`.

---

## Critical Pattern 4: safeEmit

The `safeEmit(state)` method of `BaseCubit` prevents the `emit()` call from crashing in async callbacks after the cubit is closed.

```dart
// Use safeEmit instead of emit inside a Cubit:
void doSomething() async {
  final result = await someApi();
  safeEmit(state.copyWith(data: result)); // quietly ignores if the cubit is closed
}
```

---

## Critical Pattern 5: DI Module Order

This order is **mandatory** inside `Injection.init()`:

```
1. setupNetworkModule   → FlutterSecureStorage, TokenStore, ApiManager
2. setupAuthModule      → AuthRemoteDataSource, AuthRepository, AuthManager, AuthBloc
                          (requires ApiManager and TokenStore)
3. setupNavigationModule → GoRouter, AppNavigator
                           (requires AuthBloc)
```

If the order is changed, `Object not registered` error is thrown.

---

## Critical Pattern 6: Callback-Based Deep Link

`flutter_kit_firebase` **does not import** GoRouter — doing so would cause a `firebase → navigation → auth → firebase` cycle.

Solution: The `NotificationDeepLinkHandler.onNavigate` static callback is set by the app layer at startup:

```dart
// Inside main_*.dart, after GoRouter is initialized:
NotificationDeepLinkHandler.onNavigate = (path, params) {
  router.go(path, extra: params);
};
```

---

## Critical Pattern 7: ActiveCubitHelper

If the same screen type is open **more than once** in the navigation stack (e.g., two different user profile pages), `activeKey` is used to distinguish the cubit in GetIt.

```dart
// Pass a unique key when opening the screen:
BaseBlocView<ProfileCubit, ProfileState>(
  activeKey: userId,
  create: () => ProfileCubit(userId: userId),
  ...
)

// To access it from another widget:
final cubit = getActive<ProfileCubit>(key: userId);
```

If no key is provided, `_default_ProfileCubit` is used — a single instance of that type is assumed.

---

## Critical Pattern 8: PaginatedBloc

The `PaginatedBloc` mixin is used for infinite-scroll lists. The subclass only implements `fetchPage()` and `paginatedState()`, and the pagination logic is managed by the mixin.

```dart
// Plain BaseBloc is sufficient:
class DashboardBloc extends BaseBloc<DashboardEvent, DashboardState> { ... }

// Add mixin for lists requiring pagination:
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

## Critical Pattern 9: Screen-Specific Widgets (`part of`)

A widget used by **exactly one** screen lives next to it in a `widgets/` folder and joins the screen's library via `part`/`part of`, instead of being a separately imported file. This avoids re-importing the same entities/utils in every tab/section file and makes the "only this screen uses it" relationship explicit.

```dart
// feature_screen.dart — the library file: all imports live here
import 'package:flutter/material.dart';
// ...other imports needed by the screen AND its parts

part 'widgets/feature_about_tab.dart';
part 'widgets/feature_stats_tab.dart';

class FeatureScreen extends StatelessWidget { ... }
```

```dart
// widgets/feature_about_tab.dart — no imports of its own
part of '../feature_screen.dart';

class FeatureAboutTab extends StatelessWidget { ... }
```

See `pokemon_detail/view/pokemon_detail_screen.dart` (+ `view/widgets/*_tab.dart`) and `pokemon_compare/view/compare_screen.dart` (+ `widgets/pokemon_stat_chart.dart`).

**If a widget is used by more than one screen** (e.g. `PokemonCard`, used by both `pokemon_home` and `pokemon_favorites`), it must stay a normal standalone file that gets `import`-ed — never make a widget `part of` a screen it isn't exclusive to.

---

## Test Pattern Summary

```dart
@GenerateMocks([AuthManager, SomeUseCase])
void main() {
  late MockAuthManager mockAuthManager;
  late LoginBloc loginBloc;

  setUp(() {
    // Prevents Mockito generic type warnings:
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

To generate mock files:
```bash
cd apps/mobile
dart run build_runner build --delete-conflicting-outputs
```

---

## File Naming Conventions

| File | Name |
|-------|-----|
| Bloc | `feature_bloc.dart` |
| Event | `feature_event.dart` |
| State | `feature_state.dart` |
| Screen | `feature_screen.dart` |
| Screen-only widget (single consumer) | `widgets/feature_thing.dart`, `part of '../feature_screen.dart'` |
| Navigator | `feature_navigator.dart` |
| Test | `feature_bloc_test.dart` |
| Mocks | `feature_bloc_test.mocks.dart` (auto-generated) |

---

## Melos Commands

```bash
melos bootstrap       # Install dependencies (first setup or pubspec changes)
melos analyze         # Run lint checks in all packages
melos test            # Run tests in all packages
melos format          # Format code
melos format:check    # Check formatting (used in CI, does not modify files)
```

---

## DO NOT List

| Forbidden | Reason |
|-------|-------|
| Calling `context.go('/dashboard')` directly | Path string spreads — use `DashboardNavigator.show(context)` |
| Constructing `Bloc()` inside a widget | `BaseBlocView` manages the lifecycle — always use it |
| Adding `ApiManager` or `AuthManager` as field to `BaseBloc` | Breaks package isolation — inject use case instead |
| Hardcoding path strings in repository impl | Untestable and cannot change by environment — add default param to constructor |
| Importing `auth` or `router` inside `firebase` package | Circular dependency — use callback pattern |
| Calling `emit()` directly in async callbacks | Crash after cubit is closed — use `safeEmit()` |
| Making a widget `part of` a screen it isn't exclusive to | Breaks reuse — widgets used by 2+ screens must stay standalone, `import`-ed files |
