# V1.11 反汇编 / V1.11 Disassembly

[中文](#zh) · [English](#english)

[下载完整列表 / Download the full listings](BootX64-v1.11-disassembly.zip)

<a name="zh"></a>

## 中文

这份列表对应 `n1ctm07w.zip` 里的 `EFI/Boot/BootX64.efi`。它是 ThinkPad Maintenance Utilities V1.11 的 PE32+ x64 EFI 应用，Machine 字段为 `0x8664`，Subsystem 字段为 `10`。

SHA-256 `d25fde71663b77e28e76f01cdd56030772a348be79a78c5ffed7b5d285f52993`

解压后从 `layout.tsv` 看每个镜像在 `BootX64.efi` 里的位置、长度和入口 RVA。`BootX64.txt` 对应外层 EFI，8 个内嵌模块各有一份 `.txt`。

可执行区用 Capstone 5.0.7 按 x64 线性反汇编，其他区域列出原始字节。每行保留文件偏移、RVA 和字节，九份列表合起来覆盖 `BootX64.efi` 的 783,800 个字节。

### 配置文件参数

| 文件与节 | 参数 | 原包值 | 行为 |
| --- | --- | --- | --- |
| `tpconfig.ini` · `[advanced features]` | `hide_adv` | `1` | `1` 选择传统菜单，`0` 选择带 `Planar service` 的高级菜单。 |
| `tpconfig.ini` · `[advanced features]` | `hide_eep_init` | `0` | 在高级菜单中，`0` 显示 `5 - Initialize EEPROM`，`1` 隐藏该项。 |
| `plnsrv.ini` · `[steps]` | `config_kb` | `1` | `1` 启用键盘语言 ID 步骤，`0` 跳过。 |
| `plnsrv.ini` · `[steps]` | `silent_uuid` | `0` | `0` 单独询问是否生成新 UUID，`1` 跳过这道提问。两种设置都保留向导结束时的汇总确认。 |
| `plnsrv.ini` · `[Keyboard]` | 四位键盘语言 ID | 例如 `0409=US English` | 向导用输入的四位 ID 查找对应的语言名称。 |
| `plnsrv.ini` · `[brand name]` | 四位机器类型 | 例如 `20N2=ThinkPad T490` | 向导从整机标识取四位机器类型，查找可供选择的机型名称。 |
| `USBFMT.INI` · `[SystemFileDir]` | `SystemFileDir` | `.\EFI\BOOT` | 包内 Windows 制盘工具的系统文件目录。 |
| `USBFMT.INI` · `[EFI_SUPPORT]` | `EFI_SUPPORT` | `1` | 包内 Windows 制盘工具的 EFI 支持设置。 |

`BootX64.txt` 的外层文件偏移 `0xA8768–0xA8823` 是两个菜单开关的读取和分支。`PLNSRV.txt` 的 RVA `0x7600`、`0x77DB`、`0x9484` 和 `0x974F` 分别引用 `silent_uuid`、`[Keyboard]`、`config_kb` 和 `[brand name]`。

### 菜单与模块

| 屏幕菜单 | 传统 | 高级 | 菜单传给模块的参数 |
| --- | --- | --- | --- |
| `Planar service` | — | `1` | `PLNSRV` |
| `Set system identification` | `1` | `2` | `SERUPDT M` |
| `Assign UUID` | `2` | `3` | `AUTOUUID -Y`，进入 `Change UUID. OK? [Y/N]` 确认流程。 |
| `Update Configuration Area` → `Brand name` | `3` → `2` | `4` → `2` | `CFGUPDT M /BRANDNAME` |

`SERUPDT` 的 `R [TYPE]` 参数用于按设备类型读取，`SERUPDT R C0` 读整机标识，`SERUPDT R B0` 读主板条码。`SERUPDT.txt` 的 RVA `0xAE08–0xAE45` 把 `R` 分派到读取函数 `0x8620`。

### 写入值与检查位置

下表地址为各模块列表中的 RVA。

| 模块与项目 | 参数和检查 | RVA |
| --- | --- | --- |
| `SERUPDT` · 整机标识 `C0` | 标准输入为 `1S` + 10 位 `Type` + 8 位 `SN`，直接拼接，总长 20 个字符。例 `1S20S0002ABCPF00TEST`。`SERUPDT` 检查这一格式的总长度。 | `0x73CB–0x73DA` |
| `SERUPDT` · 主板条码 `B0` | `8S` + 21 个字符，完整输入共 23 个字符。存储时剥掉 `8S`，显示时补回。可通过 `2 - Read S/N data from EEPROM` 查看 `C0` 和 `B0`。 | `0x7301–0x7365` 处理前缀，`0x7422–0x7449` 检查长度。 |
| `SERUPDT` · 旧设备类型与冲突 | 设备类型 `20` 有单独的 16 字符长度检查。新增记录时检查同类型是否已存在，并处理 `C0` 与 `20`、`B0` 与 `40` 的冲突。 | `0x7491–0x749E` 检查 `20` 的长度，`0x7850–0x7896` 包含这两组冲突的映射。 |
| `CFGUPDT` · 机型名称 | `1 - ThinkPad brand name` 自动加上 9 字节的 ASCII 前缀 `ThinkPad `，后缀最多 55 字节。`2 - Special brand name` 输入完整名称，最多 64 字节。两项写入同一个 `0xAB` 字段，提交后读回并逐字节比较 256 字节的配置块。菜单中的 `2 - Read brand name from EEPROM` 可读取名称。 | `0x8BE3–0x8BFA` 添加前缀，`0x8CD6–0x8CE4` 检查长度，`0x8907` 设置字段标签，`0xD609–0xD654` 比较读回数据。 |
| `AUTOUUID` · 单独分配 UUID | 读到 16 字节全零时进入生成流程。全 `FF` 时会显示 `Valid UUID has been already stored.`，因为 `0x2C5B` 把 `FF` 符号扩展为 `-1`，随后的比较使用 `0xFF`。`Written data is unmatch` 表示写后读回的 16 字节与拟写入值不同，这条分支仍会返回 `0`。 | `0x2BFC–0x2C7A` 判断 UUID，`0x2DF8–0x2E10` 处理已有值，`0x2B0F–0x2BEF` 比较和报告写回结果。 |
| `PLNSRV` · 换板向导 | 整机标识检查总长 20 字符和 `1S` 前缀。向导汇总待写项目后显示 `Please confirm(1=YES, 0=NO & Go Back)`。这里用 `1` 确认，可提交新 UUID 和前面选定的项目。 | `0x8D31–0x8D48` 检查整机标识，`0xA2A7` 引用最终确认提示。 |

<a name="english"></a>

## English

These listings cover `EFI/Boot/BootX64.efi` from `n1ctm07w.zip`. This is the PE32+ x64 EFI application for ThinkPad Maintenance Utilities V1.11. Its Machine field is `0x8664` and its Subsystem field is `10`.

SHA-256 `d25fde71663b77e28e76f01cdd56030772a348be79a78c5ffed7b5d285f52993`

Start with `layout.tsv` for each image's offset in `BootX64.efi`, size, and entry RVA. `BootX64.txt` covers the outer EFI image, and each of the 8 embedded images has its own `.txt` listing.

Executable sections use a linear x64 disassembly from Capstone 5.0.7. The remaining ranges are listed as raw bytes. The file offset, RVA, and byte columns across all nine listings cover the 783,800 bytes of `BootX64.efi`.

### Configuration file settings

| File and section | Setting | Included value | Behavior |
| --- | --- | --- | --- |
| `tpconfig.ini` · `[advanced features]` | `hide_adv` | `1` | `1` selects the traditional menu and `0` selects the advanced menu with `Planar service`. |
| `tpconfig.ini` · `[advanced features]` | `hide_eep_init` | `0` | In the advanced menu, `0` shows `5 - Initialize EEPROM` and `1` hides it. |
| `plnsrv.ini` · `[steps]` | `config_kb` | `1` | `1` enables the keyboard language ID step and `0` skips it. |
| `plnsrv.ini` · `[steps]` | `silent_uuid` | `0` | `0` asks separately whether to generate a new UUID. `1` skips that prompt. Both settings keep the final confirmation for all pending changes. |
| `plnsrv.ini` · `[Keyboard]` | Four-character keyboard language ID | For example, `0409=US English` | The wizard looks up the language name using the four-character ID entered. |
| `plnsrv.ini` · `[brand name]` | Four-character machine type | For example, `20N2=ThinkPad T490` | The wizard takes the four-character machine type from the system identifier and looks up a product name the operator can select. |
| `USBFMT.INI` · `[SystemFileDir]` | `SystemFileDir` | `.\EFI\BOOT` | The system file directory for the included Windows USB formatter. |
| `USBFMT.INI` · `[EFI_SUPPORT]` | `EFI_SUPPORT` | `1` | The EFI support setting for the included Windows USB formatter. |

In `BootX64.txt`, outer file offsets `0xA8768–0xA8823` cover the reads and branches for the two menu settings. In `PLNSRV.txt`, RVAs `0x7600`, `0x77DB`, `0x9484`, and `0x974F` reference `silent_uuid`, `[Keyboard]`, `config_kb`, and `[brand name]`, respectively.

### Menus and modules

| Menu label | Traditional | Advanced | Module invocation from the menu |
| --- | --- | --- | --- |
| `Planar service` | — | `1` | `PLNSRV` |
| `Set system identification` | `1` | `2` | `SERUPDT M` |
| `Assign UUID` | `2` | `3` | `AUTOUUID -Y` opens the `Change UUID. OK? [Y/N]` confirmation flow. |
| `Update Configuration Area` → `Brand name` | `3` → `2` | `4` → `2` | `CFGUPDT M /BRANDNAME` |

`SERUPDT` also accepts `R [TYPE]` to read a specific device type. `SERUPDT R C0` reads the system identifier and `SERUPDT R B0` reads the board barcode. In `SERUPDT.txt`, RVAs `0xAE08–0xAE45` dispatch `R` to the read function at `0x8620`.

### Values and validation

The addresses below are RVAs in the corresponding module listings.

| Module and item | Input and checks | RVA |
| --- | --- | --- |
| `SERUPDT` · System identifier `C0` | The standard input is `1S` + 10-character `Type` + 8-character `SN`, joined into a 20-character string. For example, `1S20S0002ABCPF00TEST`. `SERUPDT` checks the total length of this format. | `0x73CB–0x73DA` |
| `SERUPDT` · System board barcode `B0` | `8S` + 21 characters, for a total input of 23. The utility strips `8S` on storage and restores it on display. `2 - Read S/N data from EEPROM` displays `C0` and `B0`. | `0x7301–0x7365` processes the prefix and `0x7422–0x7449` checks the length. |
| `SERUPDT` · Legacy type and conflicts | Device type `20` has its own 16-character length check. Adding a record checks for duplicates and for conflicts between `C0` and `20` or between `B0` and `40`. | `0x7491–0x749E` checks the length for `20`. `0x7850–0x7896` maps the two conflicting pairs. |
| `CFGUPDT` · Product name | `1 - ThinkPad brand name` adds the 9-byte ASCII prefix `ThinkPad ` and accepts a suffix of up to 55 bytes. `2 - Special brand name` accepts the full name, up to 64 bytes. Both write field `0xAB`. On commit, the module reads back and compares the 256-byte configuration block byte for byte. `2 - Read brand name from EEPROM` displays the name. | `0x8BE3–0x8BFA` adds the prefix, `0x8CD6–0x8CE4` checks the length, `0x8907` sets the field tag, and `0xD609–0xD654` compares the readback. |
| `AUTOUUID` · Standalone UUID assignment | UUID generation proceeds when all 16 bytes read back as zero. An all-`FF` value produces `Valid UUID has been already stored.` because `0x2C5B` sign-extends `FF` to `-1` and the comparison uses `0xFF`. `Written data is unmatch` means the 16 bytes read back after the write differ from the intended value. This branch still returns `0`. | `0x2BFC–0x2C7A` checks the UUID, `0x2DF8–0x2E10` handles an existing value, and `0x2B0F–0x2BEF` compares and reports the write result. |
| `PLNSRV` · System board replacement wizard | The wizard checks that the system identifier is 20 characters and starts with `1S`. After listing the pending changes, it displays `Please confirm(1=YES, 0=NO & Go Back)`. Entering `1` can commit the new UUID and the other changes selected earlier. | `0x8D31–0x8D48` checks the system identifier and `0xA2A7` references the final confirmation prompt. |
