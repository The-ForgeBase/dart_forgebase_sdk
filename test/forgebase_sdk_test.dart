import 'package:flutter_test/flutter_test.dart';
import 'package:forgebase_sdk/forgebase_sdk.dart';

void main() {
  late DatabaseSDK sdk;

  setUp(() {
    sdk = DatabaseSDK('http://mock-api.example.com');
  });

  group('Basic Query Building', () {
    test('simple where clause builds correct params', () async {
      final query = sdk
          .table<Map<String, dynamic>>('users')
          .where('status', 'active');

      final params = await query.toParams();
      print(params.toJson());
      expect(params.filter, {'status': 'active'});
    });

    test('multiple where clauses build correct params', () async {
      final query = sdk
          .table<Map<String, dynamic>>('users')
          .where('status', 'active')
          .where('age', WhereOperator.greaterThan, 18);

      final params = await query.toParams();
      expect(params.filter, {'status': 'active'});
      expect(params.whereRaw?.length, 1);
      expect(params.whereRaw?[0].field, 'age');
      expect(params.whereRaw?[0].operator, WhereOperator.greaterThan);
      expect(params.whereRaw?[0].value, 18);
    });

    test('select specific fields', () async {
      final query = sdk.table<Map<String, dynamic>>('users').select([
        'id',
        'name',
        'email',
      ]);

      final params = await query.toParams();
      expect(params.select, ['id', 'name', 'email']);
    });
  });

  group('Advanced Filtering', () {
    test('whereBetween builds correct params', () async {
      final query = sdk.table<Map<String, dynamic>>('products').whereBetween(
        'price',
        [10, 100],
      );

      final params = await query.toParams();
      expect(params.whereBetween?.length, 1);
      expect(params.whereBetween?[0].field, 'price');
      expect(params.whereBetween?[0].value, [10, 100]);
    });

    test('whereIn builds correct params', () async {
      final query = sdk.table<Map<String, dynamic>>('orders').whereIn(
        'status',
        ['pending', 'processing'],
      );

      final params = await query.toParams();
      expect(params.whereIn, {
        'status': ['pending', 'processing'],
      });
    });

    test('whereNull and whereNotNull build correct params', () async {
      final query = sdk
          .table<Map<String, dynamic>>('users')
          .whereNull('deletedAt')
          .whereNotNull('email');

      final params = await query.toParams();
      expect(params.whereNull, ['deletedAt']);
      expect(params.whereNotNull, ['email']);
    });

    test('complex where group with AND/OR conditions', () async {
      final query = sdk
          .table<Map<String, dynamic>>('users')
          .where('status', 'active')
          .orWhere(
            (query) => query.where('role', 'admin').where('department', 'IT'),
          )
          .andWhere(
            (query) => query
                .where('experience', WhereOperator.greaterThan, 5)
                .where('level', WhereOperator.greaterThanOrEqual, 3),
          );

      final params = await query.toParams();
      expect(params.filter, {'status': 'active'});
      expect(params.whereGroups?.length, 2);

      final orGroup = params.whereGroups?[0];
      expect(orGroup?.type, GroupOperator.or);
      expect(orGroup?.clauses.length, 2);

      final andGroup = params.whereGroups?[1];
      expect(andGroup?.type, GroupOperator.and);
      expect(andGroup?.clauses.length, 2);
    });
  });

  group('Aggregations and Grouping', () {
    test('basic aggregation functions', () async {
      final query = sdk
          .table<Map<String, dynamic>>('orders')
          .sum('amount', alias: 'total')
          .avg('amount', alias: 'average')
          .count('id', alias: 'count')
          .min('amount', alias: 'min_amount')
          .max('amount', alias: 'max_amount');

      final params = await query.toParams();
      expect(params.aggregates?.length, 5);

      final aggregates = params.aggregates!;
      expect(aggregates[0].type, AggregateType.sum);
      expect(aggregates[1].type, AggregateType.avg);
      expect(aggregates[2].type, AggregateType.count);
      expect(aggregates[3].type, AggregateType.min);
      expect(aggregates[4].type, AggregateType.max);
    });

    test('group by with having clause', () async {
      final query = sdk
          .table<Map<String, dynamic>>('orders')
          .groupBy(['status'])
          .sum('amount', alias: 'total_amount')
          .having('total_amount', WhereOperator.greaterThan, 1000);

      final params = await query.toParams();
      expect(params.groupBy, ['status']);
      expect(params.having?.length, 1);
      expect(params.having?[0].field, 'total_amount');
      expect(params.having?[0].operator, WhereOperator.greaterThan);
      expect(params.having?[0].value, 1000);
    });
  });

  group('Window Functions', () {
    test('basic window function', () async {
      final query = sdk
          .table<Map<String, dynamic>>('employees')
          .window(
            WindowFunctionType.rowNumber,
            'rank',
            partitionBy: ['department'],
            orderBy: [
              OrderByClause(field: 'salary', direction: SortDirection.desc),
            ],
          );

      final params = await query.toParams();
      expect(params.windowFunctions?.length, 1);
      final window = params.windowFunctions![0];
      expect(window.type, WindowFunctionType.rowNumber);
      expect(window.alias, 'rank');
      expect(window.partitionBy, ['department']);
      expect(window.orderBy?.length, 1);
    });

    test('advanced window function with frame clause', () async {
      final query = sdk
          .table<Map<String, dynamic>>('sales')
          .windowAdvanced(
            WindowFunctionType.sum,
            'running_total',
            field: 'amount',
            over: WindowOver(
              partitionBy: ['region'],
              orderBy: [OrderByClause(field: 'date')],
              frame: WindowFrame(
                type: 'ROWS',
                start: 'UNBOUNDED PRECEDING',
                end: 'CURRENT ROW',
              ),
            ),
          );

      final params = await query.toParams();
      expect(params.advancedWindows?.length, 1);
      final window = params.advancedWindows![0];
      expect(window.type, WindowFunctionType.sum);
      expect(window.field, 'amount');
      expect(window.over?.frame?.type, 'ROWS');
    });
  });

  group('Common Table Expressions', () {
    test('simple CTE', () async {
      final initialQuery = sdk
          .table<Map<String, dynamic>>('employees')
          .where('department', 'IT');

      final query = sdk
          .table<Map<String, dynamic>>('employees')
          .with_('it_employees', initialQuery, columns: ['id', 'name']);

      final params = await query.toParams();
      expect(params.ctes?.length, 1);
      expect(params.ctes![0].name, 'it_employees');
      expect(params.ctes![0].columns, ['id', 'name']);
    });

    test('recursive CTE', () async {
      final initialQuery = sdk
          .table<Map<String, dynamic>>('employees')
          .where('manager_id', null);

      final recursiveQuery = sdk
          .table<Map<String, dynamic>>('employees')
          .where('manager_id', 'employees.id');

      final query = sdk
          .table<Map<String, dynamic>>('employees')
          .withRecursive(
            'employee_hierarchy',
            initialQuery,
            recursiveQuery,
            columns: ['id', 'manager_id'],
            unionAll: true,
          );

      final params = await query.toParams();
      expect(params.recursiveCtes?.length, 1);
      final cte = params.recursiveCtes![0];
      expect(cte.name, 'employee_hierarchy');
      expect(cte.columns, ['id', 'manager_id']);
      expect(cte.unionAll, true);
    });
  });

  group('Pagination and Sorting', () {
    test('limit and offset', () async {
      final query = sdk
          .table<Map<String, dynamic>>('users')
          .limit(10)
          .offset(20);

      final params = await query.toParams();
      expect(params.limit, 10);
      expect(params.offset, 20);
    });

    test('order by with multiple columns', () async {
      final query = sdk
          .table<Map<String, dynamic>>('users')
          .orderBy('lastName', direction: SortDirection.asc)
          .orderBy(
            'firstName',
            direction: SortDirection.asc,
            nulls: NullsPosition.last,
          );

      final params = await query.toParams();
      expect(params.orderBy?.length, 2);
      expect(params.orderBy?[0].field, 'lastName');
      expect(params.orderBy?[0].direction, SortDirection.asc);
      expect(params.orderBy?[1].field, 'firstName');
      expect(params.orderBy?[1].nulls, NullsPosition.last);
    });
  });
}
