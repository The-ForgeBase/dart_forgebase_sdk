import '../../forgebase_sdk.dart';

/// Defines the available operators for where clauses
enum WhereOperator {
  equals('='),
  notEquals('!='),
  greaterThan('>'),
  greaterThanOrEqual('>='),
  lessThan('<'),
  lessThanOrEqual('<='),
  like('like'),
  in_('in'),
  notIn('not in'),
  between('between'),
  isNull('is null'),
  isNotNull('is not null');

  final String operator;
  const WhereOperator(this.operator);
}

/// Defines the logical operators for combining where clauses
enum GroupOperator {
  and('AND'),
  or('OR');

  final String operator;
  const GroupOperator(this.operator);
}

/// Configuration for subqueries in where exists clauses
class SubQueryConfig {
  final String tableName;
  final QueryParams params;
  final JoinCondition? joinCondition;

  const SubQueryConfig({
    required this.tableName,
    required this.params,
    this.joinCondition,
  });

  Map<String, dynamic> toJson() => {
    'tableName': tableName,
    'params': params.toJson(),
    if (joinCondition != null) 'joinCondition': joinCondition!.toJson(),
  };

  factory SubQueryConfig.fromJson(Map<String, dynamic> json) {
    return SubQueryConfig(
      tableName: json['tableName'] as String,
      params: QueryParams.fromJson(json['params'] as Map<String, dynamic>),
      joinCondition:
          json['joinCondition'] != null
              ? JoinCondition.fromJson(
                json['joinCondition'] as Map<String, dynamic>,
              )
              : null,
    );
  }
}

/// Join condition for subqueries
class JoinCondition {
  final String leftField;
  final WhereOperator operator;
  final String rightField;

  const JoinCondition({
    required this.leftField,
    required this.operator,
    required this.rightField,
  });

  Map<String, dynamic> toJson() => {
    'leftField': leftField,
    'operator': operator.operator,
    'rightField': rightField,
  };

  factory JoinCondition.fromJson(Map<String, dynamic> json) {
    return JoinCondition(
      leftField: json['leftField'] as String,
      operator: WhereOperatorFromString.fromString(json['operator'] as String),
      rightField: json['rightField'] as String,
    );
  }
}

/// A where clause for filtering data
class WhereClause<T> {
  final String field;
  final WhereOperator operator;
  final dynamic value;
  final GroupOperator? boolean;

  const WhereClause({
    required this.field,
    required this.operator,
    required this.value,
    this.boolean,
  });

  Map<String, dynamic> toJson() => {
    'field': field,
    'operator': operator.operator,
    'value': value,
    if (boolean != null) 'boolean': boolean!.operator,
  };

  factory WhereClause.fromJson(Map<String, dynamic> json) {
    return WhereClause<T>(
      field: json['field'] as String,
      operator: WhereOperatorFromString.fromString(json['operator'] as String),
      value: json['value'],
      boolean:
          json['boolean'] != null
              ? GroupOperatorFromString.fromString(json['boolean'] as String)
              : null,
    );
  }
}

/// A group of where clauses combined with a logical operator
class WhereGroup<T> {
  final GroupOperator type;
  final List<dynamic>
  clauses; // Updated to accept both WhereClause<T> and WhereGroup<T>

  const WhereGroup({required this.type, required this.clauses});

  Map<String, dynamic> toJson() => {
    'type': type.operator,
    'clauses': clauses.map((c) => c.toJson()).toList(),
  };

  factory WhereGroup.fromJson(Map<String, dynamic> json) {
    return WhereGroup<T>(
      type: GroupOperatorFromString.fromString(json['type'] as String),
      clauses:
          (json['clauses'] as List).map((c) {
            if (c['type'] != null) {
              return WhereGroup<T>.fromJson(c as Map<String, dynamic>);
            } else {
              return WhereClause<T>.fromJson(c as Map<String, dynamic>);
            }
          }).toList(),
    );
  }
}

/// A where between clause for range filtering
class WhereBetweenClause<T> {
  final String field;
  final List<dynamic> value;
  final GroupOperator? boolean;

  const WhereBetweenClause({
    required this.field,
    required this.value,
    this.boolean,
  });

  Map<String, dynamic> toJson() => {
    'field': field,
    'operator': 'between',
    'value': value,
    if (boolean != null) 'boolean': boolean!.operator,
  };

