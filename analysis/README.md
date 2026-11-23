# V1.11 反汇编 / V1.11 Disassembly

[中文](#zh) · [English](#english)

[下载完整列表 / Download the full listings](BootX64-v1.11-disassembly.zip)

<a name="zh"></a>

## 中文

解压后从 `layout.tsv` 看每个镜像在 `BootX64.efi` 里的位置、长度和入口 RVA。`BootX64.txt` 对应外层 EFI，8 个内嵌模块各有一份 `.txt`。

可执行区用 Capstone 5.0.7 按 x64 线性反汇编，其他区域列出原始字节。每行保留文件偏移、RVA 和字节，九份列表合起来覆盖 `BootX64.efi` 的 783,800 个字节。

## English

Start with `layout.tsv` for each image's offset in `BootX64.efi`, size, and entry RVA. `BootX64.txt` covers the outer EFI image, and each of the eight embedded images has its own listing.

Executable sections use a linear x64 disassembly from Capstone 5.0.7. The remaining ranges are listed as raw bytes. The file offset, RVA, and byte columns across all nine listings cover the 783,800 bytes of `BootX64.efi`.
