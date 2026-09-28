# Sony Xperia XZ1 Compact (SO-02K) 向け AICP 15 デバイス設定

## 概要
NTTドコモ版 Sony Xperia XZ1 Compact（SO-02K）上で **AICP 15 (Android 15)** を動作させ、日本国内の VoLTE（ドコモ系・au系回線）を通話・通信ともに動作させるためのビルド・デバイス構成リポジトリです。

---

## 免責事項（Disclaimer / 注意事項）
* **完全自己責任**: 本リポジトリに記載されている手順・設定・パッチの利用によって生じたいかなる損害（端末の文鎮化、通信不能、データ消失、ハードウェア破損等）についても、作成者は一切の責任を負いません。
* **動作の保証外**: 記載内容はあくまで**作成者の個人環境（SO-02K 実機）において動作を確認した記録**です。当時の作業メモや検証結果に基づき整理していますが、記憶違いや見落とし、環境の違い等が含まれる可能性があります。作業を行う際は必ず事前に完全なバックアップ（TA、モデム領域等）を取得し、自身の判断で実施してください。

---

## 対象端末と動作前提条件

### 1. 対象ハードウェア
* **NTTドコモ SO-02K のみ** を対象としています。
* `/oem` パーティションは使用しません。Sony 公式の SODP OEM バイナリのフラッシュは不要です（必要なバイナリは全てベンダーツリーに含まれます）。

### 2. モデム・通信周りの前提（VoLTE 動作の必須要件）
* **ベースファームウェア**: `SO-02K_47.1.F.1.105_1311-8845_R14B`（初期 Oreo）
* **アンロック前の事前バックアップ（推奨）**:
  * 何かトラブルがあった際にいつでも後戻り（元の状態へ復旧）できるよう、ブートローダーアンロック（BLU）実施前に一時 root 等を用いて **TA（Trim Area）** やモデム関連領域（**`modemst1`, `modemst2`, `fsg`** 等）を含め、可能な限り全パーティションのバックアップを取得しておくことを強く推奨します。
* **モデム整合性の確保**:
  * グローバル版（G8441）ツリーのカスタム ROM やリカバリを導入すると、海外向けモデム構成が適用され国内 VoLTE が動作しなくなります。
  * これを防ぎ、国内 VoLTE を維持・動作させるためには、以下の全領域がドコモ純正状態として揃っている必要があります：
    1. **`modem` パーティション**: ドコモ純正 `47.1.F.1.105` の FTF に含まれる **`NON-HLOS.bin`（モデム本体）** が書き戻されていること。
    2. **`fsg`, `modemst1`, `modemst2` パーティション**: 海外ファームのフラッシュ等で破壊・上書きされておらずドコモ純正の初期状態が維持されているか、アンロック前に取得したバックアップから正しくリカバリされていること。
    3. **TA（Trim Area）**: アンロック前に取得したドコモ純正バックアップが正常にリストアされていること。
* **実機で確認されている正常値**:
  * ベースバンドバージョン: `8998-8998.gen.prodQ-00197-47`
    ```bash
    $ adb shell getprop gsm.version.baseband
    8998-8998.gen.prodQ-00197-47
    ```
* **動作確認済み SIM（実機検証実績）**:
  * **mineo（ドコモプラン / Dプラン）**: 通話（VoLTE）・データ通信の正常動作を確認
  * **IIJmio（タイプA / au回線）**: 通話（VoLTE）・データ通信の正常動作を確認
  * ※いずれも物理 SIM にて実機動作確認済み。

### 3. ブートローダーとアンロック状態
* **アンロック状態**:
  * ブートローダーアンロック（BLU）済みであること。
    ```bash
    $ fastboot getvar unlocked
    unlocked: yes
    ```
  * Android 起動時のプロパティ値:
    * `ro.boot.flash.locked`: `0`
    * `ro.boot.verifiedbootstate`: `orange`
* **プロダクト認識（自認）**:
  * 検証環境の実機では、`xperable` によるアンロック処理および共通ツリー環境の導入後、ブートローダーの自認が **`G8441`** を返す状態となっています。
    ```bash
    $ fastboot getvar product
    product: G8441
    ```
  * リカバリ（TWRP等）でROMのZIPを焼く際、端末側の機種判定が `G8441` や `lilac` として扱われるため、ROM側もこれらを対象とした機種チェック判定（assert / アサート）を通す形になっている必要があります（誤判定によるインストールエラー回避のため）。

---

## AICP 15 ビルド再現手順

### 1. ワークスペースの初期化
```bash
mkdir -p ~/aicp15
cd ~/aicp15
repo init -u [https://github.com/AICP/platform_manifest.git](https://github.com/AICP/platform_manifest.git) -b aicp-15 --git-lfs
```

### 2. ローカルマニフェストの配置
本リポジトリに含まれる再現用マニフェストを取得して配置します。
```bash
mkdir -p .repo/local_manifests
curl -sL [https://raw.githubusercontent.com/sasaki-takuro/android_device_sony_lilac/aicp-15-dcm/lilac_manifest.xml](https://raw.githubusercontent.com/sasaki-takuro/android_device_sony_lilac/aicp-15-dcm/lilac_manifest.xml) -o .repo/local_manifests/lilac.xml
```

### 3. ソースコードの同期
```bash
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
```

### 4. ビルドシステムおよびフレームワークへのパッチ適用
`device/sony/lilac/patches/` 配下に格納されている 5 つの必須パッチを適用します。
```bash
# build/make
git -C build/make am ${PWD}/device/sony/lilac/patches/build_make/*.patch

# build/soong
git -C build/soong am ${PWD}/device/sony/lilac/patches/build_soong/*.patch

# frameworks/base
git -C frameworks/base am ${PWD}/device/sony/lilac/patches/frameworks_base/*.patch

# frameworks/opt/telephony
git -C frameworks/opt/telephony am ${PWD}/device/sony/lilac/patches/frameworks_opt_telephony/*.patch
```

### 5. ビルド実行
```bash
source build/envsetup.sh
lunch aicp_lilac_dcm-bp1a-userdebug
mka bacon
```

---

## 適用パッチ一覧（概要）
* **`build_make`**: `avb_avb` が存在しない環境で `avbtool` へフォールバックさせる修正。
* **`build_soong`**: Soong 定義イメージを使用しない場合に `fsgen` の内部モジュール生成をスキップする修正。
* **`frameworks_base`**: `SQLiteTokenizer` における括弧チェックのサポートおよびビットマスク処理の修正。
* **`frameworks_opt_telephony`**:
  * シングル SIM 端末における不要な `setPreferredDataModem` 呼び出しをスキップ。
  * レガシー HAL との互換性維持のための `RadioState` マッピング修正。