  factory WhereBetweenClause.fromJson(Map<String, dynamic> json) {
    return WhereBetweenClause<T>(
      field: json['field'] as String,
      value: json['value'] as List<dynamic>,
      boolean:
          json['boolean'] != null
              ? GroupOperatorFromString.fromString(json['boolean'] as String)
              : null,
    );
  }
}

/// Defines the sort direction for orderBy clauses
enum SortDirection {
  asc('asc'),
  desc('desc');

  final String value;
  const SortDirection(this.value);
}

/// Defines how nulls should be sorted
enum NullsPosition {
  first('first'),
  last('last');

  final String value;
  const NullsPosition(this.value);
}

/// An order by clause for sorting data
class OrderByClause<T> {
  final String field;
  final SortDirection? direction;
  final NullsPosition? nulls;

  const OrderByClause({required this.field, this.direction, this.nulls});

  Map<String, dynamic> toJson() => {
    'field': field,
    if (direction != null) 'direction': direction!.value,
    if (nulls != null) 'nulls': nulls!.value,
  };

  factory OrderByClause.fromJson(Map<String, dynamic> json) {
    return OrderByClause<T>(
      field: json['field'] as String,
      direction:
          json['direction'] != null
              ? SortDirection.values.firstWhere(
                (e) => e.value == json['direction'],
              )
              : null,
      nulls:
          json['nulls'] != null
              ? NullsPosition.values.firstWhere((e) => e.value == json['nulls'])
              : null,
    );
  }
}

/// A raw SQL expression with optional bindings
class RawExpression {
  final String sql;
  final List<dynamic>? bindings;

  const RawExpression({required this.sql, this.bindings});

  Map<String, dynamic> toJson() => {
    'sql': sql,
    if (bindings != null) 'bindings': bindings,
  };

  factory RawExpression.fromJson(Map<String, dynamic> json) {
    return RawExpression(
      sql: json['sql'] as String,
      bindings: json['bindings'] as List<dynamic>?,
    );
  }
}

/// A having clause for filtering grouped data
class HavingClause<T> {
  final String field;
  final WhereOperator operator;
  final dynamic value;

  const HavingClause({
    required this.field,
    required this.operator,
    required this.value,
  });

  Map<String, dynamic> toJson() => {
    'field': field,
    'operator': operator.operator,
    'value': value,
  };

  factory HavingClause.fromJson(Map<String, dynamic> json) {
    return HavingClause<T>(
      field: json['field'] as String,
      operator: WhereOperatorFromString.fromString(json['operator'] as String),
      value: json['value'],
    );
  }
}

/// The type of aggregate function to apply
enum AggregateType {
  count('count'),
  sum('sum'),
  avg('avg'),
  min('min'),
  max('max');

  final String type;
  const AggregateType(this.type);
}

/// Options for aggregate functions
class AggregateOptions<T> {
  final AggregateType type;
  final String field;
  final String? alias;

  const AggregateOptions({required this.type, required this.field, this.alias});

  Map<String, dynamic> toJson() => {
    'type': type.type,
    'field': field,
    if (alias != null) 'alias': alias,
  };

  factory AggregateOptions.fromJson(Map<String, dynamic> json) {
    return AggregateOptions<T>(
      type: AggregateType.values.firstWhere((e) => e.type == json['type']),
      field: json['field'] as String,
      alias: json['alias'] as String?,
    );
  }
}

/// The type of window function to apply
enum WindowFunctionType {
  rowNumber('row_number'),
  rank('rank'),
  denseRank('dense_rank'),
  lag('lag'),
  lead('lead'),
  firstValue('first_value'),
  lastValue('last_value'),
  sum('sum'),
  avg('avg'),
  count('count'),
  min('min'),
  max('max'),
  nthValue('nth_value'),
  ntile('ntile');

  final String type;
  const WindowFunctionType(this.type);
}

/// Configuration for window functions
class WindowFunction<T> {
  final WindowFunctionType type;
  final String? field;
  final String alias;
  final List<String>? partitionBy;
  final List<OrderByClause<T>>? orderBy;
  final String? frameClause;

  const WindowFunction({
    required this.type,
    this.field,
    required this.alias,
    this.partitionBy,
    this.orderBy,
    this.frameClause,
  });

  Map<String, dynamic> toJson() => {
    'type': type.type,
    if (field != null) 'field': field,
    'alias': alias,
    if (partitionBy != null) 'partitionBy': partitionBy,
    if (orderBy != null) 'orderBy': orderBy!.map((o) => o.toJson()).toList(),
    if (frameClause != null) 'frameClause': frameClause,
  };

