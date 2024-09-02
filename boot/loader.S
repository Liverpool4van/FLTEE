%include "boot.inc"
SECTION loader vstart=LOADER_BASE_ADDR
LOADER_STACK_TOP equ LOADER_BASE_ADDR
jmp loader_start
;构建GDT及其内部的描述符
    GDT_BASE:       dd 0x00000000                       ;低32位  刚开始的段选择子0不能使用 故用两个双字 来填充
                    dd 0x00000000                       ;高32位 

    CODE_DESC:      dd 0x0000FFFF
                    dd DESC_CODE_HIGH4

    STACK_DATA_DESC:
                    dd 0x0000FFFF
                    dd DESC_DATA_HIGH4

    VIDEO_DESC:     dd 0x80000007                       ;limit = (0xbffff-0xb8000) / 4K = 7 低16位表示段界限 高16位表示段基址
                    dd DESC_VIDEO_HIGH4                 ;此处段基址应为0xb8000
                     
    GDT_SIZE        equ $ - GDT_BASE      
    GDT_LIMIT       equ GDT_SIZE - 1

    times    60     dq 0                                ;预留60个四字空间 四字等于64位
    total_mem_bytes dd 0                                ;地址为0x900 + 0x200 = 0xb00

    SELECTOR_CODE   equ (0x0001 << 3) + TI_GDT + RPL0   ;这里是选择子
    SELECTOR_DATA   equ (0x0002 << 3) + TI_GDT + RPL0   ;三个部分组成 段描述符索引 + 是否为GDT + 请求优先级
    SELECTOR_VIDEO  equ (0x0003 << 3) + TI_GDT + RPL0

;gdt指针 2字gdt界限放在前面 4字gdt地址放在后面 lgdt 48位格式 低位16位界限 高位32位起始地址
    gdt_ptr         dw  GDT_LIMIT
                    dd  GDT_BASE
;人工对齐 loader_start地址为0xc00
    ards_buf        times 244 db 0
    ards_nr         dw 0  


;loadermsg       db  '2 loader in real!'
;用中断0x15 查询内存布局
    loader_start:
;int 15h eax = 0000e820h edx = 534d4150h("smap"的ASCII)
        xor ebx,ebx                         
        mov edx,0x534d4150                              ;校验字符串ASCII为0x534d4150
        mov  di,ards_buf                                ;地址为ards_buf
    .e820_mem_get_loop:
        mov eax,0xe820                                  ;执行0x15后 eax为0x534d4150需要更行子功能号 
        mov ecx,20                                      ;指定ARDS地址范围描述符的大小20位            
        int 0x15            
        jc .e820_failed_to_try_e810                     ;cf为1 证明有错误转去执行e810子功能
        add di,cx                                       ;
        inc word [ards_nr]                              ;记录ADRS的数量
        cmp ebx,0
        jnz .e820_mem_get_loop                          ;到最后一个就跳出
;在所有的结构中找到baseaddresslow + lengthaddresslow的最大值即为内存的最大值
        mov cx,[ards_nr]
;遍历每一个ARDS 找出最大值
        xor edx,edx
        mov ebx,ards_buf
;利用冒泡排序来寻找最大值
    .find_max_mem_area:
        mov eax,[ards_buf]                              ;这是baseaddresslow    
        add eax,[ards_buf+8]                            ;这是lengthaddresslow
        add ebx,20
        cmp edx,eax
        jge .next_ards
        mov edx,eax
    .next_ards:
        loop .find_max_mem_area
        jmp .mem_get_ok

;int 15h ax = 0xe810h 最大要求4g
;返回时ax cx相同单位为1kb bx和dx一样单位为64kb
;在ax和cx中为低16mb bx和dx为16到4G
    .e820_failed_to_try_e810:
        mov ax,0xe810
        int 0x15
        jc .e810_failed_to_try_88
;先算出低15mb的内存 ax,cx是以kb作为单位的 现在转换为byte
        mov cx,0x400                                    ;cx为1024
        mul cx                                          ;cx * ax 16位*16位 高16位dx 低16位ax
        shl edx,16                                      
        and eax,0x0000ffff
        or  edx,eax                                     ;组合edx和eax
        add edx,0x100000                                ;最大为15mb再加1mb
        mov esi,edx
;算16mb到4GB的内存 单位为64kb转换为byte
        xor eax,eax
        mov ax,bx
        mov ecx,0x10000
        mul ecx                                          ;32位乘法 高位edx 低位eax 4GB只用eax就行
        add esi,eax
        mov edx,esi
        jmp .mem_get_ok

;int 15h ah = 0x88h 最大要求64mb
    .e810_failed_to_try_88:
        xor ax,ax
        mov ah,0x88
        int 0x15
        jc  .error_hlt
        and eax,0x0000ffff
        mov cx,0x400
        mul cx
        shl edx,16                                      
        and eax,0x0000ffff
        or  edx,eax                                     
        add edx,0x100000                                
        mov esi,edx
        jmp .mem_get_ok


    .mem_get_ok:
        mov [total_mem_bytes],ebx
    .error_hlt:
        jmp $