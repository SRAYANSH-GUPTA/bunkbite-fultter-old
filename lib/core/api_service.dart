import 'package:dio/dio.dart';
import 'constants.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  late Dio _dio;

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = storageService.getString(AppConstants.authTokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          print(
            'API Request: [${options.method}] ${options.baseUrl}${options.path}',
          );
          print('Headers: ${options.headers}');
          if (options.data != null) print('Body: ${options.data}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
            'API Response: [${response.statusCode}] ${response.requestOptions.path}',
          );
          print('Data: ${response.data}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          print('API Error: ${e.message} at ${e.requestOptions.path}');
          if (e.response != null) {
            print('Error Status: ${e.response?.statusCode}');
            print('Error Data: ${e.response?.data}');
          }
          return handler.next(e);
        },
      ),
    );
  }

  Dio get client => _dio;
}