  factory WindowFunction.fromJson(Map<String, dynamic> json) {
    return WindowFunction<T>(
      type: WindowFunctionType.values.firstWhere((e) => e.type == json['type']),
      field: json['field'] as String?,
      alias: json['alias'] as String,
      partitionBy: (json['partitionBy'] as List?)?.cast<String>(),
      orderBy:
          (json['orderBy'] as List?)
              ?.map((o) => OrderByClause<T>.fromJson(o as Map<String, dynamic>))
              .toList(),
      frameClause: json['frameClause'] as String?,
    );
  }
}

/// A Common Table Expression (CTE)
class CTE<T extends Map<String, dynamic>> {
  final String name;
  final QueryBuilder<T> query;
  final List<String>? columns;

  const CTE({required this.name, required this.query, this.columns});

  Map<String, dynamic> toJson() => {
    'name': name,
    'query': query,
    if (columns != null) 'columns': columns,
  };

  factory CTE.fromJson(Map<String, dynamic> json) {
    return CTE<T>(
      name: json['name'] as String,
      query: json['query'],
      columns: (json['columns'] as List?)?.cast<String>(),
    );
  }
}

/// Configuration for transforming query results
class TransformConfig<T> {
  final List<String>? groupBy;
  final PivotConfig<T>? pivot;
  final bool? flatten;
  final List<String>? select;
  final Map<String, dynamic Function(Map<String, dynamic>)>? compute;

  const TransformConfig({
    this.groupBy,
    this.pivot,
    this.flatten,
    this.select,
    this.compute,
  });

  Map<String, dynamic> toJson() => {
    if (groupBy != null) 'groupBy': groupBy,
    if (pivot != null) 'pivot': pivot!.toJson(),
    if (flatten != null) 'flatten': flatten,
    if (select != null) 'select': select,
  };

  factory TransformConfig.fromJson(Map<String, dynamic> json) {
    return TransformConfig<T>(
      groupBy: (json['groupBy'] as List?)?.cast<String>(),
      pivot:
          json['pivot'] != null
              ? PivotConfig<T>.fromJson(json['pivot'] as Map<String, dynamic>)
              : null,
      flatten: json['flatten'] as bool?,
      select: (json['select'] as List?)?.cast<String>(),
    );
  }
}

/// Configuration for pivot transformations
class PivotConfig<T> {
  final String column;
  final List<String> values;
  final AggregateOptions<T> aggregate;

  const PivotConfig({
    required this.column,
    required this.values,
    required this.aggregate,
  });

  Map<String, dynamic> toJson() => {
    'column': column,
    'values': values,
    'aggregate': aggregate.toJson(),
  };

  factory PivotConfig.fromJson(Map<String, dynamic> json) {
    return PivotConfig<T>(
      column: json['column'] as String,
      values: (json['values'] as List).cast<String>(),
      aggregate: AggregateOptions<T>.fromJson(
        json['aggregate'] as Map<String, dynamic>,
      ),
    );
  }
}

/// Options for EXPLAIN queries
class ExplainOptions {
  final bool? analyze;
  final bool? verbose;
  final String? format;

  const ExplainOptions({this.analyze, this.verbose, this.format});

  Map<String, dynamic> toJson() => {
    if (analyze != null) 'analyze': analyze,
    if (verbose != null) 'verbose': verbose,
    if (format != null) 'format': format,
  };

  factory ExplainOptions.fromJson(Map<String, dynamic> json) {
    return ExplainOptions(
      analyze: json['analyze'] as bool?,
      verbose: json['verbose'] as bool?,
      format: json['format'] as String?,
    );
  }
}

/// A recursive Common Table Expression (CTE)
class RecursiveCTE<T extends Map<String, dynamic>> extends CTE<T> {
  final bool isRecursive = true;
  final QueryBuilder<T> initialQuery;
  final QueryBuilder<T> recursiveQuery;
  final bool? unionAll;

  const RecursiveCTE({
    required super.name,
    required this.initialQuery,
    required this.recursiveQuery,
    super.columns,
    this.unionAll,
  }) : super(query: initialQuery);

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'isRecursive': isRecursive,
    'initialQuery': initialQuery,
    'recursiveQuery': recursiveQuery,
    if (unionAll != null) 'unionAll': unionAll,
  };

  factory RecursiveCTE.fromJson(Map<String, dynamic> json) {
    return RecursiveCTE<T>(
      name: json['name'] as String,
      initialQuery: json['initialQuery'],
      recursiveQuery: json['recursiveQuery'],
      columns: (json['columns'] as List?)?.cast<String>(),
      unionAll: json['unionAll'] as bool?,
    );
  }
}

