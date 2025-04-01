import 'package:dio/dio.dart';

import '../database_sdk.dart';
import '../models/models.dart';

/// A builder class that provides a fluent API for constructing database queries.
class QueryBuilder<T extends Map<String, dynamic>> {
  /// The query parameters being built
  final _params = _MutableQueryParams<T>();

  /// The current where group being built
  WhereGroup<T>? _currentGroup;

  /// The CTEs to be applied to the query
  final Map<String, CTE<T>> _ctes = {};

  /// The DatabaseSDK instance
  final DatabaseSDK _sdk;

  /// The table name being queried
  final String _tableName;

  /// Creates a new [QueryBuilder] instance.
  QueryBuilder(this._sdk, this._tableName);

  /// Gets the current query parameters
  QueryParams<T> get params => _params.toQueryParams();

  // Helper method to ensure lists are initialized
  void _initList<E>(List<E>? Function() getter, void Function(List<E>) setter) {
    if (getter() == null) {
      setter([]);
    }
  }

  /// Adds a recursive CTE to the query.
  /// Example:
  /// ```dart
  /// db.table('users')
  ///   .withRecursive(
  ///     'user_hierarchy',
  ///     initialQuery,
  ///     recursiveQuery,
  ///     unionAll: true,
  ///     columns: ['id', 'parent_id'],
  ///   )
  ///   .execute();
  /// ```
  QueryBuilder<T> withRecursive(
    String name,
    QueryBuilder<T> initialQuery,
    QueryBuilder<T> recursiveQuery, {
    bool? unionAll,
    List<String>? columns,
  }) {
    _initList(() => _params.recursiveCtes, (v) => _params.recursiveCtes = v);

    final cte = RecursiveCTE<T>(
      name: name,
      initialQuery: initialQuery,
      recursiveQuery: recursiveQuery,
      unionAll: unionAll,
      columns: columns,
    );

    _params.recursiveCtes!.add(cte);
    return this;
  }

  /// Adds an advanced window function to the query.
  /// Example:
  /// ```dart
  /// db.table('users')
  ///   .windowAdvanced(
  ///     WindowFunctionType.rowNumber,
  ///     'row_num',
  ///     over: WindowOver(partitionBy: ['department'], orderBy: [OrderByClause(field: 'id')]),
  ///   )
  ///   .execute();
  /// ```
  QueryBuilder<T> windowAdvanced(
    WindowFunctionType type,
    String alias, {
    String? field,
    WindowOver<T>? over,
    List<WhereClause<T>>? filter,
  }) {
    _initList(
      () => _params.advancedWindows,
      (v) => _params.advancedWindows = v,
    );

    final window = WindowFunctionAdvanced<T>(
      type: type,
      alias: alias,
      field: field,
      over: over,
      filter: filter,
    );

    _params.advancedWindows!.add(window);
    return this;
  }

  /// Adds a window function to the query.
  QueryBuilder<T> window(
    WindowFunctionType type,
    String alias, {
    String? field,
    List<String>? partitionBy,
    List<OrderByClause<T>>? orderBy,
    String? frameClause,
  }) {
    _initList(
      () => _params.windowFunctions,
      (v) => _params.windowFunctions = v,
    );

    final window = WindowFunction<T>(
      type: type,
      alias: alias,
      field: field,
      partitionBy: partitionBy,
      orderBy: orderBy,
      frameClause: frameClause,
    );

    _params.windowFunctions!.add(window);
    return this;
  }

  /// Helper method for row number window function.
  QueryBuilder<T> rowNumber(
    String alias, {
    List<String>? partitionBy,
    List<OrderByClause<T>>? orderBy,
  }) {
    return window(
      WindowFunctionType.rowNumber,
      alias,
      partitionBy: partitionBy,
      orderBy: orderBy,
    );
  }

  /// Helper method for rank window function.
  QueryBuilder<T> rank(
    String alias, {
    List<String>? partitionBy,
    List<OrderByClause<T>>? orderBy,
  }) {
    return window(
      WindowFunctionType.rank,
      alias,
      partitionBy: partitionBy,
      orderBy: orderBy,
    );
  }

  /// Helper method for lag window function.
  QueryBuilder<T> lag(
    String field,
    String alias, {
    List<String>? partitionBy,
    List<OrderByClause<T>>? orderBy,
  }) {
    return window(
      WindowFunctionType.lag,
      alias,
      field: field,
      partitionBy: partitionBy,
      orderBy: orderBy,
    );
  }

  /// Helper method for lead window function.
  QueryBuilder<T> lead(
    String field,
    String alias, {
    List<String>? partitionBy,
    List<OrderByClause<T>>? orderBy,
  }) {
    return window(
      WindowFunctionType.lead,
      alias,
      field: field,
      partitionBy: partitionBy,
      orderBy: orderBy,
    );
  }

