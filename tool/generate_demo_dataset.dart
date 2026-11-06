// Deterministic generator for the PULSE demo fixture.
//
// Run from the project root:
//   dart run tool/generate_demo_dataset.dart
//
// The seed and the manifest date are fixed so every run produces the same
// coherent dataset. The output is checked into assets/data/demo and validated
// by tool/validate_demo_dataset.dart.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

final DateTime periodStart = DateTime.utc(2025, 11, 1);
final DateTime asOf = DateTime.utc(2026, 10, 31, 23, 59, 59);
final DateTime periodEnd = DateTime.utc(2026, 11, 1);

final Random rng = Random(20261031);

const List<String> pipeline = [
  'new',
  'qualified',
  'discovery',
  'proposal',
  'negotiation',
];

const List<String> sources = [
  'inbound',
  'outbound',
  'referral',
  'event',
  'partner',
  'website',
];

const List<double> sourceWeights = [0.30, 0.24, 0.16, 0.12, 0.10, 0.08];

const List<String> industries = [
  'Retail',
  'Logistics',
  'Healthcare',
  'Technology',
  'Manufacturing',
  'Professional services',
  'Media',
  'Financial services',
];

const List<String> sizeBands = ['1-10', '11-50', '51-200', '201-1000', '1000+'];

const List<String> placeWords = [
  'Harrow',
  'Thames Valley',
  'Brick Lane',
  'Camden',
  'Kingston',
  'Whitechapel',
  'Ealing',
  'Croydon',
  'Hackney',
  'Greenwich',
  'Islington',
  'Ilford',
  'Wembley',
  'Southall',
  'Leyton',
  'Stratford',
  'Romford',
  'Tooting',
  'Brixton',
  'Luton',
];

const List<String> tradeWords = [
  'Dental',
  'Bakery',
  'Logistics',
  'Pharmacy',
  'Builders',
  'Lettings',
  'Cafe',
  'Motors',
  'Tutors',
  'Printing',
  'Florist',
  'Opticians',
  'Removals',
  'Catering',
];

const List<String> firstNames = [
  'Farhana',
  'Imran',
  'Sadia',
  'Tanvir',
  'Nusrat',
  'Arif',
  'Priya',
  'Ravi',
  'Anika',
  'Omar',
  'Fatima',
  'Daniel',
  'Sophie',
  'James',
  'Olivia',
  'Lucas',
  'Elena',
  'Marco',
  'Ana',
  'Piotr',
];

const List<String> lastNames = [
  'Ahmed',
  'Rahman',
  'Hossain',
  'Khan',
  'Chowdhury',
  'Patel',
  'Shah',
  'Begum',
  'Smith',
  'Jones',
  'Taylor',
  'Novak',
  'Rossi',
  'Silva',
  'Kowalski',
];

/// Immigration products are bought by private individuals.
const Set<String> individualProducts = {
  'visa',
  'ilr',
  'citizenship',
  'appeal',
  'ar',
  'jr',
};

/// Price band per product in whole pounds (inside each unit's spec range).
const Map<String, (int, int)> productPriceBands = {
  'visa': (1500, 3000),
  'jr': (5000, 8000),
  'ar': (1500, 2500),
  'appeal': (2000, 4500),
  'ilr': (1800, 3200),
  'citizenship': (1500, 2500),
  'm365_setup': (2000, 5000),
  'cloud_hosting': (3000, 9000),
  'backup_recovery': (2000, 6000),
  'managed_it': (5000, 12000),
  'domain_email': (2000, 3500),
  'payroll_service': (1200, 4000),
  'hr_consultancy': (1500, 4000),
  'employment_contracts': (800, 2000),
  'right_to_work': (800, 1800),
  'bookkeeping': (600, 2500),
  'self_assessment': (300, 600),
  'vat_return': (400, 900),
  'year_end_accounts': (800, 2500),
  'company_formation': (300, 800),
  'sponsor_licence': (3000, 6000),
  'overseas_setup': (6000, 15000),
  'global_payroll': (5000, 12000),
  'skilled_worker': (3000, 7000),
};

/// Relative lead volume when a lead lands outside its owner's home unit.
const Map<String, double> unitVolume = {
  'lawyer': 1.2,
  'cloud': 1.0,
  'hr': 0.9,
  'accountant': 1.5,
  'global': 0.4,
};

/// October wins per rep: (unit id, or 'jr' for Mamun's JR win; value in
/// pence). Values are clamped to the chosen product's price band.
const Map<String, List<(String, int)>> octoberBook = {
  'rep_01': [
    ('cloud', 520000),
    ('cloud', 460000),
    ('cloud', 420000),
    ('cloud', 380000),
  ],
  'rep_02': [
    ('jr', 790000),
    ('lawyer', 300000),
    ('lawyer', 290000),
    ('lawyer', 270000),
    ('lawyer', 260000),
  ],
  'rep_03': [
    ('hr', 380000),
    ('hr', 340000),
    ('hr', 310000),
    ('hr', 280000),
    ('hr', 300000),
    ('lawyer', 250000),
  ],
  'rep_04': [
    ('accountant', 220000),
    ('accountant', 180000),
    ('accountant', 150000),
    ('accountant', 120000),
    ('accountant', 90000),
  ],
  'rep_05': [('global', 580000), ('global', 420000)],
};

/// Deliberate October losses per rep.
const int octoberLosses = 1;

/// Deliberate September wins per rep (Shahriar gets one).
const int septemberWins = 3;

/// Close-cycle multiplier per unit.
const Map<String, double> unitCycle = {'accountant': 0.6, 'cloud': 1.5};

/// Judicial Review is a common, slow Lawyer product: heavier pick weight and
/// a longer overall cycle, so its Proposal stall has a real sample.
const Map<String, double> productWeight = {'jr': 2.5};
const Map<String, double> productCycle = {'jr': 3.6};