/// Advanced window function configuration
class WindowFunctionAdvanced<T> extends WindowFunction<T> {
  final WindowOver<T>? over;
  final List<WhereClause<T>>? filter;

  const WindowFunctionAdvanced({
    required super.type,
    super.field,
    required super.alias,
    this.over,
    this.filter,
  });

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    if (over != null) 'over': over!.toJson(),
    if (filter != null) 'filter': filter!.map((f) => f.toJson()).toList(),
  };

  factory WindowFunctionAdvanced.fromJson(Map<String, dynamic> json) {
    return WindowFunctionAdvanced<T>(
      type: WindowFunctionType.values.firstWhere((e) => e.type == json['type']),
      field: json['field'] as String?,
      alias: json['alias'] as String,
      over:
          json['over'] != null
              ? WindowOver<T>.fromJson(json['over'] as Map<String, dynamic>)
              : null,
      filter:
          (json['filter'] as List?)
              ?.map((f) => WhereClause<T>.fromJson(f as Map<String, dynamic>))
              .toList(),
    );
  }
}

/// Window function OVER clause configuration
class WindowOver<T> {
  final List<String>? partitionBy;
  final List<OrderByClause<T>>? orderBy;
  final WindowFrame? frame;

  const WindowOver({this.partitionBy, this.orderBy, this.frame});

  Map<String, dynamic> toJson() => {
    if (partitionBy != null) 'partitionBy': partitionBy,
    if (orderBy != null) 'orderBy': orderBy!.map((o) => o.toJson()).toList(),
    if (frame != null) 'frame': frame!.toJson(),
  };

  factory WindowOver.fromJson(Map<String, dynamic> json) {
    return WindowOver<T>(
      partitionBy: (json['partitionBy'] as List?)?.cast<String>(),
      orderBy:
          (json['orderBy'] as List?)
              ?.map((o) => OrderByClause<T>.fromJson(o as Map<String, dynamic>))
              .toList(),
      frame:
          json['frame'] != null
              ? WindowFrame.fromJson(json['frame'] as Map<String, dynamic>)
              : null,
    );
  }
}

/// Window function frame configuration
class WindowFrame {
  final String type;
  final dynamic start;
  final dynamic end;

  const WindowFrame({required this.type, required this.start, this.end});

  Map<String, dynamic> toJson() => {
    'type': type,
    'start': start,
    if (end != null) 'end': end,
  };

  factory WindowFrame.fromJson(Map<String, dynamic> json) {
    return WindowFrame(
      type: json['type'] as String,
      start: json['start'],
      end: json['end'],
    );
  }
}

/// Query cache configuration
class CacheConfig<T extends Map<String, dynamic>> {
  final int ttl;
  final String? key;
  final List<String>? tags;
  final bool Function(QueryParams<T>)? condition;

  const CacheConfig({required this.ttl, this.key, this.tags, this.condition});

  Map<String, dynamic> toJson() => {
    'ttl': ttl,
    if (key != null) 'key': key,
    if (tags != null) 'tags': tags,
  };

  factory CacheConfig.fromJson(Map<String, dynamic> json) {
    return CacheConfig<T>(
      ttl: json['ttl'] as int,
      key: json['key'] as String?,
      tags: (json['tags'] as List?)?.cast<String>(),
    );
  }
}

/// Query validation rules
class QueryValidation {
  final ValidationRules? rules;
  final bool? suggestions;

  const QueryValidation({this.rules, this.suggestions});

  Map<String, dynamic> toJson() => {
    if (rules != null) 'rules': rules!.toJson(),
    if (suggestions != null) 'suggestions': suggestions,
  };

  factory QueryValidation.fromJson(Map<String, dynamic> json) {
    return QueryValidation(
      rules:
          json['rules'] != null
              ? ValidationRules.fromJson(json['rules'] as Map<String, dynamic>)
              : null,
      suggestions: json['suggestions'] as bool?,
    );
  }
}

/// Rules for query validation
class ValidationRules {
  final int? maxLimit;
  final List<String>? requiredFields;
  final List<String>? disallowedFields;
  final int? maxComplexity;

  const ValidationRules({
    this.maxLimit,
    this.requiredFields,
    this.disallowedFields,
    this.maxComplexity,
  });

  Map<String, dynamic> toJson() => {
    if (maxLimit != null) 'maxLimit': maxLimit,
    if (requiredFields != null) 'requiredFields': requiredFields,
    if (disallowedFields != null) 'disallowedFields': disallowedFields,
    if (maxComplexity != null) 'maxComplexity': maxComplexity,
  };

