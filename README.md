# ThinkPad Maintenance Utilities Kit

本来只是想把 ThinkPad 换板后那几个号怎么填写清楚。后来拆开 `BootX64.efi` 看了下，发现菜单编号会变，`C0`、`B0` 和 UUID 也各有自己的判断，就一起记下来了。

- [使用教程 / User Guide](Guide.md) — 做启动盘、补回机器信息、写完读回核对。
- [EFI 分析笔记 / EFI Analysis](EFI-Analysis.md) — 菜单、输入校验和 UUID 的判断，附完整反汇编。

`n1ctm07w.zip` 是 V1.11 x64 工具包。进 Windows 后，可以用 `Get-ThinkPadIdentity.ps1` 看整机和主板的信息。

Both pages have an English section. The guide covers what to fill in after a board swap. The EFI notes show how V1.11 handles those fields and link to the full disassembly.