/// Business units and their products, in display order.
const List<(String, String, List<(String, String)>)> catalogue = [
  (
    'lawyer',
    'Lawyer',
    [
      ('visa', 'Visa'),
      ('jr', 'JR'),
      ('ar', 'AR'),
      ('appeal', 'Appeal'),
      ('ilr', 'ILR'),
      ('citizenship', 'Citizenship'),
    ],
  ),
  (
    'cloud',
    'Cloud',
    [
      ('m365_setup', 'Microsoft 365 Setup'),
      ('cloud_hosting', 'Cloud Hosting'),
      ('backup_recovery', 'Backup & Recovery'),
      ('managed_it', 'Managed IT'),
      ('domain_email', 'Domain & Email'),
    ],
  ),
  (
    'hr',
    'HR',
    [
      ('payroll_service', 'Payroll Service'),
      ('hr_consultancy', 'HR Consultancy'),
      ('employment_contracts', 'Employment Contracts'),
      ('right_to_work', 'Right-to-Work Checks'),
    ],
  ),
  (
    'accountant',
    'Accountant',
    [
      ('bookkeeping', 'Bookkeeping'),
      ('self_assessment', 'Self-Assessment'),
      ('vat_return', 'VAT Return'),
      ('year_end_accounts', 'Year-End Accounts'),
      ('company_formation', 'Company Formation'),
    ],
  ),
  (
    'global',
    'Global',
    [
      ('sponsor_licence', 'Sponsor Licence'),
      ('overseas_setup', 'Overseas Company Setup'),
      ('global_payroll', 'Global Payroll'),
      ('skilled_worker', 'Skilled Worker Sponsorship'),
    ],
  ),
];

final Map<String, String> productLabels = {
  for (final unit in catalogue)
    for (final product in unit.$3) product.$1: product.$2,
};

final Map<String, String> unitOfProduct = {
  for (final unit in catalogue)
    for (final product in unit.$3) product.$1: unit.$1,
};

/// Home unit with probability 0.70, otherwise one of the other four; the
/// product is uniform within the chosen unit.
String pickProduct(UserSpec owner) {
  final others = catalogue.where((unit) => unit.$1 != owner.homeUnit).toList();
  final unit = rng.nextDouble() < 0.70
      ? catalogue.firstWhere((unit) => unit.$1 == owner.homeUnit)
      : pickWeighted(others, [for (final u in others) unitVolume[u.$1]!]);
  return pickWeighted(unit.$3, [
    for (final product in unit.$3) productWeight[product.$1] ?? 1.0,
  ]).$1;
}

class UserSpec {
  const UserSpec({
    required this.id,
    required this.name,
    required this.role,
    required this.homeUnit,
    required this.leadWeight,
    required this.opsWeight,
    required this.targetFactor,
    required this.baselineTargetMinor,
  });

  final String id;
  final String name;
  final String role;

  /// Business unit this rep mostly sells for (~70% of their leads).
  final String homeUnit;
  final double leadWeight;
  final double opsWeight;
  final double targetFactor;
  final int baselineTargetMinor;
}

const List<UserSpec> userSpecs = [
  UserSpec(
    id: 'rep_01',
    name: 'Sunny',
    role: 'account_executive',
    homeUnit: 'cloud',
    leadWeight: 1.10,
    opsWeight: 0.12,
    targetFactor: 0.88,
    baselineTargetMinor: 500000,
  ),
  UserSpec(
    id: 'rep_02',
    name: 'Mamun',
    role: 'account_executive',
    homeUnit: 'lawyer',
    leadWeight: 1.50,
    opsWeight: 0.10,
    targetFactor: 0.88,
    baselineTargetMinor: 500000,
  ),
  UserSpec(
    id: 'rep_03',
    name: 'Irteza',
    role: 'account_executive',
    homeUnit: 'hr',
    leadWeight: 1.70,
    opsWeight: 0.32,
    targetFactor: 1.10,
    baselineTargetMinor: 500000,
  ),
  UserSpec(
    id: 'rep_04',
    name: 'Krishna',
    role: 'sales_rep',
    homeUnit: 'accountant',
    leadWeight: 0.80,
    opsWeight: 0.22,
    targetFactor: 1.15,
    baselineTargetMinor: 200000,
  ),
  UserSpec(
    id: 'rep_05',
    name: 'Shahriar',
    role: 'sales_rep',
    homeUnit: 'global',
    leadWeight: 0.50,
    opsWeight: 0.00,
    targetFactor: 1.25,
    baselineTargetMinor: 100000,
  ),
];

class LeadDraft {
  LeadDraft({
    required this.id,
    required this.accountId,
    required this.ownerId,
    required this.productId,
    required this.source,
    required this.createdAt,
    this.firstContactedAt,
  });

  final String id;
  final String accountId;
  final String ownerId;
  final String productId;
  final String source;
  final DateTime createdAt;
  DateTime? firstContactedAt;
  String status = 'new';
  String? convertedDealId;
  DateTime? nextFollowUpAt;
  String? lostReason;
}

class DealDraft {
  DealDraft({
    required this.id,
    required this.leadId,
    required this.accountId,
    required this.ownerId,
    required this.productId,
    required this.title,
    required this.valueMinor,
    required this.createdAt,
    required this.leadOwnerId,
    required this.leadSource,
  });

  final String id;
  final String? leadId;
  final String accountId;
  String ownerId;
  final String productId;
  final String title;
  int valueMinor;
  final DateTime createdAt;
  final String? leadOwnerId;
  final String? leadSource;
  String stage = 'new';
  String outcome = 'open';
  DateTime? closedAt;
  double? probability;
  DateTime? lastActivityAt;
  bool sameDay = false;
}

String iso(DateTime value) => value.toUtc().toIso8601String();

DateTime randomBetween(DateTime from, DateTime to) {
  final seconds = to.difference(from).inSeconds;
  if (seconds <= 0) return from;
  return from.add(Duration(seconds: rng.nextInt(seconds)));
}

DateTime addDays(DateTime value, double days) =>
    value.add(Duration(minutes: (days * 1440).round()));

DateTime addHours(DateTime value, int hours) =>
    value.add(Duration(hours: hours));

DateTime addMinutes(DateTime value, int minutes) =>
    value.add(Duration(minutes: minutes));

int weightedIndex(List<double> weights) {
  final total = weights.fold<double>(0, (sum, value) => sum + value);
  var roll = rng.nextDouble() * total;
  for (var i = 0; i < weights.length; i++) {
    roll -= weights[i];
    if (roll <= 0) return i;
  }
  return weights.length - 1;
}

T pickWeighted<T>(List<T> items, List<double> weights) =>
    items[weightedIndex(weights)];

double normal(double mean, double stdDev) {
  final u1 = max(1e-9, 1 - rng.nextDouble());
  final u2 = rng.nextDouble();
  return mean + stdDev * sqrt(-2 * log(u1)) * cos(2 * pi * u2);
}

int roundTo(int value, int step) => (value / step).round() * step;

String monthKey(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}';

String padId(int value, int width) => value.toString().padLeft(width, '0');

