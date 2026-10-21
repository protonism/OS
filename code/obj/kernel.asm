
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
ffffffffc0200044:	0d628293          	addi	t0,t0,214 # ffffffffc02000d6 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16 # ffffffffc0204ff0 <bootstack+0x1ff0>
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00001517          	auipc	a0,0x1
ffffffffc0200050:	69450513          	addi	a0,a0,1684 # ffffffffc02016e0 <etext+0x4>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f2000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07c58593          	addi	a1,a1,124 # ffffffffc02000d6 <kern_init>
ffffffffc0200062:	00001517          	auipc	a0,0x1
ffffffffc0200066:	69e50513          	addi	a0,a0,1694 # ffffffffc0201700 <etext+0x24>
ffffffffc020006a:	0de000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00001597          	auipc	a1,0x1
ffffffffc0200072:	66e58593          	addi	a1,a1,1646 # ffffffffc02016dc <etext>
ffffffffc0200076:	00001517          	auipc	a0,0x1
ffffffffc020007a:	6aa50513          	addi	a0,a0,1706 # ffffffffc0201720 <etext+0x44>
ffffffffc020007e:	0ca000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00006597          	auipc	a1,0x6
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0206018 <free_area>
ffffffffc020008a:	00001517          	auipc	a0,0x1
ffffffffc020008e:	6b650513          	addi	a0,a0,1718 # ffffffffc0201740 <etext+0x64>
ffffffffc0200092:	0b6000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00006597          	auipc	a1,0x6
ffffffffc020009a:	fe258593          	addi	a1,a1,-30 # ffffffffc0206078 <end>
ffffffffc020009e:	00001517          	auipc	a0,0x1
ffffffffc02000a2:	6c250513          	addi	a0,a0,1730 # ffffffffc0201760 <etext+0x84>
ffffffffc02000a6:	0a2000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00000717          	auipc	a4,0x0
ffffffffc02000ae:	02c70713          	addi	a4,a4,44 # ffffffffc02000d6 <kern_init>
ffffffffc02000b2:	00006797          	auipc	a5,0x6
ffffffffc02000b6:	3c578793          	addi	a5,a5,965 # ffffffffc0206477 <end+0x3ff>
ffffffffc02000ba:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000bc:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c0:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c2:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c6:	95be                	add	a1,a1,a5
ffffffffc02000c8:	85a9                	srai	a1,a1,0xa
ffffffffc02000ca:	00001517          	auipc	a0,0x1
ffffffffc02000ce:	6b650513          	addi	a0,a0,1718 # ffffffffc0201780 <etext+0xa4>
}
ffffffffc02000d2:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d4:	a895                	j	ffffffffc0200148 <cprintf>

ffffffffc02000d6 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d6:	00006517          	auipc	a0,0x6
ffffffffc02000da:	f4250513          	addi	a0,a0,-190 # ffffffffc0206018 <free_area>
ffffffffc02000de:	00006617          	auipc	a2,0x6
ffffffffc02000e2:	f9a60613          	addi	a2,a2,-102 # ffffffffc0206078 <end>
int kern_init(void) {
ffffffffc02000e6:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000e8:	8e09                	sub	a2,a2,a0
ffffffffc02000ea:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ec:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000ee:	5dc010ef          	jal	ffffffffc02016ca <memset>
    dtb_init();
ffffffffc02000f2:	136000ef          	jal	ffffffffc0200228 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f6:	128000ef          	jal	ffffffffc020021e <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fa:	00002517          	auipc	a0,0x2
ffffffffc02000fe:	e1e50513          	addi	a0,a0,-482 # ffffffffc0201f18 <etext+0x83c>
ffffffffc0200102:	07a000ef          	jal	ffffffffc020017c <cputs>

    print_kerninfo();
ffffffffc0200106:	f45ff0ef          	jal	ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010a:	70f000ef          	jal	ffffffffc0201018 <pmm_init>

    /* do nothing */
    while (1)
ffffffffc020010e:	a001                	j	ffffffffc020010e <kern_init+0x38>

ffffffffc0200110 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200110:	1101                	addi	sp,sp,-32
ffffffffc0200112:	ec06                	sd	ra,24(sp)
ffffffffc0200114:	e42e                	sd	a1,8(sp)
    cons_putc(c);
ffffffffc0200116:	10a000ef          	jal	ffffffffc0200220 <cons_putc>
    (*cnt) ++;
ffffffffc020011a:	65a2                	ld	a1,8(sp)
}
ffffffffc020011c:	60e2                	ld	ra,24(sp)
    (*cnt) ++;
ffffffffc020011e:	419c                	lw	a5,0(a1)
ffffffffc0200120:	2785                	addiw	a5,a5,1
ffffffffc0200122:	c19c                	sw	a5,0(a1)
}
ffffffffc0200124:	6105                	addi	sp,sp,32
ffffffffc0200126:	8082                	ret

ffffffffc0200128 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200128:	1101                	addi	sp,sp,-32
ffffffffc020012a:	862a                	mv	a2,a0
ffffffffc020012c:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020012e:	00000517          	auipc	a0,0x0
ffffffffc0200132:	fe250513          	addi	a0,a0,-30 # ffffffffc0200110 <cputch>
ffffffffc0200136:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200138:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020013a:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020013c:	17e010ef          	jal	ffffffffc02012ba <vprintfmt>
    return cnt;
}
ffffffffc0200140:	60e2                	ld	ra,24(sp)
ffffffffc0200142:	4532                	lw	a0,12(sp)
ffffffffc0200144:	6105                	addi	sp,sp,32
ffffffffc0200146:	8082                	ret

ffffffffc0200148 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc0200148:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020014a:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
ffffffffc020014e:	f42e                	sd	a1,40(sp)
ffffffffc0200150:	f832                	sd	a2,48(sp)
ffffffffc0200152:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200154:	862a                	mv	a2,a0
ffffffffc0200156:	004c                	addi	a1,sp,4
ffffffffc0200158:	00000517          	auipc	a0,0x0
ffffffffc020015c:	fb850513          	addi	a0,a0,-72 # ffffffffc0200110 <cputch>
ffffffffc0200160:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc0200162:	ec06                	sd	ra,24(sp)
ffffffffc0200164:	e0ba                	sd	a4,64(sp)
ffffffffc0200166:	e4be                	sd	a5,72(sp)
ffffffffc0200168:	e8c2                	sd	a6,80(sp)
ffffffffc020016a:	ecc6                	sd	a7,88(sp)
    int cnt = 0;
ffffffffc020016c:	c202                	sw	zero,4(sp)
    va_start(ap, fmt);
