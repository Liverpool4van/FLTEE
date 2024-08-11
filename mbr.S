;主引导程序
;------------------------------------------------------------------------------
SECTION MBR vstart=0x7c00
	mov ax,cs
	mov ds,ax
	mov ss,ax
	mov fs,ax
	mov es,ax
	mov sp,0x7c00
;将各种寄存器都初始化 bios通过jmp 0:0x7c00跳转mbr的 所以cs为0 
;将sp置到0x7c00时 因为栈向下暂时安全

;清屏 利用0x06功能
	mov ax,0x600 	;AH = 0x06 AL：上卷行数 为0则全部上卷
	mov bx,0x700 	;BH = 上卷行属性
	mov cx,0	 	;(CH,CL)左上角坐标
	mov dx,0x184f	;(DH,DL)右下角坐标
	int 0x10		;开启中断
;获取光标位置
	mov ah,3  		;3号子功能获取光标位置
	mov bh,0		;bh 存储的是待获取光标的页号
	int 0x10		;输出 ch＝光标开始行，cl＝光标结束行 
					;dh＝光标所在行号，dl＝光标所在列号
;打印字符串
	mov ax,message	;将字符串首地址放到ax里面
	mov bp,ax		;接下来调用的13号子功能需要es:bp es与cs一致 

	mov cx,5		;cx存储串长度
	mov ax,0x1301 	;子功能号13显示字符及属性，要存入ah寄存器， 
					;al设置写字符方式ah=01 ：显示字符串，光标跟随移动
	mov bx,0x2		;bh存储要显示的页号，此处是第0页
					;bl中是字符属性，属性黑底绿字(bl=02h)				
	int 0x10

	jmp $ 			;悬停


	message db "1,MBR"
	times 510-($-$$) db 0
	db 0x55,0xaa
