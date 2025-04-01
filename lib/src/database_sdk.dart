import 'package:dio/dio.dart';

import 'models/models.dart';
import 'query/query_builder.dart';

/// The main SDK class for interacting with the ForgeBase database.
///
/// This class provides all the core functionality for interacting with the ForgeBase API,
/// including CRUD operations and query building.
///
/// Example:
/// ```dart
/// final sdk = DatabaseSDK('https://api.example.com');
///
/// // Basic query
/// final users = await sdk
///   .table<Map<String, dynamic>>('users')
///   .where('status', 'active')
///   .execute();
///
/// // Complex query with joins and aggregates
/// final orderStats = await sdk
///   .table<Map<String, dynamic>>('orders')
///   .whereExists((subquery) =>
///     subquery.table('order_items')
///       .where('order_items.order_id', '=', 'orders.id')
///       .where('quantity', '>', 10)
///   )
///   .groupBy(['status'])
///   .having('total_amount', '>', 1000)
///   .sum('amount', 'total_amount')
///   .execute();
/// ```
class DatabaseSDK {
  /// The base URL for the API
  final String baseUrl;

  /// The Dio instance used for making HTTP requests
  final Dio _dio;

  /// Optional interceptors that can be added to the Dio instance
  final List<Interceptor>? interceptors;

  /// Creates a new instance of [DatabaseSDK].
  ///
  /// The [baseUrl] parameter is required and should point to your ForgeBase API endpoint.
  /// You can optionally provide [dioOptions] to customize the Dio client configuration.
  /// Additional [interceptors] can be provided to add custom request/response handling.
  DatabaseSDK(String url, {BaseOptions? dioOptions, this.interceptors})
    : baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url,
      _dio = Dio(dioOptions ?? BaseOptions()) {
    // Configure Dio
    _dio.options.baseUrl = baseUrl;

    // Add any provided interceptors
    if (interceptors != null) {
      _dio.interceptors.addAll(interceptors!);
    }
  }

  /// Gets the base URL for API requests
  String getBaseUrl() => baseUrl;

  /// Gets the default Dio options
  BaseOptions getDefaultOptions() => _dio.options;

  /// Sets default Dio options
  void setDefaultOptions(BaseOptions options) {
    _dio.options = options;
  }

  /// Fetches records from a specified table with filtering and pagination.
  ///
  /// Example:
  /// ```dart
  /// final response = await sdk.getRecords<User>(
  ///   tableName: 'users',
  ///   params: QueryParams(
  ///     filter: {'status': 'active'},
  ///     limit: 10,
  ///   ),
  /// );
  /// ```
  Future<ApiResponse<T>> getRecords<T extends Map<String, dynamic>>({
    required String tableName,
    QueryParams<T>? params,
    QueryOptions? options,
    Options? requestOptions,
  }) async {
    try {
      // Convert query parameters to URL parameters
      final queryParams = _serializeQueryParams(params ?? QueryParams<T>());

      // If execute is false, return only the parameters
      if (options?.execute == false) {
        return ApiResponse<T>(params: params);
      }

      final response = await _dio.get<Map<String, dynamic>>(
        '/$tableName',
        queryParameters: queryParams,
        options: requestOptions,
      );

      return ApiResponse<T>.fromJson(response.data!);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Creates a new record in the specified table.
  ///
  /// Example:
  /// ```dart
  /// final newUser = await sdk.createRecord<User>(
  ///   tableName: 'users',
  ///   data: {
  ///     'email': 'john@example.com',
  ///     'role': 'user',
  ///   },
  /// );
  /// ```
  Future<ApiResponse<T>> createRecord<T extends Map<String, dynamic>>({
    required String tableName,
    required T data,
    Options? options,
  }) async {
    _validateData(data);

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/$tableName',
        data: {'data': data},
        options: options,
      );

      return ApiResponse<T>.fromJson(response.data!);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Updates a record by ID in the specified table.
  ///
  /// Example:
  /// ```dart
  /// final updatedUser = await sdk.updateRecord<User>(
  ///   tableName: 'users',
  ///   id: 1,
  ///   data: {
  ///     'status': 'inactive',
  ///   },
  /// );
  /// ```
  Future<ApiResponse<T>> updateRecord<T extends Map<String, dynamic>>({
    required String tableName,
    required dynamic id,
    required Map<String, dynamic> data,
    Options? options,
  }) async {
    _validateData(data);

    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/$tableName/$id',
        data: {'data': data},
        options: options,
      );

      return ApiResponse<T>.fromJson(response.data!);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Deletes a record by ID from the specified table.
  ///
  /// Example:
  /// ```dart
  /// await sdk.deleteRecord(
  ///   tableName: 'users',
  ///   id: 1,
  /// );
  /// ```
  Future<ApiResponse<Map<String, dynamic>>> deleteRecord({
    required String tableName,
    required dynamic id,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '/$tableName/$id',
        options: options,
      );

      return ApiResponse<Map<String, dynamic>>.fromJson(response.data!);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Creates a query builder for the specified table.
  ///
  /// This is the main entry point for building complex queries.
  ///
  /// Example:
  /// ```dart
  /// final users = await sdk
  ///   .table<Map<String, dynamic>>('users')
  ///   .where('status', 'active')
  ///   .orderBy('lastName', direction: SortDirection.asc)
  ///   .limit(10)
  ///   .execute();
  /// ```
  QueryBuilder<T> table<T extends Map<String, dynamic>>(String tableName) {
    return QueryBuilder<T>(this, tableName);
  }

  /// Validates that the data object is not null or empty
  void _validateData(Map<String, dynamic> data) {
    if (data.isEmpty) {
      throw ForgeBaseException(
        'Invalid data: must be a non-empty object',
        'validation_error',
      );
    }
  }

  /// Converts query parameters to a format that can be sent in the URL
  Map<String, dynamic> _serializeQueryParams<T extends Map<String, dynamic>>(
    QueryParams<T> params,
  ) {
    final serialized = <String, dynamic>{};

    // Convert the params object to JSON
    final paramsJson = params.toJson();

    // Serialize each parameter that is not null
    paramsJson.forEach((key, value) {
      if (value != null) {
        if (value is Map || value is List) {
          serialized[key] = Uri.encodeComponent(value.toString());
        } else {
          serialized[key] = value.toString();
        }
      }
    });

    return serialized;
  }

  /// Handles Dio errors and converts them to ForgeBase exceptions
  ForgeBaseException _handleDioError(DioException error) {
    if (error.response?.data != null && error.response!.data is Map) {
      final data = error.response!.data as Map<String, dynamic>;
      return ForgeBaseException(
        data['error'] ?? error.message ?? 'Unknown error',
        data['code'] ?? 'unknown_error',
        statusCode: error.response?.statusCode,
      );
    }

    return ForgeBaseException(
      error.message ?? 'Unknown error',
      'network_error',
      statusCode: error.response?.statusCode,
    );
  }
}
