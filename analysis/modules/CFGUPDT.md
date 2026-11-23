# CFGUPDT 机型名称 / Product name

[中文](#zh) · [English](#english)

[反汇编索引 / Disassembly index](../README.md) · [完整反汇编 / Full disassembly](../BootX64-v1.11-disassembly.zip)

<a name="zh"></a>

## 中文

`CFGUPDT` 是 ThinkPad Maintenance Utilities V1.11 内嵌的配置区工具，自带版本号为 `V2.1.7(Discrete)(X64)`。下文地址均为压缩包中 `CFGUPDT.txt` 的模块 RVA。模块位于外层 `BootX64.efi` 文件偏移 `0x40EE0`。

### 菜单和输入

从主菜单进入 `Update Configuration Area`，传统菜单是第 3 项，高级菜单是第 4 项。再选 `2 - brand name` 和 `1 - Write brand name to EEPROM`。外层菜单用 `CFGUPDT M /BRANDNAME` 打开品牌名菜单。

| 写入选项 | 输入 | 显示预览 |
| --- | --- | --- |
| `1 - ThinkPad brand name` | 输入机型后缀，最多 55 字节。程序补上 9 字节的 `ThinkPad `，含末尾空格。 | 输入 `T41p` 时显示 `ThinkPad T41p`。 |
| `2 - Special brand name` | 输入完整名称，最多 64 字节。 | 输入 `ThinkPad T41p` 时显示 `ThinkPad T41p`。 |
| `3 - Intentional blank` | 跳过名称输入，准备写入空字符串。 | 名称为空。 |

菜单接受可打印 ASCII（`0x20–0x7E`）。选项 1 和 2 在空行时继续等待输入，并按“已有前缀 + 输入 + 结束字节”检查 65 字节上限。程序显示 `Brand name to input` 后用 `y` 确认。共用写入函数随后略过字符串开头的空白和等号，因此选项 2 的预览和回读在这些字符上可能有差异。

写入后可选 `2 - Read brand name from EEPROM` 查看名称，也可用 `CFGUPDT R /BRANDNAME` 读取。帮助列出 `W /BRANDNAME="Brand Name String"` 用于提交完整名称，`V /BRANDNAME="Brand Name String"` 用于逐字节核对指定名称。手动菜单的前缀逻辑位于写入函数之前。

### 配置块与回读

配置块长 256 字节，以 `CON#` 开头。块内偏移 `0x04` 存放已用长度，记录从 `0x10` 开始。三种写入选项共用标签 `0xAB`。

| 记录内偏移 | 内容 |
| --- | --- |
| `+0x00` | 标签 `0xAB` |
| `+0x01` | 记录总长度，等于实际保存的名称字节数加 3，最大 `0x43` |
| `+0x02` | 名称字节，末尾为 `0x00` |

`Intentional blank` 保存 `AB 03 00`，再次读取时显示 `Brand name: -NULL-`。品牌名菜单的 `3 - Delete brand name from EEPROM` 移除记录，读不到记录时显示 `Target block does not exist.`。

程序先读取配置块并在工作副本中替换或追加记录。完成修改后，提交函数更新校验字节，通过 LenovoEeprom 协议写入块选择值 `0x56`，再读回整个块并逐字节比较。回读失败返回 `0x10`，写入失败或回读内容不同返回 `0x11`。

```text
current = read_config(0x56)
if read fails: return 0x10
if config_header_invalid(current): return 0x20
staged = copy(current)

name = trim_leading_whitespace_and_equals(confirmed_name)
record = [0xAB, len(name) + 3] + name + [0x00]
status = replace_or_append(staged, record)
if status != 0: return status

update_checksums(staged)
if write_config(0x56, staged) fails: return 0x11
current = read_config(0x56)
if read fails: return 0x10
if current differs from staged across 256 bytes: return 0x11
return 0
```

| RVA | 指令用途 |
| --- | --- |
| `0x0488`、`0x8EF0` | `BRANDNAME` 分发表项和交互菜单。 |
| `0x8BE3–0x8BFA`、`0x8CD6–0x8CE4` | 添加前缀和检查预览名称长度。 |
| `0x8DC8`、`0x8894–0x89A2` | 确认后调用共用写入函数，准备并替换或追加 `0xAB` 记录。 |
| `0x884C`、`0x9064`、`0x89C8` | 查找名称、显示名称及删除记录。 |
| `0xCDE8` | 从配置块内偏移 `0x10` 开始按记录长度遍历。 |
| `0x9011`、`0xD5BC–0xD654` | 菜单触发提交，提交函数写入并比较回读的 256 字节。 |

<a name="english"></a>

## English

`CFGUPDT` is the Configuration Information Area utility embedded in ThinkPad Maintenance Utilities V1.11. Its own banner shows `V2.1.7(Discrete)(X64)`. Addresses below are module-relative RVAs in `CFGUPDT.txt`. The module starts at file offset `0x40EE0` in the outer `BootX64.efi`.

### Menu and input

From the main menu, open `Update Configuration Area`, item 3 in the traditional menu or item 4 in the advanced menu. Then choose `2 - brand name` and `1 - Write brand name to EEPROM`. The launcher opens the brand name menu with `CFGUPDT M /BRANDNAME`.

| Write option | Input | Preview |
| --- | --- | --- |
| `1 - ThinkPad brand name` | Enter the model suffix, up to 55 bytes. The utility adds the 9-byte prefix `ThinkPad `, including the trailing space. | Entering `T41p` shows `ThinkPad T41p`. |
| `2 - Special brand name` | Enter the full name, up to 64 bytes. | Entering `ThinkPad T41p` shows `ThinkPad T41p`. |
| `3 - Intentional blank` | The menu skips text input and prepares an empty string. | The name is blank. |

The menu accepts printable ASCII (`0x20–0x7E`). For options 1 and 2, an empty line prompts again. The combined prefix, input and terminator must fit in 65 bytes. The menu shows `Brand name to input` and accepts `y` to confirm. The shared writer then skips leading whitespace and equals signs, so option 2 can display those characters in the preview and omit them in the stored name.

Choose `2 - Read brand name from EEPROM` to inspect the saved value, or use `CFGUPDT R /BRANDNAME`. The help lists `W /BRANDNAME="Brand Name String"` to submit a full name and `V /BRANDNAME="Brand Name String"` to compare the specified value byte for byte. The interactive menu applies its prefix before calling the writer.

### Configuration block and readback

The 256-byte configuration block starts with `CON#`. Its byte at offset `0x04` holds the used length, and the records start at offset `0x10`. All three write options use tag `0xAB`.

| Record offset | Contents |
| --- | --- |
| `+0x00` | Tag `0xAB` |
| `+0x01` | Total record length, equal to the stored name length plus 3, with a maximum of `0x43` |
| `+0x02` | Name bytes followed by `0x00` |

`Intentional blank` stores `AB 03 00` and reads back as `Brand name: -NULL-`. The brand name menu's `3 - Delete brand name from EEPROM` removes the record. Reading an absent record reports `Target block does not exist.`.

The utility first reads the configuration block and replaces or appends the record in a working copy. At commit, it updates the checksum bytes, writes through the LenovoEeprom protocol using block selector `0x56`, and rereads the full block for a byte-by-byte comparison. A failed readback returns `0x10`. A failed write or a readback mismatch returns `0x11`.

```text
current = read_config(0x56)
if read fails: return 0x10
if config_header_invalid(current): return 0x20
staged = copy(current)

name = trim_leading_whitespace_and_equals(confirmed_name)
record = [0xAB, len(name) + 3] + name + [0x00]
status = replace_or_append(staged, record)
if status != 0: return status

update_checksums(staged)
if write_config(0x56, staged) fails: return 0x11
current = read_config(0x56)
if read fails: return 0x10
if current differs from staged across 256 bytes: return 0x11
return 0
```

| RVA | Instruction purpose |
| --- | --- |
| `0x0488`, `0x8EF0` | `BRANDNAME` dispatch entry and interactive menu. |
| `0x8BE3–0x8BFA`, `0x8CD6–0x8CE4` | Prefix copy and preview name length check. |
| `0x8DC8`, `0x8894–0x89A2` | Confirmation calls the shared writer, which prepares and replaces or appends the `0xAB` record. |
| `0x884C`, `0x9064`, `0x89C8` | Find, display and remove the record. |
| `0xCDE8` | Walk records by length, beginning at configuration block offset `0x10`. |
| `0x9011`, `0xD5BC–0xD654` | The menu triggers commit, which writes and compares all 256 bytes of the readback. |
