import '../../models/lead.dart';
import '../../models/sales_dataset.dart';

/// Read-only access to lead records for screens and drill-downs.
class LeadRepository {
  const LeadRepository(this.dataset);

  final SalesDataset dataset;

  List<Lead> get all => dataset.leads;

  Lead? byId(String id) => dataset.leadsById[id];

  List<Lead> forOwner(String ownerId) =>
      dataset.leads.where((lead) => lead.ownerId == ownerId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<Lead> get open =>
      dataset.leads.where((lead) => lead.isOpen).toList(growable: false);

  List<Lead> search(String query, {Iterable<Lead>? within}) {
    final term = query.trim().toLowerCase();
    if (term.isEmpty) return List.of(within ?? all);
    return (within ?? all)
        .where((lead) {
          final account = dataset.accountsById[lead.accountId];
          final owner = dataset.usersById[lead.ownerId];
          return (account?.name.toLowerCase().contains(term) ?? false) ||
              (owner?.displayName.toLowerCase().contains(term) ?? false) ||
              lead.id.toLowerCase().contains(term) ||
              lead.source.name.contains(term) ||
              lead.status.name.contains(term);
        })
        .toList(growable: false);
  }
}
