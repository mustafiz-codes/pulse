import '../../models/sales_dataset.dart';
import '../../models/sales_user.dart';
import '../../utils/labels.dart';

class TeamSummary {
  const TeamSummary({
    required this.id,
    required this.label,
    required this.members,
  });

  final String id;
  final String label;
  final List<SalesUser> members;

  int get headcount => members.length;
}

/// Read-only access to the people and teams in the fixture.
class TeamRepository {
  const TeamRepository(this.dataset);

  final SalesDataset dataset;

  List<SalesUser> get users => dataset.users;

  SalesUser? byId(String id) => dataset.usersById[id];

  List<SalesUser> forTeam(String teamId) => dataset.users
      .where((user) => user.homeUnitId == teamId)
      .toList(growable: false);

  List<TeamSummary> get teams => dataset.unitIds
      .map(
        (teamId) => TeamSummary(
          id: teamId,
          label: unitLabel(teamId),
          members: forTeam(teamId),
        ),
      )
      .toList(growable: false);
}
