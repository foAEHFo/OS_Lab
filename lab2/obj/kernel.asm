
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00006297          	auipc	t0,0x6
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0206000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00006297          	auipc	t0,0x6
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0206008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02052b7          	lui	t0,0xc0205
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d828293          	addi	t0,t0,216 # ffffffffc02000d8 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00001517          	auipc	a0,0x1
ffffffffc0200050:	70450513          	addi	a0,a0,1796 # ffffffffc0201750 <etext+0x6>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07e58593          	addi	a1,a1,126 # ffffffffc02000d8 <kern_init>
ffffffffc0200062:	00001517          	auipc	a0,0x1
ffffffffc0200066:	70e50513          	addi	a0,a0,1806 # ffffffffc0201770 <etext+0x26>
ffffffffc020006a:	0e2000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00001597          	auipc	a1,0x1
ffffffffc0200072:	6dc58593          	addi	a1,a1,1756 # ffffffffc020174a <etext>
ffffffffc0200076:	00001517          	auipc	a0,0x1
ffffffffc020007a:	71a50513          	addi	a0,a0,1818 # ffffffffc0201790 <etext+0x46>
ffffffffc020007e:	0ce000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00006597          	auipc	a1,0x6
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0206018 <buddy>
ffffffffc020008a:	00001517          	auipc	a0,0x1
ffffffffc020008e:	72650513          	addi	a0,a0,1830 # ffffffffc02017b0 <etext+0x66>
ffffffffc0200092:	0ba000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00006597          	auipc	a1,0x6
ffffffffc020009a:	0ca58593          	addi	a1,a1,202 # ffffffffc0206160 <end>
ffffffffc020009e:	00001517          	auipc	a0,0x1
ffffffffc02000a2:	73250513          	addi	a0,a0,1842 # ffffffffc02017d0 <etext+0x86>
ffffffffc02000a6:	0a6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00006597          	auipc	a1,0x6
ffffffffc02000ae:	4b558593          	addi	a1,a1,1205 # ffffffffc020655f <end+0x3ff>
ffffffffc02000b2:	00000797          	auipc	a5,0x0
ffffffffc02000b6:	02678793          	addi	a5,a5,38 # ffffffffc02000d8 <kern_init>
ffffffffc02000ba:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000be:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c8:	95be                	add	a1,a1,a5
ffffffffc02000ca:	85a9                	srai	a1,a1,0xa
ffffffffc02000cc:	00001517          	auipc	a0,0x1
ffffffffc02000d0:	72450513          	addi	a0,a0,1828 # ffffffffc02017f0 <etext+0xa6>
}
ffffffffc02000d4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d6:	a89d                	j	ffffffffc020014c <cprintf>

ffffffffc02000d8 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d8:	00006517          	auipc	a0,0x6
ffffffffc02000dc:	f4050513          	addi	a0,a0,-192 # ffffffffc0206018 <buddy>
ffffffffc02000e0:	00006617          	auipc	a2,0x6
ffffffffc02000e4:	08060613          	addi	a2,a2,128 # ffffffffc0206160 <end>
int kern_init(void) {
ffffffffc02000e8:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000ea:	8e09                	sub	a2,a2,a0
ffffffffc02000ec:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ee:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000f0:	648010ef          	jal	ra,ffffffffc0201738 <memset>
    dtb_init();
ffffffffc02000f4:	12c000ef          	jal	ra,ffffffffc0200220 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f8:	11e000ef          	jal	ra,ffffffffc0200216 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fc:	00001517          	auipc	a0,0x1
ffffffffc0200100:	72450513          	addi	a0,a0,1828 # ffffffffc0201820 <etext+0xd6>
ffffffffc0200104:	07e000ef          	jal	ra,ffffffffc0200182 <cputs>

    print_kerninfo();
ffffffffc0200108:	f43ff0ef          	jal	ra,ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010c:	7d3000ef          	jal	ra,ffffffffc02010de <pmm_init>

    /* do nothing */
    while (1)
ffffffffc0200110:	a001                	j	ffffffffc0200110 <kern_init+0x38>

ffffffffc0200112 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200112:	1141                	addi	sp,sp,-16
ffffffffc0200114:	e022                	sd	s0,0(sp)
ffffffffc0200116:	e406                	sd	ra,8(sp)
ffffffffc0200118:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020011a:	0fe000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    (*cnt) ++;
ffffffffc020011e:	401c                	lw	a5,0(s0)
}
ffffffffc0200120:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200122:	2785                	addiw	a5,a5,1
ffffffffc0200124:	c01c                	sw	a5,0(s0)
}
ffffffffc0200126:	6402                	ld	s0,0(sp)
ffffffffc0200128:	0141                	addi	sp,sp,16
ffffffffc020012a:	8082                	ret

ffffffffc020012c <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020012c:	1101                	addi	sp,sp,-32
ffffffffc020012e:	862a                	mv	a2,a0
ffffffffc0200130:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200132:	00000517          	auipc	a0,0x0
ffffffffc0200136:	fe050513          	addi	a0,a0,-32 # ffffffffc0200112 <cputch>
ffffffffc020013a:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc020013c:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020013e:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200140:	1e2010ef          	jal	ra,ffffffffc0201322 <vprintfmt>
    return cnt;
}
ffffffffc0200144:	60e2                	ld	ra,24(sp)
ffffffffc0200146:	4532                	lw	a0,12(sp)
ffffffffc0200148:	6105                	addi	sp,sp,32
ffffffffc020014a:	8082                	ret

ffffffffc020014c <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc020014c:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020014e:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200152:	8e2a                	mv	t3,a0
ffffffffc0200154:	f42e                	sd	a1,40(sp)
ffffffffc0200156:	f832                	sd	a2,48(sp)
ffffffffc0200158:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020015a:	00000517          	auipc	a0,0x0
ffffffffc020015e:	fb850513          	addi	a0,a0,-72 # ffffffffc0200112 <cputch>
ffffffffc0200162:	004c                	addi	a1,sp,4
ffffffffc0200164:	869a                	mv	a3,t1
ffffffffc0200166:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc0200168:	ec06                	sd	ra,24(sp)
ffffffffc020016a:	e0ba                	sd	a4,64(sp)
ffffffffc020016c:	e4be                	sd	a5,72(sp)
ffffffffc020016e:	e8c2                	sd	a6,80(sp)
ffffffffc0200170:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200172:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200174:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200176:	1ac010ef          	jal	ra,ffffffffc0201322 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020017a:	60e2                	ld	ra,24(sp)
ffffffffc020017c:	4512                	lw	a0,4(sp)
ffffffffc020017e:	6125                	addi	sp,sp,96
ffffffffc0200180:	8082                	ret

ffffffffc0200182 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200182:	1101                	addi	sp,sp,-32
ffffffffc0200184:	e822                	sd	s0,16(sp)
ffffffffc0200186:	ec06                	sd	ra,24(sp)
ffffffffc0200188:	e426                	sd	s1,8(sp)
ffffffffc020018a:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020018c:	00054503          	lbu	a0,0(a0)
ffffffffc0200190:	c51d                	beqz	a0,ffffffffc02001be <cputs+0x3c>
ffffffffc0200192:	0405                	addi	s0,s0,1
ffffffffc0200194:	4485                	li	s1,1
ffffffffc0200196:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200198:	080000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020019c:	00044503          	lbu	a0,0(s0)
ffffffffc02001a0:	008487bb          	addw	a5,s1,s0
ffffffffc02001a4:	0405                	addi	s0,s0,1
ffffffffc02001a6:	f96d                	bnez	a0,ffffffffc0200198 <cputs+0x16>
    (*cnt) ++;
ffffffffc02001a8:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001ac:	4529                	li	a0,10
ffffffffc02001ae:	06a000ef          	jal	ra,ffffffffc0200218 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001b2:	60e2                	ld	ra,24(sp)
ffffffffc02001b4:	8522                	mv	a0,s0
ffffffffc02001b6:	6442                	ld	s0,16(sp)
ffffffffc02001b8:	64a2                	ld	s1,8(sp)
ffffffffc02001ba:	6105                	addi	sp,sp,32
ffffffffc02001bc:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc02001be:	4405                	li	s0,1
ffffffffc02001c0:	b7f5                	j	ffffffffc02001ac <cputs+0x2a>

ffffffffc02001c2 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001c2:	00006317          	auipc	t1,0x6
ffffffffc02001c6:	f5630313          	addi	t1,t1,-170 # ffffffffc0206118 <is_panic>
ffffffffc02001ca:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001ce:	715d                	addi	sp,sp,-80
ffffffffc02001d0:	ec06                	sd	ra,24(sp)
ffffffffc02001d2:	e822                	sd	s0,16(sp)
ffffffffc02001d4:	f436                	sd	a3,40(sp)
ffffffffc02001d6:	f83a                	sd	a4,48(sp)
ffffffffc02001d8:	fc3e                	sd	a5,56(sp)
ffffffffc02001da:	e0c2                	sd	a6,64(sp)
ffffffffc02001dc:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001de:	000e0363          	beqz	t3,ffffffffc02001e4 <__panic+0x22>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001e2:	a001                	j	ffffffffc02001e2 <__panic+0x20>
    is_panic = 1;
ffffffffc02001e4:	4785                	li	a5,1
ffffffffc02001e6:	00f32023          	sw	a5,0(t1)
    va_start(ap, fmt);
ffffffffc02001ea:	8432                	mv	s0,a2
ffffffffc02001ec:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001ee:	862e                	mv	a2,a1
ffffffffc02001f0:	85aa                	mv	a1,a0
ffffffffc02001f2:	00001517          	auipc	a0,0x1
ffffffffc02001f6:	64e50513          	addi	a0,a0,1614 # ffffffffc0201840 <etext+0xf6>
    va_start(ap, fmt);
ffffffffc02001fa:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001fc:	f51ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200200:	65a2                	ld	a1,8(sp)
ffffffffc0200202:	8522                	mv	a0,s0
ffffffffc0200204:	f29ff0ef          	jal	ra,ffffffffc020012c <vcprintf>
    cprintf("\n");
ffffffffc0200208:	00002517          	auipc	a0,0x2
ffffffffc020020c:	c3850513          	addi	a0,a0,-968 # ffffffffc0201e40 <etext+0x6f6>
ffffffffc0200210:	f3dff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200214:	b7f9                	j	ffffffffc02001e2 <__panic+0x20>

ffffffffc0200216 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200216:	8082                	ret

ffffffffc0200218 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200218:	0ff57513          	zext.b	a0,a0
ffffffffc020021c:	4880106f          	j	ffffffffc02016a4 <sbi_console_putchar>

