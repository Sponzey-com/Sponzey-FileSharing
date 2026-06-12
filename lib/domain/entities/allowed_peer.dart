class AllowedPeer {
  const AllowedPeer({
    required this.userId,
    required this.label,
    required this.verifierBase64,
    required this.createdAt,
    required this.updatedAt,
  });

  final String userId;
  final String label;
  final String verifierBase64;
  final DateTime createdAt;
  final DateTime updatedAt;

  AllowedPeer copyWith({
    String? userId,
    String? label,
    String? verifierBase64,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AllowedPeer(
      userId: userId ?? this.userId,
      label: label ?? this.label,
      verifierBase64: verifierBase64 ?? this.verifierBase64,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
