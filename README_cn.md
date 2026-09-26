# Nongki_OP8_OOS_build

为 **OnePlus 8 (instantnoodle, 4.19.157-perf+)** 的 **OxygenOS 13.1 (Android 13)** 内核提供自动化编译。
是 [NonGKI_Kernel_Build_OP8](https://github.com/Hotsteel2901/NonGKI_Kernel_Build_OP8) 的衍生版，把内核源从
LineageOS 23.2 (A16) 换成 **一加官方 OnePlus OSS 内核**。

## ⚠️ 与 LineageOS 版本的关键差异

一加 OSS 官方内核（`OnePlusOSS/android_kernel_oneplus_sm8250`，分支 `oneplus/sm8250_t_13.1_op8`，
`4.19.157`）是**更老的 4.19 结构**，且**内核里没有设备树**：

- `arch/arm64/boot/dts/vendor` 是指向 `../../../../../../vendor/qcom/proprietary/devicetree-4.19` 的 symlink
- 有 86+ 个 symlink 指向 `vendor/oplus/kernel/*`（充电、触控、oplus_performance、网络等）
- **这些需要从独立仓库获取：**
  `OnePlusOSS/android_kernel_modules_and_devicetree_oneplus_sm8250`（分支 `oneplus/sm8250_t_13.1_op8`）
- 工作流会 clone 该仓库并按官方布局放置，使 symlink 可解析

## 集成内容

本构建完全**极简（minimal）**——不含 root（KernelSU/ReSukiSU）、不含 SUSFS、不含 DroidSpaces、
不含 Baseband Guard。只是一加官方内核 + vendor/devicetree 源码，合并后直接编译。

## 使用方法

1. **Fork 本仓库** 到你的 GitHub 账号
2. **Settings → Actions → General → Workflow permissions** 选择 `Read and write permissions`
3. 进入 **Actions** 页, 选择 `Build Kernel` 工作流, 点 **Run workflow** (或直接 push 触发)
4. 构建完成后下载 zip, 用 AnyKernel3 方式刷入

## 补丁说明 (Patches/)

| 文件 | 内容 | 应用时机 |
|---|---|---|
| `Patch/defconfig_oos.patch` | 设备树 overlay 拼写错误修复 (`CONFIG_BUILD_ARM64_DT_OVERLAY`) | 工作流步骤 |

> 所有 OOS 补丁基于内核提交 `1d2678a3548f`（OOS13.1 最终版, 4.19.157-perf）生成。

## 关键配置项 (build-oneplus-8-los23-a16.yml)

- `KERNEL_SOURCE/Branch`: 一加 OSS 官方仓库, `oneplus/sm8250_t_13.1_op8`
- `VENDOR_SOURCE/Branch`: `android_kernel_modules_and_devicetree_oneplus_sm8250`, `oneplus/sm8250_t_13.1_op8`
- `MERGE_CONFIG_FILES`: 空 — OOS defconfig 已内嵌 `CONFIG_OPLUS_SM8250_CHARGER` 等
- `DEFCONFIG_NAME`: `vendor/kona-perf_defconfig`
- DTB: 非 overlay 构建生成 `kona-mtp.dtb`（设备树 19821），由此构建 dtb.img

## OOS vendor/devicetree 布局

一加官方构建把内核放在某层级使 `arch/arm64/boot/dts/../../../../../../vendor` 能解析。
本工作流 `device_kernel` 位于 `$GITHUB_WORKSPACE/device_kernel`，其 6 层上级是
`$GITHUB_WORKSPACE`，故 `vendor` 放在 `$GITHUB_WORKSPACE/vendor`。
`build-ready` clone modules_and_devicetree 仓库并把 `vendor/` 移到该处，然后校验关键 symlink。

## 鸣谢

[OnePlusOSS](https://github.com/OnePlusOSS) ·
[JackA1ltman/NonGKI_Kernel_Build_2nd](https://github.com/JackA1ltman/NonGKI_Kernel_Build_2nd)