  factory ValidationRules.fromJson(Map<String, dynamic> json) {
    return ValidationRules(
      maxLimit: json['maxLimit'] as int?,
      requiredFields: (json['requiredFields'] as List?)?.cast<String>(),
      disallowedFields: (json['disallowedFields'] as List?)?.cast<String>(),
      maxComplexity: json['maxComplexity'] as int?,
    );
  }
}

/// Parameters for querying data
class QueryParams<T extends Map<String, dynamic>> {
  final Map<String, dynamic>? filter;
  final List<WhereClause<T>>? whereRaw;
  final List<WhereBetweenClause<T>>? whereBetween;
  final List<String>? whereNull;
  final List<String>? whereNotNull;
  final Map<String, List<dynamic>>? whereIn;
  final Map<String, List<dynamic>>? whereNotIn;
  final List<SubQueryConfig>? whereExists;
  final List<WhereGroup<T>>? whereGroups;
  final List<OrderByClause<T>>? orderBy;
  final List<String>? groupBy;
  final List<HavingClause<T>>? having;
  final List<AggregateOptions<T>>? aggregates;
  final List<RawExpression>? rawExpressions;
  final int? limit;
  final int? offset;
  final List<WindowFunction<T>>? windowFunctions;
  final List<CTE<T>>? ctes;
  final TransformConfig<T>? transforms;
  final ExplainOptions? explain;
  final List<RecursiveCTE<T>>? recursiveCtes;
  final List<WindowFunctionAdvanced<T>>? advancedWindows;
  final List<String>? select;

  const QueryParams({
    this.filter,
    this.whereRaw,
    this.whereBetween,
    this.whereNull,
    this.whereNotNull,
    this.whereIn,
    this.whereNotIn,
    this.whereExists,
    this.whereGroups,
    this.orderBy,
    this.groupBy,
    this.having,
    this.aggregates,
    this.rawExpressions,
    this.limit,
    this.offset,
    this.windowFunctions,
    this.ctes,
    this.transforms,
    this.explain,
    this.recursiveCtes,
    this.advancedWindows,
    this.select,
  });

  Map<String, dynamic> toJson() => {
    if (filter != null) 'filter': filter,
    if (whereRaw != null) 'whereRaw': whereRaw!.map((e) => e.toJson()).toList(),
    if (whereBetween != null)
      'whereBetween': whereBetween!.map((e) => e.toJson()).toList(),
    if (whereNull != null) 'whereNull': whereNull,
    if (whereNotNull != null) 'whereNotNull': whereNotNull,
    if (whereIn != null) 'whereIn': whereIn,
    if (whereNotIn != null) 'whereNotIn': whereNotIn,
    if (whereExists != null)
      'whereExists': whereExists!.map((e) => e.toJson()).toList(),
    if (whereGroups != null)
      'whereGroups': whereGroups!.map((e) => e.toJson()).toList(),
    if (orderBy != null) 'orderBy': orderBy!.map((e) => e.toJson()).toList(),
    if (groupBy != null) 'groupBy': groupBy,
    if (having != null) 'having': having!.map((e) => e.toJson()).toList(),
    if (aggregates != null)
      'aggregates': aggregates!.map((e) => e.toJson()).toList(),
    if (rawExpressions != null)
      'rawExpressions': rawExpressions!.map((e) => e.toJson()).toList(),
    if (limit != null) 'limit': limit,
    if (offset != null) 'offset': offset,
    if (windowFunctions != null)
      'windowFunctions': windowFunctions!.map((e) => e.toJson()).toList(),
    if (ctes != null) 'ctes': ctes!.map((e) => e.toJson()).toList(),
    if (transforms != null) 'transforms': transforms!.toJson(),
    if (explain != null) 'explain': explain!.toJson(),
    if (recursiveCtes != null)
      'recursiveCtes': recursiveCtes!.map((e) => e.toJson()).toList(),
    if (advancedWindows != null)
      'advancedWindows': advancedWindows!.map((e) => e.toJson()).toList(),
    if (select != null) 'select': select,
  };

