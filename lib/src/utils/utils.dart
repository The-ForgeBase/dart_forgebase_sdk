/// Collection of utility functions for the ForgeBase SDK.

/// Checks if a value is a valid number.
bool isNumber(dynamic value) {
  return value is num || value is int || value is double;
}

/// Checks if a value is a valid string.
bool isString(dynamic value) {
  return value is String;
}

/// Checks if a value is a valid boolean.
bool isBoolean(dynamic value) {
  return value is bool;
}

/// Checks if a value is a valid list.
bool isList(dynamic value) {
  return value is List;
}

/// Checks if a value is a valid map.
bool isMap(dynamic value) {
  return value is Map;
}

/// Checks if a value is null or empty.
bool isNullOrEmpty(dynamic value) {
  if (value == null) return true;
  if (value is String) return value.isEmpty;
  if (value is List) return value.isEmpty;
  if (value is Map) return value.isEmpty;
  return false;
}

/// Converts a value to a string for URL encoding.
String toQueryString(dynamic value) {
  if (value == null) return '';
  if (value is List) return value.join(',');
  if (value is Map) return Uri.encodeComponent(value.toString());
  return value.toString();
}

/// Groups a list of maps by a specific key.
Map<K, List<T>> groupBy<T, K>(List<T> items, K Function(T) keyFunction) {
  return items.fold<Map<K, List<T>>>({}, (Map<K, List<T>> map, T item) {
    final K key = keyFunction(item);
    map.putIfAbsent(key, () => []).add(item);
    return map;
  });
}

/// Pivots a list of maps using the specified configuration.
List<Map<String, dynamic>> pivot<T>(
  List<T> items,
  String pivotColumn,
  List<String> values,
  String aggregateColumn, {
  String Function(dynamic)? valueTransform,
}) {
  if (items.isEmpty) return [];

  final groups = groupBy<T, String>(
    items,
    (item) => (item as Map<String, dynamic>)[pivotColumn].toString(),
  );

  return values.map((value) {
    final groupItems = groups[value] ?? [];
    final aggregatedValue =
        groupItems.isNotEmpty
            ? groupItems
                .map((item) => (item as Map<String, dynamic>)[aggregateColumn])
                .reduce((a, b) => a + b)
            : 0;

    return {
      pivotColumn: value,
      aggregateColumn:
          valueTransform != null
              ? valueTransform(aggregatedValue)
              : aggregatedValue,
    };
  }).toList();
}

/// Deep merges two maps.
Map<K, V> deepMerge<K, V>(Map<K, V> map1, Map<K, V> map2) {
  final result = Map<K, V>.from(map1);

  map2.forEach((key, value) {
    if (result.containsKey(key)) {
      if (result[key] is Map && value is Map) {
        result[key] = deepMerge(result[key] as Map, value) as V;
      } else if (result[key] is List && value is List) {
        result[key] = [...result[key] as List, ...value] as V;
      } else {
        result[key] = value;
      }
    } else {
      result[key] = value;
    }
  });

  return result;
}

/// Flattens a nested map into a single level map.
Map<String, dynamic> flatten(
  Map<String, dynamic> map, {
  String separator = '.',
  String? prefix,
}) {
  final result = <String, dynamic>{};

  map.forEach((key, value) {
    final fullKey = prefix != null ? '$prefix$separator$key' : key;

    if (value is Map<String, dynamic>) {
      result.addAll(flatten(value, separator: separator, prefix: fullKey));
    } else {
      result[fullKey] = value;
    }
  });

  return result;
}

/// Unfolds a map with dot notation keys into a nested map.
Map<String, dynamic> unflatten(
  Map<String, dynamic> map, {
  String separator = '.',
}) {
  final result = <String, dynamic>{};

  map.forEach((key, value) {
    final parts = key.split(separator);
    var current = result;

    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (i == parts.length - 1) {
        current[part] = value;
      } else {
        current[part] = current[part] ?? <String, dynamic>{};
        current = current[part] as Map<String, dynamic>;
      }
    }
  });

  return result;
}
