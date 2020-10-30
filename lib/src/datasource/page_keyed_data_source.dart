import 'dart:developer' as developer;

import 'package:paging/src/datasource/data_source.dart';
import 'package:tuple/tuple.dart';
/// Key is page index, Value is type Data
abstract class PageKeyedDataSource<Key, Value> extends DataSource<Value> {
  static const TAG = 'PageKeyedDataSource';

  /// Current Key of page loaded success
  Key currentKey;

  /// true if data source is loaded all data
  /// false if data source is not loaded all data
  bool isEndList;

  /// Load for first time
  Future<Tuple2<List<Value>, Key>> loadInitial();

  /// Load for page after page has key is param
  Future<Tuple2<List<Value>, Key>> loadPageAfter(Key params);

  @override
  Future<List<Value>> loadPage({bool isRefresh}) async {
    if (currentKey == null || isRefresh == true) {
      final results = await loadInitial();
      developer.log('loadPage results $results', name: TAG);
      currentKey = results.item2;
      return results.item1;
    } else {
      final results = await loadPageAfter(currentKey);
      currentKey = results.item2;
      return results.item1;
    }
  }
}

