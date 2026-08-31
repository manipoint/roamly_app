import '../../domain/entities/auth_device.dart';
import '../models/authentication_response_model.dart';

/// Performs authentication operations against the remote API.
abstract interface class AuthRemoteDataSource {
  Future<AuthenticationResponseModel> register({
    required String email,
    required String password,
    required AuthDevice device,
  });

  Future<AuthenticationResponseModel> login({
    required String email,
    required String password,
    required AuthDevice device,
  });

  Future<AuthenticationResponseModel> refresh({required String refreshToken});

  Future<void> logout();
}
