import 'package:flutter_test/flutter_test.dart';
import 'package:foodlens_ai_app/auth/auth_action_state.dart';

void main() {
  test('auth action state exposes idle loading success and error phases', () {
    expect(const AuthActionState.idle().phase, AuthActionPhase.idle);

    const loading = AuthActionState.loading('正在處理…');
    expect(loading.phase, AuthActionPhase.loading);
    expect(loading.isLoading, isTrue);
    expect(loading.message, '正在處理…');

    const success = AuthActionState.success('完成。');
    expect(success.phase, AuthActionPhase.success);
    expect(success.isLoading, isFalse);

    const error = AuthActionState.error('失敗。');
    expect(error.phase, AuthActionPhase.error);
    expect(error.isError, isTrue);
  });
}
