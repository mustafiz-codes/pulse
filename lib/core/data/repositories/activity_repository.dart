import '../../models/sales_activity.dart';
import '../../models/sales_dataset.dart';

/// Read-only access to recorded activities and their relationships.
class ActivityRepository {
  const ActivityRepository(this.dataset);

  final SalesDataset dataset;

  List<SalesActivity> get all => dataset.activities;

  SalesActivity? byId(String id) => dataset.activitiesById[id];

  List<SalesActivity> forOwner(String ownerId) =>
      dataset.activitiesForOwner(ownerId);

  List<SalesActivity> forDeal(String dealId) =>
      dataset.activitiesForDeal(dealId);

  List<SalesActivity> forLead(String leadId) =>
      dataset.activitiesForLead(leadId);
}