  /// Adds a CTE to the query.
  QueryBuilder<T> with_(
    String name,
    dynamic queryOrCallback, {
    List<String>? columns,
  }) {
    QueryBuilder<T> query;

    if (queryOrCallback is Function) {
      query = QueryBuilder<T>(_sdk, _tableName);
      queryOrCallback(query);
    } else {
      query = queryOrCallback as QueryBuilder<T>;
    }

    final cte = CTE<T>(name: name, query: query, columns: columns);

    _ctes[name] = cte;
    _initList(() => _params.ctes, (v) => _params.ctes = v);
    _params.ctes!.add(cte);

    return this;
  }

  /// Transforms the result set.
  QueryBuilder<T> transform(TransformConfig<T> config) {
    _params.transforms = config;
    return this;
  }

  /// Pivots the result set.
  QueryBuilder<T> pivot(
    String column,
    List<String> values,
    AggregateOptions<T> aggregate,
  ) {
    return transform(
      TransformConfig<T>(
        pivot: PivotConfig<T>(
          column: column,
          values: values,
          aggregate: aggregate,
        ),
      ),
    );
  }

  /// Computes new fields from existing ones.
  QueryBuilder<T> compute(
    Map<String, dynamic Function(Map<String, dynamic>)> computations,
  ) {
    return transform(TransformConfig<T>(compute: computations));
  }

  /// Adds a where clause to the query.
  QueryBuilder<T> where(
    dynamic fieldOrConditions, [
    dynamic operatorOrValue,
    dynamic value,
  ]) {
    if (fieldOrConditions is Map<String, dynamic>) {
      _params.filter = {...?_params.filter, ...fieldOrConditions};
    } else if (operatorOrValue is WhereOperator) {
      _initList(() => _params.whereRaw, (v) => _params.whereRaw = v);
      _params.whereRaw!.add(
        WhereClause<T>(
          field: fieldOrConditions as String,
          operator: operatorOrValue,
          value: value,
        ),
      );
    } else {
      _params.filter = {
        ...?_params.filter,
        fieldOrConditions as String: operatorOrValue,
      };
    }
    return this;
  }

  /// Adds a where between clause.
  QueryBuilder<T> whereBetween(String field, List<dynamic> range) {
    _initList(() => _params.whereBetween, (v) => _params.whereBetween = v);
    _params.whereBetween!.add(
      WhereBetweenClause<T>(field: field, value: range),
    );
    return this;
  }

  /// Adds a where in clause.
  QueryBuilder<T> whereIn(String field, List<dynamic> values) {
    _params.whereIn = {...?_params.whereIn, field: values};
    return this;
  }

  /// Adds a where not in clause.
  QueryBuilder<T> whereNotIn(String field, List<dynamic> values) {
    _params.whereNotIn = {...?_params.whereNotIn, field: values};
    return this;
  }

  /// Adds a where null clause.
  QueryBuilder<T> whereNull(String field) {
    _initList(() => _params.whereNull, (v) => _params.whereNull = v);
    _params.whereNull!.add(field);
    return this;
  }

  /// Adds a where not null clause.
  QueryBuilder<T> whereNotNull(String field) {
    _initList(() => _params.whereNotNull, (v) => _params.whereNotNull = v);
    _params.whereNotNull!.add(field);
    return this;
  }

  /// Adds a where exists clause using a subquery
  ///
  /// Example:
  /// ```dart
  /// db.table<User>('users')
  ///   .whereExists((subquery) =>
  ///     subquery.table('orders')
  ///       .where('orders.user_id', '=', 'users.id')
  ///       .where('total', '>', 1000)
  ///   )
  ///   .execute();
  /// ```
  QueryBuilder<T> whereExists(
    QueryBuilder<Map<String, dynamic>> Function(DatabaseSDK) subqueryBuilder,
  ) {
    _initList(() => _params.whereExists, (v) => _params.whereExists = v);

    // Create a new SDK instance for the subquery
    final subquerySdk = DatabaseSDK(_sdk.baseUrl);

    // Get the subquery builder
    final subquery = subqueryBuilder(subquerySdk);

    // Extract the table name and parameters
    _params.whereExists!.add(
      SubQueryConfig(tableName: subquery._tableName, params: subquery.params),
    );

    return this;
  }

