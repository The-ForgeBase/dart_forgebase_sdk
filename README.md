# ForgeBase SDK for Dart/Flutter

A powerful and flexible Dart SDK for interacting with ForgeBase databases. This SDK provides a fluent interface for building complex queries, performing CRUD operations, and working with advanced database features like window functions, CTEs, and aggregates.

## Features

- 🚀 **Fluent Query Builder API**: Build type-safe database queries with an intuitive builder pattern
- 🔒 **Type Safety**: Full TypeScript-like generic support for your data models
- 🔄 **CRUD Operations**: Simple methods for Create, Read, Update, and Delete operations
- 📊 **Advanced Query Features**:
  - Complex filtering with AND/OR conditions
  - Window functions and analytics
  - Common Table Expressions (CTEs)
  - Aggregations and grouping
  - Subqueries and EXISTS clauses
  - Pagination and sorting
- ⚡ **Performance**: Optimized HTTP client using Dio
- 🔍 **Error Handling**: Detailed error messages and proper error typing

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  forgebase_sdk: ^1.0.0
```

## Quick Start

```dart
// Initialize the SDK
final sdk = DatabaseSDK('https://your-forgebase-api.com');

// Simple query
final users = await sdk
    .table<Map<String, dynamic>>('users')
    .where('status', 'active')
    .limit(10)
    .execute();

// Complex query with joins and aggregates
final orderStats = await sdk
    .table<Map<String, dynamic>>('orders')
    .whereExists((subquery) =>
      subquery.table('order_items')
        .where('order_items.order_id', '=', 'orders.id')
        .where('quantity', '>', 10)
    )
    .groupBy(['status'])
    .having('total_amount', WhereOperator.greaterThan, 1000)
    .sum('amount', alias: 'total_amount')
    .execute();
```

## Advanced Features

### Window Functions

```dart
final rankedSalaries = await sdk
    .table<Map<String, dynamic>>('employees')
    .windowAdvanced(
      WindowFunctionType.rowNumber,
      'salary_rank',
      over: WindowOver(
        partitionBy: ['department'],
        orderBy: [OrderByClause(field: 'salary', direction: SortDirection.desc)]
      ),
    )
    .execute();
```

### Common Table Expressions (CTEs)

```dart
final hierarchicalData = await sdk
    .table<Map<String, dynamic>>('employees')
    .withRecursive(
      'employee_hierarchy',
      initialQuery,
      recursiveQuery,
      columns: ['id', 'manager_id', 'level'],
    )
    .execute();
```

### Aggregations

```dart
final stats = await sdk
    .table<Map<String, dynamic>>('sales')
    .groupBy(['region'])
    .sum('amount', alias: 'total_sales')
    .avg('amount', alias: 'average_sale')
    .count('id', alias: 'num_transactions')
    .execute();
```

## Error Handling

The SDK provides detailed error information through the `ForgeBaseException` class:

```dart
try {
  final result = await sdk.table('users').execute();
} on ForgeBaseException catch (e) {
  print('Error: ${e.message}');
  print('Code: ${e.code}');
  print('Status: ${e.statusCode}');
}
```

## API Reference

### DatabaseSDK

The main entry point for interacting with your ForgeBase database.

```dart
final sdk = DatabaseSDK(
  'https://api.example.com',
  interceptors: [], // Optional Dio interceptors
  dioOptions: BaseOptions(), // Optional Dio configuration
);
```

### QueryBuilder

Methods for building database queries:

- `where(field, operator, value)`: Add a where clause
- `orWhere((query) => ...)`: Add an OR where clause
- `whereExists((subquery) => ...)`: Add a where exists clause
- `groupBy(fields)`: Group results by fields
- `orderBy(field, direction, nulls)`: Sort results
- `limit(value)`: Limit number of results
- `offset(value)`: Skip number of results
- And many more...

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