void main() {
  final users = [
    for (final spec in userSpecs)
      {
        'id': spec.id,
        'display_name': spec.name,
        'job_role': spec.role,
        'home_unit_id': spec.homeUnit,
        'active': true,
      },
  ];

  // 70 UK small businesses and 50 private individuals. Immigration products
  // are bought by people, everything else by companies.
  final accounts = <Map<String, dynamic>>[];
  final businessNames = <String>{};
  for (var i = 0; businessNames.length < 70; i++) {
    businessNames.add(
      '${placeWords[i % placeWords.length]} '
      '${tradeWords[(i ~/ placeWords.length + i * 3) % tradeWords.length]}',
    );
  }
  for (final name in businessNames) {
    accounts.add({
      'id': 'acc_${padId(accounts.length + 1, 3)}',
      'name': name,
      'kind': 'business',
      'industry': industries[accounts.length % industries.length],
      'size_band': sizeBands[accounts.length % 3],
    });
  }
  final personNames = <String>{};
  for (var i = 0; personNames.length < 50; i++) {
    personNames.add(
      '${firstNames[i % firstNames.length]} '
      '${lastNames[(i * 7 + i ~/ firstNames.length) % lastNames.length]}',
    );
  }
  for (final name in personNames) {
    accounts.add({
      'id': 'acc_${padId(accounts.length + 1, 3)}',
      'name': name,
      'kind': 'individual',
      'industry': null,
      'size_band': null,
    });
  }
  final businessAccounts = accounts
      .where((account) => account['kind'] == 'business')
      .toList();
  final individualAccounts = accounts
      .where((account) => account['kind'] == 'individual')
      .toList();
  Map<String, dynamic> accountFor(String productId) {
    final pool = individualProducts.contains(productId)
        ? individualAccounts
        : businessAccounts;
    return pool[rng.nextInt(pool.length)];
  }

  final leads = <LeadDraft>[];
  for (var i = 0; i < 400; i++) {
    final spec = pickWeighted(
      userSpecs,
      userSpecs.map((user) => user.leadWeight).toList(),
    );
    final productId = pickProduct(spec);
    final account = accountFor(productId);
    final source = pickWeighted(sources, sourceWeights);
    final createdAt = randomBetween(
      periodStart.add(const Duration(days: 1)),
      asOf.subtract(const Duration(days: 1)),
    );

    DateTime? firstContact;
    if (rng.nextDouble() < 0.78) {
      final baseHours = switch (source) {
        'outbound' => 2 + rng.nextInt(22),
        'inbound' => 3 + rng.nextInt(69),
        'referral' => 1 + rng.nextInt(47),
        'event' => 6 + rng.nextInt(114),
        'partner' => 2 + rng.nextInt(46),
        _ => 1 + rng.nextInt(95),
      };
      final candidate = createdAt.add(Duration(hours: baseHours));
      if (candidate.isBefore(asOf)) firstContact = candidate;
    }

    leads.add(
      LeadDraft(
        id: 'lead_${padId(i + 1, 4)}',
        accountId: account['id'] as String,
        ownerId: spec.id,
        productId: productId,
        source: source,
        createdAt: createdAt,
        firstContactedAt: firstContact,
      ),
    );
  }

  // Pick a stable set of leads that became opportunities. These are the only
  // leads that receive a linked deal, which keeps lead → deal joins coherent.
  final conversionCandidates = leads
      .where(
        (lead) =>
            lead.firstContactedAt != null &&
            lead.createdAt.isBefore(asOf.subtract(const Duration(days: 15))),
      )
      .toList();
  // Recent leads (from mid-June) convert a little more often, so the latest
  // months have enough fresh opportunities for the October story.
  final conversionKey = <LeadDraft, double>{
    for (final lead in conversionCandidates)
      lead:
          rng.nextDouble() -
          (lead.createdAt.isAfter(DateTime.utc(2026, 6, 15)) ? 0.30 : 0),
  };
  conversionCandidates.sort(
    (a, b) => conversionKey[a]!.compareTo(conversionKey[b]!),
  );
  final convertedLeads = conversionCandidates.take(155).toList();

  final deals = <DealDraft>[];
  var dealCounter = 0;
  for (final lead in convertedLeads) {
    final account = accounts.firstWhere((item) => item['id'] == lead.accountId);
    final owner = userSpecs.firstWhere((user) => user.id == lead.ownerId);
    final accountName = account['name'] as String;
    final value = productValue(lead.productId);
    final createdAt = addDays(lead.createdAt, (1 + rng.nextInt(7)).toDouble());
    dealCounter++;
    deals.add(
      DealDraft(
        id: 'deal_${padId(dealCounter, 4)}',
        leadId: lead.id,
        accountId: lead.accountId,
        ownerId: owner.id,
        productId: lead.productId,
        title: '${productLabels[lead.productId]} — $accountName',
        valueMinor: value,
        createdAt: createdAt,
        leadOwnerId: lead.ownerId,
        leadSource: lead.source,
      ),
    );
  }

  // A small number of standalone expansion deals exercise the nullable
  // lead_id path.
  for (var i = 0; i < 25; i++) {
    final owner = pickWeighted(
      userSpecs,
      userSpecs.map((user) => user.leadWeight).toList(),
    );
    final productId = pickProduct(owner);
    final account = accountFor(productId);
    final accountName = account['name'] as String;
    dealCounter++;
    deals.add(
      DealDraft(
        id: 'deal_${padId(dealCounter, 4)}',
        leadId: null,
        accountId: account['id'] as String,
        ownerId: owner.id,
        productId: productId,
        title: '${productLabels[productId]} — $accountName',
        valueMinor: productValue(productId),
        createdAt: randomBetween(
          periodStart.add(const Duration(days: 45)),
          asOf.subtract(const Duration(days: 8)),
        ),
        leadOwnerId: null,
        leadSource: null,
      ),
    );
  }

  // Ten per cent of linked deals are reassigned to a different current owner.
  for (final deal in deals) {
    if (deal.leadOwnerId != null && rng.nextDouble() < 0.10) {
      final alternatives = userSpecs
          .where((user) => user.id != deal.leadOwnerId)
          .toList();
      deal.ownerId = alternatives[rng.nextInt(alternatives.length)].id;
    }
  }

  // Outcome allocation. Every deal created in the last 25 days stays open so
  // its timestamps remain coherent; five deliberately old deals stay open to
  // exercise long-running pipeline states.
  final sortedDeals = [...deals]
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  final openDeals = <DealDraft>{};
  for (final deal in sortedDeals) {
    if (deal.createdAt.isAfter(asOf.subtract(const Duration(days: 25)))) {
      openDeals.add(deal);
    }
  }
  final olderDeals =
      sortedDeals
          .where(
            (deal) => deal.createdAt.isBefore(
              asOf.subtract(const Duration(days: 120)),
            ),
          )
          .toList()
        ..shuffle(rng);
  openDeals.addAll(olderDeals.take(5));
  // Cloud deals run long, so they make up most of the open pipeline.
  final openPool =
      sortedDeals.where((deal) => !openDeals.contains(deal)).toList()
        ..shuffle(rng)
        ..sort(
          (a, b) => (unitOfProduct[a.productId] == 'cloud' ? 0 : 1).compareTo(
            unitOfProduct[b.productId] == 'cloud' ? 0 : 1,
          ),
        );
  openDeals.addAll(openPool.take(max(0, 60 - openDeals.length)));
  // Keep at least two older JR deals open: the conversion-bottleneck story.
  final olderJr = sortedDeals
      .where(
        (deal) =>
            deal.productId == 'jr' &&
            deal.createdAt.isBefore(asOf.subtract(const Duration(days: 45))),
      )
      .toList();
  for (final deal in olderJr.take(2)) {
    openDeals.add(deal);
  }

  // Accountant deals win more often (+0.15 on the ordering key).
  final winKey = <DealDraft, double>{
    for (final deal in sortedDeals)
      deal:
          rng.nextDouble() -
          (unitOfProduct[deal.productId] == 'accountant' ? 0.15 : 0),
  };
  final closedDeals =
      sortedDeals.where((deal) => !openDeals.contains(deal)).toList()
        ..sort((a, b) => winKey[a]!.compareTo(winKey[b]!));
  for (var i = 0; i < closedDeals.length; i++) {
    final deal = closedDeals[i];
    deal.outcome = i < 65 ? 'won' : 'lost';
    final maxAgeDays = asOf.difference(deal.createdAt).inDays;
    final longCycle = rng.nextDouble() < 0.10;
    final desiredCycle = deal.outcome == 'won'
        ? longCycle
              ? 70 + rng.nextInt(51)
              : 12 + rng.nextInt(49)
        : longCycle
        ? 60 + rng.nextInt(31)
        : 10 + rng.nextInt(41);
    final unitFactor =
        (unitCycle[unitOfProduct[deal.productId]] ?? 1.0) *
        (productCycle[deal.productId] ?? 1.0);
    final cycle = min(
      (desiredCycle * unitFactor).round(),
      max(5, maxAgeDays - 1),
    );
    deal.closedAt = addDays(deal.createdAt, cycle.toDouble());
    if (deal.closedAt!.isAfter(asOf)) {
      deal.closedAt = asOf.subtract(const Duration(days: 1));
    }
  }

  // Three won deals convert on the same day to exercise a short cycle.
  final sameDayCandidates = closedDeals
      .where(
        (deal) =>
            deal.outcome == 'won' &&
            deal.createdAt.isBefore(asOf.subtract(const Duration(days: 30))),
      )
      .take(3)
      .toList();
  for (final deal in sameDayCandidates) {
    deal.sameDay = true;
    deal.closedAt = addHours(deal.createdAt, 8);
  }

  // October story, set explicitly: each rep's October wins come from recent
  // opportunities in the listed unit, at a value inside that product's band.
  // Mamun's JR win is the month's largest; Lawyer is the biggest unit and
  // Accountant the smallest; natural October wins are dropped below.
  const mamunOctoberWinMinor = 790000;
  final forcedOctober = <DealDraft>{};
  bool recentForOctober(DealDraft deal) =>
      deal.createdAt.isAfter(DateTime.utc(2026, 7, 10)) &&
      deal.createdAt.isBefore(DateTime.utc(2026, 9, 25));
  bool inBand(DealDraft deal, int minor) {
    final (low, high) = productPriceBands[deal.productId]!;
    return minor >= low * 100 && minor <= high * 100;
  }

  for (final spec in userSpecs) {
    for (final (pick, value) in octoberBook[spec.id]!) {
      bool matches(DealDraft deal) =>
          deal.ownerId == spec.id &&
          deal.outcome != 'won' &&
          !forcedOctober.contains(deal) &&
          deal.createdAt.isBefore(DateTime.utc(2026, 9, 25)) &&
          (pick == 'jr'
              ? deal.productId == 'jr'
              : deal.productId != 'jr' &&
                    unitOfProduct[deal.productId] == pick);
      // Newest matching opportunity first (realistic lead-to-win), preferring
      // a product whose price band holds the planned value.
      final candidates = deals.where(matches).toList()
        ..sort((a, b) {
          final band = (inBand(a, value) ? 0 : 1).compareTo(
            inBand(b, value) ? 0 : 1,
          );
          return band != 0 ? band : b.createdAt.compareTo(a.createdAt);
        });
      if (candidates.isEmpty) continue;
      final deal = candidates.first;
      final (low, high) = productPriceBands[deal.productId]!;
      deal.outcome = 'won';
      deal.stage = 'won';
      deal.sameDay = false;
      deal.valueMinor = pick == 'jr'
          ? mamunOctoberWinMinor
          : roundTo(value.clamp(low * 100, high * 100), 5000);
      deal.closedAt = randomBetween(
        DateTime.utc(2026, 10, 1),
        DateTime.utc(2026, 10, 31, 23, 59),
      );
      openDeals.remove(deal);
      forcedOctober.add(deal);
    }
  }

  // September gets its own deliberate wins so "vs previous" compares October
  // with a believable month rather than a near-empty one.
  for (final spec in userSpecs) {
    final candidates =
        deals
            .where(
              (deal) =>
                  deal.ownerId == spec.id &&
                  deal.outcome != 'won' &&
                  deal.productId != 'jr' &&
                  deal.createdAt.isAfter(DateTime.utc(2026, 6, 1)) &&
                  deal.createdAt.isBefore(DateTime.utc(2026, 8, 20)),
            )
            .toList()
          ..shuffle(rng)
          ..sort(
            (a, b) => (unitOfProduct[a.productId] == spec.homeUnit ? 0 : 1)
                .compareTo(unitOfProduct[b.productId] == spec.homeUnit ? 0 : 1),
          );
    final wins = spec.id == 'rep_05' ? 1 : septemberWins;
    for (final deal in candidates.take(wins)) {
      deal.outcome = 'won';
      deal.stage = 'won';
      deal.sameDay = false;
      deal.closedAt = randomBetween(
        DateTime.utc(2026, 9, 1),
        DateTime.utc(2026, 9, 30, 20),
      );
      openDeals.remove(deal);
    }
  }

  // October also loses deals: a believable win rate, and no unit that won
  // everything it closed.
  for (final spec in userSpecs) {
    final candidates =
        deals
            .where(
              (deal) =>
                  deal.ownerId == spec.id &&
                  deal.outcome != 'won' &&
                  deal.productId != 'jr' &&
                  !forcedOctober.contains(deal) &&
                  recentForOctober(deal),
            )
            .toList()
          ..shuffle(rng)
          ..sort(
            (a, b) => (unitOfProduct[a.productId] == spec.homeUnit ? 0 : 1)
                .compareTo(unitOfProduct[b.productId] == spec.homeUnit ? 0 : 1),
          );
    final losses = octoberLosses;
    for (final deal in candidates.take(losses)) {
      deal.outcome = 'lost';
      deal.stage = 'lost';
      deal.sameDay = false;
      deal.closedAt = randomBetween(
        DateTime.utc(2026, 10, 1),
        DateTime.utc(2026, 10, 31, 23, 59),
      );
      openDeals.remove(deal);
    }
  }

  // Natural October wins become losses, so October is exactly the book above
  // plus a believable number of lost deals.
  for (final deal in deals) {
    final closed = deal.closedAt;
    if (deal.outcome != 'won' || closed == null) continue;
    if (forcedOctober.contains(deal)) continue;
    final inOctober =
        !closed.isBefore(DateTime.utc(2026, 9, 30, 23)) &&
        closed.isBefore(DateTime.utc(2026, 11, 1));
    if (!inOctober) continue;
    deal.outcome = 'lost';
    deal.stage = 'lost';
  }

  // Choose an open-stage target based on age, then build stage histories.
  for (final deal in openDeals) {
    final ageDays = asOf.difference(deal.createdAt).inDays;
    final stageChoices = ageDays < 14
        ? ['new', 'qualified']
        : ageDays < 45
        ? ['qualified', 'discovery', 'proposal']
        : ['proposal', 'negotiation', 'proposal'];
    deal.stage = pickWeighted(
      stageChoices,
      List<double>.generate(stageChoices.length, (index) => 1),
    );
  }
  final newStageDeals = openDeals
      .where((deal) => asOf.difference(deal.createdAt).inDays < 14)
      .take(3)
      .toList();
  for (final deal in newStageDeals) {
    deal.stage = 'new';
  }
  for (final deal in openDeals) {
    final ageDays = asOf.difference(deal.createdAt).inDays;
    if (deal.productId == 'jr' && ageDays >= 14) deal.stage = 'proposal';
  }

  final events = <Map<String, dynamic>>[];
  var eventCounter = 0;
  String nextEventId() => 'evt_${padId(++eventCounter, 4)}';

  void addEvent(
    String dealId,
    DateTime occurredAt,
    String? fromStage,
    String toStage,
  ) {
    events.add({
      'id': nextEventId(),
      'deal_id': dealId,
      'occurred_at': iso(occurredAt),
      'from_stage': fromStage,
      'to_stage': toStage,
      'source': 'synthetic_fixture',
    });
  }

  final missingHistoryIds = openDeals.take(5).map((deal) => deal.id).toSet();

  for (final deal in deals) {
    if (missingHistoryIds.contains(deal.id)) {
      continue;
    }

    if (deal.outcome == 'open') {
      final targetIndex = pipeline.indexOf(deal.stage);
      final path = ['new', ...pipeline.sublist(1, targetIndex + 1)];
      if (path.length == 1) {
        addEvent(deal.id, deal.createdAt, null, 'new');
        continue;
      }

      final ageDays = asOf.difference(deal.createdAt).inMinutes / 1440.0;
      // Open JR deals have been stuck in Proposal for weeks (the bottleneck).
      final currentAge = deal.productId == 'jr' && deal.stage == 'proposal'
          ? min(40 + rng.nextDouble() * 30, ageDays * 0.8)
          : min(1 + rng.nextDouble() * 17, ageDays * 0.55);
      final previousDays = max(0.1, ageDays - currentAge);
      final weights = [
        for (final stage in path.sublist(0, path.length - 1))
          dwellWeight(stage, deal),
      ];
      final totalWeight = weights.fold<double>(0, (sum, value) => sum + value);

      var cursor = deal.createdAt;
      addEvent(deal.id, cursor, null, 'new');
      for (var i = 0; i < weights.length; i++) {
        final share = totalWeight == 0
            ? 1 / weights.length
            : weights[i] / totalWeight;
        cursor = addDays(cursor, previousDays * share);
        if (cursor.isAfter(asOf)) cursor = asOf;
        addEvent(deal.id, cursor, path[i], path[i + 1]);
      }
      continue;
    }

    final closedAt = deal.closedAt!;
    List<String> path;
    if (deal.sameDay) {
      path = ['new', 'qualified', 'won'];
    } else if (deal.outcome == 'won') {
      path = [
        'new',
        'qualified',
        'discovery',
        'proposal',
        'negotiation',
        'won',
      ];
      if (rng.nextDouble() < 0.12) path.remove('discovery');
      if (rng.nextDouble() < 0.05) {
        path = [
          'new',
          'qualified',
          'discovery',
          'proposal',
          'negotiation',
          'proposal',
          'negotiation',
          'won',
        ];
      }
    } else {
      final stop = pickWeighted(
        ['qualified', 'discovery', 'proposal', 'negotiation'],
        [0.10, 0.20, 0.40, 0.30],
      );
      final stopIndex = pipeline.indexOf(stop);
      path = ['new', ...pipeline.sublist(1, stopIndex + 1), 'lost'];
    }

    if (deal.sameDay) {
      addEvent(deal.id, deal.createdAt, null, 'new');
      addEvent(deal.id, addHours(deal.createdAt, 3), 'new', 'qualified');
      addEvent(deal.id, closedAt, 'qualified', 'won');
      deal.stage = 'won';
      continue;
    }

    final cycleMinutes = max(60, closedAt.difference(deal.createdAt).inMinutes);
    final weights = [
      for (final stage in path.sublist(0, path.length - 1))
        dwellWeight(stage, deal) * (deal.outcome == 'lost' ? 1.35 : 1.0),
    ];
    final totalWeight = weights.fold<double>(0, (sum, value) => sum + value);

    var cursor = deal.createdAt;
    addEvent(deal.id, cursor, null, 'new');
    for (var i = 0; i < weights.length; i++) {
      final share = totalWeight == 0
          ? 1 / weights.length
          : weights[i] / totalWeight;
      cursor = cursor.add(
        Duration(minutes: max(1, (cycleMinutes * share).round())),
      );
      if (cursor.isAfter(closedAt)) cursor = closedAt;
      addEvent(deal.id, cursor, path[i], path[i + 1]);
    }
    deal.stage = path.last;
    deal.closedAt = closedAt;
  }

  // Make sure every closed deal's final event matches its closed timestamp.
  for (final deal in deals) {
    if (deal.outcome == 'open') continue;
    final dealEvents = events
        .where((event) => event['deal_id'] == deal.id)
        .toList();
    if (dealEvents.isNotEmpty) {
      deal.closedAt = DateTime.parse(dealEvents.last['occurred_at'] as String);
    }
  }

  // Resolve lead statuses now that converted deals exist.
  for (final lead in leads) {
    if (convertedLeads.contains(lead)) {
      lead.status = 'converted';
      final deal = deals.firstWhere((deal) => deal.leadId == lead.id);
      lead.convertedDealId = deal.id;
      lead.nextFollowUpAt = null;
      continue;
    }
    if (lead.firstContactedAt == null) {
      lead.status = rng.nextDouble() < 0.62 ? 'new' : 'lost';
    } else {
      lead.status = pickWeighted(
        ['lost', 'qualified', 'contacted', 'unqualified', 'new'],
        [0.20, 0.25, 0.35, 0.10, 0.10],
      );
    }
    if (lead.status == 'lost') {
      lead.lostReason = pickWeighted(
        [
          'No budget',
          'Chose competitor',
          'No response',
          'Timing not right',
          'Not a fit',
        ],
        [0.28, 0.20, 0.24, 0.18, 0.10],
      );
    }
    if (lead.status != 'lost' && lead.status != 'converted') {
      if (rng.nextDouble() < 0.62) {
        lead.nextFollowUpAt = addDays(asOf, -10 + rng.nextDouble() * 24);
      }
    }
  }

  final activities = <Map<String, dynamic>>[];
  var activityCounter = 0;

  Map<String, dynamic> makeActivity({
    required UserSpec owner,
    String? dealId,
    String? leadId,
    String? accountId,
    required DateTime startedAt,
    required String category,
    required String type,
    required String subcategory,
    required int? duration,
    required String quality,
    required String summary,
  }) {
    return {
      'id': 'act_${padId(++activityCounter, 5)}',
      'owner_id': owner.id,
      'lead_id': leadId,
      'deal_id': dealId,
      'account_id': accountId,
      'type': type,
      'work_category': category,
      'work_subcategory': subcategory,
      'started_at': iso(startedAt),
      'duration_minutes': duration,
      'summary': summary,
      'source': 'synthetic_fixture',
      'time_quality': quality,
    };
  }

  for (var i = 0; i < 2800; i++) {
    final owner = pickWeighted(
      userSpecs,
      userSpecs.map((user) => user.leadWeight).toList(),
    );

    Map<String, dynamic>? deal;
    LeadDraft? lead;
    final linkRoll = rng.nextDouble();
    if (linkRoll < 0.70) {
      final ownedDeals = deals
          .where((item) => item.ownerId == owner.id)
          .toList();
      if (ownedDeals.isNotEmpty) {
        deal = _dealAsMap(ownedDeals[rng.nextInt(ownedDeals.length)]);
      }
    } else if (linkRoll < 0.90) {
      final ownedLeads = leads
          .where((item) => item.ownerId == owner.id)
          .toList();
      if (ownedLeads.isNotEmpty) {
        lead = ownedLeads[rng.nextInt(ownedLeads.length)];
      }
    }

    DateTime startedAt;
    var postClose = false;
    if (deal != null) {
      final createdAt = DateTime.parse(deal['created_at'] as String);
      final closedAtRaw = deal['closed_at'] as String?;
      final closedAt = closedAtRaw == null ? null : DateTime.parse(closedAtRaw);
      if (deal['outcome'] == 'won' &&
          closedAt != null &&
          rng.nextDouble() < 0.28) {
        postClose = true;
        startedAt = randomBetween(
          closedAt,
          minDateTime(asOf, closedAt.add(const Duration(days: 30))),
        );
      } else {
        startedAt = randomBetween(createdAt, closedAt ?? asOf);
      }
    } else if (lead != null) {
      startedAt = randomBetween(lead.createdAt, asOf);
    } else {
      startedAt = randomBetween(periodStart, asOf);
    }

    final category = chooseCategory(owner, deal, postClose, linkRoll);
    final descriptor = descriptorFor(category, owner);
    final duration = chooseDuration(descriptor.type, category);
    final quality = duration == null
        ? 'not_recorded'
        : rng.nextDouble() < 0.05
        ? 'estimated'
        : 'logged';
    final accountName = deal?['account_id'] != null
        ? accounts.firstWhere(
            (account) => account['id'] == deal!['account_id'],
          )['name']
        : lead != null
        ? accounts.firstWhere(
            (account) => account['id'] == lead!.accountId,
          )['name']
        : 'internal';

    activities.add(
      makeActivity(
        owner: owner,
        dealId: deal?['id'] as String?,
        leadId: deal?['lead_id'] as String? ?? lead?.id,
        accountId: deal?['account_id'] as String? ?? lead?.accountId,
        startedAt: startedAt,
        category: category,
        type: descriptor.type,
        subcategory: descriptor.subcategory,
        duration: duration,
        quality: quality,
        summary: '${descriptor.label} — $accountName',
      ),
    );
  }

  // Guarantee the designed operational-workload story for Irteza in October.
  final irteza = userSpecs.firstWhere((user) => user.id == 'rep_03');
  final irtezaWonDeals = deals
      .where((deal) => deal.ownerId == irteza.id && deal.outcome == 'won')
      .toList();
  for (var i = 0; i < 12; i++) {
    final day = 1 + rng.nextInt(30);
    final startedAt = DateTime.utc(
      2026,
      10,
      day,
      9 + rng.nextInt(8),
      rng.nextInt(60),
    );
    final linkedDeal = irtezaWonDeals.isEmpty
        ? null
        : irtezaWonDeals[rng.nextInt(irtezaWonDeals.length)];
    activities.add(
      makeActivity(
        owner: irteza,
        dealId: linkedDeal?.id,
        leadId: linkedDeal?.leadId,
        accountId: linkedDeal?.accountId,
        startedAt: startedAt,
        category: 'operations',
        type: i.isEven ? 'onboarding' : 'support',
        subcategory: i.isEven ? 'customer_setup' : 'customer_support',
        duration: 60 + rng.nextInt(121),
        quality: 'logged',
        summary: i.isEven
            ? 'Post-sale customer setup — ${linkedDeal?.title ?? 'account'}'
            : 'Customer support follow-up — ${linkedDeal?.title ?? 'account'}',
      ),
    );
  }

  // Set each deal's last activity from its activities and stage events.
  for (final deal in deals) {
    final linkedActivities = activities.where(
      (activity) => activity['deal_id'] == deal.id,
    );
    final linkedEvents = events.where((event) => event['deal_id'] == deal.id);
    final timestamps = <DateTime>[
      ...linkedActivities.map(
        (activity) => DateTime.parse(activity['started_at'] as String),
      ),
      ...linkedEvents.map(
        (event) => DateTime.parse(event['occurred_at'] as String),
      ),
    ];
    if (timestamps.isNotEmpty) {
      timestamps.sort();
      deal.lastActivityAt = timestamps.last;
    }
  }

  // Targets are derived from actual won value so the demo has a deliberate
  // mix of above- and below-target reps.
  final wonByOwnerMonth = <String, int>{};
  for (final deal in deals) {
    if (deal.outcome != 'won' || deal.closedAt == null) continue;
    final key = '${deal.ownerId}|${monthKey(deal.closedAt!)}';
    wonByOwnerMonth[key] = (wonByOwnerMonth[key] ?? 0) + deal.valueMinor;
  }

  final targets = <Map<String, dynamic>>[];
  final months = <DateTime>[
    for (var i = 0; i < 12; i++) DateTime.utc(2025, 11 + i, 1),
  ];
  for (final user in userSpecs) {
    for (final month in months) {
      final monthLabel = monthKey(month);
      if ((user.id == 'rep_05' && monthLabel == '2025-11') ||
          (user.id == 'rep_05' && monthLabel == '2025-12') ||
          (user.id == 'rep_04' && monthLabel == '2026-03')) {
        continue;
      }
      final won = wonByOwnerMonth['${user.id}|$monthLabel'] ?? 0;
      var target = won == 0
          ? user.baselineTargetMinor
          : max(user.baselineTargetMinor, (won * user.targetFactor).round());
      target = roundTo(target, 100000);
      targets.add({
        'owner_id': user.id,
        'period_month': monthLabel,
        'currency': 'GBP',
        'won_value_target_minor': target,
      });
    }
  }

  final focusDeal = deals.firstWhere(
    (deal) =>
        deal.stage == 'proposal' &&
        deal.outcome == 'open' &&
        deal.productId == 'jr',
    orElse: () => deals.first,
  );

  final scenarios = [
    {
      'id': 'executive_overview',
      'label': 'Executive overview',
      'description': 'The default October performance story.',
      'route': '/overview',
      'period': 'thisMonth',
    },
    {
      'id': 'conversion_bottleneck',
      'label': 'Conversion bottleneck',
      'description': 'Lawyer JR deals are dwelling in Proposal.',
      'route': '/conversion',
      'period': 'quarter',
      'unit_id': 'lawyer',
      'stage': 'proposal',
      'focus_deal_id': focusDeal.id,
    },
    {
      'id': 'operational_workload',
      'label': 'Operational workload',
      'description': 'Irteza’s logged time is weighted towards operations.',
      'route': '/workload',
      'period': 'last30Days',
      'owner_id': 'rep_03',
    },
    {
      'id': 'team_comparison',
      'label': 'Team comparison',
      'description': 'Compare outcomes with sample sizes in view.',
      'route': '/team',
      'period': 'thisMonth',
    },
  ];

  final manifest = {
    'schema_version': '1.0.0',
    'dataset_id': 'pulse-demo-v1',
    'dataset_label': 'PULSE Executive Demo',
    'data_kind': 'synthetic',
    'currency': 'GBP',
    'timezone': 'Europe/London',
    'as_of': iso(asOf),
    'period_start': iso(periodStart),
    'period_end': iso(periodEnd),
    'source_description':
        'Generated CRM-style sample dataset; not connected to monday.com',
  };

  leads.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  deals.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  events.sort((a, b) {
    final dealCompare = (a['deal_id'] as String).compareTo(
      b['deal_id'] as String,
    );
    if (dealCompare != 0) return dealCompare;
    return (a['occurred_at'] as String).compareTo(b['occurred_at'] as String);
  });
  activities.sort(
    (a, b) => (a['started_at'] as String).compareTo(b['started_at'] as String),
  );
  targets.sort((a, b) {
    final monthCompare = (a['period_month'] as String).compareTo(
      b['period_month'] as String,
    );
    if (monthCompare != 0) return monthCompare;
    return (a['owner_id'] as String).compareTo(b['owner_id'] as String);
  });

  final output = {
    'manifest': manifest,
    'users': users,
    'accounts': accounts,
    'leads': [
      for (final lead in leads)
        {
          'id': lead.id,
          'account_id': lead.accountId,
          'owner_id': lead.ownerId,
          'product_id': lead.productId,
          'source': lead.source,
          'status': lead.status,
          'created_at': iso(lead.createdAt),
          'first_contacted_at': lead.firstContactedAt == null
              ? null
              : iso(lead.firstContactedAt!),
          'converted_deal_id': lead.convertedDealId,
          'next_follow_up_at': lead.nextFollowUpAt == null
              ? null
              : iso(lead.nextFollowUpAt!),
          'lost_reason': lead.lostReason,
        },
    ],
    'deals': [
      for (final deal in deals)
        {
          'id': deal.id,
          'lead_id': deal.leadId,
          'account_id': deal.accountId,
          'owner_id': deal.ownerId,
          'product_id': deal.productId,
          'title': deal.title,
          'value_minor': deal.valueMinor,
          'currency': 'GBP',
          'stage': deal.stage,
          'created_at': iso(deal.createdAt),
          'closed_at': deal.closedAt == null ? null : iso(deal.closedAt!),
          'outcome': deal.outcome,
          'probability': probabilityFor(deal),
          'last_activity_at': deal.lastActivityAt == null
              ? null
              : iso(deal.lastActivityAt!),
        },
    ],
    'deal_stage_events': events,
    'activities': activities,
    'targets': targets,
    'insight_scenarios': scenarios,
    'business_units': [
      for (final unit in catalogue)
        {
          'id': unit.$1,
          'label': unit.$2,
          'products': [
            for (final product in unit.$3)
              {'id': product.$1, 'label': product.$2},
          ],
        },
    ],
  };

  final directory = Directory('assets/data/demo');
  directory.createSync(recursive: true);
  const encoder = JsonEncoder.withIndent('  ');
  for (final entry in output.entries) {
    final file = File('${directory.path}/${entry.key}.json');
    file.writeAsStringSync('${encoder.convert(entry.value)}\n');
  }

  stdout.writeln('Wrote demo dataset to ${directory.path}');
  stdout.writeln(
    '  ${leads.length} leads, ${deals.length} deals, '
    '${events.length} stage events, ${activities.length} activities, '
    '${targets.length} targets',
  );
}

