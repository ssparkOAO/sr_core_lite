# GitHub 管理日誌

本資料夾用來記錄 `sr_core` 專案如何用 Git / GitHub 做備份、復原與線上 HTML 文件管理。之後每次重要修改，可以在這裡補一筆紀錄，讓專案不是只有程式碼，也留下「什麼時候、為什麼改」的脈絡。

## 管理範圍

目前建議把 Git repository 放在：

```powershell
C:\M11413047\codex\final_proj\model_lite\sr_core
```

主要納入版本控制的內容：

- `RTL/`：核心 RTL、testbench、模擬結果摘要。
- `RTL_sys/`：系統層 RTL、wrapper、BRAM / ROM 相關設計與 Tcl。
- `tools/`：參數轉換、golden model、TFLite 解析工具。
- `generated/`、`generated_vivado_hex/`：小型 `.coe`、`.mem`、`.memh`、`.json` 參數與驗證輸出。
- `html/`：可透過 GitHub Pages 發布的專案文件。
- `handoff/`、`skill/`、`prompt/`、`pic/`、`使用說明.txt`：交接、學習與展示資料。

不建議納入版本控制的內容：

- Vivado 自動產生資料夾，例如 `.gen`、`.runs`、`.cache`、`.hw`。
- xsim 模擬工作目錄，例如 `xsim.dir`、`.wdb`、`.jou`、`.log`。
- Python cache，例如 `__pycache__`、`.pyc`。
- 本機手動備份資料夾 `backup/`。

## 第一次連到 GitHub

先在 GitHub 建立一個新的 repository，建議名稱：

```text
sr-core-lite
```

如果想讓 HTML 文件可以公開瀏覽，repository 可以設為 `Public`。如果 repository 是 `Private`，GitHub Free 通常不能直接用 private repo 發布 GitHub Pages。

建立好遠端 repository 後，在本機執行：

```powershell
cd C:\M11413047\codex\final_proj\model_lite\sr_core
git remote add origin https://github.com/<你的帳號>/sr-core-lite.git
git branch -M main
git push -u origin main
```

如果之後 GitHub 要求登入，依照 GitHub Desktop、瀏覽器登入，或 Personal Access Token 的提示完成即可。

## 平常使用方法

每次完成一個穩定進度後，建議照這個順序：

```powershell
cd C:\M11413047\codex\final_proj\model_lite\sr_core
git status
git add .
git commit -m "Describe current stable change"
git push
```

常用檢查指令：

```powershell
git status
git log --oneline --decorate -10
git diff
```

如果只想看某個檔案改了什麼：

```powershell
git diff -- RTL_sys/phase8_weight_memory/sr_core_top_mem_wrapper.v
```

## 什麼時候該 commit

建議 commit 的時機：

- 一個 RTL module 可以獨立模擬通過。
- testbench 或 golden data 更新完成。
- Vivado IP / BRAM / ROM 設定有明確變更。
- HTML 文件補完一個 phase 或新增重要說明。
- 交接文件 `handoff/HANDOFF.md` 更新到可讓別人接手。
- 開始大改之前，先 commit 目前可用版本。

不建議 commit 的時機：

- Vivado 正在產生中，資料夾還有大量臨時檔。
- 模擬尚未收斂，只是中間嘗試。
- 只是 `.log`、`.jou`、`.wdb` 這類執行紀錄改變。

## Commit 訊息格式

可以用簡短但有意義的句子：

```text
Add ROM preload wrapper verification
Update phase8 HTML handoff notes
Fix conv1 requantize scale handling
Record Vivado BRAM IP setup flow
```

如果是重要里程碑，可以加 tag：

```powershell
git tag phase8-rom-preload-ok
git push origin phase8-rom-preload-ok
```

## GitHub Pages 線上看 HTML

推上 GitHub 後，到 repository：

```text
Settings -> Pages
```

建議設定：

```text
Source: Deploy from a branch
Branch: main
Folder: / (root)
```

設定完成後，`html/index.html` 通常可以用下面網址開：

```text
https://<你的帳號>.github.io/sr-core-lite/html/
```

如果想讓首頁直接是 `https://<你的帳號>.github.io/sr-core-lite/`，可以之後再把 `html/index.html` 搬到 repository 根目錄，或建立一個根目錄 `index.html` 自動跳轉到 `html/`。

## 分支使用時機

平常穩定版本放 `main`。

如果要做較大的改動，例如 phase 9、新 wrapper、新 Vivado IP，可先開分支：

```powershell
git switch -c phase9-new-wrapper
```

完成並確認穩定後，再合回 main：

```powershell
git switch main
git merge phase9-new-wrapper
git push
```

## 復原方法

看最近版本：

```powershell
git log --oneline --decorate -10
```

只復原單一檔案到上一版：

```powershell
git restore path/to/file.v
```

如果要回到某個歷史版本，先建立分支比較安全：

```powershell
git switch -c recover-check <commit-id>
```

確認內容正確後，再決定是否合回 `main`。

## 日誌

### 2026-06-02

- 建立本資料夾作為 GitHub 管理與備份說明。
- 將 `sr_core` 規劃為獨立 Git repository。
- 新增 `.gitignore`，排除 Vivado / xsim 產生物與本機備份資料夾。
- 新增 `.nojekyll`，方便未來 GitHub Pages 直接發布靜態 HTML。
