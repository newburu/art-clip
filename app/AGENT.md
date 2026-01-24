# 対応
* 日本語で対応すること

## 技術スタック
* **Ruby:** 最新の安定版
* **Framework:** Ruby on Rails 最新の安定版
* **CSS:** Tailwind CSS（モダンで見やすいデザインにするため）
* **Database:** MySQL 最新の安定版
* **i18n:** 日本語対応

## Rails Gem
* **dotenv-rails** 環境変数を利用

## 実装ステップ
以下の手順で進めたいので、ステップごとにコードと実行コマンドを教えてください。
* Railsプロジェクトの作成とTailwind CSSのセットアップ
* モデルとコントローラーの作成（Game状態の保存など）
* ビューの作成（見た目の実装）
* ルーティングの設定

## 補足事項
* プロジェクトディレクトリは今のディレクトリをそのまま利用する

## データベース
* mariaDBを使用する
* 接続ホストは、.envのDB_HOST
* ユーザー名は、.envのDB_USERNAME
* パスワードは、.envのDB_PASSWORD

## ログイン機能(SSO)
* Deviceを利用する
* メールアドレスでのログインは禁止とする
* GoogleとXのログイン機能(SSO)とする
* GoogleのクライアントIDとシークレットは、.envのGOOGLE_CLIENT_IDとGOOGLE_CLIENT_SECRET
* XのクライアントIDとシークレットは、.envのTWITTER_CLIENT_IDとTWITTER_CLIENT_SECRET

## トラッキング
* Google Analyticsを利用する
* Google AnalyticsのトラッキングIDは、.envのGOOGLE_ANALYTICS_ID

## Google AdSense
* Google AdSenseを利用する
* Google AdSenseのトラッキングIDは、.envのGOOGLE_ADSENSE_ID

## デプロイ関係
* Capistranoを利用する
* デプロイホストは、.envのDEPLOY_HOST
* デプロイパスは、.envのDEPLOY_PATH
* デプロイユーザーは、.envのDEPLOY_USER
* Secret Key Baseは、.envのSECRET_KEY_BASE
