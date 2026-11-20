# [Unofficial] Sony Xperia XZ1 Compact (SO-02K) を Android 16 化するビルド設定・手順書（Project Sakura 16.3 ベース / 国内VoLTE対応）

## これは何？
NTTドコモ版 Xperia XZ1 Compact (SO-02K) に **Android 16 (Project Sakura 16.3 / 非公式・Unofficial)** を導入し、日本国内の **VoLTE 通話やデータ通信を正常に利用可能とするための非公式デバイスツリー・ビルド手順書** です。

- **対象端末**: Xperia XZ1 Compact（NTTドコモ SO-02K）
- **ベースOS**: Project Sakura 16.3（Android 16）
- **主な特徴**: ドコモ回線・au回線での国内 VoLTE 通話およびデータ通信の動作を維持、SO-02K 固有プロパティ群（`ro.semc.*` 等）の完全復元、SELinux Enforcing 完全対応

---

## 免責事項（Disclaimer / 注意事項）
- **完全自己責任**: 本リポジトリに記載されている手順・設定・パッチの利用によって生じたいかなる損害（端末の文鎮化、通信不能、データ消失、ハードウェア破損等）についても、作成者は一切の責任を負いません。
- **動作の保証外**: 記載内容はあくまで**作成者の個人環境（SO-02K 実機）において動作を確認した記録**です。当時の作業メモや検証結果に基づき整理していますが、記憶違いや見落とし、環境の違い等が含まれる可能性があります。作業を行う際は必ず事前に完全なバックアップ（TA、モデム領域等）を取得し、自身の判断で実施してください。

---

## 対象端末と動作前提条件

### 1. 対象ハードウェア
- **NTTドコモ SO-02K のみ** を対象としています。
- `/oem` パーティションは使用しません。Sony 公式の SODP OEM バイナリのフラッシュは不要です（必要なバイナリは全てベンダーツリーに含まれます）。

### 2. モデム・通信周りの検証メモと動作確認条件
- **ベースファームウェア**: `SO-02K_47.1.F.1.105_1311-8845_R14B`（初期 Oreo）
- **アンロック前の事前バックアップ（強く推奨）**:
  - 何かトラブルがあった際にいつでも元の状態へ復旧できるよう、ブートローダーアンロック（BLU）実施前に一時 root 等を用いて **TA（Trim Area）** やモデム関連領域（**`modemst1`, `modemst2`, `fsg`** 等）を含め、全パーティションのバックアップを取得しておくことを強く推奨します。
- **モデムイメージと MBN に関する調査結果**:
  - グローバル版（G8441）ツリーではキャリアごとの MBN ファイル（`amss_fsg_...`）が用意されていますが、SO-02K の純正モデムイメージ（`modem.img` / `NON-HLOS.bin`）および FTF 内部を走査・確認した限りでは、日本キャリア向けの独立した MBN ファイルは存在しませんでした。
  - そのため、キャリブレーション値や通信パラメータはパーティション側に直接保持されていると考えられます。
- **実機で動作確認が取れている環境・条件**:
  - 設定の不整合を避けるため、作成者の実機検証ではモデムおよび調整領域をドコモ純正状態のまま維持（またはアンロック前バックアップから復元）した環境でテストを実施しています。
    1. **`modem` パーティション**: ドコモ純正 `47.1.F.1.105` の **`NON-HLOS.bin`** を維持。
    2. **`fsg`, `modemst1`, `modemst2` パーティション**: ドコモ純正の初期調整状態を維持（または事前バックアップから復元）。
    3. **TA（Trim Area）**: アンロック前に取得したドコモ純正 TA バックアップを正しくリストア。
  - ※海外ファームの上書きやパーティション破損時の挙動、他キャリアでの網羅的な動作については未検証です。
- **実機で確認されている正常値**:
  - ベースバンドバージョン: `8998-8998.gen.prodQ-00197-47` (`adb shell getprop gsm.version.baseband`)
- **動作確認済み SIM（実機検証実績）**:
  - **mineo（ドコモプラン / Dプラン）**: 物理 SIM にて通話（VoLTE）・データ通信の正常動作を確認
  - **IIJmio（タイプA / au回線）**: 物理 SIM にて通話（VoLTE）・データ通信の正常動作を確認
- **追記（Pie下層での動作）**:
  - ドコモ純正 Pie（`47.2.B.5.38` / ベースバンド `8998-8998.gen.prodQ-00278-47`）の下層ファームウェア環境でも、ROM側の修正なしに同様に動作（LTE通信・VoLTE通話・Wi-Fi・BT・Camera・NFC）することを確認済み。

### 3. ブートローダーとアンロック状態
- **アンロック状態**:
  - ブートローダーアンロック（BLU）済みであること（`fastboot getvar unlocked` の出力が `unlocked: yes`）。
- Android 起動時のプロパティ値:
  - `ro.boot.flash.locked`: `0`
  - `ro.boot.verifiedbootstate`: `orange`
- **プロダクト判定とアサート正規化**:
  - グローバル共通ツリーに引きずられた `G8441` の誤認を排除するため、`TARGET_BOOTLOADER_BOARD_NAME := lilac` に正規化し、インストールアサート対象を `SO-02K`, `lilac`, `lilac_dcm` に統一しています。
