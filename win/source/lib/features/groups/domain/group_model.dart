enum GroupRole { admin, member }

GroupRole groupRoleFromString(String? value) =>
    value == 'admin' ? GroupRole.admin : GroupRole.member;

/// Контекст, в котором работают разделы (Задачи/Вопросы/Заметки/Желания).
/// `null` в качестве текущего контекста означает «Личное».
class Group {
  final String id;
  final String name;
  final GroupRole role;
  final int membersCount;
  final String createdById;
  final bool isOwner;
  final bool isBanned;
  final DateTime? bannedUntil;

  Group({
    required this.id,
    required this.name,
    this.role = GroupRole.member,
    this.membersCount = 1,
    this.createdById = '',
    this.isOwner = false,
    this.isBanned = false,
    this.bannedUntil,
  });

  bool get isAdmin => role == GroupRole.admin;

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      role: groupRoleFromString(json['role'] as String? ?? json['myRole'] as String?),
      membersCount: json['membersCount'] as int? ??
          (json['members'] is List ? (json['members'] as List).length : 1),
      createdById: json['createdById'] as String? ?? '',
      isOwner: json['isOwner'] as bool? ?? false,
      isBanned: json['isBanned'] as bool? ?? false,
      bannedUntil: json['bannedUntil'] != null
          ? DateTime.tryParse(json['bannedUntil'] as String)
          : null,
    );
  }
}

class GroupMember {
  final String userId;
  final String? name;
  final String email;
  final String? avatarName;
  final GroupRole role;
  final bool isOwner;
  final bool isBanned;
  final DateTime? bannedUntil;
  final bool bannedForever;
  final String? bannedByName;

  GroupMember({
    required this.userId,
    this.name,
    required this.email,
    this.avatarName,
    this.role = GroupRole.member,
    this.isOwner = false,
    this.isBanned = false,
    this.bannedUntil,
    this.bannedForever = false,
    this.bannedByName,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['userId'] as String,
      name: json['name'] as String?,
      email: json['email'] as String? ?? '',
      avatarName: json['avatarName'] as String?,
      role: groupRoleFromString(json['role'] as String?),
      isOwner: json['isOwner'] as bool? ?? false,
      isBanned: json['isBanned'] as bool? ?? false,
      bannedUntil: json['bannedUntil'] != null
          ? DateTime.tryParse(json['bannedUntil'] as String)
          : null,
      bannedForever: json['bannedForever'] as bool? ?? false,
      bannedByName: json['bannedByName'] as String?,
    );
  }
}

class GroupInvitationInfo {
  final String id;
  final String email;
  final String? invitedByName;
  final DateTime? createdAt;

  GroupInvitationInfo({
    required this.id,
    required this.email,
    this.invitedByName,
    this.createdAt,
  });

  factory GroupInvitationInfo.fromJson(Map<String, dynamic> json) {
    return GroupInvitationInfo(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      invitedByName: json['invitedByName'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}

/// Детали группы: участники + приглашения (последние — только для админа).
class GroupDetail {
  final String id;
  final String name;
  final String createdById;
  final GroupRole myRole;
  final bool isOwner;
  final List<GroupMember> members;
  final List<GroupInvitationInfo> invitations;

  GroupDetail({
    required this.id,
    required this.name,
    required this.createdById,
    required this.myRole,
    required this.isOwner,
    required this.members,
    required this.invitations,
  });

  bool get isAdmin => myRole == GroupRole.admin;

  factory GroupDetail.fromJson(Map<String, dynamic> json) {
    return GroupDetail(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      createdById: json['createdById'] as String? ?? '',
      myRole: groupRoleFromString(json['myRole'] as String?),
      isOwner: json['isOwner'] as bool? ?? false,
      members: (json['members'] as List? ?? [])
          .map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
          .toList(),
      invitations: (json['invitations'] as List? ?? [])
          .map((i) => GroupInvitationInfo.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }

  Group toGroup() => Group(
        id: id,
        name: name,
        role: myRole,
        membersCount: members.length,
        createdById: createdById,
        isOwner: isOwner,
      );
}

/// Приглашение, адресованное текущему пользователю.
class MyInvitation {
  final String token;
  final String groupId;
  final String groupName;
  final String? invitedByName;
  final DateTime? createdAt;

  MyInvitation({
    required this.token,
    required this.groupId,
    required this.groupName,
    this.invitedByName,
    this.createdAt,
  });

  factory MyInvitation.fromJson(Map<String, dynamic> json) {
    return MyInvitation(
      token: json['token'] as String,
      groupId: json['groupId'] as String? ?? '',
      groupName: json['groupName'] as String? ?? '',
      invitedByName: json['invitedByName'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}

/// Признак видимости записи внутри группы.
enum ItemVisibility { personal, shared }

ItemVisibility visibilityFromString(String? value) =>
    value == 'shared' ? ItemVisibility.shared : ItemVisibility.personal;

String visibilityToString(ItemVisibility v) =>
    v == ItemVisibility.shared ? 'shared' : 'personal';
