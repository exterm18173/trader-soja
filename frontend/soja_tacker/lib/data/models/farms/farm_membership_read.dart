// lib/data/models/farms/farm_membership_read.dart
import 'farm_read.dart';

class FarmMembershipRead {
  final int membershipId;
  final FarmRead farm;
  final String role;
  final bool ativo;

  const FarmMembershipRead({
    required this.membershipId,
    required this.farm,
    required this.role,
    required this.ativo,
  });

  factory FarmMembershipRead.fromJson(Map<String, dynamic> json) {
    return FarmMembershipRead(
      membershipId: (json['membership_id'] as num).toInt(),
      farm: FarmRead.fromJson(json['farm'] as Map<String, dynamic>),
      role: (json['role'] ?? '').toString(),
      ativo: (json['ativo'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'membership_id': membershipId,
        'farm': farm.toJson(),
        'role': role,
        'ativo': ativo,
      };
}
