import 'package:roamly_auth/src/data/api/auth_api_paths.dart';
import 'package:roamly_networking/roamly_networking.dart';

import '../../domain/entities/auth_device.dart';
import '../models/authentication_response_model.dart';
import 'auth_remote_data_source.dart';

final class ApiAuthRemoteDataSource implements AuthRemoteDataSource {
  final ApiClient _publicClient;
  final ApiClient _authenticatedClient;

  ApiAuthRemoteDataSource({
    required ApiClient publicClient,
    required ApiClient authenticatedClient,
  }) : _publicClient = publicClient,
       _authenticatedClient = authenticatedClient;

  @override
  Future<AuthenticationResponseModel> login({
    required String email,
    required String password,
    required AuthDevice device,
  }) async {
    final data = await _publicClient.post(
      AuthApiPaths.login,
      data: _credentialsPayload(
        email: email,
        password: password,
        device: device,
      ),
    );
    return _authenticationResponse(data: data);
  }

  @override
  Future<void> logout() async {
    await _authenticatedClient.post(AuthApiPaths.logout);
  }

  @override
  Future<AuthenticationResponseModel> refresh({
    required String refreshToken,
  }) async {
    final data = _publicClient.post(
      AuthApiPaths.register,
      data: <String, Object?>{'refresh_token': refreshToken},
    );
    return _authenticationResponse(data: data);
  }

  @override
  Future<AuthenticationResponseModel> register({
    required String email,
    required String password,
    required AuthDevice device,
  }) async {
    final data = _publicClient.post(
      AuthApiPaths.register,
      data: _credentialsPayload(
        email: email,
        password: password,
        device: device,
      ),
    );
    return _authenticationResponse(data: data);
  }

  static AuthenticationResponseModel _authenticationResponse({Object? data}) {
    if (data is! Map) {
      throw const FormatException(
        'Authentication response must be a JSON object',
      );
    }
    return AuthenticationResponseModel.fromJson(
      Map<String, Object?>.from(data),
    );
  }

  static Map<String, Object?> _credentialsPayload({
    required String email,
    required String password,
    required AuthDevice device,
  }) {
    return <String, Object?>{
      'email': email,
      'password': password,
      'device_id': device.id,
      if (device.name != null) 'device_name': device.name,
    };
  }
}
