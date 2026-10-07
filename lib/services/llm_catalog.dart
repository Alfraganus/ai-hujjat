enum LlmProvider {
  anthropic('anthropic'),
  openAi('openai'); // also used for OpenAI-compatible servers via a custom base URL

  const LlmProvider(this.id);
  final String id;

  static LlmProvider fromId(String? id) =>
      LlmProvider.values.firstWhere((p) => p.id == id, orElse: () => LlmProvider.anthropic);
}

/// A model offered in Settings. Prices are USD per 1M tokens.
class LlmModel {
  const LlmModel(this.id, this.inputPerM, this.outputPerM);
  final String id;
  final double inputPerM;
  final double outputPerM;

  double cost(int inputTokens, int outputTokens) =>
      inputTokens / 1e6 * inputPerM + outputTokens / 1e6 * outputPerM;

  /// e.g. "$0.10 / $0.50"
  String get priceLabel => '\$${_fmt(inputPerM)} / \$${_fmt(outputPerM)}';

  static String _fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}

// Both lists are ordered cheapest first.
// Anthropic prices: platform.claude.com pricing (2026-09).
// OpenAI prices: developers.openai.com/api/docs/pricing, standard tier (2026-10-07).
// Only models usable through /chat/completions are listed (no *-pro models).

const anthropicModels = <LlmModel>[
  LlmModel('claude-haiku-4-5', 1, 5),
  LlmModel('claude-sonnet-5-5', 2, 10),
  LlmModel('claude-opus-5-5', 4, 20),
];

const openAiModels = <LlmModel>[
  LlmModel('gpt-5-nano', 0.05, 0.40),
  LlmModel('gpt-6-luna', 0.10, 0.50),
  LlmModel('gpt-5.6-luna', 0.20, 1.20),
  LlmModel('gpt-5.4-nano', 0.20, 1.25),
  LlmModel('gpt-5-mini', 0.25, 2),
  LlmModel('gpt-5.4-mini', 0.75, 4.50),
  LlmModel('gpt-5', 1.25, 10),
  LlmModel('gpt-5.2', 1.75, 14),
  LlmModel('gpt-6.1-sol', 2, 10),
  LlmModel('gpt-5.6-terra', 2, 12),
  LlmModel('gpt-5.4', 2.50, 15),
  LlmModel('gpt-5.6-sol', 4, 20),
  LlmModel('gpt-5.5', 5, 30),
  LlmModel('gpt-6-astra', 10, 50),
];

const defaultOpenAiBaseUrl = 'https://api.openai.com/v1';

List<LlmModel> modelsFor(LlmProvider p) => switch (p) {
      LlmProvider.anthropic => anthropicModels,
      LlmProvider.openAi => openAiModels,
    };

/// The model used when the user has not chosen one: Haiku 4.5 / GPT-6 Luna
/// (the budget tiers meant for high-volume answers).
String defaultModelFor(LlmProvider p) => switch (p) {
      LlmProvider.anthropic => 'claude-haiku-4-5',
      LlmProvider.openAi => 'gpt-6-luna',
    };

LlmModel? findModel(LlmProvider p, String id) {
  for (final m in modelsFor(p)) {
    if (m.id == id) return m;
  }
  return null;
}
