import 'package:flutter_bloc/flutter_bloc.dart';
import 'base_state.dart';
import 'lifecycle_bloc.dart';

/// Base Bloc - tüm bloc'lar bundan türetilmeli.
///
/// authManager / apiManager burada tutulmaz — paket döngüsünü önlemek için
/// her bloc ihtiyacı olan bağımlılığı kendi constructor'ından alır.
///
/// onReady() BaseBlocView'ın post-frame callback'i tarafından tetiklenir;
/// BaseBloc widget render döngüsünden bağımsız kalır ve unit test'lerde
/// TestWidgetsFlutterBinding gerektirmez.
///
/// Örnek:
/// ```dart
/// class HomeBloc extends BaseBloc<HomeEvent, HomeState> {
///   final HomeRepository repo;
///   HomeBloc(this.repo) : super(const HomeState()) {
///     on<HomeStarted>(_onStarted);
///   }
/// }
/// ```
abstract class BaseBloc<E, S extends BaseState> extends Bloc<E, S>
    implements LifecycleBloc {
  BaseBloc(super.initialState);

  @override
  void onInit() {}

  @override
  void onReady() {}
}
