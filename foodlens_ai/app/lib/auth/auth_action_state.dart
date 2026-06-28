enum AuthActionPhase { idle, loading, success, error }

class AuthActionState {
  const AuthActionState.idle() : phase = AuthActionPhase.idle, message = null;

  const AuthActionState.loading(this.message) : phase = AuthActionPhase.loading;

  const AuthActionState.success(this.message) : phase = AuthActionPhase.success;

  const AuthActionState.error(this.message) : phase = AuthActionPhase.error;

  final AuthActionPhase phase;
  final String? message;

  bool get isLoading => phase == AuthActionPhase.loading;
  bool get isError => phase == AuthActionPhase.error;
}
