# Benkei

Benkeiは、MacOSで薙刀式かな入力を行うためのソフトです。薙刀使いである弁慶から名前を採用しました。

#### 薙刀式とは

【薙刀式】v15（仮最終候補）: 大岡俊彦の作品置き場
http://oookaworks.seesaa.net/article/495043083.html

# 目標

 * 導入が簡単
 * 安定かつ高速に動作する
 * 設定変更やカスタマイズがGUIでできる

# 開発ロードマップ

 * Version alpha : 親指シフトLacailleをベースに、基本的なかな入力の実装
 * Version beta 1 : 編集モードの実装
 * Version beta 2 : かな定義の外部ファイル化、UIの実装
 * Version beta 3 : 固有名詞への対応
 * Version 1 : Lacailleベースの薙刀式対応 完成版。
 * Version 2 : Swift、SwiftUIで書き直してUIを刷新し、MacOSの進化へ対応できるようにする。

 # アイデア

 * 時間を考慮したスマートな同時押し/ロールオーバー判定する。
 * 重みづけした辞書を使って、同時押しなのか、ロールオーバーなのか判定を選択する。
