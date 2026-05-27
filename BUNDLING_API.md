# 同梱処理で使う NE API 一覧（ne_api gem）

ne_bundling（同梱処理アプリ）が利用する NE API と、その gem 呼び出し名の一覧。
v0.0.23 で「同梱系API」を追加した。呼び出しは `NeAPI::Master#<model>_<method>` 形式。

## v0.0.23 で追加した同梱系API

| gem 呼び出し | NE エンドポイント | 用途 | 主なパラメータ | 戻り値(get_key) |
| --- | --- | --- | --- | --- |
| `receiveorder_base_bundle` | `POST /api_v1_receiveorder_base/bundle` | 受注伝票の一括同梱（NE標準同梱処理を実行） | `params: { data: <JSON文字列>, receive_order_recalculate_flag: "1"/"0" }` | `results`（ジョブ毎の同梱結果配列） |
| `receiveorder_base_bundle_candidate_groups` | `POST /api_v1_receiveorder_base/bundle_candidate_groups` | 同梱候補グループ取得（同梱可能な受注をグループ化） | `params: { target_receive_order_ids: "1,2,3" }`（省略時は全受注対象） | `groups`（受注番号配列の配列） |
| `receiveorder_groupingtag_search` | `POST /api_v1_receiveorder_groupingtag/search` | 受注分類タグ検索 | `fields:`, `query:`（`grouping_tag_*`） | `data` |

### `receiveorder_base_bundle` の `data` 構造

```json
[
  {
    "receive_order_id": "同梱先(親)の受注伝票番号",
    "receive_order_last_modified_date": "YYYY-MM-DD HH:MM:SS",  // 楽観ロック用
    "bundles": [
      { "receive_order_id": "同梱元(子)の受注伝票番号",
        "receive_order_last_modified_date": "YYYY-MM-DD HH:MM:SS" }
    ]
  }
]
```

- `data` 配列は 1〜100 ジョブ。`receive_order_last_modified_date` が DB の最終更新日と不一致の伝票はスキップされる。
- `results[].bundled_receive_order_ids` に成功した子注文、`skipped_receive_order_ids` / `skipped_receive_order_reasons` にスキップ分が返る。
- 同梱元が全件スキップになるとエラー（コード `028013`）。固有エラーは `028001`〜`028021`。

### `bundle_candidate_groups` のグループ判定条件

同一グループは次を全て満たす受注: ①同じ店舗 ②有効な伝票（未キャンセル）③受注状態が起票済/納品書印刷待ち/納品書印刷済 ④送り先名一致 ⑤送り先住所一致 ⑥送り先電話番号一致 ⑦送り先未マスク。
固有エラー: `029001`(1万件超) / `029002`(非数値) / `029003`。

## 同梱フローで使う既存API（v0.0.22 時点で定義済み）

| gem 呼び出し | NE エンドポイント | 用途 |
| --- | --- | --- |
| `receiveorder_row_search` / `_count` | `/api_v1_receiveorder_row/{search,count}` | 受注明細の検索・件数（同梱対象の絞り込み） |
| `receiveorder_base_search` / `_count` | `/api_v1_receiveorder_base/{search,count}` | 受注伝票の検索・件数（配送先・状態の取得） |
| `receiveorder_base_update` | `/api_v1_receiveorder_base/update` | 受注更新（商品追加・確認・タグ付与: XML） |
| `receiveorder_base_bulkupdate` | `/api_v1_receiveorder_base/bulkupdate` | 子注文の一括更新（キャンセル等: XML） |
| `master_goods_search` / `_count` | `/api_v1_master_goods/{search,count}` | 商品マスタ取得（商品名等の付与） |
| `master_shop_search` | `/api_v1_master_shop/search` | 店舗一覧取得（shop_id 絞り込み用） |
| `notice_execution_add` | `/api_v1_notice_execution/add` | 実行結果お知らせ登録 |
| `login_company_info` / `login_user_info` | `/api_v1_login_{company,user}/info` | 認証・企業/ユーザー情報 |

## 補足

- 現行の同梱アプリ（`ne_bundling`）は `receiveorder_base_update` + `bulkupdate` を XML で組み立ててクライアント側で同梱を実装している。NE標準の `receiveorder_base_bundle` / `bundle_candidate_groups` を使うと、グループ判定〜同梱実行を NE 側に委譲でき、ロジックを大幅に簡素化できる（改修方針の選択肢）。
- 全エンドポイントの詳細仕様は ne_bundling 側 `doc/ne_api_reference.txt`（出典 https://developer.next-engine.com/llms-full.txt ）を参照。
