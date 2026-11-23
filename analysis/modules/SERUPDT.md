# SERUPDT

[中文](#zh) · [English](#english)

<a name="zh"></a>

## 中文

`SERUPDT` 是 ThinkPad Maintenance Utilities V1.11 的序列号维护模块。菜单将 `C0` 标为整机序列号，将 `B0` 标为系统板序列号。模块嵌入在 `BootX64.efi` 文件偏移 `0x22890`，PE 头记录的入口 RVA 为 `0x4250`。下文地址均为 `SERUPDT.txt` 中的模块 RVA。 [V1.11 分析索引](../README.md#zh) · [完整反汇编列表](../BootX64-v1.11-disassembly.zip)

### 菜单与参数

外层的 `Set system identification` 以 `SERUPDT M` 进入交互菜单。分派器从 `argv[1]` 识别命令，`W`、`R`、`D` 将 `argc - 2` 和 `argv + 2` 交给各自的处理器。

| 命令参数 | 交互菜单 | 行为 | 调用 RVA |
| --- | --- | --- | --- |
| `M` | 打开菜单 | 操作完成后回到菜单，按 `9` 退出。 | `0xAFE9` |
| `W TYPE DATA` | `1 - Add S/N data to EEPROM` | 依次输入十六进制设备类型和序列号。 | `0xADFA`、`0xA77F` |
| `R [TYPE]` | `2 - Read S/N data from EEPROM` | 菜单列出已有记录。命令给出类型时按类型查找。 | `0xAE45`、`0x9EDA` |
| `D TYPE` | `3 - Delete S/N data from EEPROM` | 根据类型删除，输入类型后进入删除处理。 | `0xAE90`、`0xA011` |

### 输入校验

普通 Add 在 `0xA035–0xA052` 比较设备类型输入的前两个字符。文本 `20` 进入专门的旧格式检查。常规 `C0`、`B0` 进入通用提示，读取一行并将 ASCII 小写字母转为大写，再交给 `W` 处理器。类型说明见 `0x9F05–0x9F11`。

| 设备类型 | 常规输入 | `W` 的长度判定 | RVA |
| --- | --- | --- | --- |
| `C0` 整机标识 | `1S` + 10 字符 Type + 8 字符 SN，整串 20 字符。 | `1S` 计入有效长度，要求 20。 | `0x73CB–0x73DA` |
| `B0` 主板条码 | `8S` + 板上标签后续 21 字符，整串 23 字符。 | `8S` 从有效长度中扣除，要求余下 21。写入时从第三个字符开始复制。 | `0x7301–0x7365`、`0x7422–0x7449`、`0x75A9–0x75BE` |
| 旧类型 `20` | `1S` + 四个数字 + 十个字母或数字，整串 16 字符。 | 普通菜单接受 `1s` 并转为 `1S`，`W` 要求有效长度 16。 | `0xA0DD–0xA175`、`0xA20C–0xA481`、`0x7491–0x749E` |

对这三种类型，`W` 在 `0x7298–0x73C2` 计算有效长度。`11S` 扣 3、`8S` 扣 2，其余取整串长度。`C0`、`B0` 的普通 Add 以有效长度为校验条件。Type 和 SN 的拆分来自常规整机标签格式。CLI 帮助中的 `W B0 11S0123456789ABCDEF` 示例有效长度为 16，实际会收到 `The string length of the argument is not correct.`。

`Please input 16 or 19 characters for SN` 位于旧类型 `20` 的菜单分支 `0xA1B4`。该分支依赖的局部标志在 `0x9BD9` 初始化为 0，此菜单函数中随后只有读操作。普通菜单进入 16 字符分支，后端写入同样要求 `20` 的有效长度为 16。

### EEPROM 格式与写入

序列化信息区为 256 字节。记录从 `0x10` 开始，每条记录的首字节是设备类型。块内偏移 `+4`、`+5`、`+6` 分别存放记录宽度、记录数量和格式版本。读取按头部宽度和数量定位记录，以下为模块使用的两种布局。初始化的版本判断见 `0x6E7F–0x6EB4`，记录指针计算见 `0xBAEC`。

| EEPROM 格式版本 | 记录宽度 | 记录数 | 单条记录的数据空间 |
| --- | --- | --- | --- |
| 1 | 20 字节 | 12 | 19 字节 |
| 2 | 24 字节 | 10 | 23 字节 |

新增 `C0` 或 `B0` 时，格式 1 的转换发生在长度、重复和冲突检查通过后。转换将原有记录按槽位顺序复制进 10 个新槽位，空槽也占一个位置。转换例程先提交布局 2，完成后新增路径才查找空槽并写入目标记录。因此，看到 `SIA is converted to new format successfully.` 时，仍需查看接下来的新增结果。版本判断和调用位于 `0x791C–0x7930`、`0xB4E8`，转换复制和提交位于 `0xB550–0xB6C7`。

### 新增、读取与删除

```text
Add(type, input)                                # 0x7044
    validate_effective_length(type, input)       # 0x7298–0x7524
    if find_record(type): return duplicate        # 0x774D–0x7796
    if find_conflicting_record(type): return conflict   # 0x7850–0x7913
    if format_1_requires_conversion(type): convert_and_commit()  # 0x7930
    slot = find_empty_slot()                     # 0x795C–0x79AB
    if slot is missing: return overflow
    store(type, encode_serial(type, input), slot)
    commit_and_read_back()                       # 0x7A27 → 0xB77C

Read(types)                                     # 0x8620
    records = exact_type_matches(types) if types else populated_slots()
    display_type_and_serial(records)             # 0x8720, 0x89D0

Delete(type)                                    # 0x8F14
    record = find_record(type)                   # 0x9032
    if record is missing: return missing
    remove_record_and_shift_following_slots()   # 0x9078 → 0xBB44
    commit_and_read_back()                       # 0x90AD → 0xB77C
```

新增遇到同类型记录时显示 `Data of the same device type is already in EEPROM.`。已有配对的旧类型或新类型时，显示 `The device type conflicts with 0x%02X.`，其中十六进制值是现存的冲突类型。相关配对为 `C0 ↔ 20` 和 `B0 ↔ 40`。两个分支都停止该次新增。空槽用尽时显示 `EEPROM Overflow.`，成功时显示 `Data is written successfully.`。对应消息引用位于 `0x7772`、`0x78F1`、`0x79C0` 和 `0x7A89`。

读取 `B0` 时显示层补回 `8S`。常规 `1S` 整机标识写入时标记首字节的高位，展示时清除该位，显示完整的 `C0`。按类型读取缺失项时显示 `Data not found.`。对应 RVA 为 `0x87F6`、`0x8A69`、`0x7378`、`0x886D`、`0x8AAA` 和 `0x89E2`。

删除按输入类型精确查找，缺失时显示 `Data not found.`，成功时显示 `Data is deleted successfully.`。提交处理器通过 LenovoEeprom 协议更新并读回序列化信息区。新增或删除写入失败显示 `EEPROM fail when reading or writing data.`。维修时可单独运行读取操作，将显示值与原机或替换主板的标签逐字符核对。对应 RVA 为 `0x9044`、`0x90E9`、`0xB77C`、`0x7A4D` 和 `0x90C0`。

<a name="english"></a>

## English

`SERUPDT` is the serial-number maintenance module in ThinkPad Maintenance Utilities V1.11. Its menu labels `C0` as the system-unit serial number and `B0` as the system board serial number. The module starts at file offset `0x22890` in `BootX64.efi` and the PE header gives `0x4250` as its entry RVA. Addresses below are module RVAs in `SERUPDT.txt`. [V1.11 analysis index](../README.md#english) · [Full disassembly listings](../BootX64-v1.11-disassembly.zip)

### Menu and arguments

The outer `Set system identification` menu item launches `SERUPDT M`. The dispatcher identifies the command from `argv[1]`. For `W`, `R`, and `D`, it passes `argc - 2` and `argv + 2` to the selected handler.

| Command arguments | Interactive item | Behavior | Call RVA |
| --- | --- | --- | --- |
| `M` | Open the menu | Operations return to the menu. Press `9` to exit. | `0xAFE9` |
| `W TYPE DATA` | `1 - Add S/N data to EEPROM` | Prompts for the hexadecimal device type, then the serial number. | `0xADFA`, `0xA77F` |
| `R [TYPE]` | `2 - Read S/N data from EEPROM` | The menu lists existing records. A type argument selects records of that type. | `0xAE45`, `0x9EDA` |
| `D TYPE` | `3 - Delete S/N data from EEPROM` | Deletes by type. Entering the type starts the delete handler. | `0xAE90`, `0xA011` |

### Input validation

Interactive Add compares the first two characters of the type input at `0xA035–0xA052`. The literal text `20` enters the legacy input checks. For `C0` and `B0`, the generic prompt reads one line, converts lowercase ASCII letters to uppercase, and calls the `W` handler. The type descriptions are referenced at `0x9F05–0x9F11`.

| Device type | Usual input | `W` length check | RVA |
| --- | --- | --- | --- |
| `C0` system identifier | `1S` + 10-character Type + 8-character SN, for 20 characters total. | Counts `1S` and requires 20 characters. | `0x73CB–0x73DA` |
| `B0` board barcode | `8S` + 21 characters from the board label, for 23 total. | Deducts `8S` and requires 21 remaining characters. The store copies from the third input character onward. | `0x7301–0x7365`, `0x7422–0x7449`, `0x75A9–0x75BE` |
| Legacy type `20` | `1S` + four digits + ten alphanumeric characters, for 16 total. | The menu accepts `1s` and converts it to `1S`. `W` requires an effective length of 16. | `0xA0DD–0xA175`, `0xA20C–0xA481`, `0x7491–0x749E` |

For these three types, `W` calculates effective length at `0x7298–0x73C2`. It deducts three characters for `11S` and two for `8S`. Otherwise it uses the full length. Interactive `C0` and `B0` use the effective length check. The Type and SN split follows the usual system label format. The CLI help example `W B0 11S0123456789ABCDEF` has an effective length of 16 and triggers `The string length of the argument is not correct.`.

`Please input 16 or 19 characters for SN` appears in the legacy type `20` menu branch at `0xA1B4`. The local flag controlling that branch is initialized to zero at `0x9BD9`, and subsequent references in the menu function read it. The normal menu takes the 16-character branch, and the write handler also requires an effective length of 16 for type `20`.

### EEPROM format and writes

The Serialization Information Area is 256 bytes. Records start at `0x10`, with the device type in the first byte of each record. Block offsets `+4`, `+5`, and `+6` hold the record width, record count, and format version. Reads use the header fields to locate records. The version branch is at `0x6E7F–0x6EB4` and record addressing starts at `0xBAEC`.

| EEPROM format version | Record width | Record count | Data capacity per record |
| --- | --- | --- | --- |
| 1 | 20 bytes | 12 | 19 bytes |
| 2 | 24 bytes | 10 | 23 bytes |

When adding `C0` or `B0` to format 1, conversion takes place after the length, duplicate, and conflict checks. The conversion copies the old records in slot order into ten new slots, counting empty slots in that sequence. It commits format 2 before Add looks for an empty slot and stores the requested record. `SIA is converted to new format successfully.` reports the conversion result. The next message gives the Add result. See `0x791C–0x7930` and `0xB4E8` for the version check, and `0xB550–0xB6C7` for the conversion.

### Add, read, and delete

```text
Add(type, input)                                # 0x7044
    validate_effective_length(type, input)       # 0x7298–0x7524
    if find_record(type): return duplicate        # 0x774D–0x7796
    if find_conflicting_record(type): return conflict   # 0x7850–0x7913
    if format_1_requires_conversion(type): convert_and_commit()  # 0x7930
    slot = find_empty_slot()                     # 0x795C–0x79AB
    if slot is missing: return overflow
    store(type, encode_serial(type, input), slot)
    commit_and_read_back()                       # 0x7A27 → 0xB77C

Read(types)                                     # 0x8620
    records = exact_type_matches(types) if types else populated_slots()
    display_type_and_serial(records)             # 0x8720, 0x89D0

Delete(type)                                    # 0x8F14
    record = find_record(type)                   # 0x9032
    if record is missing: return missing
    remove_record_and_shift_following_slots()   # 0x9078 → 0xBB44
    commit_and_read_back()                       # 0x90AD → 0xB77C
```

When the requested type already exists, Add prints `Data of the same device type is already in EEPROM.` An existing record of the paired legacy or newer type produces `The device type conflicts with 0x%02X.`, where the hexadecimal value identifies the existing conflicting type. The relevant pairs are `C0 ↔ 20` and `B0 ↔ 40`. Both branches stop that addition. A full record area produces `EEPROM Overflow.`, and a successful addition produces `Data is written successfully.` The message references are at `0x7772`, `0x78F1`, `0x79C0`, and `0x7A89`.

Read restores the `8S` prefix when displaying `B0`. For the usual `1S` system identifier, the write path marks the high bit of the first byte and the display path clears it, restoring the full `C0` text. A missing type in a targeted read produces `Data not found.` See `0x87F6`, `0x8A69`, `0x7378`, `0x886D`, `0x8AAA`, and `0x89E2`.

Delete looks for the exact requested type. A missing record produces `Data not found.` and a successful deletion produces `Data is deleted successfully.` The commit handler updates and reads back the Serialization Information Area through the LenovoEeprom protocol. Add and Delete report a write failure as `EEPROM fail when reading or writing data.` After a repair, a separate Read lets the technician compare the displayed value with the original system or replacement board label. See `0x9044`, `0x90E9`, `0xB77C`, `0x7A4D`, and `0x90C0`.
