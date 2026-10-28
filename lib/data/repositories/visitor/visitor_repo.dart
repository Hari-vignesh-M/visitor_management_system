import '../../../services/dio_client.dart';
import '../../../services/exceptions/app_exception.dart';
import '../../models/visitor/visitor_model.dart';

class VisitorEndpoints {
  const VisitorEndpoints._();

  static const String visitors = 'visitors';
  static String visitor(String id) => 'visitors/$id';
}


class VisitorRepository {
  VisitorRepository({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// GET /visitors
  Future<List<VisitorModel>> getVisitors() async {
    try {
      final data = await _client.get(VisitorEndpoints.visitors);
      if (data is! List) throw const BadResponseException();
      return data
          .whereType<Map<String, dynamic>>()
          .map(VisitorModel.fromJson)
          .toList();
    } on NotFoundException {
      return [];
    }
  }

  /// GET /visitors/{id}
  Future<VisitorModel> getVisitor(String id) async {
    try {
      return _parseVisitor(await _client.get(VisitorEndpoints.visitor(id)));
    } on NotFoundException {
      throw const NotFoundException('Visitor not found.');
    } on ServerException catch (e) {
      if (e.statusCode != 500) rethrow;
      final visitors = await getVisitors();
      for (final visitor in visitors) {
        if (visitor.id == id) return visitor;
      }
      throw const NotFoundException('Visitor not found.');
    }
  }

  /// POST /visitors - returns the record with the server-generated ID.
  Future<VisitorModel> createVisitor(VisitorModel visitor) async {
    final data = await _client.post(
      VisitorEndpoints.visitors,
      data: visitor.toJson(),
    );
    return _parseVisitor(data);
  }

  /// PUT /visitors/{id} - used for edits and status changes.
  Future<VisitorModel> updateVisitor(VisitorModel visitor) async {
    try {
      final data = await _client.put(
        VisitorEndpoints.visitor(visitor.id),
        data: visitor.toJson(),
      );
      return _parseVisitor(data);
    } on NotFoundException {
      throw const NotFoundException('Visitor no longer exists.');
    }
  }

  /// DELETE /visitors/{id}
  Future<void> deleteVisitor(String id) async {
    try {
      await _client.delete(VisitorEndpoints.visitor(id));
    } on NotFoundException {
    }
  }

  VisitorModel _parseVisitor(dynamic data) {
    if (data is! Map<String, dynamic>) throw const BadResponseException();
    final visitor = VisitorModel.fromJson(data);
    if (visitor.id.isEmpty) throw const BadResponseException();
    return visitor;
  }
}