- **起動時警告画面の描画乱れ対策（xfl 書き戻し）**:
  - アンロック作業時に流し込んだ改変イメージ（`xfl-o77.mbn` 等）をそのまま残していると、起動時のアンロック警告（鍵アイコン）の表示が化けて乱れます。アンロック完了後はバックアップしておいた元の純正 `xfl` を書き戻す必要があります。

---

## 主な改修・適用内容

1. **ドコモ（SO-02K）固有プロパティの分離と適用**:
  - グローバル用プロパティ（`system.prop`）を汚さず、ドコモ専用定義として `system_dcm.prop` を分離。
  - `ro.semc.version.*`、`ro.semc.product.*`、`ro.somc.*` などの実機パラメータを正確に投入。また、Kernel 4.4 互換プロパティ（`ro.bpf.kver_override`, `ro.incremental.enable`）を `system` 側へ正規配置。
2. **SELinux Enforcing 完全対応（yoshino-common / lilac 側）**:
  - `vendor_init.te`、`hal_camera_somc.te`、`lilac_enforcing.te` 等を整備し、Enforcing 運用に必要な権限を付与。
  - `AT_SECURE` 環境下で `LD_PRELOAD` / `LD_LIBRARY_PATH` が無効化されてもカメラ HAL および `cacaoserver` が正常動作するよう、プロプライエタリ ELF バイナリ群へ `RUNPATH=/vendor/lib/cama15` および `NEEDED`（`libsensorfix.so` / `libsonypiecompat.so`）を `patchelf` で埋め込み。
3. **初期ブート時の ADB 無効化**:
  - `yoshino-common` の `system.prop` におけるデフォルトブート時 ADB 有効化プロパティ（`persist.service.adb.enable=1` 等）をコメントアウトし、開発者向けオプションから明示的に有効化するまで ADB が立ち上がらない構成に変更。
4. **アサートおよびターゲット名正規化**:
  - 機種判定から `G8441` を排除し、`SO-02K` 向けターゲットとして統一。
5. **モデム書き換え機能・サービスのオミット**:
  - 不意のベースバンド書き換えや競合を防ぐため、`sony-modem-switcher` サービスの自動起動停止および `OpenCustomizationSelector`（モデム切り替え機能）をオミット・無効化。
6. **KernelSU（KernelSU Next）のデフォルト非搭載**:
  - ビルド時に `WITH_KSU=true` を明示しない限りカーネル組み込みを行わない構成とし、標準リリースではオミット（標準のクリーンなカーネル状態を維持）。
7. **Project Sakura 16.3 向け UI・構成調整**:
  - Project Sakura 16.3 向けにブラーおよび顔認証（Face Unlock）設定を無効化。

---

## Project Sakura 16.3 ビルド再現手順

### 1. ワークスペースの初期化
    mkdir -p ~/sakura16
    cd ~/sakura16
    repo init -u https://github.com/ProjectSakura/android.git -b 16.3 --git-lfs

### 2. ローカルマニフェストの配置
本リポジトリに含まれる再現用マニフェストを取得して配置します。
    mkdir -p .repo/local_manifests
    curl -sL https://raw.githubusercontent.com/sasaki-takuro/android_device_sony_lilac/sakura-16.3-dcm/lilac_manifest.xml -o .repo/local_manifests/lilac.xml

### 3. ソースコードの同期
    repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags

