# TBox

## TODO

### MUST

- [x] アルバムの編集
  - アルバムの削除
  - アルバム名の編集
- [x] クリップの詳細情報を表示できる
  - [x] クリップにひもづくタグをみれる
  - [x] クリップにひもづくURLをみれる
  - [x] 詳細情報から検索できる
- [x] タグ
  - [x] タグを付与できる
  - [x] 複数のタグを一度に付与できる
  - [x] タグ一覧画面
  - [x] タグを削除できる
  - [x] タグをタップしてタグにひもづくClip一覧画面に飛べる
- [x] Localize
  - [x] Error handling
    - [x] StorageErrorをdisplayableにする
- [x] Preview画面と情報画面を遷移しやすくする
  - [x] Dismissal interactive transition
- [x] Hiddenアイテムの実装
  - [x] 設定画面から表示のOn/Offができる
  - [x] Hiddenアイテムでフィルタできる
- [x] 検索結果/アルバムに対する全て選択の実装
  - [x] NavigationItem Presenter
- [x] 各種画面からタグ追加できる
  - [x] ClipInformation
  - [x] SearchResult
  - [x] Album
- [x] Previewから各種編集操作が行える
- [x] 画像をDBではなくファイルシステム上に保存する
- [ ] クリップからタグを削除できる
- [ ] クリップにタグを追加するとき、追加ずみのタグの表示をかえる
- [ ] 画像をエクスポートできる
- [ ] iCloudバックアップできる

### Bug

- [ ] たまにPreviewからListViewへ戻るのに失敗する

### Refactor

- [ ] Presenter Protocol を切って input を明示する
- [ ] Model更新時に、Modelの更新をPresenterに伝える機構の実装

### Optional

- UI
  - [ ] ToolBar を TabBar の上に表示する
  - [ ] 画像のソート
  - [ ] 画像の一覧を小さめにする
- [ ] タグ編集をやりやすくする
  - [ ] 先にタグを選んでから対象を選択する
- [ ] Infoからタグ追加ができる
- [ ] Share時にタグやアルバムを選択できる
- [ ] 各種画面でソートできる
  - [ ] 追加の新しい順
  - [ ] 追加の古い順
  - [ ] 更新の新しい順
  - [ ] 更新の古い順
- [ ] 検索
  - [ ] アルバムを検索できる
  - [ ] タグを検索できる
