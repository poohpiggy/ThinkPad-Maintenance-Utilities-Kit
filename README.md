# ThinkPad Maintenance Utilities Kit

ThinkPad 换过主板，碰到机型名称、序列号或 UUID 缺失，可以从这里查。我们把 **ThinkPad Maintenance Utilities V1.11（x64）**、操作步骤和分析笔记放在一起，省得下次再到处翻帖子。

Community notes for restoring ThinkPad identifiers after a system board replacement. The kit brings together **ThinkPad Maintenance Utilities V1.11 (x64)**, a walkthrough, and notes on how the tool handles the data.

## 从这里开始 / Start here

### [使用教程 / User Guide](Guide.md)

从 Windows 制作维护 U 盘开始，说明怎么选菜单、怎么填 `C0` 整机记录和 `B0` 主板条码，以及怎么恢复机型名称、补齐 UUID 和读回核对。

Make a maintenance USB drive in Windows, enter the `C0` system record and `B0` board barcode, restore the product name and UUID, and read the values back.

### [EFI 分析笔记 / EFI Analysis](EFI-Analysis.md)

我们追了 `BootX64.efi` 里的几个关键分支。笔记里有两种界面的菜单编号、序列号长度检查，以及工具什么时候会生成新 UUID。

The notes cover menu numbering, serial-number length checks, and when `BootX64.efi` generates a new UUID.

## 配套文件 / Included files

| 文件 / File | 用途 / Purpose |
| --- | --- |
| `n1ctm07w.zip` | V1.11 x64 维护工具和 Windows 制盘程序。<br>V1.11 x64 maintenance utility and Windows USB formatter. |
| `Get-ThinkPadIdentity.ps1` | 在 Windows 只读查询整机和主板信息，方便维修后核对。<br>Read-only Windows check for system and board identifiers. |
