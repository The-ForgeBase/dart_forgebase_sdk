// ignore_for_file: unused_local_variable

import 'package:dio/dio.dart';
import 'package:forgebase_sdk/forgebase_sdk.dart';

// Define your data types
typedef User = Map<String, dynamic>;
typedef Order = Map<String, dynamic>;
typedef Product = Map<String, dynamic>;

void main() async {
  // Initialize SDK
  final sdk = DatabaseSDK(
    'http://localhost:3000',
    dioOptions: BaseOptions(
      connectTimeout: Duration(seconds: 5),
      receiveTimeout: Duration(seconds: 3),
    ),
  );

  // Basic Queries
  final users =
      await sdk.table<User>('users').where('status', 'active').execute();

  final seniorManagers =
      await sdk
          .table<User>('users')
          .where('role', 'manager')
          .where('experience', WhereOperator.greaterThanOrEqual, 5)
          .execute();

  final orderBy = OrderByClause(
    field: 'salary',
    direction: SortDirection.desc,
    nulls: NullsPosition.first,
  );
  final sortedUsers =
      await sdk
          .table<User>('users')
          .orderBy('lastName', direction: SortDirection.asc)
          .orderBy(
            orderBy.field,
            direction: orderBy.direction,
            nulls: orderBy.nulls,
          )
          .execute();

  final pagedResults =
      await sdk.table<User>('users').offset(20).limit(10).execute();

  // Complex queries with window functions
  final rankedSalaries =
      await sdk
          .table<User>('users')
          .select(['firstName', 'department', 'salary'])
          .window(
            WindowFunctionType.rank,
            'salary_rank',
            partitionBy: ['department'],
            orderBy: [
              OrderByClause(field: 'salary', direction: SortDirection.desc),
            ],
          )
          .execute();

  // Aggregations and grouping
  final orderStats =
      await sdk
          .table<Order>('orders')
          .groupBy(['status'])
          .count('id', alias: 'order_count')
          .sum('total', alias: 'total_amount')
          .avg('total', alias: 'average_amount')
          .execute();

  final highValueOrderGroups =
      await sdk
          .table<Order>('orders')
          .groupBy(['userId'])
          .having('total_amount', WhereOperator.greaterThan, 1000)
          .sum('total', alias: 'total_amount')
          .execute();

  // Advanced window functions
  final advancedAnalysis =
      await sdk
          .table<User>('users')
          .select([
            'id',
            'firstName',
            'lastName',
            'department',
            'salary',
            'hireDate',
          ])
          .windowAdvanced(
            WindowFunctionType.sum,
            'running_total',
            over: WindowOver(
              partitionBy: ['department'],
              orderBy: [
                OrderByClause(field: 'hireDate', direction: SortDirection.asc),
              ],
              frame: WindowFrame(
                type: 'ROWS',
                start: 'UNBOUNDED PRECEDING',
                end: 'CURRENT ROW',
              ),
            ),
          )
          .orderBy('department', direction: SortDirection.asc)
          .orderBy('hireDate', direction: SortDirection.asc)
          .execute();

  // Working with CTEs
  final highPaidUsers = sdk
      .table<User>('users')
      .where('salary', WhereOperator.greaterThan, 100000);

  final result =
      await sdk
          .table<User>('users')
          .with_('high_paid', highPaidUsers)
          .execute();

  // Recursive CTEs
  final initialQuery = sdk
      .table<Product>('products')
      .where('category', 'Electronics');

  final recursiveQuery = sdk
      .table<Product>('products')
      .where('price', WhereOperator.greaterThan, 1000);

  final recursiveResult =
      await sdk
          .table<Product>('products')
          .withRecursive(
            'product_hierarchy',
            initialQuery,
            recursiveQuery,
            unionAll: true,
          )
          .execute();

  // Complex filtering
  final filteredUsers =
      await sdk.table<User>('users').where('status', 'active').andWhere((
        query,
      ) {
        query.where('role', 'admin').orWhere((subQuery) {
          subQuery.where('role', 'manager').where('department', 'IT');
        });
      }).execute();

  // Range queries
  final salaryRange =
      await sdk.table<User>('users').whereBetween('salary', [
        50000,
        100000,
      ]).execute();

  // IN queries
  final specificDepts =
      await sdk.table<User>('users').whereIn('department', [
        'IT',
        'HR',
        'Finance',
      ]).execute();

  // Create a record
  final newUser = await sdk.table<User>('users').create({
    'firstName': 'John',
    'lastName': 'Doe',
    'email': 'john@example.com',
    'role': 'user',
  });

  // Update a record
  final updatedUser = await sdk.table<User>('users').update(1, {
    'status': 'inactive',
  });

  // Delete a record
  await sdk.table<User>('users').delete(1);

  // Print some results
  print('Active users: ${users.records?.length}');
  print('Senior managers: ${seniorManagers.records?.length}');
  print('Order statistics: ${orderStats.records}');
}
