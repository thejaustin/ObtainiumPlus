# Project Context & Agent Guidelines

## 🤖 Automated Tool Usage
You have access to specialized MCP servers. **You MUST use them proactively** without waiting for the user to invoke a specific command.

### 1. Google Developer Knowledge (Android/Firebase/Cloud)
**Trigger:** Whenever the user asks about:
- Android APIs, Lifecycle, or Best Practices
- Firebase implementation
- Google Cloud services

**Action:**
- IMMEDIATELY use the `google-developer-knowledge` tool to search for the official documentation.
- Base your answers on the *retrieved documentation* to ensure accuracy.
- Do not rely solely on your training data for API specifics as they may be outdated.

### 2. Dart & Flutter Analysis
**Trigger:** Whenever the user:
- Asks for code analysis or debugging
- Shares a Dart/Flutter file
- Asks about Dart language features

**Action:**
- Use the `dart-mcp` toolset (e.g., `analyze_context`, `get_diagnostics`) to get real-time compiler feedback.
- Prioritize these tools over generic text-based analysis.

## ⚡ Slash Commands (Optional Override)
While you should use tools automatically, these commands are available for the user to force a specific action:
- `/project:docs` - Force a docs search.
- `/project:analyze` - Force a code analysis.
- `/project:ask` - Force a docs-first query.