/// Deal value for a product, uniform inside its price band, rounded to £50.
int productValue(String productId) {
  final (low, high) = productPriceBands[productId]!;
  final pounds = low + rng.nextInt(high - low + 1);
  return roundTo(pounds * 100, 5000);
}

double dwellWeight(String stage, DealDraft deal) {
  var base = switch (stage) {
    'new' => 1.2,
    'qualified' => 2.4,
    'discovery' => 2.6,
    'proposal' => 5.2,
    'negotiation' => 3.2,
    _ => 1.0,
  };
  // Judicial Review deals stall at Proposal (the conversion-bottleneck story).
  if (stage == 'proposal' && deal.productId == 'jr') {
    base *= 6.0;
  }
  if (stage == 'proposal' && deal.leadSource == 'referral') {
    base *= 0.68;
  }
  if (deal.ownerId == 'rep_03') base *= 1.12;
  return max(0.4, base * (0.7 + rng.nextDouble() * 0.6));
}

DateTime minDateTime(DateTime a, DateTime b) => a.isBefore(b) ? a : b;

Map<String, dynamic> _dealAsMap(DealDraft deal) => {
  'id': deal.id,
  'lead_id': deal.leadId,
  'account_id': deal.accountId,
  'owner_id': deal.ownerId,
  'product_id': deal.productId,
  'created_at': iso(deal.createdAt),
  'closed_at': deal.closedAt == null ? null : iso(deal.closedAt!),
  'outcome': deal.outcome,
};

