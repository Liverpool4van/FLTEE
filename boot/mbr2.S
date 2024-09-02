%include "boot.inc"
SECTION MBR vstart=0x7c00
    mov ax,cs
	mov ds,ax
	mov ss,ax
	mov fs,ax
	mov es,ax
	mov sp,0x7c00
    mov ax,0xb800
    mov gs,ax

    mov ax,0600h
    mov bx,0700h
    mov cx,0
    mov dx,184fh
    int 0x10
    ;输出背景为绿色，前景色为红色，且跳动的“1 MBR”
    mov byte [gs:0x00],'1'
    mov byte [gs:0x01],0xA4     ;A表示绿色背景闪烁,4表示前景色为红色
    mov byte [gs:0x02],' '
    mov byte [gs:0x03],0xA4
    mov byte [gs:0x04],'M'
    mov byte [gs:0x05],0xA4
    mov byte [gs:0x06],'B'
    mov byte [gs:0x07],0xA4
    mov byte [gs:0x08],'R'
    mov byte [gs:0x09],0xA4
 ;-------------------------------------------------------------------------------------------------------
    mov eax,LOADER_START_SECTION    ;eax里面存扇区lba地址
    mov bx,LOADER_BASE_ADDR         ;bx里面存写入的地址
    mov cx,4                        ;cx里面存待读入扇区数
    call rd_risk_m_16

    jmp LOADER_BASE_ADDR + 0x300
;读取硬盘n个扇区
rd_risk_m_16:
    mov esi,eax
    mov di,cx                       ;备份

;读写硬盘：
;第一步设置读取的扇区数
    mov dx,0x1F2
    mov al,cl
    out dx,al                       ;读取的扇区数
    mov eax,esi                     ;恢复eax

;第二步将lba地址存入0x1f3，0x1f4，0x1f5，0x1f6.
    mov cl,8

    mov dx,0x1F3
    out dx,al
   
    shr eax,cl
    mov dx,0x1F4
    out dx,al

    shr eax,cl
    mov dx,0x1F5
    out dx,al

    shr eax,cl
    and al,0x0f                     ;将lba地址完全送到lba low middle high 和device端口里面
    or al,0xe0                      ;将al高四位赋1110 第四位表示主从盘 hd60img是主盘
    mov dx,0x1f6                    ;第六位表示寻址方式 0为lba 1为chs 其余两位不关注
    out dx,al
;第三步向0x1f7写入读命令
    mov al,0x20
    mov dx,0x1f7
    out dx,al
;第四步检测硬盘的状态
.not_ready:
    nop                             ;类似于c的sleep 
    in al,dx                        ;同一端口，写时表示写入命令字，读时表示读入硬盘状态
    and al,0x88                     ;第四位表示是否准备好数据传输 1为是 第七位表示硬盘是否忙碌 1为是
    cmp al,0x08                     ;0x08表示硬盘不忙碌 且 准备好数据传输了 此时到传输数据
    jne .not_ready                  ;若不相等继续检测

;第五步开始传输数据 0x1f0
    mov dx,256                      ;这里为256是因为data端口为16位寄存器一次传输一个字，512字节需要传256次
    mov ax,di                       ;这里通过lba地址寻址 且通过0x1f2端口读取
    mul dx
    mov cx,ax
    mov dx,0x1f0
.go_on_read:
    in ax,dx
    mov [bx],ax
    add bx,2
    loop .go_on_read                ;读256返回
    ret

times 510-($ - $$) db 0
db 0x55,0xaa
