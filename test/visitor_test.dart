import 'package:flutter_test/flutter_test.dart';
import 'package:visitor_management_system/data/models/visitor/visitor_model.dart';
import 'package:visitor_management_system/data/repositories/visitor/visitor_repo.dart';
import 'package:visitor_management_system/services/exceptions/app_exception.dart';
import 'package:visitor_management_system/utils/commonFunctions/qr_payload.dart';
import 'package:visitor_management_system/utils/validators/validators.dart';
import 'package:visitor_management_system/viewModel/visitor_view_model/visitor_viewmodel.dart';

/// In-memory repository so view model logic can be tested without network.
class FakeVisitorRepository extends VisitorRepository {
  final Map<String, VisitorModel> store = {};
  int _nextId = 1;

  @override
  Future<List<VisitorModel>> getVisitors() async => store.values.toList();

  @override
  Future<VisitorModel> getVisitor(String id) async {
    final visitor = store[id];
    if (visitor == null) throw const NotFoundException('Visitor not found.');
    return visitor;
  }

  @override
  Future<VisitorModel> createVisitor(VisitorModel visitor) async {
    final saved = visitor.copyWith(id: '${_nextId++}');
    store[saved.id] = saved;
    return saved;
  }

  @override
  Future<VisitorModel> updateVisitor(VisitorModel visitor) async {
    if (!store.containsKey(visitor.id)) throw const NotFoundException();
    store[visitor.id] = visitor;
    return visitor;
  }

  @override
  Future<void> deleteVisitor(String id) async => store.remove(id);
}

VisitorModel draft({String name = 'Rahul Sharma'}) => VisitorModel(
      name: name,
      mobile: '9876543210',
      visitorType: 'Customer',
      project: 'Project A',
      purpose: 'Site Visit',
      createdAt: '',
    );

void main() {
  group('VisitorModel', () {
    test('parses the sample JSON', () {
      final visitor = VisitorModel.fromJson({
        'id': 'VIS001',
        'name': 'Rahul Sharma',
        'mobile': '9876543210',
        'email': 'rahul@example.com',
        'visitor_type': 'Customer',
        'project': 'Project A',
        'purpose': 'Site Visit',
        'status': 'Checked In',
        'created_at': '2026-10-26T10:00:00+05:30',
        'check_in_time': '2026-10-26T10:30:00+05:30',
        'check_out_time': null,
      });

      expect(visitor.id, 'VIS001');
      expect(visitor.status, VisitorStatus.checkedIn);
      expect(visitor.checkOutTime, isNull);
      expect(visitor.toJson()['status'], 'Checked In');
      expect(visitor.toJson()['visitor_type'], 'Customer');
    });

    test('accepts numeric ids and empty email', () {
      final visitor = VisitorModel.fromJson({'id': 7, 'email': ''});
      expect(visitor.id, '7');
      expect(visitor.email, isNull);
    });
  });

  group('QrPayload', () {
    test('round-trips a visitor id', () {
      expect(QrPayload.decode(QrPayload.encode('12')), '12');
    });

    test('accepts a bare id and rejects other QR content', () {
      expect(QrPayload.decode('VIS001'), 'VIS001');
      expect(QrPayload.decode('https://example.com'), isNull);
      expect(QrPayload.decode(''), isNull);
      expect(QrPayload.decode(null), isNull);
    });
  });

  group('Validators', () {
    test('mobile must be exactly 10 digits', () {
      expect(Validators.mobile('9876543210'), isNull);
      expect(Validators.mobile('98765'), isNotNull);
      expect(Validators.mobile(''), isNotNull);
    });

    test('email is optional but validated when entered', () {
      expect(Validators.optionalEmail(''), isNull);
      expect(Validators.optionalEmail('a@b.com'), isNull);
      expect(Validators.optionalEmail('not-an-email'), isNotNull);
    });
  });

  group('VisitorViewModel', () {
    late FakeVisitorRepository repo;
    late VisitorViewModel vm;

    setUp(() {
      repo = FakeVisitorRepository();
      vm = VisitorViewModel(repository: repo);
    });

    test('new visitor is Registered and counted today', () async {
      final result = await vm.registerVisitor(draft());

      expect(result.isSuccess, isTrue);
      expect(result.data!.status, VisitorStatus.registered);
      expect(vm.totalVisitorsToday, 1);
      expect(vm.currentlyCheckedIn, 0);
    });

    test('follows Registered -> Checked In -> Checked Out', () async {
      final id = (await vm.registerVisitor(draft())).data!.id;

      final checkIn = await vm.checkIn(id);
      expect(checkIn.isSuccess, isTrue);
      expect(vm.visitorById(id)!.checkInTime, isNotNull);
      expect(vm.currentlyCheckedIn, 1);

      final checkOut = await vm.checkOut(id);
      expect(checkOut.isSuccess, isTrue);
      expect(vm.visitorById(id)!.status, VisitorStatus.checkedOut);
      expect(vm.currentlyCheckedIn, 0);
      expect(vm.checkedOutToday, 1);
    });

    test('blocks check-out before check-in', () async {
      final id = (await vm.registerVisitor(draft())).data!.id;
      final result = await vm.checkOut(id);
      expect(result.isSuccess, isFalse);
      expect(repo.store[id]!.status, VisitorStatus.registered);
    });

    test('blocks duplicate check-in and re-check-in after checkout', () async {
      final id = (await vm.registerVisitor(draft())).data!.id;
      await vm.checkIn(id);

      expect((await vm.checkIn(id)).isSuccess, isFalse);

      await vm.checkOut(id);
      expect((await vm.checkIn(id)).isSuccess, isFalse);
      expect(repo.store[id]!.status, VisitorStatus.checkedOut);
    });

    test('ignores a second check-in while the first is running', () async {
      final id = (await vm.registerVisitor(draft())).data!.id;
      final results = await Future.wait([vm.checkIn(id), vm.checkIn(id)]);
      expect(results.where((r) => r.isSuccess).length, 1);
    });

    test('search matches name or mobile', () async {
      await vm.registerVisitor(draft(name: 'Rahul Sharma'));
      await vm.registerVisitor(draft(name: 'Priya Nair'));

      vm.search('priya');
      expect(vm.filteredVisitors.map((v) => v.name), ['Priya Nair']);

      vm.search('98765');
      expect(vm.filteredVisitors.length, 2);
    });

    test('delete removes the visitor from the list', () async {
      final id = (await vm.registerVisitor(draft())).data!.id;
      await vm.deleteVisitor(id);
      expect(vm.visitors, isEmpty);
      expect(vm.totalVisitorsToday, 0);
    });

    test('unknown visitor lookup fails with a message', () async {
      final result = await vm.fetchVisitorById('999');
      expect(result.isSuccess, isFalse);
      expect(result.error, 'Visitor not found.');
    });
  });
}
