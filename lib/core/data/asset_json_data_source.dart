import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/sales_dataset.dart';
import 'data_validation.dart';
import 'sales_data_source.dart';

class AssetJsonDataSource implements SalesDataSource {
  AssetJsonDataSource({
    AssetBundle? bundle,
    this.basePath = 'assets/data/demo',
    DataValidator validator = const DataValidator(),
  }) : _bundle = bundle ?? rootBundle,
       _validator = validator;

  final AssetBundle _bundle;
  final String basePath;
  final DataValidator _validator;

  static const _files = <String>[
    'manifest',
    'users',
    'accounts',
    'leads',
    'deals',
    'deal_stage_events',
    'activities',
    'targets',
    'insight_scenarios',
    'business_units',
  ];

  @override
  Future<SalesDataset> load() async {
    final payloads = await Future.wait(
      _files.map((name) => _bundle.loadString('$basePath/$name.json')),
    );

    final raw = <String, dynamic>{};
    for (var i = 0; i < _files.length; i++) {
      raw[_files[i]] = jsonDecode(payloads[i]);
    }

    final dataset = SalesDataset.fromJson(raw);
    final validation = _validator.validate(dataset);
    if (!validation.isValid) {
      throw DataValidationException(validation);
    }
    if (kDebugMode) {
      for (final warning in validation.warnings) {
        debugPrint('Demo data warning: $warning');
      }
    }
    return dataset;
  }
}
