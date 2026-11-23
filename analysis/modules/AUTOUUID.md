# AUTOUUID · UUID 分配 / UUID assignment

[中文](#zh) · [English](#english) · [参数索引 / Parameter index](../README.md) · [完整反汇编 / Full disassembly](../BootX64-v1.11-disassembly.zip)

<a name="zh"></a>

## 中文

`AUTOUUID` 是 ThinkPad Maintenance Utilities V1.11 的内嵌模块，程序横幅显示 `Auto UUID generation utility V2.11(X64) (Discrete EEPROM)`。它在 `BootX64.efi` 中的文件偏移为 `0x8C770`，长度 39,488 字节，入口 RVA 为 `0x1C20`。下文地址均是 `AUTOUUID.txt` 中的模块 RVA。

### 菜单参数

传统菜单的 `2 - Assign UUID` 和高级菜单的 `3 - Assign UUID` 都调用 `AUTOUUID -Y`。这条调用由程序生成 16 字节 UUID，`-Y` 表示写入前询问确认。参数解析在 `0x2727` 引用 `-Y`，并在 `0x273F` 置位确认标志。生成成功后，`0x2E42` 检查该标志，`0x2E4D` 调用提示例程。屏幕显示 `Change UUID. OK? [Y/N]`，选 `Y` 才进入写入，选 `N` 显示 `Canceled.`。

### 何时生成 UUID

`0x2DCB` 调用 `0x2808`，通过 `LenovoEeprom` 读出 UUID 的 16 字节。`0x2DF8` 调用 `0x2BFC` 判断是否已有值。第一轮用 `0x2C25` 逐字节检查是否为零。只有 16 字节全零时，这一路才返回 `0`，并在 `0x2E1A` 调用 `0x30B0` 生成新值。

第二轮看起来要识别全 `FF`，但 `0x2C5B` 的 `movsx` 把字节 `0xFF` 符号扩展成 `0xFFFFFFFF`（`-1`），`0x2C5F` 的 `cmp eax, 0xff` 比较的是 `0x000000FF`（`255`）。因此全 `FF` 和其他含非零字节的值一样，会走 `0x2E04` 的 `Valid UUID has been already stored.` 提示，随后退出这一菜单操作。

### 写入与读回

确认后，`0x2E75` 调用写入例程 `0x28C0`。`0x2AE2` 发起写后的 EEPROM 读回，`0x2B0F–0x2B2D` 比较拟写入和读回的 16 字节。若两者有差异，`0x2B33` 引用 `Written data is unmatch`，并接着输出两组字节。该分支虽然在 `0x2BE6` 记录了 `1`，随后 `0x2BEF` 却清零 `eax`，所以写入例程仍返回 `0`。

主流程会把这个返回码当作成功，接着在 `0x2E9A` 打印 `UUID = [ … ] is stored.`。那里显示的是准备写入的字节。判断实际保存的值，应以 BIOS 或系统重新读到的 UUID 为准。

### 菜单流程伪代码

```text
当前值 = 读取 UUID 的 16 字节
如果读取失败，报告错误并退出
如果当前值有任意非零字节，提示已有 UUID 并退出

新值 = 生成 16 字节 UUID
如果生成失败，报告错误并退出
如果 -Y 确认未通过，提示取消并退出

状态 = 写入新值并读回比较
如果读回值不同，写入例程会报告差异，但仍返回 0
如果状态为 EFI 错误，报告写入错误并退出
显示准备写入的新值
```

## English

`AUTOUUID` is embedded in ThinkPad Maintenance Utilities V1.11. Its banner reads `Auto UUID generation utility V2.11(X64) (Discrete EEPROM)`. The module starts at file offset `0x8C770` in `BootX64.efi`, is 39,488 bytes long, and has entry RVA `0x1C20`. The addresses below are module RVAs in `AUTOUUID.txt`.

### Menu parameter

`2 - Assign UUID` in the traditional menu and `3 - Assign UUID` in the advanced menu both invoke `AUTOUUID -Y`. This invocation generates a 16-byte UUID, and `-Y` requests confirmation before writing it. The argument parser references `-Y` at `0x2727` and sets the confirmation flag at `0x273F`. After generation succeeds, `0x2E42` checks that flag and `0x2E4D` calls the prompt routine. At `Change UUID. OK? [Y/N]`, choosing `Y` proceeds to the write and choosing `N` displays `Canceled.`.

### When the module generates a UUID

`0x2DCB` calls `0x2808` to read the 16 UUID bytes through `LenovoEeprom`. `0x2DF8` calls `0x2BFC` to check for an existing value. The first loop tests each byte for zero at `0x2C25`. With all 16 bytes zero, this path returns `0`, and `0x2E1A` calls `0x30B0` to generate a new value.

The second loop appears to check for an all-`FF` value. Its `movsx` at `0x2C5B` sign-extends the byte `0xFF` to `0xFFFFFFFF` (`-1`), and `cmp eax, 0xff` at `0x2C5F` compares it with `0x000000FF` (`255`). An all-`FF` value therefore follows the same branch as any other value containing a nonzero byte. The utility prints `Valid UUID has been already stored.` at `0x2E04` and exits the menu operation.

### Write and readback

After confirmation, `0x2E75` calls the write routine at `0x28C0`. `0x2AE2` reads the EEPROM back after writing, and `0x2B0F–0x2B2D` compares the 16 intended bytes with the 16 bytes read back. If the values differ, `0x2B33` references `Written data is unmatch` and the routine prints both byte sequences. The branch records `1` at `0x2BE6`, then clears `eax` at `0x2BEF`, so the write routine still returns `0`.

The caller treats that return value as success and prints `UUID = [ … ] is stored.` at `0x2E9A`. The bytes in that message come from the value prepared for writing. To establish what was saved, read the UUID again from the BIOS or operating system.

### Menu flow pseudocode

```text
current = read the 16 UUID bytes
if the read failed, report the error and return
if any byte in current is nonzero, report that a UUID exists and return

candidate = generate a 16-byte UUID
if generation failed, report the error and return
if the -Y confirmation is declined, report cancellation and return

status = write candidate and compare the readback
if the readback differs, the write routine reports the mismatch but returns 0
if status is an EFI error, report the write error and return
display candidate
```
