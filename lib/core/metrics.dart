class TokenMetrics {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  TokenMetrics({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  factory TokenMetrics.fromJson(Map<String, dynamic> json) => TokenMetrics(
    promptTokens: json['promptTokens'] ?? 0,
    completionTokens: json['completionTokens'] ?? 0,
    totalTokens: json['totalTokens'] ?? 0,
  );
}