ffffffffc0200220 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200220:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200222:	00001517          	auipc	a0,0x1
ffffffffc0200226:	63e50513          	addi	a0,a0,1598 # ffffffffc0201860 <etext+0x116>
void dtb_init(void) {
ffffffffc020022a:	fc86                	sd	ra,120(sp)
ffffffffc020022c:	f8a2                	sd	s0,112(sp)
ffffffffc020022e:	e8d2                	sd	s4,80(sp)
ffffffffc0200230:	f4a6                	sd	s1,104(sp)
ffffffffc0200232:	f0ca                	sd	s2,96(sp)
ffffffffc0200234:	ecce                	sd	s3,88(sp)
ffffffffc0200236:	e4d6                	sd	s5,72(sp)
ffffffffc0200238:	e0da                	sd	s6,64(sp)
ffffffffc020023a:	fc5e                	sd	s7,56(sp)
ffffffffc020023c:	f862                	sd	s8,48(sp)
ffffffffc020023e:	f466                	sd	s9,40(sp)
ffffffffc0200240:	f06a                	sd	s10,32(sp)
ffffffffc0200242:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200244:	f09ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200248:	00006597          	auipc	a1,0x6
ffffffffc020024c:	db85b583          	ld	a1,-584(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc0200250:	00001517          	auipc	a0,0x1
ffffffffc0200254:	62050513          	addi	a0,a0,1568 # ffffffffc0201870 <etext+0x126>
ffffffffc0200258:	ef5ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020025c:	00006417          	auipc	s0,0x6
ffffffffc0200260:	dac40413          	addi	s0,s0,-596 # ffffffffc0206008 <boot_dtb>
ffffffffc0200264:	600c                	ld	a1,0(s0)
ffffffffc0200266:	00001517          	auipc	a0,0x1
ffffffffc020026a:	61a50513          	addi	a0,a0,1562 # ffffffffc0201880 <etext+0x136>
ffffffffc020026e:	edfff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200272:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200276:	00001517          	auipc	a0,0x1
ffffffffc020027a:	62250513          	addi	a0,a0,1570 # ffffffffc0201898 <etext+0x14e>
    if (boot_dtb == 0) {
ffffffffc020027e:	120a0463          	beqz	s4,ffffffffc02003a6 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200282:	57f5                	li	a5,-3
ffffffffc0200284:	07fa                	slli	a5,a5,0x1e
ffffffffc0200286:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc020028a:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020028c:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200290:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200292:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200296:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020029a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020029e:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a2:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a6:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a8:	8ec9                	or	a3,a3,a0
ffffffffc02002aa:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002ae:	1b7d                	addi	s6,s6,-1
ffffffffc02002b0:	0167f7b3          	and	a5,a5,s6
ffffffffc02002b4:	8dd5                	or	a1,a1,a3
ffffffffc02002b6:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02002b8:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002bc:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02002be:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed9d8d>
ffffffffc02002c2:	10f59163          	bne	a1,a5,ffffffffc02003c4 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002c6:	471c                	lw	a5,8(a4)
ffffffffc02002c8:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02002ca:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002cc:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02002d0:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02002d4:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d8:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002dc:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e0:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e4:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e8:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ec:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f0:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002f4:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f6:	01146433          	or	s0,s0,a7
ffffffffc02002fa:	0086969b          	slliw	a3,a3,0x8
ffffffffc02002fe:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200302:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200304:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200308:	8c49                	or	s0,s0,a0
ffffffffc020030a:	0166f6b3          	and	a3,a3,s6
ffffffffc020030e:	00ca6a33          	or	s4,s4,a2
ffffffffc0200312:	0167f7b3          	and	a5,a5,s6
ffffffffc0200316:	8c55                	or	s0,s0,a3
ffffffffc0200318:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020031c:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020031e:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200320:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200322:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200326:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200328:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020032a:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020032e:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200330:	00001917          	auipc	s2,0x1
ffffffffc0200334:	5b890913          	addi	s2,s2,1464 # ffffffffc02018e8 <etext+0x19e>
ffffffffc0200338:	49bd                	li	s3,15
        switch (token) {
ffffffffc020033a:	4d91                	li	s11,4
ffffffffc020033c:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020033e:	00001497          	auipc	s1,0x1
ffffffffc0200342:	5a248493          	addi	s1,s1,1442 # ffffffffc02018e0 <etext+0x196>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200346:	000a2703          	lw	a4,0(s4)
ffffffffc020034a:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020034e:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200352:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200356:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020035a:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020035e:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200362:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200364:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200368:	0087171b          	slliw	a4,a4,0x8
ffffffffc020036c:	8fd5                	or	a5,a5,a3
ffffffffc020036e:	00eb7733          	and	a4,s6,a4
ffffffffc0200372:	8fd9                	or	a5,a5,a4
ffffffffc0200374:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200376:	09778c63          	beq	a5,s7,ffffffffc020040e <dtb_init+0x1ee>
ffffffffc020037a:	00fbea63          	bltu	s7,a5,ffffffffc020038e <dtb_init+0x16e>
ffffffffc020037e:	07a78663          	beq	a5,s10,ffffffffc02003ea <dtb_init+0x1ca>
ffffffffc0200382:	4709                	li	a4,2
ffffffffc0200384:	00e79763          	bne	a5,a4,ffffffffc0200392 <dtb_init+0x172>
ffffffffc0200388:	4c81                	li	s9,0
ffffffffc020038a:	8a56                	mv	s4,s5
ffffffffc020038c:	bf6d                	j	ffffffffc0200346 <dtb_init+0x126>
ffffffffc020038e:	ffb78ee3          	beq	a5,s11,ffffffffc020038a <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200392:	00001517          	auipc	a0,0x1
ffffffffc0200396:	5ce50513          	addi	a0,a0,1486 # ffffffffc0201960 <etext+0x216>
ffffffffc020039a:	db3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020039e:	00001517          	auipc	a0,0x1
ffffffffc02003a2:	5fa50513          	addi	a0,a0,1530 # ffffffffc0201998 <etext+0x24e>
}
ffffffffc02003a6:	7446                	ld	s0,112(sp)
ffffffffc02003a8:	70e6                	ld	ra,120(sp)
ffffffffc02003aa:	74a6                	ld	s1,104(sp)
ffffffffc02003ac:	7906                	ld	s2,96(sp)
ffffffffc02003ae:	69e6                	ld	s3,88(sp)
ffffffffc02003b0:	6a46                	ld	s4,80(sp)
ffffffffc02003b2:	6aa6                	ld	s5,72(sp)
ffffffffc02003b4:	6b06                	ld	s6,64(sp)
ffffffffc02003b6:	7be2                	ld	s7,56(sp)
ffffffffc02003b8:	7c42                	ld	s8,48(sp)
ffffffffc02003ba:	7ca2                	ld	s9,40(sp)
ffffffffc02003bc:	7d02                	ld	s10,32(sp)
ffffffffc02003be:	6de2                	ld	s11,24(sp)
ffffffffc02003c0:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02003c2:	b369                	j	ffffffffc020014c <cprintf>
}
ffffffffc02003c4:	7446                	ld	s0,112(sp)
ffffffffc02003c6:	70e6                	ld	ra,120(sp)
ffffffffc02003c8:	74a6                	ld	s1,104(sp)
ffffffffc02003ca:	7906                	ld	s2,96(sp)
ffffffffc02003cc:	69e6                	ld	s3,88(sp)
ffffffffc02003ce:	6a46                	ld	s4,80(sp)
ffffffffc02003d0:	6aa6                	ld	s5,72(sp)
ffffffffc02003d2:	6b06                	ld	s6,64(sp)
ffffffffc02003d4:	7be2                	ld	s7,56(sp)
ffffffffc02003d6:	7c42                	ld	s8,48(sp)
ffffffffc02003d8:	7ca2                	ld	s9,40(sp)
ffffffffc02003da:	7d02                	ld	s10,32(sp)
ffffffffc02003dc:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003de:	00001517          	auipc	a0,0x1
ffffffffc02003e2:	4da50513          	addi	a0,a0,1242 # ffffffffc02018b8 <etext+0x16e>
}
ffffffffc02003e6:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003e8:	b395                	j	ffffffffc020014c <cprintf>
                int name_len = strlen(name);
ffffffffc02003ea:	8556                	mv	a0,s5
ffffffffc02003ec:	2d2010ef          	jal	ra,ffffffffc02016be <strlen>
ffffffffc02003f0:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003f2:	4619                	li	a2,6
ffffffffc02003f4:	85a6                	mv	a1,s1
ffffffffc02003f6:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02003f8:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003fa:	318010ef          	jal	ra,ffffffffc0201712 <strncmp>
ffffffffc02003fe:	e111                	bnez	a0,ffffffffc0200402 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200400:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200402:	0a91                	addi	s5,s5,4
ffffffffc0200404:	9ad2                	add	s5,s5,s4
ffffffffc0200406:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc020040a:	8a56                	mv	s4,s5
ffffffffc020040c:	bf2d                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc020040e:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200412:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200416:	0087d71b          	srliw	a4,a5,0x8
ffffffffc020041a:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020041e:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200422:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200426:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020042a:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020042e:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200432:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200436:	00eaeab3          	or	s5,s5,a4
ffffffffc020043a:	00fb77b3          	and	a5,s6,a5
ffffffffc020043e:	00faeab3          	or	s5,s5,a5
ffffffffc0200442:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200444:	000c9c63          	bnez	s9,ffffffffc020045c <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200448:	1a82                	slli	s5,s5,0x20
ffffffffc020044a:	00368793          	addi	a5,a3,3
ffffffffc020044e:	020ada93          	srli	s5,s5,0x20
ffffffffc0200452:	9abe                	add	s5,s5,a5
ffffffffc0200454:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200458:	8a56                	mv	s4,s5
ffffffffc020045a:	b5f5                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020045c:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200460:	85ca                	mv	a1,s2
ffffffffc0200462:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200464:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200468:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020046c:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200470:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200474:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200478:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020047a:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020047e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200482:	8d59                	or	a0,a0,a4
ffffffffc0200484:	00fb77b3          	and	a5,s6,a5
ffffffffc0200488:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc020048a:	1502                	slli	a0,a0,0x20
ffffffffc020048c:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020048e:	9522                	add	a0,a0,s0
ffffffffc0200490:	264010ef          	jal	ra,ffffffffc02016f4 <strcmp>
ffffffffc0200494:	66a2                	ld	a3,8(sp)
ffffffffc0200496:	f94d                	bnez	a0,ffffffffc0200448 <dtb_init+0x228>
ffffffffc0200498:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200448 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020049c:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02004a0:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02004a4:	00001517          	auipc	a0,0x1
ffffffffc02004a8:	44c50513          	addi	a0,a0,1100 # ffffffffc02018f0 <etext+0x1a6>
           fdt32_to_cpu(x >> 32);
ffffffffc02004ac:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b0:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02004b4:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004b8:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02004bc:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c0:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c4:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c8:	0187d693          	srli	a3,a5,0x18
ffffffffc02004cc:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02004d0:	0087579b          	srliw	a5,a4,0x8
ffffffffc02004d4:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d8:	0106561b          	srliw	a2,a2,0x10
ffffffffc02004dc:	010f6f33          	or	t5,t5,a6
ffffffffc02004e0:	0187529b          	srliw	t0,a4,0x18
ffffffffc02004e4:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e8:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ec:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f0:	0186f6b3          	and	a3,a3,s8
ffffffffc02004f4:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02004f8:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004fc:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200500:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200504:	8361                	srli	a4,a4,0x18
ffffffffc0200506:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020050a:	0105d59b          	srliw	a1,a1,0x10
ffffffffc020050e:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200512:	00cb7633          	and	a2,s6,a2
ffffffffc0200516:	0088181b          	slliw	a6,a6,0x8
ffffffffc020051a:	0085959b          	slliw	a1,a1,0x8
ffffffffc020051e:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200522:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200526:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052e:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200532:	011b78b3          	and	a7,s6,a7
ffffffffc0200536:	005eeeb3          	or	t4,t4,t0
ffffffffc020053a:	00c6e733          	or	a4,a3,a2
ffffffffc020053e:	006c6c33          	or	s8,s8,t1
ffffffffc0200542:	010b76b3          	and	a3,s6,a6
ffffffffc0200546:	00bb7b33          	and	s6,s6,a1
ffffffffc020054a:	01d7e7b3          	or	a5,a5,t4
ffffffffc020054e:	016c6b33          	or	s6,s8,s6
ffffffffc0200552:	01146433          	or	s0,s0,a7
ffffffffc0200556:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200558:	1702                	slli	a4,a4,0x20
ffffffffc020055a:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020055c:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020055e:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200560:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200562:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200566:	0167eb33          	or	s6,a5,s6
ffffffffc020056a:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020056c:	be1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200570:	85a2                	mv	a1,s0
ffffffffc0200572:	00001517          	auipc	a0,0x1
ffffffffc0200576:	39e50513          	addi	a0,a0,926 # ffffffffc0201910 <etext+0x1c6>
ffffffffc020057a:	bd3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020057e:	014b5613          	srli	a2,s6,0x14
ffffffffc0200582:	85da                	mv	a1,s6
ffffffffc0200584:	00001517          	auipc	a0,0x1
ffffffffc0200588:	3a450513          	addi	a0,a0,932 # ffffffffc0201928 <etext+0x1de>
ffffffffc020058c:	bc1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200590:	008b05b3          	add	a1,s6,s0
ffffffffc0200594:	15fd                	addi	a1,a1,-1
ffffffffc0200596:	00001517          	auipc	a0,0x1
ffffffffc020059a:	3b250513          	addi	a0,a0,946 # ffffffffc0201948 <etext+0x1fe>
ffffffffc020059e:	bafff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02005a2:	00001517          	auipc	a0,0x1
ffffffffc02005a6:	3f650513          	addi	a0,a0,1014 # ffffffffc0201998 <etext+0x24e>
        memory_base = mem_base;
ffffffffc02005aa:	00006797          	auipc	a5,0x6
ffffffffc02005ae:	b687bb23          	sd	s0,-1162(a5) # ffffffffc0206120 <memory_base>
        memory_size = mem_size;
ffffffffc02005b2:	00006797          	auipc	a5,0x6
ffffffffc02005b6:	b767bb23          	sd	s6,-1162(a5) # ffffffffc0206128 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02005ba:	b3f5                	j	ffffffffc02003a6 <dtb_init+0x186>

ffffffffc02005bc <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02005bc:	00006517          	auipc	a0,0x6
ffffffffc02005c0:	b6453503          	ld	a0,-1180(a0) # ffffffffc0206120 <memory_base>
ffffffffc02005c4:	8082                	ret

ffffffffc02005c6 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02005c6:	00006517          	auipc	a0,0x6
ffffffffc02005ca:	b6253503          	ld	a0,-1182(a0) # ffffffffc0206128 <memory_size>
ffffffffc02005ce:	8082                	ret

ffffffffc02005d0 <buddy_system_init>:
    return pa2page(buddy_pa);
}
static void // 初始化伙伴内存分配系统
buddy_system_init(void)
{
    for (int i = 0; i < MAX_ORDER + 1; i++)
ffffffffc02005d0:	00006797          	auipc	a5,0x6
ffffffffc02005d4:	a5078793          	addi	a5,a5,-1456 # ffffffffc0206020 <buddy+0x8>
ffffffffc02005d8:	00006717          	auipc	a4,0x6
ffffffffc02005dc:	b3870713          	addi	a4,a4,-1224 # ffffffffc0206110 <buddy+0xf8>
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc02005e0:	e79c                	sd	a5,8(a5)
ffffffffc02005e2:	e39c                	sd	a5,0(a5)
ffffffffc02005e4:	07c1                	addi	a5,a5,16
ffffffffc02005e6:	fee79de3          	bne	a5,a4,ffffffffc02005e0 <buddy_system_init+0x10>
    {
        list_init(&buddy.array[i]);
    }
    buddy.free = 0;
ffffffffc02005ea:	00006797          	auipc	a5,0x6
ffffffffc02005ee:	b207a323          	sw	zero,-1242(a5) # ffffffffc0206110 <buddy+0xf8>
    buddy.max = 0;
ffffffffc02005f2:	00006797          	auipc	a5,0x6
ffffffffc02005f6:	a207a323          	sw	zero,-1498(a5) # ffffffffc0206018 <buddy>
    // 调用list_init函数初始化每一个阶层的链表，并且把free和max值都设为0
}
ffffffffc02005fa:	8082                	ret

ffffffffc02005fc <buddy_system_nr_free_pages>:

static size_t
buddy_system_nr_free_pages(void)
{
    return buddy.free;
}
ffffffffc02005fc:	00006517          	auipc	a0,0x6
ffffffffc0200600:	b1456503          	lwu	a0,-1260(a0) # ffffffffc0206110 <buddy+0xf8>
ffffffffc0200604:	8082                	ret

ffffffffc0200606 <getBuddy>:
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200606:	00006697          	auipc	a3,0x6
ffffffffc020060a:	b326b683          	ld	a3,-1230(a3) # ffffffffc0206138 <pages>
ffffffffc020060e:	40d50733          	sub	a4,a0,a3
ffffffffc0200612:	00002797          	auipc	a5,0x2
ffffffffc0200616:	dd67b783          	ld	a5,-554(a5) # ffffffffc02023e8 <error_string+0x38>
ffffffffc020061a:	870d                	srai	a4,a4,0x3
ffffffffc020061c:	02f70733          	mul	a4,a4,a5
ffffffffc0200620:	00002517          	auipc	a0,0x2
ffffffffc0200624:	dd053503          	ld	a0,-560(a0) # ffffffffc02023f0 <nbase>
    size_t block_pages = 1 << order;
ffffffffc0200628:	4785                	li	a5,1
ffffffffc020062a:	00b795bb          	sllw	a1,a5,a1
    if (buddy_pa >= npage * PGSIZE) {
ffffffffc020062e:	00006797          	auipc	a5,0x6
ffffffffc0200632:	b027b783          	ld	a5,-1278(a5) # ffffffffc0206130 <npage>
ffffffffc0200636:	00c79613          	slli	a2,a5,0xc
ffffffffc020063a:	972a                	add	a4,a4,a0
    uintptr_t buddy_pa = base_pa ^ (block_pages * PGSIZE);
ffffffffc020063c:	8db9                	xor	a1,a1,a4
ffffffffc020063e:	05b2                	slli	a1,a1,0xc
    if (buddy_pa >= npage * PGSIZE) {
ffffffffc0200640:	00c5fc63          	bgeu	a1,a2,ffffffffc0200658 <getBuddy+0x52>
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0200644:	81b1                	srli	a1,a1,0xc
ffffffffc0200646:	00f5fb63          	bgeu	a1,a5,ffffffffc020065c <getBuddy+0x56>
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc020064a:	8d89                	sub	a1,a1,a0
ffffffffc020064c:	00259513          	slli	a0,a1,0x2
ffffffffc0200650:	952e                	add	a0,a0,a1
ffffffffc0200652:	050e                	slli	a0,a0,0x3
ffffffffc0200654:	9536                	add	a0,a0,a3
    return pa2page(buddy_pa);
ffffffffc0200656:	8082                	ret
        return NULL;
ffffffffc0200658:	4501                	li	a0,0
}
ffffffffc020065a:	8082                	ret
{
ffffffffc020065c:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc020065e:	00001617          	auipc	a2,0x1
ffffffffc0200662:	35260613          	addi	a2,a2,850 # ffffffffc02019b0 <etext+0x266>
ffffffffc0200666:	06a00593          	li	a1,106
ffffffffc020066a:	00001517          	auipc	a0,0x1
ffffffffc020066e:	36650513          	addi	a0,a0,870 # ffffffffc02019d0 <etext+0x286>
ffffffffc0200672:	e406                	sd	ra,8(sp)
ffffffffc0200674:	b4fff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200678 <show_buddy_array.constprop.0>:

static void
show_buddy_array(int left, int right)
ffffffffc0200678:	715d                	addi	sp,sp,-80
{
    cprintf("------------------ Buddy System Free Lists ------------------\n");
ffffffffc020067a:	00001517          	auipc	a0,0x1
ffffffffc020067e:	36650513          	addi	a0,a0,870 # ffffffffc02019e0 <etext+0x296>
show_buddy_array(int left, int right)
ffffffffc0200682:	fc26                	sd	s1,56(sp)
ffffffffc0200684:	f84a                	sd	s2,48(sp)
ffffffffc0200686:	f44e                	sd	s3,40(sp)
ffffffffc0200688:	f052                	sd	s4,32(sp)
ffffffffc020068a:	ec56                	sd	s5,24(sp)
ffffffffc020068c:	e85a                	sd	s6,16(sp)
ffffffffc020068e:	e45e                	sd	s7,8(sp)
ffffffffc0200690:	e062                	sd	s8,0(sp)
ffffffffc0200692:	e486                	sd	ra,72(sp)
ffffffffc0200694:	e0a2                	sd	s0,64(sp)
ffffffffc0200696:	00006497          	auipc	s1,0x6
ffffffffc020069a:	98a48493          	addi	s1,s1,-1654 # ffffffffc0206020 <buddy+0x8>
    cprintf("------------------ Buddy System Free Lists ------------------\n");
ffffffffc020069e:	aafff0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (int i = left; i <= right; i++)
ffffffffc02006a2:	4901                	li	s2,0
        {
            cprintf("Order %d: Empty\n", i);
        }
        else
        {
            cprintf("Order %d: ", i);
ffffffffc02006a4:	00001c17          	auipc	s8,0x1
ffffffffc02006a8:	394c0c13          	addi	s8,s8,916 # ffffffffc0201a38 <etext+0x2ee>
            list_entry_t *le = &buddy.array[i];
            while ((le = list_next(le)) != &buddy.array[i])
            {
                struct Page *page = le2page(le, page_link);
                cprintf("[%p, size=%d] ", page, 1 << page->property);
ffffffffc02006ac:	4a05                	li	s4,1
ffffffffc02006ae:	00001997          	auipc	s3,0x1
ffffffffc02006b2:	39a98993          	addi	s3,s3,922 # ffffffffc0201a48 <etext+0x2fe>
            }
            cprintf("\n");
ffffffffc02006b6:	00001b97          	auipc	s7,0x1
ffffffffc02006ba:	78ab8b93          	addi	s7,s7,1930 # ffffffffc0201e40 <etext+0x6f6>
            cprintf("Order %d: Empty\n", i);
ffffffffc02006be:	00001b17          	auipc	s6,0x1
ffffffffc02006c2:	362b0b13          	addi	s6,s6,866 # ffffffffc0201a20 <etext+0x2d6>
    for (int i = left; i <= right; i++)
ffffffffc02006c6:	4abd                	li	s5,15
ffffffffc02006c8:	a801                	j	ffffffffc02006d8 <show_buddy_array.constprop.0+0x60>
            cprintf("Order %d: Empty\n", i);
ffffffffc02006ca:	855a                	mv	a0,s6
    for (int i = left; i <= right; i++)
ffffffffc02006cc:	2905                	addiw	s2,s2,1
            cprintf("Order %d: Empty\n", i);
ffffffffc02006ce:	a7fff0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (int i = left; i <= right; i++)
ffffffffc02006d2:	04c1                	addi	s1,s1,16
ffffffffc02006d4:	03590f63          	beq	s2,s5,ffffffffc0200712 <show_buddy_array.constprop.0+0x9a>
        if (list_empty(&buddy.array[i]))
ffffffffc02006d8:	649c                	ld	a5,8(s1)
            cprintf("Order %d: Empty\n", i);
ffffffffc02006da:	85ca                	mv	a1,s2
        if (list_empty(&buddy.array[i]))
ffffffffc02006dc:	fe9787e3          	beq	a5,s1,ffffffffc02006ca <show_buddy_array.constprop.0+0x52>
            cprintf("Order %d: ", i);
ffffffffc02006e0:	8562                	mv	a0,s8
ffffffffc02006e2:	a6bff0ef          	jal	ra,ffffffffc020014c <cprintf>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc02006e6:	6480                	ld	s0,8(s1)
            while ((le = list_next(le)) != &buddy.array[i])
ffffffffc02006e8:	00940e63          	beq	s0,s1,ffffffffc0200704 <show_buddy_array.constprop.0+0x8c>
                cprintf("[%p, size=%d] ", page, 1 << page->property);
ffffffffc02006ec:	ff842603          	lw	a2,-8(s0)
ffffffffc02006f0:	fe840593          	addi	a1,s0,-24
ffffffffc02006f4:	854e                	mv	a0,s3
ffffffffc02006f6:	00ca163b          	sllw	a2,s4,a2
ffffffffc02006fa:	a53ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc02006fe:	6400                	ld	s0,8(s0)
            while ((le = list_next(le)) != &buddy.array[i])
ffffffffc0200700:	fe9416e3          	bne	s0,s1,ffffffffc02006ec <show_buddy_array.constprop.0+0x74>
            cprintf("\n");
ffffffffc0200704:	855e                	mv	a0,s7
    for (int i = left; i <= right; i++)
ffffffffc0200706:	2905                	addiw	s2,s2,1
            cprintf("\n");
ffffffffc0200708:	a45ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (int i = left; i <= right; i++)
ffffffffc020070c:	04c1                	addi	s1,s1,16
ffffffffc020070e:	fd5915e3          	bne	s2,s5,ffffffffc02006d8 <show_buddy_array.constprop.0+0x60>
        }
    }
    cprintf("Total free pages: %d\n", buddy.free);
ffffffffc0200712:	00006597          	auipc	a1,0x6
ffffffffc0200716:	9fe5a583          	lw	a1,-1538(a1) # ffffffffc0206110 <buddy+0xf8>
ffffffffc020071a:	00001517          	auipc	a0,0x1
ffffffffc020071e:	33e50513          	addi	a0,a0,830 # ffffffffc0201a58 <etext+0x30e>
ffffffffc0200722:	a2bff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("-------------------------------------------------------------\n");
}
ffffffffc0200726:	6406                	ld	s0,64(sp)
ffffffffc0200728:	60a6                	ld	ra,72(sp)
ffffffffc020072a:	74e2                	ld	s1,56(sp)
ffffffffc020072c:	7942                	ld	s2,48(sp)
ffffffffc020072e:	79a2                	ld	s3,40(sp)
ffffffffc0200730:	7a02                	ld	s4,32(sp)
ffffffffc0200732:	6ae2                	ld	s5,24(sp)
ffffffffc0200734:	6b42                	ld	s6,16(sp)
ffffffffc0200736:	6ba2                	ld	s7,8(sp)
ffffffffc0200738:	6c02                	ld	s8,0(sp)
    cprintf("-------------------------------------------------------------\n");
ffffffffc020073a:	00001517          	auipc	a0,0x1
ffffffffc020073e:	33650513          	addi	a0,a0,822 # ffffffffc0201a70 <etext+0x326>
}
ffffffffc0200742:	6161                	addi	sp,sp,80
    cprintf("-------------------------------------------------------------\n");