String chooseCategory(
  UserSpec owner,
  Map<String, dynamic>? deal,
  bool postClose,
  double linkRoll,
) {
  if (owner.id == 'rep_05') {
    return pickWeighted(['sales', 'other', 'unknown'], [0.72, 0.23, 0.05]);
  }
  if (postClose) {
    final hr = deal != null && unitOfProduct[deal['product_id']] == 'hr';
    return pickWeighted([
      'operations',
      'other',
      'sales',
    ], hr ? [0.80, 0.10, 0.10] : [0.70, 0.15, 0.15]);
  }
  if (deal != null && deal['outcome'] == 'open') {
    return pickWeighted(
      ['sales', 'operations', 'other', 'unknown'],
      [0.76, 0.07, 0.12, 0.05],
    );
  }
  if (deal == null && linkRoll >= 0.90) {
    return pickWeighted(
      ['other', 'operations', 'sales', 'unknown'],
      [0.50, 0.20, 0.20, 0.10],
    );
  }
  if (owner.id == 'rep_03') {
    return pickWeighted(
      ['sales', 'operations', 'other', 'unknown'],
      [0.42, 0.45, 0.10, 0.03],
    );
  }
  return pickWeighted(
    ['sales', 'operations', 'other', 'unknown'],
    [0.60, owner.opsWeight, 0.15, 0.05],
  );
}

