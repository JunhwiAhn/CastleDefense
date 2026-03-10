# CastleDefense チーム起動プロンプト

> このファイルの内容をリードセッションに貼り付けてチームを起動する。

---

以下のプロンプトをClaude Codeリードセッションにコピペしてください:

```
CastleDefenseの新ゲーム実装のためにAgent Teamを作成してください。

まず docs/新ゲーム仕様書.md と docs/タスク分担表.md を読んでプロジェクト全体を理解してください。

以下の3人のチームメイトをspawnしてください:

1. **Planner (기획자)** — agents/planner-prompt.md を読んでその内容をspawn promptとして使用
2. **Engineer (백엔드)** — agents/engineer-prompt.md を読んでその内容をspawn promptとして使用
3. **Designer (디자이너)** — agents/designer-prompt.md を読んでその内容をspawn promptとして使用

作業の進め方:
- まず Phase 1 のタスクから開始
- Engineer は B-1-1, B-1-2, B-1-3 を並行で着手（依存なし）
- Designer は D-4-1, D-4-2, D-1-3 を並行で着手（依存なし）
- Planner は P-1-1〜P-1-5 のベンチマーク調査を開始
- Phase 1 完了後に Phase 2 に進む
- タスク完了時は gh issue close #番号 を実行
- 同じファイルを複数メイトが同時編集しないよう調整してください
- Engineerにはplan approvalを要求してください（コア基盤変更のため）

Sonnetモデルを各チームメイトに使用してください。
```