ffffffffc020016e:	e41a                	sd	t1,8(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200170:	14a010ef          	jal	ffffffffc02012ba <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200174:	60e2                	ld	ra,24(sp)
ffffffffc0200176:	4512                	lw	a0,4(sp)
ffffffffc0200178:	6125                	addi	sp,sp,96
ffffffffc020017a:	8082                	ret

ffffffffc020017c <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc020017c:	1101                	addi	sp,sp,-32
ffffffffc020017e:	e822                	sd	s0,16(sp)
ffffffffc0200180:	ec06                	sd	ra,24(sp)
ffffffffc0200182:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200184:	00054503          	lbu	a0,0(a0)
ffffffffc0200188:	c51d                	beqz	a0,ffffffffc02001b6 <cputs+0x3a>
ffffffffc020018a:	e426                	sd	s1,8(sp)
ffffffffc020018c:	0405                	addi	s0,s0,1
    int cnt = 0;
ffffffffc020018e:	4481                	li	s1,0
    cons_putc(c);
ffffffffc0200190:	090000ef          	jal	ffffffffc0200220 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200194:	00044503          	lbu	a0,0(s0)
ffffffffc0200198:	0405                	addi	s0,s0,1
ffffffffc020019a:	87a6                	mv	a5,s1
    (*cnt) ++;
ffffffffc020019c:	2485                	addiw	s1,s1,1
    while ((c = *str ++) != '\0') {
ffffffffc020019e:	f96d                	bnez	a0,ffffffffc0200190 <cputs+0x14>
    cons_putc(c);
ffffffffc02001a0:	4529                	li	a0,10
    (*cnt) ++;
ffffffffc02001a2:	0027841b          	addiw	s0,a5,2
ffffffffc02001a6:	64a2                	ld	s1,8(sp)
    cons_putc(c);
ffffffffc02001a8:	078000ef          	jal	ffffffffc0200220 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001ac:	60e2                	ld	ra,24(sp)
ffffffffc02001ae:	8522                	mv	a0,s0
ffffffffc02001b0:	6442                	ld	s0,16(sp)
ffffffffc02001b2:	6105                	addi	sp,sp,32
ffffffffc02001b4:	8082                	ret
    cons_putc(c);
ffffffffc02001b6:	4529                	li	a0,10
ffffffffc02001b8:	068000ef          	jal	ffffffffc0200220 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc02001bc:	4405                	li	s0,1
}
ffffffffc02001be:	60e2                	ld	ra,24(sp)
ffffffffc02001c0:	8522                	mv	a0,s0
ffffffffc02001c2:	6442                	ld	s0,16(sp)
ffffffffc02001c4:	6105                	addi	sp,sp,32
ffffffffc02001c6:	8082                	ret

ffffffffc02001c8 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001c8:	00006317          	auipc	t1,0x6
ffffffffc02001cc:	e6832303          	lw	t1,-408(t1) # ffffffffc0206030 <is_panic>
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001d0:	715d                	addi	sp,sp,-80
ffffffffc02001d2:	ec06                	sd	ra,24(sp)
ffffffffc02001d4:	f436                	sd	a3,40(sp)
ffffffffc02001d6:	f83a                	sd	a4,48(sp)
ffffffffc02001d8:	fc3e                	sd	a5,56(sp)
ffffffffc02001da:	e0c2                	sd	a6,64(sp)
ffffffffc02001dc:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001de:	00030363          	beqz	t1,ffffffffc02001e4 <__panic+0x1c>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001e2:	a001                	j	ffffffffc02001e2 <__panic+0x1a>
    is_panic = 1;
ffffffffc02001e4:	4705                	li	a4,1
    va_start(ap, fmt);
ffffffffc02001e6:	103c                	addi	a5,sp,40
ffffffffc02001e8:	e822                	sd	s0,16(sp)
ffffffffc02001ea:	8432                	mv	s0,a2
ffffffffc02001ec:	862e                	mv	a2,a1
ffffffffc02001ee:	85aa                	mv	a1,a0
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001f0:	00001517          	auipc	a0,0x1
ffffffffc02001f4:	5c050513          	addi	a0,a0,1472 # ffffffffc02017b0 <etext+0xd4>
    is_panic = 1;
ffffffffc02001f8:	00006697          	auipc	a3,0x6
ffffffffc02001fc:	e2e6ac23          	sw	a4,-456(a3) # ffffffffc0206030 <is_panic>
    va_start(ap, fmt);
ffffffffc0200200:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200202:	f47ff0ef          	jal	ffffffffc0200148 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200206:	65a2                	ld	a1,8(sp)
ffffffffc0200208:	8522                	mv	a0,s0
ffffffffc020020a:	f1fff0ef          	jal	ffffffffc0200128 <vcprintf>
    cprintf("\n");
ffffffffc020020e:	00001517          	auipc	a0,0x1
ffffffffc0200212:	5c250513          	addi	a0,a0,1474 # ffffffffc02017d0 <etext+0xf4>
ffffffffc0200216:	f33ff0ef          	jal	ffffffffc0200148 <cprintf>
ffffffffc020021a:	6442                	ld	s0,16(sp)
ffffffffc020021c:	b7d9                	j	ffffffffc02001e2 <__panic+0x1a>

ffffffffc020021e <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020021e:	8082                	ret

ffffffffc0200220 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200220:	0ff57513          	zext.b	a0,a0
ffffffffc0200224:	3fc0106f          	j	ffffffffc0201620 <sbi_console_putchar>

ffffffffc0200228 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200228:	7179                	addi	sp,sp,-48
    cprintf("DTB Init\n");
ffffffffc020022a:	00001517          	auipc	a0,0x1
ffffffffc020022e:	5ae50513          	addi	a0,a0,1454 # ffffffffc02017d8 <etext+0xfc>
void dtb_init(void) {
ffffffffc0200232:	f406                	sd	ra,40(sp)
ffffffffc0200234:	f022                	sd	s0,32(sp)
    cprintf("DTB Init\n");
ffffffffc0200236:	f13ff0ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc020023a:	00006597          	auipc	a1,0x6
ffffffffc020023e:	dc65b583          	ld	a1,-570(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc0200242:	00001517          	auipc	a0,0x1
ffffffffc0200246:	5a650513          	addi	a0,a0,1446 # ffffffffc02017e8 <etext+0x10c>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020024a:	00006417          	auipc	s0,0x6
ffffffffc020024e:	dbe40413          	addi	s0,s0,-578 # ffffffffc0206008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200252:	ef7ff0ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200256:	600c                	ld	a1,0(s0)
ffffffffc0200258:	00001517          	auipc	a0,0x1
ffffffffc020025c:	5a050513          	addi	a0,a0,1440 # ffffffffc02017f8 <etext+0x11c>
ffffffffc0200260:	ee9ff0ef          	jal	ffffffffc0200148 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200264:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200266:	00001517          	auipc	a0,0x1
ffffffffc020026a:	5aa50513          	addi	a0,a0,1450 # ffffffffc0201810 <etext+0x134>
    if (boot_dtb == 0) {
ffffffffc020026e:	10070163          	beqz	a4,ffffffffc0200370 <dtb_init+0x148>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200272:	57f5                	li	a5,-3
ffffffffc0200274:	07fa                	slli	a5,a5,0x1e
ffffffffc0200276:	973e                	add	a4,a4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200278:	431c                	lw	a5,0(a4)
    if (magic != 0xd00dfeed) {
ffffffffc020027a:	d00e06b7          	lui	a3,0xd00e0
ffffffffc020027e:	eed68693          	addi	a3,a3,-275 # ffffffffd00dfeed <end+0xfed9e75>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200282:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200286:	0187961b          	slliw	a2,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020028a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020028e:	0ff5f593          	zext.b	a1,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200292:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200296:	05c2                	slli	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200298:	8e49                	or	a2,a2,a0
ffffffffc020029a:	0ff7f793          	zext.b	a5,a5
ffffffffc020029e:	8dd1                	or	a1,a1,a2
ffffffffc02002a0:	07a2                	slli	a5,a5,0x8
ffffffffc02002a2:	8ddd                	or	a1,a1,a5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a4:	00ff0837          	lui	a6,0xff0
    if (magic != 0xd00dfeed) {
ffffffffc02002a8:	0cd59863          	bne	a1,a3,ffffffffc0200378 <dtb_init+0x150>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002ac:	4710                	lw	a2,8(a4)
ffffffffc02002ae:	4754                	lw	a3,12(a4)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02002b0:	e84a                	sd	s2,16(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002b2:	0086541b          	srliw	s0,a2,0x8
ffffffffc02002b6:	0086d79b          	srliw	a5,a3,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ba:	01865e1b          	srliw	t3,a2,0x18
ffffffffc02002be:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002c2:	0186151b          	slliw	a0,a2,0x18
ffffffffc02002c6:	0186959b          	slliw	a1,a3,0x18
ffffffffc02002ca:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ce:	0106561b          	srliw	a2,a2,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002d2:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d6:	0106d69b          	srliw	a3,a3,0x10
ffffffffc02002da:	01c56533          	or	a0,a0,t3
ffffffffc02002de:	0115e5b3          	or	a1,a1,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e2:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e6:	0ff67613          	zext.b	a2,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ea:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ee:	0ff6f693          	zext.b	a3,a3
ffffffffc02002f2:	8c49                	or	s0,s0,a0
ffffffffc02002f4:	0622                	slli	a2,a2,0x8
ffffffffc02002f6:	8fcd                	or	a5,a5,a1
ffffffffc02002f8:	06a2                	slli	a3,a3,0x8
ffffffffc02002fa:	8c51                	or	s0,s0,a2
ffffffffc02002fc:	8fd5                	or	a5,a5,a3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02002fe:	1402                	slli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200300:	1782                	slli	a5,a5,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200302:	9001                	srli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200304:	9381                	srli	a5,a5,0x20
ffffffffc0200306:	ec26                	sd	s1,24(sp)
    int in_memory_node = 0;
ffffffffc0200308:	4301                	li	t1,0
        switch (token) {
ffffffffc020030a:	488d                	li	a7,3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020030c:	943a                	add	s0,s0,a4
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020030e:	00e78933          	add	s2,a5,a4
        switch (token) {
ffffffffc0200312:	4e05                	li	t3,1
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200314:	4018                	lw	a4,0(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200316:	0087579b          	srliw	a5,a4,0x8
ffffffffc020031a:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020031e:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200322:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200326:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020032a:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020032e:	8ed1                	or	a3,a3,a2
ffffffffc0200330:	0ff77713          	zext.b	a4,a4
ffffffffc0200334:	8fd5                	or	a5,a5,a3
ffffffffc0200336:	0722                	slli	a4,a4,0x8
ffffffffc0200338:	8fd9                	or	a5,a5,a4
        switch (token) {
ffffffffc020033a:	05178763          	beq	a5,a7,ffffffffc0200388 <dtb_init+0x160>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020033e:	0411                	addi	s0,s0,4
        switch (token) {
ffffffffc0200340:	00f8e963          	bltu	a7,a5,ffffffffc0200352 <dtb_init+0x12a>
ffffffffc0200344:	07c78d63          	beq	a5,t3,ffffffffc02003be <dtb_init+0x196>
ffffffffc0200348:	4709                	li	a4,2
ffffffffc020034a:	00e79763          	bne	a5,a4,ffffffffc0200358 <dtb_init+0x130>
ffffffffc020034e:	4301                	li	t1,0
ffffffffc0200350:	b7d1                	j	ffffffffc0200314 <dtb_init+0xec>
ffffffffc0200352:	4711                	li	a4,4
ffffffffc0200354:	fce780e3          	beq	a5,a4,ffffffffc0200314 <dtb_init+0xec>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200358:	00001517          	auipc	a0,0x1
ffffffffc020035c:	58050513          	addi	a0,a0,1408 # ffffffffc02018d8 <etext+0x1fc>
ffffffffc0200360:	de9ff0ef          	jal	ffffffffc0200148 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200364:	64e2                	ld	s1,24(sp)
ffffffffc0200366:	6942                	ld	s2,16(sp)
ffffffffc0200368:	00001517          	auipc	a0,0x1
ffffffffc020036c:	5a850513          	addi	a0,a0,1448 # ffffffffc0201910 <etext+0x234>
}
ffffffffc0200370:	7402                	ld	s0,32(sp)
ffffffffc0200372:	70a2                	ld	ra,40(sp)
ffffffffc0200374:	6145                	addi	sp,sp,48
    cprintf("DTB init completed\n");
ffffffffc0200376:	bbc9                	j	ffffffffc0200148 <cprintf>
}
ffffffffc0200378:	7402                	ld	s0,32(sp)
ffffffffc020037a:	70a2                	ld	ra,40(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020037c:	00001517          	auipc	a0,0x1
ffffffffc0200380:	4b450513          	addi	a0,a0,1204 # ffffffffc0201830 <etext+0x154>
}
ffffffffc0200384:	6145                	addi	sp,sp,48
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200386:	b3c9                	j	ffffffffc0200148 <cprintf>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200388:	4058                	lw	a4,4(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020038a:	0087579b          	srliw	a5,a4,0x8
ffffffffc020038e:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200392:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200396:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020039a:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020039e:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02003a2:	8ed1                	or	a3,a3,a2
ffffffffc02003a4:	0ff77713          	zext.b	a4,a4
ffffffffc02003a8:	8fd5                	or	a5,a5,a3
ffffffffc02003aa:	0722                	slli	a4,a4,0x8
ffffffffc02003ac:	8fd9                	or	a5,a5,a4
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02003ae:	04031463          	bnez	t1,ffffffffc02003f6 <dtb_init+0x1ce>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02003b2:	1782                	slli	a5,a5,0x20
ffffffffc02003b4:	9381                	srli	a5,a5,0x20
ffffffffc02003b6:	043d                	addi	s0,s0,15
ffffffffc02003b8:	943e                	add	s0,s0,a5
ffffffffc02003ba:	9871                	andi	s0,s0,-4
                break;
ffffffffc02003bc:	bfa1                	j	ffffffffc0200314 <dtb_init+0xec>
                int name_len = strlen(name);
ffffffffc02003be:	8522                	mv	a0,s0
ffffffffc02003c0:	e01a                	sd	t1,0(sp)
ffffffffc02003c2:	278010ef          	jal	ffffffffc020163a <strlen>
ffffffffc02003c6:	84aa                	mv	s1,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003c8:	4619                	li	a2,6
ffffffffc02003ca:	8522                	mv	a0,s0
ffffffffc02003cc:	00001597          	auipc	a1,0x1
ffffffffc02003d0:	48c58593          	addi	a1,a1,1164 # ffffffffc0201858 <etext+0x17c>
ffffffffc02003d4:	2ce010ef          	jal	ffffffffc02016a2 <strncmp>
ffffffffc02003d8:	6302                	ld	t1,0(sp)
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02003da:	0411                	addi	s0,s0,4
ffffffffc02003dc:	0004879b          	sext.w	a5,s1
ffffffffc02003e0:	943e                	add	s0,s0,a5
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003e2:	00153513          	seqz	a0,a0
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02003e6:	9871                	andi	s0,s0,-4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003e8:	00a36333          	or	t1,t1,a0
                break;
ffffffffc02003ec:	00ff0837          	lui	a6,0xff0
ffffffffc02003f0:	488d                	li	a7,3
ffffffffc02003f2:	4e05                	li	t3,1
ffffffffc02003f4:	b705                	j	ffffffffc0200314 <dtb_init+0xec>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02003f6:	4418                	lw	a4,8(s0)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02003f8:	00001597          	auipc	a1,0x1
ffffffffc02003fc:	46858593          	addi	a1,a1,1128 # ffffffffc0201860 <etext+0x184>
ffffffffc0200400:	e43e                	sd	a5,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200402:	0087551b          	srliw	a0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200406:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020040a:	0187169b          	slliw	a3,a4,0x18
ffffffffc020040e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200412:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200416:	01057533          	and	a0,a0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020041a:	8ed1                	or	a3,a3,a2
ffffffffc020041c:	0ff77713          	zext.b	a4,a4
ffffffffc0200420:	0722                	slli	a4,a4,0x8
ffffffffc0200422:	8d55                	or	a0,a0,a3
ffffffffc0200424:	8d59                	or	a0,a0,a4
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200426:	1502                	slli	a0,a0,0x20
ffffffffc0200428:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020042a:	954a                	add	a0,a0,s2
ffffffffc020042c:	e01a                	sd	t1,0(sp)
ffffffffc020042e:	240010ef          	jal	ffffffffc020166e <strcmp>
ffffffffc0200432:	67a2                	ld	a5,8(sp)
ffffffffc0200434:	473d                	li	a4,15
ffffffffc0200436:	6302                	ld	t1,0(sp)
ffffffffc0200438:	00ff0837          	lui	a6,0xff0
ffffffffc020043c:	488d                	li	a7,3
ffffffffc020043e:	4e05                	li	t3,1
ffffffffc0200440:	f6f779e3          	bgeu	a4,a5,ffffffffc02003b2 <dtb_init+0x18a>
ffffffffc0200444:	f53d                	bnez	a0,ffffffffc02003b2 <dtb_init+0x18a>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200446:	00c43683          	ld	a3,12(s0)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc020044a:	01443703          	ld	a4,20(s0)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020044e:	00001517          	auipc	a0,0x1
ffffffffc0200452:	41a50513          	addi	a0,a0,1050 # ffffffffc0201868 <etext+0x18c>
           fdt32_to_cpu(x >> 32);
ffffffffc0200456:	4206d793          	srai	a5,a3,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020045a:	0087d31b          	srliw	t1,a5,0x8
ffffffffc020045e:	00871f93          	slli	t6,a4,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200462:	42075893          	srai	a7,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200466:	0187df1b          	srliw	t5,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020046a:	0187959b          	slliw	a1,a5,0x18
ffffffffc020046e:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200472:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200476:	420fd613          	srai	a2,t6,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020047a:	0188de9b          	srliw	t4,a7,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020047e:	01037333          	and	t1,t1,a6
ffffffffc0200482:	01889e1b          	slliw	t3,a7,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200486:	01e5e5b3          	or	a1,a1,t5
ffffffffc020048a:	0ff7f793          	zext.b	a5,a5
ffffffffc020048e:	01de6e33          	or	t3,t3,t4
ffffffffc0200492:	0065e5b3          	or	a1,a1,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200496:	01067633          	and	a2,a2,a6
ffffffffc020049a:	0086d31b          	srliw	t1,a3,0x8
ffffffffc020049e:	0087541b          	srliw	s0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004a2:	07a2                	slli	a5,a5,0x8
ffffffffc02004a4:	0108d89b          	srliw	a7,a7,0x10
ffffffffc02004a8:	0186df1b          	srliw	t5,a3,0x18
ffffffffc02004ac:	01875e9b          	srliw	t4,a4,0x18
ffffffffc02004b0:	8ddd                	or	a1,a1,a5
ffffffffc02004b2:	01c66633          	or	a2,a2,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b6:	0186979b          	slliw	a5,a3,0x18
ffffffffc02004ba:	01871e1b          	slliw	t3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004be:	0ff8f893          	zext.b	a7,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c2:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c6:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004ca:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ce:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004d2:	01037333          	and	t1,t1,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d6:	08a2                	slli	a7,a7,0x8
ffffffffc02004d8:	01e7e7b3          	or	a5,a5,t5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004dc:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004e0:	0ff6f693          	zext.b	a3,a3
ffffffffc02004e4:	01de6833          	or	a6,t3,t4
ffffffffc02004e8:	0ff77713          	zext.b	a4,a4
ffffffffc02004ec:	01166633          	or	a2,a2,a7
ffffffffc02004f0:	0067e7b3          	or	a5,a5,t1
ffffffffc02004f4:	06a2                	slli	a3,a3,0x8
ffffffffc02004f6:	01046433          	or	s0,s0,a6
ffffffffc02004fa:	0722                	slli	a4,a4,0x8
ffffffffc02004fc:	8fd5                	or	a5,a5,a3
ffffffffc02004fe:	8c59                	or	s0,s0,a4
           fdt32_to_cpu(x >> 32);
ffffffffc0200500:	1582                	slli	a1,a1,0x20
ffffffffc0200502:	1602                	slli	a2,a2,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200504:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200506:	9201                	srli	a2,a2,0x20
ffffffffc0200508:	9181                	srli	a1,a1,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020050a:	1402                	slli	s0,s0,0x20
ffffffffc020050c:	00b7e4b3          	or	s1,a5,a1
ffffffffc0200510:	8c51                	or	s0,s0,a2
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200512:	c37ff0ef          	jal	ffffffffc0200148 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200516:	85a6                	mv	a1,s1
ffffffffc0200518:	00001517          	auipc	a0,0x1
ffffffffc020051c:	37050513          	addi	a0,a0,880 # ffffffffc0201888 <etext+0x1ac>
ffffffffc0200520:	c29ff0ef          	jal	ffffffffc0200148 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200524:	01445613          	srli	a2,s0,0x14
ffffffffc0200528:	85a2                	mv	a1,s0
ffffffffc020052a:	00001517          	auipc	a0,0x1
ffffffffc020052e:	37650513          	addi	a0,a0,886 # ffffffffc02018a0 <etext+0x1c4>
ffffffffc0200532:	c17ff0ef          	jal	ffffffffc0200148 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200536:	009405b3          	add	a1,s0,s1
ffffffffc020053a:	15fd                	addi	a1,a1,-1
ffffffffc020053c:	00001517          	auipc	a0,0x1
ffffffffc0200540:	38450513          	addi	a0,a0,900 # ffffffffc02018c0 <etext+0x1e4>
ffffffffc0200544:	c05ff0ef          	jal	ffffffffc0200148 <cprintf>
        memory_base = mem_base;
ffffffffc0200548:	00006797          	auipc	a5,0x6
ffffffffc020054c:	ae97bc23          	sd	s1,-1288(a5) # ffffffffc0206040 <memory_base>
        memory_size = mem_size;
ffffffffc0200550:	00006797          	auipc	a5,0x6
ffffffffc0200554:	ae87b423          	sd	s0,-1304(a5) # ffffffffc0206038 <memory_size>
ffffffffc0200558:	b531                	j	ffffffffc0200364 <dtb_init+0x13c>

ffffffffc020055a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020055a:	00006517          	auipc	a0,0x6
ffffffffc020055e:	ae653503          	ld	a0,-1306(a0) # ffffffffc0206040 <memory_base>
ffffffffc0200562:	8082                	ret

ffffffffc0200564 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc0200564:	00006517          	auipc	a0,0x6
ffffffffc0200568:	ad453503          	ld	a0,-1324(a0) # ffffffffc0206038 <memory_size>
ffffffffc020056c:	8082                	ret

ffffffffc020056e <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc020056e:	00006797          	auipc	a5,0x6
ffffffffc0200572:	aaa78793          	addi	a5,a5,-1366 # ffffffffc0206018 <free_area>
ffffffffc0200576:	e79c                	sd	a5,8(a5)
ffffffffc0200578:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc020057a:	0007a823          	sw	zero,16(a5)
}
ffffffffc020057e:	8082                	ret

ffffffffc0200580 <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200580:	00006517          	auipc	a0,0x6
ffffffffc0200584:	aa856503          	lwu	a0,-1368(a0) # ffffffffc0206028 <free_area+0x10>
ffffffffc0200588:	8082                	ret

ffffffffc020058a <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc020058a:	c569                	beqz	a0,ffffffffc0200654 <best_fit_alloc_pages+0xca>
    if (n > nr_free) {
ffffffffc020058c:	00006897          	auipc	a7,0x6
ffffffffc0200590:	a9c8a883          	lw	a7,-1380(a7) # ffffffffc0206028 <free_area+0x10>
ffffffffc0200594:	00006597          	auipc	a1,0x6
ffffffffc0200598:	a8458593          	addi	a1,a1,-1404 # ffffffffc0206018 <free_area>
ffffffffc020059c:	02089793          	slli	a5,a7,0x20
ffffffffc02005a0:	9381                	srli	a5,a5,0x20
ffffffffc02005a2:	0aa7e663          	bltu	a5,a0,ffffffffc020064e <best_fit_alloc_pages+0xc4>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc02005a6:	659c                	ld	a5,8(a1)
    struct Page *page = NULL;
ffffffffc02005a8:	4681                	li	a3,0
    while ((le = list_next(le)) != &free_list) {
ffffffffc02005aa:	06b78363          	beq	a5,a1,ffffffffc0200610 <best_fit_alloc_pages+0x86>
        if (p->property >= n &&
ffffffffc02005ae:	ff87a703          	lw	a4,-8(a5)
ffffffffc02005b2:	02071613          	slli	a2,a4,0x20
ffffffffc02005b6:	9201                	srli	a2,a2,0x20
ffffffffc02005b8:	02a66663          	bltu	a2,a0,ffffffffc02005e4 <best_fit_alloc_pages+0x5a>
        struct Page *p = le2page(le, page_link);
ffffffffc02005bc:	fe878613          	addi	a2,a5,-24
        if (p->property >= n &&
ffffffffc02005c0:	cab1                	beqz	a3,ffffffffc0200614 <best_fit_alloc_pages+0x8a>
            (page == NULL || p->property < page->property)) {
ffffffffc02005c2:	0106a803          	lw	a6,16(a3)
ffffffffc02005c6:	05076763          	bltu	a4,a6,ffffffffc0200614 <best_fit_alloc_pages+0x8a>
ffffffffc02005ca:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02005cc:	02b78063          	beq	a5,a1,ffffffffc02005ec <best_fit_alloc_pages+0x62>
        if (p->property >= n &&
ffffffffc02005d0:	ff87a703          	lw	a4,-8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc02005d4:	fe878613          	addi	a2,a5,-24
        if (p->property >= n &&
ffffffffc02005d8:	02071313          	slli	t1,a4,0x20
ffffffffc02005dc:	02035313          	srli	t1,t1,0x20
ffffffffc02005e0:	fea373e3          	bgeu	t1,a0,ffffffffc02005c6 <best_fit_alloc_pages+0x3c>
ffffffffc02005e4:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02005e6:	fcb794e3          	bne	a5,a1,ffffffffc02005ae <best_fit_alloc_pages+0x24>
    if (page != NULL) {
ffffffffc02005ea:	c29d                	beqz	a3,ffffffffc0200610 <best_fit_alloc_pages+0x86>
        if (page->property > n) {
ffffffffc02005ec:	0106a803          	lw	a6,16(a3)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc02005f0:	6e98                	ld	a4,24(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02005f2:	7290                	ld	a2,32(a3)
ffffffffc02005f4:	02081793          	slli	a5,a6,0x20
ffffffffc02005f8:	9381                	srli	a5,a5,0x20
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02005fa:	e710                	sd	a2,8(a4)
    next->prev = prev;
ffffffffc02005fc:	e218                	sd	a4,0(a2)
ffffffffc02005fe:	02f56063          	bltu	a0,a5,ffffffffc020061e <best_fit_alloc_pages+0x94>
        ClearPageProperty(page);
ffffffffc0200602:	669c                	ld	a5,8(a3)
        nr_free -= n;
ffffffffc0200604:	40a888bb          	subw	a7,a7,a0
ffffffffc0200608:	0115a823          	sw	a7,16(a1)
        ClearPageProperty(page);
ffffffffc020060c:	9bf5                	andi	a5,a5,-3
ffffffffc020060e:	e69c                	sd	a5,8(a3)
}
ffffffffc0200610:	8536                	mv	a0,a3
ffffffffc0200612:	8082                	ret
    return listelm->next;
ffffffffc0200614:	679c                	ld	a5,8(a5)
            page = p;
ffffffffc0200616:	86b2                	mv	a3,a2
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200618:	f8b79be3          	bne	a5,a1,ffffffffc02005ae <best_fit_alloc_pages+0x24>
ffffffffc020061c:	b7f9                	j	ffffffffc02005ea <best_fit_alloc_pages+0x60>
            struct Page *p = page + n;
ffffffffc020061e:	00251793          	slli	a5,a0,0x2
ffffffffc0200622:	97aa                	add	a5,a5,a0
ffffffffc0200624:	078e                	slli	a5,a5,0x3
ffffffffc0200626:	97b6                	add	a5,a5,a3
            SetPageProperty(p);
ffffffffc0200628:	0087b303          	ld	t1,8(a5)
            p->property = page->property - n;
ffffffffc020062c:	40a8083b          	subw	a6,a6,a0
ffffffffc0200630:	0107a823          	sw	a6,16(a5)
            SetPageProperty(p);
ffffffffc0200634:	00236813          	ori	a6,t1,2
ffffffffc0200638:	0107b423          	sd	a6,8(a5)
            list_add(prev, &(p->page_link));
ffffffffc020063c:	01878813          	addi	a6,a5,24
    prev->next = next->prev = elm;
ffffffffc0200640:	01063023          	sd	a6,0(a2)
ffffffffc0200644:	01073423          	sd	a6,8(a4)
    elm->next = next;
ffffffffc0200648:	f390                	sd	a2,32(a5)
    elm->prev = prev;
ffffffffc020064a:	ef98                	sd	a4,24(a5)
}
ffffffffc020064c:	bf5d                	j	ffffffffc0200602 <best_fit_alloc_pages+0x78>
        return NULL;
ffffffffc020064e:	4681                	li	a3,0
}
ffffffffc0200650:	8536                	mv	a0,a3
ffffffffc0200652:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc0200654:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200656:	00001697          	auipc	a3,0x1
ffffffffc020065a:	2d268693          	addi	a3,a3,722 # ffffffffc0201928 <etext+0x24c>
ffffffffc020065e:	00001617          	auipc	a2,0x1
ffffffffc0200662:	2d260613          	addi	a2,a2,722 # ffffffffc0201930 <etext+0x254>
ffffffffc0200666:	03000593          	li	a1,48
ffffffffc020066a:	00001517          	auipc	a0,0x1
ffffffffc020066e:	2de50513          	addi	a0,a0,734 # ffffffffc0201948 <etext+0x26c>
best_fit_alloc_pages(size_t n) {
ffffffffc0200672:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200674:	b55ff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc0200678 <best_fit_check>:
    free_page(p1);
    free_page(p2);
}

static void
best_fit_check(void) {
ffffffffc0200678:	711d                	addi	sp,sp,-96
ffffffffc020067a:	e0ca                	sd	s2,64(sp)
    return listelm->next;
ffffffffc020067c:	00006917          	auipc	s2,0x6
ffffffffc0200680:	99c90913          	addi	s2,s2,-1636 # ffffffffc0206018 <free_area>
ffffffffc0200684:	00893783          	ld	a5,8(s2)
ffffffffc0200688:	ec86                	sd	ra,88(sp)
ffffffffc020068a:	e8a2                	sd	s0,80(sp)
ffffffffc020068c:	e4a6                	sd	s1,72(sp)
ffffffffc020068e:	fc4e                	sd	s3,56(sp)
ffffffffc0200690:	f852                	sd	s4,48(sp)
ffffffffc0200692:	f456                	sd	s5,40(sp)
ffffffffc0200694:	f05a                	sd	s6,32(sp)
ffffffffc0200696:	ec5e                	sd	s7,24(sp)
ffffffffc0200698:	e862                	sd	s8,16(sp)
ffffffffc020069a:	e466                	sd	s9,8(sp)
    int score = 0, sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc020069c:	2b278f63          	beq	a5,s2,ffffffffc020095a <best_fit_check+0x2e2>
    int count = 0, total = 0;
ffffffffc02006a0:	4401                	li	s0,0
ffffffffc02006a2:	4481                	li	s1,0
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc02006a4:	ff07b703          	ld	a4,-16(a5)
ffffffffc02006a8:	8b09                	andi	a4,a4,2
ffffffffc02006aa:	2a070c63          	beqz	a4,ffffffffc0200962 <best_fit_check+0x2ea>
        count++, total += p->property;
ffffffffc02006ae:	ff87a703          	lw	a4,-8(a5)
ffffffffc02006b2:	679c                	ld	a5,8(a5)
ffffffffc02006b4:	2485                	addiw	s1,s1,1
ffffffffc02006b6:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02006b8:	ff2796e3          	bne	a5,s2,ffffffffc02006a4 <best_fit_check+0x2c>
    }
    assert(total == nr_free_pages());
ffffffffc02006bc:	89a2                	mv	s3,s0
ffffffffc02006be:	14f000ef          	jal	ffffffffc020100c <nr_free_pages>
ffffffffc02006c2:	39351063          	bne	a0,s3,ffffffffc0200a42 <best_fit_check+0x3ca>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02006c6:	4505                	li	a0,1
ffffffffc02006c8:	12d000ef          	jal	ffffffffc0200ff4 <alloc_pages>
ffffffffc02006cc:	8aaa                	mv	s5,a0
ffffffffc02006ce:	3a050a63          	beqz	a0,ffffffffc0200a82 <best_fit_check+0x40a>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02006d2:	4505                	li	a0,1
ffffffffc02006d4:	121000ef          	jal	ffffffffc0200ff4 <alloc_pages>
ffffffffc02006d8:	89aa                	mv	s3,a0
ffffffffc02006da:	38050463          	beqz	a0,ffffffffc0200a62 <best_fit_check+0x3ea>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02006de:	4505                	li	a0,1
ffffffffc02006e0:	115000ef          	jal	ffffffffc0200ff4 <alloc_pages>
ffffffffc02006e4:	8a2a                	mv	s4,a0
ffffffffc02006e6:	30050e63          	beqz	a0,ffffffffc0200a02 <best_fit_check+0x38a>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02006ea:	40aa87b3          	sub	a5,s5,a0
ffffffffc02006ee:	40a98733          	sub	a4,s3,a0
ffffffffc02006f2:	0017b793          	seqz	a5,a5
ffffffffc02006f6:	00173713          	seqz	a4,a4
ffffffffc02006fa:	8fd9                	or	a5,a5,a4
ffffffffc02006fc:	2e079363          	bnez	a5,ffffffffc02009e2 <best_fit_check+0x36a>
ffffffffc0200700:	2f3a8163          	beq	s5,s3,ffffffffc02009e2 <best_fit_check+0x36a>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200704:	000aa783          	lw	a5,0(s5)
ffffffffc0200708:	26079d63          	bnez	a5,ffffffffc0200982 <best_fit_check+0x30a>
ffffffffc020070c:	0009a783          	lw	a5,0(s3)
ffffffffc0200710:	26079963          	bnez	a5,ffffffffc0200982 <best_fit_check+0x30a>
ffffffffc0200714:	411c                	lw	a5,0(a0)
ffffffffc0200716:	26079663          	bnez	a5,ffffffffc0200982 <best_fit_check+0x30a>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020071a:	00006797          	auipc	a5,0x6
ffffffffc020071e:	9567b783          	ld	a5,-1706(a5) # ffffffffc0206070 <pages>
ffffffffc0200722:	ccccd737          	lui	a4,0xccccd
ffffffffc0200726:	ccd70713          	addi	a4,a4,-819 # ffffffffcccccccd <end+0xcac6c55>
ffffffffc020072a:	02071693          	slli	a3,a4,0x20
ffffffffc020072e:	96ba                	add	a3,a3,a4
ffffffffc0200730:	40fa8733          	sub	a4,s5,a5
ffffffffc0200734:	870d                	srai	a4,a4,0x3
ffffffffc0200736:	02d70733          	mul	a4,a4,a3
ffffffffc020073a:	00002517          	auipc	a0,0x2
ffffffffc020073e:	9c653503          	ld	a0,-1594(a0) # ffffffffc0202100 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200742:	00006697          	auipc	a3,0x6
ffffffffc0200746:	9266b683          	ld	a3,-1754(a3) # ffffffffc0206068 <npage>
ffffffffc020074a:	06b2                	slli	a3,a3,0xc
ffffffffc020074c:	972a                	add	a4,a4,a0

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc020074e:	0732                	slli	a4,a4,0xc
ffffffffc0200750:	26d77963          	bgeu	a4,a3,ffffffffc02009c2 <best_fit_check+0x34a>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200754:	ccccd5b7          	lui	a1,0xccccd
ffffffffc0200758:	ccd58593          	addi	a1,a1,-819 # ffffffffcccccccd <end+0xcac6c55>
ffffffffc020075c:	02059613          	slli	a2,a1,0x20
ffffffffc0200760:	40f98733          	sub	a4,s3,a5
ffffffffc0200764:	962e                	add	a2,a2,a1
ffffffffc0200766:	870d                	srai	a4,a4,0x3
ffffffffc0200768:	02c70733          	mul	a4,a4,a2
ffffffffc020076c:	972a                	add	a4,a4,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc020076e:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200770:	40d77963          	bgeu	a4,a3,ffffffffc0200b82 <best_fit_check+0x50a>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200774:	40fa07b3          	sub	a5,s4,a5
ffffffffc0200778:	878d                	srai	a5,a5,0x3
ffffffffc020077a:	02c787b3          	mul	a5,a5,a2
ffffffffc020077e:	97aa                	add	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0200780:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200782:	3ed7f063          	bgeu	a5,a3,ffffffffc0200b62 <best_fit_check+0x4ea>
    assert(alloc_page() == NULL);
ffffffffc0200786:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200788:	00093c03          	ld	s8,0(s2)
ffffffffc020078c:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc0200790:	00006b17          	auipc	s6,0x6
ffffffffc0200794:	898b2b03          	lw	s6,-1896(s6) # ffffffffc0206028 <free_area+0x10>
    elm->prev = elm->next = elm;
ffffffffc0200798:	01293023          	sd	s2,0(s2)
ffffffffc020079c:	01293423          	sd	s2,8(s2)
    nr_free = 0;
ffffffffc02007a0:	00006797          	auipc	a5,0x6
ffffffffc02007a4:	8807a423          	sw	zero,-1912(a5) # ffffffffc0206028 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02007a8:	04d000ef          	jal	ffffffffc0200ff4 <alloc_pages>
ffffffffc02007ac:	38051b63          	bnez	a0,ffffffffc0200b42 <best_fit_check+0x4ca>
    free_page(p0);
ffffffffc02007b0:	8556                	mv	a0,s5
ffffffffc02007b2:	4585                	li	a1,1
ffffffffc02007b4:	04d000ef          	jal	ffffffffc0201000 <free_pages>
    free_page(p1);
ffffffffc02007b8:	854e                	mv	a0,s3
ffffffffc02007ba:	4585                	li	a1,1
ffffffffc02007bc:	045000ef          	jal	ffffffffc0201000 <free_pages>
    free_page(p2);
ffffffffc02007c0:	8552                	mv	a0,s4
ffffffffc02007c2:	4585                	li	a1,1
ffffffffc02007c4:	03d000ef          	jal	ffffffffc0201000 <free_pages>
    assert(nr_free == 3);
ffffffffc02007c8:	00006717          	auipc	a4,0x6
ffffffffc02007cc:	86072703          	lw	a4,-1952(a4) # ffffffffc0206028 <free_area+0x10>
ffffffffc02007d0:	478d                	li	a5,3
ffffffffc02007d2:	34f71863          	bne	a4,a5,ffffffffc0200b22 <best_fit_check+0x4aa>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02007d6:	4505                	li	a0,1
ffffffffc02007d8:	01d000ef          	jal	ffffffffc0200ff4 <alloc_pages>
ffffffffc02007dc:	89aa                	mv	s3,a0
ffffffffc02007de:	32050263          	beqz	a0,ffffffffc0200b02 <best_fit_check+0x48a>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02007e2:	4505                	li	a0,1
ffffffffc02007e4:	011000ef          	jal	ffffffffc0200ff4 <alloc_pages>
ffffffffc02007e8:	8aaa                	mv	s5,a0
ffffffffc02007ea:	2e050c63          	beqz	a0,ffffffffc0200ae2 <best_fit_check+0x46a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02007ee:	4505                	li	a0,1
ffffffffc02007f0:	005000ef          	jal	ffffffffc0200ff4 <alloc_pages>
ffffffffc02007f4:	8a2a                	mv	s4,a0
ffffffffc02007f6:	2c050663          	beqz	a0,ffffffffc0200ac2 <best_fit_check+0x44a>
    assert(alloc_page() == NULL);
ffffffffc02007fa:	4505                	li	a0,1
ffffffffc02007fc:	7f8000ef          	jal	ffffffffc0200ff4 <alloc_pages>
ffffffffc0200800:	2a051163          	bnez	a0,ffffffffc0200aa2 <best_fit_check+0x42a>
    free_page(p0);
ffffffffc0200804:	4585                	li	a1,1
ffffffffc0200806:	854e                	mv	a0,s3
ffffffffc0200808:	7f8000ef          	jal	ffffffffc0201000 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc020080c:	00893783          	ld	a5,8(s2)
ffffffffc0200810:	19278963          	beq	a5,s2,ffffffffc02009a2 <best_fit_check+0x32a>
    assert((p = alloc_page()) == p0);
ffffffffc0200814:	4505                	li	a0,1
ffffffffc0200816:	7de000ef          	jal	ffffffffc0200ff4 <alloc_pages>
ffffffffc020081a:	8caa                	mv	s9,a0
ffffffffc020081c:	54a99363          	bne	s3,a0,ffffffffc0200d62 <best_fit_check+0x6ea>
    assert(alloc_page() == NULL);
ffffffffc0200820:	4505                	li	a0,1
ffffffffc0200822:	7d2000ef          	jal	ffffffffc0200ff4 <alloc_pages>
ffffffffc0200826:	50051e63          	bnez	a0,ffffffffc0200d42 <best_fit_check+0x6ca>
    assert(nr_free == 0);
ffffffffc020082a:	00005797          	auipc	a5,0x5
ffffffffc020082e:	7fe7a783          	lw	a5,2046(a5) # ffffffffc0206028 <free_area+0x10>
ffffffffc0200832:	4e079863          	bnez	a5,ffffffffc0200d22 <best_fit_check+0x6aa>
    free_page(p);
ffffffffc0200836:	8566                	mv	a0,s9
ffffffffc0200838:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc020083a:	01893023          	sd	s8,0(s2)
ffffffffc020083e:	01793423          	sd	s7,8(s2)
    nr_free = nr_free_store;
ffffffffc0200842:	01692823          	sw	s6,16(s2)
    free_page(p);
ffffffffc0200846:	7ba000ef          	jal	ffffffffc0201000 <free_pages>
    free_page(p1);
ffffffffc020084a:	8556                	mv	a0,s5
ffffffffc020084c:	4585                	li	a1,1
ffffffffc020084e:	7b2000ef          	jal	ffffffffc0201000 <free_pages>
    free_page(p2);
ffffffffc0200852:	8552                	mv	a0,s4
ffffffffc0200854:	4585                	li	a1,1
ffffffffc0200856:	7aa000ef          	jal	ffffffffc0201000 <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc020085a:	4515                	li	a0,5
ffffffffc020085c:	798000ef          	jal	ffffffffc0200ff4 <alloc_pages>
ffffffffc0200860:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200862:	4a050063          	beqz	a0,ffffffffc0200d02 <best_fit_check+0x68a>
    assert(!PageProperty(p0));
ffffffffc0200866:	651c                	ld	a5,8(a0)
ffffffffc0200868:	8b89                	andi	a5,a5,2
ffffffffc020086a:	46079c63          	bnez	a5,ffffffffc0200ce2 <best_fit_check+0x66a>
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc020086e:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200870:	00093b83          	ld	s7,0(s2)
ffffffffc0200874:	00893b03          	ld	s6,8(s2)
ffffffffc0200878:	01293023          	sd	s2,0(s2)
ffffffffc020087c:	01293423          	sd	s2,8(s2)
    assert(alloc_page() == NULL);
ffffffffc0200880:	774000ef          	jal	ffffffffc0200ff4 <alloc_pages>
ffffffffc0200884:	42051f63          	bnez	a0,ffffffffc0200cc2 <best_fit_check+0x64a>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0200888:	4589                	li	a1,2
ffffffffc020088a:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc020088e:	00005c17          	auipc	s8,0x5
ffffffffc0200892:	79ac2c03          	lw	s8,1946(s8) # ffffffffc0206028 <free_area+0x10>
    free_pages(p0 + 4, 1);
ffffffffc0200896:	0a098a93          	addi	s5,s3,160
    nr_free = 0;
ffffffffc020089a:	00005797          	auipc	a5,0x5
ffffffffc020089e:	7807a723          	sw	zero,1934(a5) # ffffffffc0206028 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc02008a2:	75e000ef          	jal	ffffffffc0201000 <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc02008a6:	8556                	mv	a0,s5
ffffffffc02008a8:	4585                	li	a1,1
ffffffffc02008aa:	756000ef          	jal	ffffffffc0201000 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc02008ae:	4511                	li	a0,4
ffffffffc02008b0:	744000ef          	jal	ffffffffc0200ff4 <alloc_pages>
ffffffffc02008b4:	3e051763          	bnez	a0,ffffffffc0200ca2 <best_fit_check+0x62a>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc02008b8:	0309b783          	ld	a5,48(s3)
ffffffffc02008bc:	8b89                	andi	a5,a5,2
ffffffffc02008be:	3c078263          	beqz	a5,ffffffffc0200c82 <best_fit_check+0x60a>
ffffffffc02008c2:	0389ac83          	lw	s9,56(s3)
ffffffffc02008c6:	4789                	li	a5,2
ffffffffc02008c8:	3afc9d63          	bne	s9,a5,ffffffffc0200c82 <best_fit_check+0x60a>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc02008cc:	4505                	li	a0,1
ffffffffc02008ce:	726000ef          	jal	ffffffffc0200ff4 <alloc_pages>
ffffffffc02008d2:	8a2a                	mv	s4,a0
ffffffffc02008d4:	38050763          	beqz	a0,ffffffffc0200c62 <best_fit_check+0x5ea>
    assert(alloc_pages(2) != NULL);
ffffffffc02008d8:	8566                	mv	a0,s9
ffffffffc02008da:	71a000ef          	jal	ffffffffc0200ff4 <alloc_pages>
ffffffffc02008de:	36050263          	beqz	a0,ffffffffc0200c42 <best_fit_check+0x5ca>
    assert(p0 + 4 == p1);
ffffffffc02008e2:	354a9063          	bne	s5,s4,ffffffffc0200c22 <best_fit_check+0x5aa>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc02008e6:	854e                	mv	a0,s3
ffffffffc02008e8:	4595                	li	a1,5
ffffffffc02008ea:	716000ef          	jal	ffffffffc0201000 <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02008ee:	4515                	li	a0,5
ffffffffc02008f0:	704000ef          	jal	ffffffffc0200ff4 <alloc_pages>
ffffffffc02008f4:	89aa                	mv	s3,a0
ffffffffc02008f6:	30050663          	beqz	a0,ffffffffc0200c02 <best_fit_check+0x58a>
    assert(alloc_page() == NULL);
ffffffffc02008fa:	4505                	li	a0,1
ffffffffc02008fc:	6f8000ef          	jal	ffffffffc0200ff4 <alloc_pages>
ffffffffc0200900:	2e051163          	bnez	a0,ffffffffc0200be2 <best_fit_check+0x56a>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc0200904:	00005797          	auipc	a5,0x5
ffffffffc0200908:	7247a783          	lw	a5,1828(a5) # ffffffffc0206028 <free_area+0x10>
ffffffffc020090c:	2a079b63          	bnez	a5,ffffffffc0200bc2 <best_fit_check+0x54a>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200910:	854e                	mv	a0,s3
ffffffffc0200912:	4595                	li	a1,5
    nr_free = nr_free_store;
ffffffffc0200914:	01892823          	sw	s8,16(s2)
    free_list = free_list_store;
ffffffffc0200918:	01793023          	sd	s7,0(s2)
ffffffffc020091c:	01693423          	sd	s6,8(s2)
    free_pages(p0, 5);
ffffffffc0200920:	6e0000ef          	jal	ffffffffc0201000 <free_pages>
    return listelm->next;
ffffffffc0200924:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200928:	01278963          	beq	a5,s2,ffffffffc020093a <best_fit_check+0x2c2>
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc020092c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200930:	679c                	ld	a5,8(a5)
ffffffffc0200932:	34fd                	addiw	s1,s1,-1
ffffffffc0200934:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200936:	ff279be3          	bne	a5,s2,ffffffffc020092c <best_fit_check+0x2b4>
    }
    assert(count == 0);
ffffffffc020093a:	26049463          	bnez	s1,ffffffffc0200ba2 <best_fit_check+0x52a>
    assert(total == 0);
ffffffffc020093e:	e075                	bnez	s0,ffffffffc0200a22 <best_fit_check+0x3aa>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
}
ffffffffc0200940:	60e6                	ld	ra,88(sp)
ffffffffc0200942:	6446                	ld	s0,80(sp)
ffffffffc0200944:	64a6                	ld	s1,72(sp)
ffffffffc0200946:	6906                	ld	s2,64(sp)
ffffffffc0200948:	79e2                	ld	s3,56(sp)
ffffffffc020094a:	7a42                	ld	s4,48(sp)
ffffffffc020094c:	7aa2                	ld	s5,40(sp)
ffffffffc020094e:	7b02                	ld	s6,32(sp)
ffffffffc0200950:	6be2                	ld	s7,24(sp)
ffffffffc0200952:	6c42                	ld	s8,16(sp)
ffffffffc0200954:	6ca2                	ld	s9,8(sp)
ffffffffc0200956:	6125                	addi	sp,sp,96
ffffffffc0200958:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc020095a:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc020095c:	4401                	li	s0,0
ffffffffc020095e:	4481                	li	s1,0
ffffffffc0200960:	bbb9                	j	ffffffffc02006be <best_fit_check+0x46>
        assert(PageProperty(p));
ffffffffc0200962:	00001697          	auipc	a3,0x1
ffffffffc0200966:	ffe68693          	addi	a3,a3,-2 # ffffffffc0201960 <etext+0x284>
ffffffffc020096a:	00001617          	auipc	a2,0x1
ffffffffc020096e:	fc660613          	addi	a2,a2,-58 # ffffffffc0201930 <etext+0x254>
ffffffffc0200972:	0c500593          	li	a1,197
ffffffffc0200976:	00001517          	auipc	a0,0x1
ffffffffc020097a:	fd250513          	addi	a0,a0,-46 # ffffffffc0201948 <etext+0x26c>
ffffffffc020097e:	84bff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200982:	00001697          	auipc	a3,0x1
ffffffffc0200986:	09668693          	addi	a3,a3,150 # ffffffffc0201a18 <etext+0x33c>
ffffffffc020098a:	00001617          	auipc	a2,0x1
ffffffffc020098e:	fa660613          	addi	a2,a2,-90 # ffffffffc0201930 <etext+0x254>
ffffffffc0200992:	09400593          	li	a1,148
ffffffffc0200996:	00001517          	auipc	a0,0x1
ffffffffc020099a:	fb250513          	addi	a0,a0,-78 # ffffffffc0201948 <etext+0x26c>
ffffffffc020099e:	82bff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(!list_empty(&free_list));
ffffffffc02009a2:	00001697          	auipc	a3,0x1
ffffffffc02009a6:	13e68693          	addi	a3,a3,318 # ffffffffc0201ae0 <etext+0x404>
ffffffffc02009aa:	00001617          	auipc	a2,0x1
ffffffffc02009ae:	f8660613          	addi	a2,a2,-122 # ffffffffc0201930 <etext+0x254>
ffffffffc02009b2:	0af00593          	li	a1,175
ffffffffc02009b6:	00001517          	auipc	a0,0x1
ffffffffc02009ba:	f9250513          	addi	a0,a0,-110 # ffffffffc0201948 <etext+0x26c>
ffffffffc02009be:	80bff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02009c2:	00001697          	auipc	a3,0x1
ffffffffc02009c6:	09668693          	addi	a3,a3,150 # ffffffffc0201a58 <etext+0x37c>
ffffffffc02009ca:	00001617          	auipc	a2,0x1
ffffffffc02009ce:	f6660613          	addi	a2,a2,-154 # ffffffffc0201930 <etext+0x254>
ffffffffc02009d2:	09600593          	li	a1,150
ffffffffc02009d6:	00001517          	auipc	a0,0x1
ffffffffc02009da:	f7250513          	addi	a0,a0,-142 # ffffffffc0201948 <etext+0x26c>
ffffffffc02009de:	feaff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02009e2:	00001697          	auipc	a3,0x1
ffffffffc02009e6:	00e68693          	addi	a3,a3,14 # ffffffffc02019f0 <etext+0x314>
ffffffffc02009ea:	00001617          	auipc	a2,0x1
ffffffffc02009ee:	f4660613          	addi	a2,a2,-186 # ffffffffc0201930 <etext+0x254>
ffffffffc02009f2:	09300593          	li	a1,147
ffffffffc02009f6:	00001517          	auipc	a0,0x1
ffffffffc02009fa:	f5250513          	addi	a0,a0,-174 # ffffffffc0201948 <etext+0x26c>
ffffffffc02009fe:	fcaff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200a02:	00001697          	auipc	a3,0x1
ffffffffc0200a06:	fce68693          	addi	a3,a3,-50 # ffffffffc02019d0 <etext+0x2f4>
ffffffffc0200a0a:	00001617          	auipc	a2,0x1
ffffffffc0200a0e:	f2660613          	addi	a2,a2,-218 # ffffffffc0201930 <etext+0x254>
ffffffffc0200a12:	09100593          	li	a1,145
ffffffffc0200a16:	00001517          	auipc	a0,0x1
ffffffffc0200a1a:	f3250513          	addi	a0,a0,-206 # ffffffffc0201948 <etext+0x26c>
ffffffffc0200a1e:	faaff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(total == 0);
ffffffffc0200a22:	00001697          	auipc	a3,0x1
ffffffffc0200a26:	1ee68693          	addi	a3,a3,494 # ffffffffc0201c10 <etext+0x534>
ffffffffc0200a2a:	00001617          	auipc	a2,0x1
ffffffffc0200a2e:	f0660613          	addi	a2,a2,-250 # ffffffffc0201930 <etext+0x254>
ffffffffc0200a32:	10700593          	li	a1,263
ffffffffc0200a36:	00001517          	auipc	a0,0x1
ffffffffc0200a3a:	f1250513          	addi	a0,a0,-238 # ffffffffc0201948 <etext+0x26c>
ffffffffc0200a3e:	f8aff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(total == nr_free_pages());
ffffffffc0200a42:	00001697          	auipc	a3,0x1
ffffffffc0200a46:	f2e68693          	addi	a3,a3,-210 # ffffffffc0201970 <etext+0x294>
ffffffffc0200a4a:	00001617          	auipc	a2,0x1
ffffffffc0200a4e:	ee660613          	addi	a2,a2,-282 # ffffffffc0201930 <etext+0x254>
ffffffffc0200a52:	0c800593          	li	a1,200
ffffffffc0200a56:	00001517          	auipc	a0,0x1
ffffffffc0200a5a:	ef250513          	addi	a0,a0,-270 # ffffffffc0201948 <etext+0x26c>
ffffffffc0200a5e:	f6aff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200a62:	00001697          	auipc	a3,0x1
ffffffffc0200a66:	f4e68693          	addi	a3,a3,-178 # ffffffffc02019b0 <etext+0x2d4>
ffffffffc0200a6a:	00001617          	auipc	a2,0x1
ffffffffc0200a6e:	ec660613          	addi	a2,a2,-314 # ffffffffc0201930 <etext+0x254>
ffffffffc0200a72:	09000593          	li	a1,144
ffffffffc0200a76:	00001517          	auipc	a0,0x1
ffffffffc0200a7a:	ed250513          	addi	a0,a0,-302 # ffffffffc0201948 <etext+0x26c>
ffffffffc0200a7e:	f4aff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200a82:	00001697          	auipc	a3,0x1
ffffffffc0200a86:	f0e68693          	addi	a3,a3,-242 # ffffffffc0201990 <etext+0x2b4>
ffffffffc0200a8a:	00001617          	auipc	a2,0x1
ffffffffc0200a8e:	ea660613          	addi	a2,a2,-346 # ffffffffc0201930 <etext+0x254>
ffffffffc0200a92:	08f00593          	li	a1,143
ffffffffc0200a96:	00001517          	auipc	a0,0x1
ffffffffc0200a9a:	eb250513          	addi	a0,a0,-334 # ffffffffc0201948 <etext+0x26c>
ffffffffc0200a9e:	f2aff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200aa2:	00001697          	auipc	a3,0x1
ffffffffc0200aa6:	01668693          	addi	a3,a3,22 # ffffffffc0201ab8 <etext+0x3dc>
ffffffffc0200aaa:	00001617          	auipc	a2,0x1
ffffffffc0200aae:	e8660613          	addi	a2,a2,-378 # ffffffffc0201930 <etext+0x254>
ffffffffc0200ab2:	0ac00593          	li	a1,172
ffffffffc0200ab6:	00001517          	auipc	a0,0x1
ffffffffc0200aba:	e9250513          	addi	a0,a0,-366 # ffffffffc0201948 <etext+0x26c>
ffffffffc0200abe:	f0aff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200ac2:	00001697          	auipc	a3,0x1
ffffffffc0200ac6:	f0e68693          	addi	a3,a3,-242 # ffffffffc02019d0 <etext+0x2f4>
ffffffffc0200aca:	00001617          	auipc	a2,0x1
ffffffffc0200ace:	e6660613          	addi	a2,a2,-410 # ffffffffc0201930 <etext+0x254>
ffffffffc0200ad2:	0aa00593          	li	a1,170
ffffffffc0200ad6:	00001517          	auipc	a0,0x1
ffffffffc0200ada:	e7250513          	addi	a0,a0,-398 # ffffffffc0201948 <etext+0x26c>
ffffffffc0200ade:	eeaff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200ae2:	00001697          	auipc	a3,0x1
ffffffffc0200ae6:	ece68693          	addi	a3,a3,-306 # ffffffffc02019b0 <etext+0x2d4>
ffffffffc0200aea:	00001617          	auipc	a2,0x1
ffffffffc0200aee:	e4660613          	addi	a2,a2,-442 # ffffffffc0201930 <etext+0x254>
ffffffffc0200af2:	0a900593          	li	a1,169
ffffffffc0200af6:	00001517          	auipc	a0,0x1
ffffffffc0200afa:	e5250513          	addi	a0,a0,-430 # ffffffffc0201948 <etext+0x26c>
ffffffffc0200afe:	ecaff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200b02:	00001697          	auipc	a3,0x1
ffffffffc0200b06:	e8e68693          	addi	a3,a3,-370 # ffffffffc0201990 <etext+0x2b4>
ffffffffc0200b0a:	00001617          	auipc	a2,0x1
ffffffffc0200b0e:	e2660613          	addi	a2,a2,-474 # ffffffffc0201930 <etext+0x254>
ffffffffc0200b12:	0a800593          	li	a1,168
ffffffffc0200b16:	00001517          	auipc	a0,0x1
ffffffffc0200b1a:	e3250513          	addi	a0,a0,-462 # ffffffffc0201948 <etext+0x26c>
ffffffffc0200b1e:	eaaff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(nr_free == 3);
ffffffffc0200b22:	00001697          	auipc	a3,0x1
ffffffffc0200b26:	fae68693          	addi	a3,a3,-82 # ffffffffc0201ad0 <etext+0x3f4>
ffffffffc0200b2a:	00001617          	auipc	a2,0x1
ffffffffc0200b2e:	e0660613          	addi	a2,a2,-506 # ffffffffc0201930 <etext+0x254>
ffffffffc0200b32:	0a600593          	li	a1,166
ffffffffc0200b36:	00001517          	auipc	a0,0x1
ffffffffc0200b3a:	e1250513          	addi	a0,a0,-494 # ffffffffc0201948 <etext+0x26c>
ffffffffc0200b3e:	e8aff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200b42:	00001697          	auipc	a3,0x1
ffffffffc0200b46:	f7668693          	addi	a3,a3,-138 # ffffffffc0201ab8 <etext+0x3dc>
ffffffffc0200b4a:	00001617          	auipc	a2,0x1
ffffffffc0200b4e:	de660613          	addi	a2,a2,-538 # ffffffffc0201930 <etext+0x254>
ffffffffc0200b52:	0a100593          	li	a1,161
ffffffffc0200b56:	00001517          	auipc	a0,0x1
ffffffffc0200b5a:	df250513          	addi	a0,a0,-526 # ffffffffc0201948 <etext+0x26c>
ffffffffc0200b5e:	e6aff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200b62:	00001697          	auipc	a3,0x1
ffffffffc0200b66:	f3668693          	addi	a3,a3,-202 # ffffffffc0201a98 <etext+0x3bc>
ffffffffc0200b6a:	00001617          	auipc	a2,0x1
ffffffffc0200b6e:	dc660613          	addi	a2,a2,-570 # ffffffffc0201930 <etext+0x254>
ffffffffc0200b72:	09800593          	li	a1,152
ffffffffc0200b76:	00001517          	auipc	a0,0x1
ffffffffc0200b7a:	dd250513          	addi	a0,a0,-558 # ffffffffc0201948 <etext+0x26c>
ffffffffc0200b7e:	e4aff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200b82:	00001697          	auipc	a3,0x1
ffffffffc0200b86:	ef668693          	addi	a3,a3,-266 # ffffffffc0201a78 <etext+0x39c>
ffffffffc0200b8a:	00001617          	auipc	a2,0x1
ffffffffc0200b8e:	da660613          	addi	a2,a2,-602 # ffffffffc0201930 <etext+0x254>
ffffffffc0200b92:	09700593          	li	a1,151
ffffffffc0200b96:	00001517          	auipc	a0,0x1
ffffffffc0200b9a:	db250513          	addi	a0,a0,-590 # ffffffffc0201948 <etext+0x26c>
ffffffffc0200b9e:	e2aff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(count == 0);
ffffffffc0200ba2:	00001697          	auipc	a3,0x1
ffffffffc0200ba6:	05e68693          	addi	a3,a3,94 # ffffffffc0201c00 <etext+0x524>
ffffffffc0200baa:	00001617          	auipc	a2,0x1
ffffffffc0200bae:	d8660613          	addi	a2,a2,-634 # ffffffffc0201930 <etext+0x254>
ffffffffc0200bb2:	10600593          	li	a1,262
ffffffffc0200bb6:	00001517          	auipc	a0,0x1
ffffffffc0200bba:	d9250513          	addi	a0,a0,-622 # ffffffffc0201948 <etext+0x26c>
ffffffffc0200bbe:	e0aff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(nr_free == 0);
ffffffffc0200bc2:	00001697          	auipc	a3,0x1
ffffffffc0200bc6:	f5668693          	addi	a3,a3,-170 # ffffffffc0201b18 <etext+0x43c>
ffffffffc0200bca:	00001617          	auipc	a2,0x1
ffffffffc0200bce:	d6660613          	addi	a2,a2,-666 # ffffffffc0201930 <etext+0x254>
ffffffffc0200bd2:	0fb00593          	li	a1,251
ffffffffc0200bd6:	00001517          	auipc	a0,0x1
ffffffffc0200bda:	d7250513          	addi	a0,a0,-654 # ffffffffc0201948 <etext+0x26c>
ffffffffc0200bde:	deaff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200be2:	00001697          	auipc	a3,0x1
ffffffffc0200be6:	ed668693          	addi	a3,a3,-298 # ffffffffc0201ab8 <etext+0x3dc>
ffffffffc0200bea:	00001617          	auipc	a2,0x1
ffffffffc0200bee:	d4660613          	addi	a2,a2,-698 # ffffffffc0201930 <etext+0x254>
ffffffffc0200bf2:	0f500593          	li	a1,245
ffffffffc0200bf6:	00001517          	auipc	a0,0x1
ffffffffc0200bfa:	d5250513          	addi	a0,a0,-686 # ffffffffc0201948 <etext+0x26c>
ffffffffc0200bfe:	dcaff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200c02:	00001697          	auipc	a3,0x1
ffffffffc0200c06:	fde68693          	addi	a3,a3,-34 # ffffffffc0201be0 <etext+0x504>
ffffffffc0200c0a:	00001617          	auipc	a2,0x1
ffffffffc0200c0e:	d2660613          	addi	a2,a2,-730 # ffffffffc0201930 <etext+0x254>
ffffffffc0200c12:	0f400593          	li	a1,244
ffffffffc0200c16:	00001517          	auipc	a0,0x1
ffffffffc0200c1a:	d3250513          	addi	a0,a0,-718 # ffffffffc0201948 <etext+0x26c>
ffffffffc0200c1e:	daaff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(p0 + 4 == p1);
ffffffffc0200c22:	00001697          	auipc	a3,0x1
ffffffffc0200c26:	fae68693          	addi	a3,a3,-82 # ffffffffc0201bd0 <etext+0x4f4>
ffffffffc0200c2a:	00001617          	auipc	a2,0x1
ffffffffc0200c2e:	d0660613          	addi	a2,a2,-762 # ffffffffc0201930 <etext+0x254>
ffffffffc0200c32:	0ec00593          	li	a1,236
ffffffffc0200c36:	00001517          	auipc	a0,0x1
ffffffffc0200c3a:	d1250513          	addi	a0,a0,-750 # ffffffffc0201948 <etext+0x26c>
ffffffffc0200c3e:	d8aff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(alloc_pages(2) != NULL);
ffffffffc0200c42:	00001697          	auipc	a3,0x1
ffffffffc0200c46:	f7668693          	addi	a3,a3,-138 # ffffffffc0201bb8 <etext+0x4dc>
ffffffffc0200c4a:	00001617          	auipc	a2,0x1
ffffffffc0200c4e:	ce660613          	addi	a2,a2,-794 # ffffffffc0201930 <etext+0x254>
ffffffffc0200c52:	0eb00593          	li	a1,235
ffffffffc0200c56:	00001517          	auipc	a0,0x1
ffffffffc0200c5a:	cf250513          	addi	a0,a0,-782 # ffffffffc0201948 <etext+0x26c>
ffffffffc0200c5e:	d6aff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200c62:	00001697          	auipc	a3,0x1
ffffffffc0200c66:	f3668693          	addi	a3,a3,-202 # ffffffffc0201b98 <etext+0x4bc>
ffffffffc0200c6a:	00001617          	auipc	a2,0x1
ffffffffc0200c6e:	cc660613          	addi	a2,a2,-826 # ffffffffc0201930 <etext+0x254>
ffffffffc0200c72:	0ea00593          	li	a1,234
ffffffffc0200c76:	00001517          	auipc	a0,0x1
ffffffffc0200c7a:	cd250513          	addi	a0,a0,-814 # ffffffffc0201948 <etext+0x26c>
ffffffffc0200c7e:	d4aff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200c82:	00001697          	auipc	a3,0x1
ffffffffc0200c86:	ee668693          	addi	a3,a3,-282 # ffffffffc0201b68 <etext+0x48c>
ffffffffc0200c8a:	00001617          	auipc	a2,0x1
ffffffffc0200c8e:	ca660613          	addi	a2,a2,-858 # ffffffffc0201930 <etext+0x254>
ffffffffc0200c92:	0e800593          	li	a1,232
ffffffffc0200c96:	00001517          	auipc	a0,0x1
ffffffffc0200c9a:	cb250513          	addi	a0,a0,-846 # ffffffffc0201948 <etext+0x26c>
ffffffffc0200c9e:	d2aff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0200ca2:	00001697          	auipc	a3,0x1
ffffffffc0200ca6:	eae68693          	addi	a3,a3,-338 # ffffffffc0201b50 <etext+0x474>
ffffffffc0200caa:	00001617          	auipc	a2,0x1
ffffffffc0200cae:	c8660613          	addi	a2,a2,-890 # ffffffffc0201930 <etext+0x254>
ffffffffc0200cb2:	0e700593          	li	a1,231
ffffffffc0200cb6:	00001517          	auipc	a0,0x1
ffffffffc0200cba:	c9250513          	addi	a0,a0,-878 # ffffffffc0201948 <etext+0x26c>
ffffffffc0200cbe:	d0aff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200cc2:	00001697          	auipc	a3,0x1
ffffffffc0200cc6:	df668693          	addi	a3,a3,-522 # ffffffffc0201ab8 <etext+0x3dc>
ffffffffc0200cca:	00001617          	auipc	a2,0x1
ffffffffc0200cce:	c6660613          	addi	a2,a2,-922 # ffffffffc0201930 <etext+0x254>
ffffffffc0200cd2:	0db00593          	li	a1,219
ffffffffc0200cd6:	00001517          	auipc	a0,0x1
ffffffffc0200cda:	c7250513          	addi	a0,a0,-910 # ffffffffc0201948 <etext+0x26c>
ffffffffc0200cde:	ceaff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(!PageProperty(p0));
ffffffffc0200ce2:	00001697          	auipc	a3,0x1
ffffffffc0200ce6:	e5668693          	addi	a3,a3,-426 # ffffffffc0201b38 <etext+0x45c>
ffffffffc0200cea:	00001617          	auipc	a2,0x1
ffffffffc0200cee:	c4660613          	addi	a2,a2,-954 # ffffffffc0201930 <etext+0x254>
ffffffffc0200cf2:	0d200593          	li	a1,210
ffffffffc0200cf6:	00001517          	auipc	a0,0x1
ffffffffc0200cfa:	c5250513          	addi	a0,a0,-942 # ffffffffc0201948 <etext+0x26c>
ffffffffc0200cfe:	ccaff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(p0 != NULL);
ffffffffc0200d02:	00001697          	auipc	a3,0x1
ffffffffc0200d06:	e2668693          	addi	a3,a3,-474 # ffffffffc0201b28 <etext+0x44c>
ffffffffc0200d0a:	00001617          	auipc	a2,0x1
ffffffffc0200d0e:	c2660613          	addi	a2,a2,-986 # ffffffffc0201930 <etext+0x254>
ffffffffc0200d12:	0d100593          	li	a1,209
ffffffffc0200d16:	00001517          	auipc	a0,0x1
ffffffffc0200d1a:	c3250513          	addi	a0,a0,-974 # ffffffffc0201948 <etext+0x26c>
ffffffffc0200d1e:	caaff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(nr_free == 0);
ffffffffc0200d22:	00001697          	auipc	a3,0x1
ffffffffc0200d26:	df668693          	addi	a3,a3,-522 # ffffffffc0201b18 <etext+0x43c>
ffffffffc0200d2a:	00001617          	auipc	a2,0x1
ffffffffc0200d2e:	c0660613          	addi	a2,a2,-1018 # ffffffffc0201930 <etext+0x254>
ffffffffc0200d32:	0b500593          	li	a1,181
ffffffffc0200d36:	00001517          	auipc	a0,0x1
ffffffffc0200d3a:	c1250513          	addi	a0,a0,-1006 # ffffffffc0201948 <etext+0x26c>
ffffffffc0200d3e:	c8aff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200d42:	00001697          	auipc	a3,0x1
ffffffffc0200d46:	d7668693          	addi	a3,a3,-650 # ffffffffc0201ab8 <etext+0x3dc>
ffffffffc0200d4a:	00001617          	auipc	a2,0x1
ffffffffc0200d4e:	be660613          	addi	a2,a2,-1050 # ffffffffc0201930 <etext+0x254>
ffffffffc0200d52:	0b300593          	li	a1,179
ffffffffc0200d56:	00001517          	auipc	a0,0x1
ffffffffc0200d5a:	bf250513          	addi	a0,a0,-1038 # ffffffffc0201948 <etext+0x26c>
ffffffffc0200d5e:	c6aff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200d62:	00001697          	auipc	a3,0x1
ffffffffc0200d66:	d9668693          	addi	a3,a3,-618 # ffffffffc0201af8 <etext+0x41c>
ffffffffc0200d6a:	00001617          	auipc	a2,0x1
ffffffffc0200d6e:	bc660613          	addi	a2,a2,-1082 # ffffffffc0201930 <etext+0x254>
ffffffffc0200d72:	0b200593          	li	a1,178
ffffffffc0200d76:	00001517          	auipc	a0,0x1
ffffffffc0200d7a:	bd250513          	addi	a0,a0,-1070 # ffffffffc0201948 <etext+0x26c>
ffffffffc0200d7e:	c4aff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc0200d82 <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc0200d82:	1141                	addi	sp,sp,-16
ffffffffc0200d84:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200d86:	14058e63          	beqz	a1,ffffffffc0200ee2 <best_fit_free_pages+0x160>
    for (; p != base + n; p ++) {
ffffffffc0200d8a:	00259713          	slli	a4,a1,0x2
ffffffffc0200d8e:	972e                	add	a4,a4,a1
ffffffffc0200d90:	070e                	slli	a4,a4,0x3
ffffffffc0200d92:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0200d96:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc0200d98:	cf09                	beqz	a4,ffffffffc0200db2 <best_fit_free_pages+0x30>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200d9a:	6798                	ld	a4,8(a5)
ffffffffc0200d9c:	8b0d                	andi	a4,a4,3
ffffffffc0200d9e:	12071263          	bnez	a4,ffffffffc0200ec2 <best_fit_free_pages+0x140>
        p->flags = 0;
ffffffffc0200da2:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200da6:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0200daa:	02878793          	addi	a5,a5,40
ffffffffc0200dae:	fed796e3          	bne	a5,a3,ffffffffc0200d9a <best_fit_free_pages+0x18>
    SetPageProperty(base);
ffffffffc0200db2:	00853883          	ld	a7,8(a0)
    nr_free += n;
ffffffffc0200db6:	00005717          	auipc	a4,0x5
ffffffffc0200dba:	27272703          	lw	a4,626(a4) # ffffffffc0206028 <free_area+0x10>
ffffffffc0200dbe:	00005697          	auipc	a3,0x5
ffffffffc0200dc2:	25a68693          	addi	a3,a3,602 # ffffffffc0206018 <free_area>
    return list->next == list;
ffffffffc0200dc6:	669c                	ld	a5,8(a3)
    SetPageProperty(base);
ffffffffc0200dc8:	0028e613          	ori	a2,a7,2
    base->property = n;
ffffffffc0200dcc:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200dce:	e510                	sd	a2,8(a0)
    nr_free += n;
ffffffffc0200dd0:	9f2d                	addw	a4,a4,a1
ffffffffc0200dd2:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0200dd4:	0ad78763          	beq	a5,a3,ffffffffc0200e82 <best_fit_free_pages+0x100>
            struct Page* page = le2page(le, page_link);
ffffffffc0200dd8:	fe878713          	addi	a4,a5,-24
ffffffffc0200ddc:	4801                	li	a6,0
ffffffffc0200dde:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0200de2:	00e56a63          	bltu	a0,a4,ffffffffc0200df6 <best_fit_free_pages+0x74>
    return listelm->next;
ffffffffc0200de6:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0200de8:	06d70563          	beq	a4,a3,ffffffffc0200e52 <best_fit_free_pages+0xd0>
    struct Page *p = base;
ffffffffc0200dec:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0200dee:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0200df2:	fee57ae3          	bgeu	a0,a4,ffffffffc0200de6 <best_fit_free_pages+0x64>
ffffffffc0200df6:	00080463          	beqz	a6,ffffffffc0200dfe <best_fit_free_pages+0x7c>
ffffffffc0200dfa:	0066b023          	sd	t1,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200dfe:	0007b803          	ld	a6,0(a5)
    prev->next = next->prev = elm;
ffffffffc0200e02:	e390                	sd	a2,0(a5)
ffffffffc0200e04:	00c83423          	sd	a2,8(a6) # ff0008 <kern_entry-0xffffffffbf20fff8>
    elm->prev = prev;
ffffffffc0200e08:	01053c23          	sd	a6,24(a0)
    elm->next = next;
ffffffffc0200e0c:	f11c                	sd	a5,32(a0)
    if (le != &free_list) {
ffffffffc0200e0e:	02d80063          	beq	a6,a3,ffffffffc0200e2e <best_fit_free_pages+0xac>
        if (p + p->property == base) {
ffffffffc0200e12:	ff882e03          	lw	t3,-8(a6)
        p = le2page(le, page_link);
ffffffffc0200e16:	fe880313          	addi	t1,a6,-24
        if (p + p->property == base) {
ffffffffc0200e1a:	020e1613          	slli	a2,t3,0x20
ffffffffc0200e1e:	9201                	srli	a2,a2,0x20
ffffffffc0200e20:	00261713          	slli	a4,a2,0x2
ffffffffc0200e24:	9732                	add	a4,a4,a2
ffffffffc0200e26:	070e                	slli	a4,a4,0x3
ffffffffc0200e28:	971a                	add	a4,a4,t1
ffffffffc0200e2a:	02e50e63          	beq	a0,a4,ffffffffc0200e66 <best_fit_free_pages+0xe4>
    if (le != &free_list) {
ffffffffc0200e2e:	00d78f63          	beq	a5,a3,ffffffffc0200e4c <best_fit_free_pages+0xca>
        if (base + base->property == p) {
ffffffffc0200e32:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc0200e34:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p) {
ffffffffc0200e38:	02059613          	slli	a2,a1,0x20
ffffffffc0200e3c:	9201                	srli	a2,a2,0x20
ffffffffc0200e3e:	00261713          	slli	a4,a2,0x2
ffffffffc0200e42:	9732                	add	a4,a4,a2
ffffffffc0200e44:	070e                	slli	a4,a4,0x3
ffffffffc0200e46:	972a                	add	a4,a4,a0
ffffffffc0200e48:	04e68a63          	beq	a3,a4,ffffffffc0200e9c <best_fit_free_pages+0x11a>
}
ffffffffc0200e4c:	60a2                	ld	ra,8(sp)
ffffffffc0200e4e:	0141                	addi	sp,sp,16
ffffffffc0200e50:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0200e52:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0200e54:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0200e56:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0200e58:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0200e5a:	8332                	mv	t1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0200e5c:	02d70c63          	beq	a4,a3,ffffffffc0200e94 <best_fit_free_pages+0x112>
ffffffffc0200e60:	4805                	li	a6,1
    struct Page *p = base;
ffffffffc0200e62:	87ba                	mv	a5,a4
ffffffffc0200e64:	b769                	j	ffffffffc0200dee <best_fit_free_pages+0x6c>
            p->property += base->property;
ffffffffc0200e66:	01c585bb          	addw	a1,a1,t3
ffffffffc0200e6a:	feb82c23          	sw	a1,-8(a6)
            ClearPageProperty(base);
ffffffffc0200e6e:	ffd8f893          	andi	a7,a7,-3
ffffffffc0200e72:	01153423          	sd	a7,8(a0)
    prev->next = next;
ffffffffc0200e76:	00f83423          	sd	a5,8(a6)
    next->prev = prev;
ffffffffc0200e7a:	0107b023          	sd	a6,0(a5)
            base = p;
ffffffffc0200e7e:	851a                	mv	a0,t1
ffffffffc0200e80:	b77d                	j	ffffffffc0200e2e <best_fit_free_pages+0xac>
}
ffffffffc0200e82:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0200e84:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc0200e88:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200e8a:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc0200e8c:	e398                	sd	a4,0(a5)
ffffffffc0200e8e:	e798                	sd	a4,8(a5)
}
ffffffffc0200e90:	0141                	addi	sp,sp,16
ffffffffc0200e92:	8082                	ret
    return listelm->prev;
ffffffffc0200e94:	883e                	mv	a6,a5
ffffffffc0200e96:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200e98:	87b6                	mv	a5,a3
ffffffffc0200e9a:	bf95                	j	ffffffffc0200e0e <best_fit_free_pages+0x8c>
            base->property += p->property;
ffffffffc0200e9c:	ff87a683          	lw	a3,-8(a5)
            ClearPageProperty(p);
ffffffffc0200ea0:	ff07b703          	ld	a4,-16(a5)
ffffffffc0200ea4:	0007b803          	ld	a6,0(a5)
ffffffffc0200ea8:	6790                	ld	a2,8(a5)
            base->property += p->property;
ffffffffc0200eaa:	9ead                	addw	a3,a3,a1
ffffffffc0200eac:	c914                	sw	a3,16(a0)
            ClearPageProperty(p);
ffffffffc0200eae:	9b75                	andi	a4,a4,-3
ffffffffc0200eb0:	fee7b823          	sd	a4,-16(a5)
}
ffffffffc0200eb4:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0200eb6:	00c83423          	sd	a2,8(a6)
    next->prev = prev;
ffffffffc0200eba:	01063023          	sd	a6,0(a2)
ffffffffc0200ebe:	0141                	addi	sp,sp,16
ffffffffc0200ec0:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200ec2:	00001697          	auipc	a3,0x1
ffffffffc0200ec6:	d5e68693          	addi	a3,a3,-674 # ffffffffc0201c20 <etext+0x544>
ffffffffc0200eca:	00001617          	auipc	a2,0x1
ffffffffc0200ece:	a6660613          	addi	a2,a2,-1434 # ffffffffc0201930 <etext+0x254>
ffffffffc0200ed2:	05500593          	li	a1,85
ffffffffc0200ed6:	00001517          	auipc	a0,0x1
ffffffffc0200eda:	a7250513          	addi	a0,a0,-1422 # ffffffffc0201948 <etext+0x26c>
ffffffffc0200ede:	aeaff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(n > 0);
ffffffffc0200ee2:	00001697          	auipc	a3,0x1
ffffffffc0200ee6:	a4668693          	addi	a3,a3,-1466 # ffffffffc0201928 <etext+0x24c>
ffffffffc0200eea:	00001617          	auipc	a2,0x1
ffffffffc0200eee:	a4660613          	addi	a2,a2,-1466 # ffffffffc0201930 <etext+0x254>
ffffffffc0200ef2:	05200593          	li	a1,82
ffffffffc0200ef6:	00001517          	auipc	a0,0x1
ffffffffc0200efa:	a5250513          	addi	a0,a0,-1454 # ffffffffc0201948 <etext+0x26c>
ffffffffc0200efe:	acaff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc0200f02 <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc0200f02:	1141                	addi	sp,sp,-16
ffffffffc0200f04:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200f06:	c9e1                	beqz	a1,ffffffffc0200fd6 <best_fit_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc0200f08:	00259713          	slli	a4,a1,0x2
ffffffffc0200f0c:	972e                	add	a4,a4,a1
ffffffffc0200f0e:	070e                	slli	a4,a4,0x3
ffffffffc0200f10:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0200f14:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc0200f16:	cf11                	beqz	a4,ffffffffc0200f32 <best_fit_init_memmap+0x30>
        assert(PageReserved(p));
ffffffffc0200f18:	6798                	ld	a4,8(a5)
ffffffffc0200f1a:	8b05                	andi	a4,a4,1
ffffffffc0200f1c:	cf51                	beqz	a4,ffffffffc0200fb8 <best_fit_init_memmap+0xb6>
        p->flags = p->property = 0;
ffffffffc0200f1e:	0007a823          	sw	zero,16(a5)
ffffffffc0200f22:	0007b423          	sd	zero,8(a5)
ffffffffc0200f26:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0200f2a:	02878793          	addi	a5,a5,40
ffffffffc0200f2e:	fed795e3          	bne	a5,a3,ffffffffc0200f18 <best_fit_init_memmap+0x16>
    SetPageProperty(base);
ffffffffc0200f32:	6510                	ld	a2,8(a0)
    nr_free += n;
ffffffffc0200f34:	00005717          	auipc	a4,0x5
ffffffffc0200f38:	0f472703          	lw	a4,244(a4) # ffffffffc0206028 <free_area+0x10>
ffffffffc0200f3c:	00005697          	auipc	a3,0x5
ffffffffc0200f40:	0dc68693          	addi	a3,a3,220 # ffffffffc0206018 <free_area>
    return list->next == list;
ffffffffc0200f44:	669c                	ld	a5,8(a3)
    SetPageProperty(base);
ffffffffc0200f46:	00266613          	ori	a2,a2,2
    base->property = n;
ffffffffc0200f4a:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200f4c:	e510                	sd	a2,8(a0)
    nr_free += n;
ffffffffc0200f4e:	9f2d                	addw	a4,a4,a1
ffffffffc0200f50:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0200f52:	04d78663          	beq	a5,a3,ffffffffc0200f9e <best_fit_init_memmap+0x9c>
            struct Page* page = le2page(le, page_link);
ffffffffc0200f56:	fe878713          	addi	a4,a5,-24
ffffffffc0200f5a:	4581                	li	a1,0
ffffffffc0200f5c:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0200f60:	00e56a63          	bltu	a0,a4,ffffffffc0200f74 <best_fit_init_memmap+0x72>
    return listelm->next;
ffffffffc0200f64:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0200f66:	02d70263          	beq	a4,a3,ffffffffc0200f8a <best_fit_init_memmap+0x88>
    struct Page *p = base;
ffffffffc0200f6a:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0200f6c:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0200f70:	fee57ae3          	bgeu	a0,a4,ffffffffc0200f64 <best_fit_init_memmap+0x62>
ffffffffc0200f74:	c199                	beqz	a1,ffffffffc0200f7a <best_fit_init_memmap+0x78>
ffffffffc0200f76:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200f7a:	6398                	ld	a4,0(a5)
}
ffffffffc0200f7c:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0200f7e:	e390                	sd	a2,0(a5)
ffffffffc0200f80:	e710                	sd	a2,8(a4)
    elm->prev = prev;
ffffffffc0200f82:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc0200f84:	f11c                	sd	a5,32(a0)
ffffffffc0200f86:	0141                	addi	sp,sp,16
ffffffffc0200f88:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0200f8a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0200f8c:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0200f8e:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0200f90:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0200f92:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0200f94:	00d70e63          	beq	a4,a3,ffffffffc0200fb0 <best_fit_init_memmap+0xae>
ffffffffc0200f98:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc0200f9a:	87ba                	mv	a5,a4
ffffffffc0200f9c:	bfc1                	j	ffffffffc0200f6c <best_fit_init_memmap+0x6a>
}
ffffffffc0200f9e:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0200fa0:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc0200fa4:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200fa6:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc0200fa8:	e398                	sd	a4,0(a5)
ffffffffc0200faa:	e798                	sd	a4,8(a5)
}
ffffffffc0200fac:	0141                	addi	sp,sp,16
ffffffffc0200fae:	8082                	ret
ffffffffc0200fb0:	60a2                	ld	ra,8(sp)
ffffffffc0200fb2:	e290                	sd	a2,0(a3)
ffffffffc0200fb4:	0141                	addi	sp,sp,16
ffffffffc0200fb6:	8082                	ret
        assert(PageReserved(p));
ffffffffc0200fb8:	00001697          	auipc	a3,0x1
ffffffffc0200fbc:	c9068693          	addi	a3,a3,-880 # ffffffffc0201c48 <etext+0x56c>
ffffffffc0200fc0:	00001617          	auipc	a2,0x1
ffffffffc0200fc4:	97060613          	addi	a2,a2,-1680 # ffffffffc0201930 <etext+0x254>
ffffffffc0200fc8:	45dd                	li	a1,23
ffffffffc0200fca:	00001517          	auipc	a0,0x1
ffffffffc0200fce:	97e50513          	addi	a0,a0,-1666 # ffffffffc0201948 <etext+0x26c>
ffffffffc0200fd2:	9f6ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(n > 0);
ffffffffc0200fd6:	00001697          	auipc	a3,0x1
ffffffffc0200fda:	95268693          	addi	a3,a3,-1710 # ffffffffc0201928 <etext+0x24c>
ffffffffc0200fde:	00001617          	auipc	a2,0x1
ffffffffc0200fe2:	95260613          	addi	a2,a2,-1710 # ffffffffc0201930 <etext+0x254>
ffffffffc0200fe6:	45d1                	li	a1,20
ffffffffc0200fe8:	00001517          	auipc	a0,0x1
ffffffffc0200fec:	96050513          	addi	a0,a0,-1696 # ffffffffc0201948 <etext+0x26c>
ffffffffc0200ff0:	9d8ff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc0200ff4 <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc0200ff4:	00005797          	auipc	a5,0x5
ffffffffc0200ff8:	0547b783          	ld	a5,84(a5) # ffffffffc0206048 <pmm_manager>
ffffffffc0200ffc:	6f9c                	ld	a5,24(a5)
ffffffffc0200ffe:	8782                	jr	a5

ffffffffc0201000 <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc0201000:	00005797          	auipc	a5,0x5
ffffffffc0201004:	0487b783          	ld	a5,72(a5) # ffffffffc0206048 <pmm_manager>
ffffffffc0201008:	739c                	ld	a5,32(a5)
ffffffffc020100a:	8782                	jr	a5

ffffffffc020100c <nr_free_pages>:
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
ffffffffc020100c:	00005797          	auipc	a5,0x5
ffffffffc0201010:	03c7b783          	ld	a5,60(a5) # ffffffffc0206048 <pmm_manager>
ffffffffc0201014:	779c                	ld	a5,40(a5)
ffffffffc0201016:	8782                	jr	a5

ffffffffc0201018 <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201018:	00001797          	auipc	a5,0x1
ffffffffc020101c:	f2078793          	addi	a5,a5,-224 # ffffffffc0201f38 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201020:	638c                	ld	a1,0(a5)
    }
    init_memmap(pa2page(freemem), npage - PPN(freemem));
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0201022:	7179                	addi	sp,sp,-48
ffffffffc0201024:	f406                	sd	ra,40(sp)
ffffffffc0201026:	f022                	sd	s0,32(sp)
ffffffffc0201028:	ec26                	sd	s1,24(sp)
ffffffffc020102a:	e84a                	sd	s2,16(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc020102c:	00005417          	auipc	s0,0x5
ffffffffc0201030:	01c40413          	addi	s0,s0,28 # ffffffffc0206048 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201034:	00001517          	auipc	a0,0x1
ffffffffc0201038:	c3c50513          	addi	a0,a0,-964 # ffffffffc0201c70 <etext+0x594>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc020103c:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020103e:	90aff0ef          	jal	ffffffffc0200148 <cprintf>
    pmm_manager->init();
ffffffffc0201042:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201044:	00005497          	auipc	s1,0x5
ffffffffc0201048:	01c48493          	addi	s1,s1,28 # ffffffffc0206060 <va_pa_offset>
    pmm_manager->init();
ffffffffc020104c:	679c                	ld	a5,8(a5)
ffffffffc020104e:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201050:	57f5                	li	a5,-3
ffffffffc0201052:	07fa                	slli	a5,a5,0x1e
ffffffffc0201054:	e09c                	sd	a5,0(s1)
    uint64_t mem_base = get_memory_base();
ffffffffc0201056:	d04ff0ef          	jal	ffffffffc020055a <get_memory_base>
ffffffffc020105a:	e42a                	sd	a0,8(sp)
    uint64_t mem_size = get_memory_size();
ffffffffc020105c:	d08ff0ef          	jal	ffffffffc0200564 <get_memory_size>
    if (mem_base == 0 || mem_size == 0) {
ffffffffc0201060:	65a2                	ld	a1,8(sp)
ffffffffc0201062:	1a058463          	beqz	a1,ffffffffc020120a <pmm_init+0x1f2>
ffffffffc0201066:	1a050263          	beqz	a0,ffffffffc020120a <pmm_init+0x1f2>
    if (mem_base < DRAM_BASE) {
ffffffffc020106a:	800007b7          	lui	a5,0x80000
ffffffffc020106e:	fff7c793          	not	a5,a5
ffffffffc0201072:	18b7f063          	bgeu	a5,a1,ffffffffc02011f2 <pmm_init+0x1da>
    if (mem_size > (uint64_t)-1 - mem_base) {  // 防止 base + size 溢出
ffffffffc0201076:	00a58633          	add	a2,a1,a0
ffffffffc020107a:	16b66063          	bltu	a2,a1,ffffffffc02011da <pmm_init+0x1c2>
    npage = PPN(mem_end);
ffffffffc020107e:	00c65713          	srli	a4,a2,0xc
ffffffffc0201082:	00005797          	auipc	a5,0x5
ffffffffc0201086:	fee7b323          	sd	a4,-26(a5) # ffffffffc0206068 <npage>
    if (npage <= nbase) {
ffffffffc020108a:	00080837          	lui	a6,0x80
ffffffffc020108e:	12e87a63          	bgeu	a6,a4,ffffffffc02011c2 <pmm_init+0x1aa>
    pages = (struct Page *)ROUNDUP((uintptr_t)end, PGSIZE);
ffffffffc0201092:	77fd                	lui	a5,0xfffff
ffffffffc0201094:	00006697          	auipc	a3,0x6
ffffffffc0201098:	fe368693          	addi	a3,a3,-29 # ffffffffc0207077 <end+0xfff>
ffffffffc020109c:	8efd                	and	a3,a3,a5
ffffffffc020109e:	00005917          	auipc	s2,0x5
ffffffffc02010a2:	fd290913          	addi	s2,s2,-46 # ffffffffc0206070 <pages>
ffffffffc02010a6:	00d93023          	sd	a3,0(s2)
    uintptr_t page_array_pa = PADDR((uintptr_t)pages);
ffffffffc02010aa:	c02007b7          	lui	a5,0xc0200
ffffffffc02010ae:	0ef6ee63          	bltu	a3,a5,ffffffffc02011aa <pmm_init+0x192>
        page_array_pa + sizeof(struct Page) * (npage - nbase);
ffffffffc02010b2:	41070833          	sub	a6,a4,a6
    uintptr_t page_array_pa = PADDR((uintptr_t)pages);
ffffffffc02010b6:	609c                	ld	a5,0(s1)
        page_array_pa + sizeof(struct Page) * (npage - nbase);
ffffffffc02010b8:	00281513          	slli	a0,a6,0x2
ffffffffc02010bc:	9542                	add	a0,a0,a6
ffffffffc02010be:	050e                	slli	a0,a0,0x3
    uintptr_t page_array_pa = PADDR((uintptr_t)pages);
ffffffffc02010c0:	40f687b3          	sub	a5,a3,a5
    uintptr_t page_array_end =
ffffffffc02010c4:	97aa                	add	a5,a5,a0
    if (page_array_end > mem_end) {
ffffffffc02010c6:	0cf66663          	bltu	a2,a5,ffffffffc0201192 <pmm_init+0x17a>
ffffffffc02010ca:	00271513          	slli	a0,a4,0x2
ffffffffc02010ce:	953a                	add	a0,a0,a4
ffffffffc02010d0:	fec00837          	lui	a6,0xfec00
ffffffffc02010d4:	050e                	slli	a0,a0,0x3
ffffffffc02010d6:	9836                	add	a6,a6,a3
ffffffffc02010d8:	982a                	add	a6,a6,a0
        SetPageReserved(&pages[i]);
ffffffffc02010da:	4885                	li	a7,1
        pages[i].property = 0;
ffffffffc02010dc:	0006a823          	sw	zero,16(a3)
ffffffffc02010e0:	0006a023          	sw	zero,0(a3)
        SetPageReserved(&pages[i]);
ffffffffc02010e4:	0116b423          	sd	a7,8(a3)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02010e8:	02868693          	addi	a3,a3,40
ffffffffc02010ec:	fed818e3          	bne	a6,a3,ffffffffc02010dc <pmm_init+0xc4>
    uintptr_t freemem = ROUNDUP(page_array_end, PGSIZE);
ffffffffc02010f0:	6505                	lui	a0,0x1
ffffffffc02010f2:	157d                	addi	a0,a0,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc02010f4:	00a786b3          	add	a3,a5,a0
ffffffffc02010f8:	77fd                	lui	a5,0xfffff
ffffffffc02010fa:	8efd                	and	a3,a3,a5
    if (freemem < mem_base) {
ffffffffc02010fc:	08b6e763          	bltu	a3,a1,ffffffffc020118a <pmm_init+0x172>
    cprintf("page_init: memory [0x%016lx, 0x%016lx), free start 0x%016lx, "
ffffffffc0201100:	00001517          	auipc	a0,0x1
ffffffffc0201104:	c9050513          	addi	a0,a0,-880 # ffffffffc0201d90 <etext+0x6b4>
ffffffffc0201108:	e436                	sd	a3,8(sp)
ffffffffc020110a:	83eff0ef          	jal	ffffffffc0200148 <cprintf>
    if (PPN(freemem) >= npage) {
ffffffffc020110e:	66a2                	ld	a3,8(sp)
ffffffffc0201110:	00005597          	auipc	a1,0x5
ffffffffc0201114:	f585b583          	ld	a1,-168(a1) # ffffffffc0206068 <npage>
ffffffffc0201118:	82b1                	srli	a3,a3,0xc
ffffffffc020111a:	12b6f163          	bgeu	a3,a1,ffffffffc020123c <pmm_init+0x224>
    pmm_manager->init_memmap(base, n);
ffffffffc020111e:	6010                	ld	a2,0(s0)
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0201120:	fff80737          	lui	a4,0xfff80
ffffffffc0201124:	9736                	add	a4,a4,a3
ffffffffc0201126:	00093503          	ld	a0,0(s2)
ffffffffc020112a:	00271793          	slli	a5,a4,0x2
ffffffffc020112e:	97ba                	add	a5,a5,a4
ffffffffc0201130:	6a18                	ld	a4,16(a2)
ffffffffc0201132:	078e                	slli	a5,a5,0x3
ffffffffc0201134:	8d95                	sub	a1,a1,a3
ffffffffc0201136:	953e                	add	a0,a0,a5
ffffffffc0201138:	9702                	jalr	a4
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc020113a:	601c                	ld	a5,0(s0)
ffffffffc020113c:	7b9c                	ld	a5,48(a5)
ffffffffc020113e:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201140:	00001517          	auipc	a0,0x1
ffffffffc0201144:	cc050513          	addi	a0,a0,-832 # ffffffffc0201e00 <etext+0x724>
ffffffffc0201148:	800ff0ef          	jal	ffffffffc0200148 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc020114c:	00004597          	auipc	a1,0x4
ffffffffc0201150:	eb458593          	addi	a1,a1,-332 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0201154:	00005797          	auipc	a5,0x5
ffffffffc0201158:	f0b7b223          	sd	a1,-252(a5) # ffffffffc0206058 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc020115c:	c02007b7          	lui	a5,0xc0200
ffffffffc0201160:	0cf5e163          	bltu	a1,a5,ffffffffc0201222 <pmm_init+0x20a>
ffffffffc0201164:	609c                	ld	a5,0(s1)
}
ffffffffc0201166:	7402                	ld	s0,32(sp)
ffffffffc0201168:	70a2                	ld	ra,40(sp)
ffffffffc020116a:	64e2                	ld	s1,24(sp)
ffffffffc020116c:	6942                	ld	s2,16(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc020116e:	40f586b3          	sub	a3,a1,a5
ffffffffc0201172:	00005797          	auipc	a5,0x5
ffffffffc0201176:	ecd7bf23          	sd	a3,-290(a5) # ffffffffc0206050 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020117a:	00001517          	auipc	a0,0x1
ffffffffc020117e:	ca650513          	addi	a0,a0,-858 # ffffffffc0201e20 <etext+0x744>
ffffffffc0201182:	8636                	mv	a2,a3
}
ffffffffc0201184:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201186:	fc3fe06f          	j	ffffffffc0200148 <cprintf>
        freemem = ROUNDUP(mem_base, PGSIZE);
ffffffffc020118a:	952e                	add	a0,a0,a1
ffffffffc020118c:	00f576b3          	and	a3,a0,a5
ffffffffc0201190:	bf85                	j	ffffffffc0201100 <pmm_init+0xe8>
        panic("page_init: Page array exceeds physical memory");
ffffffffc0201192:	00001617          	auipc	a2,0x1
ffffffffc0201196:	bce60613          	addi	a2,a2,-1074 # ffffffffc0201d60 <etext+0x684>
ffffffffc020119a:	06500593          	li	a1,101
ffffffffc020119e:	00001517          	auipc	a0,0x1
ffffffffc02011a2:	b1250513          	addi	a0,a0,-1262 # ffffffffc0201cb0 <etext+0x5d4>
ffffffffc02011a6:	822ff0ef          	jal	ffffffffc02001c8 <__panic>
    uintptr_t page_array_pa = PADDR((uintptr_t)pages);
ffffffffc02011aa:	00001617          	auipc	a2,0x1
ffffffffc02011ae:	b8e60613          	addi	a2,a2,-1138 # ffffffffc0201d38 <etext+0x65c>
ffffffffc02011b2:	06100593          	li	a1,97
ffffffffc02011b6:	00001517          	auipc	a0,0x1
ffffffffc02011ba:	afa50513          	addi	a0,a0,-1286 # ffffffffc0201cb0 <etext+0x5d4>
ffffffffc02011be:	80aff0ef          	jal	ffffffffc02001c8 <__panic>
        panic("page_init: npage <= nbase");
ffffffffc02011c2:	00001617          	auipc	a2,0x1
ffffffffc02011c6:	b5660613          	addi	a2,a2,-1194 # ffffffffc0201d18 <etext+0x63c>
ffffffffc02011ca:	05900593          	li	a1,89
ffffffffc02011ce:	00001517          	auipc	a0,0x1
ffffffffc02011d2:	ae250513          	addi	a0,a0,-1310 # ffffffffc0201cb0 <etext+0x5d4>
ffffffffc02011d6:	ff3fe0ef          	jal	ffffffffc02001c8 <__panic>
        panic("page_init: physical memory range overflows");
ffffffffc02011da:	00001617          	auipc	a2,0x1
ffffffffc02011de:	b0e60613          	addi	a2,a2,-1266 # ffffffffc0201ce8 <etext+0x60c>
ffffffffc02011e2:	05200593          	li	a1,82
ffffffffc02011e6:	00001517          	auipc	a0,0x1
ffffffffc02011ea:	aca50513          	addi	a0,a0,-1334 # ffffffffc0201cb0 <etext+0x5d4>
ffffffffc02011ee:	fdbfe0ef          	jal	ffffffffc02001c8 <__panic>
        panic("page_init: memory base below DRAM_BASE");
ffffffffc02011f2:	00001617          	auipc	a2,0x1
ffffffffc02011f6:	ace60613          	addi	a2,a2,-1330 # ffffffffc0201cc0 <etext+0x5e4>
ffffffffc02011fa:	04f00593          	li	a1,79
ffffffffc02011fe:	00001517          	auipc	a0,0x1
ffffffffc0201202:	ab250513          	addi	a0,a0,-1358 # ffffffffc0201cb0 <etext+0x5d4>
ffffffffc0201206:	fc3fe0ef          	jal	ffffffffc02001c8 <__panic>
        panic("page_init: invalid DTB memory info");
ffffffffc020120a:	00001617          	auipc	a2,0x1
ffffffffc020120e:	a7e60613          	addi	a2,a2,-1410 # ffffffffc0201c88 <etext+0x5ac>
ffffffffc0201212:	04c00593          	li	a1,76
ffffffffc0201216:	00001517          	auipc	a0,0x1
ffffffffc020121a:	a9a50513          	addi	a0,a0,-1382 # ffffffffc0201cb0 <etext+0x5d4>
ffffffffc020121e:	fabfe0ef          	jal	ffffffffc02001c8 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201222:	86ae                	mv	a3,a1
ffffffffc0201224:	00001617          	auipc	a2,0x1
ffffffffc0201228:	b1460613          	addi	a2,a2,-1260 # ffffffffc0201d38 <etext+0x65c>
ffffffffc020122c:	09700593          	li	a1,151
ffffffffc0201230:	00001517          	auipc	a0,0x1
ffffffffc0201234:	a8050513          	addi	a0,a0,-1408 # ffffffffc0201cb0 <etext+0x5d4>
ffffffffc0201238:	f91fe0ef          	jal	ffffffffc02001c8 <__panic>
        panic("page_init: no complete free page left");
ffffffffc020123c:	00001617          	auipc	a2,0x1
ffffffffc0201240:	b9c60613          	addi	a2,a2,-1124 # ffffffffc0201dd8 <etext+0x6fc>
ffffffffc0201244:	08000593          	li	a1,128
ffffffffc0201248:	00001517          	auipc	a0,0x1
ffffffffc020124c:	a6850513          	addi	a0,a0,-1432 # ffffffffc0201cb0 <etext+0x5d4>
ffffffffc0201250:	f79fe0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc0201254 <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201254:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201256:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020125a:	f022                	sd	s0,32(sp)
ffffffffc020125c:	ec26                	sd	s1,24(sp)
ffffffffc020125e:	e84a                	sd	s2,16(sp)
ffffffffc0201260:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201262:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201266:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201268:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc020126c:	fff7041b          	addiw	s0,a4,-1 # fffffffffff7ffff <end+0x3fd79f87>
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201270:	84aa                	mv	s1,a0
ffffffffc0201272:	892e                	mv	s2,a1
    if (num >= base) {
ffffffffc0201274:	03067d63          	bgeu	a2,a6,ffffffffc02012ae <printnum+0x5a>
ffffffffc0201278:	e44e                	sd	s3,8(sp)
ffffffffc020127a:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc020127c:	4785                	li	a5,1
ffffffffc020127e:	00e7d763          	bge	a5,a4,ffffffffc020128c <printnum+0x38>
            putch(padc, putdat);
ffffffffc0201282:	85ca                	mv	a1,s2
ffffffffc0201284:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc0201286:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201288:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020128a:	fc65                	bnez	s0,ffffffffc0201282 <printnum+0x2e>
ffffffffc020128c:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020128e:	00001797          	auipc	a5,0x1
ffffffffc0201292:	bd278793          	addi	a5,a5,-1070 # ffffffffc0201e60 <etext+0x784>
ffffffffc0201296:	97d2                	add	a5,a5,s4
}
ffffffffc0201298:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020129a:	0007c503          	lbu	a0,0(a5)
}
ffffffffc020129e:	70a2                	ld	ra,40(sp)
ffffffffc02012a0:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02012a2:	85ca                	mv	a1,s2
ffffffffc02012a4:	87a6                	mv	a5,s1
}
ffffffffc02012a6:	6942                	ld	s2,16(sp)
ffffffffc02012a8:	64e2                	ld	s1,24(sp)
ffffffffc02012aa:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02012ac:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02012ae:	03065633          	divu	a2,a2,a6
ffffffffc02012b2:	8722                	mv	a4,s0
ffffffffc02012b4:	fa1ff0ef          	jal	ffffffffc0201254 <printnum>
ffffffffc02012b8:	bfd9                	j	ffffffffc020128e <printnum+0x3a>

ffffffffc02012ba <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02012ba:	7119                	addi	sp,sp,-128
ffffffffc02012bc:	f4a6                	sd	s1,104(sp)
ffffffffc02012be:	f0ca                	sd	s2,96(sp)
ffffffffc02012c0:	ecce                	sd	s3,88(sp)
ffffffffc02012c2:	e8d2                	sd	s4,80(sp)
ffffffffc02012c4:	e4d6                	sd	s5,72(sp)
ffffffffc02012c6:	e0da                	sd	s6,64(sp)
ffffffffc02012c8:	f862                	sd	s8,48(sp)
ffffffffc02012ca:	fc86                	sd	ra,120(sp)
ffffffffc02012cc:	f8a2                	sd	s0,112(sp)
ffffffffc02012ce:	fc5e                	sd	s7,56(sp)
ffffffffc02012d0:	f466                	sd	s9,40(sp)
ffffffffc02012d2:	f06a                	sd	s10,32(sp)
ffffffffc02012d4:	ec6e                	sd	s11,24(sp)
ffffffffc02012d6:	84aa                	mv	s1,a0
ffffffffc02012d8:	8c32                	mv	s8,a2
ffffffffc02012da:	8a36                	mv	s4,a3
ffffffffc02012dc:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02012de:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02012e2:	05500b13          	li	s6,85
ffffffffc02012e6:	00001a97          	auipc	s5,0x1
ffffffffc02012ea:	c8aa8a93          	addi	s5,s5,-886 # ffffffffc0201f70 <best_fit_pmm_manager+0x38>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02012ee:	000c4503          	lbu	a0,0(s8)
ffffffffc02012f2:	001c0413          	addi	s0,s8,1
ffffffffc02012f6:	01350a63          	beq	a0,s3,ffffffffc020130a <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc02012fa:	cd0d                	beqz	a0,ffffffffc0201334 <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc02012fc:	85ca                	mv	a1,s2
ffffffffc02012fe:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201300:	00044503          	lbu	a0,0(s0)
ffffffffc0201304:	0405                	addi	s0,s0,1
ffffffffc0201306:	ff351ae3          	bne	a0,s3,ffffffffc02012fa <vprintfmt+0x40>
        width = precision = -1;
ffffffffc020130a:	5cfd                	li	s9,-1
ffffffffc020130c:	8d66                	mv	s10,s9
        char padc = ' ';
ffffffffc020130e:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc0201312:	4b81                	li	s7,0
ffffffffc0201314:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201316:	00044683          	lbu	a3,0(s0)
ffffffffc020131a:	00140c13          	addi	s8,s0,1
ffffffffc020131e:	fdd6859b          	addiw	a1,a3,-35
ffffffffc0201322:	0ff5f593          	zext.b	a1,a1
ffffffffc0201326:	02bb6663          	bltu	s6,a1,ffffffffc0201352 <vprintfmt+0x98>
ffffffffc020132a:	058a                	slli	a1,a1,0x2
ffffffffc020132c:	95d6                	add	a1,a1,s5
ffffffffc020132e:	4198                	lw	a4,0(a1)
ffffffffc0201330:	9756                	add	a4,a4,s5
ffffffffc0201332:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201334:	70e6                	ld	ra,120(sp)
ffffffffc0201336:	7446                	ld	s0,112(sp)
ffffffffc0201338:	74a6                	ld	s1,104(sp)
ffffffffc020133a:	7906                	ld	s2,96(sp)
ffffffffc020133c:	69e6                	ld	s3,88(sp)
ffffffffc020133e:	6a46                	ld	s4,80(sp)
ffffffffc0201340:	6aa6                	ld	s5,72(sp)
ffffffffc0201342:	6b06                	ld	s6,64(sp)
ffffffffc0201344:	7be2                	ld	s7,56(sp)
ffffffffc0201346:	7c42                	ld	s8,48(sp)
ffffffffc0201348:	7ca2                	ld	s9,40(sp)
ffffffffc020134a:	7d02                	ld	s10,32(sp)
ffffffffc020134c:	6de2                	ld	s11,24(sp)
ffffffffc020134e:	6109                	addi	sp,sp,128
ffffffffc0201350:	8082                	ret
            putch('%', putdat);
ffffffffc0201352:	85ca                	mv	a1,s2
ffffffffc0201354:	02500513          	li	a0,37
ffffffffc0201358:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc020135a:	fff44783          	lbu	a5,-1(s0)
ffffffffc020135e:	02500713          	li	a4,37
ffffffffc0201362:	8c22                	mv	s8,s0
ffffffffc0201364:	f8e785e3          	beq	a5,a4,ffffffffc02012ee <vprintfmt+0x34>
ffffffffc0201368:	ffec4783          	lbu	a5,-2(s8)
ffffffffc020136c:	1c7d                	addi	s8,s8,-1
ffffffffc020136e:	fee79de3          	bne	a5,a4,ffffffffc0201368 <vprintfmt+0xae>
ffffffffc0201372:	bfb5                	j	ffffffffc02012ee <vprintfmt+0x34>
                ch = *fmt;
ffffffffc0201374:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc0201378:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
ffffffffc020137a:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc020137e:	fd06071b          	addiw	a4,a2,-48
ffffffffc0201382:	24e56a63          	bltu	a0,a4,ffffffffc02015d6 <vprintfmt+0x31c>
                ch = *fmt;
ffffffffc0201386:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201388:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
ffffffffc020138a:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
ffffffffc020138e:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201392:	0197073b          	addw	a4,a4,s9
ffffffffc0201396:	0017171b          	slliw	a4,a4,0x1
ffffffffc020139a:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
ffffffffc020139c:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02013a0:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02013a2:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc02013a6:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
ffffffffc02013aa:	feb570e3          	bgeu	a0,a1,ffffffffc020138a <vprintfmt+0xd0>
            if (width < 0)
ffffffffc02013ae:	f60d54e3          	bgez	s10,ffffffffc0201316 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc02013b2:	8d66                	mv	s10,s9
ffffffffc02013b4:	5cfd                	li	s9,-1
ffffffffc02013b6:	b785                	j	ffffffffc0201316 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013b8:	8db6                	mv	s11,a3
ffffffffc02013ba:	8462                	mv	s0,s8
ffffffffc02013bc:	bfa9                	j	ffffffffc0201316 <vprintfmt+0x5c>
ffffffffc02013be:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc02013c0:	4b85                	li	s7,1
            goto reswitch;
ffffffffc02013c2:	bf91                	j	ffffffffc0201316 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc02013c4:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02013c6:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02013ca:	00f74463          	blt	a4,a5,ffffffffc02013d2 <vprintfmt+0x118>
    else if (lflag) {
ffffffffc02013ce:	1a078763          	beqz	a5,ffffffffc020157c <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
ffffffffc02013d2:	000a3603          	ld	a2,0(s4)
ffffffffc02013d6:	46c1                	li	a3,16
ffffffffc02013d8:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02013da:	000d879b          	sext.w	a5,s11
ffffffffc02013de:	876a                	mv	a4,s10
ffffffffc02013e0:	85ca                	mv	a1,s2
ffffffffc02013e2:	8526                	mv	a0,s1
ffffffffc02013e4:	e71ff0ef          	jal	ffffffffc0201254 <printnum>
            break;
ffffffffc02013e8:	b719                	j	ffffffffc02012ee <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc02013ea:	000a2503          	lw	a0,0(s4)
ffffffffc02013ee:	85ca                	mv	a1,s2
ffffffffc02013f0:	0a21                	addi	s4,s4,8
ffffffffc02013f2:	9482                	jalr	s1
            break;
ffffffffc02013f4:	bded                	j	ffffffffc02012ee <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc02013f6:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02013f8:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02013fc:	00f74463          	blt	a4,a5,ffffffffc0201404 <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc0201400:	16078963          	beqz	a5,ffffffffc0201572 <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
ffffffffc0201404:	000a3603          	ld	a2,0(s4)
ffffffffc0201408:	46a9                	li	a3,10
ffffffffc020140a:	8a2e                	mv	s4,a1
ffffffffc020140c:	b7f9                	j	ffffffffc02013da <vprintfmt+0x120>
            putch('0', putdat);
ffffffffc020140e:	85ca                	mv	a1,s2
ffffffffc0201410:	03000513          	li	a0,48
ffffffffc0201414:	9482                	jalr	s1
            putch('x', putdat);
ffffffffc0201416:	85ca                	mv	a1,s2
ffffffffc0201418:	07800513          	li	a0,120
ffffffffc020141c:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020141e:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc0201422:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201424:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201426:	bf55                	j	ffffffffc02013da <vprintfmt+0x120>
            putch(ch, putdat);
ffffffffc0201428:	85ca                	mv	a1,s2
ffffffffc020142a:	02500513          	li	a0,37
ffffffffc020142e:	9482                	jalr	s1
            break;
ffffffffc0201430:	bd7d                	j	ffffffffc02012ee <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc0201432:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201436:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc0201438:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc020143a:	bf95                	j	ffffffffc02013ae <vprintfmt+0xf4>
    if (lflag >= 2) {
ffffffffc020143c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020143e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201442:	00f74463          	blt	a4,a5,ffffffffc020144a <vprintfmt+0x190>
    else if (lflag) {
ffffffffc0201446:	12078163          	beqz	a5,ffffffffc0201568 <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
ffffffffc020144a:	000a3603          	ld	a2,0(s4)
ffffffffc020144e:	46a1                	li	a3,8
ffffffffc0201450:	8a2e                	mv	s4,a1
ffffffffc0201452:	b761                	j	ffffffffc02013da <vprintfmt+0x120>
            if (width < 0)
ffffffffc0201454:	876a                	mv	a4,s10
ffffffffc0201456:	000d5363          	bgez	s10,ffffffffc020145c <vprintfmt+0x1a2>
ffffffffc020145a:	4701                	li	a4,0
ffffffffc020145c:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201460:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0201462:	bd55                	j	ffffffffc0201316 <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
ffffffffc0201464:	000d841b          	sext.w	s0,s11
ffffffffc0201468:	fd340793          	addi	a5,s0,-45
ffffffffc020146c:	00f037b3          	snez	a5,a5
ffffffffc0201470:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201474:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
ffffffffc0201478:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020147a:	008a0793          	addi	a5,s4,8
ffffffffc020147e:	e43e                	sd	a5,8(sp)
ffffffffc0201480:	100d8c63          	beqz	s11,ffffffffc0201598 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc0201484:	12071363          	bnez	a4,ffffffffc02015aa <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201488:	000dc783          	lbu	a5,0(s11)
ffffffffc020148c:	0007851b          	sext.w	a0,a5
ffffffffc0201490:	c78d                	beqz	a5,ffffffffc02014ba <vprintfmt+0x200>
ffffffffc0201492:	0d85                	addi	s11,s11,1
ffffffffc0201494:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201496:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020149a:	000cc563          	bltz	s9,ffffffffc02014a4 <vprintfmt+0x1ea>
ffffffffc020149e:	3cfd                	addiw	s9,s9,-1
ffffffffc02014a0:	008c8d63          	beq	s9,s0,ffffffffc02014ba <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02014a4:	020b9663          	bnez	s7,ffffffffc02014d0 <vprintfmt+0x216>
                    putch(ch, putdat);
ffffffffc02014a8:	85ca                	mv	a1,s2
ffffffffc02014aa:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02014ac:	000dc783          	lbu	a5,0(s11)
ffffffffc02014b0:	0d85                	addi	s11,s11,1
ffffffffc02014b2:	3d7d                	addiw	s10,s10,-1
ffffffffc02014b4:	0007851b          	sext.w	a0,a5
ffffffffc02014b8:	f3ed                	bnez	a5,ffffffffc020149a <vprintfmt+0x1e0>
            for (; width > 0; width --) {
ffffffffc02014ba:	01a05963          	blez	s10,ffffffffc02014cc <vprintfmt+0x212>
                putch(' ', putdat);
ffffffffc02014be:	85ca                	mv	a1,s2
ffffffffc02014c0:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc02014c4:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
ffffffffc02014c6:	9482                	jalr	s1
            for (; width > 0; width --) {
ffffffffc02014c8:	fe0d1be3          	bnez	s10,ffffffffc02014be <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02014cc:	6a22                	ld	s4,8(sp)
ffffffffc02014ce:	b505                	j	ffffffffc02012ee <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02014d0:	3781                	addiw	a5,a5,-32
ffffffffc02014d2:	fcfa7be3          	bgeu	s4,a5,ffffffffc02014a8 <vprintfmt+0x1ee>
                    putch('?', putdat);
ffffffffc02014d6:	03f00513          	li	a0,63
ffffffffc02014da:	85ca                	mv	a1,s2
ffffffffc02014dc:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02014de:	000dc783          	lbu	a5,0(s11)
ffffffffc02014e2:	0d85                	addi	s11,s11,1
ffffffffc02014e4:	3d7d                	addiw	s10,s10,-1
ffffffffc02014e6:	0007851b          	sext.w	a0,a5
ffffffffc02014ea:	dbe1                	beqz	a5,ffffffffc02014ba <vprintfmt+0x200>
ffffffffc02014ec:	fa0cd9e3          	bgez	s9,ffffffffc020149e <vprintfmt+0x1e4>
ffffffffc02014f0:	b7c5                	j	ffffffffc02014d0 <vprintfmt+0x216>
            if (err < 0) {
ffffffffc02014f2:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02014f6:	4619                	li	a2,6
            err = va_arg(ap, int);
ffffffffc02014f8:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02014fa:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc02014fe:	8fb9                	xor	a5,a5,a4
ffffffffc0201500:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201504:	02d64563          	blt	a2,a3,ffffffffc020152e <vprintfmt+0x274>
ffffffffc0201508:	00001797          	auipc	a5,0x1
ffffffffc020150c:	bc078793          	addi	a5,a5,-1088 # ffffffffc02020c8 <error_string>
ffffffffc0201510:	00369713          	slli	a4,a3,0x3
ffffffffc0201514:	97ba                	add	a5,a5,a4
ffffffffc0201516:	639c                	ld	a5,0(a5)
ffffffffc0201518:	cb99                	beqz	a5,ffffffffc020152e <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
ffffffffc020151a:	86be                	mv	a3,a5
ffffffffc020151c:	00001617          	auipc	a2,0x1
ffffffffc0201520:	97460613          	addi	a2,a2,-1676 # ffffffffc0201e90 <etext+0x7b4>
ffffffffc0201524:	85ca                	mv	a1,s2
ffffffffc0201526:	8526                	mv	a0,s1
ffffffffc0201528:	0d8000ef          	jal	ffffffffc0201600 <printfmt>
ffffffffc020152c:	b3c9                	j	ffffffffc02012ee <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc020152e:	00001617          	auipc	a2,0x1
ffffffffc0201532:	95260613          	addi	a2,a2,-1710 # ffffffffc0201e80 <etext+0x7a4>
ffffffffc0201536:	85ca                	mv	a1,s2
ffffffffc0201538:	8526                	mv	a0,s1
ffffffffc020153a:	0c6000ef          	jal	ffffffffc0201600 <printfmt>
ffffffffc020153e:	bb45                	j	ffffffffc02012ee <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0201540:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201542:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc0201546:	00f74363          	blt	a4,a5,ffffffffc020154c <vprintfmt+0x292>
    else if (lflag) {
ffffffffc020154a:	cf81                	beqz	a5,ffffffffc0201562 <vprintfmt+0x2a8>
        return va_arg(*ap, long);
ffffffffc020154c:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201550:	02044b63          	bltz	s0,ffffffffc0201586 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc0201554:	8622                	mv	a2,s0
ffffffffc0201556:	8a5e                	mv	s4,s7
ffffffffc0201558:	46a9                	li	a3,10
ffffffffc020155a:	b541                	j	ffffffffc02013da <vprintfmt+0x120>
            lflag ++;
ffffffffc020155c:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020155e:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0201560:	bb5d                	j	ffffffffc0201316 <vprintfmt+0x5c>
        return va_arg(*ap, int);
ffffffffc0201562:	000a2403          	lw	s0,0(s4)
ffffffffc0201566:	b7ed                	j	ffffffffc0201550 <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
ffffffffc0201568:	000a6603          	lwu	a2,0(s4)
ffffffffc020156c:	46a1                	li	a3,8
ffffffffc020156e:	8a2e                	mv	s4,a1
ffffffffc0201570:	b5ad                	j	ffffffffc02013da <vprintfmt+0x120>
ffffffffc0201572:	000a6603          	lwu	a2,0(s4)
ffffffffc0201576:	46a9                	li	a3,10
ffffffffc0201578:	8a2e                	mv	s4,a1
ffffffffc020157a:	b585                	j	ffffffffc02013da <vprintfmt+0x120>
ffffffffc020157c:	000a6603          	lwu	a2,0(s4)
ffffffffc0201580:	46c1                	li	a3,16
ffffffffc0201582:	8a2e                	mv	s4,a1
ffffffffc0201584:	bd99                	j	ffffffffc02013da <vprintfmt+0x120>
                putch('-', putdat);
ffffffffc0201586:	85ca                	mv	a1,s2
ffffffffc0201588:	02d00513          	li	a0,45
ffffffffc020158c:	9482                	jalr	s1
                num = -(long long)num;
ffffffffc020158e:	40800633          	neg	a2,s0
ffffffffc0201592:	8a5e                	mv	s4,s7
ffffffffc0201594:	46a9                	li	a3,10
ffffffffc0201596:	b591                	j	ffffffffc02013da <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
ffffffffc0201598:	e329                	bnez	a4,ffffffffc02015da <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020159a:	02800793          	li	a5,40
ffffffffc020159e:	853e                	mv	a0,a5
ffffffffc02015a0:	00001d97          	auipc	s11,0x1
ffffffffc02015a4:	8d9d8d93          	addi	s11,s11,-1831 # ffffffffc0201e79 <etext+0x79d>
ffffffffc02015a8:	b5f5                	j	ffffffffc0201494 <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02015aa:	85e6                	mv	a1,s9
ffffffffc02015ac:	856e                	mv	a0,s11
ffffffffc02015ae:	0a4000ef          	jal	ffffffffc0201652 <strnlen>
ffffffffc02015b2:	40ad0d3b          	subw	s10,s10,a0
ffffffffc02015b6:	01a05863          	blez	s10,ffffffffc02015c6 <vprintfmt+0x30c>
                    putch(padc, putdat);
ffffffffc02015ba:	85ca                	mv	a1,s2
ffffffffc02015bc:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02015be:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
ffffffffc02015c0:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02015c2:	fe0d1ce3          	bnez	s10,ffffffffc02015ba <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02015c6:	000dc783          	lbu	a5,0(s11)
ffffffffc02015ca:	0007851b          	sext.w	a0,a5
ffffffffc02015ce:	ec0792e3          	bnez	a5,ffffffffc0201492 <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02015d2:	6a22                	ld	s4,8(sp)
ffffffffc02015d4:	bb29                	j	ffffffffc02012ee <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02015d6:	8462                	mv	s0,s8
ffffffffc02015d8:	bbd9                	j	ffffffffc02013ae <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02015da:	85e6                	mv	a1,s9
ffffffffc02015dc:	00001517          	auipc	a0,0x1
ffffffffc02015e0:	89c50513          	addi	a0,a0,-1892 # ffffffffc0201e78 <etext+0x79c>
ffffffffc02015e4:	06e000ef          	jal	ffffffffc0201652 <strnlen>
ffffffffc02015e8:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02015ec:	02800793          	li	a5,40
                p = "(null)";
ffffffffc02015f0:	00001d97          	auipc	s11,0x1
ffffffffc02015f4:	888d8d93          	addi	s11,s11,-1912 # ffffffffc0201e78 <etext+0x79c>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02015f8:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02015fa:	fda040e3          	bgtz	s10,ffffffffc02015ba <vprintfmt+0x300>
ffffffffc02015fe:	bd51                	j	ffffffffc0201492 <vprintfmt+0x1d8>

ffffffffc0201600 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201600:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201602:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201606:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201608:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020160a:	ec06                	sd	ra,24(sp)
ffffffffc020160c:	f83a                	sd	a4,48(sp)
ffffffffc020160e:	fc3e                	sd	a5,56(sp)
ffffffffc0201610:	e0c2                	sd	a6,64(sp)
ffffffffc0201612:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201614:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201616:	ca5ff0ef          	jal	ffffffffc02012ba <vprintfmt>
}
ffffffffc020161a:	60e2                	ld	ra,24(sp)
ffffffffc020161c:	6161                	addi	sp,sp,80
ffffffffc020161e:	8082                	ret

ffffffffc0201620 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201620:	00005717          	auipc	a4,0x5
ffffffffc0201624:	9f073703          	ld	a4,-1552(a4) # ffffffffc0206010 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201628:	4781                	li	a5,0
ffffffffc020162a:	88ba                	mv	a7,a4
ffffffffc020162c:	852a                	mv	a0,a0
ffffffffc020162e:	85be                	mv	a1,a5
ffffffffc0201630:	863e                	mv	a2,a5
ffffffffc0201632:	00000073          	ecall
ffffffffc0201636:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201638:	8082                	ret

ffffffffc020163a <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc020163a:	00054783          	lbu	a5,0(a0)
ffffffffc020163e:	cb81                	beqz	a5,ffffffffc020164e <strlen+0x14>
    size_t cnt = 0;
ffffffffc0201640:	4781                	li	a5,0
        cnt ++;
ffffffffc0201642:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc0201644:	00f50733          	add	a4,a0,a5
ffffffffc0201648:	00074703          	lbu	a4,0(a4)
ffffffffc020164c:	fb7d                	bnez	a4,ffffffffc0201642 <strlen+0x8>
    }
    return cnt;
}
ffffffffc020164e:	853e                	mv	a0,a5
ffffffffc0201650:	8082                	ret

ffffffffc0201652 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201652:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201654:	e589                	bnez	a1,ffffffffc020165e <strnlen+0xc>
ffffffffc0201656:	a811                	j	ffffffffc020166a <strnlen+0x18>
        cnt ++;
ffffffffc0201658:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc020165a:	00f58863          	beq	a1,a5,ffffffffc020166a <strnlen+0x18>
ffffffffc020165e:	00f50733          	add	a4,a0,a5
ffffffffc0201662:	00074703          	lbu	a4,0(a4)
ffffffffc0201666:	fb6d                	bnez	a4,ffffffffc0201658 <strnlen+0x6>
ffffffffc0201668:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc020166a:	852e                	mv	a0,a1
ffffffffc020166c:	8082                	ret

ffffffffc020166e <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020166e:	00054783          	lbu	a5,0(a0)
ffffffffc0201672:	e791                	bnez	a5,ffffffffc020167e <strcmp+0x10>
ffffffffc0201674:	a01d                	j	ffffffffc020169a <strcmp+0x2c>
ffffffffc0201676:	00054783          	lbu	a5,0(a0)
ffffffffc020167a:	cb99                	beqz	a5,ffffffffc0201690 <strcmp+0x22>
ffffffffc020167c:	0585                	addi	a1,a1,1
ffffffffc020167e:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc0201682:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201684:	fef709e3          	beq	a4,a5,ffffffffc0201676 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201688:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc020168c:	9d19                	subw	a0,a0,a4
ffffffffc020168e:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201690:	0015c703          	lbu	a4,1(a1)
ffffffffc0201694:	4501                	li	a0,0
}
ffffffffc0201696:	9d19                	subw	a0,a0,a4
ffffffffc0201698:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020169a:	0005c703          	lbu	a4,0(a1)
ffffffffc020169e:	4501                	li	a0,0
ffffffffc02016a0:	b7f5                	j	ffffffffc020168c <strcmp+0x1e>

ffffffffc02016a2 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02016a2:	ce01                	beqz	a2,ffffffffc02016ba <strncmp+0x18>
ffffffffc02016a4:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc02016a8:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02016aa:	cb91                	beqz	a5,ffffffffc02016be <strncmp+0x1c>
ffffffffc02016ac:	0005c703          	lbu	a4,0(a1)
ffffffffc02016b0:	00f71763          	bne	a4,a5,ffffffffc02016be <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc02016b4:	0505                	addi	a0,a0,1
ffffffffc02016b6:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02016b8:	f675                	bnez	a2,ffffffffc02016a4 <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02016ba:	4501                	li	a0,0
ffffffffc02016bc:	8082                	ret
ffffffffc02016be:	00054503          	lbu	a0,0(a0)
ffffffffc02016c2:	0005c783          	lbu	a5,0(a1)
ffffffffc02016c6:	9d1d                	subw	a0,a0,a5
}
ffffffffc02016c8:	8082                	ret

ffffffffc02016ca <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02016ca:	ca01                	beqz	a2,ffffffffc02016da <memset+0x10>
ffffffffc02016cc:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02016ce:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02016d0:	0785                	addi	a5,a5,1
ffffffffc02016d2:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02016d6:	fef61de3          	bne	a2,a5,ffffffffc02016d0 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02016da:	8082                	ret