  /// Adds a where exists clause with join conditions
  ///
  /// Example:
  /// ```dart
  /// db.table<User>('users')
  ///   .whereExistsJoin(
  ///     'orders',
  ///     'id',
  ///     'user_id',
  ///     (qb) => qb.where('total', '>', 1000),
  ///   )
  ///   .execute();
  /// ```
  QueryBuilder<T> whereExistsJoin(
    String tableName,
    String leftField,
    String rightField,
    void Function(QueryBuilder<dynamic>)? additionalConditions,
  ) {
    _initList(() => _params.whereExists, (v) => _params.whereExists = v);

    // Create a new SDK instance for the subquery
    final subquerySdk = DatabaseSDK(_sdk.baseUrl);

    // Build the subquery
    final subQueryBuilder = subquerySdk.table(tableName);

    // Apply additional conditions if provided
    if (additionalConditions != null) {
      additionalConditions(subQueryBuilder);
    }

    // Add the join condition
    _params.whereExists!.add(
      SubQueryConfig(
        tableName: tableName,
        params: subQueryBuilder.params,
        joinCondition: JoinCondition(
          leftField: leftField,
          operator: WhereOperator.equals,
          rightField: rightField,
        ),
      ),
    );

    return this;
  }

  /// Gets the current table name
  String get tableName => _tableName;

  /// Select specific fields from the table
  ///
  /// Example:
  /// ```dart
  /// db.table('users')
  ///   .select(['id', 'name', 'email'])
  ///   .execute();
  /// ```
  QueryBuilder<T> select(List<String> fields) {
    _params.select = fields;
    return this;
  }

  /// Creates an OR where group
  ///
  /// Example:
  /// ```dart
  /// db.table<User>('users')
  ///   .where('status', 'active')
  ///   .orWhere((query) =>
  ///     query
  ///       .where('role', 'admin')
  ///       .where('department', 'IT')
  ///   )
  ///   .execute();
  /// ```
  QueryBuilder<T> orWhere(void Function(QueryBuilder<T>) callback) {
    return _whereGroup(GroupOperator.or, callback);
  }

  /// Creates an AND where group
  ///
  /// Example:
  /// ```dart
  /// db.table<User>('users')
  ///   .where('status', 'active')
  ///   .andWhere((query) =>
  ///     query
  ///       .where('role', 'admin')
  ///       .where('department', 'IT')
  ///   )
  ///   .execute();
  /// ```
  QueryBuilder<T> andWhere(void Function(QueryBuilder<T>) callback) {
    return _whereGroup(GroupOperator.and, callback);
  }

  /// Creates a where group with the specified operator.
  QueryBuilder<T> _whereGroup(
    GroupOperator operator,
    void Function(QueryBuilder<T>) callback,
  ) {
    final group = WhereGroup<T>(type: operator, clauses: []);

    // Save the current group to restore it after processing the callback
    final previousGroup = _currentGroup;
    _currentGroup = group;

    // Create a new builder for the group to collect clauses
    final groupBuilder = QueryBuilder<T>(_sdk, _tableName);

    // Execute the callback with the group builder
    callback(groupBuilder);

    // If there are filter conditions, convert them to where clauses
    if (groupBuilder._params.filter != null) {
      groupBuilder._params.filter!.forEach((key, value) {
        group.clauses.add(
          WhereClause<T>(
            field: key,
            operator: WhereOperator.equals,
            value: value,
          ),
        );
      });
    }

    // Add all whereRaw clauses to the group
    if (groupBuilder._params.whereRaw != null) {
      group.clauses.addAll(groupBuilder._params.whereRaw!);
    }

    // Add nested groups if any
    if (groupBuilder._params.whereGroups != null) {
      for (final nestedGroup in groupBuilder._params.whereGroups!) {
        group.clauses.add(nestedGroup);
      }
    }

    // Add the group to the parent's whereGroups
    _initList(() => _params.whereGroups, (v) => _params.whereGroups = v);
    _params.whereGroups!.add(group);

    // Restore the previous group
    _currentGroup = previousGroup;

    return this;
  }

  /// Gets the query parameters without executing the query.
  Future<QueryParams<T>> toParams() async {
    final response = await _sdk.getRecords<T>(
      tableName: _tableName,
      params: params,
      options: QueryOptions(execute: false),
    );
    return response.params!;
  }

  /// Adds a raw SQL expression to the query.
  QueryBuilder<T> rawExpression(String sql, [List<dynamic>? bindings]) {
    _initList(() => _params.rawExpressions, (v) => _params.rawExpressions = v);

    _params.rawExpressions!.add(RawExpression(sql: sql, bindings: bindings));
    return this;
  }

  /// Adds a group by clause to the query.
  QueryBuilder<T> groupBy(List<String> fields) {
    _params.groupBy = fields;
    return this;
  }

  /// Adds a having clause to the query for use with group by.
  QueryBuilder<T> having(String field, WhereOperator operator, dynamic value) {
    _initList(() => _params.having, (v) => _params.having = v);
    _params.having!.add(
      HavingClause<T>(field: field, operator: operator, value: value),
    );
    return this;
  }