### 4. ビルドシステムおよびフレームワークへのパッチ適用
`device/sony/lilac/patches/` 配下に格納されている全 19 個のパッチを適用します。
    # bootable/recovery
    git -C bootable/recovery am ${PWD}/device/sony/lilac/patches/bootable_recovery/*.patch

    # build/make
    git -C build/make am ${PWD}/device/sony/lilac/patches/build_make/*.patch

    # build/soong
    git -C build/soong am ${PWD}/device/sony/lilac/patches/build_soong/*.patch

    # frameworks/base
    git -C frameworks/base am ${PWD}/device/sony/lilac/patches/frameworks_base/*.patch

    # frameworks/opt/telephony
    git -C frameworks/opt/telephony am ${PWD}/device/sony/lilac/patches/frameworks_opt_telephony/*.patch

    # hardware/qcom-caf/msm8998/media
    git -C hardware/qcom-caf/msm8998/media am ${PWD}/device/sony/lilac/patches/hardware_qcom-caf_msm8998_media/*.patch

    # packages/modules/CellBroadcastService
    git -C packages/modules/CellBroadcastService am ${PWD}/device/sony/lilac/patches/packages_modules_CellBroadcastService/*.patch

    # packages/modules/Connectivity
    git -C packages/modules/Connectivity am ${PWD}/device/sony/lilac/patches/packages_modules_Connectivity/*.patch

    # packages/modules/Wifi
    git -C packages/modules/Wifi am ${PWD}/device/sony/lilac/patches/packages_modules_Wifi/*.patch

    # prebuilts/build-tools (Arch Linux 等でホストの date / tar を使用する場合)
    git -C prebuilts/build-tools am ${PWD}/device/sony/lilac/patches/prebuilts_build-tools/*.patch

    # vendor/lineage
    git -C vendor/lineage am ${PWD}/device/sony/lilac/patches/vendor_lineage/*.patch

### 5. ビルド実行
    source build/envsetup.sh
    lunch lineage_lilac_dcm-bp4a-userdebug
    m bacon

---

## 適用パッチ一覧（概要）
- **`bootable_recovery`**: リカバリ画面上のビルドバージョン表示で Sakura バージョンプロパティへフォールバックする修正。
- **`build_make`**:
  - `avb_avbtool` が存在しない環境で `avbtool` へフォールバックさせる修正。
  - `releasetools` における `ZipFile` の `partition_map` 参照およびシンボリックリンク OTA チェックの修正。
- **`build_soong`**:
  - Soong 定義イメージを使用しない場合に `fsgen` の内部モジュール生成をスキップする修正。
  - `userdebug` バリアントで `Debuggable` フラグを適切に反映する修正。
- **`frameworks_base`**:
  - 新規ストレージ利用不可時に proto フラグストレージへフォールバックする `AconfigFlags` 修正。
  - `debug.hwui.wait_for_gpu_completion` プロパティの読み込みをサポート（描画完了同期待ちによる競合回避）。
  - ウィンドウ、トランジション、および Animator アニメーションスケールの初期値を 0 倍（無効化）に設定。
  - SystemUI における音量ダイアログ（ボリュームオーバーレイ）のセンタリング表示対応。
- **`frameworks_opt_telephony`**:
  - シングル SIM 端末における不要な `setPreferredDataModem` 呼び出しをスキップ。
  - レガシー HAL（HAL 1.0 / 1.4+）との互換性維持のための `RadioState` マッピング修正。
- **`hardware_qcom-caf_msm8998_media`**:
  - `yoshino-common` の `qcom-caf` 名前空間をインポートする `soong_namespace` 定義を追加。
- **`packages_modules_CellBroadcastService`**:
  - CBR 互換性のための 26Q1 UX/Map メトリクス定数を追加。
- **`packages_modules_Connectivity`**:
  - レガシー Linux 4.4 カーネル向けに BPF の 4.14+ バージョンチェックをバイパス。
  - `dump()` 内の `sLocalNetAccessMap` に対する null チェックを修正。
  - レガシー環境で存在しない `local_net` BPF マップを安全にスキップする修正。
- **`packages_modules_Wifi`**:
  - レガシー Wi-Fi チップセット非対応による `getCachedScanData` の `ERROR_NOT_SUPPORTED` ログ出力を抑止。
- **`prebuilts_build-tools`**:
  - 新しい Linux ディストリビューション（Arch Linux 等）環境でホスト側の `date` / `tar` を使用するため prebuilt シンボリックリンクを削除。
- **`vendor_lineage`**:
  - `userdebug` ビルドでのデバッグ有効化および `adb_root` 許可設定を維持する修正。

---

## クレジット・謝辞 (Credits & Acknowledgments)

本環境およびビルド設定は、オープンソース開発者およびコミュニティの多大な成果に基づいています。素晴らしいベースを維持・公開してくださっている皆様に深く敬意と感謝を表します。

Special thanks to all the upstream developers and communities whose dedicated work made this project possible:

- **[Project Sakura](https://github.com/ProjectSakura)**
  - Project Sakura 16.3 ROM ベースシステムおよびカスタマイズ基盤の提供 / Providing the Project Sakura 16.3 ROM base and customization framework
- **[LineageOS Project](https://github.com/LineageOS)**
  - Android オープンソースカスタムROMの強固な基盤システムの提供 / Providing the solid foundation of the open-source Android platform
- **[LineageOS-UL](https://github.com/LineageOS-UL)**
  - レガシーデバイス向け LineageOS ツリーおよび互換基盤の維持 / Maintaining LineageOS trees and compatibility layers for legacy devices
- **[sunplex07](https://github.com/sunplex07) 氏**
  - Sony Yoshino プラットフォーム（msm8998 / Lilac）向け LineageOS 23.2（Android 16）カーネル・デバイス・ベンダーツリーの移植およびメンテナンス / Porting and maintaining LineageOS 23.2 (Android 16) kernel, device, and vendor trees for Sony Yoshino (msm8998 / Lilac)
- **[derfelot](https://github.com/derfelot) 氏**
  - Sony Yoshino プラットフォーム向けベンダーブロブおよびプロプライエタリ構成のメンテナンス / Maintaining vendor blobs and proprietary configurations for the Sony Yoshino platform
- **[justinlin099 (Justin Lin)](https://github.com/justinlin099) 氏**
  - Xperia XZ1 Compact (Lilac / SO-02K) 向けデバイスツリー・ベンダーブロブの構築および成果の公開 / Maintaining and sharing device trees and vendor blobs for Xperia XZ1 Compact (Lilac / SO-02K)
- **Sony Open Devices プロジェクトおよび Xperia 開発コミュニティの皆様**
  - Sony Open Devices Project and the Xperia development community
