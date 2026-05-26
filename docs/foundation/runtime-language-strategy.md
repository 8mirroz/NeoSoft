# Runtime Language Strategy (Godot Match-3)

## Baseline Choice

- **MVP gameplay core:** GDScript.
- **Reason:** current target includes Web export in MVP scope, while C#/.NET path in Godot 4 has export limitations for Web.

## C# Track (Optional)

- C# can be used for Android/iOS-focused future builds if/when Web is dropped from release scope.
- Any C# adoption must pass a platform-gate review first (build stability, team tooling, CI support).

## Practical Rule

- Keep core logic API engine/language-neutral (`BoardModel`, `MatchSystem`, `SheddingSystem`, `GenerationSystem` contracts).
- If a future C# migration is needed, reimplement behind the same contract and preserve event semantics.