class Descriptor {
  const Descriptor(this.type, this.subcategory, this.label);

  final String type;
  final String subcategory;
  final String label;
}

Descriptor descriptorFor(String category, UserSpec owner) {
  switch (category) {
    case 'sales':
      final choices = [
        const Descriptor('call', 'prospecting', 'Outbound call'),
        const Descriptor('email', 'follow_up', 'Follow-up email'),
        const Descriptor('meeting', 'discovery', 'Discovery meeting'),
        const Descriptor('demo', 'product_demo', 'Product demo'),
        const Descriptor('proposal', 'proposal', 'Proposal preparation'),
        const Descriptor('negotiation', 'negotiation', 'Negotiation call'),
      ];
      return pickWeighted(choices, [0.18, 0.20, 0.18, 0.16, 0.16, 0.12]);
    case 'operations':
      final choices = [
        const Descriptor('onboarding', 'customer_setup', 'Customer setup'),
        const Descriptor(
          'onboarding',
          'implementation',
          'Implementation handoff',
        ),
        const Descriptor('support', 'customer_support', 'Customer support'),
        const Descriptor(
          'admin',
          'admin_processing',
          'Administrative processing',
        ),
      ];
      return pickWeighted(choices, [0.35, 0.20, 0.28, 0.17]);
    case 'other':
      return pickWeighted(
        [
          const Descriptor(
            'internal_meeting',
            'internal_meeting',
            'Internal meeting',
          ),
          const Descriptor('training', 'training', 'Training'),
        ],
        [0.65, 0.35],
      );
    default:
      return const Descriptor('other', 'unclassified', 'Unclassified work');
  }
}

int? chooseDuration(String type, String category) {
  if (rng.nextDouble() < 0.08) return null;
  final base = switch (type) {
    'onboarding' => 60 + rng.nextInt(181),
    'support' => 30 + rng.nextInt(91),
    'admin' => 15 + rng.nextInt(46),
    'meeting' => 30 + rng.nextInt(61),
    'demo' => 30 + rng.nextInt(61),
    'internal_meeting' => 30 + rng.nextInt(61),
    'training' => 45 + rng.nextInt(76),
    _ => 15 + rng.nextInt(76),
  };
  return base;
}

double? probabilityFor(DealDraft deal) {
  if (deal.outcome == 'won') return 1.0;
  if (deal.outcome == 'lost') return 0.0;
  return switch (deal.stage) {
    'new' => 0.10,
    'qualified' => 0.25,
    'discovery' => 0.40,
    'proposal' => 0.60,
    'negotiation' => 0.80,
    _ => null,
  };
}