ffffffffc0200744:	b421                	j	ffffffffc020014c <cprintf>

ffffffffc0200746 <buddy_system_init_memmap>:
{
ffffffffc0200746:	1141                	addi	sp,sp,-16
ffffffffc0200748:	e406                	sd	ra,8(sp)
    assert(base != NULL && n > 0);
ffffffffc020074a:	cd5d                	beqz	a0,ffffffffc0200808 <buddy_system_init_memmap+0xc2>
ffffffffc020074c:	cdd5                	beqz	a1,ffffffffc0200808 <buddy_system_init_memmap+0xc2>
    return (n & (n - 1)) == 0;
ffffffffc020074e:	fff58793          	addi	a5,a1,-1
ffffffffc0200752:	8fed                	and	a5,a5,a1
ffffffffc0200754:	882e                	mv	a6,a1
    if (isPowerOfTwo(n))
ffffffffc0200756:	cb91                	beqz	a5,ffffffffc020076a <buddy_system_init_memmap+0x24>
    int i = 1;
ffffffffc0200758:	4785                	li	a5,1
ffffffffc020075a:	a029                	j	ffffffffc0200764 <buddy_system_init_memmap+0x1e>
        if (2 * i > n)
ffffffffc020075c:	0017979b          	slliw	a5,a5,0x1
ffffffffc0200760:	00f5e563          	bltu	a1,a5,ffffffffc020076a <buddy_system_init_memmap+0x24>
    while (i < n)
ffffffffc0200764:	883e                	mv	a6,a5
ffffffffc0200766:	feb7ebe3          	bltu	a5,a1,ffffffffc020075c <buddy_system_init_memmap+0x16>
    while (n >> 1)
ffffffffc020076a:	00185793          	srli	a5,a6,0x1
    unsigned int count = 0;
ffffffffc020076e:	4601                	li	a2,0
    while (n >> 1)
ffffffffc0200770:	c781                	beqz	a5,ffffffffc0200778 <buddy_system_init_memmap+0x32>
ffffffffc0200772:	8385                	srli	a5,a5,0x1
        count++;
ffffffffc0200774:	2605                	addiw	a2,a2,1
    while (n >> 1)
ffffffffc0200776:	fff5                	bnez	a5,ffffffffc0200772 <buddy_system_init_memmap+0x2c>
    for (struct Page *p = base; p != base + pageNumber; p++)
ffffffffc0200778:	00281693          	slli	a3,a6,0x2
ffffffffc020077c:	96c2                	add	a3,a3,a6
ffffffffc020077e:	068e                	slli	a3,a3,0x3
ffffffffc0200780:	96aa                	add	a3,a3,a0
ffffffffc0200782:	02d50063          	beq	a0,a3,ffffffffc02007a2 <buddy_system_init_memmap+0x5c>
ffffffffc0200786:	87aa                	mv	a5,a0
        p->property = -1;
ffffffffc0200788:	55fd                	li	a1,-1
        assert(PageReserved(p));
ffffffffc020078a:	6798                	ld	a4,8(a5)
ffffffffc020078c:	8b05                	andi	a4,a4,1
ffffffffc020078e:	cf29                	beqz	a4,ffffffffc02007e8 <buddy_system_init_memmap+0xa2>
        p->flags = 0;
ffffffffc0200790:	0007b423          	sd	zero,8(a5)
        p->property = -1;
ffffffffc0200794:	cb8c                	sw	a1,16(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200796:	0007a023          	sw	zero,0(a5)
    for (struct Page *p = base; p != base + pageNumber; p++)
ffffffffc020079a:	02878793          	addi	a5,a5,40
ffffffffc020079e:	fed796e3          	bne	a5,a3,ffffffffc020078a <buddy_system_init_memmap+0x44>
    __list_add(elm, listelm, listelm->next);
ffffffffc02007a2:	02061693          	slli	a3,a2,0x20
ffffffffc02007a6:	00006717          	auipc	a4,0x6
ffffffffc02007aa:	87270713          	addi	a4,a4,-1934 # ffffffffc0206018 <buddy>
ffffffffc02007ae:	01c6d793          	srli	a5,a3,0x1c
ffffffffc02007b2:	00f708b3          	add	a7,a4,a5
ffffffffc02007b6:	0108b583          	ld	a1,16(a7)
    list_add(&buddy.array[order], &(base->page_link));
ffffffffc02007ba:	01850313          	addi	t1,a0,24
    SetPageProperty(base); // 设置对应的属性
ffffffffc02007be:	6514                	ld	a3,8(a0)
    list_add(&buddy.array[order], &(base->page_link));
ffffffffc02007c0:	07a1                	addi	a5,a5,8
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02007c2:	0065b023          	sd	t1,0(a1)
ffffffffc02007c6:	0068b823          	sd	t1,16(a7)
ffffffffc02007ca:	97ba                	add	a5,a5,a4
    elm->next = next;
    elm->prev = prev;
ffffffffc02007cc:	ed1c                	sd	a5,24(a0)
}
ffffffffc02007ce:	60a2                	ld	ra,8(sp)
    buddy.free = pageNumber;
ffffffffc02007d0:	2801                	sext.w	a6,a6
    elm->next = next;
ffffffffc02007d2:	f10c                	sd	a1,32(a0)
ffffffffc02007d4:	0f072c23          	sw	a6,248(a4)
    SetPageProperty(base); // 设置对应的属性
ffffffffc02007d8:	0026e793          	ori	a5,a3,2
    buddy.max = pageNumber;
ffffffffc02007dc:	01072023          	sw	a6,0(a4)
    base->property = order;
ffffffffc02007e0:	c910                	sw	a2,16(a0)
    SetPageProperty(base); // 设置对应的属性
ffffffffc02007e2:	e51c                	sd	a5,8(a0)
}
ffffffffc02007e4:	0141                	addi	sp,sp,16
ffffffffc02007e6:	8082                	ret
        assert(PageReserved(p));
