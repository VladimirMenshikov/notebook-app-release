enum WishStatus { active, fulfilled, cancelled }

WishStatus wishStatusFromString(String? value) {
  switch (value) {
    case 'fulfilled':
      return WishStatus.fulfilled;
    case 'cancelled':
      return WishStatus.cancelled;
    default:
      return WishStatus.active;
  }
}

String wishStatusToString(WishStatus status) {
  switch (status) {
    case WishStatus.fulfilled:
      return 'fulfilled';
    case WishStatus.cancelled:
      return 'cancelled';
    case WishStatus.active:
      return 'active';
  }
}

extension WishStatusLabel on WishStatus {
  String get label {
    switch (this) {
      case WishStatus.active:
        return 'Активно';
      case WishStatus.fulfilled:
        return 'Исполнено';
      case WishStatus.cancelled:
        return 'Отменено';
    }
  }
}

enum WishFilter { all, fulfilled, active, cancelled }

extension WishFilterX on WishFilter {
  String get label {
    switch (this) {
      case WishFilter.all:
        return 'Все';
      case WishFilter.fulfilled:
        return 'Исполнены';
      case WishFilter.active:
        return 'Активны';
      case WishFilter.cancelled:
        return 'Отменены';
    }
  }

  /// Значение для query-параметра `status`; `null` — без фильтра.
  String? get statusParam {
    switch (this) {
      case WishFilter.all:
        return null;
      case WishFilter.fulfilled:
        return 'fulfilled';
      case WishFilter.active:
        return 'active';
      case WishFilter.cancelled:
        return 'cancelled';
    }
  }
}

class Wish {
  final String id;
  final String title;
  final String? description;
  final WishStatus status;
  final String? groupId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Wish({
    required this.id,
    required this.title,
    this.description,
    this.status = WishStatus.active,
    this.groupId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Wish.fromJson(Map<String, dynamic> json) {
    return Wish(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: wishStatusFromString(json['status'] as String?),
      groupId: json['groupId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Wish copyWith({
    String? title,
    String? description,
    WishStatus? status,
    DateTime? updatedAt,
  }) {
    return Wish(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      groupId: groupId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
