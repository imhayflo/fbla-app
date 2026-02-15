class FblaSection {
  final String id;
  final String name;
  final String stateCode;
  final int order;

  const FblaSection({
    required this.id,
    required this.name,
    required this.stateCode,
    this.order = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FblaSection && id == other.id && name == other.name;

  @override
  int get hashCode => Object.hash(id, name);
}