ffffffffc02007e8:	00001697          	auipc	a3,0x1
ffffffffc02007ec:	31868693          	addi	a3,a3,792 # ffffffffc0201b00 <etext+0x3b6>
ffffffffc02007f0:	00001617          	auipc	a2,0x1
ffffffffc02007f4:	2d860613          	addi	a2,a2,728 # ffffffffc0201ac8 <etext+0x37e>
ffffffffc02007f8:	06d00593          	li	a1,109
ffffffffc02007fc:	00001517          	auipc	a0,0x1
ffffffffc0200800:	2e450513          	addi	a0,a0,740 # ffffffffc0201ae0 <etext+0x396>
ffffffffc0200804:	9bfff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(base != NULL && n > 0);
ffffffffc0200808:	00001697          	auipc	a3,0x1
ffffffffc020080c:	2a868693          	addi	a3,a3,680 # ffffffffc0201ab0 <etext+0x366>
ffffffffc0200810:	00001617          	auipc	a2,0x1
ffffffffc0200814:	2b860613          	addi	a2,a2,696 # ffffffffc0201ac8 <etext+0x37e>
ffffffffc0200818:	06400593          	li	a1,100
ffffffffc020081c:	00001517          	auipc	a0,0x1
ffffffffc0200820:	2c450513          	addi	a0,a0,708 # ffffffffc0201ae0 <etext+0x396>
ffffffffc0200824:	99fff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200828 <buddy_system_free_pages>:
{
ffffffffc0200828:	7139                	addi	sp,sp,-64
ffffffffc020082a:	fc06                	sd	ra,56(sp)
ffffffffc020082c:	f822                	sd	s0,48(sp)
ffffffffc020082e:	f426                	sd	s1,40(sp)
ffffffffc0200830:	f04a                	sd	s2,32(sp)
ffffffffc0200832:	ec4e                	sd	s3,24(sp)
ffffffffc0200834:	e852                	sd	s4,16(sp)
ffffffffc0200836:	e456                	sd	s5,8(sp)
ffffffffc0200838:	e05a                	sd	s6,0(sp)
    assert(base != NULL && n > 0);
ffffffffc020083a:	0e050e63          	beqz	a0,ffffffffc0200936 <buddy_system_free_pages+0x10e>
ffffffffc020083e:	892e                	mv	s2,a1
ffffffffc0200840:	c9fd                	beqz	a1,ffffffffc0200936 <buddy_system_free_pages+0x10e>
    list_add(&(buddy.array[base->property]), &(base->page_link));
ffffffffc0200842:	4904                	lw	s1,16(a0)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200844:	00005b17          	auipc	s6,0x5
ffffffffc0200848:	7d4b0b13          	addi	s6,s6,2004 # ffffffffc0206018 <buddy>
    SetPageProperty(base);
ffffffffc020084c:	00853983          	ld	s3,8(a0)
ffffffffc0200850:	02049713          	slli	a4,s1,0x20
ffffffffc0200854:	01c75793          	srli	a5,a4,0x1c
ffffffffc0200858:	00fb06b3          	add	a3,s6,a5
ffffffffc020085c:	6a98                	ld	a4,16(a3)
    list_add(&(buddy.array[base->property]), &(base->page_link));
ffffffffc020085e:	01850a93          	addi	s5,a0,24
ffffffffc0200862:	07a1                	addi	a5,a5,8
    prev->next = next->prev = elm;
ffffffffc0200864:	01573023          	sd	s5,0(a4)
ffffffffc0200868:	0156b823          	sd	s5,16(a3)
ffffffffc020086c:	97da                	add	a5,a5,s6
    SetPageProperty(base);
ffffffffc020086e:	0029e993          	ori	s3,s3,2
    elm->prev = prev;
ffffffffc0200872:	ed1c                	sd	a5,24(a0)
    elm->next = next;
ffffffffc0200874:	f118                	sd	a4,32(a0)
ffffffffc0200876:	01353423          	sd	s3,8(a0)
    struct Page *buddy_block2 = getBuddy(base,base->property);
ffffffffc020087a:	85a6                	mv	a1,s1
ffffffffc020087c:	842a                	mv	s0,a0
ffffffffc020087e:	d89ff0ef          	jal	ra,ffffffffc0200606 <getBuddy>
    while(PageProperty(buddy_block2) && buddy_block1->property < buddy.max){
ffffffffc0200882:	651c                	ld	a5,8(a0)
ffffffffc0200884:	8b89                	andi	a5,a5,2
ffffffffc0200886:	c7a5                	beqz	a5,ffffffffc02008ee <buddy_system_free_pages+0xc6>
ffffffffc0200888:	000b2983          	lw	s3,0(s6)
            buddy_block2->property = -1;
ffffffffc020088c:	5a7d                	li	s4,-1
    while(PageProperty(buddy_block2) && buddy_block1->property < buddy.max){
ffffffffc020088e:	0534fc63          	bgeu	s1,s3,ffffffffc02008e6 <buddy_system_free_pages+0xbe>
        if(buddy_block1 > buddy_block2){
ffffffffc0200892:	00857a63          	bgeu	a0,s0,ffffffffc02008a6 <buddy_system_free_pages+0x7e>
            buddy_block2->property = -1;
ffffffffc0200896:	01442823          	sw	s4,16(s0)
        buddy_block1->property++;
ffffffffc020089a:	87a2                	mv	a5,s0
ffffffffc020089c:	4904                	lw	s1,16(a0)
ffffffffc020089e:	842a                	mv	s0,a0
ffffffffc02008a0:	01850a93          	addi	s5,a0,24
ffffffffc02008a4:	853e                	mv	a0,a5
    __list_del(listelm->prev, listelm->next);
ffffffffc02008a6:	6d14                	ld	a3,24(a0)
ffffffffc02008a8:	7118                	ld	a4,32(a0)
ffffffffc02008aa:	2485                	addiw	s1,s1,1
    __list_add(elm, listelm, listelm->next);
ffffffffc02008ac:	02049613          	slli	a2,s1,0x20
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02008b0:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc02008b2:	e314                	sd	a3,0(a4)
    __list_add(elm, listelm, listelm->next);
ffffffffc02008b4:	01c65793          	srli	a5,a2,0x1c
    __list_del(listelm->prev, listelm->next);
ffffffffc02008b8:	7018                	ld	a4,32(s0)
ffffffffc02008ba:	6c10                	ld	a2,24(s0)
    __list_add(elm, listelm, listelm->next);
ffffffffc02008bc:	00fb06b3          	add	a3,s6,a5
        list_add(&(buddy.array[buddy_block1->property]), &(buddy_block1->page_link));
ffffffffc02008c0:	07a1                	addi	a5,a5,8
    prev->next = next;
ffffffffc02008c2:	e618                	sd	a4,8(a2)
    next->prev = prev;
ffffffffc02008c4:	e310                	sd	a2,0(a4)
    __list_add(elm, listelm, listelm->next);
ffffffffc02008c6:	6a98                	ld	a4,16(a3)
        buddy_block1->property++;
ffffffffc02008c8:	c804                	sw	s1,16(s0)
        list_add(&(buddy.array[buddy_block1->property]), &(buddy_block1->page_link));
ffffffffc02008ca:	97da                	add	a5,a5,s6
    prev->next = next->prev = elm;
ffffffffc02008cc:	01573023          	sd	s5,0(a4)
ffffffffc02008d0:	0156b823          	sd	s5,16(a3)
    elm->prev = prev;
ffffffffc02008d4:	ec1c                	sd	a5,24(s0)
    elm->next = next;
ffffffffc02008d6:	f018                	sd	a4,32(s0)
        buddy_block2 = getBuddy(buddy_block1,buddy_block1->property);
ffffffffc02008d8:	85a6                	mv	a1,s1
ffffffffc02008da:	8522                	mv	a0,s0
ffffffffc02008dc:	d2bff0ef          	jal	ra,ffffffffc0200606 <getBuddy>
    while(PageProperty(buddy_block2) && buddy_block1->property < buddy.max){
ffffffffc02008e0:	651c                	ld	a5,8(a0)
ffffffffc02008e2:	8b89                	andi	a5,a5,2
ffffffffc02008e4:	f7cd                	bnez	a5,ffffffffc020088e <buddy_system_free_pages+0x66>
    SetPageProperty(buddy_block1);
ffffffffc02008e6:	00843983          	ld	s3,8(s0)
ffffffffc02008ea:	0029e993          	ori	s3,s3,2
    return (n & (n - 1)) == 0;
ffffffffc02008ee:	fff90793          	addi	a5,s2,-1
    SetPageProperty(buddy_block1);
ffffffffc02008f2:	01343423          	sd	s3,8(s0)
    return (n & (n - 1)) == 0;
ffffffffc02008f6:	0127f7b3          	and	a5,a5,s2
    if (isPowerOfTwo(n))
ffffffffc02008fa:	cf91                	beqz	a5,ffffffffc0200916 <buddy_system_free_pages+0xee>
    int i = 1;
ffffffffc02008fc:	4785                	li	a5,1
ffffffffc02008fe:	a029                	j	ffffffffc0200908 <buddy_system_free_pages+0xe0>
        if (2 * i > n)
ffffffffc0200900:	0017979b          	slliw	a5,a5,0x1
ffffffffc0200904:	00f96763          	bltu	s2,a5,ffffffffc0200912 <buddy_system_free_pages+0xea>
    while (i < n)
ffffffffc0200908:	873e                	mv	a4,a5
ffffffffc020090a:	ff27ebe3          	bltu	a5,s2,ffffffffc0200900 <buddy_system_free_pages+0xd8>
    if (pageNumber != n)
ffffffffc020090e:	00f90463          	beq	s2,a5,ffffffffc0200916 <buddy_system_free_pages+0xee>
        pageNumber *= 2;
ffffffffc0200912:	00171913          	slli	s2,a4,0x1
    buddy.free += pageNumber;
ffffffffc0200916:	0f8b2583          	lw	a1,248(s6)
}
ffffffffc020091a:	70e2                	ld	ra,56(sp)
ffffffffc020091c:	7442                	ld	s0,48(sp)
    buddy.free += pageNumber;
ffffffffc020091e:	0125893b          	addw	s2,a1,s2
ffffffffc0200922:	0f2b2c23          	sw	s2,248(s6)
}
ffffffffc0200926:	74a2                	ld	s1,40(sp)
ffffffffc0200928:	7902                	ld	s2,32(sp)
ffffffffc020092a:	69e2                	ld	s3,24(sp)
ffffffffc020092c:	6a42                	ld	s4,16(sp)
ffffffffc020092e:	6aa2                	ld	s5,8(sp)
ffffffffc0200930:	6b02                	ld	s6,0(sp)
ffffffffc0200932:	6121                	addi	sp,sp,64
ffffffffc0200934:	8082                	ret
    assert(base != NULL && n > 0);
ffffffffc0200936:	00001697          	auipc	a3,0x1
ffffffffc020093a:	17a68693          	addi	a3,a3,378 # ffffffffc0201ab0 <etext+0x366>
ffffffffc020093e:	00001617          	auipc	a2,0x1
ffffffffc0200942:	18a60613          	addi	a2,a2,394 # ffffffffc0201ac8 <etext+0x37e>
ffffffffc0200946:	0d500593          	li	a1,213
ffffffffc020094a:	00001517          	auipc	a0,0x1
ffffffffc020094e:	19650513          	addi	a0,a0,406 # ffffffffc0201ae0 <etext+0x396>
ffffffffc0200952:	871ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200956 <buddy_system_alloc_pages>:
    assert(n > 0);
ffffffffc0200956:	12050363          	beqz	a0,ffffffffc0200a7c <buddy_system_alloc_pages+0x126>
    if (n > buddy.free)
ffffffffc020095a:	00005317          	auipc	t1,0x5
ffffffffc020095e:	6be30313          	addi	t1,t1,1726 # ffffffffc0206018 <buddy>
ffffffffc0200962:	0f832e03          	lw	t3,248(t1)
ffffffffc0200966:	88aa                	mv	a7,a0
        return NULL;
ffffffffc0200968:	4501                	li	a0,0
    if (n > buddy.free)
ffffffffc020096a:	020e1793          	slli	a5,t3,0x20
ffffffffc020096e:	9381                	srli	a5,a5,0x20
ffffffffc0200970:	0f17ed63          	bltu	a5,a7,ffffffffc0200a6a <buddy_system_alloc_pages+0x114>
    return (n & (n - 1)) == 0;
ffffffffc0200974:	fff88793          	addi	a5,a7,-1
ffffffffc0200978:	0117f7b3          	and	a5,a5,a7
    if (isPowerOfTwo(n))
ffffffffc020097c:	cbe5                	beqz	a5,ffffffffc0200a6c <buddy_system_alloc_pages+0x116>
    int i = 1;
ffffffffc020097e:	4785                	li	a5,1
ffffffffc0200980:	a029                	j	ffffffffc020098a <buddy_system_alloc_pages+0x34>
        if (2 * i > n)
ffffffffc0200982:	0017979b          	slliw	a5,a5,0x1
ffffffffc0200986:	00f8e763          	bltu	a7,a5,ffffffffc0200994 <buddy_system_alloc_pages+0x3e>
    while (i < n)
ffffffffc020098a:	873e                	mv	a4,a5
ffffffffc020098c:	ff17ebe3          	bltu	a5,a7,ffffffffc0200982 <buddy_system_alloc_pages+0x2c>
    if (pageNumber != n)
ffffffffc0200990:	0cf88e63          	beq	a7,a5,ffffffffc0200a6c <buddy_system_alloc_pages+0x116>
        pageNumber *= 2;
ffffffffc0200994:	00171893          	slli	a7,a4,0x1
    while (n >> 1)
ffffffffc0200998:	0018d793          	srli	a5,a7,0x1
ffffffffc020099c:	4801                	li	a6,0
ffffffffc020099e:	8385                	srli	a5,a5,0x1
        count++;
ffffffffc02009a0:	2805                	addiw	a6,a6,1
    while (n >> 1)
ffffffffc02009a2:	fff5                	bnez	a5,ffffffffc020099e <buddy_system_alloc_pages+0x48>
ffffffffc02009a4:	02081793          	slli	a5,a6,0x20
ffffffffc02009a8:	9381                	srli	a5,a5,0x20
ffffffffc02009aa:	00479f13          	slli	t5,a5,0x4
ffffffffc02009ae:	0f21                	addi	t5,t5,8
    return list->next == list;
ffffffffc02009b0:	0792                	slli	a5,a5,0x4
ffffffffc02009b2:	00f30eb3          	add	t4,t1,a5
ffffffffc02009b6:	2805                	addiw	a6,a6,1
ffffffffc02009b8:	010eb783          	ld	a5,16(t4)
ffffffffc02009bc:	00481513          	slli	a0,a6,0x4
ffffffffc02009c0:	0521                	addi	a0,a0,8
        if (!list_empty(&buddy.array[order]))
ffffffffc02009c2:	9f1a                	add	t5,t5,t1
            for (int i = order + 1; i <= buddy.max; i++)
ffffffffc02009c4:	00032583          	lw	a1,0(t1)
ffffffffc02009c8:	951a                	add	a0,a0,t1
        if (!list_empty(&buddy.array[order]))
ffffffffc02009ca:	08ff1063          	bne	t5,a5,ffffffffc0200a4a <buddy_system_alloc_pages+0xf4>
            for (int i = order + 1; i <= buddy.max; i++)
ffffffffc02009ce:	0105e063          	bltu	a1,a6,ffffffffc02009ce <buddy_system_alloc_pages+0x78>
ffffffffc02009d2:	87aa                	mv	a5,a0
ffffffffc02009d4:	8742                	mv	a4,a6
ffffffffc02009d6:	8646                	mv	a2,a7
ffffffffc02009d8:	a031                	j	ffffffffc02009e4 <buddy_system_alloc_pages+0x8e>
ffffffffc02009da:	2705                	addiw	a4,a4,1
                tmp *= 2;
ffffffffc02009dc:	0606                	slli	a2,a2,0x1
            for (int i = order + 1; i <= buddy.max; i++)
ffffffffc02009de:	07c1                	addi	a5,a5,16
ffffffffc02009e0:	fee5e7e3          	bltu	a1,a4,ffffffffc02009ce <buddy_system_alloc_pages+0x78>
ffffffffc02009e4:	6794                	ld	a3,8(a5)
                if (!list_empty(&buddy.array[i]))
ffffffffc02009e6:	fef68ae3          	beq	a3,a5,ffffffffc02009da <buddy_system_alloc_pages+0x84>
                    struct Page *right = left + tmp;
ffffffffc02009ea:	00261793          	slli	a5,a2,0x2
ffffffffc02009ee:	97b2                	add	a5,a5,a2
ffffffffc02009f0:	078e                	slli	a5,a5,0x3
                    SetPageProperty(left);
ffffffffc02009f2:	ff06b603          	ld	a2,-16(a3)
                    left->property = i - 1;
ffffffffc02009f6:	377d                	addiw	a4,a4,-1
                    struct Page *right = left + tmp;
ffffffffc02009f8:	17a1                	addi	a5,a5,-24
                    left->property = i - 1;
ffffffffc02009fa:	fee6ac23          	sw	a4,-8(a3)
                    struct Page *right = left + tmp;
ffffffffc02009fe:	97b6                	add	a5,a5,a3
                    right->property = i - 1;
ffffffffc0200a00:	cb98                	sw	a4,16(a5)
                    SetPageProperty(left);
ffffffffc0200a02:	00266613          	ori	a2,a2,2
ffffffffc0200a06:	fec6b823          	sd	a2,-16(a3)
                    SetPageProperty(right);
ffffffffc0200a0a:	6790                	ld	a2,8(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200a0c:	0086bf83          	ld	t6,8(a3)
ffffffffc0200a10:	0006b283          	ld	t0,0(a3)
ffffffffc0200a14:	00266613          	ori	a2,a2,2
ffffffffc0200a18:	e790                	sd	a2,8(a5)
    prev->next = next;
ffffffffc0200a1a:	01f2b423          	sd	t6,8(t0)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200a1e:	0712                	slli	a4,a4,0x4
    next->prev = prev;
ffffffffc0200a20:	005fb023          	sd	t0,0(t6)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200a24:	00e30fb3          	add	t6,t1,a4
ffffffffc0200a28:	010fb603          	ld	a2,16(t6)
                    list_add(&(buddy.array[i - 1]), &(left->page_link));
ffffffffc0200a2c:	0721                	addi	a4,a4,8
    prev->next = next->prev = elm;
ffffffffc0200a2e:	00dfb823          	sd	a3,16(t6)
ffffffffc0200a32:	971a                	add	a4,a4,t1
    elm->prev = prev;
ffffffffc0200a34:	e298                	sd	a4,0(a3)
                    list_add(&(left->page_link), &(right->page_link));
ffffffffc0200a36:	01878713          	addi	a4,a5,24
    prev->next = next->prev = elm;
ffffffffc0200a3a:	e218                	sd	a4,0(a2)
ffffffffc0200a3c:	e698                	sd	a4,8(a3)
    elm->next = next;
ffffffffc0200a3e:	f390                	sd	a2,32(a5)
    elm->prev = prev;
ffffffffc0200a40:	ef94                	sd	a3,24(a5)
    return list->next == list;
ffffffffc0200a42:	010eb783          	ld	a5,16(t4)
        if (!list_empty(&buddy.array[order]))
ffffffffc0200a46:	f8ff04e3          	beq	t5,a5,ffffffffc02009ce <buddy_system_alloc_pages+0x78>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200a4a:	6390                	ld	a2,0(a5)
ffffffffc0200a4c:	6794                	ld	a3,8(a5)
            ClearPageProperty(ret);
ffffffffc0200a4e:	ff07b703          	ld	a4,-16(a5)
        buddy.free -= pageNumber;
ffffffffc0200a52:	411e08bb          	subw	a7,t3,a7
    prev->next = next;
ffffffffc0200a56:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0200a58:	e290                	sd	a2,0(a3)
            ClearPageProperty(ret);
ffffffffc0200a5a:	9b75                	andi	a4,a4,-3
ffffffffc0200a5c:	fee7b823          	sd	a4,-16(a5)
            ret = le2page(list_next(&buddy.array[order]), page_link);
ffffffffc0200a60:	fe878513          	addi	a0,a5,-24
        buddy.free -= pageNumber;
ffffffffc0200a64:	0f132c23          	sw	a7,248(t1)
    return ret;
ffffffffc0200a68:	8082                	ret
}
ffffffffc0200a6a:	8082                	ret
    while (n >> 1)
ffffffffc0200a6c:	0018d793          	srli	a5,a7,0x1
ffffffffc0200a70:	f795                	bnez	a5,ffffffffc020099c <buddy_system_alloc_pages+0x46>
ffffffffc0200a72:	4f21                	li	t5,8
ffffffffc0200a74:	4885                	li	a7,1
    unsigned int count = 0;
ffffffffc0200a76:	4801                	li	a6,0
ffffffffc0200a78:	4781                	li	a5,0
ffffffffc0200a7a:	bf1d                	j	ffffffffc02009b0 <buddy_system_alloc_pages+0x5a>
{
ffffffffc0200a7c:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200a7e:	00001697          	auipc	a3,0x1
ffffffffc0200a82:	04268693          	addi	a3,a3,66 # ffffffffc0201ac0 <etext+0x376>
ffffffffc0200a86:	00001617          	auipc	a2,0x1
ffffffffc0200a8a:	04260613          	addi	a2,a2,66 # ffffffffc0201ac8 <etext+0x37e>
ffffffffc0200a8e:	08400593          	li	a1,132
ffffffffc0200a92:	00001517          	auipc	a0,0x1
ffffffffc0200a96:	04e50513          	addi	a0,a0,78 # ffffffffc0201ae0 <etext+0x396>
{
ffffffffc0200a9a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200a9c:	f26ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200aa0 <buddy_system_check>:
}

// 主测试函数
static void
buddy_system_check(void)
{
ffffffffc0200aa0:	715d                	addi	sp,sp,-80
    cprintf("============================================\n");
ffffffffc0200aa2:	00001517          	auipc	a0,0x1
ffffffffc0200aa6:	06e50513          	addi	a0,a0,110 # ffffffffc0201b10 <etext+0x3c6>
{
ffffffffc0200aaa:	e486                	sd	ra,72(sp)
ffffffffc0200aac:	e0a2                	sd	s0,64(sp)
ffffffffc0200aae:	fc26                	sd	s1,56(sp)
ffffffffc0200ab0:	f84a                	sd	s2,48(sp)
ffffffffc0200ab2:	f44e                	sd	s3,40(sp)
ffffffffc0200ab4:	f052                	sd	s4,32(sp)
ffffffffc0200ab6:	ec56                	sd	s5,24(sp)
ffffffffc0200ab8:	e85a                	sd	s6,16(sp)
ffffffffc0200aba:	e45e                	sd	s7,8(sp)
    cprintf("============================================\n");
ffffffffc0200abc:	e90ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Starting Buddy System Tests\n");
ffffffffc0200ac0:	00001517          	auipc	a0,0x1
ffffffffc0200ac4:	08050513          	addi	a0,a0,128 # ffffffffc0201b40 <etext+0x3f6>
ffffffffc0200ac8:	e84ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("============================================\n");
ffffffffc0200acc:	00001517          	auipc	a0,0x1
ffffffffc0200ad0:	04450513          	addi	a0,a0,68 # ffffffffc0201b10 <etext+0x3c6>
ffffffffc0200ad4:	e78ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("=== Basic Allocation and Free Test ===\n");
ffffffffc0200ad8:	00001517          	auipc	a0,0x1
ffffffffc0200adc:	08850513          	addi	a0,a0,136 # ffffffffc0201b60 <etext+0x416>
ffffffffc0200ae0:	e6cff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Initial free pages: %d\n", buddy.free);
ffffffffc0200ae4:	00005417          	auipc	s0,0x5
ffffffffc0200ae8:	53440413          	addi	s0,s0,1332 # ffffffffc0206018 <buddy>
ffffffffc0200aec:	0f842583          	lw	a1,248(s0)
ffffffffc0200af0:	00001517          	auipc	a0,0x1
ffffffffc0200af4:	09850513          	addi	a0,a0,152 # ffffffffc0201b88 <etext+0x43e>
ffffffffc0200af8:	e54ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Allocating 10 pages for p0...\n");
ffffffffc0200afc:	00001517          	auipc	a0,0x1
ffffffffc0200b00:	0a450513          	addi	a0,a0,164 # ffffffffc0201ba0 <etext+0x456>
ffffffffc0200b04:	e48ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    p0 = buddy_system_alloc_pages(10);
ffffffffc0200b08:	4529                	li	a0,10
ffffffffc0200b0a:	e4dff0ef          	jal	ra,ffffffffc0200956 <buddy_system_alloc_pages>
    assert(p0 != NULL);
ffffffffc0200b0e:	50050863          	beqz	a0,ffffffffc020101e <buddy_system_check+0x57e>
ffffffffc0200b12:	89aa                	mv	s3,a0
    show_buddy_array(0, MAX_ORDER);
ffffffffc0200b14:	b65ff0ef          	jal	ra,ffffffffc0200678 <show_buddy_array.constprop.0>
    cprintf("Allocating 10 pages for p1...\n");
ffffffffc0200b18:	00001517          	auipc	a0,0x1
ffffffffc0200b1c:	0b850513          	addi	a0,a0,184 # ffffffffc0201bd0 <etext+0x486>
ffffffffc0200b20:	e2cff0ef          	jal	ra,ffffffffc020014c <cprintf>
    p1 = buddy_system_alloc_pages(10);
ffffffffc0200b24:	4529                	li	a0,10
ffffffffc0200b26:	e31ff0ef          	jal	ra,ffffffffc0200956 <buddy_system_alloc_pages>
ffffffffc0200b2a:	8b2a                	mv	s6,a0
    assert(p1 != NULL);
ffffffffc0200b2c:	4c050963          	beqz	a0,ffffffffc0200ffe <buddy_system_check+0x55e>
    show_buddy_array(0, MAX_ORDER);
ffffffffc0200b30:	b49ff0ef          	jal	ra,ffffffffc0200678 <show_buddy_array.constprop.0>
    cprintf("Allocating 10 pages for p2...\n");
ffffffffc0200b34:	00001517          	auipc	a0,0x1
ffffffffc0200b38:	0cc50513          	addi	a0,a0,204 # ffffffffc0201c00 <etext+0x4b6>
ffffffffc0200b3c:	e10ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    p2 = buddy_system_alloc_pages(10);
ffffffffc0200b40:	4529                	li	a0,10
ffffffffc0200b42:	e15ff0ef          	jal	ra,ffffffffc0200956 <buddy_system_alloc_pages>
ffffffffc0200b46:	8baa                	mv	s7,a0
    assert(p2 != NULL);
ffffffffc0200b48:	52050b63          	beqz	a0,ffffffffc020107e <buddy_system_check+0x5de>
    show_buddy_array(0, MAX_ORDER);
ffffffffc0200b4c:	b2dff0ef          	jal	ra,ffffffffc0200678 <show_buddy_array.constprop.0>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200b50:	3b698763          	beq	s3,s6,ffffffffc0200efe <buddy_system_check+0x45e>
ffffffffc0200b54:	3b798563          	beq	s3,s7,ffffffffc0200efe <buddy_system_check+0x45e>
ffffffffc0200b58:	3b7b0363          	beq	s6,s7,ffffffffc0200efe <buddy_system_check+0x45e>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200b5c:	0009a783          	lw	a5,0(s3)
ffffffffc0200b60:	36079f63          	bnez	a5,ffffffffc0200ede <buddy_system_check+0x43e>
ffffffffc0200b64:	000b2783          	lw	a5,0(s6)
ffffffffc0200b68:	36079b63          	bnez	a5,ffffffffc0200ede <buddy_system_check+0x43e>
ffffffffc0200b6c:	000ba783          	lw	a5,0(s7)
ffffffffc0200b70:	36079763          	bnez	a5,ffffffffc0200ede <buddy_system_check+0x43e>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200b74:	00005a97          	auipc	s5,0x5
ffffffffc0200b78:	5c4a8a93          	addi	s5,s5,1476 # ffffffffc0206138 <pages>
ffffffffc0200b7c:	000ab783          	ld	a5,0(s5)
ffffffffc0200b80:	00002917          	auipc	s2,0x2
ffffffffc0200b84:	86893903          	ld	s2,-1944(s2) # ffffffffc02023e8 <error_string+0x38>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200b88:	00005a17          	auipc	s4,0x5
ffffffffc0200b8c:	5a8a0a13          	addi	s4,s4,1448 # ffffffffc0206130 <npage>
ffffffffc0200b90:	40f98733          	sub	a4,s3,a5
ffffffffc0200b94:	870d                	srai	a4,a4,0x3
ffffffffc0200b96:	03270733          	mul	a4,a4,s2
ffffffffc0200b9a:	000a3683          	ld	a3,0(s4)
ffffffffc0200b9e:	00002497          	auipc	s1,0x2
ffffffffc0200ba2:	8524b483          	ld	s1,-1966(s1) # ffffffffc02023f0 <nbase>
ffffffffc0200ba6:	06b2                	slli	a3,a3,0xc
ffffffffc0200ba8:	9726                	add	a4,a4,s1
    return page2ppn(page) << PGSHIFT;
ffffffffc0200baa:	0732                	slli	a4,a4,0xc
ffffffffc0200bac:	3ed77963          	bgeu	a4,a3,ffffffffc0200f9e <buddy_system_check+0x4fe>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200bb0:	40fb0733          	sub	a4,s6,a5
ffffffffc0200bb4:	870d                	srai	a4,a4,0x3
ffffffffc0200bb6:	03270733          	mul	a4,a4,s2
ffffffffc0200bba:	9726                	add	a4,a4,s1
    return page2ppn(page) << PGSHIFT;
ffffffffc0200bbc:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200bbe:	42d77063          	bgeu	a4,a3,ffffffffc0200fde <buddy_system_check+0x53e>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200bc2:	40fb87b3          	sub	a5,s7,a5
ffffffffc0200bc6:	878d                	srai	a5,a5,0x3
ffffffffc0200bc8:	032787b3          	mul	a5,a5,s2
ffffffffc0200bcc:	97a6                	add	a5,a5,s1
    return page2ppn(page) << PGSHIFT;
ffffffffc0200bce:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200bd0:	3ed7f763          	bgeu	a5,a3,ffffffffc0200fbe <buddy_system_check+0x51e>
    cprintf("p0 address: 0x%016lx\n", p0);
ffffffffc0200bd4:	85ce                	mv	a1,s3
ffffffffc0200bd6:	00001517          	auipc	a0,0x1
ffffffffc0200bda:	12250513          	addi	a0,a0,290 # ffffffffc0201cf8 <etext+0x5ae>
ffffffffc0200bde:	d6eff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("p1 address: 0x%016lx\n", p1);
ffffffffc0200be2:	85da                	mv	a1,s6
ffffffffc0200be4:	00001517          	auipc	a0,0x1
ffffffffc0200be8:	12c50513          	addi	a0,a0,300 # ffffffffc0201d10 <etext+0x5c6>
ffffffffc0200bec:	d60ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("p2 address: 0x%016lx\n", p2);
ffffffffc0200bf0:	85de                	mv	a1,s7
ffffffffc0200bf2:	00001517          	auipc	a0,0x1
ffffffffc0200bf6:	13650513          	addi	a0,a0,310 # ffffffffc0201d28 <etext+0x5de>
ffffffffc0200bfa:	d52ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Freeing p0...\n");
ffffffffc0200bfe:	00001517          	auipc	a0,0x1
ffffffffc0200c02:	14250513          	addi	a0,a0,322 # ffffffffc0201d40 <etext+0x5f6>
ffffffffc0200c06:	d46ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    buddy_system_free_pages(p0, 10);
ffffffffc0200c0a:	45a9                	li	a1,10
ffffffffc0200c0c:	854e                	mv	a0,s3
ffffffffc0200c0e:	c1bff0ef          	jal	ra,ffffffffc0200828 <buddy_system_free_pages>
    show_buddy_array(0, MAX_ORDER);
ffffffffc0200c12:	a67ff0ef          	jal	ra,ffffffffc0200678 <show_buddy_array.constprop.0>
    cprintf("Freeing p1...\n");
ffffffffc0200c16:	00001517          	auipc	a0,0x1
ffffffffc0200c1a:	13a50513          	addi	a0,a0,314 # ffffffffc0201d50 <etext+0x606>
ffffffffc0200c1e:	d2eff0ef          	jal	ra,ffffffffc020014c <cprintf>
    buddy_system_free_pages(p1, 10);
ffffffffc0200c22:	45a9                	li	a1,10
ffffffffc0200c24:	855a                	mv	a0,s6
ffffffffc0200c26:	c03ff0ef          	jal	ra,ffffffffc0200828 <buddy_system_free_pages>
    show_buddy_array(0, MAX_ORDER);
ffffffffc0200c2a:	a4fff0ef          	jal	ra,ffffffffc0200678 <show_buddy_array.constprop.0>
    cprintf("Freeing p2...\n");
ffffffffc0200c2e:	00001517          	auipc	a0,0x1
ffffffffc0200c32:	13250513          	addi	a0,a0,306 # ffffffffc0201d60 <etext+0x616>
ffffffffc0200c36:	d16ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    buddy_system_free_pages(p2, 10);
ffffffffc0200c3a:	45a9                	li	a1,10
ffffffffc0200c3c:	855e                	mv	a0,s7
ffffffffc0200c3e:	bebff0ef          	jal	ra,ffffffffc0200828 <buddy_system_free_pages>
    show_buddy_array(0, MAX_ORDER);
ffffffffc0200c42:	a37ff0ef          	jal	ra,ffffffffc0200678 <show_buddy_array.constprop.0>
    cprintf("Basic test completed successfully!\n\n");
ffffffffc0200c46:	00001517          	auipc	a0,0x1
ffffffffc0200c4a:	12a50513          	addi	a0,a0,298 # ffffffffc0201d70 <etext+0x626>
ffffffffc0200c4e:	cfeff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("=== Minimum Allocation Test (1 page) ===\n");
ffffffffc0200c52:	00001517          	auipc	a0,0x1
ffffffffc0200c56:	14650513          	addi	a0,a0,326 # ffffffffc0201d98 <etext+0x64e>
ffffffffc0200c5a:	cf2ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Initial free pages: %d\n", buddy.free);
ffffffffc0200c5e:	0f842583          	lw	a1,248(s0)
ffffffffc0200c62:	00001517          	auipc	a0,0x1
ffffffffc0200c66:	f2650513          	addi	a0,a0,-218 # ffffffffc0201b88 <etext+0x43e>
ffffffffc0200c6a:	ce2ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    struct Page *p = buddy_system_alloc_pages(1);
ffffffffc0200c6e:	4505                	li	a0,1
ffffffffc0200c70:	ce7ff0ef          	jal	ra,ffffffffc0200956 <buddy_system_alloc_pages>
ffffffffc0200c74:	89aa                	mv	s3,a0
    assert(p != NULL);
ffffffffc0200c76:	30050463          	beqz	a0,ffffffffc0200f7e <buddy_system_check+0x4de>
    cprintf("Allocated 1 page at address: 0x%016lx\n", p);
ffffffffc0200c7a:	85aa                	mv	a1,a0
ffffffffc0200c7c:	00001517          	auipc	a0,0x1
ffffffffc0200c80:	15c50513          	addi	a0,a0,348 # ffffffffc0201dd8 <etext+0x68e>
ffffffffc0200c84:	cc8ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    show_buddy_array(0, MAX_ORDER);
ffffffffc0200c88:	9f1ff0ef          	jal	ra,ffffffffc0200678 <show_buddy_array.constprop.0>
    buddy_system_free_pages(p, 1);
ffffffffc0200c8c:	4585                	li	a1,1
ffffffffc0200c8e:	854e                	mv	a0,s3
ffffffffc0200c90:	b99ff0ef          	jal	ra,ffffffffc0200828 <buddy_system_free_pages>
    cprintf("Freed 1 page\n");
ffffffffc0200c94:	00001517          	auipc	a0,0x1
ffffffffc0200c98:	16c50513          	addi	a0,a0,364 # ffffffffc0201e00 <etext+0x6b6>
ffffffffc0200c9c:	cb0ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    show_buddy_array(0, MAX_ORDER);
ffffffffc0200ca0:	9d9ff0ef          	jal	ra,ffffffffc0200678 <show_buddy_array.constprop.0>
    cprintf("Minimum allocation test completed successfully!\n\n");
ffffffffc0200ca4:	00001517          	auipc	a0,0x1
ffffffffc0200ca8:	16c50513          	addi	a0,a0,364 # ffffffffc0201e10 <etext+0x6c6>
ffffffffc0200cac:	ca0ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("=== Maximum Allocation Test (16384 pages) ===\n");
ffffffffc0200cb0:	00001517          	auipc	a0,0x1
ffffffffc0200cb4:	19850513          	addi	a0,a0,408 # ffffffffc0201e48 <etext+0x6fe>
ffffffffc0200cb8:	c94ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Initial free pages: %d\n", buddy.free);
ffffffffc0200cbc:	0f842583          	lw	a1,248(s0)
ffffffffc0200cc0:	00001517          	auipc	a0,0x1
ffffffffc0200cc4:	ec850513          	addi	a0,a0,-312 # ffffffffc0201b88 <etext+0x43e>
ffffffffc0200cc8:	c84ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    struct Page *p = buddy_system_alloc_pages(16384);
ffffffffc0200ccc:	6511                	lui	a0,0x4
ffffffffc0200cce:	c89ff0ef          	jal	ra,ffffffffc0200956 <buddy_system_alloc_pages>
ffffffffc0200cd2:	89aa                	mv	s3,a0
    if (p == NULL) {
ffffffffc0200cd4:	1c050e63          	beqz	a0,ffffffffc0200eb0 <buddy_system_check+0x410>
    cprintf("Allocated 16384 pages at address: 0x%016lx\n", p);
ffffffffc0200cd8:	85aa                	mv	a1,a0
ffffffffc0200cda:	00001517          	auipc	a0,0x1
ffffffffc0200cde:	1de50513          	addi	a0,a0,478 # ffffffffc0201eb8 <etext+0x76e>
ffffffffc0200ce2:	c6aff0ef          	jal	ra,ffffffffc020014c <cprintf>
    show_buddy_array(0, MAX_ORDER);
ffffffffc0200ce6:	993ff0ef          	jal	ra,ffffffffc0200678 <show_buddy_array.constprop.0>
    buddy_system_free_pages(p, 16384);
ffffffffc0200cea:	6591                	lui	a1,0x4
ffffffffc0200cec:	854e                	mv	a0,s3
ffffffffc0200cee:	b3bff0ef          	jal	ra,ffffffffc0200828 <buddy_system_free_pages>
    cprintf("Freed 16384 pages\n");
ffffffffc0200cf2:	00001517          	auipc	a0,0x1
ffffffffc0200cf6:	1f650513          	addi	a0,a0,502 # ffffffffc0201ee8 <etext+0x79e>
ffffffffc0200cfa:	c52ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    show_buddy_array(0, MAX_ORDER);
ffffffffc0200cfe:	97bff0ef          	jal	ra,ffffffffc0200678 <show_buddy_array.constprop.0>
    cprintf("Maximum allocation test completed successfully!\n\n");
ffffffffc0200d02:	00001517          	auipc	a0,0x1
ffffffffc0200d06:	1fe50513          	addi	a0,a0,510 # ffffffffc0201f00 <etext+0x7b6>
ffffffffc0200d0a:	c42ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("=== Difficult Allocation Test ===\n");
ffffffffc0200d0e:	00001517          	auipc	a0,0x1
ffffffffc0200d12:	22a50513          	addi	a0,a0,554 # ffffffffc0201f38 <etext+0x7ee>
ffffffffc0200d16:	c36ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Initial free pages: %d\n", buddy.free);
ffffffffc0200d1a:	0f842583          	lw	a1,248(s0)
ffffffffc0200d1e:	00001517          	auipc	a0,0x1
ffffffffc0200d22:	e6a50513          	addi	a0,a0,-406 # ffffffffc0201b88 <etext+0x43e>
ffffffffc0200d26:	c26ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Allocating 10 pages for p0...\n");
ffffffffc0200d2a:	00001517          	auipc	a0,0x1
ffffffffc0200d2e:	e7650513          	addi	a0,a0,-394 # ffffffffc0201ba0 <etext+0x456>
ffffffffc0200d32:	c1aff0ef          	jal	ra,ffffffffc020014c <cprintf>
    p0 = buddy_system_alloc_pages(10);
ffffffffc0200d36:	4529                	li	a0,10
ffffffffc0200d38:	c1fff0ef          	jal	ra,ffffffffc0200956 <buddy_system_alloc_pages>
ffffffffc0200d3c:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200d3e:	32050063          	beqz	a0,ffffffffc020105e <buddy_system_check+0x5be>
    show_buddy_array(0, MAX_ORDER);
ffffffffc0200d42:	937ff0ef          	jal	ra,ffffffffc0200678 <show_buddy_array.constprop.0>
    cprintf("Allocating 50 pages for p1...\n");
ffffffffc0200d46:	00001517          	auipc	a0,0x1
ffffffffc0200d4a:	21a50513          	addi	a0,a0,538 # ffffffffc0201f60 <etext+0x816>
ffffffffc0200d4e:	bfeff0ef          	jal	ra,ffffffffc020014c <cprintf>
    p1 = buddy_system_alloc_pages(50);
ffffffffc0200d52:	03200513          	li	a0,50
ffffffffc0200d56:	c01ff0ef          	jal	ra,ffffffffc0200956 <buddy_system_alloc_pages>
ffffffffc0200d5a:	8b2a                	mv	s6,a0
    assert(p1 != NULL);
ffffffffc0200d5c:	2e050163          	beqz	a0,ffffffffc020103e <buddy_system_check+0x59e>
    show_buddy_array(0, MAX_ORDER);
ffffffffc0200d60:	919ff0ef          	jal	ra,ffffffffc0200678 <show_buddy_array.constprop.0>
    cprintf("Allocating 100 pages for p2...\n");
ffffffffc0200d64:	00001517          	auipc	a0,0x1
ffffffffc0200d68:	21c50513          	addi	a0,a0,540 # ffffffffc0201f80 <etext+0x836>
ffffffffc0200d6c:	be0ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    p2 = buddy_system_alloc_pages(100);
ffffffffc0200d70:	06400513          	li	a0,100
ffffffffc0200d74:	be3ff0ef          	jal	ra,ffffffffc0200956 <buddy_system_alloc_pages>
ffffffffc0200d78:	8baa                	mv	s7,a0
    assert(p2 != NULL);
ffffffffc0200d7a:	1e050263          	beqz	a0,ffffffffc0200f5e <buddy_system_check+0x4be>
    show_buddy_array(0, MAX_ORDER);
ffffffffc0200d7e:	8fbff0ef          	jal	ra,ffffffffc0200678 <show_buddy_array.constprop.0>
    cprintf("p0 address: 0x%016lx\n", p0);
ffffffffc0200d82:	85ce                	mv	a1,s3
ffffffffc0200d84:	00001517          	auipc	a0,0x1
ffffffffc0200d88:	f7450513          	addi	a0,a0,-140 # ffffffffc0201cf8 <etext+0x5ae>
ffffffffc0200d8c:	bc0ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("p1 address: 0x%016lx\n", p1);
ffffffffc0200d90:	85da                	mv	a1,s6
ffffffffc0200d92:	00001517          	auipc	a0,0x1
ffffffffc0200d96:	f7e50513          	addi	a0,a0,-130 # ffffffffc0201d10 <etext+0x5c6>
ffffffffc0200d9a:	bb2ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("p2 address: 0x%016lx\n", p2);
ffffffffc0200d9e:	85de                	mv	a1,s7
ffffffffc0200da0:	00001517          	auipc	a0,0x1
ffffffffc0200da4:	f8850513          	addi	a0,a0,-120 # ffffffffc0201d28 <etext+0x5de>
ffffffffc0200da8:	ba4ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200dac:	11698963          	beq	s3,s6,ffffffffc0200ebe <buddy_system_check+0x41e>
ffffffffc0200db0:	11798763          	beq	s3,s7,ffffffffc0200ebe <buddy_system_check+0x41e>
ffffffffc0200db4:	117b0563          	beq	s6,s7,ffffffffc0200ebe <buddy_system_check+0x41e>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200db8:	0009a783          	lw	a5,0(s3)
ffffffffc0200dbc:	16079163          	bnez	a5,ffffffffc0200f1e <buddy_system_check+0x47e>
ffffffffc0200dc0:	000b2783          	lw	a5,0(s6)
ffffffffc0200dc4:	14079d63          	bnez	a5,ffffffffc0200f1e <buddy_system_check+0x47e>
ffffffffc0200dc8:	000ba783          	lw	a5,0(s7)
ffffffffc0200dcc:	14079963          	bnez	a5,ffffffffc0200f1e <buddy_system_check+0x47e>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200dd0:	000ab783          	ld	a5,0(s5)
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200dd4:	000a3683          	ld	a3,0(s4)
ffffffffc0200dd8:	40f98733          	sub	a4,s3,a5
ffffffffc0200ddc:	870d                	srai	a4,a4,0x3
ffffffffc0200dde:	03270733          	mul	a4,a4,s2
ffffffffc0200de2:	06b2                	slli	a3,a3,0xc
ffffffffc0200de4:	9726                	add	a4,a4,s1
    return page2ppn(page) << PGSHIFT;
ffffffffc0200de6:	0732                	slli	a4,a4,0xc
ffffffffc0200de8:	2ad77b63          	bgeu	a4,a3,ffffffffc020109e <buddy_system_check+0x5fe>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200dec:	40fb0733          	sub	a4,s6,a5
ffffffffc0200df0:	870d                	srai	a4,a4,0x3
ffffffffc0200df2:	03270733          	mul	a4,a4,s2
ffffffffc0200df6:	9726                	add	a4,a4,s1
    return page2ppn(page) << PGSHIFT;
ffffffffc0200df8:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200dfa:	14d77263          	bgeu	a4,a3,ffffffffc0200f3e <buddy_system_check+0x49e>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200dfe:	40fb87b3          	sub	a5,s7,a5
ffffffffc0200e02:	878d                	srai	a5,a5,0x3
ffffffffc0200e04:	032787b3          	mul	a5,a5,s2
ffffffffc0200e08:	97a6                	add	a5,a5,s1
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e0a:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200e0c:	2ad7f963          	bgeu	a5,a3,ffffffffc02010be <buddy_system_check+0x61e>
    cprintf("Freeing p1 first...\n");
ffffffffc0200e10:	00001517          	auipc	a0,0x1
ffffffffc0200e14:	19050513          	addi	a0,a0,400 # ffffffffc0201fa0 <etext+0x856>
ffffffffc0200e18:	b34ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    buddy_system_free_pages(p1, 50);
ffffffffc0200e1c:	03200593          	li	a1,50
ffffffffc0200e20:	855a                	mv	a0,s6
ffffffffc0200e22:	a07ff0ef          	jal	ra,ffffffffc0200828 <buddy_system_free_pages>
    show_buddy_array(0, MAX_ORDER);
ffffffffc0200e26:	853ff0ef          	jal	ra,ffffffffc0200678 <show_buddy_array.constprop.0>
    cprintf("Freeing p0...\n");
ffffffffc0200e2a:	00001517          	auipc	a0,0x1
ffffffffc0200e2e:	f1650513          	addi	a0,a0,-234 # ffffffffc0201d40 <etext+0x5f6>
ffffffffc0200e32:	b1aff0ef          	jal	ra,ffffffffc020014c <cprintf>
    buddy_system_free_pages(p0, 10);
ffffffffc0200e36:	45a9                	li	a1,10
ffffffffc0200e38:	854e                	mv	a0,s3
ffffffffc0200e3a:	9efff0ef          	jal	ra,ffffffffc0200828 <buddy_system_free_pages>
    show_buddy_array(0, MAX_ORDER);
ffffffffc0200e3e:	83bff0ef          	jal	ra,ffffffffc0200678 <show_buddy_array.constprop.0>
    cprintf("Freeing p2...\n");
ffffffffc0200e42:	00001517          	auipc	a0,0x1
ffffffffc0200e46:	f1e50513          	addi	a0,a0,-226 # ffffffffc0201d60 <etext+0x616>
ffffffffc0200e4a:	b02ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    buddy_system_free_pages(p2, 100);
ffffffffc0200e4e:	06400593          	li	a1,100
ffffffffc0200e52:	855e                	mv	a0,s7
ffffffffc0200e54:	9d5ff0ef          	jal	ra,ffffffffc0200828 <buddy_system_free_pages>
    show_buddy_array(0, MAX_ORDER);
ffffffffc0200e58:	821ff0ef          	jal	ra,ffffffffc0200678 <show_buddy_array.constprop.0>
    cprintf("Difficult test completed successfully!\n\n");
ffffffffc0200e5c:	00001517          	auipc	a0,0x1
ffffffffc0200e60:	15c50513          	addi	a0,a0,348 # ffffffffc0201fb8 <etext+0x86e>
ffffffffc0200e64:	ae8ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("=== Edge Cases Test ===\n");
ffffffffc0200e68:	00001517          	auipc	a0,0x1
ffffffffc0200e6c:	18050513          	addi	a0,a0,384 # ffffffffc0201fe8 <etext+0x89e>
ffffffffc0200e70:	adcff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Initial free pages: %d\n", buddy.free);
ffffffffc0200e74:	0f842583          	lw	a1,248(s0)
ffffffffc0200e78:	00001517          	auipc	a0,0x1
ffffffffc0200e7c:	d1050513          	addi	a0,a0,-752 # ffffffffc0201b88 <etext+0x43e>
ffffffffc0200e80:	accff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Testing allocation of 0 pages...\n");
ffffffffc0200e84:	00001517          	auipc	a0,0x1
ffffffffc0200e88:	18450513          	addi	a0,a0,388 # ffffffffc0202008 <etext+0x8be>
ffffffffc0200e8c:	ac0ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    assert(n > 0);
ffffffffc0200e90:	00001697          	auipc	a3,0x1
ffffffffc0200e94:	c3068693          	addi	a3,a3,-976 # ffffffffc0201ac0 <etext+0x376>
ffffffffc0200e98:	00001617          	auipc	a2,0x1
ffffffffc0200e9c:	c3060613          	addi	a2,a2,-976 # ffffffffc0201ac8 <etext+0x37e>
ffffffffc0200ea0:	08400593          	li	a1,132
ffffffffc0200ea4:	00001517          	auipc	a0,0x1
ffffffffc0200ea8:	c3c50513          	addi	a0,a0,-964 # ffffffffc0201ae0 <etext+0x396>
ffffffffc0200eac:	b16ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        cprintf("Warning: Cannot allocate 16384 pages (might be expected)\n");
ffffffffc0200eb0:	00001517          	auipc	a0,0x1
ffffffffc0200eb4:	fc850513          	addi	a0,a0,-56 # ffffffffc0201e78 <etext+0x72e>
ffffffffc0200eb8:	a94ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        return;
ffffffffc0200ebc:	bd89                	j	ffffffffc0200d0e <buddy_system_check+0x26e>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200ebe:	00001697          	auipc	a3,0x1
ffffffffc0200ec2:	d7268693          	addi	a3,a3,-654 # ffffffffc0201c30 <etext+0x4e6>
ffffffffc0200ec6:	00001617          	auipc	a2,0x1
ffffffffc0200eca:	c0260613          	addi	a2,a2,-1022 # ffffffffc0201ac8 <etext+0x37e>
ffffffffc0200ece:	19a00593          	li	a1,410
ffffffffc0200ed2:	00001517          	auipc	a0,0x1
ffffffffc0200ed6:	c0e50513          	addi	a0,a0,-1010 # ffffffffc0201ae0 <etext+0x396>
ffffffffc0200eda:	ae8ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200ede:	00001697          	auipc	a3,0x1
ffffffffc0200ee2:	d7a68693          	addi	a3,a3,-646 # ffffffffc0201c58 <etext+0x50e>
ffffffffc0200ee6:	00001617          	auipc	a2,0x1
ffffffffc0200eea:	be260613          	addi	a2,a2,-1054 # ffffffffc0201ac8 <etext+0x37e>
ffffffffc0200eee:	13800593          	li	a1,312
ffffffffc0200ef2:	00001517          	auipc	a0,0x1
ffffffffc0200ef6:	bee50513          	addi	a0,a0,-1042 # ffffffffc0201ae0 <etext+0x396>
ffffffffc0200efa:	ac8ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200efe:	00001697          	auipc	a3,0x1
ffffffffc0200f02:	d3268693          	addi	a3,a3,-718 # ffffffffc0201c30 <etext+0x4e6>
ffffffffc0200f06:	00001617          	auipc	a2,0x1
ffffffffc0200f0a:	bc260613          	addi	a2,a2,-1086 # ffffffffc0201ac8 <etext+0x37e>
ffffffffc0200f0e:	13700593          	li	a1,311
ffffffffc0200f12:	00001517          	auipc	a0,0x1
ffffffffc0200f16:	bce50513          	addi	a0,a0,-1074 # ffffffffc0201ae0 <etext+0x396>
ffffffffc0200f1a:	aa8ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200f1e:	00001697          	auipc	a3,0x1
ffffffffc0200f22:	d3a68693          	addi	a3,a3,-710 # ffffffffc0201c58 <etext+0x50e>
ffffffffc0200f26:	00001617          	auipc	a2,0x1
ffffffffc0200f2a:	ba260613          	addi	a2,a2,-1118 # ffffffffc0201ac8 <etext+0x37e>
ffffffffc0200f2e:	19b00593          	li	a1,411
ffffffffc0200f32:	00001517          	auipc	a0,0x1
ffffffffc0200f36:	bae50513          	addi	a0,a0,-1106 # ffffffffc0201ae0 <etext+0x396>
ffffffffc0200f3a:	a88ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200f3e:	00001697          	auipc	a3,0x1
ffffffffc0200f42:	d7a68693          	addi	a3,a3,-646 # ffffffffc0201cb8 <etext+0x56e>
ffffffffc0200f46:	00001617          	auipc	a2,0x1
ffffffffc0200f4a:	b8260613          	addi	a2,a2,-1150 # ffffffffc0201ac8 <etext+0x37e>
ffffffffc0200f4e:	19d00593          	li	a1,413
ffffffffc0200f52:	00001517          	auipc	a0,0x1
ffffffffc0200f56:	b8e50513          	addi	a0,a0,-1138 # ffffffffc0201ae0 <etext+0x396>
ffffffffc0200f5a:	a68ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p2 != NULL);
ffffffffc0200f5e:	00001697          	auipc	a3,0x1
ffffffffc0200f62:	cc268693          	addi	a3,a3,-830 # ffffffffc0201c20 <etext+0x4d6>
ffffffffc0200f66:	00001617          	auipc	a2,0x1
ffffffffc0200f6a:	b6260613          	addi	a2,a2,-1182 # ffffffffc0201ac8 <etext+0x37e>
ffffffffc0200f6e:	19200593          	li	a1,402
ffffffffc0200f72:	00001517          	auipc	a0,0x1
ffffffffc0200f76:	b6e50513          	addi	a0,a0,-1170 # ffffffffc0201ae0 <etext+0x396>
ffffffffc0200f7a:	a48ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p != NULL);
ffffffffc0200f7e:	00001697          	auipc	a3,0x1
ffffffffc0200f82:	e4a68693          	addi	a3,a3,-438 # ffffffffc0201dc8 <etext+0x67e>
ffffffffc0200f86:	00001617          	auipc	a2,0x1
ffffffffc0200f8a:	b4260613          	addi	a2,a2,-1214 # ffffffffc0201ac8 <etext+0x37e>
ffffffffc0200f8e:	15900593          	li	a1,345
ffffffffc0200f92:	00001517          	auipc	a0,0x1
ffffffffc0200f96:	b4e50513          	addi	a0,a0,-1202 # ffffffffc0201ae0 <etext+0x396>
ffffffffc0200f9a:	a28ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200f9e:	00001697          	auipc	a3,0x1
ffffffffc0200fa2:	cfa68693          	addi	a3,a3,-774 # ffffffffc0201c98 <etext+0x54e>
ffffffffc0200fa6:	00001617          	auipc	a2,0x1
ffffffffc0200faa:	b2260613          	addi	a2,a2,-1246 # ffffffffc0201ac8 <etext+0x37e>
ffffffffc0200fae:	13900593          	li	a1,313
ffffffffc0200fb2:	00001517          	auipc	a0,0x1
ffffffffc0200fb6:	b2e50513          	addi	a0,a0,-1234 # ffffffffc0201ae0 <etext+0x396>
ffffffffc0200fba:	a08ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200fbe:	00001697          	auipc	a3,0x1
ffffffffc0200fc2:	d1a68693          	addi	a3,a3,-742 # ffffffffc0201cd8 <etext+0x58e>
ffffffffc0200fc6:	00001617          	auipc	a2,0x1
ffffffffc0200fca:	b0260613          	addi	a2,a2,-1278 # ffffffffc0201ac8 <etext+0x37e>
ffffffffc0200fce:	13b00593          	li	a1,315
ffffffffc0200fd2:	00001517          	auipc	a0,0x1
ffffffffc0200fd6:	b0e50513          	addi	a0,a0,-1266 # ffffffffc0201ae0 <etext+0x396>
ffffffffc0200fda:	9e8ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200fde:	00001697          	auipc	a3,0x1
ffffffffc0200fe2:	cda68693          	addi	a3,a3,-806 # ffffffffc0201cb8 <etext+0x56e>
ffffffffc0200fe6:	00001617          	auipc	a2,0x1
ffffffffc0200fea:	ae260613          	addi	a2,a2,-1310 # ffffffffc0201ac8 <etext+0x37e>
ffffffffc0200fee:	13a00593          	li	a1,314
ffffffffc0200ff2:	00001517          	auipc	a0,0x1
ffffffffc0200ff6:	aee50513          	addi	a0,a0,-1298 # ffffffffc0201ae0 <etext+0x396>
ffffffffc0200ffa:	9c8ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p1 != NULL);
ffffffffc0200ffe:	00001697          	auipc	a3,0x1
ffffffffc0201002:	bf268693          	addi	a3,a3,-1038 # ffffffffc0201bf0 <etext+0x4a6>
ffffffffc0201006:	00001617          	auipc	a2,0x1
ffffffffc020100a:	ac260613          	addi	a2,a2,-1342 # ffffffffc0201ac8 <etext+0x37e>
ffffffffc020100e:	12e00593          	li	a1,302
ffffffffc0201012:	00001517          	auipc	a0,0x1
ffffffffc0201016:	ace50513          	addi	a0,a0,-1330 # ffffffffc0201ae0 <etext+0x396>
ffffffffc020101a:	9a8ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 != NULL);
ffffffffc020101e:	00001697          	auipc	a3,0x1
ffffffffc0201022:	ba268693          	addi	a3,a3,-1118 # ffffffffc0201bc0 <etext+0x476>
ffffffffc0201026:	00001617          	auipc	a2,0x1
ffffffffc020102a:	aa260613          	addi	a2,a2,-1374 # ffffffffc0201ac8 <etext+0x37e>
ffffffffc020102e:	12900593          	li	a1,297
ffffffffc0201032:	00001517          	auipc	a0,0x1
ffffffffc0201036:	aae50513          	addi	a0,a0,-1362 # ffffffffc0201ae0 <etext+0x396>
ffffffffc020103a:	988ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p1 != NULL);
ffffffffc020103e:	00001697          	auipc	a3,0x1
ffffffffc0201042:	bb268693          	addi	a3,a3,-1102 # ffffffffc0201bf0 <etext+0x4a6>
ffffffffc0201046:	00001617          	auipc	a2,0x1
ffffffffc020104a:	a8260613          	addi	a2,a2,-1406 # ffffffffc0201ac8 <etext+0x37e>
ffffffffc020104e:	18d00593          	li	a1,397
ffffffffc0201052:	00001517          	auipc	a0,0x1
ffffffffc0201056:	a8e50513          	addi	a0,a0,-1394 # ffffffffc0201ae0 <etext+0x396>
ffffffffc020105a:	968ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p0 != NULL);
ffffffffc020105e:	00001697          	auipc	a3,0x1
ffffffffc0201062:	b6268693          	addi	a3,a3,-1182 # ffffffffc0201bc0 <etext+0x476>
ffffffffc0201066:	00001617          	auipc	a2,0x1
ffffffffc020106a:	a6260613          	addi	a2,a2,-1438 # ffffffffc0201ac8 <etext+0x37e>
ffffffffc020106e:	18800593          	li	a1,392
ffffffffc0201072:	00001517          	auipc	a0,0x1
ffffffffc0201076:	a6e50513          	addi	a0,a0,-1426 # ffffffffc0201ae0 <etext+0x396>
ffffffffc020107a:	948ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(p2 != NULL);
ffffffffc020107e:	00001697          	auipc	a3,0x1
ffffffffc0201082:	ba268693          	addi	a3,a3,-1118 # ffffffffc0201c20 <etext+0x4d6>
ffffffffc0201086:	00001617          	auipc	a2,0x1
ffffffffc020108a:	a4260613          	addi	a2,a2,-1470 # ffffffffc0201ac8 <etext+0x37e>
ffffffffc020108e:	13300593          	li	a1,307
ffffffffc0201092:	00001517          	auipc	a0,0x1
ffffffffc0201096:	a4e50513          	addi	a0,a0,-1458 # ffffffffc0201ae0 <etext+0x396>
ffffffffc020109a:	928ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020109e:	00001697          	auipc	a3,0x1
ffffffffc02010a2:	bfa68693          	addi	a3,a3,-1030 # ffffffffc0201c98 <etext+0x54e>
ffffffffc02010a6:	00001617          	auipc	a2,0x1
ffffffffc02010aa:	a2260613          	addi	a2,a2,-1502 # ffffffffc0201ac8 <etext+0x37e>
ffffffffc02010ae:	19c00593          	li	a1,412
ffffffffc02010b2:	00001517          	auipc	a0,0x1
ffffffffc02010b6:	a2e50513          	addi	a0,a0,-1490 # ffffffffc0201ae0 <etext+0x396>
ffffffffc02010ba:	908ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02010be:	00001697          	auipc	a3,0x1
ffffffffc02010c2:	c1a68693          	addi	a3,a3,-998 # ffffffffc0201cd8 <etext+0x58e>
ffffffffc02010c6:	00001617          	auipc	a2,0x1
ffffffffc02010ca:	a0260613          	addi	a2,a2,-1534 # ffffffffc0201ac8 <etext+0x37e>
ffffffffc02010ce:	19e00593          	li	a1,414
ffffffffc02010d2:	00001517          	auipc	a0,0x1
ffffffffc02010d6:	a0e50513          	addi	a0,a0,-1522 # ffffffffc0201ae0 <etext+0x396>
ffffffffc02010da:	8e8ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02010de <pmm_init>:

static void check_alloc_page(void);

// init_pmm_manager - initialize a pmm_manager instance
static void init_pmm_manager(void) {
    pmm_manager = &buddy_system_pmm_manager;
ffffffffc02010de:	00001797          	auipc	a5,0x1
ffffffffc02010e2:	f7278793          	addi	a5,a5,-142 # ffffffffc0202050 <buddy_system_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02010e6:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc02010e8:	7179                	addi	sp,sp,-48
ffffffffc02010ea:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02010ec:	00001517          	auipc	a0,0x1
ffffffffc02010f0:	f9c50513          	addi	a0,a0,-100 # ffffffffc0202088 <buddy_system_pmm_manager+0x38>
    pmm_manager = &buddy_system_pmm_manager;
ffffffffc02010f4:	00005417          	auipc	s0,0x5
ffffffffc02010f8:	04c40413          	addi	s0,s0,76 # ffffffffc0206140 <pmm_manager>
void pmm_init(void) {
ffffffffc02010fc:	f406                	sd	ra,40(sp)
ffffffffc02010fe:	ec26                	sd	s1,24(sp)
ffffffffc0201100:	e44e                	sd	s3,8(sp)
ffffffffc0201102:	e84a                	sd	s2,16(sp)
ffffffffc0201104:	e052                	sd	s4,0(sp)
    pmm_manager = &buddy_system_pmm_manager;
ffffffffc0201106:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201108:	844ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    pmm_manager->init();
ffffffffc020110c:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020110e:	00005497          	auipc	s1,0x5
ffffffffc0201112:	04a48493          	addi	s1,s1,74 # ffffffffc0206158 <va_pa_offset>
    pmm_manager->init();
ffffffffc0201116:	679c                	ld	a5,8(a5)
ffffffffc0201118:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020111a:	57f5                	li	a5,-3
ffffffffc020111c:	07fa                	slli	a5,a5,0x1e
ffffffffc020111e:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0201120:	c9cff0ef          	jal	ra,ffffffffc02005bc <get_memory_base>
ffffffffc0201124:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc0201126:	ca0ff0ef          	jal	ra,ffffffffc02005c6 <get_memory_size>
    if (mem_size == 0) {
ffffffffc020112a:	14050d63          	beqz	a0,ffffffffc0201284 <pmm_init+0x1a6>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc020112e:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc0201130:	00001517          	auipc	a0,0x1
ffffffffc0201134:	fa050513          	addi	a0,a0,-96 # ffffffffc02020d0 <buddy_system_pmm_manager+0x80>
ffffffffc0201138:	814ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc020113c:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0201140:	864e                	mv	a2,s3
ffffffffc0201142:	fffa0693          	addi	a3,s4,-1
ffffffffc0201146:	85ca                	mv	a1,s2
ffffffffc0201148:	00001517          	auipc	a0,0x1
ffffffffc020114c:	fa050513          	addi	a0,a0,-96 # ffffffffc02020e8 <buddy_system_pmm_manager+0x98>
ffffffffc0201150:	ffdfe0ef          	jal	ra,ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0201154:	c80007b7          	lui	a5,0xc8000
ffffffffc0201158:	8652                	mv	a2,s4
ffffffffc020115a:	0d47e463          	bltu	a5,s4,ffffffffc0201222 <pmm_init+0x144>
ffffffffc020115e:	00006797          	auipc	a5,0x6
ffffffffc0201162:	00178793          	addi	a5,a5,1 # ffffffffc020715f <end+0xfff>
ffffffffc0201166:	757d                	lui	a0,0xfffff
ffffffffc0201168:	8d7d                	and	a0,a0,a5
ffffffffc020116a:	8231                	srli	a2,a2,0xc
ffffffffc020116c:	00005797          	auipc	a5,0x5
ffffffffc0201170:	fcc7b223          	sd	a2,-60(a5) # ffffffffc0206130 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201174:	00005797          	auipc	a5,0x5
ffffffffc0201178:	fca7b223          	sd	a0,-60(a5) # ffffffffc0206138 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020117c:	000807b7          	lui	a5,0x80
ffffffffc0201180:	002005b7          	lui	a1,0x200
ffffffffc0201184:	02f60563          	beq	a2,a5,ffffffffc02011ae <pmm_init+0xd0>
ffffffffc0201188:	00261593          	slli	a1,a2,0x2
ffffffffc020118c:	00c586b3          	add	a3,a1,a2
ffffffffc0201190:	fec007b7          	lui	a5,0xfec00
ffffffffc0201194:	97aa                	add	a5,a5,a0
ffffffffc0201196:	068e                	slli	a3,a3,0x3
ffffffffc0201198:	96be                	add	a3,a3,a5
ffffffffc020119a:	87aa                	mv	a5,a0
        SetPageReserved(pages + i);
ffffffffc020119c:	6798                	ld	a4,8(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020119e:	02878793          	addi	a5,a5,40 # fffffffffec00028 <end+0x3e9f9ec8>
        SetPageReserved(pages + i);
ffffffffc02011a2:	00176713          	ori	a4,a4,1
ffffffffc02011a6:	fee7b023          	sd	a4,-32(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02011aa:	fef699e3          	bne	a3,a5,ffffffffc020119c <pmm_init+0xbe>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02011ae:	95b2                	add	a1,a1,a2
ffffffffc02011b0:	fec006b7          	lui	a3,0xfec00
ffffffffc02011b4:	96aa                	add	a3,a3,a0
ffffffffc02011b6:	058e                	slli	a1,a1,0x3
ffffffffc02011b8:	96ae                	add	a3,a3,a1
ffffffffc02011ba:	c02007b7          	lui	a5,0xc0200
ffffffffc02011be:	0af6e763          	bltu	a3,a5,ffffffffc020126c <pmm_init+0x18e>
ffffffffc02011c2:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02011c4:	77fd                	lui	a5,0xfffff
ffffffffc02011c6:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02011ca:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc02011cc:	04b6ee63          	bltu	a3,a1,ffffffffc0201228 <pmm_init+0x14a>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02011d0:	601c                	ld	a5,0(s0)
ffffffffc02011d2:	7b9c                	ld	a5,48(a5)
ffffffffc02011d4:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02011d6:	00001517          	auipc	a0,0x1
ffffffffc02011da:	f6a50513          	addi	a0,a0,-150 # ffffffffc0202140 <buddy_system_pmm_manager+0xf0>
ffffffffc02011de:	f6ffe0ef          	jal	ra,ffffffffc020014c <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc02011e2:	00004597          	auipc	a1,0x4
ffffffffc02011e6:	e1e58593          	addi	a1,a1,-482 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc02011ea:	00005797          	auipc	a5,0x5
ffffffffc02011ee:	f6b7b323          	sd	a1,-154(a5) # ffffffffc0206150 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc02011f2:	c02007b7          	lui	a5,0xc0200
ffffffffc02011f6:	0af5e363          	bltu	a1,a5,ffffffffc020129c <pmm_init+0x1be>
ffffffffc02011fa:	6090                	ld	a2,0(s1)
}
ffffffffc02011fc:	7402                	ld	s0,32(sp)
ffffffffc02011fe:	70a2                	ld	ra,40(sp)
ffffffffc0201200:	64e2                	ld	s1,24(sp)
ffffffffc0201202:	6942                	ld	s2,16(sp)
ffffffffc0201204:	69a2                	ld	s3,8(sp)
ffffffffc0201206:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0201208:	40c58633          	sub	a2,a1,a2
ffffffffc020120c:	00005797          	auipc	a5,0x5
ffffffffc0201210:	f2c7be23          	sd	a2,-196(a5) # ffffffffc0206148 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201214:	00001517          	auipc	a0,0x1
ffffffffc0201218:	f4c50513          	addi	a0,a0,-180 # ffffffffc0202160 <buddy_system_pmm_manager+0x110>
}
ffffffffc020121c:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020121e:	f2ffe06f          	j	ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0201222:	c8000637          	lui	a2,0xc8000
ffffffffc0201226:	bf25                	j	ffffffffc020115e <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201228:	6705                	lui	a4,0x1
ffffffffc020122a:	177d                	addi	a4,a4,-1
ffffffffc020122c:	96ba                	add	a3,a3,a4
ffffffffc020122e:	8efd                	and	a3,a3,a5
    if (PPN(pa) >= npage) {
ffffffffc0201230:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201234:	02c7f063          	bgeu	a5,a2,ffffffffc0201254 <pmm_init+0x176>
    pmm_manager->init_memmap(base, n);
ffffffffc0201238:	6010                	ld	a2,0(s0)
    return &pages[PPN(pa) - nbase];
ffffffffc020123a:	fff80737          	lui	a4,0xfff80
ffffffffc020123e:	973e                	add	a4,a4,a5
ffffffffc0201240:	00271793          	slli	a5,a4,0x2
ffffffffc0201244:	97ba                	add	a5,a5,a4
ffffffffc0201246:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201248:	8d95                	sub	a1,a1,a3
ffffffffc020124a:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc020124c:	81b1                	srli	a1,a1,0xc
ffffffffc020124e:	953e                	add	a0,a0,a5
ffffffffc0201250:	9702                	jalr	a4
}
ffffffffc0201252:	bfbd                	j	ffffffffc02011d0 <pmm_init+0xf2>
        panic("pa2page called with invalid pa");
ffffffffc0201254:	00000617          	auipc	a2,0x0
ffffffffc0201258:	75c60613          	addi	a2,a2,1884 # ffffffffc02019b0 <etext+0x266>
ffffffffc020125c:	06a00593          	li	a1,106
ffffffffc0201260:	00000517          	auipc	a0,0x0
ffffffffc0201264:	77050513          	addi	a0,a0,1904 # ffffffffc02019d0 <etext+0x286>
ffffffffc0201268:	f5bfe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020126c:	00001617          	auipc	a2,0x1
ffffffffc0201270:	eac60613          	addi	a2,a2,-340 # ffffffffc0202118 <buddy_system_pmm_manager+0xc8>
ffffffffc0201274:	05f00593          	li	a1,95
ffffffffc0201278:	00001517          	auipc	a0,0x1
ffffffffc020127c:	e4850513          	addi	a0,a0,-440 # ffffffffc02020c0 <buddy_system_pmm_manager+0x70>
ffffffffc0201280:	f43fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("DTB memory info not available");
ffffffffc0201284:	00001617          	auipc	a2,0x1
ffffffffc0201288:	e1c60613          	addi	a2,a2,-484 # ffffffffc02020a0 <buddy_system_pmm_manager+0x50>
ffffffffc020128c:	04700593          	li	a1,71
ffffffffc0201290:	00001517          	auipc	a0,0x1
ffffffffc0201294:	e3050513          	addi	a0,a0,-464 # ffffffffc02020c0 <buddy_system_pmm_manager+0x70>
ffffffffc0201298:	f2bfe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc020129c:	86ae                	mv	a3,a1
ffffffffc020129e:	00001617          	auipc	a2,0x1
ffffffffc02012a2:	e7a60613          	addi	a2,a2,-390 # ffffffffc0202118 <buddy_system_pmm_manager+0xc8>
ffffffffc02012a6:	07a00593          	li	a1,122
ffffffffc02012aa:	00001517          	auipc	a0,0x1
ffffffffc02012ae:	e1650513          	addi	a0,a0,-490 # ffffffffc02020c0 <buddy_system_pmm_manager+0x70>
ffffffffc02012b2:	f11fe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc02012b6 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02012b6:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02012ba:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02012bc:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02012c0:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02012c2:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02012c6:	f022                	sd	s0,32(sp)
ffffffffc02012c8:	ec26                	sd	s1,24(sp)
ffffffffc02012ca:	e84a                	sd	s2,16(sp)
ffffffffc02012cc:	f406                	sd	ra,40(sp)
ffffffffc02012ce:	e44e                	sd	s3,8(sp)
ffffffffc02012d0:	84aa                	mv	s1,a0
ffffffffc02012d2:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02012d4:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02012d8:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02012da:	03067e63          	bgeu	a2,a6,ffffffffc0201316 <printnum+0x60>
ffffffffc02012de:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02012e0:	00805763          	blez	s0,ffffffffc02012ee <printnum+0x38>
ffffffffc02012e4:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02012e6:	85ca                	mv	a1,s2
ffffffffc02012e8:	854e                	mv	a0,s3
ffffffffc02012ea:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02012ec:	fc65                	bnez	s0,ffffffffc02012e4 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02012ee:	1a02                	slli	s4,s4,0x20
ffffffffc02012f0:	00001797          	auipc	a5,0x1
ffffffffc02012f4:	eb078793          	addi	a5,a5,-336 # ffffffffc02021a0 <buddy_system_pmm_manager+0x150>
ffffffffc02012f8:	020a5a13          	srli	s4,s4,0x20
ffffffffc02012fc:	9a3e                	add	s4,s4,a5
}
ffffffffc02012fe:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201300:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201304:	70a2                	ld	ra,40(sp)
ffffffffc0201306:	69a2                	ld	s3,8(sp)
ffffffffc0201308:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020130a:	85ca                	mv	a1,s2
ffffffffc020130c:	87a6                	mv	a5,s1
}
ffffffffc020130e:	6942                	ld	s2,16(sp)
ffffffffc0201310:	64e2                	ld	s1,24(sp)
ffffffffc0201312:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201314:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201316:	03065633          	divu	a2,a2,a6
ffffffffc020131a:	8722                	mv	a4,s0
ffffffffc020131c:	f9bff0ef          	jal	ra,ffffffffc02012b6 <printnum>
ffffffffc0201320:	b7f9                	j	ffffffffc02012ee <printnum+0x38>

ffffffffc0201322 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201322:	7119                	addi	sp,sp,-128
ffffffffc0201324:	f4a6                	sd	s1,104(sp)
ffffffffc0201326:	f0ca                	sd	s2,96(sp)
ffffffffc0201328:	ecce                	sd	s3,88(sp)
ffffffffc020132a:	e8d2                	sd	s4,80(sp)
ffffffffc020132c:	e4d6                	sd	s5,72(sp)
ffffffffc020132e:	e0da                	sd	s6,64(sp)
ffffffffc0201330:	fc5e                	sd	s7,56(sp)
ffffffffc0201332:	f06a                	sd	s10,32(sp)
ffffffffc0201334:	fc86                	sd	ra,120(sp)
ffffffffc0201336:	f8a2                	sd	s0,112(sp)
ffffffffc0201338:	f862                	sd	s8,48(sp)
ffffffffc020133a:	f466                	sd	s9,40(sp)
ffffffffc020133c:	ec6e                	sd	s11,24(sp)
ffffffffc020133e:	892a                	mv	s2,a0
ffffffffc0201340:	84ae                	mv	s1,a1
ffffffffc0201342:	8d32                	mv	s10,a2
ffffffffc0201344:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201346:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc020134a:	5b7d                	li	s6,-1
ffffffffc020134c:	00001a97          	auipc	s5,0x1
ffffffffc0201350:	e88a8a93          	addi	s5,s5,-376 # ffffffffc02021d4 <buddy_system_pmm_manager+0x184>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201354:	00001b97          	auipc	s7,0x1
ffffffffc0201358:	05cb8b93          	addi	s7,s7,92 # ffffffffc02023b0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020135c:	000d4503          	lbu	a0,0(s10)
ffffffffc0201360:	001d0413          	addi	s0,s10,1
ffffffffc0201364:	01350a63          	beq	a0,s3,ffffffffc0201378 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201368:	c121                	beqz	a0,ffffffffc02013a8 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc020136a:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020136c:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc020136e:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201370:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201374:	ff351ae3          	bne	a0,s3,ffffffffc0201368 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201378:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc020137c:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201380:	4c81                	li	s9,0
ffffffffc0201382:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201384:	5c7d                	li	s8,-1
ffffffffc0201386:	5dfd                	li	s11,-1
ffffffffc0201388:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc020138c:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020138e:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201392:	0ff5f593          	zext.b	a1,a1
ffffffffc0201396:	00140d13          	addi	s10,s0,1
ffffffffc020139a:	04b56263          	bltu	a0,a1,ffffffffc02013de <vprintfmt+0xbc>
ffffffffc020139e:	058a                	slli	a1,a1,0x2
ffffffffc02013a0:	95d6                	add	a1,a1,s5
ffffffffc02013a2:	4194                	lw	a3,0(a1)
ffffffffc02013a4:	96d6                	add	a3,a3,s5
ffffffffc02013a6:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02013a8:	70e6                	ld	ra,120(sp)
ffffffffc02013aa:	7446                	ld	s0,112(sp)
ffffffffc02013ac:	74a6                	ld	s1,104(sp)
ffffffffc02013ae:	7906                	ld	s2,96(sp)
ffffffffc02013b0:	69e6                	ld	s3,88(sp)
ffffffffc02013b2:	6a46                	ld	s4,80(sp)
ffffffffc02013b4:	6aa6                	ld	s5,72(sp)
ffffffffc02013b6:	6b06                	ld	s6,64(sp)
ffffffffc02013b8:	7be2                	ld	s7,56(sp)
ffffffffc02013ba:	7c42                	ld	s8,48(sp)
ffffffffc02013bc:	7ca2                	ld	s9,40(sp)
ffffffffc02013be:	7d02                	ld	s10,32(sp)
ffffffffc02013c0:	6de2                	ld	s11,24(sp)
ffffffffc02013c2:	6109                	addi	sp,sp,128
ffffffffc02013c4:	8082                	ret
            padc = '0';
ffffffffc02013c6:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc02013c8:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013cc:	846a                	mv	s0,s10
ffffffffc02013ce:	00140d13          	addi	s10,s0,1
ffffffffc02013d2:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02013d6:	0ff5f593          	zext.b	a1,a1
ffffffffc02013da:	fcb572e3          	bgeu	a0,a1,ffffffffc020139e <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc02013de:	85a6                	mv	a1,s1
ffffffffc02013e0:	02500513          	li	a0,37
ffffffffc02013e4:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02013e6:	fff44783          	lbu	a5,-1(s0)
ffffffffc02013ea:	8d22                	mv	s10,s0
ffffffffc02013ec:	f73788e3          	beq	a5,s3,ffffffffc020135c <vprintfmt+0x3a>
ffffffffc02013f0:	ffed4783          	lbu	a5,-2(s10)
ffffffffc02013f4:	1d7d                	addi	s10,s10,-1
ffffffffc02013f6:	ff379de3          	bne	a5,s3,ffffffffc02013f0 <vprintfmt+0xce>
ffffffffc02013fa:	b78d                	j	ffffffffc020135c <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc02013fc:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201400:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201404:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201406:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc020140a:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020140e:	02d86463          	bltu	a6,a3,ffffffffc0201436 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201412:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201416:	002c169b          	slliw	a3,s8,0x2
ffffffffc020141a:	0186873b          	addw	a4,a3,s8
ffffffffc020141e:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201422:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201424:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201428:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc020142a:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc020142e:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201432:	fed870e3          	bgeu	a6,a3,ffffffffc0201412 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201436:	f40ddce3          	bgez	s11,ffffffffc020138e <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc020143a:	8de2                	mv	s11,s8
ffffffffc020143c:	5c7d                	li	s8,-1
ffffffffc020143e:	bf81                	j	ffffffffc020138e <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201440:	fffdc693          	not	a3,s11
ffffffffc0201444:	96fd                	srai	a3,a3,0x3f
ffffffffc0201446:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020144a:	00144603          	lbu	a2,1(s0)
ffffffffc020144e:	2d81                	sext.w	s11,s11
ffffffffc0201450:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201452:	bf35                	j	ffffffffc020138e <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201454:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201458:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc020145c:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020145e:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201460:	bfd9                	j	ffffffffc0201436 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201462:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201464:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201468:	01174463          	blt	a4,a7,ffffffffc0201470 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc020146c:	1a088e63          	beqz	a7,ffffffffc0201628 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201470:	000a3603          	ld	a2,0(s4)
ffffffffc0201474:	46c1                	li	a3,16
ffffffffc0201476:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201478:	2781                	sext.w	a5,a5
ffffffffc020147a:	876e                	mv	a4,s11
ffffffffc020147c:	85a6                	mv	a1,s1
ffffffffc020147e:	854a                	mv	a0,s2
ffffffffc0201480:	e37ff0ef          	jal	ra,ffffffffc02012b6 <printnum>
            break;
ffffffffc0201484:	bde1                	j	ffffffffc020135c <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201486:	000a2503          	lw	a0,0(s4)
ffffffffc020148a:	85a6                	mv	a1,s1
ffffffffc020148c:	0a21                	addi	s4,s4,8
ffffffffc020148e:	9902                	jalr	s2
            break;
ffffffffc0201490:	b5f1                	j	ffffffffc020135c <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201492:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201494:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201498:	01174463          	blt	a4,a7,ffffffffc02014a0 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc020149c:	18088163          	beqz	a7,ffffffffc020161e <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc02014a0:	000a3603          	ld	a2,0(s4)
ffffffffc02014a4:	46a9                	li	a3,10
ffffffffc02014a6:	8a2e                	mv	s4,a1
ffffffffc02014a8:	bfc1                	j	ffffffffc0201478 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02014aa:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02014ae:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02014b0:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02014b2:	bdf1                	j	ffffffffc020138e <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc02014b4:	85a6                	mv	a1,s1
ffffffffc02014b6:	02500513          	li	a0,37
ffffffffc02014ba:	9902                	jalr	s2
            break;
ffffffffc02014bc:	b545                	j	ffffffffc020135c <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02014be:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc02014c2:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02014c4:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02014c6:	b5e1                	j	ffffffffc020138e <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc02014c8:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02014ca:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02014ce:	01174463          	blt	a4,a7,ffffffffc02014d6 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc02014d2:	14088163          	beqz	a7,ffffffffc0201614 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc02014d6:	000a3603          	ld	a2,0(s4)
ffffffffc02014da:	46a1                	li	a3,8
ffffffffc02014dc:	8a2e                	mv	s4,a1
ffffffffc02014de:	bf69                	j	ffffffffc0201478 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc02014e0:	03000513          	li	a0,48
ffffffffc02014e4:	85a6                	mv	a1,s1
ffffffffc02014e6:	e03e                	sd	a5,0(sp)
ffffffffc02014e8:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02014ea:	85a6                	mv	a1,s1
ffffffffc02014ec:	07800513          	li	a0,120
ffffffffc02014f0:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02014f2:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc02014f4:	6782                	ld	a5,0(sp)
ffffffffc02014f6:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02014f8:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc02014fc:	bfb5                	j	ffffffffc0201478 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02014fe:	000a3403          	ld	s0,0(s4)
ffffffffc0201502:	008a0713          	addi	a4,s4,8
ffffffffc0201506:	e03a                	sd	a4,0(sp)
ffffffffc0201508:	14040263          	beqz	s0,ffffffffc020164c <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc020150c:	0fb05763          	blez	s11,ffffffffc02015fa <vprintfmt+0x2d8>
ffffffffc0201510:	02d00693          	li	a3,45
ffffffffc0201514:	0cd79163          	bne	a5,a3,ffffffffc02015d6 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201518:	00044783          	lbu	a5,0(s0)
ffffffffc020151c:	0007851b          	sext.w	a0,a5
ffffffffc0201520:	cf85                	beqz	a5,ffffffffc0201558 <vprintfmt+0x236>
ffffffffc0201522:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201526:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020152a:	000c4563          	bltz	s8,ffffffffc0201534 <vprintfmt+0x212>
ffffffffc020152e:	3c7d                	addiw	s8,s8,-1
ffffffffc0201530:	036c0263          	beq	s8,s6,ffffffffc0201554 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201534:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201536:	0e0c8e63          	beqz	s9,ffffffffc0201632 <vprintfmt+0x310>
ffffffffc020153a:	3781                	addiw	a5,a5,-32
ffffffffc020153c:	0ef47b63          	bgeu	s0,a5,ffffffffc0201632 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201540:	03f00513          	li	a0,63
ffffffffc0201544:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201546:	000a4783          	lbu	a5,0(s4)
ffffffffc020154a:	3dfd                	addiw	s11,s11,-1
ffffffffc020154c:	0a05                	addi	s4,s4,1
ffffffffc020154e:	0007851b          	sext.w	a0,a5
ffffffffc0201552:	ffe1                	bnez	a5,ffffffffc020152a <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201554:	01b05963          	blez	s11,ffffffffc0201566 <vprintfmt+0x244>
ffffffffc0201558:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc020155a:	85a6                	mv	a1,s1
ffffffffc020155c:	02000513          	li	a0,32
ffffffffc0201560:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201562:	fe0d9be3          	bnez	s11,ffffffffc0201558 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201566:	6a02                	ld	s4,0(sp)
ffffffffc0201568:	bbd5                	j	ffffffffc020135c <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020156a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020156c:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201570:	01174463          	blt	a4,a7,ffffffffc0201578 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201574:	08088d63          	beqz	a7,ffffffffc020160e <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201578:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc020157c:	0a044d63          	bltz	s0,ffffffffc0201636 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201580:	8622                	mv	a2,s0
ffffffffc0201582:	8a66                	mv	s4,s9
ffffffffc0201584:	46a9                	li	a3,10
ffffffffc0201586:	bdcd                	j	ffffffffc0201478 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201588:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020158c:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc020158e:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201590:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201594:	8fb5                	xor	a5,a5,a3
ffffffffc0201596:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020159a:	02d74163          	blt	a4,a3,ffffffffc02015bc <vprintfmt+0x29a>
ffffffffc020159e:	00369793          	slli	a5,a3,0x3
ffffffffc02015a2:	97de                	add	a5,a5,s7
ffffffffc02015a4:	639c                	ld	a5,0(a5)
ffffffffc02015a6:	cb99                	beqz	a5,ffffffffc02015bc <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc02015a8:	86be                	mv	a3,a5
ffffffffc02015aa:	00001617          	auipc	a2,0x1
ffffffffc02015ae:	c2660613          	addi	a2,a2,-986 # ffffffffc02021d0 <buddy_system_pmm_manager+0x180>
ffffffffc02015b2:	85a6                	mv	a1,s1
ffffffffc02015b4:	854a                	mv	a0,s2
ffffffffc02015b6:	0ce000ef          	jal	ra,ffffffffc0201684 <printfmt>
ffffffffc02015ba:	b34d                	j	ffffffffc020135c <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02015bc:	00001617          	auipc	a2,0x1
ffffffffc02015c0:	c0460613          	addi	a2,a2,-1020 # ffffffffc02021c0 <buddy_system_pmm_manager+0x170>
ffffffffc02015c4:	85a6                	mv	a1,s1
ffffffffc02015c6:	854a                	mv	a0,s2
ffffffffc02015c8:	0bc000ef          	jal	ra,ffffffffc0201684 <printfmt>
ffffffffc02015cc:	bb41                	j	ffffffffc020135c <vprintfmt+0x3a>
                p = "(null)";
ffffffffc02015ce:	00001417          	auipc	s0,0x1
ffffffffc02015d2:	bea40413          	addi	s0,s0,-1046 # ffffffffc02021b8 <buddy_system_pmm_manager+0x168>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02015d6:	85e2                	mv	a1,s8
ffffffffc02015d8:	8522                	mv	a0,s0
ffffffffc02015da:	e43e                	sd	a5,8(sp)
ffffffffc02015dc:	0fc000ef          	jal	ra,ffffffffc02016d8 <strnlen>
ffffffffc02015e0:	40ad8dbb          	subw	s11,s11,a0
ffffffffc02015e4:	01b05b63          	blez	s11,ffffffffc02015fa <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc02015e8:	67a2                	ld	a5,8(sp)
ffffffffc02015ea:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02015ee:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc02015f0:	85a6                	mv	a1,s1
ffffffffc02015f2:	8552                	mv	a0,s4
ffffffffc02015f4:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02015f6:	fe0d9ce3          	bnez	s11,ffffffffc02015ee <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02015fa:	00044783          	lbu	a5,0(s0)
ffffffffc02015fe:	00140a13          	addi	s4,s0,1
ffffffffc0201602:	0007851b          	sext.w	a0,a5
ffffffffc0201606:	d3a5                	beqz	a5,ffffffffc0201566 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201608:	05e00413          	li	s0,94
ffffffffc020160c:	bf39                	j	ffffffffc020152a <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc020160e:	000a2403          	lw	s0,0(s4)
ffffffffc0201612:	b7ad                	j	ffffffffc020157c <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201614:	000a6603          	lwu	a2,0(s4)
ffffffffc0201618:	46a1                	li	a3,8
ffffffffc020161a:	8a2e                	mv	s4,a1
ffffffffc020161c:	bdb1                	j	ffffffffc0201478 <vprintfmt+0x156>
ffffffffc020161e:	000a6603          	lwu	a2,0(s4)
ffffffffc0201622:	46a9                	li	a3,10
ffffffffc0201624:	8a2e                	mv	s4,a1
ffffffffc0201626:	bd89                	j	ffffffffc0201478 <vprintfmt+0x156>
ffffffffc0201628:	000a6603          	lwu	a2,0(s4)
ffffffffc020162c:	46c1                	li	a3,16
ffffffffc020162e:	8a2e                	mv	s4,a1
ffffffffc0201630:	b5a1                	j	ffffffffc0201478 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201632:	9902                	jalr	s2
ffffffffc0201634:	bf09                	j	ffffffffc0201546 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201636:	85a6                	mv	a1,s1
ffffffffc0201638:	02d00513          	li	a0,45
ffffffffc020163c:	e03e                	sd	a5,0(sp)
ffffffffc020163e:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201640:	6782                	ld	a5,0(sp)
ffffffffc0201642:	8a66                	mv	s4,s9
ffffffffc0201644:	40800633          	neg	a2,s0
ffffffffc0201648:	46a9                	li	a3,10
ffffffffc020164a:	b53d                	j	ffffffffc0201478 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc020164c:	03b05163          	blez	s11,ffffffffc020166e <vprintfmt+0x34c>
ffffffffc0201650:	02d00693          	li	a3,45
ffffffffc0201654:	f6d79de3          	bne	a5,a3,ffffffffc02015ce <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201658:	00001417          	auipc	s0,0x1
ffffffffc020165c:	b6040413          	addi	s0,s0,-1184 # ffffffffc02021b8 <buddy_system_pmm_manager+0x168>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201660:	02800793          	li	a5,40
ffffffffc0201664:	02800513          	li	a0,40
ffffffffc0201668:	00140a13          	addi	s4,s0,1
ffffffffc020166c:	bd6d                	j	ffffffffc0201526 <vprintfmt+0x204>
ffffffffc020166e:	00001a17          	auipc	s4,0x1
ffffffffc0201672:	b4ba0a13          	addi	s4,s4,-1205 # ffffffffc02021b9 <buddy_system_pmm_manager+0x169>
ffffffffc0201676:	02800513          	li	a0,40
ffffffffc020167a:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020167e:	05e00413          	li	s0,94
ffffffffc0201682:	b565                	j	ffffffffc020152a <vprintfmt+0x208>

ffffffffc0201684 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201684:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201686:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020168a:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020168c:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020168e:	ec06                	sd	ra,24(sp)
ffffffffc0201690:	f83a                	sd	a4,48(sp)
ffffffffc0201692:	fc3e                	sd	a5,56(sp)
ffffffffc0201694:	e0c2                	sd	a6,64(sp)
ffffffffc0201696:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201698:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020169a:	c89ff0ef          	jal	ra,ffffffffc0201322 <vprintfmt>
}
ffffffffc020169e:	60e2                	ld	ra,24(sp)
ffffffffc02016a0:	6161                	addi	sp,sp,80
ffffffffc02016a2:	8082                	ret

ffffffffc02016a4 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc02016a4:	4781                	li	a5,0
ffffffffc02016a6:	00005717          	auipc	a4,0x5
ffffffffc02016aa:	96a73703          	ld	a4,-1686(a4) # ffffffffc0206010 <SBI_CONSOLE_PUTCHAR>
ffffffffc02016ae:	88ba                	mv	a7,a4
ffffffffc02016b0:	852a                	mv	a0,a0
ffffffffc02016b2:	85be                	mv	a1,a5
ffffffffc02016b4:	863e                	mv	a2,a5
ffffffffc02016b6:	00000073          	ecall
ffffffffc02016ba:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc02016bc:	8082                	ret

ffffffffc02016be <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02016be:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc02016c2:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc02016c4:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc02016c6:	cb81                	beqz	a5,ffffffffc02016d6 <strlen+0x18>
        cnt ++;
ffffffffc02016c8:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc02016ca:	00a707b3          	add	a5,a4,a0
ffffffffc02016ce:	0007c783          	lbu	a5,0(a5)
ffffffffc02016d2:	fbfd                	bnez	a5,ffffffffc02016c8 <strlen+0xa>
ffffffffc02016d4:	8082                	ret
    }
    return cnt;
}
ffffffffc02016d6:	8082                	ret