  factory QueryParams.fromJson(Map<String, dynamic> json) {
    return QueryParams<T>(
      filter: json['filter'] as Map<String, dynamic>?,
      whereRaw:
          (json['whereRaw'] as List?)
              ?.map((w) => WhereClause<T>.fromJson(w as Map<String, dynamic>))
              .toList(),
      whereBetween:
          (json['whereBetween'] as List?)
              ?.map(
                (w) =>
                    WhereBetweenClause<T>.fromJson(w as Map<String, dynamic>),
              )
              .toList(),
      whereNull: (json['whereNull'] as List?)?.cast<String>(),
      whereNotNull: (json['whereNotNull'] as List?)?.cast<String>(),
      whereIn: (json['whereIn'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, v as List<dynamic>),
      ),
      whereNotIn: (json['whereNotIn'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, v as List<dynamic>),
      ),
      whereExists:
          (json['whereExists'] as List?)
              ?.map((w) => SubQueryConfig.fromJson(w as Map<String, dynamic>))
              .toList(),
      whereGroups:
          (json['whereGroups'] as List?)
              ?.map((w) => WhereGroup<T>.fromJson(w as Map<String, dynamic>))
              .toList(),
      orderBy:
          (json['orderBy'] as List?)
              ?.map((o) => OrderByClause<T>.fromJson(o as Map<String, dynamic>))
              .toList(),
      groupBy: (json['groupBy'] as List?)?.cast<String>(),
      having:
          (json['having'] as List?)
              ?.map((h) => HavingClause<T>.fromJson(h as Map<String, dynamic>))
              .toList(),
      aggregates:
          (json['aggregates'] as List?)
              ?.map(
                (a) => AggregateOptions<T>.fromJson(a as Map<String, dynamic>),
              )
              .toList(),
      rawExpressions:
          (json['rawExpressions'] as List?)
              ?.map((r) => RawExpression.fromJson(r as Map<String, dynamic>))
              .toList(),
      limit: json['limit'] as int?,
      offset: json['offset'] as int?,
      windowFunctions:
          (json['windowFunctions'] as List?)
              ?.map(
                (w) => WindowFunction<T>.fromJson(w as Map<String, dynamic>),
              )
              .toList(),
      ctes:
          (json['ctes'] as List?)
              ?.map((c) => CTE<T>.fromJson(c as Map<String, dynamic>))
              .toList(),
      transforms:
          json['transforms'] != null
              ? TransformConfig<T>.fromJson(
                json['transforms'] as Map<String, dynamic>,
              )
              : null,
      explain:
          json['explain'] != null
              ? ExplainOptions.fromJson(json['explain'] as Map<String, dynamic>)
              : null,
      recursiveCtes:
          (json['recursiveCtes'] as List?)
              ?.map((r) => RecursiveCTE<T>.fromJson(r as Map<String, dynamic>))
              .toList(),
      advancedWindows:
          (json['advancedWindows'] as List?)
              ?.map(
                (w) => WindowFunctionAdvanced<T>.fromJson(
                  w as Map<String, dynamic>,
                ),
              )
              .toList(),
      select: (json['select'] as List?)?.cast<String>(),
    );
  }
}

/// Options for query execution
class QueryOptions {
  final bool? execute;

  const QueryOptions({this.execute});

  Map<String, dynamic> toJson() => {if (execute != null) 'execute': execute};
}

/// Response from the API
class ApiResponse<T extends Map<String, dynamic>> {
  final List<T>? records;
  final QueryParams<T>? params;
  final String? message;
  final String? error;
  final int? id;

  const ApiResponse({
    this.records,
    this.params,
    this.message,
    this.error,
    this.id,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      records: json['records']?.cast<T>(),
      params:
          json['params'] != null
              ? QueryParams<T>.fromJson(json['params'] as Map<String, dynamic>)
              : null,
      message: json['message'] as String?,
      error: json['error'] as String?,
      id: json['id'] as int?,
    );
  }
}

/// Custom exception for ForgeBase errors
class ForgeBaseException implements Exception {
  final String message;
  final String code;
  final int? statusCode;

  const ForgeBaseException(this.message, this.code, {this.statusCode});

  @override
  String toString() =>
      'ForgeBaseException: $message (Code: $code${statusCode != null ? ', Status: $statusCode' : ''})';
}

extension WhereOperatorFromString on WhereOperator {
  static WhereOperator fromString(String value) {
    return WhereOperator.values.firstWhere(
      (e) => e.operator == value,
      orElse: () => throw FormatException('Invalid WhereOperator: $value'),
    );
  }
}

extension GroupOperatorFromString on GroupOperator {
  static GroupOperator fromString(String value) {
    return GroupOperator.values.firstWhere(
      (e) => e.operator == value,
      orElse: () => throw FormatException('Invalid GroupOperator: $value'),
    );
  }
}
