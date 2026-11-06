import '../models/sales_dataset.dart';

/// Abstraction over the local asset fixture. A future Monday adapter can
/// implement this interface without changing screens or analytics.
abstract interface class SalesDataSource {
  Future<SalesDataset> load();
}