ffffffffc02016d8 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02016d8:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02016da:	e589                	bnez	a1,ffffffffc02016e4 <strnlen+0xc>
ffffffffc02016dc:	a811                	j	ffffffffc02016f0 <strnlen+0x18>
        cnt ++;
ffffffffc02016de:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02016e0:	00f58863          	beq	a1,a5,ffffffffc02016f0 <strnlen+0x18>
ffffffffc02016e4:	00f50733          	add	a4,a0,a5
ffffffffc02016e8:	00074703          	lbu	a4,0(a4)
ffffffffc02016ec:	fb6d                	bnez	a4,ffffffffc02016de <strnlen+0x6>
ffffffffc02016ee:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02016f0:	852e                	mv	a0,a1
ffffffffc02016f2:	8082                	ret

ffffffffc02016f4 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02016f4:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02016f8:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02016fc:	cb89                	beqz	a5,ffffffffc020170e <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc02016fe:	0505                	addi	a0,a0,1
ffffffffc0201700:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201702:	fee789e3          	beq	a5,a4,ffffffffc02016f4 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201706:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc020170a:	9d19                	subw	a0,a0,a4
ffffffffc020170c:	8082                	ret
ffffffffc020170e:	4501                	li	a0,0
ffffffffc0201710:	bfed                	j	ffffffffc020170a <strcmp+0x16>

ffffffffc0201712 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201712:	c20d                	beqz	a2,ffffffffc0201734 <strncmp+0x22>
ffffffffc0201714:	962e                	add	a2,a2,a1
ffffffffc0201716:	a031                	j	ffffffffc0201722 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0201718:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020171a:	00e79a63          	bne	a5,a4,ffffffffc020172e <strncmp+0x1c>
ffffffffc020171e:	00b60b63          	beq	a2,a1,ffffffffc0201734 <strncmp+0x22>
ffffffffc0201722:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201726:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201728:	fff5c703          	lbu	a4,-1(a1)
ffffffffc020172c:	f7f5                	bnez	a5,ffffffffc0201718 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020172e:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0201732:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201734:	4501                	li	a0,0
ffffffffc0201736:	8082                	ret

ffffffffc0201738 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201738:	ca01                	beqz	a2,ffffffffc0201748 <memset+0x10>
ffffffffc020173a:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc020173c:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc020173e:	0785                	addi	a5,a5,1
ffffffffc0201740:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201744:	fec79de3          	bne	a5,a2,ffffffffc020173e <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201748:	8082                	ret
