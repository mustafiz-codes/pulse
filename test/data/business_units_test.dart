import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/data/data_validation.dart';
import 'package:pulse/core/models/enums.dart';
import 'package:pulse/core/models/sales_dataset.dart';

import '../support/demo_dataset.dart';
import '../support/fixture.dart';

void main() {
  late SalesDataset ds;

  setUpAll(() async {
    ds = await loadDemoDataset();
  });

  test('catalogue has 5 units in order with spec products', () {
    expect(ds.businessUnits.map((u) => u.id), [
      'lawyer',
      'cloud',
      'hr',
      'accountant',
      'global',
    ]);
    expect(ds.unitIds, ['lawyer', 'cloud', 'hr', 'accountant', 'global']);
    expect(ds.unitFor('lawyer').products.map((p) => p.label), [
      'Visa',
      'JR',
      'AR',
      'Appeal',
      'ILR',
      'Citizenship',
    ]);
    expect(ds.unitFor('cloud').products.map((p) => p.label), [
      'Microsoft 365 Setup',
      'Cloud Hosting',
      'Backup & Recovery',
      'Managed IT',
      'Domain & Email',
    ]);
    expect(ds.unitFor('hr').products.map((p) => p.label), [
      'Payroll Service',
      'HR Consultancy',
      'Employment Contracts',
      'Right-to-Work Checks',
    ]);
    expect(ds.unitFor('accountant').products.map((p) => p.label), [
      'Bookkeeping',
      'Self-Assessment',
      'VAT Return',
      'Year-End Accounts',
      'Company Formation',
    ]);
    expect(ds.unitFor('global').products.map((p) => p.label), [
      'Sponsor Licence',
      'Overseas Company Setup',
      'Global Payroll',
      'Skilled Worker Sponsorship',
    ]);
    expect(ds.unitIdOf('jr'), 'lawyer');
    expect(ds.productFor('skilled_worker').label, 'Skilled Worker Sponsorship');
  });

  test('every lead and deal has a known product; deals match their lead', () {
    for (final lead in ds.leads) {
      expect(ds.productsById.containsKey(lead.productId), isTrue);
    }
    for (final deal in ds.deals) {
      expect(ds.productsById.containsKey(deal.productId), isTrue);
      final lead = deal.leadId == null ? null : ds.leadsById[deal.leadId];
      if (lead != null) expect(deal.productId, lead.productId);
    }
  });

  test('deal titles start with product label', () {
    for (final deal in ds.deals) {
      expect(
        deal.title,
        startsWith('${ds.productFor(deal.productId).label} — '),
      );
    }
  });

  test('reps have home units', () {
    expect(
      {for (final u in ds.users) u.displayName: u.homeUnitId},
      {
        'Sunny': 'cloud',
        'Mamun': 'lawyer',
        'Irteza': 'hr',
        'Krishna': 'accountant',
        'Shahriar': 'global',
      },
    );
  });

  test('home unit share ~70%', () {
    for (final user in ds.users) {
      final leads = ds.leads.where((l) => l.ownerId == user.id).toList();
      final home = leads
          .where((l) => ds.unitIdOf(l.productId) == user.homeUnitId)
          .length;
      expect(
        home / leads.length,
        inInclusiveRange(0.55, 0.85),
        reason: user.displayName,
      );
    }
  });

  group('validator', () {
    const validator = DataValidator();
    Set<String> codes(SalesDataset d) =>
        validator.validate(d).issues.map((i) => i.code).toSet();

    test('valid fixture has no product errors', () {
      final d = buildDataset(
        leads: [testLead(id: 'lead_1', createdAt: testAsOf, productId: 'visa')],
      );
      expect(codes(d), isNot(contains('products.unknown')));
    });

    test('unknown product is an error', () {
      final d = buildDataset(
        leads: [testLead(id: 'lead_1', createdAt: testAsOf, productId: 'nope')],
      );
      expect(codes(d), contains('products.unknown'));
    });

    test('deal product must match its lead', () {
      final d = buildDataset(
        leads: [testLead(id: 'lead_1', createdAt: testAsOf, productId: 'visa')],
        deals: [
          testDeal(
            id: 'deal_1',
            leadId: 'lead_1',
            productId: 'jr',
            valueMinor: 100000,
            stage: DealStage.proposal,
            outcome: DealOutcome.open,
            createdAt: testAsOf,
          ),
        ],
      );
      expect(codes(d), contains('deals.product_mismatch'));
    });

    test('individual account must not have a size band', () {
      final d = buildDataset(
        accounts: [
          testAccount('acc_1', kind: AccountKind.individual, sizeBand: '1-10'),
        ],
      );
      expect(codes(d), contains('accounts.individual_size_band'));
    });

    test('home unit must exist', () {
      final d = buildDataset(users: [testUser('rep_x', homeUnitId: 'mars')]);
      expect(codes(d), contains('users.unknown_home_unit'));
    });
  });
}
