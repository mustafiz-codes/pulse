import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/data/data_validation.dart';
import 'package:pulse/core/models/enums.dart';

import '../support/demo_dataset.dart';
import '../support/fixture.dart';

void main() {
  test('bundled demo fixture loads and validates without errors', () async {
    final dataset = await loadDemoDataset();
    final result = const DataValidator().validate(dataset);

    expect(result.isValid, isTrue, reason: result.errors.join('\n'));
    expect(result.errors, isEmpty);
    expect(result.warnings, hasLength(5));
    expect(result.warnings.map((issue) => issue.code).toSet(), {
      'deal_stage_events.missing',
    });

    expect(dataset.manifest.asOf, DateTime.utc(2026, 10, 31, 23, 59, 59));
    expect(dataset.manifest.currency, 'GBP');
    expect(dataset.manifest.timezone, 'Europe/London');
    expect(dataset.users.map((user) => user.displayName), [
      'Sunny',
      'Mamun',
      'Irteza',
      'Krishna',
      'Shahriar',
    ]);
    expect(dataset.leads, hasLength(400));
    expect(dataset.deals, hasLength(180));
    expect(dataset.stageEvents, hasLength(907));
    expect(dataset.activities, hasLength(2812));
    expect(dataset.targets, hasLength(57));
    expect(dataset.scenarios, hasLength(4));
  });

  test('validator rejects a deal that references a missing account', () {
    final dataset = buildDataset(
      deals: [
        testDeal(
          id: 'deal_1',
          accountId: 'missing_account',
          valueMinor: 100000,
          stage: DealStage.proposal,
          outcome: DealOutcome.open,
          createdAt: DateTime.utc(2026, 10, 1),
        ),
      ],
    );

    final result = const DataValidator().validate(dataset);

    expect(result.isValid, isFalse);
    expect(result.errors, isNotEmpty);
  });

  test('validator rejects duplicate entity identifiers', () {
    final dataset = buildDataset(
      accounts: [
        testAccount('acc_1'),
        testAccount('acc_1', name: 'Duplicate'),
      ],
    );

    final result = const DataValidator().validate(dataset);

    expect(result.isValid, isFalse);
    expect(
      result.errors.any((issue) => issue.code.contains('duplicate')),
      isTrue,
      reason: result.errors.join('\n'),
    );
  });
}
