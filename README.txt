This is translation toolkit for a PC game "Bible Black" (2000, English version by Kitty Media).
It consists of BBLACK.EXE IPS patch, PAK unpacker/packer and text scripts along with injection program.

About BBLACK.exe patches:
0x4E000: embedded font
0x0CF34: embedded font size in bytes
0x47B88: font weight ($0000, $6400, $C800, $2C01, $9001, $F401, $5802, $BC02, $2003 or $8403)
0x47B94: font name (monospaced)
0x47BCF: font encoding ($CC=Win-1251, $80=Shift-JIS)
0x3189A: font size 1 (default value is $12)
0x3189E: font size 2 (default value is $10)
0x318A2: font size 3 (default value is $0E)
0x318A6: font size 4 (default value is $16)

About ED8/SAL and EDT images editing:
Use 'Crass' (galcrass.blog124.fc2blog.us) or 'Susie' with 'Ifactive.spi' plugin to convert ED8/SAL and EDT images into BMP.
After modifying BMP convert it into uncompressed ED8 using my 'ed8conv.exe'.
You can replace EDT files with ED8. For example: delete E000.EDT and place E000.ED8 instead.
For smart color reduction and best image quality use OPTPiX iMageStudio.

//made by RikuKH3
(riku.kh3@gmail.com)
