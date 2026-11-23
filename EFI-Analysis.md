# ThinkPad Maintenance Utilities V1.11 EFI 分析笔记 / EFI Analysis

[中文](#zh) · [English](#english)

<a name="zh"></a>

## 中文

我们看的是 `n1ctm07w.zip` 里的 `EFI/Boot/BootX64.efi`（**V1.11，X64**）。下面这些是从菜单和关键分支追出来的。UUID 的判断另外做了指令模拟。

| 项目 | 已确认的行为 |
| --- | --- |
| 主菜单 | 原包 `tpconfig.ini` 选择传统菜单，整机标识、UUID、配置更新分别是第 `1`、`2`、`3` 项。带 `Planar service` 的界面对应第 `2`、`3`、`4` 项。 |
| 整机记录 `C0` | `1S` + `Type` 码 + `SN` 码，含前缀共 **20 个字符**。换板向导也检查 `1S` 前缀。16 字符的校验属于设备类型 `20`。 |
| 主板条码 `B0` | `8S` + **21 个字符**，共 23 个字符。程序存储时去掉 `8S`，读取时补回。新增时会拒绝同类型记录，也会检查 `C0` 与 `20`、`B0` 与 `40` 的冲突。 |
| 机型名称 | `ThinkPad brand name` 和 `Special brand name` 写入同一字段。前者自动添加 `ThinkPad `，后者填写完整名称。写入后程序读回并比较配置块。 |
| 系统 UUID | 单独使用 `Assign UUID` 时，只有读到 16 字节全零才进入生成流程。全 `FF` 也会被当作已有值。换板向导最终确认后可以写入新 UUID。出现 `Written data is unmatch` 表示读回比较失败，程序仍可能继续显示结果。 |

这些流程通过 `LenovoEeprom` 固件接口读写设备记录。步骤见 [V1.11 使用教程](Guide.md#zh)。

外层 EFI 和 8 个内嵌模块的 [完整反汇编](analysis/)。

## English

We looked at `EFI/Boot/BootX64.efi` in `n1ctm07w.zip`, version **V1.11 (x64)**. These notes are based on disassembling the menu and validation paths. We also ran the UUID presence check in an isolated CPU emulator.

| Item | What V1.11 does |
| --- | --- |
| Main menu | The included `tpconfig.ini` selects the traditional menu. System identification, UUID, and configuration are items `1`, `2`, and `3`. With `Planar service` present they appear at `2`, `3`, and `4`. |
| System record `C0` | `1S` + `Type` + `SN`, **20 characters** including the prefix. `Planar service` also checks the `1S` prefix. The 16-character check applies to device type `20`. |
| Board barcode `B0` | `8S` + **21 characters**, 23 total. The utility strips `8S` when storing the value and restores it on display. Adding a record checks for duplicates and conflicts between `C0` and `20`, and between `B0` and `40`. |
| Product name | `ThinkPad brand name` and `Special brand name` write the same field. The first adds `ThinkPad `, and the second takes the full name. The utility reads back and compares the configuration block after writing. |
| System UUID | `Assign UUID` proceeds only after reading 16 zero bytes. An all-`FF` value is treated as an existing UUID. `Planar service` can write a new UUID at its final confirmation. `Written data is unmatch` means the readback comparison failed, even if the utility goes on to display a result. |

The utility reaches these records through the firmware's `LenovoEeprom` interface. These findings describe the application code in this package. For the steps, see the [V1.11 user guide](Guide.md#english).

The [full disassembly](analysis/) includes the outer EFI image and all eight embedded modules.
