# PLNSRV · 换板配置向导 / Board replacement wizard

[中文](#zh) · [English](#english) · [流程伪代码 / Pseudocode](#pseudocode) · [反汇编 / Listings](../BootX64-v1.11-disassembly.zip)

<a name="zh"></a>

## 中文

`Planar service` 启动 `PLNSRV`。向导先准备整机标识、机型名称、键盘语言和新 UUID，最后在同一页确认待写内容。以下地址都是 `PLNSRV.txt` 里的模块 RVA。该模块在外层 `BootX64.efi` 的文件偏移为 `0x1AE0`。

### 阶段和参数

| 阶段 | 读取或填写的内容 | 对照 RVA |
| --- | --- | --- |
| 整机标识 | 界面列出现有 `B0` 和 `C0`。这一阶段填写 `C0`，检查 `1S` 前缀和 20 字符的总长度。 | `0x8BA8` 进入阶段，`0x8C3A` 引用已有记录标题，`0x8D31–0x8D48` 检查输入。 |
| 机型名称 | 用 `C0` 中的四位机器类型查 `plnsrv.ini` 的 `[brand name]`。有匹配时可以选配置中的名称。手工输入时填写完整产品名称。 | `0x974F` 引用查找节，`0x98F8` 进入阶段。 |
| 键盘语言 | `[steps]` 的 `config_kb=0` 跳过这一步。原包为 `1`，程序还会检查对应的 UEFI 键盘配置协议。界面要求四位十六进制 ID，并从 `[Keyboard]` 查名称，例如 `0409=US English`。 | `0x7129–0x715D` 选择阶段表，`0x784C` 查协议，`0x78FA` 引用输入提示，`0x7955` 调用查找。 |
| UUID | 原包 `silent_uuid=0`，会单独问是否生成新值。输入 `1` 生成，`0` 返回。配置值为 `1` 时直接生成待写值，最后的汇总确认仍会出现。 | `0x7600` 读设置，`0x7685` 和 `0x7726` 调用生成函数。 |
| 汇总确认 | 显示 `C0`、名称、可用的键盘语言和生成 UUID 的提示。输入 `1` 后，顺序调用整机标识、机型名称、键盘语言和 UUID 的写入流程。 | `0xA2A7` 引用最终提示，`0xA32C–0xA344` 调用写入。 |

阶段函数表在 `0x3C8`，主循环从 `0x70B4` 开始。当前阶段成功就进入下一步，选择返回就回到上一步。键盘写入还会检查解析后的值在 `0x0100–0xFFFF` 范围内，判断在 `0x7A25–0x7A3F`。

`0xA344` 调用 UUID 写入函数，返回后直接在 `0xA349` 准备打印汇总。核对 UUID 时，以写入后读到的值为准。单独分配 UUID 的判断流程见 [AUTOUUID](AUTOUUID.md#zh)。

[返回参数表](../README.md#zh)

## English

`Planar service` launches `PLNSRV`. The wizard collects the system identifier, product name, keyboard language, and a new UUID before showing them together for confirmation. The addresses below are module RVAs in `PLNSRV.txt`. The embedded image starts at file offset `0x1AE0` in `BootX64.efi`.

### Stages and parameters

| Stage | Value read or entered | RVA |
| --- | --- | --- |
| System identifier | The screen shows the current `B0` and `C0`. This step collects `C0` and checks for the `1S` prefix and a total of 20 characters. | `0x8BA8` enters the stage, `0x8C3A` references the current-record heading, and `0x8D31–0x8D48` validates the input. |
| Product name | The wizard takes the four-character machine type from `C0` and looks it up in `[brand name]` in `plnsrv.ini`. A matching name can be selected. For manual entry, use the full product name. | `0x974F` references the lookup section and `0x98F8` enters the stage. |
| Keyboard language | `config_kb=0` under `[steps]` skips this step. The included setting is `1`, and the wizard checks for the corresponding UEFI keyboard configuration protocol as well. The prompt takes a four-digit hexadecimal ID and looks up the name in `[Keyboard]`, for example `0409=US English`. | `0x7129–0x715D` selects a stage list, `0x784C` looks for the protocol, `0x78FA` references the prompt, and `0x7955` calls the lookup. |
| UUID | The included `silent_uuid=0` asks separately whether to generate a UUID. Enter `1` to generate it or `0` to go back. A setting of `1` prepares the value automatically and keeps the final confirmation. | `0x7600` reads the setting. `0x7685` and `0x7726` call the generator. |
| Final confirmation | Shows `C0`, the product name, the keyboard language if available, and the UUID generation notice. Entering `1` calls the system-identifier, product-name, keyboard-language, and UUID write routines in order. | `0xA2A7` references the final prompt. `0xA32C–0xA344` calls the write routines. |

The stage function table is at `0x3C8` and the main loop starts at `0x70B4`. A stage result moves the wizard forward or back. The keyboard write validates the parsed ID against `0x0100–0xFFFF` at `0x7A25–0x7A3F`.

`0xA344` calls the UUID writer. After it returns, `0xA349` immediately prepares the summary message. Use a subsequent read to check the UUID. See [AUTOUUID](AUTOUUID.md#english) for the separate UUID assignment flow.

[Back to the parameter reference](../README.md#english)

## Pseudocode

流程摘要 / Control-flow summary

```text
stages = [system_identifier, product_name]
if config_kb != 0 and keyboard_protocol_is_available:
    stages += [keyboard_language]
stages += [prepare_uuid, confirm]

run stages, moving forward or back according to each result

prepare_uuid:
    if not silent_uuid and operator chooses to go back:
        return back
    prepare generated UUID

confirm:
    display pending changes
    if operator confirms:
        write C0
        write product name
        if keyboard setting is enabled:
            call keyboard writer with its ID checks
        call UUID writer
        print summary
```
