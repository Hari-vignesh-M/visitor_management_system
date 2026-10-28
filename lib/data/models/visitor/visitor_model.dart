enum VisitorStatus {
  registered('Registered'),
  checkedIn('Checked In'),
  checkedOut('Checked Out');

  const VisitorStatus(this.label);
  final String label;

  static VisitorStatus fromLabel(String? value) {
    return VisitorStatus.values.firstWhere(
      (status) => status.label.toLowerCase() == value?.trim().toLowerCase(),
      orElse: () => VisitorStatus.registered,
    );
  }
}

class VisitorModel {
  final String id;
  final String name;
  final String mobile;
  final String? email;
  final String visitorType;
  final String project;
  final String purpose;
  final VisitorStatus status;
  final String createdAt;
  final String? checkInTime;
  final String? checkOutTime;

  const VisitorModel({
    this.id = '',
    required this.name,
    required this.mobile,
    this.email,
    required this.visitorType,
    required this.project,
    required this.purpose,
    this.status = VisitorStatus.registered,
    required this.createdAt,
    this.checkInTime,
    this.checkOutTime,
  });

  /// Check-in is only allowed from Registered.
  bool get canCheckIn => status == VisitorStatus.registered;

  /// Check-out is only allowed from Checked In.
  bool get canCheckOut => status == VisitorStatus.checkedIn;

  factory VisitorModel.fromJson(Map<String, dynamic> json) {
    return VisitorModel(
      id: json['id']?.toString() ?? '',
      name: _string(json['name']),
      mobile: _string(json['mobile']),
      email: _nullableString(json['email']),
      visitorType: _string(json['visitor_type']),
      project: _string(json['project']),
      purpose: _string(json['purpose']),
      status: VisitorStatus.fromLabel(json['status']?.toString()),
      createdAt: _string(json['created_at']),
      checkInTime: _nullableString(json['check_in_time']),
      checkOutTime: _nullableString(json['check_out_time']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'mobile': mobile,
      'email': email,
      'visitor_type': visitorType,
      'project': project,
      'purpose': purpose,
      'status': status.label,
      'created_at': createdAt,
      'check_in_time': checkInTime,
      'check_out_time': checkOutTime,
    };
  }

  VisitorModel copyWith({
    String? id,
    String? name,
    String? mobile,
    String? email,
    String? visitorType,
    String? project,
    String? purpose,
    VisitorStatus? status,
    String? createdAt,
    String? checkInTime,
    String? checkOutTime,
  }) {
    return VisitorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      visitorType: visitorType ?? this.visitorType,
      project: project ?? this.project,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
    );
  }

  static String _string(dynamic value) => value?.toString() ?? '';

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim();
    return (text == null || text.isEmpty || text == 'null') ? null : text;
  }
}
