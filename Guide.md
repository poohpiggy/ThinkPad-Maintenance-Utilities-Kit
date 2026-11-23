# ThinkPad Maintenance Utilities V1.11 使用教程 / User Guide

[中文](#zh) · [English](#english)

<a name="zh"></a>

## 中文

这是我们整理的 ThinkPad 换板笔记，从制作维护 U 盘写到恢复机器信息和读回核对。用的是 [`n1ctm07w.zip`](n1ctm07w.zip) 里的 **ThinkPad Maintenance Utilities V1.11（X64）**。

先翻一下对应型号的 Lenovo《硬件维护手册》。有些机型用其他版本，或指定使用 System Board Self-Repair Tool。

想看工具内部是怎么判断的，可以翻 [EFI 分析笔记](EFI-Analysis.md#zh)。

### 一、准备设备信息

先从原机 BIOS、机身标签或维修记录抄下整机信息。更换过主板时，从**实际装入的主板**标签或对应维修记录取得主板条码。

| 项目 | 从哪里取得 |
| --- | --- |
| 机器类型型号（MTM）及整机序列号（S/N） | 机身标签、旧板 BIOS 或维修记录。按机型要求组合成 `C0` 的写入值。 |
| 主板条码（`B0`） | 当前主板标签或维修记录。若该机型使用 `8S` 条码，记下包含 `8S` 前缀的完整字符串。 |
| 机型名称（`Brand name`） | 联想机型资料或旧板读出的产品名称。记下原有大小写和空格。 |
| 系统 UUID | 从现有 BIOS 或系统读出并记录。仅在新板缺少有效 UUID 时生成。 |

准备一只已经备份或可清空的 U 盘。接上目标 ThinkPad 的电源适配器，写入过程中保持供电。

### 二、在 Windows 制作维护 U 盘

1. 将 `n1ctm07w.zip` 完整解压到一个文件夹。解压目录下应有 `usbfmtpw.exe`、`USBFMT.INI`、`plnsrv.ini`、`tpconfig.ini` 和 `EFI\Boot\BootX64.efi`。运行制盘工具时，让 `USBFMT.INI` 和 `EFI` 目录留在 `usbfmtpw.exe` 同级。
2. 插入 U 盘。在资源管理器确认盘符和容量，运行 `usbfmtpw.exe`。如果 Windows 提示需要提升权限，用管理员身份重新打开程序。
3. 在 `USB Format for FAT` 窗口选定刚确认的 U 盘盘符，点 `Start`。核对确认框里的盘符，再点 `OK`。**格式化会清空所选 U 盘。**
4. 等待 `Format Complete` 或格式化成功提示。回到资源管理器打开 U 盘，卷标可能显示为 `LENOVOBIOS`。例如 U 盘盘符是 `E:`，引导文件应位于 `E:\EFI\Boot\BootX64.efi`。再核对 U 盘根目录里的 `plnsrv.ini` 和 `tpconfig.ini`，有缺失就把解压目录中的原件复制过去。完成后安全弹出 U 盘。

### 三、从维护 U 盘启动

1. 在关机状态插入维护 U 盘。开机出现 ThinkPad 标志时，按该机型维护手册指定的按键。部分机型在标志画面按 `Esc` 进入维护工具。
2. 如果机型支持从启动菜单选择设备，可在标志画面按 `F12`，选择 U 盘的 UEFI 启动项。如果 BIOS 提供 `UEFI/Legacy Boot` 选项，按机型手册使用 `UEFI Only`。
3. 看到 `ThinkPad Maintenance Utilities V1.11(X64)` 后，按屏幕上的英文菜单名称选择。这份压缩包的 `tpconfig.ini` 配置为传统菜单，编号如下。

| 传统菜单 | 用途 |
| --- | --- |
| `1 - Set system identification` | 读取、写入和删除 `C0`、`B0` |
| `2 - Assign UUID` | 为缺少有效 UUID 的主板生成 UUID |
| `3 - Update Configuration Area` | 读取和写入机型名称 |
| `9 - Exit (Shutdown)` | 退出并关机 |

如果屏幕第一项显示 `1 - Planar service`（换板配置向导），上表前三项在该界面依次排在 `2`、`3`、`4`。例如，写整机序列号或主板条码时，直接选 `Set system identification`。

### 四、读取和恢复整机序列号与主板条码

`C0` 和 `B0` 都在 `Set system identification`，使用同一套读写菜单。每次确认前看清设备类型和待写内容。

#### 整机序列号和 MTM（C0）

1. 进入 `Set system identification`，选 `2 - Read S/N data from EEPROM`，查看并记录现有 `C0`。与原机资料一致的话，直接保留。
2. **`C0` 的填写格式是 `1S` 开头 + `Type` 码 + `SN` 码。** 三段直接拼接，保留前导零。`Type` 码通常填完整的机器类型型号（MTM），`SN` 码填原机的整机序列号。V1.11 对 `1S` 开头的 `C0` 字符串检查总长度 **20 个字符**，其中包含前缀。若标签另列 Product ID，按该机型的维修资料选择对应的值。

   以下用虚构号码演示拼接。`20S0` 是示例的前四位机器类型，`20S0002ABC` 才是完整的 `Type` 码。

   | `Type` 码 | `SN` 码 | `C0` 完整输入 |
   | --- | --- | --- |
   | `20S0002ABC`（10 位） | `PF00TEST`（8 位） | `1S20S0002ABCPF00TEST`（20 个字符） |

3. `C0` 为空时，选 `1 - Add S/N data to EEPROM`。看到 `Enter the Device Type number` 时输入 `C0` 并回车，看到 `Enter the Serial Number` 时输入拼好的完整字符串并回车。
4. 若工具提示同类型数据已存在，先读回确认。只有在确认现有 `C0` 错误、已记录原值且已核对正确替换值后，才选 `3 - Delete S/N data from EEPROM` 并输入 `C0`，随后重新执行新增。写入成功后再用 `Read S/N data from EEPROM` 核对。

#### 主板条码（B0）

1. 在同一菜单选 `2 - Read S/N data from EEPROM`，读取 `B0`，与当前主板标签核对。条码一致就保留。
2. `B0` 为空时，选 `1 - Add S/N data to EEPROM`，设备类型输入 `B0`，回车后输入当前主板的完整序列条码。V1.11 写入 `8S` 格式时要求前缀后有 **21 个字符**，连同 `8S` 共 23 个字符。若标签长度不同，先核对机型资料和工具版本。主板标签上的 FRU P/N 用于识别备件型号，填写时认准序列条码。
3. 如需更正已存在的错误条码，先记录原值并确认新值，再用 `3 - Delete S/N data from EEPROM` 删除 `B0`，随后新增正确条码。写完读回 `B0`，逐字符与板上标签核对。

### 五、恢复机型名称

1. 从主菜单进入 `Update Configuration Area`，选择 `2 - Brand name`，再选 `2 - Read brand name from EEPROM`。先记录现有名称。正确的话，保留现有值。
2. 需要补写或更正时，进入 `1 - Write brand name to EEPROM`。下面两种方式写入同一个名称字段，按机型需要选一种。

   | 输入方式 | 填写示例 |
   | --- | --- |
   | `1 - ThinkPad brand name` | 填 `X1 Carbon Gen 9`。工具添加 `ThinkPad ` 前缀。 |
   | `2 - Special brand name` | 填完整名称，例如 `ThinkPad X1 Carbon Gen 9`。 |

3. 回车后检查工具预览的完整名称，确认无误再输入 `Y`。写入结束后返回 `Read brand name from EEPROM` 复核。名称示例对应 X1 Carbon Gen 9，维修其他型号时使用对应的产品名称。

### 六、补齐系统 UUID

1. 仅在确认新主板缺少有效 UUID 时，从主菜单进入 `Assign UUID`。V1.11 只在读到 16 字节全零时继续生成 UUID。已有值会显示 `Valid UUID has been already stored.`，全 `FF` 也会触发这条提示。遇到异常占位值时，按该机型的维修流程处理。
2. 在 `Change UUID. OK? [Y/N]` 提示处输入 `Y` 写入 UUID，并记录生成的值。若出现 `Written data is unmatch`，表示读回校验失败，即使工具随后仍显示 UUID。重启后按下一节读回复核。

### 七、重启复核

1. 退出工具并拔掉 U 盘。开机按 `F1` 进入 BIOS，核对可见的 MTM、整机 S/N 和 UUID，再确认正常启动且相关开机报错消失。
2. 主板条码以工具的 `B0` 读回值和实物标签为准。机型名称以 `Read brand name from EEPROM` 读回为准，也可以对照系统显示的产品名称。
3. 在 Windows 上打开 PowerShell 7，进入 [Get-ThinkPadIdentity.ps1](Get-ThinkPadIdentity.ps1) 所在的目录，运行下面的命令。脚本通过 CIM 读取 SMBIOS 信息，用于交叉检查 MTM、产品名称、整机序列号、UUID、主板型号和主板序列号。部分机型只公开部分字段，板号仍以维护工具和主板标签为准。

   ```powershell
   pwsh -NoProfile -File .\Get-ThinkPadIdentity.ps1
   ```

### 常见问题

| 现象 | 检查方法 |
| --- | --- |
| 启动菜单找不到 U 盘 | 检查 `EFI\Boot\BootX64.efi` 是否在 U 盘根目录下的对应路径，确认启用了 USB 启动和 UEFI，再按机型手册选择启动入口。 |
| 启动时提示 `Secure Boot` 或签名错误 | 查该机型手册允许的启动方式与维护包版本。若因维护调整过固件设置，操作完后恢复原设置。 |
| 能进入工具，但写入提示 `Write Protected` 或 `Access is denied` | 确认 U 盘由包内制盘工具制作，并核对该机型的维护启动方式和工具版本。问题持续时，记录完整报错并停止写入。 |
| 出现同类型数据已存在或长度不正确的提示 | 已存在时先读回并比对。长度不正确时核对设备类型、前缀、MTM 或 Product ID 和原始条码，以机型资料和工具提示为准。 |
| 提示 `The device type conflicts with ...` | 先读回现有记录。V1.11 将 `C0` 与 `20`、`B0` 与 `40` 分别视为冲突。核对机型资料后再决定如何处理。 |
| BIOS 仍报告机器类型、序列号或 UUID 无效 | 读回对应项目，确认写入成功且内容逐字吻合。避免用 `Initialize EEPROM` 处理单一字段错误，它会清除机器标识及其他配置。 |

## English

These are our notes on restoring machine information after a ThinkPad system board replacement. They cover **ThinkPad Maintenance Utilities V1.11 (x64)** in [`n1ctm07w.zip`](n1ctm07w.zip), from making the USB drive to checking the values afterward.

Check the Lenovo Hardware Maintenance Manual for your exact model first. Some models call for a different version or the System Board Self-Repair Tool. For details on what V1.11 does with the values you enter, see the [EFI analysis notes](EFI-Analysis.md#english).

### 1. Gather the original information

Record the original system information from the BIOS, the case label, or the repair record. For the board barcode, use the label on the **board you actually installed** or its repair record.

| Item | Where to find it |
| --- | --- |
| Machine Type Model (MTM) and system serial number (S/N) | Case label, old board's BIOS, or repair record. Together they make up the `C0` value. |
| Board barcode (`B0`) | Replacement board label or repair record. If it uses an `8S` barcode, copy the entire string, including `8S`. |
| Product name (`Brand name`) | Lenovo's model documentation or the name read from the old board. Keep the original capitalization and spaces. |
| System UUID | Read it from the BIOS or the operating system. Generate one when the new board is missing a valid UUID. |

Use a USB drive you can erase and keep the ThinkPad plugged into AC power while writing the values.

### 2. Make the maintenance USB drive in Windows

1. Extract all of `n1ctm07w.zip` to a folder. It should contain `usbfmtpw.exe`, `USBFMT.INI`, `plnsrv.ini`, `tpconfig.ini`, and `EFI\Boot\BootX64.efi`. Keep `USBFMT.INI` and the `EFI` folder next to `usbfmtpw.exe` when you run it.
2. Plug in the USB drive. Check its drive letter and capacity in File Explorer, then run `usbfmtpw.exe`. Run it as administrator if Windows asks for elevation.
3. In `USB Format for FAT`, select the drive letter you checked and click `Start`. Check it again in the confirmation dialog and click `OK`. **Formatting erases the selected USB drive.**
4. Wait for `Format Complete` or the success message. Open the USB drive in File Explorer. Its label may be `LENOVOBIOS`. For drive `E:`, the boot file should be at `E:\EFI\Boot\BootX64.efi`. Check for `plnsrv.ini` and `tpconfig.ini` in the root of the USB drive, and copy any missing file from the extracted folder. Eject the drive when finished.

### 3. Start the maintenance utility

1. With the ThinkPad off, plug in the maintenance USB drive. Power on and use the startup key given in your model's maintenance manual. Some models enter the utility when you press `Esc` at the ThinkPad logo.
2. If your model supports a boot menu, press `F12` at the logo and select the UEFI entry for the USB drive. If your BIOS offers `UEFI/Legacy Boot`, follow the model's manual for using `UEFI Only`.
3. When you see `ThinkPad Maintenance Utilities V1.11(X64)`, select entries by their names. The included `tpconfig.ini` selects the traditional menu.

| Traditional menu | What it does |
| --- | --- |
| `1 - Set system identification` | Read, add, or delete `C0` and `B0`. |
| `2 - Assign UUID` | Generate a UUID when the board has none. |
| `3 - Update Configuration Area` | Read or write the product name. |
| `9 - Exit (Shutdown)` | Exit and power off. |

If the first item is `1 - Planar service`, the first three functions in the table appear at `2`, `3`, and `4`. To work on a system serial number or a board barcode, look for `Set system identification`.

### 4. Restore the system serial number and board barcode

Both `C0` and `B0` use `Set system identification`. Check the device type and the value before entering it.

#### System serial number and MTM (`C0`)

1. Open `Set system identification` and choose `2 - Read S/N data from EEPROM`. Record the current `C0`. Keep it if it matches the original machine information.
2. **Build `C0` as `1S` + `Type` + `SN`.** Join the three parts directly and keep any leading zeroes. `Type` is usually the full MTM. `SN` is the original system serial number. V1.11 checks for **20 characters** including `1S`. If the label also lists a Product ID, check your model's maintenance documentation for which value to use.

   This example uses made-up values. `20S0` is the four-character machine type, and `20S0002ABC` is the full `Type` value.

   | `Type` | `SN` | Full `C0` input |
   | --- | --- | --- |
   | `20S0002ABC` (10 characters) | `PF00TEST` (8 characters) | `1S20S0002ABCPF00TEST` (20 characters) |

3. If `C0` is empty, choose `1 - Add S/N data to EEPROM`. At `Enter the Device Type number`, enter `C0` and press Enter. At `Enter the Serial Number`, enter the complete string and press Enter.
4. If a record already exists, read it first. If it is wrong, record the old value and check the replacement before selecting `3 - Delete S/N data from EEPROM` and entering `C0`. Add the correct value, then read it back with `Read S/N data from EEPROM`.

#### System board barcode (`B0`)

1. In the same menu, choose `2 - Read S/N data from EEPROM` and compare the `B0` value with the label on the installed board. Keep the value if it matches.
2. If `B0` is empty, choose `1 - Add S/N data to EEPROM`. Enter `B0`, press Enter, and enter the complete serial barcode. For `8S` barcodes, V1.11 expects **21 characters after `8S`**, for a total of 23. If your label has a different length, check the model documentation and utility version. Use the serial barcode from the label. The FRU P/N identifies the part model.
3. To correct an existing barcode, record the old value and check the replacement first. Use `3 - Delete S/N data from EEPROM` to delete `B0`, then add the correct value. Read it back and check it against the label character by character.

### 5. Restore the product name

1. From the main menu, choose `Update Configuration Area`, then `2 - Brand name`, then `2 - Read brand name from EEPROM`. Record the current name and keep it if it is correct.
2. To add or correct it, choose `1 - Write brand name to EEPROM`. Both options below write to the same field. Pick the one you need.

   | Option | Example input |
   | --- | --- |
   | `1 - ThinkPad brand name` | Enter `X1 Carbon Gen 9`. The utility adds `ThinkPad `. |
   | `2 - Special brand name` | Enter the full name, such as `ThinkPad X1 Carbon Gen 9`. |

3. Press Enter and check the full name in the preview. Enter `Y` to confirm, then use `Read brand name from EEPROM` to check the result. Use the correct name for the model you're repairing.

### 6. Assign a system UUID

1. If the replacement board has no valid UUID, choose `Assign UUID`. V1.11 proceeds only when it reads 16 zero bytes. An existing value produces `Valid UUID has been already stored.` An all-`FF` value also produces this message. For a placeholder like this, check the model's repair procedure.
2. At `Change UUID. OK? [Y/N]`, enter `Y` and record the generated UUID. `Written data is unmatch` means the readback comparison failed, even if the utility goes on to display a UUID. After restarting, check the stored value as described below.

### 7. Verify after restarting

1. Exit the utility and remove the USB drive. At startup, press `F1` to enter the BIOS and check the MTM, system serial number, and UUID it displays. Then confirm the machine boots and the related startup error is gone.
2. Compare `B0` from the maintenance utility with the physical board label. Use `Read brand name from EEPROM` to check the product name and compare it with what the OS displays if useful.
3. In Windows, open PowerShell 7 in the folder containing [Get-ThinkPadIdentity.ps1](Get-ThinkPadIdentity.ps1) and run the command below. The script reads SMBIOS through CIM and shows the MTM, product name, system serial number, UUID, board product, and board serial number. Some models expose only part of this information. Check the board barcode using the maintenance utility and the board label.

   ```powershell
   pwsh -NoProfile -File .\Get-ThinkPadIdentity.ps1
   ```

### Troubleshooting

| Symptom | What to check |
| --- | --- |
| USB drive is missing from the boot menu | Check for `EFI\Boot\BootX64.efi` on the drive, confirm USB boot and UEFI are enabled, and check the model's instructions for starting the utility. |
| Secure Boot or signature error | Check which boot method and utility version the model's manual specifies. Restore any firmware settings you changed for the repair afterward. |
| Utility starts but says `Write Protected` or `Access is denied` | Check that the USB drive was made with the included formatter and that you used the model's maintenance entry point and tool version. If the message persists, record it and stop writing. |
| A record already exists or the length is wrong | Read existing records before changing them. For a length error, check the device type, prefix, MTM or Product ID, and the original barcode against the model documentation and prompt. |
| `The device type conflicts with ...` | Read the existing records. V1.11 treats `C0` and `20` as conflicting, as well as `B0` and `40`. Check the model documentation before changing them. |
| The BIOS still reports an invalid MTM, serial number, or UUID | Read the relevant value back and check it character by character. `Initialize EEPROM` clears machine identifiers and other settings, so use the field's own menu for a single-value repair. |

## 参考来源 / References

- [Lenovo ThinkPad Maintenance Utilities 支持入口](https://support.lenovo.com/us/en/downloads/ds102472)
- [Lenovo ThinkPad X1 Carbon Gen 9 官方手册下载页](https://pcsupport.lenovo.com/us/en/products/laptops-and-netbooks/thinkpad-x-series-laptops/thinkpad-x1-carbon-9th-gen-type-20xw-20xx/document-userguide)
- [Lenovo X1 Carbon Gen 9 和 X1 Yoga Gen 6 用户指南](https://download.lenovo.com/pccbbs/mobiles_pdf/x1_carbon_gen9_x1_yoga_gen6_ug_en.pdf)
- [Lenovo LSTC FAQ 中的 U1 制盘说明](https://seservice.lenovo.com/static_file/Istc_Depository/lstc_FAQ.htm)
- [Lenovo Golden Key U1 版本记录（3.1.6 条目）](https://seservice.lenovo.com/static_file/download2/gku1/U1_Readme.html)
- [Pragalbha-Patil 的 Lenovo U1 Tool 制盘说明](https://github.com/Pragalbha-Patil/lenovo-u1-tool/blob/master/README.md)
- [iuuniang 的 Lenovo U1 Tool 制盘及整机序列号填写示例](https://github.com/iuuniang/Lenovo-U1-Tool/blob/main/README.md)
- [迅维网 · ThinkPad 手动刷号 · 机型名称](https://www.chinafix.com/thread-1353755-1-1.html)
- [迅维网 · ThinkPad 手动刷号 · 主板条码](https://www.chinafix.com/thread-1353757-1-1.html)
- [迅维网 · ThinkPad 手动刷号 · 整机序列号](https://www.chinafix.com/thread-1353756-1-1.html)
- [迅维网 · ThinkPad 手动刷号 · UUID](https://www.chinafix.com/thread-1353754-1-1.html)
- [专门网 · UEFI 版 HMD ThinkPad Maintenance Utilities（Linux 写盘）](https://www.thinkpad.com.cn/thread-1999053-1-1.html)
- [Microsoft Learn · Win32_ComputerSystemProduct](https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-computersystemproduct) 与 [Win32_BaseBoard](https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-baseboard)
