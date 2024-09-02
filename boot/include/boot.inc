LOADER_BASE_ADDR equ 0x900
LOADER_START_SECTION equ 0x2
;--------------------------gdt描述符属性----------------------------------------------------------------------------------
DESC_G_4K           equ 1_00000000000000000000000b  ;第23位G 表示4K或者1MB位 段界限的单位值 此时为1则为4k 
DESC_D_32           equ 1_0000000000000000000000b   ;第22位D/B 表示有效地址和操作数的大小 此时为1则为有效地址的位数位32位 
DESC_L              equ 0_000000000000000000000b    ;第21位L 表示64位代码标记 为0是32位代码段
DESC_AVL            equ 0_00000000000000000000b     ;第20位AVL软件专用 在此处没有专用用途 标记为0即可

DESC_LIMIT_CODE2    equ  1111_0000000000000000b     ;第16-19位 段界限的最后四位 全部初始化为1 
                                                    ;因为最大段界限为(0xfffff+1)=(0x100000)*粒度(0x1000)须等于0xffffffff
DESC_LIMIT_DATA2    equ  DESC_LIMIT_CODE2           ;数据段最后四位也初始化为1
DESC_LIMIT_VIDEO2   equ  0000_0000000000000000b     ;第16-19位 显存段初始化为全0

DESC_P              equ  1_00000000000000b          ;第15位  P present判断段是否存在于内存

DESC_DPL_0          equ  00_0000000000000b          ;第13到14位 表示特权级
DESC_DPL_1          equ  01_0000000000000b          
DESC_DPL_2          equ  10_0000000000000b  
DESC_DPL_3          equ  11_0000000000000b  

DESC_S_SYS          equ  0_000000000000b            ;第12位表示是系统段还是非系统段    
DESC_S_DATA         equ  1_000000000000b            
DESC_S_CODE         equ  DESC_S_DATA        

DESC_TYPE_CODE      equ  1000_00000000b             ;第9-11位表示该段状态 1000 可执行 不允许可读 已访问位0
;x=1 e=0 w=0 a=0
DESC_TYPE_DATA      equ  0010_00000000b             ;第9-11位type段   0010  可写  
;x=0 e=0 w=1 a=0


DESC_CODE_HIGH4     equ  (0x00<<24) + DESC_G_4K + DESC_D_32 + DESC_L + DESC_AVL + DESC_LIMIT_CODE2 + DESC_P + DESC_DPL_0 + DESC_S_CODE + DESC_TYPE_CODE + 0x00
;代码段描述符高位4字节初始化 (0x00共8位 <<24 共32位初始化0) 
;4KB为单位 Data段32位操作数 初始化的部分段界限 最高权限操作系统代码段 P存在表示 状态 
DESC_DATA_HIGH4     equ  (0x00<<24) + DESC_G_4K + DESC_D_32 + DESC_L + DESC_AVL + DESC_LIMIT_DATA2 + DESC_P + DESC_DPL_0 + DESC_S_DATA + DESC_TYPE_DATA + 0x00
;数据段
DESC_VIDEO_HIGH4    equ  (0x00<<24) + DESC_G_4K + DESC_D_32 + DESC_L + DESC_AVL + DESC_LIMIT_VIDEO2 + DESC_P + DESC_DPL_0 + DESC_S_DATA + DESC_TYPE_DATA + 0x0b
;显存段



;选择子属性 
RPL0                equ 00b                         ;rpl为请求特权级
RPL1                equ 01b        
RPL2                equ 10b
RPL3                equ 11b
TI_GDT              equ 000b                        ;TI_GDT用来指示选择子索引GDT还是LDT
TI_LDT              equ 100b




