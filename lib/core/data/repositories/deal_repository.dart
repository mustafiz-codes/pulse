import '../../models/deal.dart';
import '../../models/sales_dataset.dart';

/// Read-only access to opportunity records and their relationships.
class DealRepository {
  const DealRepository(this.dataset);

  final SalesDataset dataset;

  List<Deal> get all => dataset.deals;

  Deal? byId(String id) => dataset.dealsById[id];

  Deal? forLead(String leadId) => dataset.dealForLead(leadId);

  List<Deal> forOwner(String ownerId) => dataset.dealsForOwner(ownerId);

  List<Deal> get open =>
      dataset.deals.where((deal) => deal.isOpen).toList(growable: false);

  List<Deal> forAccount(String accountId) => dataset.deals
      .where((deal) => deal.accountId == accountId)
      .toList(growable: false);
}