  /// Adds an aggregate function to the query.
  QueryBuilder<T> aggregate(AggregateType type, String field, {String? alias}) {
    _initList(() => _params.aggregates, (v) => _params.aggregates = v);
    _params.aggregates!.add(
      AggregateOptions<T>(type: type, field: field, alias: alias),
    );
    return this;
  }

  /// Adds a COUNT aggregate function to the query.
  QueryBuilder<T> count(String field, {String? alias}) {
    return aggregate(AggregateType.count, field, alias: alias);
  }

  /// Adds a SUM aggregate function to the query.
  QueryBuilder<T> sum(String field, {String? alias}) {
    return aggregate(AggregateType.sum, field, alias: alias);
  }

  /// Adds an AVG aggregate function to the query.
  QueryBuilder<T> avg(String field, {String? alias}) {
    return aggregate(AggregateType.avg, field, alias: alias);
  }

  /// Adds a MIN aggregate function to the query.
  QueryBuilder<T> min(String field, {String? alias}) {
    return aggregate(AggregateType.min, field, alias: alias);
  }

  /// Adds a MAX aggregate function to the query.
  QueryBuilder<T> max(String field, {String? alias}) {
    return aggregate(AggregateType.max, field, alias: alias);
  }

  /// Adds an order by clause to the query.
  QueryBuilder<T> orderBy(
    String field, {
    SortDirection? direction,
    NullsPosition? nulls,
  }) {
    _initList(() => _params.orderBy, (v) => _params.orderBy = v);

    final clause = OrderByClause<T>(
      field: field,
      direction: direction,
      nulls: nulls,
    );

    _params.orderBy!.add(clause);
    return this;
  }

  /// Sets the limit for the query.
  QueryBuilder<T> limit(int limit) {
    _params.limit = limit;
    return this;
  }

  /// Sets the offset for the query.
  QueryBuilder<T> offset(int offset) {
    _params.offset = offset;
    return this;
  }

  /// Executes the query with optional transforms.
  Future<ApiResponse<T>> execute([Options? options]) async {
    final response = await _sdk.getRecords<T>(
      tableName: _tableName,
      params: params,
      options: QueryOptions(execute: true),
      requestOptions: options,
    );

    return response;
  }

  /// Creates a new record.
  Future<ApiResponse<T>> create(T data, [Options? options]) async {
    return _sdk.createRecord<T>(
      tableName: _tableName,
      data: data,
      options: options,
    );
  }

  /// Updates a record by ID.
  Future<ApiResponse<T>> update(
    dynamic id,
    Map<String, dynamic> data, [
    Options? options,
  ]) async {
    return _sdk.updateRecord<T>(
      tableName: _tableName,
      id: id,
      data: data,
      options: options,
    );
  }

  /// Deletes a record by ID.
  Future<ApiResponse<void>> delete(dynamic id, [Options? options]) async {
    return _sdk.deleteRecord(tableName: _tableName, id: id, options: options);
  }
}

/// Internal class for handling mutable query parameters
class _MutableQueryParams<T extends Map<String, dynamic>> {
  Map<String, dynamic>? filter;
  List<WhereClause<T>>? whereRaw;
  List<WhereBetweenClause<T>>? whereBetween;
  List<String>? whereNull;
  List<String>? whereNotNull;
  Map<String, List<dynamic>>? whereIn;
  Map<String, List<dynamic>>? whereNotIn;
  List<SubQueryConfig>? whereExists;
  List<WhereGroup<T>>? whereGroups;
  List<OrderByClause<T>>? orderBy;
  List<String>? groupBy;
  List<HavingClause<T>>? having;
  List<AggregateOptions<T>>? aggregates;
  List<RawExpression>? rawExpressions;
  int? limit;
  int? offset;
  List<WindowFunction<T>>? windowFunctions;
  List<CTE<T>>? ctes;
  TransformConfig<T>? transforms;
  ExplainOptions? explain;
  List<RecursiveCTE<T>>? recursiveCtes;
  List<WindowFunctionAdvanced<T>>? advancedWindows;
  List<String>? select;

  /// Converts the mutable parameters to an immutable QueryParams instance
  QueryParams<T> toQueryParams() {
    return QueryParams<T>(
      filter: filter,
      whereRaw: whereRaw,
      whereBetween: whereBetween,
      whereNull: whereNull,
      whereNotNull: whereNotNull,
      whereIn: whereIn,
      whereNotIn: whereNotIn,
      whereExists: whereExists,
      whereGroups: whereGroups,
      orderBy: orderBy,
      groupBy: groupBy,
      having: having,
      aggregates: aggregates,
      rawExpressions: rawExpressions,
      limit: limit,
      offset: offset,
      windowFunctions: windowFunctions,
      ctes: ctes,
      transforms: transforms,
      explain: explain,
      recursiveCtes: recursiveCtes,
      advancedWindows: advancedWindows,
      select: select,
    );
  }
}
