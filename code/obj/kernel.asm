
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00008297          	auipc	t0,0x8
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0208000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00008297          	auipc	t0,0x8
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0208008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02072b7          	lui	t0,0xc0207
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
ffffffffc020003c:	c0207137          	lui	sp,0xc0207

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
ffffffffc020004a:	1141                	addi	sp,sp,-16 # ffffffffc0206ff0 <bootstack+0x1ff0>
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00003517          	auipc	a0,0x3
ffffffffc0200050:	e7450513          	addi	a0,a0,-396 # ffffffffc0202ec0 <etext+0x6>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0fa000ef          	jal	ffffffffc0200150 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07c58593          	addi	a1,a1,124 # ffffffffc02000d6 <kern_init>
ffffffffc0200062:	00003517          	auipc	a0,0x3
ffffffffc0200066:	e7e50513          	addi	a0,a0,-386 # ffffffffc0202ee0 <etext+0x26>
ffffffffc020006a:	0e6000ef          	jal	ffffffffc0200150 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00003597          	auipc	a1,0x3
ffffffffc0200072:	e4c58593          	addi	a1,a1,-436 # ffffffffc0202eba <etext>
ffffffffc0200076:	00003517          	auipc	a0,0x3
ffffffffc020007a:	e8a50513          	addi	a0,a0,-374 # ffffffffc0202f00 <etext+0x46>
ffffffffc020007e:	0d2000ef          	jal	ffffffffc0200150 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00008597          	auipc	a1,0x8
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0208018 <buddy_free_lists>
ffffffffc020008a:	00003517          	auipc	a0,0x3
ffffffffc020008e:	e9650513          	addi	a0,a0,-362 # ffffffffc0202f20 <etext+0x66>
ffffffffc0200092:	0be000ef          	jal	ffffffffc0200150 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00009597          	auipc	a1,0x9
ffffffffc020009a:	99e58593          	addi	a1,a1,-1634 # ffffffffc0208a34 <end>
ffffffffc020009e:	00003517          	auipc	a0,0x3
ffffffffc02000a2:	ea250513          	addi	a0,a0,-350 # ffffffffc0202f40 <etext+0x86>
ffffffffc02000a6:	0aa000ef          	jal	ffffffffc0200150 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00000717          	auipc	a4,0x0
ffffffffc02000ae:	02c70713          	addi	a4,a4,44 # ffffffffc02000d6 <kern_init>
ffffffffc02000b2:	00009797          	auipc	a5,0x9
ffffffffc02000b6:	d8178793          	addi	a5,a5,-639 # ffffffffc0208e33 <end+0x3ff>
ffffffffc02000ba:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000bc:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c0:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c2:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c6:	95be                	add	a1,a1,a5
ffffffffc02000c8:	85a9                	srai	a1,a1,0xa
ffffffffc02000ca:	00003517          	auipc	a0,0x3
ffffffffc02000ce:	e9650513          	addi	a0,a0,-362 # ffffffffc0202f60 <etext+0xa6>
}
ffffffffc02000d2:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d4:	a8b5                	j	ffffffffc0200150 <cprintf>

ffffffffc02000d6 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d6:	00008517          	auipc	a0,0x8
ffffffffc02000da:	f4250513          	addi	a0,a0,-190 # ffffffffc0208018 <buddy_free_lists>
ffffffffc02000de:	00009617          	auipc	a2,0x9
ffffffffc02000e2:	95660613          	addi	a2,a2,-1706 # ffffffffc0208a34 <end>
int kern_init(void) {
ffffffffc02000e6:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000e8:	8e09                	sub	a2,a2,a0
ffffffffc02000ea:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ec:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000ee:	5bb020ef          	jal	ffffffffc0202ea8 <memset>
    dtb_init();
ffffffffc02000f2:	13e000ef          	jal	ffffffffc0200230 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f6:	130000ef          	jal	ffffffffc0200226 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fa:	00004517          	auipc	a0,0x4
ffffffffc02000fe:	06e50513          	addi	a0,a0,110 # ffffffffc0204168 <etext+0x12ae>
ffffffffc0200102:	082000ef          	jal	ffffffffc0200184 <cputs>

    print_kerninfo();
ffffffffc0200106:	f45ff0ef          	jal	ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010a:	59e010ef          	jal	ffffffffc02016a8 <pmm_init>
                 //先初始化并测试底层页分配器 -lzs
    slub_init(); // 再初始化对象缓存 -lzs
ffffffffc020010e:	7d6010ef          	jal	ffffffffc02018e4 <slub_init>
    slub_check();// 最后测试对象分配器 -lzs
ffffffffc0200112:	525010ef          	jal	ffffffffc0201e36 <slub_check>

    /* do nothing */
    while (1)
ffffffffc0200116:	a001                	j	ffffffffc0200116 <kern_init+0x40>

ffffffffc0200118 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200118:	1101                	addi	sp,sp,-32
ffffffffc020011a:	ec06                	sd	ra,24(sp)
ffffffffc020011c:	e42e                	sd	a1,8(sp)
    cons_putc(c);
ffffffffc020011e:	10a000ef          	jal	ffffffffc0200228 <cons_putc>
    (*cnt) ++;
ffffffffc0200122:	65a2                	ld	a1,8(sp)
}
ffffffffc0200124:	60e2                	ld	ra,24(sp)
    (*cnt) ++;
ffffffffc0200126:	419c                	lw	a5,0(a1)
ffffffffc0200128:	2785                	addiw	a5,a5,1
ffffffffc020012a:	c19c                	sw	a5,0(a1)
}
ffffffffc020012c:	6105                	addi	sp,sp,32
ffffffffc020012e:	8082                	ret

ffffffffc0200130 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200130:	1101                	addi	sp,sp,-32
ffffffffc0200132:	862a                	mv	a2,a0
ffffffffc0200134:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200136:	00000517          	auipc	a0,0x0
ffffffffc020013a:	fe250513          	addi	a0,a0,-30 # ffffffffc0200118 <cputch>
ffffffffc020013e:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200140:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200142:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200144:	155020ef          	jal	ffffffffc0202a98 <vprintfmt>
    return cnt;
}
ffffffffc0200148:	60e2                	ld	ra,24(sp)
ffffffffc020014a:	4532                	lw	a0,12(sp)
ffffffffc020014c:	6105                	addi	sp,sp,32
ffffffffc020014e:	8082                	ret

ffffffffc0200150 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc0200150:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200152:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
ffffffffc0200156:	f42e                	sd	a1,40(sp)
ffffffffc0200158:	f832                	sd	a2,48(sp)
ffffffffc020015a:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020015c:	862a                	mv	a2,a0
ffffffffc020015e:	004c                	addi	a1,sp,4
ffffffffc0200160:	00000517          	auipc	a0,0x0
ffffffffc0200164:	fb850513          	addi	a0,a0,-72 # ffffffffc0200118 <cputch>
ffffffffc0200168:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc020016a:	ec06                	sd	ra,24(sp)
ffffffffc020016c:	e0ba                	sd	a4,64(sp)
ffffffffc020016e:	e4be                	sd	a5,72(sp)
ffffffffc0200170:	e8c2                	sd	a6,80(sp)
ffffffffc0200172:	ecc6                	sd	a7,88(sp)
    int cnt = 0;
ffffffffc0200174:	c202                	sw	zero,4(sp)
    va_start(ap, fmt);
ffffffffc0200176:	e41a                	sd	t1,8(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200178:	121020ef          	jal	ffffffffc0202a98 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020017c:	60e2                	ld	ra,24(sp)
ffffffffc020017e:	4512                	lw	a0,4(sp)
ffffffffc0200180:	6125                	addi	sp,sp,96
ffffffffc0200182:	8082                	ret

ffffffffc0200184 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200184:	1101                	addi	sp,sp,-32
ffffffffc0200186:	e822                	sd	s0,16(sp)
ffffffffc0200188:	ec06                	sd	ra,24(sp)
ffffffffc020018a:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020018c:	00054503          	lbu	a0,0(a0)
ffffffffc0200190:	c51d                	beqz	a0,ffffffffc02001be <cputs+0x3a>
ffffffffc0200192:	e426                	sd	s1,8(sp)
ffffffffc0200194:	0405                	addi	s0,s0,1
    int cnt = 0;
ffffffffc0200196:	4481                	li	s1,0
    cons_putc(c);
ffffffffc0200198:	090000ef          	jal	ffffffffc0200228 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020019c:	00044503          	lbu	a0,0(s0)
ffffffffc02001a0:	0405                	addi	s0,s0,1
ffffffffc02001a2:	87a6                	mv	a5,s1
    (*cnt) ++;
ffffffffc02001a4:	2485                	addiw	s1,s1,1
    while ((c = *str ++) != '\0') {
ffffffffc02001a6:	f96d                	bnez	a0,ffffffffc0200198 <cputs+0x14>
    cons_putc(c);
ffffffffc02001a8:	4529                	li	a0,10
    (*cnt) ++;
ffffffffc02001aa:	0027841b          	addiw	s0,a5,2
ffffffffc02001ae:	64a2                	ld	s1,8(sp)
    cons_putc(c);
ffffffffc02001b0:	078000ef          	jal	ffffffffc0200228 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001b4:	60e2                	ld	ra,24(sp)
ffffffffc02001b6:	8522                	mv	a0,s0
ffffffffc02001b8:	6442                	ld	s0,16(sp)
ffffffffc02001ba:	6105                	addi	sp,sp,32
ffffffffc02001bc:	8082                	ret
    cons_putc(c);
ffffffffc02001be:	4529                	li	a0,10
ffffffffc02001c0:	068000ef          	jal	ffffffffc0200228 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc02001c4:	4405                	li	s0,1
}
ffffffffc02001c6:	60e2                	ld	ra,24(sp)
ffffffffc02001c8:	8522                	mv	a0,s0
ffffffffc02001ca:	6442                	ld	s0,16(sp)
ffffffffc02001cc:	6105                	addi	sp,sp,32
ffffffffc02001ce:	8082                	ret

ffffffffc02001d0 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001d0:	00009317          	auipc	t1,0x9
ffffffffc02001d4:	80032303          	lw	t1,-2048(t1) # ffffffffc02089d0 <is_panic>
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001d8:	715d                	addi	sp,sp,-80
ffffffffc02001da:	ec06                	sd	ra,24(sp)
ffffffffc02001dc:	f436                	sd	a3,40(sp)
ffffffffc02001de:	f83a                	sd	a4,48(sp)
ffffffffc02001e0:	fc3e                	sd	a5,56(sp)
ffffffffc02001e2:	e0c2                	sd	a6,64(sp)
ffffffffc02001e4:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001e6:	00030363          	beqz	t1,ffffffffc02001ec <__panic+0x1c>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001ea:	a001                	j	ffffffffc02001ea <__panic+0x1a>
    is_panic = 1;
ffffffffc02001ec:	4705                	li	a4,1
    va_start(ap, fmt);
ffffffffc02001ee:	103c                	addi	a5,sp,40
ffffffffc02001f0:	e822                	sd	s0,16(sp)
ffffffffc02001f2:	8432                	mv	s0,a2
ffffffffc02001f4:	862e                	mv	a2,a1
ffffffffc02001f6:	85aa                	mv	a1,a0
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001f8:	00003517          	auipc	a0,0x3
ffffffffc02001fc:	d9850513          	addi	a0,a0,-616 # ffffffffc0202f90 <etext+0xd6>
    is_panic = 1;
ffffffffc0200200:	00008697          	auipc	a3,0x8
ffffffffc0200204:	7ce6a823          	sw	a4,2000(a3) # ffffffffc02089d0 <is_panic>
    va_start(ap, fmt);
ffffffffc0200208:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020020a:	f47ff0ef          	jal	ffffffffc0200150 <cprintf>
    vcprintf(fmt, ap);
ffffffffc020020e:	65a2                	ld	a1,8(sp)
ffffffffc0200210:	8522                	mv	a0,s0
ffffffffc0200212:	f1fff0ef          	jal	ffffffffc0200130 <vcprintf>
    cprintf("\n");
ffffffffc0200216:	00003517          	auipc	a0,0x3
ffffffffc020021a:	d9a50513          	addi	a0,a0,-614 # ffffffffc0202fb0 <etext+0xf6>
ffffffffc020021e:	f33ff0ef          	jal	ffffffffc0200150 <cprintf>
ffffffffc0200222:	6442                	ld	s0,16(sp)
ffffffffc0200224:	b7d9                	j	ffffffffc02001ea <__panic+0x1a>

ffffffffc0200226 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200226:	8082                	ret

ffffffffc0200228 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200228:	0ff57513          	zext.b	a0,a0
ffffffffc020022c:	3d30206f          	j	ffffffffc0202dfe <sbi_console_putchar>

ffffffffc0200230 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200230:	7179                	addi	sp,sp,-48
    cprintf("DTB Init\n");
ffffffffc0200232:	00003517          	auipc	a0,0x3
ffffffffc0200236:	d8650513          	addi	a0,a0,-634 # ffffffffc0202fb8 <etext+0xfe>
void dtb_init(void) {
ffffffffc020023a:	f406                	sd	ra,40(sp)
ffffffffc020023c:	f022                	sd	s0,32(sp)
    cprintf("DTB Init\n");
ffffffffc020023e:	f13ff0ef          	jal	ffffffffc0200150 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200242:	00008597          	auipc	a1,0x8
ffffffffc0200246:	dbe5b583          	ld	a1,-578(a1) # ffffffffc0208000 <boot_hartid>
ffffffffc020024a:	00003517          	auipc	a0,0x3
ffffffffc020024e:	d7e50513          	addi	a0,a0,-642 # ffffffffc0202fc8 <etext+0x10e>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200252:	00008417          	auipc	s0,0x8
ffffffffc0200256:	db640413          	addi	s0,s0,-586 # ffffffffc0208008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc020025a:	ef7ff0ef          	jal	ffffffffc0200150 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020025e:	600c                	ld	a1,0(s0)
ffffffffc0200260:	00003517          	auipc	a0,0x3
ffffffffc0200264:	d7850513          	addi	a0,a0,-648 # ffffffffc0202fd8 <etext+0x11e>
ffffffffc0200268:	ee9ff0ef          	jal	ffffffffc0200150 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc020026c:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020026e:	00003517          	auipc	a0,0x3
ffffffffc0200272:	d8250513          	addi	a0,a0,-638 # ffffffffc0202ff0 <etext+0x136>
    if (boot_dtb == 0) {
ffffffffc0200276:	10070163          	beqz	a4,ffffffffc0200378 <dtb_init+0x148>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc020027a:	57f5                	li	a5,-3
ffffffffc020027c:	07fa                	slli	a5,a5,0x1e
ffffffffc020027e:	973e                	add	a4,a4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200280:	431c                	lw	a5,0(a4)
    if (magic != 0xd00dfeed) {
ffffffffc0200282:	d00e06b7          	lui	a3,0xd00e0
ffffffffc0200286:	eed68693          	addi	a3,a3,-275 # ffffffffd00dfeed <end+0xfed74b9>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020028a:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020028e:	0187961b          	slliw	a2,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200292:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200296:	0ff5f593          	zext.b	a1,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020029a:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020029e:	05c2                	slli	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a0:	8e49                	or	a2,a2,a0
ffffffffc02002a2:	0ff7f793          	zext.b	a5,a5
ffffffffc02002a6:	8dd1                	or	a1,a1,a2
ffffffffc02002a8:	07a2                	slli	a5,a5,0x8
ffffffffc02002aa:	8ddd                	or	a1,a1,a5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ac:	00ff0837          	lui	a6,0xff0
    if (magic != 0xd00dfeed) {
ffffffffc02002b0:	0cd59863          	bne	a1,a3,ffffffffc0200380 <dtb_init+0x150>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002b4:	4710                	lw	a2,8(a4)
ffffffffc02002b6:	4754                	lw	a3,12(a4)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02002b8:	e84a                	sd	s2,16(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ba:	0086541b          	srliw	s0,a2,0x8
ffffffffc02002be:	0086d79b          	srliw	a5,a3,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002c2:	01865e1b          	srliw	t3,a2,0x18
ffffffffc02002c6:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ca:	0186151b          	slliw	a0,a2,0x18
ffffffffc02002ce:	0186959b          	slliw	a1,a3,0x18
ffffffffc02002d2:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d6:	0106561b          	srliw	a2,a2,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002da:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002de:	0106d69b          	srliw	a3,a3,0x10
ffffffffc02002e2:	01c56533          	or	a0,a0,t3
ffffffffc02002e6:	0115e5b3          	or	a1,a1,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ea:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ee:	0ff67613          	zext.b	a2,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002f2:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f6:	0ff6f693          	zext.b	a3,a3
ffffffffc02002fa:	8c49                	or	s0,s0,a0
ffffffffc02002fc:	0622                	slli	a2,a2,0x8
ffffffffc02002fe:	8fcd                	or	a5,a5,a1
ffffffffc0200300:	06a2                	slli	a3,a3,0x8
ffffffffc0200302:	8c51                	or	s0,s0,a2
ffffffffc0200304:	8fd5                	or	a5,a5,a3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200306:	1402                	slli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200308:	1782                	slli	a5,a5,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020030a:	9001                	srli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020030c:	9381                	srli	a5,a5,0x20
ffffffffc020030e:	ec26                	sd	s1,24(sp)
    int in_memory_node = 0;
ffffffffc0200310:	4301                	li	t1,0
        switch (token) {
ffffffffc0200312:	488d                	li	a7,3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200314:	943a                	add	s0,s0,a4
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200316:	00e78933          	add	s2,a5,a4
        switch (token) {
ffffffffc020031a:	4e05                	li	t3,1
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020031c:	4018                	lw	a4,0(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020031e:	0087579b          	srliw	a5,a4,0x8
ffffffffc0200322:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200326:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020032a:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020032e:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200332:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200336:	8ed1                	or	a3,a3,a2
ffffffffc0200338:	0ff77713          	zext.b	a4,a4
ffffffffc020033c:	8fd5                	or	a5,a5,a3
ffffffffc020033e:	0722                	slli	a4,a4,0x8
ffffffffc0200340:	8fd9                	or	a5,a5,a4
        switch (token) {
ffffffffc0200342:	05178763          	beq	a5,a7,ffffffffc0200390 <dtb_init+0x160>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200346:	0411                	addi	s0,s0,4
        switch (token) {
ffffffffc0200348:	00f8e963          	bltu	a7,a5,ffffffffc020035a <dtb_init+0x12a>
ffffffffc020034c:	07c78d63          	beq	a5,t3,ffffffffc02003c6 <dtb_init+0x196>
ffffffffc0200350:	4709                	li	a4,2
ffffffffc0200352:	00e79763          	bne	a5,a4,ffffffffc0200360 <dtb_init+0x130>
ffffffffc0200356:	4301                	li	t1,0
ffffffffc0200358:	b7d1                	j	ffffffffc020031c <dtb_init+0xec>
ffffffffc020035a:	4711                	li	a4,4
ffffffffc020035c:	fce780e3          	beq	a5,a4,ffffffffc020031c <dtb_init+0xec>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200360:	00003517          	auipc	a0,0x3
ffffffffc0200364:	d5850513          	addi	a0,a0,-680 # ffffffffc02030b8 <etext+0x1fe>
ffffffffc0200368:	de9ff0ef          	jal	ffffffffc0200150 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020036c:	64e2                	ld	s1,24(sp)
ffffffffc020036e:	6942                	ld	s2,16(sp)
ffffffffc0200370:	00003517          	auipc	a0,0x3
ffffffffc0200374:	d8050513          	addi	a0,a0,-640 # ffffffffc02030f0 <etext+0x236>
}
ffffffffc0200378:	7402                	ld	s0,32(sp)
ffffffffc020037a:	70a2                	ld	ra,40(sp)
ffffffffc020037c:	6145                	addi	sp,sp,48
    cprintf("DTB init completed\n");
ffffffffc020037e:	bbc9                	j	ffffffffc0200150 <cprintf>
}
ffffffffc0200380:	7402                	ld	s0,32(sp)
ffffffffc0200382:	70a2                	ld	ra,40(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200384:	00003517          	auipc	a0,0x3
ffffffffc0200388:	c8c50513          	addi	a0,a0,-884 # ffffffffc0203010 <etext+0x156>
}
ffffffffc020038c:	6145                	addi	sp,sp,48
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020038e:	b3c9                	j	ffffffffc0200150 <cprintf>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200390:	4058                	lw	a4,4(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200392:	0087579b          	srliw	a5,a4,0x8
ffffffffc0200396:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020039a:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020039e:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02003a2:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02003a6:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02003aa:	8ed1                	or	a3,a3,a2
ffffffffc02003ac:	0ff77713          	zext.b	a4,a4
ffffffffc02003b0:	8fd5                	or	a5,a5,a3
ffffffffc02003b2:	0722                	slli	a4,a4,0x8
ffffffffc02003b4:	8fd9                	or	a5,a5,a4
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02003b6:	04031463          	bnez	t1,ffffffffc02003fe <dtb_init+0x1ce>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02003ba:	1782                	slli	a5,a5,0x20
ffffffffc02003bc:	9381                	srli	a5,a5,0x20
ffffffffc02003be:	043d                	addi	s0,s0,15
ffffffffc02003c0:	943e                	add	s0,s0,a5
ffffffffc02003c2:	9871                	andi	s0,s0,-4
                break;
ffffffffc02003c4:	bfa1                	j	ffffffffc020031c <dtb_init+0xec>
                int name_len = strlen(name);
ffffffffc02003c6:	8522                	mv	a0,s0
ffffffffc02003c8:	e01a                	sd	t1,0(sp)
ffffffffc02003ca:	24f020ef          	jal	ffffffffc0202e18 <strlen>
ffffffffc02003ce:	84aa                	mv	s1,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003d0:	4619                	li	a2,6
ffffffffc02003d2:	8522                	mv	a0,s0
ffffffffc02003d4:	00003597          	auipc	a1,0x3
ffffffffc02003d8:	c6458593          	addi	a1,a1,-924 # ffffffffc0203038 <etext+0x17e>
ffffffffc02003dc:	2a5020ef          	jal	ffffffffc0202e80 <strncmp>
ffffffffc02003e0:	6302                	ld	t1,0(sp)
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02003e2:	0411                	addi	s0,s0,4
ffffffffc02003e4:	0004879b          	sext.w	a5,s1
ffffffffc02003e8:	943e                	add	s0,s0,a5
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003ea:	00153513          	seqz	a0,a0
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02003ee:	9871                	andi	s0,s0,-4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003f0:	00a36333          	or	t1,t1,a0
                break;
ffffffffc02003f4:	00ff0837          	lui	a6,0xff0
ffffffffc02003f8:	488d                	li	a7,3
ffffffffc02003fa:	4e05                	li	t3,1
ffffffffc02003fc:	b705                	j	ffffffffc020031c <dtb_init+0xec>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02003fe:	4418                	lw	a4,8(s0)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200400:	00003597          	auipc	a1,0x3
ffffffffc0200404:	c4058593          	addi	a1,a1,-960 # ffffffffc0203040 <etext+0x186>
ffffffffc0200408:	e43e                	sd	a5,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020040a:	0087551b          	srliw	a0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020040e:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200412:	0187169b          	slliw	a3,a4,0x18
ffffffffc0200416:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020041a:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020041e:	01057533          	and	a0,a0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200422:	8ed1                	or	a3,a3,a2
ffffffffc0200424:	0ff77713          	zext.b	a4,a4
ffffffffc0200428:	0722                	slli	a4,a4,0x8
ffffffffc020042a:	8d55                	or	a0,a0,a3
ffffffffc020042c:	8d59                	or	a0,a0,a4
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc020042e:	1502                	slli	a0,a0,0x20
ffffffffc0200430:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200432:	954a                	add	a0,a0,s2
ffffffffc0200434:	e01a                	sd	t1,0(sp)
ffffffffc0200436:	217020ef          	jal	ffffffffc0202e4c <strcmp>
ffffffffc020043a:	67a2                	ld	a5,8(sp)
ffffffffc020043c:	473d                	li	a4,15
ffffffffc020043e:	6302                	ld	t1,0(sp)
ffffffffc0200440:	00ff0837          	lui	a6,0xff0
ffffffffc0200444:	488d                	li	a7,3
ffffffffc0200446:	4e05                	li	t3,1
ffffffffc0200448:	f6f779e3          	bgeu	a4,a5,ffffffffc02003ba <dtb_init+0x18a>
ffffffffc020044c:	f53d                	bnez	a0,ffffffffc02003ba <dtb_init+0x18a>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020044e:	00c43683          	ld	a3,12(s0)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200452:	01443703          	ld	a4,20(s0)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200456:	00003517          	auipc	a0,0x3
ffffffffc020045a:	bf250513          	addi	a0,a0,-1038 # ffffffffc0203048 <etext+0x18e>
           fdt32_to_cpu(x >> 32);
ffffffffc020045e:	4206d793          	srai	a5,a3,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200462:	0087d31b          	srliw	t1,a5,0x8
ffffffffc0200466:	00871f93          	slli	t6,a4,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc020046a:	42075893          	srai	a7,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020046e:	0187df1b          	srliw	t5,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200472:	0187959b          	slliw	a1,a5,0x18
ffffffffc0200476:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020047a:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020047e:	420fd613          	srai	a2,t6,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200482:	0188de9b          	srliw	t4,a7,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200486:	01037333          	and	t1,t1,a6
ffffffffc020048a:	01889e1b          	slliw	t3,a7,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020048e:	01e5e5b3          	or	a1,a1,t5
ffffffffc0200492:	0ff7f793          	zext.b	a5,a5
ffffffffc0200496:	01de6e33          	or	t3,t3,t4
ffffffffc020049a:	0065e5b3          	or	a1,a1,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020049e:	01067633          	and	a2,a2,a6
ffffffffc02004a2:	0086d31b          	srliw	t1,a3,0x8
ffffffffc02004a6:	0087541b          	srliw	s0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004aa:	07a2                	slli	a5,a5,0x8
ffffffffc02004ac:	0108d89b          	srliw	a7,a7,0x10
ffffffffc02004b0:	0186df1b          	srliw	t5,a3,0x18
ffffffffc02004b4:	01875e9b          	srliw	t4,a4,0x18
ffffffffc02004b8:	8ddd                	or	a1,a1,a5
ffffffffc02004ba:	01c66633          	or	a2,a2,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004be:	0186979b          	slliw	a5,a3,0x18
ffffffffc02004c2:	01871e1b          	slliw	t3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c6:	0ff8f893          	zext.b	a7,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004ca:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ce:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004d2:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d6:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004da:	01037333          	and	t1,t1,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004de:	08a2                	slli	a7,a7,0x8
ffffffffc02004e0:	01e7e7b3          	or	a5,a5,t5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e4:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004e8:	0ff6f693          	zext.b	a3,a3
ffffffffc02004ec:	01de6833          	or	a6,t3,t4
ffffffffc02004f0:	0ff77713          	zext.b	a4,a4
ffffffffc02004f4:	01166633          	or	a2,a2,a7
ffffffffc02004f8:	0067e7b3          	or	a5,a5,t1
ffffffffc02004fc:	06a2                	slli	a3,a3,0x8
ffffffffc02004fe:	01046433          	or	s0,s0,a6
ffffffffc0200502:	0722                	slli	a4,a4,0x8
ffffffffc0200504:	8fd5                	or	a5,a5,a3
ffffffffc0200506:	8c59                	or	s0,s0,a4
           fdt32_to_cpu(x >> 32);
ffffffffc0200508:	1582                	slli	a1,a1,0x20
ffffffffc020050a:	1602                	slli	a2,a2,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020050c:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020050e:	9201                	srli	a2,a2,0x20
ffffffffc0200510:	9181                	srli	a1,a1,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200512:	1402                	slli	s0,s0,0x20
ffffffffc0200514:	00b7e4b3          	or	s1,a5,a1
ffffffffc0200518:	8c51                	or	s0,s0,a2
        cprintf("Physical Memory from DTB:\n");
ffffffffc020051a:	c37ff0ef          	jal	ffffffffc0200150 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc020051e:	85a6                	mv	a1,s1
ffffffffc0200520:	00003517          	auipc	a0,0x3
ffffffffc0200524:	b4850513          	addi	a0,a0,-1208 # ffffffffc0203068 <etext+0x1ae>
ffffffffc0200528:	c29ff0ef          	jal	ffffffffc0200150 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020052c:	01445613          	srli	a2,s0,0x14
ffffffffc0200530:	85a2                	mv	a1,s0
ffffffffc0200532:	00003517          	auipc	a0,0x3
ffffffffc0200536:	b4e50513          	addi	a0,a0,-1202 # ffffffffc0203080 <etext+0x1c6>
ffffffffc020053a:	c17ff0ef          	jal	ffffffffc0200150 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc020053e:	009405b3          	add	a1,s0,s1
ffffffffc0200542:	15fd                	addi	a1,a1,-1
ffffffffc0200544:	00003517          	auipc	a0,0x3
ffffffffc0200548:	b5c50513          	addi	a0,a0,-1188 # ffffffffc02030a0 <etext+0x1e6>
ffffffffc020054c:	c05ff0ef          	jal	ffffffffc0200150 <cprintf>
        memory_base = mem_base;
ffffffffc0200550:	00008797          	auipc	a5,0x8
ffffffffc0200554:	4897b823          	sd	s1,1168(a5) # ffffffffc02089e0 <memory_base>
        memory_size = mem_size;
ffffffffc0200558:	00008797          	auipc	a5,0x8
ffffffffc020055c:	4887b023          	sd	s0,1152(a5) # ffffffffc02089d8 <memory_size>
ffffffffc0200560:	b531                	j	ffffffffc020036c <dtb_init+0x13c>

ffffffffc0200562 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc0200562:	00008517          	auipc	a0,0x8
ffffffffc0200566:	47e53503          	ld	a0,1150(a0) # ffffffffc02089e0 <memory_base>
ffffffffc020056a:	8082                	ret

ffffffffc020056c <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc020056c:	00008517          	auipc	a0,0x8
ffffffffc0200570:	46c53503          	ld	a0,1132(a0) # ffffffffc02089d8 <memory_size>
ffffffffc0200574:	8082                	ret

ffffffffc0200576 <buddy_init>:
static size_t buddy_begin_ppn;
static size_t buddy_end_ppn;

static void
buddy_init(void) {
    for (unsigned int order = 0; order <= BUDDY_MAX_ORDER; order++) {
ffffffffc0200576:	00008797          	auipc	a5,0x8
ffffffffc020057a:	aa278793          	addi	a5,a5,-1374 # ffffffffc0208018 <buddy_free_lists>
ffffffffc020057e:	00008717          	auipc	a4,0x8
ffffffffc0200582:	b9a70713          	addi	a4,a4,-1126 # ffffffffc0208118 <caches>
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200586:	e79c                	sd	a5,8(a5)
ffffffffc0200588:	e39c                	sd	a5,0(a5)
ffffffffc020058a:	07c1                	addi	a5,a5,16
ffffffffc020058c:	fee79de3          	bne	a5,a4,ffffffffc0200586 <buddy_init+0x10>
        list_init(&buddy_free_lists[order]);
    }

    buddy_nr_free = 0;
ffffffffc0200590:	00008797          	auipc	a5,0x8
ffffffffc0200594:	4607b423          	sd	zero,1128(a5) # ffffffffc02089f8 <buddy_nr_free>
    buddy_begin_ppn = buddy_end_ppn = 0;
ffffffffc0200598:	00008797          	auipc	a5,0x8
ffffffffc020059c:	4407b823          	sd	zero,1104(a5) # ffffffffc02089e8 <buddy_end_ppn>
ffffffffc02005a0:	00008797          	auipc	a5,0x8
ffffffffc02005a4:	4407b823          	sd	zero,1104(a5) # ffffffffc02089f0 <buddy_begin_ppn>
}
ffffffffc02005a8:	8082                	ret

ffffffffc02005aa <buddy_nr_free_pages>:
}

static size_t
buddy_nr_free_pages(void) {
    return buddy_nr_free;
}
ffffffffc02005aa:	00008517          	auipc	a0,0x8
ffffffffc02005ae:	44e53503          	ld	a0,1102(a0) # ffffffffc02089f8 <buddy_nr_free>
ffffffffc02005b2:	8082                	ret

ffffffffc02005b4 <buddy_init_check>:
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02005b4:	ccccd7b7          	lui	a5,0xccccd
ffffffffc02005b8:	ccd78793          	addi	a5,a5,-819 # ffffffffcccccccd <end+0xcac4299>
ffffffffc02005bc:	00008297          	auipc	t0,0x8
ffffffffc02005c0:	46c2b283          	ld	t0,1132(t0) # ffffffffc0208a28 <pages>
ffffffffc02005c4:	00004f97          	auipc	t6,0x4
ffffffffc02005c8:	f14fbf83          	ld	t6,-236(t6) # ffffffffc02044d8 <nbase>
            size_t count = (size_t)1 << order;
            size_t ppn = page2ppn(p);

            assert(PageProperty(p) && p->property == order);
            assert((ppn & (count - 1)) == 0);
            assert(ppn >= buddy_begin_ppn && ppn < buddy_end_ppn);
ffffffffc02005cc:	00008f17          	auipc	t5,0x8
ffffffffc02005d0:	424f3f03          	ld	t5,1060(t5) # ffffffffc02089f0 <buddy_begin_ppn>
ffffffffc02005d4:	00008897          	auipc	a7,0x8
ffffffffc02005d8:	4148b883          	ld	a7,1044(a7) # ffffffffc02089e8 <buddy_end_ppn>
buddy_init_check(void) {
ffffffffc02005dc:	1101                	addi	sp,sp,-32
ffffffffc02005de:	02079e93          	slli	t4,a5,0x20
ffffffffc02005e2:	e822                	sd	s0,16(sp)
ffffffffc02005e4:	ec06                	sd	ra,24(sp)
ffffffffc02005e6:	e426                	sd	s1,8(sp)
ffffffffc02005e8:	9ebe                	add	t4,t4,a5
ffffffffc02005ea:	00008e17          	auipc	t3,0x8
ffffffffc02005ee:	a2ee0e13          	addi	t3,t3,-1490 # ffffffffc0208018 <buddy_free_lists>
    for (unsigned int order = 0; order <= BUDDY_MAX_ORDER; order++) {
ffffffffc02005f2:	4301                	li	t1,0
    size_t blocks = 0;
ffffffffc02005f4:	4601                	li	a2,0
    size_t total = 0;
ffffffffc02005f6:	4581                	li	a1,0
            size_t count = (size_t)1 << order;
ffffffffc02005f8:	4405                	li	s0,1
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc02005fa:	008e3503          	ld	a0,8(t3)
        for (list_entry_t *le = list_next(head); le != head;
ffffffffc02005fe:	0aae0463          	beq	t3,a0,ffffffffc02006a6 <buddy_init_check+0xf2>
            size_t count = (size_t)1 << order;
ffffffffc0200602:	00641833          	sll	a6,s0,t1
            assert((ppn & (count - 1)) == 0);
ffffffffc0200606:	fff80393          	addi	t2,a6,-1 # feffff <kern_entry-0xffffffffbf210001>
            assert(PageProperty(p) && p->property == order);
ffffffffc020060a:	ff053783          	ld	a5,-16(a0)
ffffffffc020060e:	8b89                	andi	a5,a5,2
ffffffffc0200610:	16078963          	beqz	a5,ffffffffc0200782 <buddy_init_check+0x1ce>
ffffffffc0200614:	ff852783          	lw	a5,-8(a0)
ffffffffc0200618:	16679563          	bne	a5,t1,ffffffffc0200782 <buddy_init_check+0x1ce>
            struct Page *p = le2page(le, page_link);
ffffffffc020061c:	fe850793          	addi	a5,a0,-24
ffffffffc0200620:	40578733          	sub	a4,a5,t0
ffffffffc0200624:	870d                	srai	a4,a4,0x3
ffffffffc0200626:	03d70733          	mul	a4,a4,t4
ffffffffc020062a:	977e                	add	a4,a4,t6
            assert((ppn & (count - 1)) == 0);
ffffffffc020062c:	00e3f6b3          	and	a3,t2,a4
ffffffffc0200630:	12069963          	bnez	a3,ffffffffc0200762 <buddy_init_check+0x1ae>
            assert(ppn >= buddy_begin_ppn && ppn < buddy_end_ppn);
ffffffffc0200634:	11e76763          	bltu	a4,t5,ffffffffc0200742 <buddy_init_check+0x18e>
ffffffffc0200638:	11177563          	bgeu	a4,a7,ffffffffc0200742 <buddy_init_check+0x18e>
            assert(count <= buddy_end_ppn - ppn);
ffffffffc020063c:	40e88733          	sub	a4,a7,a4
ffffffffc0200640:	1b076163          	bltu	a4,a6,ffffffffc02007e2 <buddy_init_check+0x22e>
ffffffffc0200644:	6118                	ld	a4,0(a0)

            assert(list_next(list_prev(le)) == le);
ffffffffc0200646:	6718                	ld	a4,8(a4)
ffffffffc0200648:	16a71d63          	bne	a4,a0,ffffffffc02007c2 <buddy_init_check+0x20e>
ffffffffc020064c:	6504                	ld	s1,8(a0)
            assert(list_prev(list_next(le)) == le);
ffffffffc020064e:	6098                	ld	a4,0(s1)
ffffffffc0200650:	14a71963          	bne	a4,a0,ffffffffc02007a2 <buddy_init_check+0x1ee>

            for (size_t i = 0; i < count; i++) {
                assert(!PageReserved(p + i));
ffffffffc0200654:	6794                	ld	a3,8(a5)
ffffffffc0200656:	8a85                	andi	a3,a3,1
ffffffffc0200658:	e6cd                	bnez	a3,ffffffffc0200702 <buddy_init_check+0x14e>
                assert(page_ref(p + i) == 0);
ffffffffc020065a:	fe852703          	lw	a4,-24(a0)
ffffffffc020065e:	e351                	bnez	a4,ffffffffc02006e2 <buddy_init_check+0x12e>
            for (size_t i = 0; i < count; i++) {
ffffffffc0200660:	0685                	addi	a3,a3,1
ffffffffc0200662:	02d80c63          	beq	a6,a3,ffffffffc020069a <buddy_init_check+0xe6>
                assert(!PageReserved(p + i));
ffffffffc0200666:	7b98                	ld	a4,48(a5)
            for (size_t i = 0; i < count; i++) {
ffffffffc0200668:	02878793          	addi	a5,a5,40
                assert(!PageReserved(p + i));
ffffffffc020066c:	00177513          	andi	a0,a4,1
ffffffffc0200670:	e949                	bnez	a0,ffffffffc0200702 <buddy_init_check+0x14e>
                assert(page_ref(p + i) == 0);
ffffffffc0200672:	4388                	lw	a0,0(a5)
ffffffffc0200674:	e53d                	bnez	a0,ffffffffc02006e2 <buddy_init_check+0x12e>

                if (i != 0) {
                    assert(!PageProperty(p + i));
ffffffffc0200676:	8b09                	andi	a4,a4,2
ffffffffc0200678:	d765                	beqz	a4,ffffffffc0200660 <buddy_init_check+0xac>
ffffffffc020067a:	00003697          	auipc	a3,0x3
ffffffffc020067e:	bc668693          	addi	a3,a3,-1082 # ffffffffc0203240 <etext+0x386>
ffffffffc0200682:	00003617          	auipc	a2,0x3
ffffffffc0200686:	aae60613          	addi	a2,a2,-1362 # ffffffffc0203130 <etext+0x276>
ffffffffc020068a:	0f600593          	li	a1,246
ffffffffc020068e:	00003517          	auipc	a0,0x3
ffffffffc0200692:	aba50513          	addi	a0,a0,-1350 # ffffffffc0203148 <etext+0x28e>
ffffffffc0200696:	b3bff0ef          	jal	ffffffffc02001d0 <__panic>
                }
            }

            total += count;
ffffffffc020069a:	95c2                	add	a1,a1,a6
            blocks++;
ffffffffc020069c:	0605                	addi	a2,a2,1
        for (list_entry_t *le = list_next(head); le != head;
ffffffffc020069e:	01c48463          	beq	s1,t3,ffffffffc02006a6 <buddy_init_check+0xf2>
ffffffffc02006a2:	8526                	mv	a0,s1
ffffffffc02006a4:	b79d                	j	ffffffffc020060a <buddy_init_check+0x56>
    for (unsigned int order = 0; order <= BUDDY_MAX_ORDER; order++) {
ffffffffc02006a6:	47c1                	li	a5,16
ffffffffc02006a8:	2305                	addiw	t1,t1,1
ffffffffc02006aa:	9e3e                	add	t3,t3,a5
ffffffffc02006ac:	f4f317e3          	bne	t1,a5,ffffffffc02005fa <buddy_init_check+0x46>
        }
    }

    assert(total == buddy_nr_free);
ffffffffc02006b0:	00008797          	auipc	a5,0x8
ffffffffc02006b4:	3487b783          	ld	a5,840(a5) # ffffffffc02089f8 <buddy_nr_free>
ffffffffc02006b8:	06b79563          	bne	a5,a1,ffffffffc0200722 <buddy_init_check+0x16e>
    assert(total == buddy_end_ppn - buddy_begin_ppn);
ffffffffc02006bc:	41e888b3          	sub	a7,a7,t5
ffffffffc02006c0:	14b89163          	bne	a7,a1,ffffffffc0200802 <buddy_init_check+0x24e>

    cprintf("buddy init: %lu pages in %lu blocks\n",
ffffffffc02006c4:	00003517          	auipc	a0,0x3
ffffffffc02006c8:	bdc50513          	addi	a0,a0,-1060 # ffffffffc02032a0 <etext+0x3e6>
ffffffffc02006cc:	a85ff0ef          	jal	ffffffffc0200150 <cprintf>
            (unsigned long)total, (unsigned long)blocks);
    cprintf("buddy_init_check() succeeded!\n");
}
ffffffffc02006d0:	6442                	ld	s0,16(sp)
ffffffffc02006d2:	60e2                	ld	ra,24(sp)
ffffffffc02006d4:	64a2                	ld	s1,8(sp)
    cprintf("buddy_init_check() succeeded!\n");
ffffffffc02006d6:	00003517          	auipc	a0,0x3
ffffffffc02006da:	bf250513          	addi	a0,a0,-1038 # ffffffffc02032c8 <etext+0x40e>
}
ffffffffc02006de:	6105                	addi	sp,sp,32
    cprintf("buddy_init_check() succeeded!\n");
ffffffffc02006e0:	bc85                	j	ffffffffc0200150 <cprintf>
                assert(page_ref(p + i) == 0);
ffffffffc02006e2:	00003697          	auipc	a3,0x3
ffffffffc02006e6:	b4668693          	addi	a3,a3,-1210 # ffffffffc0203228 <etext+0x36e>
ffffffffc02006ea:	00003617          	auipc	a2,0x3
ffffffffc02006ee:	a4660613          	addi	a2,a2,-1466 # ffffffffc0203130 <etext+0x276>
ffffffffc02006f2:	0f300593          	li	a1,243
ffffffffc02006f6:	00003517          	auipc	a0,0x3
ffffffffc02006fa:	a5250513          	addi	a0,a0,-1454 # ffffffffc0203148 <etext+0x28e>
ffffffffc02006fe:	ad3ff0ef          	jal	ffffffffc02001d0 <__panic>
                assert(!PageReserved(p + i));
ffffffffc0200702:	00003697          	auipc	a3,0x3
ffffffffc0200706:	b0e68693          	addi	a3,a3,-1266 # ffffffffc0203210 <etext+0x356>
ffffffffc020070a:	00003617          	auipc	a2,0x3
ffffffffc020070e:	a2660613          	addi	a2,a2,-1498 # ffffffffc0203130 <etext+0x276>
ffffffffc0200712:	0f200593          	li	a1,242
ffffffffc0200716:	00003517          	auipc	a0,0x3
ffffffffc020071a:	a3250513          	addi	a0,a0,-1486 # ffffffffc0203148 <etext+0x28e>
ffffffffc020071e:	ab3ff0ef          	jal	ffffffffc02001d0 <__panic>
    assert(total == buddy_nr_free);
ffffffffc0200722:	00003697          	auipc	a3,0x3
ffffffffc0200726:	b3668693          	addi	a3,a3,-1226 # ffffffffc0203258 <etext+0x39e>
ffffffffc020072a:	00003617          	auipc	a2,0x3
ffffffffc020072e:	a0660613          	addi	a2,a2,-1530 # ffffffffc0203130 <etext+0x276>
ffffffffc0200732:	0ff00593          	li	a1,255
ffffffffc0200736:	00003517          	auipc	a0,0x3
ffffffffc020073a:	a1250513          	addi	a0,a0,-1518 # ffffffffc0203148 <etext+0x28e>
ffffffffc020073e:	a93ff0ef          	jal	ffffffffc02001d0 <__panic>
            assert(ppn >= buddy_begin_ppn && ppn < buddy_end_ppn);
ffffffffc0200742:	00003697          	auipc	a3,0x3
ffffffffc0200746:	a3e68693          	addi	a3,a3,-1474 # ffffffffc0203180 <etext+0x2c6>
ffffffffc020074a:	00003617          	auipc	a2,0x3
ffffffffc020074e:	9e660613          	addi	a2,a2,-1562 # ffffffffc0203130 <etext+0x276>
ffffffffc0200752:	0eb00593          	li	a1,235
ffffffffc0200756:	00003517          	auipc	a0,0x3
ffffffffc020075a:	9f250513          	addi	a0,a0,-1550 # ffffffffc0203148 <etext+0x28e>
ffffffffc020075e:	a73ff0ef          	jal	ffffffffc02001d0 <__panic>
            assert((ppn & (count - 1)) == 0);
ffffffffc0200762:	00003697          	auipc	a3,0x3
ffffffffc0200766:	9fe68693          	addi	a3,a3,-1538 # ffffffffc0203160 <etext+0x2a6>
ffffffffc020076a:	00003617          	auipc	a2,0x3
ffffffffc020076e:	9c660613          	addi	a2,a2,-1594 # ffffffffc0203130 <etext+0x276>
ffffffffc0200772:	0ea00593          	li	a1,234
ffffffffc0200776:	00003517          	auipc	a0,0x3
ffffffffc020077a:	9d250513          	addi	a0,a0,-1582 # ffffffffc0203148 <etext+0x28e>
ffffffffc020077e:	a53ff0ef          	jal	ffffffffc02001d0 <__panic>
            assert(PageProperty(p) && p->property == order);
ffffffffc0200782:	00003697          	auipc	a3,0x3
ffffffffc0200786:	98668693          	addi	a3,a3,-1658 # ffffffffc0203108 <etext+0x24e>
ffffffffc020078a:	00003617          	auipc	a2,0x3
ffffffffc020078e:	9a660613          	addi	a2,a2,-1626 # ffffffffc0203130 <etext+0x276>
ffffffffc0200792:	0e900593          	li	a1,233
ffffffffc0200796:	00003517          	auipc	a0,0x3
ffffffffc020079a:	9b250513          	addi	a0,a0,-1614 # ffffffffc0203148 <etext+0x28e>
ffffffffc020079e:	a33ff0ef          	jal	ffffffffc02001d0 <__panic>
            assert(list_prev(list_next(le)) == le);
ffffffffc02007a2:	00003697          	auipc	a3,0x3
ffffffffc02007a6:	a4e68693          	addi	a3,a3,-1458 # ffffffffc02031f0 <etext+0x336>
ffffffffc02007aa:	00003617          	auipc	a2,0x3
ffffffffc02007ae:	98660613          	addi	a2,a2,-1658 # ffffffffc0203130 <etext+0x276>
ffffffffc02007b2:	0ef00593          	li	a1,239
ffffffffc02007b6:	00003517          	auipc	a0,0x3
ffffffffc02007ba:	99250513          	addi	a0,a0,-1646 # ffffffffc0203148 <etext+0x28e>
ffffffffc02007be:	a13ff0ef          	jal	ffffffffc02001d0 <__panic>
            assert(list_next(list_prev(le)) == le);
ffffffffc02007c2:	00003697          	auipc	a3,0x3
ffffffffc02007c6:	a0e68693          	addi	a3,a3,-1522 # ffffffffc02031d0 <etext+0x316>
ffffffffc02007ca:	00003617          	auipc	a2,0x3
ffffffffc02007ce:	96660613          	addi	a2,a2,-1690 # ffffffffc0203130 <etext+0x276>
ffffffffc02007d2:	0ee00593          	li	a1,238
ffffffffc02007d6:	00003517          	auipc	a0,0x3
ffffffffc02007da:	97250513          	addi	a0,a0,-1678 # ffffffffc0203148 <etext+0x28e>
ffffffffc02007de:	9f3ff0ef          	jal	ffffffffc02001d0 <__panic>
            assert(count <= buddy_end_ppn - ppn);
ffffffffc02007e2:	00003697          	auipc	a3,0x3
ffffffffc02007e6:	9ce68693          	addi	a3,a3,-1586 # ffffffffc02031b0 <etext+0x2f6>
ffffffffc02007ea:	00003617          	auipc	a2,0x3
ffffffffc02007ee:	94660613          	addi	a2,a2,-1722 # ffffffffc0203130 <etext+0x276>
ffffffffc02007f2:	0ec00593          	li	a1,236
ffffffffc02007f6:	00003517          	auipc	a0,0x3
ffffffffc02007fa:	95250513          	addi	a0,a0,-1710 # ffffffffc0203148 <etext+0x28e>
ffffffffc02007fe:	9d3ff0ef          	jal	ffffffffc02001d0 <__panic>
    assert(total == buddy_end_ppn - buddy_begin_ppn);
ffffffffc0200802:	00003697          	auipc	a3,0x3
ffffffffc0200806:	a6e68693          	addi	a3,a3,-1426 # ffffffffc0203270 <etext+0x3b6>
ffffffffc020080a:	00003617          	auipc	a2,0x3
ffffffffc020080e:	92660613          	addi	a2,a2,-1754 # ffffffffc0203130 <etext+0x276>
ffffffffc0200812:	10000593          	li	a1,256
ffffffffc0200816:	00003517          	auipc	a0,0x3
ffffffffc020081a:	93250513          	addi	a0,a0,-1742 # ffffffffc0203148 <etext+0x28e>
ffffffffc020081e:	9b3ff0ef          	jal	ffffffffc02001d0 <__panic>

ffffffffc0200822 <buddy_free_pages>:
buddy_free_pages(struct Page *base, size_t n) {
ffffffffc0200822:	1141                	addi	sp,sp,-16
ffffffffc0200824:	e406                	sd	ra,8(sp)
    assert(base != NULL && n > 0);
ffffffffc0200826:	22050863          	beqz	a0,ffffffffc0200a56 <buddy_free_pages+0x234>
ffffffffc020082a:	22058663          	beqz	a1,ffffffffc0200a56 <buddy_free_pages+0x234>
ffffffffc020082e:	00008e97          	auipc	t4,0x8
ffffffffc0200832:	1faebe83          	ld	t4,506(t4) # ffffffffc0208a28 <pages>
ffffffffc0200836:	ccccd7b7          	lui	a5,0xccccd
ffffffffc020083a:	ccd78793          	addi	a5,a5,-819 # ffffffffcccccccd <end+0xcac4299>
ffffffffc020083e:	02079713          	slli	a4,a5,0x20
ffffffffc0200842:	41d50833          	sub	a6,a0,t4
ffffffffc0200846:	97ba                	add	a5,a5,a4
ffffffffc0200848:	40385813          	srai	a6,a6,0x3
ffffffffc020084c:	02f80833          	mul	a6,a6,a5
ffffffffc0200850:	00004f17          	auipc	t5,0x4
ffffffffc0200854:	c88f3f03          	ld	t5,-888(t5) # ffffffffc02044d8 <nbase>
    assert(ppn >= buddy_begin_ppn && ppn < buddy_end_ppn);
ffffffffc0200858:	00008e17          	auipc	t3,0x8
ffffffffc020085c:	198e3e03          	ld	t3,408(t3) # ffffffffc02089f0 <buddy_begin_ppn>
ffffffffc0200860:	987a                	add	a6,a6,t5
ffffffffc0200862:	19c86a63          	bltu	a6,t3,ffffffffc02009f6 <buddy_free_pages+0x1d4>
ffffffffc0200866:	00008317          	auipc	t1,0x8
ffffffffc020086a:	18233303          	ld	t1,386(t1) # ffffffffc02089e8 <buddy_end_ppn>
ffffffffc020086e:	18687463          	bgeu	a6,t1,ffffffffc02009f6 <buddy_free_pages+0x1d4>
    assert(!PageReserved(base) && !PageProperty(base));
ffffffffc0200872:	651c                	ld	a5,8(a0)
ffffffffc0200874:	0037f713          	andi	a4,a5,3
ffffffffc0200878:	1a071f63          	bnez	a4,ffffffffc0200a36 <buddy_free_pages+0x214>
    assert((base->flags & BUDDY_ALLOCATED) != 0);
ffffffffc020087c:	0047f713          	andi	a4,a5,4
ffffffffc0200880:	22070b63          	beqz	a4,ffffffffc0200ab6 <buddy_free_pages+0x294>
    unsigned int order = base->property;
ffffffffc0200884:	4910                	lw	a2,16(a0)
    assert(order <= BUDDY_MAX_ORDER);
ffffffffc0200886:	473d                	li	a4,15
ffffffffc0200888:	24c76763          	bltu	a4,a2,ffffffffc0200ad6 <buddy_free_pages+0x2b4>
    size_t released = (size_t)1 << order;
ffffffffc020088c:	4705                	li	a4,1
ffffffffc020088e:	00c71733          	sll	a4,a4,a2
    assert(n <= released && (order == 0 || n > released / 2));
ffffffffc0200892:	18b76263          	bltu	a4,a1,ffffffffc0200a16 <buddy_free_pages+0x1f4>
ffffffffc0200896:	e679                	bnez	a2,ffffffffc0200964 <buddy_free_pages+0x142>
    assert(released <=
ffffffffc0200898:	00008697          	auipc	a3,0x8
ffffffffc020089c:	1606b683          	ld	a3,352(a3) # ffffffffc02089f8 <buddy_nr_free>
ffffffffc02008a0:	00de05b3          	add	a1,t3,a3
ffffffffc02008a4:	40b305b3          	sub	a1,t1,a1
ffffffffc02008a8:	1ee5e763          	bltu	a1,a4,ffffffffc0200a96 <buddy_free_pages+0x274>
    base->flags &= ~BUDDY_ALLOCATED;
ffffffffc02008ac:	9bed                	andi	a5,a5,-5
    buddy_nr_free += released;
ffffffffc02008ae:	96ba                	add	a3,a3,a4
    base->flags &= ~BUDDY_ALLOCATED;
ffffffffc02008b0:	e51c                	sd	a5,8(a0)
    buddy_nr_free += released;
ffffffffc02008b2:	00008717          	auipc	a4,0x8
ffffffffc02008b6:	14d73323          	sd	a3,326(a4) # ffffffffc02089f8 <buddy_nr_free>
    base->property = 0;
ffffffffc02008ba:	00052823          	sw	zero,16(a0)
    while (order < BUDDY_MAX_ORDER) {
ffffffffc02008be:	4fbd                	li	t6,15
ffffffffc02008c0:	0ff60763          	beq	a2,t6,ffffffffc02009ae <buddy_free_pages+0x18c>
        size_t count = (size_t)1 << order;
ffffffffc02008c4:	4285                	li	t0,1
ffffffffc02008c6:	a8a9                	j	ffffffffc0200920 <buddy_free_pages+0xfe>
        if (buddy_ppn < buddy_begin_ppn ||
ffffffffc02008c8:	0666f263          	bgeu	a3,t1,ffffffffc020092c <buddy_free_pages+0x10a>
            count > buddy_end_ppn - buddy_ppn) {
ffffffffc02008cc:	40d30733          	sub	a4,t1,a3
            buddy_ppn >= buddy_end_ppn ||
ffffffffc02008d0:	04f76e63          	bltu	a4,a5,ffffffffc020092c <buddy_free_pages+0x10a>
        struct Page *buddy = pages + (buddy_ppn - nbase);
ffffffffc02008d4:	41e68733          	sub	a4,a3,t5
ffffffffc02008d8:	00271793          	slli	a5,a4,0x2
ffffffffc02008dc:	97ba                	add	a5,a5,a4
ffffffffc02008de:	078e                	slli	a5,a5,0x3
ffffffffc02008e0:	97f6                	add	a5,a5,t4
        if (!PageProperty(buddy) || buddy->property != order) {
ffffffffc02008e2:	6798                	ld	a4,8(a5)
ffffffffc02008e4:	00277593          	andi	a1,a4,2
ffffffffc02008e8:	c1b1                	beqz	a1,ffffffffc020092c <buddy_free_pages+0x10a>
ffffffffc02008ea:	4b8c                	lw	a1,16(a5)
ffffffffc02008ec:	04c59063          	bne	a1,a2,ffffffffc020092c <buddy_free_pages+0x10a>
        assert(!PageReserved(buddy));
ffffffffc02008f0:	00177593          	andi	a1,a4,1
ffffffffc02008f4:	e1e9                	bnez	a1,ffffffffc02009b6 <buddy_free_pages+0x194>
        assert((buddy->flags & BUDDY_ALLOCATED) == 0);
ffffffffc02008f6:	00477593          	andi	a1,a4,4
ffffffffc02008fa:	edf1                	bnez	a1,ffffffffc02009d6 <buddy_free_pages+0x1b4>
    __list_del(listelm->prev, listelm->next);
ffffffffc02008fc:	0187b883          	ld	a7,24(a5)
ffffffffc0200900:	738c                	ld	a1,32(a5)
        ClearPageProperty(buddy);
ffffffffc0200902:	9b75                	andi	a4,a4,-3
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200904:	00b8b423          	sd	a1,8(a7)
    next->prev = prev;
ffffffffc0200908:	0115b023          	sd	a7,0(a1)
ffffffffc020090c:	e798                	sd	a4,8(a5)
        buddy->property = 0;
ffffffffc020090e:	0007a823          	sw	zero,16(a5)
        if (buddy_ppn < ppn) {
ffffffffc0200912:	0106f463          	bgeu	a3,a6,ffffffffc020091a <buddy_free_pages+0xf8>
            ppn = buddy_ppn;
ffffffffc0200916:	8836                	mv	a6,a3
            base = buddy;
ffffffffc0200918:	853e                	mv	a0,a5
        order++;
ffffffffc020091a:	2605                	addiw	a2,a2,1
    while (order < BUDDY_MAX_ORDER) {
ffffffffc020091c:	09f60263          	beq	a2,t6,ffffffffc02009a0 <buddy_free_pages+0x17e>
        size_t count = (size_t)1 << order;
ffffffffc0200920:	00c297b3          	sll	a5,t0,a2
        size_t buddy_ppn = ppn ^ count;
ffffffffc0200924:	0107c6b3          	xor	a3,a5,a6
        if (buddy_ppn < buddy_begin_ppn ||
ffffffffc0200928:	fbc6f0e3          	bgeu	a3,t3,ffffffffc02008c8 <buddy_free_pages+0xa6>
ffffffffc020092c:	02061713          	slli	a4,a2,0x20
    SetPageProperty(base);
ffffffffc0200930:	651c                	ld	a5,8(a0)
ffffffffc0200932:	9301                	srli	a4,a4,0x20
ffffffffc0200934:	00471693          	slli	a3,a4,0x4
    __list_add(elm, listelm, listelm->next);
ffffffffc0200938:	00007817          	auipc	a6,0x7
ffffffffc020093c:	6e080813          	addi	a6,a6,1760 # ffffffffc0208018 <buddy_free_lists>
ffffffffc0200940:	0712                	slli	a4,a4,0x4
ffffffffc0200942:	9742                	add	a4,a4,a6
ffffffffc0200944:	670c                	ld	a1,8(a4)
ffffffffc0200946:	0027e793          	ori	a5,a5,2
ffffffffc020094a:	e51c                	sd	a5,8(a0)
    base->property = order;
ffffffffc020094c:	c910                	sw	a2,16(a0)
    list_add(&buddy_free_lists[order], &base->page_link);
ffffffffc020094e:	01850613          	addi	a2,a0,24
    prev->next = next->prev = elm;
ffffffffc0200952:	e190                	sd	a2,0(a1)
}
ffffffffc0200954:	60a2                	ld	ra,8(sp)
ffffffffc0200956:	e710                	sd	a2,8(a4)
    list_add(&buddy_free_lists[order], &base->page_link);
ffffffffc0200958:	010687b3          	add	a5,a3,a6
    elm->prev = prev;
ffffffffc020095c:	ed1c                	sd	a5,24(a0)
    elm->next = next;
ffffffffc020095e:	f10c                	sd	a1,32(a0)
}
ffffffffc0200960:	0141                	addi	sp,sp,16
ffffffffc0200962:	8082                	ret
    assert(n <= released && (order == 0 || n > released / 2));
ffffffffc0200964:	00175693          	srli	a3,a4,0x1
ffffffffc0200968:	0ab6f763          	bgeu	a3,a1,ffffffffc0200a16 <buddy_free_pages+0x1f4>
    assert((ppn & (released - 1)) == 0);
ffffffffc020096c:	fff70693          	addi	a3,a4,-1
ffffffffc0200970:	0106f6b3          	and	a3,a3,a6
ffffffffc0200974:	10069163          	bnez	a3,ffffffffc0200a76 <buddy_free_pages+0x254>
    assert(released <= buddy_end_ppn - ppn);
ffffffffc0200978:	410306b3          	sub	a3,t1,a6
ffffffffc020097c:	f0e6fee3          	bgeu	a3,a4,ffffffffc0200898 <buddy_free_pages+0x76>
ffffffffc0200980:	00003697          	auipc	a3,0x3
ffffffffc0200984:	a5068693          	addi	a3,a3,-1456 # ffffffffc02033d0 <etext+0x516>
ffffffffc0200988:	00002617          	auipc	a2,0x2
ffffffffc020098c:	7a860613          	addi	a2,a2,1960 # ffffffffc0203130 <etext+0x276>
ffffffffc0200990:	0a300593          	li	a1,163
ffffffffc0200994:	00002517          	auipc	a0,0x2
ffffffffc0200998:	7b450513          	addi	a0,a0,1972 # ffffffffc0203148 <etext+0x28e>
ffffffffc020099c:	835ff0ef          	jal	ffffffffc02001d0 <__panic>
ffffffffc02009a0:	02061713          	slli	a4,a2,0x20
    SetPageProperty(base);
ffffffffc02009a4:	651c                	ld	a5,8(a0)
ffffffffc02009a6:	0f000693          	li	a3,240
ffffffffc02009aa:	9301                	srli	a4,a4,0x20
ffffffffc02009ac:	b771                	j	ffffffffc0200938 <buddy_free_pages+0x116>
    while (order < BUDDY_MAX_ORDER) {
ffffffffc02009ae:	0f000693          	li	a3,240
ffffffffc02009b2:	8732                	mv	a4,a2
ffffffffc02009b4:	b751                	j	ffffffffc0200938 <buddy_free_pages+0x116>
        assert(!PageReserved(buddy));
ffffffffc02009b6:	00003697          	auipc	a3,0x3
ffffffffc02009ba:	a7a68693          	addi	a3,a3,-1414 # ffffffffc0203430 <etext+0x576>
ffffffffc02009be:	00002617          	auipc	a2,0x2
ffffffffc02009c2:	77260613          	addi	a2,a2,1906 # ffffffffc0203130 <etext+0x276>
ffffffffc02009c6:	0c000593          	li	a1,192
ffffffffc02009ca:	00002517          	auipc	a0,0x2
ffffffffc02009ce:	77e50513          	addi	a0,a0,1918 # ffffffffc0203148 <etext+0x28e>
ffffffffc02009d2:	ffeff0ef          	jal	ffffffffc02001d0 <__panic>
        assert((buddy->flags & BUDDY_ALLOCATED) == 0);
ffffffffc02009d6:	00003697          	auipc	a3,0x3
ffffffffc02009da:	a7268693          	addi	a3,a3,-1422 # ffffffffc0203448 <etext+0x58e>
ffffffffc02009de:	00002617          	auipc	a2,0x2
ffffffffc02009e2:	75260613          	addi	a2,a2,1874 # ffffffffc0203130 <etext+0x276>
ffffffffc02009e6:	0c100593          	li	a1,193
ffffffffc02009ea:	00002517          	auipc	a0,0x2
ffffffffc02009ee:	75e50513          	addi	a0,a0,1886 # ffffffffc0203148 <etext+0x28e>
ffffffffc02009f2:	fdeff0ef          	jal	ffffffffc02001d0 <__panic>
    assert(ppn >= buddy_begin_ppn && ppn < buddy_end_ppn);
ffffffffc02009f6:	00002697          	auipc	a3,0x2
ffffffffc02009fa:	78a68693          	addi	a3,a3,1930 # ffffffffc0203180 <etext+0x2c6>
ffffffffc02009fe:	00002617          	auipc	a2,0x2
ffffffffc0200a02:	73260613          	addi	a2,a2,1842 # ffffffffc0203130 <etext+0x276>
ffffffffc0200a06:	09700593          	li	a1,151
ffffffffc0200a0a:	00002517          	auipc	a0,0x2
ffffffffc0200a0e:	73e50513          	addi	a0,a0,1854 # ffffffffc0203148 <etext+0x28e>
ffffffffc0200a12:	fbeff0ef          	jal	ffffffffc02001d0 <__panic>
    assert(n <= released && (order == 0 || n > released / 2));
ffffffffc0200a16:	00003697          	auipc	a3,0x3
ffffffffc0200a1a:	96268693          	addi	a3,a3,-1694 # ffffffffc0203378 <etext+0x4be>
ffffffffc0200a1e:	00002617          	auipc	a2,0x2
ffffffffc0200a22:	71260613          	addi	a2,a2,1810 # ffffffffc0203130 <etext+0x276>
ffffffffc0200a26:	0a100593          	li	a1,161
ffffffffc0200a2a:	00002517          	auipc	a0,0x2
ffffffffc0200a2e:	71e50513          	addi	a0,a0,1822 # ffffffffc0203148 <etext+0x28e>
ffffffffc0200a32:	f9eff0ef          	jal	ffffffffc02001d0 <__panic>
    assert(!PageReserved(base) && !PageProperty(base));
ffffffffc0200a36:	00003697          	auipc	a3,0x3
ffffffffc0200a3a:	8ca68693          	addi	a3,a3,-1846 # ffffffffc0203300 <etext+0x446>
ffffffffc0200a3e:	00002617          	auipc	a2,0x2
ffffffffc0200a42:	6f260613          	addi	a2,a2,1778 # ffffffffc0203130 <etext+0x276>
ffffffffc0200a46:	09800593          	li	a1,152
ffffffffc0200a4a:	00002517          	auipc	a0,0x2
ffffffffc0200a4e:	6fe50513          	addi	a0,a0,1790 # ffffffffc0203148 <etext+0x28e>
ffffffffc0200a52:	f7eff0ef          	jal	ffffffffc02001d0 <__panic>
    assert(base != NULL && n > 0);
ffffffffc0200a56:	00003697          	auipc	a3,0x3
ffffffffc0200a5a:	89268693          	addi	a3,a3,-1902 # ffffffffc02032e8 <etext+0x42e>
ffffffffc0200a5e:	00002617          	auipc	a2,0x2
ffffffffc0200a62:	6d260613          	addi	a2,a2,1746 # ffffffffc0203130 <etext+0x276>
ffffffffc0200a66:	09400593          	li	a1,148
ffffffffc0200a6a:	00002517          	auipc	a0,0x2
ffffffffc0200a6e:	6de50513          	addi	a0,a0,1758 # ffffffffc0203148 <etext+0x28e>
ffffffffc0200a72:	f5eff0ef          	jal	ffffffffc02001d0 <__panic>
    assert((ppn & (released - 1)) == 0);
ffffffffc0200a76:	00003697          	auipc	a3,0x3
ffffffffc0200a7a:	93a68693          	addi	a3,a3,-1734 # ffffffffc02033b0 <etext+0x4f6>
ffffffffc0200a7e:	00002617          	auipc	a2,0x2
ffffffffc0200a82:	6b260613          	addi	a2,a2,1714 # ffffffffc0203130 <etext+0x276>
ffffffffc0200a86:	0a200593          	li	a1,162
ffffffffc0200a8a:	00002517          	auipc	a0,0x2
ffffffffc0200a8e:	6be50513          	addi	a0,a0,1726 # ffffffffc0203148 <etext+0x28e>
ffffffffc0200a92:	f3eff0ef          	jal	ffffffffc02001d0 <__panic>
    assert(released <=
ffffffffc0200a96:	00003697          	auipc	a3,0x3
ffffffffc0200a9a:	95a68693          	addi	a3,a3,-1702 # ffffffffc02033f0 <etext+0x536>
ffffffffc0200a9e:	00002617          	auipc	a2,0x2
ffffffffc0200aa2:	69260613          	addi	a2,a2,1682 # ffffffffc0203130 <etext+0x276>
ffffffffc0200aa6:	0a400593          	li	a1,164
ffffffffc0200aaa:	00002517          	auipc	a0,0x2
ffffffffc0200aae:	69e50513          	addi	a0,a0,1694 # ffffffffc0203148 <etext+0x28e>
ffffffffc0200ab2:	f1eff0ef          	jal	ffffffffc02001d0 <__panic>
    assert((base->flags & BUDDY_ALLOCATED) != 0);
ffffffffc0200ab6:	00003697          	auipc	a3,0x3
ffffffffc0200aba:	87a68693          	addi	a3,a3,-1926 # ffffffffc0203330 <etext+0x476>
ffffffffc0200abe:	00002617          	auipc	a2,0x2
ffffffffc0200ac2:	67260613          	addi	a2,a2,1650 # ffffffffc0203130 <etext+0x276>
ffffffffc0200ac6:	09900593          	li	a1,153
ffffffffc0200aca:	00002517          	auipc	a0,0x2
ffffffffc0200ace:	67e50513          	addi	a0,a0,1662 # ffffffffc0203148 <etext+0x28e>
ffffffffc0200ad2:	efeff0ef          	jal	ffffffffc02001d0 <__panic>
    assert(order <= BUDDY_MAX_ORDER);
ffffffffc0200ad6:	00003697          	auipc	a3,0x3
ffffffffc0200ada:	88268693          	addi	a3,a3,-1918 # ffffffffc0203358 <etext+0x49e>
ffffffffc0200ade:	00002617          	auipc	a2,0x2
ffffffffc0200ae2:	65260613          	addi	a2,a2,1618 # ffffffffc0203130 <etext+0x276>
ffffffffc0200ae6:	09c00593          	li	a1,156
ffffffffc0200aea:	00002517          	auipc	a0,0x2
ffffffffc0200aee:	65e50513          	addi	a0,a0,1630 # ffffffffc0203148 <etext+0x28e>
ffffffffc0200af2:	edeff0ef          	jal	ffffffffc02001d0 <__panic>

ffffffffc0200af6 <buddy_alloc_pages>:
buddy_alloc_pages(size_t n) {
ffffffffc0200af6:	1141                	addi	sp,sp,-16
ffffffffc0200af8:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200afa:	12050e63          	beqz	a0,ffffffffc0200c36 <buddy_alloc_pages+0x140>
    if (n > buddy_nr_free ||
ffffffffc0200afe:	00008e97          	auipc	t4,0x8
ffffffffc0200b02:	efaebe83          	ld	t4,-262(t4) # ffffffffc02089f8 <buddy_nr_free>
ffffffffc0200b06:	6721                	lui	a4,0x8
ffffffffc0200b08:	87f6                	mv	a5,t4
ffffffffc0200b0a:	11d76163          	bltu	a4,t4,ffffffffc0200c0c <buddy_alloc_pages+0x116>
ffffffffc0200b0e:	0ea7eb63          	bltu	a5,a0,ffffffffc0200c04 <buddy_alloc_pages+0x10e>
    while (((size_t)1 << order) < n) {
ffffffffc0200b12:	4785                	li	a5,1
ffffffffc0200b14:	0ef50e63          	beq	a0,a5,ffffffffc0200c10 <buddy_alloc_pages+0x11a>
    unsigned int order = 0;
ffffffffc0200b18:	4601                	li	a2,0
        order++;
ffffffffc0200b1a:	2605                	addiw	a2,a2,1
    while (((size_t)1 << order) < n) {
ffffffffc0200b1c:	00c798b3          	sll	a7,a5,a2
ffffffffc0200b20:	fea8ede3          	bltu	a7,a0,ffffffffc0200b1a <buddy_alloc_pages+0x24>
    while (found <= BUDDY_MAX_ORDER &&
ffffffffc0200b24:	47bd                	li	a5,15
ffffffffc0200b26:	0cc7ef63          	bltu	a5,a2,ffffffffc0200c04 <buddy_alloc_pages+0x10e>
ffffffffc0200b2a:	02061793          	slli	a5,a2,0x20
ffffffffc0200b2e:	01c7d713          	srli	a4,a5,0x1c
ffffffffc0200b32:	00007697          	auipc	a3,0x7
ffffffffc0200b36:	4e668693          	addi	a3,a3,1254 # ffffffffc0208018 <buddy_free_lists>
ffffffffc0200b3a:	9736                	add	a4,a4,a3
    unsigned int found = order;
ffffffffc0200b3c:	87b2                	mv	a5,a2
    while (found <= BUDDY_MAX_ORDER &&
ffffffffc0200b3e:	4541                	li	a0,16
ffffffffc0200b40:	a029                	j	ffffffffc0200b4a <buddy_alloc_pages+0x54>
        found++;
ffffffffc0200b42:	2785                	addiw	a5,a5,1
    while (found <= BUDDY_MAX_ORDER &&
ffffffffc0200b44:	0741                	addi	a4,a4,16 # 8010 <kern_entry-0xffffffffc01f7ff0>
ffffffffc0200b46:	0aa78f63          	beq	a5,a0,ffffffffc0200c04 <buddy_alloc_pages+0x10e>
ffffffffc0200b4a:	670c                	ld	a1,8(a4)
ffffffffc0200b4c:	fee58be3          	beq	a1,a4,ffffffffc0200b42 <buddy_alloc_pages+0x4c>
    return listelm->next;
ffffffffc0200b50:	02079593          	slli	a1,a5,0x20
ffffffffc0200b54:	01c5d713          	srli	a4,a1,0x1c
ffffffffc0200b58:	9736                	add	a4,a4,a3
ffffffffc0200b5a:	00873303          	ld	t1,8(a4)
    assert(PageProperty(p) && p->property == found);
ffffffffc0200b5e:	ff033703          	ld	a4,-16(t1)
ffffffffc0200b62:	00277593          	andi	a1,a4,2
ffffffffc0200b66:	c9c5                	beqz	a1,ffffffffc0200c16 <buddy_alloc_pages+0x120>
ffffffffc0200b68:	ff832583          	lw	a1,-8(t1)
ffffffffc0200b6c:	0af59563          	bne	a1,a5,ffffffffc0200c16 <buddy_alloc_pages+0x120>
    assert(!PageReserved(p));
ffffffffc0200b70:	00177593          	andi	a1,a4,1
ffffffffc0200b74:	10059163          	bnez	a1,ffffffffc0200c76 <buddy_alloc_pages+0x180>
    assert((p->flags & BUDDY_ALLOCATED) == 0);
ffffffffc0200b78:	00477593          	andi	a1,a4,4
ffffffffc0200b7c:	ede9                	bnez	a1,ffffffffc0200c56 <buddy_alloc_pages+0x160>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200b7e:	00033803          	ld	a6,0(t1)
ffffffffc0200b82:	00833583          	ld	a1,8(t1)
    ClearPageProperty(p);
ffffffffc0200b86:	9b75                	andi	a4,a4,-3
    struct Page *p =
ffffffffc0200b88:	fe830513          	addi	a0,t1,-24
    prev->next = next;
ffffffffc0200b8c:	00b83423          	sd	a1,8(a6)
    next->prev = prev;
ffffffffc0200b90:	0105b023          	sd	a6,0(a1)
    ClearPageProperty(p);
ffffffffc0200b94:	fee33823          	sd	a4,-16(t1)
    elm->prev = elm->next = elm;
ffffffffc0200b98:	00633423          	sd	t1,8(t1)
ffffffffc0200b9c:	00633023          	sd	t1,0(t1)
    while (found > order) {
ffffffffc0200ba0:	04f67363          	bgeu	a2,a5,ffffffffc0200be6 <buddy_alloc_pages+0xf0>
ffffffffc0200ba4:	37fd                	addiw	a5,a5,-1
ffffffffc0200ba6:	02079593          	slli	a1,a5,0x20
ffffffffc0200baa:	01c5d713          	srli	a4,a1,0x1c
ffffffffc0200bae:	96ba                	add	a3,a3,a4
        struct Page *right = p + ((size_t)1 << found);
ffffffffc0200bb0:	02800e13          	li	t3,40
ffffffffc0200bb4:	a011                	j	ffffffffc0200bb8 <buddy_alloc_pages+0xc2>
ffffffffc0200bb6:	37fd                	addiw	a5,a5,-1
ffffffffc0200bb8:	00fe1733          	sll	a4,t3,a5
ffffffffc0200bbc:	972a                	add	a4,a4,a0
        SetPageProperty(right);
ffffffffc0200bbe:	670c                	ld	a1,8(a4)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200bc0:	0086b803          	ld	a6,8(a3)
        right->property = found;
ffffffffc0200bc4:	cb1c                	sw	a5,16(a4)
        SetPageProperty(right);
ffffffffc0200bc6:	0025e593          	ori	a1,a1,2
ffffffffc0200bca:	e70c                	sd	a1,8(a4)
        list_add(&buddy_free_lists[found], &right->page_link);
ffffffffc0200bcc:	01870593          	addi	a1,a4,24
    prev->next = next->prev = elm;
ffffffffc0200bd0:	00b83023          	sd	a1,0(a6)
ffffffffc0200bd4:	e68c                	sd	a1,8(a3)
    elm->prev = prev;
ffffffffc0200bd6:	ef14                	sd	a3,24(a4)
    elm->next = next;
ffffffffc0200bd8:	03073023          	sd	a6,32(a4)
    while (found > order) {
ffffffffc0200bdc:	16c1                	addi	a3,a3,-16
ffffffffc0200bde:	fcf61ce3          	bne	a2,a5,ffffffffc0200bb6 <buddy_alloc_pages+0xc0>
    p->flags |= BUDDY_ALLOCATED;
ffffffffc0200be2:	ff033703          	ld	a4,-16(t1)
}
ffffffffc0200be6:	60a2                	ld	ra,8(sp)
    p->flags |= BUDDY_ALLOCATED;
ffffffffc0200be8:	00476713          	ori	a4,a4,4
    buddy_nr_free -= (size_t)1 << order;
ffffffffc0200bec:	411e88b3          	sub	a7,t4,a7
    p->flags |= BUDDY_ALLOCATED;
ffffffffc0200bf0:	fee33823          	sd	a4,-16(t1)
    buddy_nr_free -= (size_t)1 << order;
ffffffffc0200bf4:	00008797          	auipc	a5,0x8
ffffffffc0200bf8:	e117b223          	sd	a7,-508(a5) # ffffffffc02089f8 <buddy_nr_free>
    p->property = order;
ffffffffc0200bfc:	fec32c23          	sw	a2,-8(t1)
}
ffffffffc0200c00:	0141                	addi	sp,sp,16
ffffffffc0200c02:	8082                	ret
ffffffffc0200c04:	60a2                	ld	ra,8(sp)
        return NULL;
ffffffffc0200c06:	4501                	li	a0,0
}
ffffffffc0200c08:	0141                	addi	sp,sp,16
ffffffffc0200c0a:	8082                	ret
    if (n > buddy_nr_free ||
ffffffffc0200c0c:	87ba                	mv	a5,a4
ffffffffc0200c0e:	b701                	j	ffffffffc0200b0e <buddy_alloc_pages+0x18>
    while (((size_t)1 << order) < n) {
ffffffffc0200c10:	88aa                	mv	a7,a0
    unsigned int order = 0;
ffffffffc0200c12:	4601                	li	a2,0
ffffffffc0200c14:	bf19                	j	ffffffffc0200b2a <buddy_alloc_pages+0x34>
    assert(PageProperty(p) && p->property == found);
ffffffffc0200c16:	00003697          	auipc	a3,0x3
ffffffffc0200c1a:	85a68693          	addi	a3,a3,-1958 # ffffffffc0203470 <etext+0x5b6>
ffffffffc0200c1e:	00002617          	auipc	a2,0x2
ffffffffc0200c22:	51260613          	addi	a2,a2,1298 # ffffffffc0203130 <etext+0x276>
ffffffffc0200c26:	07500593          	li	a1,117
ffffffffc0200c2a:	00002517          	auipc	a0,0x2
ffffffffc0200c2e:	51e50513          	addi	a0,a0,1310 # ffffffffc0203148 <etext+0x28e>
ffffffffc0200c32:	d9eff0ef          	jal	ffffffffc02001d0 <__panic>
    assert(n > 0);
ffffffffc0200c36:	00002697          	auipc	a3,0x2
ffffffffc0200c3a:	6c268693          	addi	a3,a3,1730 # ffffffffc02032f8 <etext+0x43e>
ffffffffc0200c3e:	00002617          	auipc	a2,0x2
ffffffffc0200c42:	4f260613          	addi	a2,a2,1266 # ffffffffc0203130 <etext+0x276>
ffffffffc0200c46:	05a00593          	li	a1,90
ffffffffc0200c4a:	00002517          	auipc	a0,0x2
ffffffffc0200c4e:	4fe50513          	addi	a0,a0,1278 # ffffffffc0203148 <etext+0x28e>
ffffffffc0200c52:	d7eff0ef          	jal	ffffffffc02001d0 <__panic>
    assert((p->flags & BUDDY_ALLOCATED) == 0);
ffffffffc0200c56:	00003697          	auipc	a3,0x3
ffffffffc0200c5a:	85a68693          	addi	a3,a3,-1958 # ffffffffc02034b0 <etext+0x5f6>
ffffffffc0200c5e:	00002617          	auipc	a2,0x2
ffffffffc0200c62:	4d260613          	addi	a2,a2,1234 # ffffffffc0203130 <etext+0x276>
ffffffffc0200c66:	07700593          	li	a1,119
ffffffffc0200c6a:	00002517          	auipc	a0,0x2
ffffffffc0200c6e:	4de50513          	addi	a0,a0,1246 # ffffffffc0203148 <etext+0x28e>
ffffffffc0200c72:	d5eff0ef          	jal	ffffffffc02001d0 <__panic>
    assert(!PageReserved(p));
ffffffffc0200c76:	00003697          	auipc	a3,0x3
ffffffffc0200c7a:	82268693          	addi	a3,a3,-2014 # ffffffffc0203498 <etext+0x5de>
ffffffffc0200c7e:	00002617          	auipc	a2,0x2
ffffffffc0200c82:	4b260613          	addi	a2,a2,1202 # ffffffffc0203130 <etext+0x276>
ffffffffc0200c86:	07600593          	li	a1,118
ffffffffc0200c8a:	00002517          	auipc	a0,0x2
ffffffffc0200c8e:	4be50513          	addi	a0,a0,1214 # ffffffffc0203148 <etext+0x28e>
ffffffffc0200c92:	d3eff0ef          	jal	ffffffffc02001d0 <__panic>

ffffffffc0200c96 <buddy_init_memmap>:
buddy_init_memmap(struct Page *base, size_t n) {
ffffffffc0200c96:	1141                	addi	sp,sp,-16
ffffffffc0200c98:	e406                	sd	ra,8(sp)
ffffffffc0200c9a:	e022                	sd	s0,0(sp)
    assert(n > 0);
ffffffffc0200c9c:	1a058463          	beqz	a1,ffffffffc0200e44 <buddy_init_memmap+0x1ae>
    assert(buddy_nr_free == 0);
ffffffffc0200ca0:	00008797          	auipc	a5,0x8
ffffffffc0200ca4:	d587b783          	ld	a5,-680(a5) # ffffffffc02089f8 <buddy_nr_free>
ffffffffc0200ca8:	16079e63          	bnez	a5,ffffffffc0200e24 <buddy_init_memmap+0x18e>
ffffffffc0200cac:	00008e97          	auipc	t4,0x8
ffffffffc0200cb0:	d7cebe83          	ld	t4,-644(t4) # ffffffffc0208a28 <pages>
ffffffffc0200cb4:	ccccd7b7          	lui	a5,0xccccd
ffffffffc0200cb8:	ccd78793          	addi	a5,a5,-819 # ffffffffcccccccd <end+0xcac4299>
ffffffffc0200cbc:	02079713          	slli	a4,a5,0x20
ffffffffc0200cc0:	41d50eb3          	sub	t4,a0,t4
ffffffffc0200cc4:	97ba                	add	a5,a5,a4
ffffffffc0200cc6:	403ede93          	srai	t4,t4,0x3
ffffffffc0200cca:	02fe8eb3          	mul	t4,t4,a5
ffffffffc0200cce:	00004797          	auipc	a5,0x4
ffffffffc0200cd2:	80a7b783          	ld	a5,-2038(a5) # ffffffffc02044d8 <nbase>
ffffffffc0200cd6:	97f6                	add	a5,a5,t4
ffffffffc0200cd8:	01d7beb3          	sltu	t4,a5,t4
ffffffffc0200cdc:	883e                	mv	a6,a5
    assert(ppn >= nbase && ppn < npage);
ffffffffc0200cde:	120e9363          	bnez	t4,ffffffffc0200e04 <buddy_init_memmap+0x16e>
ffffffffc0200ce2:	00008717          	auipc	a4,0x8
ffffffffc0200ce6:	d3e73703          	ld	a4,-706(a4) # ffffffffc0208a20 <npage>
ffffffffc0200cea:	10e7fd63          	bgeu	a5,a4,ffffffffc0200e04 <buddy_init_memmap+0x16e>
    assert(n <= npage - ppn);
ffffffffc0200cee:	8f1d                	sub	a4,a4,a5
ffffffffc0200cf0:	0eb76a63          	bltu	a4,a1,ffffffffc0200de4 <buddy_init_memmap+0x14e>
    buddy_end_ppn = ppn + n;
ffffffffc0200cf4:	97ae                	add	a5,a5,a1
ffffffffc0200cf6:	00008717          	auipc	a4,0x8
ffffffffc0200cfa:	cef73923          	sd	a5,-782(a4) # ffffffffc02089e8 <buddy_end_ppn>
ffffffffc0200cfe:	01850f13          	addi	t5,a0,24
    buddy_begin_ppn = ppn;
ffffffffc0200d02:	00008797          	auipc	a5,0x8
ffffffffc0200d06:	cf07b723          	sd	a6,-786(a5) # ffffffffc02089f0 <buddy_begin_ppn>
    for (size_t i = 0; i < n; i++) {
ffffffffc0200d0a:	87fa                	mv	a5,t5
ffffffffc0200d0c:	4601                	li	a2,0
        assert(PageReserved(p));
ffffffffc0200d0e:	ff07b703          	ld	a4,-16(a5)
ffffffffc0200d12:	8b05                	andi	a4,a4,1
ffffffffc0200d14:	cb45                	beqz	a4,ffffffffc0200dc4 <buddy_init_memmap+0x12e>
        p->flags = 0;
ffffffffc0200d16:	fe07b823          	sd	zero,-16(a5)
        p->property = 0;
ffffffffc0200d1a:	fe07ac23          	sw	zero,-8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200d1e:	fe07a423          	sw	zero,-24(a5)
    elm->prev = elm->next = elm;
ffffffffc0200d22:	e79c                	sd	a5,8(a5)
ffffffffc0200d24:	e39c                	sd	a5,0(a5)
    for (size_t i = 0; i < n; i++) {
ffffffffc0200d26:	0605                	addi	a2,a2,1
ffffffffc0200d28:	02878793          	addi	a5,a5,40
ffffffffc0200d2c:	fec591e3          	bne	a1,a2,ffffffffc0200d0e <buddy_init_memmap+0x78>
ffffffffc0200d30:	00007297          	auipc	t0,0x7
ffffffffc0200d34:	2e828293          	addi	t0,t0,744 # ffffffffc0208018 <buddy_free_lists>
            size_t larger = (size_t)1 << (order + 1);
ffffffffc0200d38:	4885                	li	a7,1
        while (order < BUDDY_MAX_ORDER) {
ffffffffc0200d3a:	433d                	li	t1,15
        base += count;
ffffffffc0200d3c:	02800413          	li	s0,40
        unsigned int order = 0;
ffffffffc0200d40:	4781                	li	a5,0
            size_t larger = (size_t)1 << (order + 1);
ffffffffc0200d42:	85be                	mv	a1,a5
ffffffffc0200d44:	2785                	addiw	a5,a5,1
ffffffffc0200d46:	00f896b3          	sll	a3,a7,a5
            if ((ppn & (larger - 1)) != 0 || larger > n) {
ffffffffc0200d4a:	fff68713          	addi	a4,a3,-1
ffffffffc0200d4e:	01077733          	and	a4,a4,a6
ffffffffc0200d52:	e739                	bnez	a4,ffffffffc0200da0 <buddy_init_memmap+0x10a>
ffffffffc0200d54:	04d66663          	bltu	a2,a3,ffffffffc0200da0 <buddy_init_memmap+0x10a>
        while (order < BUDDY_MAX_ORDER) {
ffffffffc0200d58:	fe6795e3          	bne	a5,t1,ffffffffc0200d42 <buddy_init_memmap+0xac>
ffffffffc0200d5c:	001403b7          	lui	t2,0x140
ffffffffc0200d60:	66a1                	lui	a3,0x8
ffffffffc0200d62:	0f000e13          	li	t3,240
    __list_add(elm, listelm, listelm->next);
ffffffffc0200d66:	02079593          	slli	a1,a5,0x20
ffffffffc0200d6a:	01c5d713          	srli	a4,a1,0x1c
        SetPageProperty(base);
ffffffffc0200d6e:	650c                	ld	a1,8(a0)
ffffffffc0200d70:	9716                	add	a4,a4,t0
ffffffffc0200d72:	00873f83          	ld	t6,8(a4)
ffffffffc0200d76:	0025e593          	ori	a1,a1,2
        base->property = order;
ffffffffc0200d7a:	c91c                	sw	a5,16(a0)
        SetPageProperty(base);
ffffffffc0200d7c:	e50c                	sd	a1,8(a0)
    prev->next = next->prev = elm;
ffffffffc0200d7e:	01efb023          	sd	t5,0(t6)
ffffffffc0200d82:	01e73423          	sd	t5,8(a4)
        list_add(&buddy_free_lists[order], &base->page_link);
ffffffffc0200d86:	01c287b3          	add	a5,t0,t3
    elm->prev = prev;
ffffffffc0200d8a:	ed1c                	sd	a5,24(a0)
    elm->next = next;
ffffffffc0200d8c:	03f53023          	sd	t6,32(a0)
        n -= count;
ffffffffc0200d90:	8e15                	sub	a2,a2,a3
        buddy_nr_free += count;
ffffffffc0200d92:	9eb6                	add	t4,t4,a3
        ppn += count;
ffffffffc0200d94:	9836                	add	a6,a6,a3
        base += count;
ffffffffc0200d96:	951e                	add	a0,a0,t2
    while (n > 0) {
ffffffffc0200d98:	ce11                	beqz	a2,ffffffffc0200db4 <buddy_init_memmap+0x11e>
ffffffffc0200d9a:	01850f13          	addi	t5,a0,24
ffffffffc0200d9e:	b74d                	j	ffffffffc0200d40 <buddy_init_memmap+0xaa>
ffffffffc0200da0:	02059793          	slli	a5,a1,0x20
ffffffffc0200da4:	01c7de13          	srli	t3,a5,0x1c
        size_t count = (size_t)1 << order;
ffffffffc0200da8:	00b896b3          	sll	a3,a7,a1
        base += count;
ffffffffc0200dac:	00b413b3          	sll	t2,s0,a1
ffffffffc0200db0:	87ae                	mv	a5,a1
ffffffffc0200db2:	bf55                	j	ffffffffc0200d66 <buddy_init_memmap+0xd0>
}
ffffffffc0200db4:	60a2                	ld	ra,8(sp)
ffffffffc0200db6:	6402                	ld	s0,0(sp)
ffffffffc0200db8:	00008797          	auipc	a5,0x8
ffffffffc0200dbc:	c5d7b023          	sd	t4,-960(a5) # ffffffffc02089f8 <buddy_nr_free>
ffffffffc0200dc0:	0141                	addi	sp,sp,16
ffffffffc0200dc2:	8082                	ret
        assert(PageReserved(p));
ffffffffc0200dc4:	00002697          	auipc	a3,0x2
ffffffffc0200dc8:	76468693          	addi	a3,a3,1892 # ffffffffc0203528 <etext+0x66e>
ffffffffc0200dcc:	00002617          	auipc	a2,0x2
ffffffffc0200dd0:	36460613          	addi	a2,a2,868 # ffffffffc0203130 <etext+0x276>
ffffffffc0200dd4:	02f00593          	li	a1,47
ffffffffc0200dd8:	00002517          	auipc	a0,0x2
ffffffffc0200ddc:	37050513          	addi	a0,a0,880 # ffffffffc0203148 <etext+0x28e>
ffffffffc0200de0:	bf0ff0ef          	jal	ffffffffc02001d0 <__panic>
    assert(n <= npage - ppn);
ffffffffc0200de4:	00002697          	auipc	a3,0x2
ffffffffc0200de8:	72c68693          	addi	a3,a3,1836 # ffffffffc0203510 <etext+0x656>
ffffffffc0200dec:	00002617          	auipc	a2,0x2
ffffffffc0200df0:	34460613          	addi	a2,a2,836 # ffffffffc0203130 <etext+0x276>
ffffffffc0200df4:	02600593          	li	a1,38
ffffffffc0200df8:	00002517          	auipc	a0,0x2
ffffffffc0200dfc:	35050513          	addi	a0,a0,848 # ffffffffc0203148 <etext+0x28e>
ffffffffc0200e00:	bd0ff0ef          	jal	ffffffffc02001d0 <__panic>
    assert(ppn >= nbase && ppn < npage);
ffffffffc0200e04:	00002697          	auipc	a3,0x2
ffffffffc0200e08:	6ec68693          	addi	a3,a3,1772 # ffffffffc02034f0 <etext+0x636>
ffffffffc0200e0c:	00002617          	auipc	a2,0x2
ffffffffc0200e10:	32460613          	addi	a2,a2,804 # ffffffffc0203130 <etext+0x276>
ffffffffc0200e14:	02500593          	li	a1,37
ffffffffc0200e18:	00002517          	auipc	a0,0x2
ffffffffc0200e1c:	33050513          	addi	a0,a0,816 # ffffffffc0203148 <etext+0x28e>
ffffffffc0200e20:	bb0ff0ef          	jal	ffffffffc02001d0 <__panic>
    assert(buddy_nr_free == 0);
ffffffffc0200e24:	00002697          	auipc	a3,0x2
ffffffffc0200e28:	6b468693          	addi	a3,a3,1716 # ffffffffc02034d8 <etext+0x61e>
ffffffffc0200e2c:	00002617          	auipc	a2,0x2
ffffffffc0200e30:	30460613          	addi	a2,a2,772 # ffffffffc0203130 <etext+0x276>
ffffffffc0200e34:	02200593          	li	a1,34
ffffffffc0200e38:	00002517          	auipc	a0,0x2
ffffffffc0200e3c:	31050513          	addi	a0,a0,784 # ffffffffc0203148 <etext+0x28e>
ffffffffc0200e40:	b90ff0ef          	jal	ffffffffc02001d0 <__panic>
    assert(n > 0);
ffffffffc0200e44:	00002697          	auipc	a3,0x2
ffffffffc0200e48:	4b468693          	addi	a3,a3,1204 # ffffffffc02032f8 <etext+0x43e>
ffffffffc0200e4c:	00002617          	auipc	a2,0x2
ffffffffc0200e50:	2e460613          	addi	a2,a2,740 # ffffffffc0203130 <etext+0x276>
ffffffffc0200e54:	45fd                	li	a1,31
ffffffffc0200e56:	00002517          	auipc	a0,0x2
ffffffffc0200e5a:	2f250513          	addi	a0,a0,754 # ffffffffc0203148 <etext+0x28e>
ffffffffc0200e5e:	b72ff0ef          	jal	ffffffffc02001d0 <__panic>

ffffffffc0200e62 <buddy_check>:
            (unsigned long)obtained);
}


static void
buddy_check(void) {
ffffffffc0200e62:	7151                	addi	sp,sp,-240
ffffffffc0200e64:	f586                	sd	ra,232(sp)
ffffffffc0200e66:	f1a2                	sd	s0,224(sp)
ffffffffc0200e68:	eda6                	sd	s1,216(sp)
ffffffffc0200e6a:	e9ca                	sd	s2,208(sp)
ffffffffc0200e6c:	e5ce                	sd	s3,200(sp)
ffffffffc0200e6e:	e1d2                	sd	s4,192(sp)
ffffffffc0200e70:	fd56                	sd	s5,184(sp)
ffffffffc0200e72:	f95a                	sd	s6,176(sp)
ffffffffc0200e74:	f55e                	sd	s7,168(sp)
ffffffffc0200e76:	f162                	sd	s8,160(sp)
ffffffffc0200e78:	ed66                	sd	s9,152(sp)
ffffffffc0200e7a:	e96a                	sd	s10,144(sp)
    buddy_init_check();
ffffffffc0200e7c:	f38ff0ef          	jal	ffffffffc02005b4 <buddy_init_check>
    size_t before = nr_free_pages();
ffffffffc0200e80:	01d000ef          	jal	ffffffffc020169c <nr_free_pages>
    assert(before >= 13);
ffffffffc0200e84:	47b1                	li	a5,12
ffffffffc0200e86:	78a7ff63          	bgeu	a5,a0,ffffffffc0201624 <buddy_check+0x7c2>
ffffffffc0200e8a:	00007b17          	auipc	s6,0x7
ffffffffc0200e8e:	18eb0b13          	addi	s6,s6,398 # ffffffffc0208018 <buddy_free_lists>
ffffffffc0200e92:	01010a93          	addi	s5,sp,16
ffffffffc0200e96:	8a2a                	mv	s4,a0
ffffffffc0200e98:	895a                	mv	s2,s6
ffffffffc0200e9a:	87da                	mv	a5,s6
ffffffffc0200e9c:	00007417          	auipc	s0,0x7
ffffffffc0200ea0:	27c40413          	addi	s0,s0,636 # ffffffffc0208118 <caches>
ffffffffc0200ea4:	8756                	mv	a4,s5
    return listelm->next;
ffffffffc0200ea6:	6794                	ld	a3,8(a5)
    size_t count = 0;
ffffffffc0200ea8:	4601                	li	a2,0
         le != head; le = list_next(le)) {
ffffffffc0200eaa:	00f68663          	beq	a3,a5,ffffffffc0200eb6 <buddy_check+0x54>
ffffffffc0200eae:	6694                	ld	a3,8(a3)
        count++;
ffffffffc0200eb0:	0605                	addi	a2,a2,1
         le != head; le = list_next(le)) {
ffffffffc0200eb2:	fef69ee3          	bne	a3,a5,ffffffffc0200eae <buddy_check+0x4c>
        blocks_before[i] = buddy_count_blocks(i);
ffffffffc0200eb6:	e310                	sd	a2,0(a4)
    for (unsigned int i = 0; i <= BUDDY_MAX_ORDER; i++) {
ffffffffc0200eb8:	07c1                	addi	a5,a5,16
ffffffffc0200eba:	0721                	addi	a4,a4,8
ffffffffc0200ebc:	fe8795e3          	bne	a5,s0,ffffffffc0200ea6 <buddy_check+0x44>
    struct Page *p = alloc_pages(1);
ffffffffc0200ec0:	4505                	li	a0,1
ffffffffc0200ec2:	7c2000ef          	jal	ffffffffc0201684 <alloc_pages>
ffffffffc0200ec6:	8c2a                	mv	s8,a0
    struct Page *q = alloc_pages(3);
ffffffffc0200ec8:	450d                	li	a0,3
ffffffffc0200eca:	7ba000ef          	jal	ffffffffc0201684 <alloc_pages>
ffffffffc0200ece:	8d2a                	mv	s10,a0
    struct Page *r = alloc_pages(8);
ffffffffc0200ed0:	4521                	li	a0,8
ffffffffc0200ed2:	7b2000ef          	jal	ffffffffc0201684 <alloc_pages>
    assert(p != NULL && q != NULL && r != NULL);
ffffffffc0200ed6:	001c3793          	seqz	a5,s8
ffffffffc0200eda:	001d3713          	seqz	a4,s10
ffffffffc0200ede:	8fd9                	or	a5,a5,a4
    struct Page *r = alloc_pages(8);
ffffffffc0200ee0:	8baa                	mv	s7,a0
    assert(p != NULL && q != NULL && r != NULL);
ffffffffc0200ee2:	72079163          	bnez	a5,ffffffffc0201604 <buddy_check+0x7a2>
ffffffffc0200ee6:	70050f63          	beqz	a0,ffffffffc0201604 <buddy_check+0x7a2>
    assert(p->property == 0 && q->property == 2 && r->property == 3);
ffffffffc0200eea:	010c2783          	lw	a5,16(s8)
ffffffffc0200eee:	6e079b63          	bnez	a5,ffffffffc02015e4 <buddy_check+0x782>
ffffffffc0200ef2:	010d2703          	lw	a4,16(s10)
ffffffffc0200ef6:	4789                	li	a5,2
ffffffffc0200ef8:	6ef71663          	bne	a4,a5,ffffffffc02015e4 <buddy_check+0x782>
ffffffffc0200efc:	4918                	lw	a4,16(a0)
ffffffffc0200efe:	478d                	li	a5,3
ffffffffc0200f00:	6ef71263          	bne	a4,a5,ffffffffc02015e4 <buddy_check+0x782>
    assert(!PageProperty(p) && !PageProperty(q) && !PageProperty(r));
ffffffffc0200f04:	008c3683          	ld	a3,8(s8)
ffffffffc0200f08:	0026f793          	andi	a5,a3,2
ffffffffc0200f0c:	6a079c63          	bnez	a5,ffffffffc02015c4 <buddy_check+0x762>
ffffffffc0200f10:	008d3703          	ld	a4,8(s10)
ffffffffc0200f14:	00277793          	andi	a5,a4,2
ffffffffc0200f18:	6a079663          	bnez	a5,ffffffffc02015c4 <buddy_check+0x762>
ffffffffc0200f1c:	651c                	ld	a5,8(a0)
ffffffffc0200f1e:	0027f613          	andi	a2,a5,2
ffffffffc0200f22:	6a061163          	bnez	a2,ffffffffc02015c4 <buddy_check+0x762>
    assert((p->flags & BUDDY_ALLOCATED) != 0);
ffffffffc0200f26:	8a91                	andi	a3,a3,4
ffffffffc0200f28:	66068e63          	beqz	a3,ffffffffc02015a4 <buddy_check+0x742>
    assert((q->flags & BUDDY_ALLOCATED) != 0);
ffffffffc0200f2c:	8b11                	andi	a4,a4,4
ffffffffc0200f2e:	64070b63          	beqz	a4,ffffffffc0201584 <buddy_check+0x722>
    assert((r->flags & BUDDY_ALLOCATED) != 0);
ffffffffc0200f32:	8b91                	andi	a5,a5,4
ffffffffc0200f34:	62078863          	beqz	a5,ffffffffc0201564 <buddy_check+0x702>
    assert(nr_free_pages() == before - 13);
ffffffffc0200f38:	764000ef          	jal	ffffffffc020169c <nr_free_pages>
ffffffffc0200f3c:	ff3a0793          	addi	a5,s4,-13
ffffffffc0200f40:	54f51263          	bne	a0,a5,ffffffffc0201484 <buddy_check+0x622>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200f44:	00008997          	auipc	s3,0x8
ffffffffc0200f48:	ae498993          	addi	s3,s3,-1308 # ffffffffc0208a28 <pages>
ffffffffc0200f4c:	0009b783          	ld	a5,0(s3)
ffffffffc0200f50:	ccccd737          	lui	a4,0xccccd
ffffffffc0200f54:	ccd70713          	addi	a4,a4,-819 # ffffffffcccccccd <end+0xcac4299>
ffffffffc0200f58:	02071613          	slli	a2,a4,0x20
ffffffffc0200f5c:	963a                	add	a2,a2,a4
ffffffffc0200f5e:	40fd06b3          	sub	a3,s10,a5
ffffffffc0200f62:	40fb8733          	sub	a4,s7,a5
ffffffffc0200f66:	868d                	srai	a3,a3,0x3
ffffffffc0200f68:	870d                	srai	a4,a4,0x3
ffffffffc0200f6a:	02c686b3          	mul	a3,a3,a2
ffffffffc0200f6e:	00003497          	auipc	s1,0x3
ffffffffc0200f72:	56a4b483          	ld	s1,1386(s1) # ffffffffc02044d8 <nbase>
ffffffffc0200f76:	02c70733          	mul	a4,a4,a2
ffffffffc0200f7a:	96a6                	add	a3,a3,s1
    assert((b & 3) == 0 && (c & 7) == 0);
ffffffffc0200f7c:	0036fc93          	andi	s9,a3,3
ffffffffc0200f80:	9726                	add	a4,a4,s1
ffffffffc0200f82:	00777593          	andi	a1,a4,7
ffffffffc0200f86:	00bcecb3          	or	s9,s9,a1
ffffffffc0200f8a:	360c9d63          	bnez	s9,ffffffffc0201304 <buddy_check+0x4a2>
ffffffffc0200f8e:	40fc07b3          	sub	a5,s8,a5
ffffffffc0200f92:	878d                	srai	a5,a5,0x3
ffffffffc0200f94:	02c787b3          	mul	a5,a5,a2
ffffffffc0200f98:	97a6                	add	a5,a5,s1
    assert(a + 1 <= b || b + 4 <= a);
ffffffffc0200f9a:	00d7e663          	bltu	a5,a3,ffffffffc0200fa6 <buddy_check+0x144>
ffffffffc0200f9e:	00468613          	addi	a2,a3,4
ffffffffc0200fa2:	3ac7e163          	bltu	a5,a2,ffffffffc0201344 <buddy_check+0x4e2>
    assert(a + 1 <= c || c + 8 <= a);
ffffffffc0200fa6:	24e7fb63          	bgeu	a5,a4,ffffffffc02011fc <buddy_check+0x39a>
    assert(b + 4 <= c || c + 8 <= b);
ffffffffc0200faa:	00468793          	addi	a5,a3,4
ffffffffc0200fae:	00f77563          	bgeu	a4,a5,ffffffffc0200fb8 <buddy_check+0x156>
ffffffffc0200fb2:	0721                	addi	a4,a4,8
ffffffffc0200fb4:	32e6e863          	bltu	a3,a4,ffffffffc02012e4 <buddy_check+0x482>
    free_pages(q, 3);
ffffffffc0200fb8:	856a                	mv	a0,s10
ffffffffc0200fba:	458d                	li	a1,3
ffffffffc0200fbc:	6d4000ef          	jal	ffffffffc0201690 <free_pages>
    assert(nr_free_pages() == before - 9);
ffffffffc0200fc0:	6dc000ef          	jal	ffffffffc020169c <nr_free_pages>
ffffffffc0200fc4:	ff7a0793          	addi	a5,s4,-9
ffffffffc0200fc8:	44f51e63          	bne	a0,a5,ffffffffc0201424 <buddy_check+0x5c2>
    free_pages(p, 1);
ffffffffc0200fcc:	8562                	mv	a0,s8
ffffffffc0200fce:	4585                	li	a1,1
ffffffffc0200fd0:	6c0000ef          	jal	ffffffffc0201690 <free_pages>
    assert(nr_free_pages() == before - 8);
ffffffffc0200fd4:	6c8000ef          	jal	ffffffffc020169c <nr_free_pages>
ffffffffc0200fd8:	ff8a0793          	addi	a5,s4,-8
ffffffffc0200fdc:	42f51463          	bne	a0,a5,ffffffffc0201404 <buddy_check+0x5a2>
    free_pages(r, 8);
ffffffffc0200fe0:	855e                	mv	a0,s7
ffffffffc0200fe2:	45a1                	li	a1,8
ffffffffc0200fe4:	6ac000ef          	jal	ffffffffc0201690 <free_pages>
    assert(nr_free_pages() == before);
ffffffffc0200fe8:	6b4000ef          	jal	ffffffffc020169c <nr_free_pages>
ffffffffc0200fec:	00007697          	auipc	a3,0x7
ffffffffc0200ff0:	02c68693          	addi	a3,a3,44 # ffffffffc0208018 <buddy_free_lists>
ffffffffc0200ff4:	3eaa1863          	bne	s4,a0,ffffffffc02013e4 <buddy_check+0x582>
ffffffffc0200ff8:	669c                	ld	a5,8(a3)
    size_t count = 0;
ffffffffc0200ffa:	4701                	li	a4,0
         le != head; le = list_next(le)) {
ffffffffc0200ffc:	00d78663          	beq	a5,a3,ffffffffc0201008 <buddy_check+0x1a6>
ffffffffc0201000:	679c                	ld	a5,8(a5)
        count++;
ffffffffc0201002:	0705                	addi	a4,a4,1
         le != head; le = list_next(le)) {
ffffffffc0201004:	fed79ee3          	bne	a5,a3,ffffffffc0201000 <buddy_check+0x19e>
        assert(buddy_count_blocks(i) == blocks_before[i]);
ffffffffc0201008:	000ab783          	ld	a5,0(s5)
ffffffffc020100c:	3ae79c63          	bne	a5,a4,ffffffffc02013c4 <buddy_check+0x562>
    for (unsigned int i = 0; i <= BUDDY_MAX_ORDER; i++) {
ffffffffc0201010:	06c1                	addi	a3,a3,16
ffffffffc0201012:	0aa1                	addi	s5,s5,8
ffffffffc0201014:	fe8692e3          	bne	a3,s0,ffffffffc0200ff8 <buddy_check+0x196>
    assert(alloc_pages(((size_t)1 << BUDDY_MAX_ORDER) + 1) == NULL);
ffffffffc0201018:	6521                	lui	a0,0x8
ffffffffc020101a:	0505                	addi	a0,a0,1 # 8001 <kern_entry-0xffffffffc01f7fff>
ffffffffc020101c:	668000ef          	jal	ffffffffc0201684 <alloc_pages>
ffffffffc0201020:	38051263          	bnez	a0,ffffffffc02013a4 <buddy_check+0x542>
    assert(nr_free_pages() == before);
ffffffffc0201024:	678000ef          	jal	ffffffffc020169c <nr_free_pages>
ffffffffc0201028:	34aa1e63          	bne	s4,a0,ffffffffc0201384 <buddy_check+0x522>
    cprintf("buddy_alloc_free_check() succeeded!\n");
ffffffffc020102c:	00002517          	auipc	a0,0x2
ffffffffc0201030:	7a450513          	addi	a0,a0,1956 # ffffffffc02037d0 <etext+0x916>
ffffffffc0201034:	91cff0ef          	jal	ffffffffc0200150 <cprintf>
    size_t before = nr_free_pages();
ffffffffc0201038:	664000ef          	jal	ffffffffc020169c <nr_free_pages>
    assert(before >= 4);
ffffffffc020103c:	478d                	li	a5,3
    size_t before = nr_free_pages();
ffffffffc020103e:	8aaa                	mv	s5,a0
    assert(before >= 4);
ffffffffc0201040:	62a7f263          	bgeu	a5,a0,ffffffffc0201664 <buddy_check+0x802>
ffffffffc0201044:	01010a13          	addi	s4,sp,16
ffffffffc0201048:	8652                	mv	a2,s4
ffffffffc020104a:	00007697          	auipc	a3,0x7
ffffffffc020104e:	fce68693          	addi	a3,a3,-50 # ffffffffc0208018 <buddy_free_lists>
ffffffffc0201052:	669c                	ld	a5,8(a3)
    size_t count = 0;
ffffffffc0201054:	4701                	li	a4,0
         le != head; le = list_next(le)) {
ffffffffc0201056:	00d78663          	beq	a5,a3,ffffffffc0201062 <buddy_check+0x200>
ffffffffc020105a:	679c                	ld	a5,8(a5)
        count++;
ffffffffc020105c:	0705                	addi	a4,a4,1
         le != head; le = list_next(le)) {
ffffffffc020105e:	fed79ee3          	bne	a5,a3,ffffffffc020105a <buddy_check+0x1f8>
        blocks_before[i] = buddy_count_blocks(i);
ffffffffc0201062:	e218                	sd	a4,0(a2)
    for (unsigned int i = 0; i <= BUDDY_MAX_ORDER; i++) {
ffffffffc0201064:	06c1                	addi	a3,a3,16
ffffffffc0201066:	0621                	addi	a2,a2,8
ffffffffc0201068:	fe8695e3          	bne	a3,s0,ffffffffc0201052 <buddy_check+0x1f0>
    elm->prev = elm->next = elm;
ffffffffc020106c:	8b8a                	mv	s7,sp
ffffffffc020106e:	e40a                	sd	sp,8(sp)
ffffffffc0201070:	e00a                	sd	sp,0(sp)
    while ((p = alloc_page()) != NULL) {
ffffffffc0201072:	4c05                	li	s8,1
ffffffffc0201074:	a825                	j	ffffffffc02010ac <buddy_check+0x24a>
        assert(obtained < before);
ffffffffc0201076:	259a8763          	beq	s5,s9,ffffffffc02012c4 <buddy_check+0x462>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020107a:	651c                	ld	a5,8(a0)
ffffffffc020107c:	0037f713          	andi	a4,a5,3
ffffffffc0201080:	1c071263          	bnez	a4,ffffffffc0201244 <buddy_check+0x3e2>
        assert(p->property == 0);
ffffffffc0201084:	4918                	lw	a4,16(a0)
ffffffffc0201086:	20071f63          	bnez	a4,ffffffffc02012a4 <buddy_check+0x442>
        assert((p->flags & BUDDY_ALLOCATED) != 0);
ffffffffc020108a:	8b91                	andi	a5,a5,4
ffffffffc020108c:	1e078c63          	beqz	a5,ffffffffc0201284 <buddy_check+0x422>
        assert(page_ref(p) == 0);
ffffffffc0201090:	411c                	lw	a5,0(a0)
ffffffffc0201092:	1c079963          	bnez	a5,ffffffffc0201264 <buddy_check+0x402>
    __list_add(elm, listelm, listelm->next);
ffffffffc0201096:	67a2                	ld	a5,8(sp)
        list_add(&held, &p->page_link);
ffffffffc0201098:	01850713          	addi	a4,a0,24
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc020109c:	01852023          	sw	s8,0(a0)
    prev->next = next->prev = elm;
ffffffffc02010a0:	e398                	sd	a4,0(a5)
        obtained++;
ffffffffc02010a2:	0c85                	addi	s9,s9,1
ffffffffc02010a4:	e43a                	sd	a4,8(sp)
    elm->next = next;
ffffffffc02010a6:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02010a8:	01753c23          	sd	s7,24(a0)
    while ((p = alloc_page()) != NULL) {
ffffffffc02010ac:	4505                	li	a0,1
ffffffffc02010ae:	5d6000ef          	jal	ffffffffc0201684 <alloc_pages>
ffffffffc02010b2:	f171                	bnez	a0,ffffffffc0201076 <buddy_check+0x214>
    assert(obtained == before);
ffffffffc02010b4:	399a9863          	bne	s5,s9,ffffffffc0201444 <buddy_check+0x5e2>
    assert(nr_free_pages() == 0);
ffffffffc02010b8:	5e4000ef          	jal	ffffffffc020169c <nr_free_pages>
ffffffffc02010bc:	58051463          	bnez	a0,ffffffffc0201644 <buddy_check+0x7e2>
    assert(alloc_page() == NULL);
ffffffffc02010c0:	4505                	li	a0,1
ffffffffc02010c2:	5c2000ef          	jal	ffffffffc0201684 <alloc_pages>
ffffffffc02010c6:	00007797          	auipc	a5,0x7
ffffffffc02010ca:	f5278793          	addi	a5,a5,-174 # ffffffffc0208018 <buddy_free_lists>
ffffffffc02010ce:	38051b63          	bnez	a0,ffffffffc0201464 <buddy_check+0x602>
        assert(list_empty(&buddy_free_lists[i]));
ffffffffc02010d2:	6798                	ld	a4,8(a5)
ffffffffc02010d4:	24f71863          	bne	a4,a5,ffffffffc0201324 <buddy_check+0x4c2>
    for (unsigned int i = 0; i <= BUDDY_MAX_ORDER; i++) {
ffffffffc02010d8:	07c1                	addi	a5,a5,16
ffffffffc02010da:	fe879ce3          	bne	a5,s0,ffffffffc02010d2 <buddy_check+0x270>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02010de:	ccccd7b7          	lui	a5,0xccccd
    return listelm->next;
ffffffffc02010e2:	6aa2                	ld	s5,8(sp)
ffffffffc02010e4:	ccd78793          	addi	a5,a5,-819 # ffffffffcccccccd <end+0xcac4299>
ffffffffc02010e8:	02079c13          	slli	s8,a5,0x20
ffffffffc02010ec:	9c3e                	add	s8,s8,a5
    size_t released_even = 0;
ffffffffc02010ee:	4d01                	li	s10,0
    while (le != &held) {
ffffffffc02010f0:	137a8a63          	beq	s5,s7,ffffffffc0201224 <buddy_check+0x3c2>
ffffffffc02010f4:	0009b783          	ld	a5,0(s3)
        p = le2page(le, page_link);
ffffffffc02010f8:	fe8a8513          	addi	a0,s5,-24
ffffffffc02010fc:	8756                	mv	a4,s5
ffffffffc02010fe:	40f507b3          	sub	a5,a0,a5
ffffffffc0201102:	878d                	srai	a5,a5,0x3
ffffffffc0201104:	038787b3          	mul	a5,a5,s8
ffffffffc0201108:	008aba83          	ld	s5,8(s5)
ffffffffc020110c:	97a6                	add	a5,a5,s1
        if ((page2ppn(p) & 1) == 0) {
ffffffffc020110e:	8b85                	andi	a5,a5,1
ffffffffc0201110:	cbe1                	beqz	a5,ffffffffc02011e0 <buddy_check+0x37e>
    while (le != &held) {
ffffffffc0201112:	ff7a91e3          	bne	s5,s7,ffffffffc02010f4 <buddy_check+0x292>
    assert(released_even >= 2);
ffffffffc0201116:	4785                	li	a5,1
ffffffffc0201118:	11a7f663          	bgeu	a5,s10,ffffffffc0201224 <buddy_check+0x3c2>
    assert(nr_free_pages() == released_even);
ffffffffc020111c:	580000ef          	jal	ffffffffc020169c <nr_free_pages>
ffffffffc0201120:	3aad1263          	bne	s10,a0,ffffffffc02014c4 <buddy_check+0x662>
ffffffffc0201124:	00893783          	ld	a5,8(s2)
    size_t count = 0;
ffffffffc0201128:	4481                	li	s1,0
         le != head; le = list_next(le)) {
ffffffffc020112a:	37278d63          	beq	a5,s2,ffffffffc02014a4 <buddy_check+0x642>
ffffffffc020112e:	679c                	ld	a5,8(a5)
        count++;
ffffffffc0201130:	0485                	addi	s1,s1,1
         le != head; le = list_next(le)) {
ffffffffc0201132:	ff279ee3          	bne	a5,s2,ffffffffc020112e <buddy_check+0x2cc>
    return count;
ffffffffc0201136:	00007797          	auipc	a5,0x7
ffffffffc020113a:	ef278793          	addi	a5,a5,-270 # ffffffffc0208028 <buddy_free_lists+0x10>
    assert(buddy_count_blocks(0) == released_even);
ffffffffc020113e:	369d1363          	bne	s10,s1,ffffffffc02014a4 <buddy_check+0x642>
        assert(list_empty(&buddy_free_lists[i]));
ffffffffc0201142:	6798                	ld	a4,8(a5)
ffffffffc0201144:	40f71063          	bne	a4,a5,ffffffffc0201544 <buddy_check+0x6e2>
    for (unsigned int i = 1; i <= BUDDY_MAX_ORDER; i++) {
ffffffffc0201148:	07c1                	addi	a5,a5,16
ffffffffc020114a:	fe879ce3          	bne	a5,s0,ffffffffc0201142 <buddy_check+0x2e0>
    assert(alloc_pages(2) == NULL);
ffffffffc020114e:	4509                	li	a0,2
ffffffffc0201150:	534000ef          	jal	ffffffffc0201684 <alloc_pages>
ffffffffc0201154:	3c051863          	bnez	a0,ffffffffc0201524 <buddy_check+0x6c2>
    assert(nr_free_pages() == released_even);
ffffffffc0201158:	544000ef          	jal	ffffffffc020169c <nr_free_pages>
ffffffffc020115c:	00a48e63          	beq	s1,a0,ffffffffc0201178 <buddy_check+0x316>
ffffffffc0201160:	a655                	j	ffffffffc0201504 <buddy_check+0x6a2>
    __list_del(listelm->prev, listelm->next);
ffffffffc0201162:	6394                	ld	a3,0(a5)
ffffffffc0201164:	6798                	ld	a4,8(a5)
        free_page(p);
ffffffffc0201166:	fe878513          	addi	a0,a5,-24
ffffffffc020116a:	4585                	li	a1,1
    prev->next = next;
ffffffffc020116c:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc020116e:	e314                	sd	a3,0(a4)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201170:	fe07a423          	sw	zero,-24(a5)
ffffffffc0201174:	51c000ef          	jal	ffffffffc0201690 <free_pages>
    return list->next == list;
ffffffffc0201178:	67a2                	ld	a5,8(sp)
    while (!list_empty(&held)) {
ffffffffc020117a:	ff7794e3          	bne	a5,s7,ffffffffc0201162 <buddy_check+0x300>
    assert(nr_free_pages() == before);
ffffffffc020117e:	51e000ef          	jal	ffffffffc020169c <nr_free_pages>
ffffffffc0201182:	36ac9163          	bne	s9,a0,ffffffffc02014e4 <buddy_check+0x682>
    return listelm->next;
ffffffffc0201186:	008b3783          	ld	a5,8(s6)
    size_t count = 0;
ffffffffc020118a:	4701                	li	a4,0
         le != head; le = list_next(le)) {
ffffffffc020118c:	01678663          	beq	a5,s6,ffffffffc0201198 <buddy_check+0x336>
ffffffffc0201190:	679c                	ld	a5,8(a5)
        count++;
ffffffffc0201192:	0705                	addi	a4,a4,1
         le != head; le = list_next(le)) {
ffffffffc0201194:	ff679ee3          	bne	a5,s6,ffffffffc0201190 <buddy_check+0x32e>
        assert(buddy_count_blocks(i) == blocks_before[i]);
ffffffffc0201198:	000a3783          	ld	a5,0(s4)
ffffffffc020119c:	1ce79463          	bne	a5,a4,ffffffffc0201364 <buddy_check+0x502>
    for (unsigned int i = 0; i <= BUDDY_MAX_ORDER; i++) {
ffffffffc02011a0:	0b41                	addi	s6,s6,16
ffffffffc02011a2:	0a21                	addi	s4,s4,8
ffffffffc02011a4:	fe8b11e3          	bne	s6,s0,ffffffffc0201186 <buddy_check+0x324>
    cprintf("buddy_exhaustion_check() succeeded! (%lu pages)\n",
ffffffffc02011a8:	85e6                	mv	a1,s9
ffffffffc02011aa:	00002517          	auipc	a0,0x2
ffffffffc02011ae:	7be50513          	addi	a0,a0,1982 # ffffffffc0203968 <etext+0xaae>
ffffffffc02011b2:	f9ffe0ef          	jal	ffffffffc0200150 <cprintf>
    buddy_alloc_free_check();
    buddy_exhaustion_check();
    buddy_init_check();
ffffffffc02011b6:	bfeff0ef          	jal	ffffffffc02005b4 <buddy_init_check>

    cprintf("buddy_check() succeeded!\n");
}
ffffffffc02011ba:	740e                	ld	s0,224(sp)
ffffffffc02011bc:	70ae                	ld	ra,232(sp)
ffffffffc02011be:	64ee                	ld	s1,216(sp)
ffffffffc02011c0:	694e                	ld	s2,208(sp)
ffffffffc02011c2:	69ae                	ld	s3,200(sp)
ffffffffc02011c4:	6a0e                	ld	s4,192(sp)
ffffffffc02011c6:	7aea                	ld	s5,184(sp)
ffffffffc02011c8:	7b4a                	ld	s6,176(sp)
ffffffffc02011ca:	7baa                	ld	s7,168(sp)
ffffffffc02011cc:	7c0a                	ld	s8,160(sp)
ffffffffc02011ce:	6cea                	ld	s9,152(sp)
ffffffffc02011d0:	6d4a                	ld	s10,144(sp)
    cprintf("buddy_check() succeeded!\n");
ffffffffc02011d2:	00002517          	auipc	a0,0x2
ffffffffc02011d6:	7ce50513          	addi	a0,a0,1998 # ffffffffc02039a0 <etext+0xae6>
}
ffffffffc02011da:	616d                	addi	sp,sp,240
    cprintf("buddy_check() succeeded!\n");
ffffffffc02011dc:	f75fe06f          	j	ffffffffc0200150 <cprintf>
    __list_del(listelm->prev, listelm->next);
ffffffffc02011e0:	631c                	ld	a5,0(a4)
            free_page(p);
ffffffffc02011e2:	4585                	li	a1,1
            released_even++;
ffffffffc02011e4:	0d05                	addi	s10,s10,1
    prev->next = next;
ffffffffc02011e6:	0157b423          	sd	s5,8(a5)
    next->prev = prev;
ffffffffc02011ea:	00fab023          	sd	a5,0(s5)
ffffffffc02011ee:	fe072423          	sw	zero,-24(a4)
            free_page(p);
ffffffffc02011f2:	49e000ef          	jal	ffffffffc0201690 <free_pages>
    while (le != &held) {
ffffffffc02011f6:	ef7a9fe3          	bne	s5,s7,ffffffffc02010f4 <buddy_check+0x292>
ffffffffc02011fa:	bf31                	j	ffffffffc0201116 <buddy_check+0x2b4>
    assert(a + 1 <= c || c + 8 <= a);
ffffffffc02011fc:	00870613          	addi	a2,a4,8
ffffffffc0201200:	dac7f5e3          	bgeu	a5,a2,ffffffffc0200faa <buddy_check+0x148>
ffffffffc0201204:	00002697          	auipc	a3,0x2
ffffffffc0201208:	4c468693          	addi	a3,a3,1220 # ffffffffc02036c8 <etext+0x80e>
ffffffffc020120c:	00002617          	auipc	a2,0x2
ffffffffc0201210:	f2460613          	addi	a2,a2,-220 # ffffffffc0203130 <etext+0x276>
ffffffffc0201214:	13500593          	li	a1,309
ffffffffc0201218:	00002517          	auipc	a0,0x2
ffffffffc020121c:	f3050513          	addi	a0,a0,-208 # ffffffffc0203148 <etext+0x28e>
ffffffffc0201220:	fb1fe0ef          	jal	ffffffffc02001d0 <__panic>
    assert(released_even >= 2);
ffffffffc0201224:	00002697          	auipc	a3,0x2
ffffffffc0201228:	6c468693          	addi	a3,a3,1732 # ffffffffc02038e8 <etext+0xa2e>
ffffffffc020122c:	00002617          	auipc	a2,0x2
ffffffffc0201230:	f0460613          	addi	a2,a2,-252 # ffffffffc0203130 <etext+0x276>
ffffffffc0201234:	19000593          	li	a1,400
ffffffffc0201238:	00002517          	auipc	a0,0x2
ffffffffc020123c:	f1050513          	addi	a0,a0,-240 # ffffffffc0203148 <etext+0x28e>
ffffffffc0201240:	f91fe0ef          	jal	ffffffffc02001d0 <__panic>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201244:	00002697          	auipc	a3,0x2
ffffffffc0201248:	5dc68693          	addi	a3,a3,1500 # ffffffffc0203820 <etext+0x966>
ffffffffc020124c:	00002617          	auipc	a2,0x2
ffffffffc0201250:	ee460613          	addi	a2,a2,-284 # ffffffffc0203130 <etext+0x276>
ffffffffc0201254:	16700593          	li	a1,359
ffffffffc0201258:	00002517          	auipc	a0,0x2
ffffffffc020125c:	ef050513          	addi	a0,a0,-272 # ffffffffc0203148 <etext+0x28e>
ffffffffc0201260:	f71fe0ef          	jal	ffffffffc02001d0 <__panic>
        assert(page_ref(p) == 0);
ffffffffc0201264:	00002697          	auipc	a3,0x2
ffffffffc0201268:	5fc68693          	addi	a3,a3,1532 # ffffffffc0203860 <etext+0x9a6>
ffffffffc020126c:	00002617          	auipc	a2,0x2
ffffffffc0201270:	ec460613          	addi	a2,a2,-316 # ffffffffc0203130 <etext+0x276>
ffffffffc0201274:	16f00593          	li	a1,367
ffffffffc0201278:	00002517          	auipc	a0,0x2
ffffffffc020127c:	ed050513          	addi	a0,a0,-304 # ffffffffc0203148 <etext+0x28e>
ffffffffc0201280:	f51fe0ef          	jal	ffffffffc02001d0 <__panic>
        assert((p->flags & BUDDY_ALLOCATED) != 0);
ffffffffc0201284:	00002697          	auipc	a3,0x2
ffffffffc0201288:	36c68693          	addi	a3,a3,876 # ffffffffc02035f0 <etext+0x736>
ffffffffc020128c:	00002617          	auipc	a2,0x2
ffffffffc0201290:	ea460613          	addi	a2,a2,-348 # ffffffffc0203130 <etext+0x276>
ffffffffc0201294:	16900593          	li	a1,361
ffffffffc0201298:	00002517          	auipc	a0,0x2
ffffffffc020129c:	eb050513          	addi	a0,a0,-336 # ffffffffc0203148 <etext+0x28e>
ffffffffc02012a0:	f31fe0ef          	jal	ffffffffc02001d0 <__panic>
        assert(p->property == 0);
ffffffffc02012a4:	00002697          	auipc	a3,0x2
ffffffffc02012a8:	5a468693          	addi	a3,a3,1444 # ffffffffc0203848 <etext+0x98e>
ffffffffc02012ac:	00002617          	auipc	a2,0x2
ffffffffc02012b0:	e8460613          	addi	a2,a2,-380 # ffffffffc0203130 <etext+0x276>
ffffffffc02012b4:	16800593          	li	a1,360
ffffffffc02012b8:	00002517          	auipc	a0,0x2
ffffffffc02012bc:	e9050513          	addi	a0,a0,-368 # ffffffffc0203148 <etext+0x28e>
ffffffffc02012c0:	f11fe0ef          	jal	ffffffffc02001d0 <__panic>
        assert(obtained < before);
ffffffffc02012c4:	00002697          	auipc	a3,0x2
ffffffffc02012c8:	54468693          	addi	a3,a3,1348 # ffffffffc0203808 <etext+0x94e>
ffffffffc02012cc:	00002617          	auipc	a2,0x2
ffffffffc02012d0:	e6460613          	addi	a2,a2,-412 # ffffffffc0203130 <etext+0x276>
ffffffffc02012d4:	16600593          	li	a1,358
ffffffffc02012d8:	00002517          	auipc	a0,0x2
ffffffffc02012dc:	e7050513          	addi	a0,a0,-400 # ffffffffc0203148 <etext+0x28e>
ffffffffc02012e0:	ef1fe0ef          	jal	ffffffffc02001d0 <__panic>
    assert(b + 4 <= c || c + 8 <= b);
ffffffffc02012e4:	00002697          	auipc	a3,0x2
ffffffffc02012e8:	40468693          	addi	a3,a3,1028 # ffffffffc02036e8 <etext+0x82e>
ffffffffc02012ec:	00002617          	auipc	a2,0x2
ffffffffc02012f0:	e4460613          	addi	a2,a2,-444 # ffffffffc0203130 <etext+0x276>
ffffffffc02012f4:	13600593          	li	a1,310
ffffffffc02012f8:	00002517          	auipc	a0,0x2
ffffffffc02012fc:	e5050513          	addi	a0,a0,-432 # ffffffffc0203148 <etext+0x28e>
ffffffffc0201300:	ed1fe0ef          	jal	ffffffffc02001d0 <__panic>
    assert((b & 3) == 0 && (c & 7) == 0);
ffffffffc0201304:	00002697          	auipc	a3,0x2
ffffffffc0201308:	38468693          	addi	a3,a3,900 # ffffffffc0203688 <etext+0x7ce>
ffffffffc020130c:	00002617          	auipc	a2,0x2
ffffffffc0201310:	e2460613          	addi	a2,a2,-476 # ffffffffc0203130 <etext+0x276>
ffffffffc0201314:	13300593          	li	a1,307
ffffffffc0201318:	00002517          	auipc	a0,0x2
ffffffffc020131c:	e3050513          	addi	a0,a0,-464 # ffffffffc0203148 <etext+0x28e>
ffffffffc0201320:	eb1fe0ef          	jal	ffffffffc02001d0 <__panic>
        assert(list_empty(&buddy_free_lists[i]));
ffffffffc0201324:	00002697          	auipc	a3,0x2
ffffffffc0201328:	59c68693          	addi	a3,a3,1436 # ffffffffc02038c0 <etext+0xa06>
ffffffffc020132c:	00002617          	auipc	a2,0x2
ffffffffc0201330:	e0460613          	addi	a2,a2,-508 # ffffffffc0203130 <etext+0x276>
ffffffffc0201334:	17b00593          	li	a1,379
ffffffffc0201338:	00002517          	auipc	a0,0x2
ffffffffc020133c:	e1050513          	addi	a0,a0,-496 # ffffffffc0203148 <etext+0x28e>
ffffffffc0201340:	e91fe0ef          	jal	ffffffffc02001d0 <__panic>
    assert(a + 1 <= b || b + 4 <= a);
ffffffffc0201344:	00002697          	auipc	a3,0x2
ffffffffc0201348:	36468693          	addi	a3,a3,868 # ffffffffc02036a8 <etext+0x7ee>
ffffffffc020134c:	00002617          	auipc	a2,0x2
ffffffffc0201350:	de460613          	addi	a2,a2,-540 # ffffffffc0203130 <etext+0x276>
ffffffffc0201354:	13400593          	li	a1,308
ffffffffc0201358:	00002517          	auipc	a0,0x2
ffffffffc020135c:	df050513          	addi	a0,a0,-528 # ffffffffc0203148 <etext+0x28e>
ffffffffc0201360:	e71fe0ef          	jal	ffffffffc02001d0 <__panic>
        assert(buddy_count_blocks(i) == blocks_before[i]);
ffffffffc0201364:	00002697          	auipc	a3,0x2
ffffffffc0201368:	40468693          	addi	a3,a3,1028 # ffffffffc0203768 <etext+0x8ae>
ffffffffc020136c:	00002617          	auipc	a2,0x2
ffffffffc0201370:	dc460613          	addi	a2,a2,-572 # ffffffffc0203130 <etext+0x276>
ffffffffc0201374:	1aa00593          	li	a1,426
ffffffffc0201378:	00002517          	auipc	a0,0x2
ffffffffc020137c:	dd050513          	addi	a0,a0,-560 # ffffffffc0203148 <etext+0x28e>
ffffffffc0201380:	e51fe0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free_pages() == before);
ffffffffc0201384:	00002697          	auipc	a3,0x2
ffffffffc0201388:	3c468693          	addi	a3,a3,964 # ffffffffc0203748 <etext+0x88e>
ffffffffc020138c:	00002617          	auipc	a2,0x2
ffffffffc0201390:	da460613          	addi	a2,a2,-604 # ffffffffc0203130 <etext+0x276>
ffffffffc0201394:	14900593          	li	a1,329
ffffffffc0201398:	00002517          	auipc	a0,0x2
ffffffffc020139c:	db050513          	addi	a0,a0,-592 # ffffffffc0203148 <etext+0x28e>
ffffffffc02013a0:	e31fe0ef          	jal	ffffffffc02001d0 <__panic>
    assert(alloc_pages(((size_t)1 << BUDDY_MAX_ORDER) + 1) == NULL);
ffffffffc02013a4:	00002697          	auipc	a3,0x2
ffffffffc02013a8:	3f468693          	addi	a3,a3,1012 # ffffffffc0203798 <etext+0x8de>
ffffffffc02013ac:	00002617          	auipc	a2,0x2
ffffffffc02013b0:	d8460613          	addi	a2,a2,-636 # ffffffffc0203130 <etext+0x276>
ffffffffc02013b4:	14800593          	li	a1,328
ffffffffc02013b8:	00002517          	auipc	a0,0x2
ffffffffc02013bc:	d9050513          	addi	a0,a0,-624 # ffffffffc0203148 <etext+0x28e>
ffffffffc02013c0:	e11fe0ef          	jal	ffffffffc02001d0 <__panic>
        assert(buddy_count_blocks(i) == blocks_before[i]);
ffffffffc02013c4:	00002697          	auipc	a3,0x2
ffffffffc02013c8:	3a468693          	addi	a3,a3,932 # ffffffffc0203768 <etext+0x8ae>
ffffffffc02013cc:	00002617          	auipc	a2,0x2
ffffffffc02013d0:	d6460613          	addi	a2,a2,-668 # ffffffffc0203130 <etext+0x276>
ffffffffc02013d4:	14400593          	li	a1,324
ffffffffc02013d8:	00002517          	auipc	a0,0x2
ffffffffc02013dc:	d7050513          	addi	a0,a0,-656 # ffffffffc0203148 <etext+0x28e>
ffffffffc02013e0:	df1fe0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free_pages() == before);
ffffffffc02013e4:	00002697          	auipc	a3,0x2
ffffffffc02013e8:	36468693          	addi	a3,a3,868 # ffffffffc0203748 <etext+0x88e>
ffffffffc02013ec:	00002617          	auipc	a2,0x2
ffffffffc02013f0:	d4460613          	addi	a2,a2,-700 # ffffffffc0203130 <etext+0x276>
ffffffffc02013f4:	14000593          	li	a1,320
ffffffffc02013f8:	00002517          	auipc	a0,0x2
ffffffffc02013fc:	d5050513          	addi	a0,a0,-688 # ffffffffc0203148 <etext+0x28e>
ffffffffc0201400:	dd1fe0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free_pages() == before - 8);
ffffffffc0201404:	00002697          	auipc	a3,0x2
ffffffffc0201408:	32468693          	addi	a3,a3,804 # ffffffffc0203728 <etext+0x86e>
ffffffffc020140c:	00002617          	auipc	a2,0x2
ffffffffc0201410:	d2460613          	addi	a2,a2,-732 # ffffffffc0203130 <etext+0x276>
ffffffffc0201414:	13d00593          	li	a1,317
ffffffffc0201418:	00002517          	auipc	a0,0x2
ffffffffc020141c:	d3050513          	addi	a0,a0,-720 # ffffffffc0203148 <etext+0x28e>
ffffffffc0201420:	db1fe0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free_pages() == before - 9);
ffffffffc0201424:	00002697          	auipc	a3,0x2
ffffffffc0201428:	2e468693          	addi	a3,a3,740 # ffffffffc0203708 <etext+0x84e>
ffffffffc020142c:	00002617          	auipc	a2,0x2
ffffffffc0201430:	d0460613          	addi	a2,a2,-764 # ffffffffc0203130 <etext+0x276>
ffffffffc0201434:	13a00593          	li	a1,314
ffffffffc0201438:	00002517          	auipc	a0,0x2
ffffffffc020143c:	d1050513          	addi	a0,a0,-752 # ffffffffc0203148 <etext+0x28e>
ffffffffc0201440:	d91fe0ef          	jal	ffffffffc02001d0 <__panic>
    assert(obtained == before);
ffffffffc0201444:	00002697          	auipc	a3,0x2
ffffffffc0201448:	43468693          	addi	a3,a3,1076 # ffffffffc0203878 <etext+0x9be>
ffffffffc020144c:	00002617          	auipc	a2,0x2
ffffffffc0201450:	ce460613          	addi	a2,a2,-796 # ffffffffc0203130 <etext+0x276>
ffffffffc0201454:	17600593          	li	a1,374
ffffffffc0201458:	00002517          	auipc	a0,0x2
ffffffffc020145c:	cf050513          	addi	a0,a0,-784 # ffffffffc0203148 <etext+0x28e>
ffffffffc0201460:	d71fe0ef          	jal	ffffffffc02001d0 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201464:	00002697          	auipc	a3,0x2
ffffffffc0201468:	44468693          	addi	a3,a3,1092 # ffffffffc02038a8 <etext+0x9ee>
ffffffffc020146c:	00002617          	auipc	a2,0x2
ffffffffc0201470:	cc460613          	addi	a2,a2,-828 # ffffffffc0203130 <etext+0x276>
ffffffffc0201474:	17800593          	li	a1,376
ffffffffc0201478:	00002517          	auipc	a0,0x2
ffffffffc020147c:	cd050513          	addi	a0,a0,-816 # ffffffffc0203148 <etext+0x28e>
ffffffffc0201480:	d51fe0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free_pages() == before - 13);
ffffffffc0201484:	00002697          	auipc	a3,0x2
ffffffffc0201488:	1e468693          	addi	a3,a3,484 # ffffffffc0203668 <etext+0x7ae>
ffffffffc020148c:	00002617          	auipc	a2,0x2
ffffffffc0201490:	ca460613          	addi	a2,a2,-860 # ffffffffc0203130 <etext+0x276>
ffffffffc0201494:	12c00593          	li	a1,300
ffffffffc0201498:	00002517          	auipc	a0,0x2
ffffffffc020149c:	cb050513          	addi	a0,a0,-848 # ffffffffc0203148 <etext+0x28e>
ffffffffc02014a0:	d31fe0ef          	jal	ffffffffc02001d0 <__panic>
    assert(buddy_count_blocks(0) == released_even);
ffffffffc02014a4:	00002697          	auipc	a3,0x2
ffffffffc02014a8:	48468693          	addi	a3,a3,1156 # ffffffffc0203928 <etext+0xa6e>
ffffffffc02014ac:	00002617          	auipc	a2,0x2
ffffffffc02014b0:	c8460613          	addi	a2,a2,-892 # ffffffffc0203130 <etext+0x276>
ffffffffc02014b4:	19400593          	li	a1,404
ffffffffc02014b8:	00002517          	auipc	a0,0x2
ffffffffc02014bc:	c9050513          	addi	a0,a0,-880 # ffffffffc0203148 <etext+0x28e>
ffffffffc02014c0:	d11fe0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free_pages() == released_even);
ffffffffc02014c4:	00002697          	auipc	a3,0x2
ffffffffc02014c8:	43c68693          	addi	a3,a3,1084 # ffffffffc0203900 <etext+0xa46>
ffffffffc02014cc:	00002617          	auipc	a2,0x2
ffffffffc02014d0:	c6460613          	addi	a2,a2,-924 # ffffffffc0203130 <etext+0x276>
ffffffffc02014d4:	19100593          	li	a1,401
ffffffffc02014d8:	00002517          	auipc	a0,0x2
ffffffffc02014dc:	c7050513          	addi	a0,a0,-912 # ffffffffc0203148 <etext+0x28e>
ffffffffc02014e0:	cf1fe0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free_pages() == before);
ffffffffc02014e4:	00002697          	auipc	a3,0x2
ffffffffc02014e8:	26468693          	addi	a3,a3,612 # ffffffffc0203748 <etext+0x88e>
ffffffffc02014ec:	00002617          	auipc	a2,0x2
ffffffffc02014f0:	c4460613          	addi	a2,a2,-956 # ffffffffc0203130 <etext+0x276>
ffffffffc02014f4:	1a700593          	li	a1,423
ffffffffc02014f8:	00002517          	auipc	a0,0x2
ffffffffc02014fc:	c5050513          	addi	a0,a0,-944 # ffffffffc0203148 <etext+0x28e>
ffffffffc0201500:	cd1fe0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free_pages() == released_even);
ffffffffc0201504:	00002697          	auipc	a3,0x2
ffffffffc0201508:	3fc68693          	addi	a3,a3,1020 # ffffffffc0203900 <etext+0xa46>
ffffffffc020150c:	00002617          	auipc	a2,0x2
ffffffffc0201510:	c2460613          	addi	a2,a2,-988 # ffffffffc0203130 <etext+0x276>
ffffffffc0201514:	19c00593          	li	a1,412
ffffffffc0201518:	00002517          	auipc	a0,0x2
ffffffffc020151c:	c3050513          	addi	a0,a0,-976 # ffffffffc0203148 <etext+0x28e>
ffffffffc0201520:	cb1fe0ef          	jal	ffffffffc02001d0 <__panic>
    assert(alloc_pages(2) == NULL);
ffffffffc0201524:	00002697          	auipc	a3,0x2
ffffffffc0201528:	42c68693          	addi	a3,a3,1068 # ffffffffc0203950 <etext+0xa96>
ffffffffc020152c:	00002617          	auipc	a2,0x2
ffffffffc0201530:	c0460613          	addi	a2,a2,-1020 # ffffffffc0203130 <etext+0x276>
ffffffffc0201534:	19b00593          	li	a1,411
ffffffffc0201538:	00002517          	auipc	a0,0x2
ffffffffc020153c:	c1050513          	addi	a0,a0,-1008 # ffffffffc0203148 <etext+0x28e>
ffffffffc0201540:	c91fe0ef          	jal	ffffffffc02001d0 <__panic>
        assert(list_empty(&buddy_free_lists[i]));
ffffffffc0201544:	00002697          	auipc	a3,0x2
ffffffffc0201548:	37c68693          	addi	a3,a3,892 # ffffffffc02038c0 <etext+0xa06>
ffffffffc020154c:	00002617          	auipc	a2,0x2
ffffffffc0201550:	be460613          	addi	a2,a2,-1052 # ffffffffc0203130 <etext+0x276>
ffffffffc0201554:	19700593          	li	a1,407
ffffffffc0201558:	00002517          	auipc	a0,0x2
ffffffffc020155c:	bf050513          	addi	a0,a0,-1040 # ffffffffc0203148 <etext+0x28e>
ffffffffc0201560:	c71fe0ef          	jal	ffffffffc02001d0 <__panic>
    assert((r->flags & BUDDY_ALLOCATED) != 0);
ffffffffc0201564:	00002697          	auipc	a3,0x2
ffffffffc0201568:	0dc68693          	addi	a3,a3,220 # ffffffffc0203640 <etext+0x786>
ffffffffc020156c:	00002617          	auipc	a2,0x2
ffffffffc0201570:	bc460613          	addi	a2,a2,-1084 # ffffffffc0203130 <etext+0x276>
ffffffffc0201574:	12900593          	li	a1,297
ffffffffc0201578:	00002517          	auipc	a0,0x2
ffffffffc020157c:	bd050513          	addi	a0,a0,-1072 # ffffffffc0203148 <etext+0x28e>
ffffffffc0201580:	c51fe0ef          	jal	ffffffffc02001d0 <__panic>
    assert((q->flags & BUDDY_ALLOCATED) != 0);
ffffffffc0201584:	00002697          	auipc	a3,0x2
ffffffffc0201588:	09468693          	addi	a3,a3,148 # ffffffffc0203618 <etext+0x75e>
ffffffffc020158c:	00002617          	auipc	a2,0x2
ffffffffc0201590:	ba460613          	addi	a2,a2,-1116 # ffffffffc0203130 <etext+0x276>
ffffffffc0201594:	12800593          	li	a1,296
ffffffffc0201598:	00002517          	auipc	a0,0x2
ffffffffc020159c:	bb050513          	addi	a0,a0,-1104 # ffffffffc0203148 <etext+0x28e>
ffffffffc02015a0:	c31fe0ef          	jal	ffffffffc02001d0 <__panic>
    assert((p->flags & BUDDY_ALLOCATED) != 0);
ffffffffc02015a4:	00002697          	auipc	a3,0x2
ffffffffc02015a8:	04c68693          	addi	a3,a3,76 # ffffffffc02035f0 <etext+0x736>
ffffffffc02015ac:	00002617          	auipc	a2,0x2
ffffffffc02015b0:	b8460613          	addi	a2,a2,-1148 # ffffffffc0203130 <etext+0x276>
ffffffffc02015b4:	12700593          	li	a1,295
ffffffffc02015b8:	00002517          	auipc	a0,0x2
ffffffffc02015bc:	b9050513          	addi	a0,a0,-1136 # ffffffffc0203148 <etext+0x28e>
ffffffffc02015c0:	c11fe0ef          	jal	ffffffffc02001d0 <__panic>
    assert(!PageProperty(p) && !PageProperty(q) && !PageProperty(r));
ffffffffc02015c4:	00002697          	auipc	a3,0x2
ffffffffc02015c8:	fec68693          	addi	a3,a3,-20 # ffffffffc02035b0 <etext+0x6f6>
ffffffffc02015cc:	00002617          	auipc	a2,0x2
ffffffffc02015d0:	b6460613          	addi	a2,a2,-1180 # ffffffffc0203130 <etext+0x276>
ffffffffc02015d4:	12600593          	li	a1,294
ffffffffc02015d8:	00002517          	auipc	a0,0x2
ffffffffc02015dc:	b7050513          	addi	a0,a0,-1168 # ffffffffc0203148 <etext+0x28e>
ffffffffc02015e0:	bf1fe0ef          	jal	ffffffffc02001d0 <__panic>
    assert(p->property == 0 && q->property == 2 && r->property == 3);
ffffffffc02015e4:	00002697          	auipc	a3,0x2
ffffffffc02015e8:	f8c68693          	addi	a3,a3,-116 # ffffffffc0203570 <etext+0x6b6>
ffffffffc02015ec:	00002617          	auipc	a2,0x2
ffffffffc02015f0:	b4460613          	addi	a2,a2,-1212 # ffffffffc0203130 <etext+0x276>
ffffffffc02015f4:	12500593          	li	a1,293
ffffffffc02015f8:	00002517          	auipc	a0,0x2
ffffffffc02015fc:	b5050513          	addi	a0,a0,-1200 # ffffffffc0203148 <etext+0x28e>
ffffffffc0201600:	bd1fe0ef          	jal	ffffffffc02001d0 <__panic>
    assert(p != NULL && q != NULL && r != NULL);
ffffffffc0201604:	00002697          	auipc	a3,0x2
ffffffffc0201608:	f4468693          	addi	a3,a3,-188 # ffffffffc0203548 <etext+0x68e>
ffffffffc020160c:	00002617          	auipc	a2,0x2
ffffffffc0201610:	b2460613          	addi	a2,a2,-1244 # ffffffffc0203130 <etext+0x276>
ffffffffc0201614:	12400593          	li	a1,292
ffffffffc0201618:	00002517          	auipc	a0,0x2
ffffffffc020161c:	b3050513          	addi	a0,a0,-1232 # ffffffffc0203148 <etext+0x28e>
ffffffffc0201620:	bb1fe0ef          	jal	ffffffffc02001d0 <__panic>
    assert(before >= 13);
ffffffffc0201624:	00002697          	auipc	a3,0x2
ffffffffc0201628:	f1468693          	addi	a3,a3,-236 # ffffffffc0203538 <etext+0x67e>
ffffffffc020162c:	00002617          	auipc	a2,0x2
ffffffffc0201630:	b0460613          	addi	a2,a2,-1276 # ffffffffc0203130 <etext+0x276>
ffffffffc0201634:	11800593          	li	a1,280
ffffffffc0201638:	00002517          	auipc	a0,0x2
ffffffffc020163c:	b1050513          	addi	a0,a0,-1264 # ffffffffc0203148 <etext+0x28e>
ffffffffc0201640:	b91fe0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free_pages() == 0);
ffffffffc0201644:	00002697          	auipc	a3,0x2
ffffffffc0201648:	24c68693          	addi	a3,a3,588 # ffffffffc0203890 <etext+0x9d6>
ffffffffc020164c:	00002617          	auipc	a2,0x2
ffffffffc0201650:	ae460613          	addi	a2,a2,-1308 # ffffffffc0203130 <etext+0x276>
ffffffffc0201654:	17700593          	li	a1,375
ffffffffc0201658:	00002517          	auipc	a0,0x2
ffffffffc020165c:	af050513          	addi	a0,a0,-1296 # ffffffffc0203148 <etext+0x28e>
ffffffffc0201660:	b71fe0ef          	jal	ffffffffc02001d0 <__panic>
    assert(before >= 4);
ffffffffc0201664:	00002697          	auipc	a3,0x2
ffffffffc0201668:	19468693          	addi	a3,a3,404 # ffffffffc02037f8 <etext+0x93e>
ffffffffc020166c:	00002617          	auipc	a2,0x2
ffffffffc0201670:	ac460613          	addi	a2,a2,-1340 # ffffffffc0203130 <etext+0x276>
ffffffffc0201674:	15200593          	li	a1,338
ffffffffc0201678:	00002517          	auipc	a0,0x2
ffffffffc020167c:	ad050513          	addi	a0,a0,-1328 # ffffffffc0203148 <etext+0x28e>
ffffffffc0201680:	b51fe0ef          	jal	ffffffffc02001d0 <__panic>

ffffffffc0201684 <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc0201684:	00007797          	auipc	a5,0x7
ffffffffc0201688:	37c7b783          	ld	a5,892(a5) # ffffffffc0208a00 <pmm_manager>
ffffffffc020168c:	6f9c                	ld	a5,24(a5)
ffffffffc020168e:	8782                	jr	a5

ffffffffc0201690 <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc0201690:	00007797          	auipc	a5,0x7
ffffffffc0201694:	3707b783          	ld	a5,880(a5) # ffffffffc0208a00 <pmm_manager>
ffffffffc0201698:	739c                	ld	a5,32(a5)
ffffffffc020169a:	8782                	jr	a5

ffffffffc020169c <nr_free_pages>:
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
ffffffffc020169c:	00007797          	auipc	a5,0x7
ffffffffc02016a0:	3647b783          	ld	a5,868(a5) # ffffffffc0208a00 <pmm_manager>
ffffffffc02016a4:	779c                	ld	a5,40(a5)
ffffffffc02016a6:	8782                	jr	a5

ffffffffc02016a8 <pmm_init>:
    pmm_manager = &buddy_pmm_manager;
ffffffffc02016a8:	00003797          	auipc	a5,0x3
ffffffffc02016ac:	ae078793          	addi	a5,a5,-1312 # ffffffffc0204188 <buddy_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02016b0:	638c                	ld	a1,0(a5)
    }
    init_memmap(pa2page(freemem), npage - PPN(freemem));
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc02016b2:	7179                	addi	sp,sp,-48
ffffffffc02016b4:	f406                	sd	ra,40(sp)
ffffffffc02016b6:	f022                	sd	s0,32(sp)
ffffffffc02016b8:	ec26                	sd	s1,24(sp)
ffffffffc02016ba:	e84a                	sd	s2,16(sp)
    pmm_manager = &buddy_pmm_manager;
ffffffffc02016bc:	00007417          	auipc	s0,0x7
ffffffffc02016c0:	34440413          	addi	s0,s0,836 # ffffffffc0208a00 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02016c4:	00002517          	auipc	a0,0x2
ffffffffc02016c8:	31450513          	addi	a0,a0,788 # ffffffffc02039d8 <etext+0xb1e>
    pmm_manager = &buddy_pmm_manager;
ffffffffc02016cc:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02016ce:	a83fe0ef          	jal	ffffffffc0200150 <cprintf>
    pmm_manager->init();
ffffffffc02016d2:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02016d4:	00007497          	auipc	s1,0x7
ffffffffc02016d8:	34448493          	addi	s1,s1,836 # ffffffffc0208a18 <va_pa_offset>
    pmm_manager->init();
ffffffffc02016dc:	679c                	ld	a5,8(a5)
ffffffffc02016de:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02016e0:	57f5                	li	a5,-3
ffffffffc02016e2:	07fa                	slli	a5,a5,0x1e
ffffffffc02016e4:	e09c                	sd	a5,0(s1)
    uint64_t mem_base = get_memory_base();
ffffffffc02016e6:	e7dfe0ef          	jal	ffffffffc0200562 <get_memory_base>
ffffffffc02016ea:	e42a                	sd	a0,8(sp)
    uint64_t mem_size = get_memory_size();
ffffffffc02016ec:	e81fe0ef          	jal	ffffffffc020056c <get_memory_size>
    if (mem_base == 0 || mem_size == 0) {
ffffffffc02016f0:	65a2                	ld	a1,8(sp)
ffffffffc02016f2:	1a058463          	beqz	a1,ffffffffc020189a <pmm_init+0x1f2>
ffffffffc02016f6:	1a050263          	beqz	a0,ffffffffc020189a <pmm_init+0x1f2>
    if (mem_base < DRAM_BASE) {
ffffffffc02016fa:	800007b7          	lui	a5,0x80000
ffffffffc02016fe:	fff7c793          	not	a5,a5
ffffffffc0201702:	18b7f063          	bgeu	a5,a1,ffffffffc0201882 <pmm_init+0x1da>
    if (mem_size > (uint64_t)-1 - mem_base) {  // 防止 base + size 溢出
ffffffffc0201706:	00a58633          	add	a2,a1,a0
ffffffffc020170a:	16b66063          	bltu	a2,a1,ffffffffc020186a <pmm_init+0x1c2>
    npage = PPN(mem_end);
ffffffffc020170e:	00c65713          	srli	a4,a2,0xc
ffffffffc0201712:	00007797          	auipc	a5,0x7
ffffffffc0201716:	30e7b723          	sd	a4,782(a5) # ffffffffc0208a20 <npage>
    if (npage <= nbase) {
ffffffffc020171a:	00080837          	lui	a6,0x80
ffffffffc020171e:	12e87a63          	bgeu	a6,a4,ffffffffc0201852 <pmm_init+0x1aa>
    pages = (struct Page *)ROUNDUP((uintptr_t)end, PGSIZE);
ffffffffc0201722:	77fd                	lui	a5,0xfffff
ffffffffc0201724:	00008697          	auipc	a3,0x8
ffffffffc0201728:	30f68693          	addi	a3,a3,783 # ffffffffc0209a33 <end+0xfff>
ffffffffc020172c:	8efd                	and	a3,a3,a5
ffffffffc020172e:	00007917          	auipc	s2,0x7
ffffffffc0201732:	2fa90913          	addi	s2,s2,762 # ffffffffc0208a28 <pages>
ffffffffc0201736:	00d93023          	sd	a3,0(s2)
    uintptr_t page_array_pa = PADDR((uintptr_t)pages);
ffffffffc020173a:	c02007b7          	lui	a5,0xc0200
ffffffffc020173e:	0ef6ee63          	bltu	a3,a5,ffffffffc020183a <pmm_init+0x192>
        page_array_pa + sizeof(struct Page) * (npage - nbase);
ffffffffc0201742:	41070833          	sub	a6,a4,a6
    uintptr_t page_array_pa = PADDR((uintptr_t)pages);
ffffffffc0201746:	609c                	ld	a5,0(s1)
        page_array_pa + sizeof(struct Page) * (npage - nbase);
ffffffffc0201748:	00281513          	slli	a0,a6,0x2
ffffffffc020174c:	9542                	add	a0,a0,a6
ffffffffc020174e:	050e                	slli	a0,a0,0x3
    uintptr_t page_array_pa = PADDR((uintptr_t)pages);
ffffffffc0201750:	40f687b3          	sub	a5,a3,a5
    uintptr_t page_array_end =
ffffffffc0201754:	97aa                	add	a5,a5,a0
    if (page_array_end > mem_end) {
ffffffffc0201756:	0cf66663          	bltu	a2,a5,ffffffffc0201822 <pmm_init+0x17a>
ffffffffc020175a:	00271513          	slli	a0,a4,0x2
ffffffffc020175e:	953a                	add	a0,a0,a4
ffffffffc0201760:	fec00837          	lui	a6,0xfec00
ffffffffc0201764:	050e                	slli	a0,a0,0x3
ffffffffc0201766:	9836                	add	a6,a6,a3
ffffffffc0201768:	982a                	add	a6,a6,a0
        SetPageReserved(&pages[i]);
ffffffffc020176a:	4885                	li	a7,1
        pages[i].property = 0;
ffffffffc020176c:	0006a823          	sw	zero,16(a3)
ffffffffc0201770:	0006a023          	sw	zero,0(a3)
        SetPageReserved(&pages[i]);
ffffffffc0201774:	0116b423          	sd	a7,8(a3)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201778:	02868693          	addi	a3,a3,40
ffffffffc020177c:	fed818e3          	bne	a6,a3,ffffffffc020176c <pmm_init+0xc4>
    uintptr_t freemem = ROUNDUP(page_array_end, PGSIZE);
ffffffffc0201780:	6505                	lui	a0,0x1
ffffffffc0201782:	157d                	addi	a0,a0,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc0201784:	00a786b3          	add	a3,a5,a0
ffffffffc0201788:	77fd                	lui	a5,0xfffff
ffffffffc020178a:	8efd                	and	a3,a3,a5
    if (freemem < mem_base) {
ffffffffc020178c:	08b6e763          	bltu	a3,a1,ffffffffc020181a <pmm_init+0x172>
    cprintf("page_init: memory [0x%016lx, 0x%016lx), free start 0x%016lx, "
ffffffffc0201790:	00002517          	auipc	a0,0x2
ffffffffc0201794:	36850513          	addi	a0,a0,872 # ffffffffc0203af8 <etext+0xc3e>
ffffffffc0201798:	e436                	sd	a3,8(sp)
ffffffffc020179a:	9b7fe0ef          	jal	ffffffffc0200150 <cprintf>
    if (PPN(freemem) >= npage) {
ffffffffc020179e:	66a2                	ld	a3,8(sp)
ffffffffc02017a0:	00007597          	auipc	a1,0x7
ffffffffc02017a4:	2805b583          	ld	a1,640(a1) # ffffffffc0208a20 <npage>
ffffffffc02017a8:	82b1                	srli	a3,a3,0xc
ffffffffc02017aa:	12b6f163          	bgeu	a3,a1,ffffffffc02018cc <pmm_init+0x224>
    pmm_manager->init_memmap(base, n);
ffffffffc02017ae:	6010                	ld	a2,0(s0)
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc02017b0:	fff80737          	lui	a4,0xfff80
ffffffffc02017b4:	9736                	add	a4,a4,a3
ffffffffc02017b6:	00093503          	ld	a0,0(s2)
ffffffffc02017ba:	00271793          	slli	a5,a4,0x2
ffffffffc02017be:	97ba                	add	a5,a5,a4
ffffffffc02017c0:	6a18                	ld	a4,16(a2)
ffffffffc02017c2:	078e                	slli	a5,a5,0x3
ffffffffc02017c4:	8d95                	sub	a1,a1,a3
ffffffffc02017c6:	953e                	add	a0,a0,a5
ffffffffc02017c8:	9702                	jalr	a4
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02017ca:	601c                	ld	a5,0(s0)
ffffffffc02017cc:	7b9c                	ld	a5,48(a5)
ffffffffc02017ce:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02017d0:	00002517          	auipc	a0,0x2
ffffffffc02017d4:	39850513          	addi	a0,a0,920 # ffffffffc0203b68 <etext+0xcae>
ffffffffc02017d8:	979fe0ef          	jal	ffffffffc0200150 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc02017dc:	00006597          	auipc	a1,0x6
ffffffffc02017e0:	82458593          	addi	a1,a1,-2012 # ffffffffc0207000 <boot_page_table_sv39>
ffffffffc02017e4:	00007797          	auipc	a5,0x7
ffffffffc02017e8:	22b7b623          	sd	a1,556(a5) # ffffffffc0208a10 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc02017ec:	c02007b7          	lui	a5,0xc0200
ffffffffc02017f0:	0cf5e163          	bltu	a1,a5,ffffffffc02018b2 <pmm_init+0x20a>
ffffffffc02017f4:	609c                	ld	a5,0(s1)
}
ffffffffc02017f6:	7402                	ld	s0,32(sp)
ffffffffc02017f8:	70a2                	ld	ra,40(sp)
ffffffffc02017fa:	64e2                	ld	s1,24(sp)
ffffffffc02017fc:	6942                	ld	s2,16(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc02017fe:	40f586b3          	sub	a3,a1,a5
ffffffffc0201802:	00007797          	auipc	a5,0x7
ffffffffc0201806:	20d7b323          	sd	a3,518(a5) # ffffffffc0208a08 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020180a:	00002517          	auipc	a0,0x2
ffffffffc020180e:	37e50513          	addi	a0,a0,894 # ffffffffc0203b88 <etext+0xcce>
ffffffffc0201812:	8636                	mv	a2,a3
}
ffffffffc0201814:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201816:	93bfe06f          	j	ffffffffc0200150 <cprintf>
        freemem = ROUNDUP(mem_base, PGSIZE);
ffffffffc020181a:	952e                	add	a0,a0,a1
ffffffffc020181c:	00f576b3          	and	a3,a0,a5
ffffffffc0201820:	bf85                	j	ffffffffc0201790 <pmm_init+0xe8>
        panic("page_init: Page array exceeds physical memory");
ffffffffc0201822:	00002617          	auipc	a2,0x2
ffffffffc0201826:	2a660613          	addi	a2,a2,678 # ffffffffc0203ac8 <etext+0xc0e>
ffffffffc020182a:	06c00593          	li	a1,108
ffffffffc020182e:	00002517          	auipc	a0,0x2
ffffffffc0201832:	1ea50513          	addi	a0,a0,490 # ffffffffc0203a18 <etext+0xb5e>
ffffffffc0201836:	99bfe0ef          	jal	ffffffffc02001d0 <__panic>
    uintptr_t page_array_pa = PADDR((uintptr_t)pages);
ffffffffc020183a:	00002617          	auipc	a2,0x2
ffffffffc020183e:	26660613          	addi	a2,a2,614 # ffffffffc0203aa0 <etext+0xbe6>
ffffffffc0201842:	06800593          	li	a1,104
ffffffffc0201846:	00002517          	auipc	a0,0x2
ffffffffc020184a:	1d250513          	addi	a0,a0,466 # ffffffffc0203a18 <etext+0xb5e>
ffffffffc020184e:	983fe0ef          	jal	ffffffffc02001d0 <__panic>
        panic("page_init: npage <= nbase");
ffffffffc0201852:	00002617          	auipc	a2,0x2
ffffffffc0201856:	22e60613          	addi	a2,a2,558 # ffffffffc0203a80 <etext+0xbc6>
ffffffffc020185a:	06000593          	li	a1,96
ffffffffc020185e:	00002517          	auipc	a0,0x2
ffffffffc0201862:	1ba50513          	addi	a0,a0,442 # ffffffffc0203a18 <etext+0xb5e>
ffffffffc0201866:	96bfe0ef          	jal	ffffffffc02001d0 <__panic>
        panic("page_init: physical memory range overflows");
ffffffffc020186a:	00002617          	auipc	a2,0x2
ffffffffc020186e:	1e660613          	addi	a2,a2,486 # ffffffffc0203a50 <etext+0xb96>
ffffffffc0201872:	05900593          	li	a1,89
ffffffffc0201876:	00002517          	auipc	a0,0x2
ffffffffc020187a:	1a250513          	addi	a0,a0,418 # ffffffffc0203a18 <etext+0xb5e>
ffffffffc020187e:	953fe0ef          	jal	ffffffffc02001d0 <__panic>
        panic("page_init: memory base below DRAM_BASE");
ffffffffc0201882:	00002617          	auipc	a2,0x2
ffffffffc0201886:	1a660613          	addi	a2,a2,422 # ffffffffc0203a28 <etext+0xb6e>
ffffffffc020188a:	05600593          	li	a1,86
ffffffffc020188e:	00002517          	auipc	a0,0x2
ffffffffc0201892:	18a50513          	addi	a0,a0,394 # ffffffffc0203a18 <etext+0xb5e>
ffffffffc0201896:	93bfe0ef          	jal	ffffffffc02001d0 <__panic>
        panic("page_init: invalid DTB memory info");
ffffffffc020189a:	00002617          	auipc	a2,0x2
ffffffffc020189e:	15660613          	addi	a2,a2,342 # ffffffffc02039f0 <etext+0xb36>
ffffffffc02018a2:	05300593          	li	a1,83
ffffffffc02018a6:	00002517          	auipc	a0,0x2
ffffffffc02018aa:	17250513          	addi	a0,a0,370 # ffffffffc0203a18 <etext+0xb5e>
ffffffffc02018ae:	923fe0ef          	jal	ffffffffc02001d0 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc02018b2:	86ae                	mv	a3,a1
ffffffffc02018b4:	00002617          	auipc	a2,0x2
ffffffffc02018b8:	1ec60613          	addi	a2,a2,492 # ffffffffc0203aa0 <etext+0xbe6>
ffffffffc02018bc:	09e00593          	li	a1,158
ffffffffc02018c0:	00002517          	auipc	a0,0x2
ffffffffc02018c4:	15850513          	addi	a0,a0,344 # ffffffffc0203a18 <etext+0xb5e>
ffffffffc02018c8:	909fe0ef          	jal	ffffffffc02001d0 <__panic>
        panic("page_init: no complete free page left");
ffffffffc02018cc:	00002617          	auipc	a2,0x2
ffffffffc02018d0:	27460613          	addi	a2,a2,628 # ffffffffc0203b40 <etext+0xc86>
ffffffffc02018d4:	08700593          	li	a1,135
ffffffffc02018d8:	00002517          	auipc	a0,0x2
ffffffffc02018dc:	14050513          	addi	a0,a0,320 # ffffffffc0203a18 <etext+0xb5e>
ffffffffc02018e0:	8f1fe0ef          	jal	ffffffffc02001d0 <__panic>

ffffffffc02018e4 <slub_init>:
    return (void *)(page2pa(page) + va_pa_offset);
}

void
slub_init(void) {
    assert(!slub_ready);
ffffffffc02018e4:	00007797          	auipc	a5,0x7
ffffffffc02018e8:	14c7a783          	lw	a5,332(a5) # ffffffffc0208a30 <slub_ready>
ffffffffc02018ec:	ef85                	bnez	a5,ffffffffc0201924 <slub_init+0x40>
ffffffffc02018ee:	00003717          	auipc	a4,0x3
ffffffffc02018f2:	8d270713          	addi	a4,a4,-1838 # ffffffffc02041c0 <cache_sizes>
ffffffffc02018f6:	00007797          	auipc	a5,0x7
ffffffffc02018fa:	82a78793          	addi	a5,a5,-2006 # ffffffffc0208120 <caches+0x8>
ffffffffc02018fe:	00007617          	auipc	a2,0x7
ffffffffc0201902:	8e260613          	addi	a2,a2,-1822 # ffffffffc02081e0 <tags.1+0x8>
    assert(object_offset() + SLUB_SMALL_MAX <= PGSIZE);
    assert((PGSIZE - object_offset()) / cache_sizes[0] <=
           BITMAP_WORDS * 64);

    for (unsigned int i = 0; i < CACHE_COUNT; i++) {
        caches[i].size = cache_sizes[i];
ffffffffc0201906:	6314                	ld	a3,0(a4)
    elm->prev = elm->next = elm;
ffffffffc0201908:	e79c                	sd	a5,8(a5)
ffffffffc020190a:	e39c                	sd	a5,0(a5)
ffffffffc020190c:	fed7bc23          	sd	a3,-8(a5)
    for (unsigned int i = 0; i < CACHE_COUNT; i++) {
ffffffffc0201910:	07e1                	addi	a5,a5,24
ffffffffc0201912:	0721                	addi	a4,a4,8
ffffffffc0201914:	fec799e3          	bne	a5,a2,ffffffffc0201906 <slub_init+0x22>
        list_init(&caches[i].partial);
    }
    slub_ready = 1;
ffffffffc0201918:	4785                	li	a5,1
ffffffffc020191a:	00007717          	auipc	a4,0x7
ffffffffc020191e:	10f72b23          	sw	a5,278(a4) # ffffffffc0208a30 <slub_ready>
ffffffffc0201922:	8082                	ret
slub_init(void) {
ffffffffc0201924:	1141                	addi	sp,sp,-16
    assert(!slub_ready);
ffffffffc0201926:	00002697          	auipc	a3,0x2
ffffffffc020192a:	2a268693          	addi	a3,a3,674 # ffffffffc0203bc8 <etext+0xd0e>
ffffffffc020192e:	00002617          	auipc	a2,0x2
ffffffffc0201932:	80260613          	addi	a2,a2,-2046 # ffffffffc0203130 <etext+0x276>
ffffffffc0201936:	03000593          	li	a1,48
ffffffffc020193a:	00002517          	auipc	a0,0x2
ffffffffc020193e:	29e50513          	addi	a0,a0,670 # ffffffffc0203bd8 <etext+0xd1e>
slub_init(void) {
ffffffffc0201942:	e406                	sd	ra,8(sp)
    assert(!slub_ready);
ffffffffc0201944:	88dfe0ef          	jal	ffffffffc02001d0 <__panic>

ffffffffc0201948 <kmalloc>:
    return s;
}

void *
kmalloc(size_t size) {
    assert(slub_ready);
ffffffffc0201948:	00007797          	auipc	a5,0x7
ffffffffc020194c:	0e87a783          	lw	a5,232(a5) # ffffffffc0208a30 <slub_ready>
kmalloc(size_t size) {
ffffffffc0201950:	7179                	addi	sp,sp,-48
ffffffffc0201952:	f406                	sd	ra,40(sp)
    assert(slub_ready);
ffffffffc0201954:	20078163          	beqz	a5,ffffffffc0201b56 <kmalloc+0x20e>
    if (size == 0) {
ffffffffc0201958:	12050f63          	beqz	a0,ffffffffc0201a96 <kmalloc+0x14e>
        return NULL;
    }

    if (size > SLUB_SMALL_MAX) {
ffffffffc020195c:	6785                	lui	a5,0x1
ffffffffc020195e:	80078713          	addi	a4,a5,-2048 # 800 <kern_entry-0xffffffffc01ff800>
ffffffffc0201962:	0aa77363          	bgeu	a4,a0,ffffffffc0201a08 <kmalloc+0xc0>
        size_t offset = object_offset();
        if (size > (size_t)-1 - offset) {
ffffffffc0201966:	f9f00713          	li	a4,-97
ffffffffc020196a:	12a76663          	bltu	a4,a0,ffffffffc0201a96 <kmalloc+0x14e>
            return NULL;
        }

        size_t bytes = size + offset;
ffffffffc020196e:	06050513          	addi	a0,a0,96
        /* Avoid overflow from ROUNDUP(bytes, PGSIZE). */
        size_t n = bytes / PGSIZE + (bytes % PGSIZE != 0);
ffffffffc0201972:	fff78713          	addi	a4,a5,-1
        if (n > npage - nbase) {
ffffffffc0201976:	00003697          	auipc	a3,0x3
ffffffffc020197a:	b626b683          	ld	a3,-1182(a3) # ffffffffc02044d8 <nbase>
ffffffffc020197e:	00007797          	auipc	a5,0x7
ffffffffc0201982:	0a27b783          	ld	a5,162(a5) # ffffffffc0208a20 <npage>
        size_t n = bytes / PGSIZE + (bytes % PGSIZE != 0);
ffffffffc0201986:	8f69                	and	a4,a4,a0
ffffffffc0201988:	00e03733          	snez	a4,a4
ffffffffc020198c:	8131                	srli	a0,a0,0xc
ffffffffc020198e:	972a                	add	a4,a4,a0
        if (n > npage - nbase) {
ffffffffc0201990:	8f95                	sub	a5,a5,a3
ffffffffc0201992:	10e7e263          	bltu	a5,a4,ffffffffc0201a96 <kmalloc+0x14e>
            return NULL;
        }

        struct Page *page = alloc_pages(n);
ffffffffc0201996:	853a                	mv	a0,a4
ffffffffc0201998:	e03a                	sd	a4,0(sp)
ffffffffc020199a:	e436                	sd	a3,8(sp)
ffffffffc020199c:	ce9ff0ef          	jal	ffffffffc0201684 <alloc_pages>
ffffffffc02019a0:	882a                	mv	a6,a0
        if (page == NULL) {
ffffffffc02019a2:	c975                	beqz	a0,ffffffffc0201a96 <kmalloc+0x14e>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02019a4:	00007517          	auipc	a0,0x7
ffffffffc02019a8:	08453503          	ld	a0,132(a0) # ffffffffc0208a28 <pages>
ffffffffc02019ac:	ccccd7b7          	lui	a5,0xccccd
ffffffffc02019b0:	ccd78793          	addi	a5,a5,-819 # ffffffffcccccccd <end+0xcac4299>
ffffffffc02019b4:	40a80533          	sub	a0,a6,a0
ffffffffc02019b8:	02079613          	slli	a2,a5,0x20
ffffffffc02019bc:	97b2                	add	a5,a5,a2
ffffffffc02019be:	850d                	srai	a0,a0,0x3
ffffffffc02019c0:	02f50533          	mul	a0,a0,a5
ffffffffc02019c4:	66a2                	ld	a3,8(sp)
    return (void *)(page2pa(page) + va_pa_offset);
ffffffffc02019c6:	00007797          	auipc	a5,0x7
ffffffffc02019ca:	0527b783          	ld	a5,82(a5) # ffffffffc0208a18 <va_pa_offset>
            return NULL;
        }

        struct slab *s = slub_page_address(page);
        memset(s, 0, sizeof(*s));
ffffffffc02019ce:	06000613          	li	a2,96
ffffffffc02019d2:	4581                	li	a1,0
ffffffffc02019d4:	e842                	sd	a6,16(sp)
ffffffffc02019d6:	9536                	add	a0,a0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02019d8:	0532                	slli	a0,a0,0xc
    return (void *)(page2pa(page) + va_pa_offset);
ffffffffc02019da:	97aa                	add	a5,a5,a0
        memset(s, 0, sizeof(*s));
ffffffffc02019dc:	853e                	mv	a0,a5
ffffffffc02019de:	e43e                	sd	a5,8(sp)
ffffffffc02019e0:	4c8010ef          	jal	ffffffffc0202ea8 <memset>
        s->magic = SLUB_MAGIC;
        s->page = page;
ffffffffc02019e4:	67a2                	ld	a5,8(sp)
        s->magic = SLUB_MAGIC;
ffffffffc02019e6:	00003617          	auipc	a2,0x3
ffffffffc02019ea:	afa63603          	ld	a2,-1286(a2) # ffffffffc02044e0 <nbase+0x8>
        s->page = page;
ffffffffc02019ee:	6842                	ld	a6,16(sp)
        s->npages = n;
ffffffffc02019f0:	6702                	ld	a4,0(sp)
        s->inuse = 1;
ffffffffc02019f2:	4685                	li	a3,1
        s->page = page;
ffffffffc02019f4:	0107b823          	sd	a6,16(a5)
        s->npages = n;
ffffffffc02019f8:	ef98                	sd	a4,24(a5)
        s->magic = SLUB_MAGIC;
ffffffffc02019fa:	e390                	sd	a2,0(a5)
        s->inuse = 1;
ffffffffc02019fc:	d3d4                	sw	a3,36(a5)
        return (char *)s + offset;
ffffffffc02019fe:	06078513          	addi	a0,a5,96
    s->inuse++;
    if (s->inuse == s->capacity) {
        list_del_init(&s->link);  /* Full slabs leave the partial list. */
    }
    return obj;
}
ffffffffc0201a02:	70a2                	ld	ra,40(sp)
ffffffffc0201a04:	6145                	addi	sp,sp,48
ffffffffc0201a06:	8082                	ret
    while (cache->size < size) {
ffffffffc0201a08:	00006717          	auipc	a4,0x6
ffffffffc0201a0c:	71073703          	ld	a4,1808(a4) # ffffffffc0208118 <caches>
    struct kmem_cache *cache = &caches[0];
ffffffffc0201a10:	00006797          	auipc	a5,0x6
ffffffffc0201a14:	70878793          	addi	a5,a5,1800 # ffffffffc0208118 <caches>
    while (cache->size < size) {
ffffffffc0201a18:	00a77663          	bgeu	a4,a0,ffffffffc0201a24 <kmalloc+0xdc>
ffffffffc0201a1c:	6f98                	ld	a4,24(a5)
        cache++;
ffffffffc0201a1e:	07e1                	addi	a5,a5,24
    while (cache->size < size) {
ffffffffc0201a20:	fea76ee3          	bltu	a4,a0,ffffffffc0201a1c <kmalloc+0xd4>
    return list->next == list;
ffffffffc0201a24:	0107b803          	ld	a6,16(a5)
    if (list_empty(&cache->partial)) {
ffffffffc0201a28:	00878693          	addi	a3,a5,8
        s = to_struct(list_next(&cache->partial), struct slab, link);
ffffffffc0201a2c:	fd080713          	addi	a4,a6,-48 # fffffffffebfffd0 <end+0x3e9f759c>
    if (list_empty(&cache->partial)) {
ffffffffc0201a30:	06d80763          	beq	a6,a3,ffffffffc0201a9e <kmalloc+0x156>
    void *obj = s->freelist;
ffffffffc0201a34:	7708                	ld	a0,40(a4)
    assert(obj != NULL);
ffffffffc0201a36:	14050063          	beqz	a0,ffffffffc0201b76 <kmalloc+0x22e>
    size_t index = ((uintptr_t)obj - (uintptr_t)s - object_offset()) /
ffffffffc0201a3a:	6394                	ld	a3,0(a5)
ffffffffc0201a3c:	40e507b3          	sub	a5,a0,a4
ffffffffc0201a40:	fa078793          	addi	a5,a5,-96
ffffffffc0201a44:	02d7d7b3          	divu	a5,a5,a3
    assert(index < s->capacity);
ffffffffc0201a48:	02072803          	lw	a6,32(a4)
ffffffffc0201a4c:	02081693          	slli	a3,a6,0x20
ffffffffc0201a50:	9281                	srli	a3,a3,0x20
ffffffffc0201a52:	14d7f263          	bgeu	a5,a3,ffffffffc0201b96 <kmalloc+0x24e>
    assert((s->used[index / 64] & mask) == 0);
ffffffffc0201a56:	0067d693          	srli	a3,a5,0x6
ffffffffc0201a5a:	068e                	slli	a3,a3,0x3
ffffffffc0201a5c:	96ba                	add	a3,a3,a4
ffffffffc0201a5e:	62b0                	ld	a2,64(a3)
    uint64_t mask = 1ULL << (index % 64);
ffffffffc0201a60:	4585                	li	a1,1
ffffffffc0201a62:	00f597b3          	sll	a5,a1,a5
    assert((s->used[index / 64] & mask) == 0);
ffffffffc0201a66:	00f675b3          	and	a1,a2,a5
ffffffffc0201a6a:	14059663          	bnez	a1,ffffffffc0201bb6 <kmalloc+0x26e>
    s->freelist = *(void **)obj;
ffffffffc0201a6e:	610c                	ld	a1,0(a0)
    s->used[index / 64] |= mask;
ffffffffc0201a70:	8e5d                	or	a2,a2,a5
    s->freelist = *(void **)obj;
ffffffffc0201a72:	f70c                	sd	a1,40(a4)
    s->used[index / 64] |= mask;
ffffffffc0201a74:	e2b0                	sd	a2,64(a3)
    s->inuse++;
ffffffffc0201a76:	535c                	lw	a5,36(a4)
ffffffffc0201a78:	2785                	addiw	a5,a5,1
ffffffffc0201a7a:	d35c                	sw	a5,36(a4)
    if (s->inuse == s->capacity) {
ffffffffc0201a7c:	f8f813e3          	bne	a6,a5,ffffffffc0201a02 <kmalloc+0xba>
    __list_del(listelm->prev, listelm->next);
ffffffffc0201a80:	7b10                	ld	a2,48(a4)
ffffffffc0201a82:	7f14                	ld	a3,56(a4)
}
ffffffffc0201a84:	70a2                	ld	ra,40(sp)
        list_del_init(&s->link);  /* Full slabs leave the partial list. */
ffffffffc0201a86:	03070793          	addi	a5,a4,48
    prev->next = next;
ffffffffc0201a8a:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0201a8c:	e290                	sd	a2,0(a3)
    elm->prev = elm->next = elm;
ffffffffc0201a8e:	ff1c                	sd	a5,56(a4)
ffffffffc0201a90:	fb1c                	sd	a5,48(a4)
}
ffffffffc0201a92:	6145                	addi	sp,sp,48
ffffffffc0201a94:	8082                	ret
ffffffffc0201a96:	70a2                	ld	ra,40(sp)
        return NULL;
ffffffffc0201a98:	4501                	li	a0,0
}
ffffffffc0201a9a:	6145                	addi	sp,sp,48
ffffffffc0201a9c:	8082                	ret
    struct Page *page = alloc_page();
ffffffffc0201a9e:	4505                	li	a0,1
ffffffffc0201aa0:	e43e                	sd	a5,8(sp)
ffffffffc0201aa2:	e042                	sd	a6,0(sp)
ffffffffc0201aa4:	be1ff0ef          	jal	ffffffffc0201684 <alloc_pages>
    if (page == NULL) {
ffffffffc0201aa8:	d57d                	beqz	a0,ffffffffc0201a96 <kmalloc+0x14e>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201aaa:	00007717          	auipc	a4,0x7
ffffffffc0201aae:	f7e73703          	ld	a4,-130(a4) # ffffffffc0208a28 <pages>
ffffffffc0201ab2:	ccccd6b7          	lui	a3,0xccccd
ffffffffc0201ab6:	ccd68693          	addi	a3,a3,-819 # ffffffffcccccccd <end+0xcac4299>
ffffffffc0201aba:	02069613          	slli	a2,a3,0x20
ffffffffc0201abe:	40e50733          	sub	a4,a0,a4
ffffffffc0201ac2:	96b2                	add	a3,a3,a2
ffffffffc0201ac4:	870d                	srai	a4,a4,0x3
ffffffffc0201ac6:	02d70733          	mul	a4,a4,a3
ffffffffc0201aca:	ec2a                	sd	a0,24(sp)
ffffffffc0201acc:	00003517          	auipc	a0,0x3
ffffffffc0201ad0:	a0c53503          	ld	a0,-1524(a0) # ffffffffc02044d8 <nbase>
    return (void *)(page2pa(page) + va_pa_offset);
ffffffffc0201ad4:	00007697          	auipc	a3,0x7
ffffffffc0201ad8:	f446b683          	ld	a3,-188(a3) # ffffffffc0208a18 <va_pa_offset>
    memset(s, 0, sizeof(*s));
ffffffffc0201adc:	06000613          	li	a2,96
ffffffffc0201ae0:	4581                	li	a1,0
ffffffffc0201ae2:	972a                	add	a4,a4,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0201ae4:	0732                	slli	a4,a4,0xc
    return (void *)(page2pa(page) + va_pa_offset);
ffffffffc0201ae6:	9736                	add	a4,a4,a3
    memset(s, 0, sizeof(*s));
ffffffffc0201ae8:	853a                	mv	a0,a4
ffffffffc0201aea:	e83a                	sd	a4,16(sp)
ffffffffc0201aec:	3bc010ef          	jal	ffffffffc0202ea8 <memset>
    s->capacity = (PGSIZE - object_offset()) / cache->size;
ffffffffc0201af0:	67a2                	ld	a5,8(sp)
ffffffffc0201af2:	6685                	lui	a3,0x1
ffffffffc0201af4:	fa068693          	addi	a3,a3,-96 # fa0 <kern_entry-0xffffffffc01ff060>
ffffffffc0201af8:	6388                	ld	a0,0(a5)
    s->page = page;
ffffffffc0201afa:	6742                	ld	a4,16(sp)
ffffffffc0201afc:	68e2                	ld	a7,24(sp)
    s->capacity = (PGSIZE - object_offset()) / cache->size;
ffffffffc0201afe:	02a6d5b3          	divu	a1,a3,a0
    s->magic = SLUB_MAGIC;
ffffffffc0201b02:	00003317          	auipc	t1,0x3
ffffffffc0201b06:	9de33303          	ld	t1,-1570(t1) # ffffffffc02044e0 <nbase+0x8>
    s->page = page;
ffffffffc0201b0a:	01173823          	sd	a7,16(a4)
    s->npages = 1;
ffffffffc0201b0e:	4605                	li	a2,1
    list_init(&s->link);
ffffffffc0201b10:	03070893          	addi	a7,a4,48
    s->cache = cache;
ffffffffc0201b14:	e71c                	sd	a5,8(a4)
    s->magic = SLUB_MAGIC;
ffffffffc0201b16:	00673023          	sd	t1,0(a4)
    s->npages = 1;
ffffffffc0201b1a:	ef10                	sd	a2,24(a4)
ffffffffc0201b1c:	03173c23          	sd	a7,56(a4)
    for (size_t i = s->capacity; i > 0; i--) {
ffffffffc0201b20:	6802                	ld	a6,0(sp)
    s->capacity = (PGSIZE - object_offset()) / cache->size;
ffffffffc0201b22:	d30c                	sw	a1,32(a4)
    for (size_t i = s->capacity; i > 0; i--) {
ffffffffc0201b24:	02a6e063          	bltu	a3,a0,ffffffffc0201b44 <kmalloc+0x1fc>
ffffffffc0201b28:	15fd                	addi	a1,a1,-1
ffffffffc0201b2a:	02a586b3          	mul	a3,a1,a0
        *(void **)obj = s->freelist;
ffffffffc0201b2e:	7710                	ld	a2,40(a4)
ffffffffc0201b30:	06068693          	addi	a3,a3,96
ffffffffc0201b34:	96ba                	add	a3,a3,a4
ffffffffc0201b36:	a011                	j	ffffffffc0201b3a <kmalloc+0x1f2>
ffffffffc0201b38:	15fd                	addi	a1,a1,-1
ffffffffc0201b3a:	e290                	sd	a2,0(a3)
        void *obj = (char *)s + object_offset() + (i - 1) * cache->size;
ffffffffc0201b3c:	8636                	mv	a2,a3
    for (size_t i = s->capacity; i > 0; i--) {
ffffffffc0201b3e:	8e89                	sub	a3,a3,a0
ffffffffc0201b40:	fde5                	bnez	a1,ffffffffc0201b38 <kmalloc+0x1f0>
ffffffffc0201b42:	f710                	sd	a2,40(a4)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201b44:	6b94                	ld	a3,16(a5)
    prev->next = next->prev = elm;
ffffffffc0201b46:	0116b023          	sd	a7,0(a3)
ffffffffc0201b4a:	0117b823          	sd	a7,16(a5)
    elm->next = next;
ffffffffc0201b4e:	ff14                	sd	a3,56(a4)
    elm->prev = prev;
ffffffffc0201b50:	03073823          	sd	a6,48(a4)
        if (s == NULL) {
ffffffffc0201b54:	b5c5                	j	ffffffffc0201a34 <kmalloc+0xec>
    assert(slub_ready);
ffffffffc0201b56:	00002697          	auipc	a3,0x2
ffffffffc0201b5a:	09268693          	addi	a3,a3,146 # ffffffffc0203be8 <etext+0xd2e>
ffffffffc0201b5e:	00001617          	auipc	a2,0x1
ffffffffc0201b62:	5d260613          	addi	a2,a2,1490 # ffffffffc0203130 <etext+0x276>
ffffffffc0201b66:	05800593          	li	a1,88
ffffffffc0201b6a:	00002517          	auipc	a0,0x2
ffffffffc0201b6e:	06e50513          	addi	a0,a0,110 # ffffffffc0203bd8 <etext+0xd1e>
ffffffffc0201b72:	e5efe0ef          	jal	ffffffffc02001d0 <__panic>
    assert(obj != NULL);
ffffffffc0201b76:	00002697          	auipc	a3,0x2
ffffffffc0201b7a:	08268693          	addi	a3,a3,130 # ffffffffc0203bf8 <etext+0xd3e>
ffffffffc0201b7e:	00001617          	auipc	a2,0x1
ffffffffc0201b82:	5b260613          	addi	a2,a2,1458 # ffffffffc0203130 <etext+0x276>
ffffffffc0201b86:	08800593          	li	a1,136
ffffffffc0201b8a:	00002517          	auipc	a0,0x2
ffffffffc0201b8e:	04e50513          	addi	a0,a0,78 # ffffffffc0203bd8 <etext+0xd1e>
ffffffffc0201b92:	e3efe0ef          	jal	ffffffffc02001d0 <__panic>
    assert(index < s->capacity);
ffffffffc0201b96:	00002697          	auipc	a3,0x2
ffffffffc0201b9a:	07268693          	addi	a3,a3,114 # ffffffffc0203c08 <etext+0xd4e>
ffffffffc0201b9e:	00001617          	auipc	a2,0x1
ffffffffc0201ba2:	59260613          	addi	a2,a2,1426 # ffffffffc0203130 <etext+0x276>
ffffffffc0201ba6:	08b00593          	li	a1,139
ffffffffc0201baa:	00002517          	auipc	a0,0x2
ffffffffc0201bae:	02e50513          	addi	a0,a0,46 # ffffffffc0203bd8 <etext+0xd1e>
ffffffffc0201bb2:	e1efe0ef          	jal	ffffffffc02001d0 <__panic>
    assert((s->used[index / 64] & mask) == 0);
ffffffffc0201bb6:	00002697          	auipc	a3,0x2
ffffffffc0201bba:	06a68693          	addi	a3,a3,106 # ffffffffc0203c20 <etext+0xd66>
ffffffffc0201bbe:	00001617          	auipc	a2,0x1
ffffffffc0201bc2:	57260613          	addi	a2,a2,1394 # ffffffffc0203130 <etext+0x276>
ffffffffc0201bc6:	08d00593          	li	a1,141
ffffffffc0201bca:	00002517          	auipc	a0,0x2
ffffffffc0201bce:	00e50513          	addi	a0,a0,14 # ffffffffc0203bd8 <etext+0xd1e>
ffffffffc0201bd2:	dfefe0ef          	jal	ffffffffc02001d0 <__panic>

ffffffffc0201bd6 <kfree>:

void
kfree(void *ptr) {
    if (ptr == NULL) {
ffffffffc0201bd6:	10050f63          	beqz	a0,ffffffffc0201cf4 <kfree+0x11e>
        return;
    }
    assert(slub_ready);
ffffffffc0201bda:	00007797          	auipc	a5,0x7
ffffffffc0201bde:	e567a783          	lw	a5,-426(a5) # ffffffffc0208a30 <slub_ready>
kfree(void *ptr) {
ffffffffc0201be2:	1141                	addi	sp,sp,-16
ffffffffc0201be4:	e406                	sd	ra,8(sp)
    assert(slub_ready);
ffffffffc0201be6:	12078863          	beqz	a5,ffffffffc0201d16 <kfree+0x140>
    assert((uintptr_t)ptr >= KERNBASE);
ffffffffc0201bea:	c02007b7          	lui	a5,0xc0200
ffffffffc0201bee:	14f56463          	bltu	a0,a5,ffffffffc0201d36 <kfree+0x160>
    uintptr_t pa = (uintptr_t)ptr - va_pa_offset;
ffffffffc0201bf2:	00007797          	auipc	a5,0x7
ffffffffc0201bf6:	e267b783          	ld	a5,-474(a5) # ffffffffc0208a18 <va_pa_offset>
    assert(PPN(pa) >= nbase && PPN(pa) < npage);
ffffffffc0201bfa:	00003717          	auipc	a4,0x3
ffffffffc0201bfe:	8de73703          	ld	a4,-1826(a4) # ffffffffc02044d8 <nbase>
    uintptr_t pa = (uintptr_t)ptr - va_pa_offset;
ffffffffc0201c02:	40f507b3          	sub	a5,a0,a5
    assert(PPN(pa) >= nbase && PPN(pa) < npage);
ffffffffc0201c06:	83b1                	srli	a5,a5,0xc
ffffffffc0201c08:	0ee7e763          	bltu	a5,a4,ffffffffc0201cf6 <kfree+0x120>
ffffffffc0201c0c:	00007717          	auipc	a4,0x7
ffffffffc0201c10:	e1473703          	ld	a4,-492(a4) # ffffffffc0208a20 <npage>
ffffffffc0201c14:	0ee7f163          	bgeu	a5,a4,ffffffffc0201cf6 <kfree+0x120>

    struct slab *s = (struct slab *)ROUNDDOWN((uintptr_t)ptr, PGSIZE);
ffffffffc0201c18:	77fd                	lui	a5,0xfffff
ffffffffc0201c1a:	8fe9                	and	a5,a5,a0
    assert(s->magic == SLUB_MAGIC);
ffffffffc0201c1c:	534c5737          	lui	a4,0x534c5
ffffffffc0201c20:	54270713          	addi	a4,a4,1346 # 534c5542 <kern_entry-0xffffffff6cd3aabe>
ffffffffc0201c24:	6390                	ld	a2,0(a5)
ffffffffc0201c26:	02071693          	slli	a3,a4,0x20
ffffffffc0201c2a:	9736                	add	a4,a4,a3
ffffffffc0201c2c:	14e61563          	bne	a2,a4,ffffffffc0201d76 <kfree+0x1a0>
    assert(s->inuse > 0);
ffffffffc0201c30:	53d0                	lw	a2,36(a5)
ffffffffc0201c32:	12060263          	beqz	a2,ffffffffc0201d56 <kfree+0x180>

    if (s->cache == NULL) {
ffffffffc0201c36:	0087b803          	ld	a6,8(a5) # fffffffffffff008 <end+0x3fdf65d4>
        assert(ptr == (void *)((char *)s + object_offset()));
ffffffffc0201c3a:	06078713          	addi	a4,a5,96
    if (s->cache == NULL) {
ffffffffc0201c3e:	06080263          	beqz	a6,ffffffffc0201ca2 <kfree+0xcc>
        return;
    }

    struct kmem_cache *cache = s->cache;
    uintptr_t first = (uintptr_t)s + object_offset();
    assert((uintptr_t)ptr >= first);
ffffffffc0201c42:	1ae56a63          	bltu	a0,a4,ffffffffc0201df6 <kfree+0x220>
    size_t delta = (uintptr_t)ptr - first;
    assert(delta % cache->size == 0);
ffffffffc0201c46:	00083683          	ld	a3,0(a6)
    size_t delta = (uintptr_t)ptr - first;
ffffffffc0201c4a:	40e50733          	sub	a4,a0,a4
    assert(delta % cache->size == 0);
ffffffffc0201c4e:	02d775b3          	remu	a1,a4,a3
ffffffffc0201c52:	16059263          	bnez	a1,ffffffffc0201db6 <kfree+0x1e0>
    size_t index = delta / cache->size;
ffffffffc0201c56:	02d75733          	divu	a4,a4,a3
    assert(index < s->capacity);
ffffffffc0201c5a:	0207a303          	lw	t1,32(a5)
ffffffffc0201c5e:	02031693          	slli	a3,t1,0x20
ffffffffc0201c62:	9281                	srli	a3,a3,0x20
ffffffffc0201c64:	12d77963          	bgeu	a4,a3,ffffffffc0201d96 <kfree+0x1c0>
    uint64_t mask = 1ULL << (index % 64);
    assert((s->used[index / 64] & mask) != 0);
ffffffffc0201c68:	00675593          	srli	a1,a4,0x6
ffffffffc0201c6c:	058e                	slli	a1,a1,0x3
ffffffffc0201c6e:	95be                	add	a1,a1,a5
ffffffffc0201c70:	0405b883          	ld	a7,64(a1)
    uint64_t mask = 1ULL << (index % 64);
ffffffffc0201c74:	4685                	li	a3,1
ffffffffc0201c76:	00e69733          	sll	a4,a3,a4
    assert((s->used[index / 64] & mask) != 0);
ffffffffc0201c7a:	00e8f6b3          	and	a3,a7,a4
ffffffffc0201c7e:	14068c63          	beqz	a3,ffffffffc0201dd6 <kfree+0x200>

    if (s->inuse == s->capacity) {
ffffffffc0201c82:	02660a63          	beq	a2,t1,ffffffffc0201cb6 <kfree+0xe0>
        list_add(&cache->partial, &s->link);
    }
    s->used[index / 64] &= ~mask;
ffffffffc0201c86:	fff74713          	not	a4,a4
ffffffffc0201c8a:	01177733          	and	a4,a4,a7
ffffffffc0201c8e:	e1b8                	sd	a4,64(a1)
    *(void **)ptr = s->freelist;
ffffffffc0201c90:	7798                	ld	a4,40(a5)
    s->freelist = ptr;
    s->inuse--;
ffffffffc0201c92:	367d                	addiw	a2,a2,-1
    *(void **)ptr = s->freelist;
ffffffffc0201c94:	e118                	sd	a4,0(a0)
    s->inuse--;
ffffffffc0201c96:	d3d0                	sw	a2,36(a5)
    s->freelist = ptr;
ffffffffc0201c98:	f788                	sd	a0,40(a5)

    if (s->inuse == 0) {
ffffffffc0201c9a:	ce0d                	beqz	a2,ffffffffc0201cd4 <kfree+0xfe>
        struct Page *page = s->page;
        list_del_init(&s->link);
        s->magic = 0;
        free_page(page);
    }
ffffffffc0201c9c:	60a2                	ld	ra,8(sp)
ffffffffc0201c9e:	0141                	addi	sp,sp,16
ffffffffc0201ca0:	8082                	ret
        assert(ptr == (void *)((char *)s + object_offset()));
ffffffffc0201ca2:	16e51a63          	bne	a0,a4,ffffffffc0201e16 <kfree+0x240>
ffffffffc0201ca6:	60a2                	ld	ra,8(sp)
        free_pages(page, n);
ffffffffc0201ca8:	6f8c                	ld	a1,24(a5)
ffffffffc0201caa:	6b88                	ld	a0,16(a5)
        s->magic = 0;
ffffffffc0201cac:	0007b023          	sd	zero,0(a5)
ffffffffc0201cb0:	0141                	addi	sp,sp,16
        free_pages(page, n);
ffffffffc0201cb2:	9dfff06f          	j	ffffffffc0201690 <free_pages>
    __list_add(elm, listelm, listelm->next);
ffffffffc0201cb6:	01083303          	ld	t1,16(a6)
        list_add(&cache->partial, &s->link);
ffffffffc0201cba:	03078693          	addi	a3,a5,48
ffffffffc0201cbe:	00880e13          	addi	t3,a6,8
    prev->next = next->prev = elm;
ffffffffc0201cc2:	00d33023          	sd	a3,0(t1)
ffffffffc0201cc6:	00d83823          	sd	a3,16(a6)
    elm->next = next;
ffffffffc0201cca:	0267bc23          	sd	t1,56(a5)
    elm->prev = prev;
ffffffffc0201cce:	03c7b823          	sd	t3,48(a5)
}
ffffffffc0201cd2:	bf55                	j	ffffffffc0201c86 <kfree+0xb0>
    __list_del(listelm->prev, listelm->next);
ffffffffc0201cd4:	7b90                	ld	a2,48(a5)
ffffffffc0201cd6:	7f94                	ld	a3,56(a5)
        struct Page *page = s->page;
ffffffffc0201cd8:	6b88                	ld	a0,16(a5)
ffffffffc0201cda:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201cdc:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0201cde:	e290                	sd	a2,0(a3)
        list_del_init(&s->link);
ffffffffc0201ce0:	03078713          	addi	a4,a5,48
        s->magic = 0;
ffffffffc0201ce4:	0007b023          	sd	zero,0(a5)
    elm->prev = elm->next = elm;
ffffffffc0201ce8:	ff98                	sd	a4,56(a5)
ffffffffc0201cea:	fb98                	sd	a4,48(a5)
        free_page(page);
ffffffffc0201cec:	4585                	li	a1,1
ffffffffc0201cee:	0141                	addi	sp,sp,16
        free_page(page);
ffffffffc0201cf0:	9a1ff06f          	j	ffffffffc0201690 <free_pages>
ffffffffc0201cf4:	8082                	ret
    assert(PPN(pa) >= nbase && PPN(pa) < npage);
ffffffffc0201cf6:	00002697          	auipc	a3,0x2
ffffffffc0201cfa:	f7268693          	addi	a3,a3,-142 # ffffffffc0203c68 <etext+0xdae>
ffffffffc0201cfe:	00001617          	auipc	a2,0x1
ffffffffc0201d02:	43260613          	addi	a2,a2,1074 # ffffffffc0203130 <etext+0x276>
ffffffffc0201d06:	0a000593          	li	a1,160
ffffffffc0201d0a:	00002517          	auipc	a0,0x2
ffffffffc0201d0e:	ece50513          	addi	a0,a0,-306 # ffffffffc0203bd8 <etext+0xd1e>
ffffffffc0201d12:	cbefe0ef          	jal	ffffffffc02001d0 <__panic>
    assert(slub_ready);
ffffffffc0201d16:	00002697          	auipc	a3,0x2
ffffffffc0201d1a:	ed268693          	addi	a3,a3,-302 # ffffffffc0203be8 <etext+0xd2e>
ffffffffc0201d1e:	00001617          	auipc	a2,0x1
ffffffffc0201d22:	41260613          	addi	a2,a2,1042 # ffffffffc0203130 <etext+0x276>
ffffffffc0201d26:	09d00593          	li	a1,157
ffffffffc0201d2a:	00002517          	auipc	a0,0x2
ffffffffc0201d2e:	eae50513          	addi	a0,a0,-338 # ffffffffc0203bd8 <etext+0xd1e>
ffffffffc0201d32:	c9efe0ef          	jal	ffffffffc02001d0 <__panic>
    assert((uintptr_t)ptr >= KERNBASE);
ffffffffc0201d36:	00002697          	auipc	a3,0x2
ffffffffc0201d3a:	f1268693          	addi	a3,a3,-238 # ffffffffc0203c48 <etext+0xd8e>
ffffffffc0201d3e:	00001617          	auipc	a2,0x1
ffffffffc0201d42:	3f260613          	addi	a2,a2,1010 # ffffffffc0203130 <etext+0x276>
ffffffffc0201d46:	09e00593          	li	a1,158
ffffffffc0201d4a:	00002517          	auipc	a0,0x2
ffffffffc0201d4e:	e8e50513          	addi	a0,a0,-370 # ffffffffc0203bd8 <etext+0xd1e>
ffffffffc0201d52:	c7efe0ef          	jal	ffffffffc02001d0 <__panic>
    assert(s->inuse > 0);
ffffffffc0201d56:	00002697          	auipc	a3,0x2
ffffffffc0201d5a:	f5268693          	addi	a3,a3,-174 # ffffffffc0203ca8 <etext+0xdee>
ffffffffc0201d5e:	00001617          	auipc	a2,0x1
ffffffffc0201d62:	3d260613          	addi	a2,a2,978 # ffffffffc0203130 <etext+0x276>
ffffffffc0201d66:	0a400593          	li	a1,164
ffffffffc0201d6a:	00002517          	auipc	a0,0x2
ffffffffc0201d6e:	e6e50513          	addi	a0,a0,-402 # ffffffffc0203bd8 <etext+0xd1e>
ffffffffc0201d72:	c5efe0ef          	jal	ffffffffc02001d0 <__panic>
    assert(s->magic == SLUB_MAGIC);
ffffffffc0201d76:	00002697          	auipc	a3,0x2
ffffffffc0201d7a:	f1a68693          	addi	a3,a3,-230 # ffffffffc0203c90 <etext+0xdd6>
ffffffffc0201d7e:	00001617          	auipc	a2,0x1
ffffffffc0201d82:	3b260613          	addi	a2,a2,946 # ffffffffc0203130 <etext+0x276>
ffffffffc0201d86:	0a300593          	li	a1,163
ffffffffc0201d8a:	00002517          	auipc	a0,0x2
ffffffffc0201d8e:	e4e50513          	addi	a0,a0,-434 # ffffffffc0203bd8 <etext+0xd1e>
ffffffffc0201d92:	c3efe0ef          	jal	ffffffffc02001d0 <__panic>
    assert(index < s->capacity);
ffffffffc0201d96:	00002697          	auipc	a3,0x2
ffffffffc0201d9a:	e7268693          	addi	a3,a3,-398 # ffffffffc0203c08 <etext+0xd4e>
ffffffffc0201d9e:	00001617          	auipc	a2,0x1
ffffffffc0201da2:	39260613          	addi	a2,a2,914 # ffffffffc0203130 <etext+0x276>
ffffffffc0201da6:	0b600593          	li	a1,182
ffffffffc0201daa:	00002517          	auipc	a0,0x2
ffffffffc0201dae:	e2e50513          	addi	a0,a0,-466 # ffffffffc0203bd8 <etext+0xd1e>
ffffffffc0201db2:	c1efe0ef          	jal	ffffffffc02001d0 <__panic>
    assert(delta % cache->size == 0);
ffffffffc0201db6:	00002697          	auipc	a3,0x2
ffffffffc0201dba:	f4a68693          	addi	a3,a3,-182 # ffffffffc0203d00 <etext+0xe46>
ffffffffc0201dbe:	00001617          	auipc	a2,0x1
ffffffffc0201dc2:	37260613          	addi	a2,a2,882 # ffffffffc0203130 <etext+0x276>
ffffffffc0201dc6:	0b400593          	li	a1,180
ffffffffc0201dca:	00002517          	auipc	a0,0x2
ffffffffc0201dce:	e0e50513          	addi	a0,a0,-498 # ffffffffc0203bd8 <etext+0xd1e>
ffffffffc0201dd2:	bfefe0ef          	jal	ffffffffc02001d0 <__panic>
    assert((s->used[index / 64] & mask) != 0);
ffffffffc0201dd6:	00002697          	auipc	a3,0x2
ffffffffc0201dda:	f4a68693          	addi	a3,a3,-182 # ffffffffc0203d20 <etext+0xe66>
ffffffffc0201dde:	00001617          	auipc	a2,0x1
ffffffffc0201de2:	35260613          	addi	a2,a2,850 # ffffffffc0203130 <etext+0x276>
ffffffffc0201de6:	0b800593          	li	a1,184
ffffffffc0201dea:	00002517          	auipc	a0,0x2
ffffffffc0201dee:	dee50513          	addi	a0,a0,-530 # ffffffffc0203bd8 <etext+0xd1e>
ffffffffc0201df2:	bdefe0ef          	jal	ffffffffc02001d0 <__panic>
    assert((uintptr_t)ptr >= first);
ffffffffc0201df6:	00002697          	auipc	a3,0x2
ffffffffc0201dfa:	ef268693          	addi	a3,a3,-270 # ffffffffc0203ce8 <etext+0xe2e>
ffffffffc0201dfe:	00001617          	auipc	a2,0x1
ffffffffc0201e02:	33260613          	addi	a2,a2,818 # ffffffffc0203130 <etext+0x276>
ffffffffc0201e06:	0b200593          	li	a1,178
ffffffffc0201e0a:	00002517          	auipc	a0,0x2
ffffffffc0201e0e:	dce50513          	addi	a0,a0,-562 # ffffffffc0203bd8 <etext+0xd1e>
ffffffffc0201e12:	bbefe0ef          	jal	ffffffffc02001d0 <__panic>
        assert(ptr == (void *)((char *)s + object_offset()));
ffffffffc0201e16:	00002697          	auipc	a3,0x2
ffffffffc0201e1a:	ea268693          	addi	a3,a3,-350 # ffffffffc0203cb8 <etext+0xdfe>
ffffffffc0201e1e:	00001617          	auipc	a2,0x1
ffffffffc0201e22:	31260613          	addi	a2,a2,786 # ffffffffc0203130 <etext+0x276>
ffffffffc0201e26:	0a700593          	li	a1,167
ffffffffc0201e2a:	00002517          	auipc	a0,0x2
ffffffffc0201e2e:	dae50513          	addi	a0,a0,-594 # ffffffffc0203bd8 <etext+0xd1e>
ffffffffc0201e32:	b9efe0ef          	jal	ffffffffc02001d0 <__panic>

ffffffffc0201e36 <slub_check>:
    assert(nr_free_pages() == before);
    cprintf("slub_exhaustion_check() succeeded!\n");
}

void
slub_check(void) {
ffffffffc0201e36:	7171                	addi	sp,sp,-176
ffffffffc0201e38:	f506                	sd	ra,168(sp)
ffffffffc0201e3a:	e54e                	sd	s3,136(sp)
ffffffffc0201e3c:	f122                	sd	s0,160(sp)
ffffffffc0201e3e:	ed26                	sd	s1,152(sp)
ffffffffc0201e40:	e94a                	sd	s2,144(sp)
ffffffffc0201e42:	e152                	sd	s4,128(sp)
ffffffffc0201e44:	fcd6                	sd	s5,120(sp)
ffffffffc0201e46:	f8da                	sd	s6,112(sp)
ffffffffc0201e48:	f4de                	sd	s7,104(sp)
ffffffffc0201e4a:	f0e2                	sd	s8,96(sp)
ffffffffc0201e4c:	ece6                	sd	s9,88(sp)
ffffffffc0201e4e:	e8ea                	sd	s10,80(sp)
ffffffffc0201e50:	e4ee                	sd	s11,72(sp)
    size_t before = nr_free_pages();
ffffffffc0201e52:	84bff0ef          	jal	ffffffffc020169c <nr_free_pages>
ffffffffc0201e56:	e02a                	sd	a0,0(sp)
    size_t before = nr_free_pages();
ffffffffc0201e58:	845ff0ef          	jal	ffffffffc020169c <nr_free_pages>
ffffffffc0201e5c:	89aa                	mv	s3,a0
    assert(kmalloc(0) == NULL);
ffffffffc0201e5e:	4501                	li	a0,0
ffffffffc0201e60:	ae9ff0ef          	jal	ffffffffc0201948 <kmalloc>
ffffffffc0201e64:	360517e3          	bnez	a0,ffffffffc02029d2 <slub_check+0xb9c>
    assert(kmalloc((size_t)-1) == NULL);
ffffffffc0201e68:	557d                	li	a0,-1
ffffffffc0201e6a:	adfff0ef          	jal	ffffffffc0201948 <kmalloc>
ffffffffc0201e6e:	3a0512e3          	bnez	a0,ffffffffc0202a12 <slub_check+0xbdc>
    assert(kmalloc((size_t)-1 - 128) == NULL);
ffffffffc0201e72:	f7f00513          	li	a0,-129
ffffffffc0201e76:	ad3ff0ef          	jal	ffffffffc0201948 <kmalloc>
ffffffffc0201e7a:	36051ce3          	bnez	a0,ffffffffc02029f2 <slub_check+0xbbc>
    assert(kmalloc((npage - nbase) * PGSIZE) == NULL);
ffffffffc0201e7e:	00007517          	auipc	a0,0x7
ffffffffc0201e82:	ba253503          	ld	a0,-1118(a0) # ffffffffc0208a20 <npage>
ffffffffc0201e86:	00002797          	auipc	a5,0x2
ffffffffc0201e8a:	6527b783          	ld	a5,1618(a5) # ffffffffc02044d8 <nbase>
ffffffffc0201e8e:	8d1d                	sub	a0,a0,a5
ffffffffc0201e90:	0532                	slli	a0,a0,0xc
ffffffffc0201e92:	ab7ff0ef          	jal	ffffffffc0201948 <kmalloc>
ffffffffc0201e96:	24051ee3          	bnez	a0,ffffffffc02028f2 <slub_check+0xabc>
    kfree(NULL);
ffffffffc0201e9a:	d3dff0ef          	jal	ffffffffc0201bd6 <kfree>
    assert(nr_free_pages() == before);
ffffffffc0201e9e:	ffeff0ef          	jal	ffffffffc020169c <nr_free_pages>
ffffffffc0201ea2:	1ea998e3          	bne	s3,a0,ffffffffc0202892 <slub_check+0xa5c>
ffffffffc0201ea6:	00007417          	auipc	s0,0x7
ffffffffc0201eaa:	a3a40413          	addi	s0,s0,-1478 # ffffffffc02088e0 <objects.5>
ffffffffc0201eae:	8aa2                	mv	s5,s0
ffffffffc0201eb0:	00002917          	auipc	s2,0x2
ffffffffc0201eb4:	3a890913          	addi	s2,s2,936 # ffffffffc0204258 <sizes.6>
ffffffffc0201eb8:	00002c17          	auipc	s8,0x2
ffffffffc0201ebc:	3a8c0c13          	addi	s8,s8,936 # ffffffffc0204260 <sizes.6+0x8>
ffffffffc0201ec0:	4b85                	li	s7,1
    for (unsigned int i = 0; i < N; i++) {
ffffffffc0201ec2:	4b01                	li	s6,0
ffffffffc0201ec4:	4a79                	li	s4,30
        objects[i] = kmalloc(sizes[i]);
ffffffffc0201ec6:	855e                	mv	a0,s7
ffffffffc0201ec8:	a81ff0ef          	jal	ffffffffc0201948 <kmalloc>
ffffffffc0201ecc:	00aab023          	sd	a0,0(s5)
        assert(objects[i] != NULL);
ffffffffc0201ed0:	1a0501e3          	beqz	a0,ffffffffc0202872 <slub_check+0xa3c>
        assert((uintptr_t)objects[i] % SLUB_ALIGNMENT == 0);
ffffffffc0201ed4:	00f57493          	andi	s1,a0,15
ffffffffc0201ed8:	872a                	mv	a4,a0
ffffffffc0201eda:	16049ce3          	bnez	s1,ffffffffc0202852 <slub_check+0xa1c>
    assert(x + na <= y || y + nb <= x);
ffffffffc0201ede:	01750833          	add	a6,a0,s7
ffffffffc0201ee2:	00002617          	auipc	a2,0x2
ffffffffc0201ee6:	37660613          	addi	a2,a2,886 # ffffffffc0204258 <sizes.6>
ffffffffc0201eea:	00007697          	auipc	a3,0x7
ffffffffc0201eee:	9f668693          	addi	a3,a3,-1546 # ffffffffc02088e0 <objects.5>
        for (unsigned int j = 0; j < i; j++) {
ffffffffc0201ef2:	020b0e63          	beqz	s6,ffffffffc0201f2e <slub_check+0xf8>
    uintptr_t x = (uintptr_t)a, y = (uintptr_t)b;
ffffffffc0201ef6:	629c                	ld	a5,0(a3)
    assert(x + na <= y || y + nb <= x);
ffffffffc0201ef8:	0107f663          	bgeu	a5,a6,ffffffffc0201f04 <slub_check+0xce>
ffffffffc0201efc:	620c                	ld	a1,0(a2)
ffffffffc0201efe:	97ae                	add	a5,a5,a1
ffffffffc0201f00:	6cf56a63          	bltu	a0,a5,ffffffffc02025d4 <slub_check+0x79e>
        for (unsigned int j = 0; j < i; j++) {
ffffffffc0201f04:	06a1                	addi	a3,a3,8
ffffffffc0201f06:	0621                	addi	a2,a2,8
ffffffffc0201f08:	ff5697e3          	bne	a3,s5,ffffffffc0201ef6 <slub_check+0xc0>
        fill_bytes(objects[i], sizes[i], i + 1);
ffffffffc0201f0c:	2b05                	addiw	s6,s6,1
    for (size_t i = 0; i < size; i++) {
ffffffffc0201f0e:	000b8963          	beqz	s7,ffffffffc0201f20 <slub_check+0xea>
ffffffffc0201f12:	87da                	mv	a5,s6
        p[i] = (unsigned char)(tag + i * 17);
ffffffffc0201f14:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc0201f18:	0705                	addi	a4,a4,1
ffffffffc0201f1a:	27c5                	addiw	a5,a5,17
ffffffffc0201f1c:	ff071ce3          	bne	a4,a6,ffffffffc0201f14 <slub_check+0xde>
    for (unsigned int i = 0; i < N; i++) {
ffffffffc0201f20:	014b0b63          	beq	s6,s4,ffffffffc0201f36 <slub_check+0x100>
        objects[i] = kmalloc(sizes[i]);
ffffffffc0201f24:	000c3b83          	ld	s7,0(s8)
    for (unsigned int i = 0; i < N; i++) {
ffffffffc0201f28:	0aa1                	addi	s5,s5,8
ffffffffc0201f2a:	0c21                	addi	s8,s8,8
ffffffffc0201f2c:	bf69                	j	ffffffffc0201ec6 <slub_check+0x90>
        fill_bytes(objects[i], sizes[i], i + 1);
ffffffffc0201f2e:	4b05                	li	s6,1
    for (size_t i = 0; i < size; i++) {
ffffffffc0201f30:	fe0b91e3          	bnez	s7,ffffffffc0201f12 <slub_check+0xdc>
ffffffffc0201f34:	bfc5                	j	ffffffffc0201f24 <slub_check+0xee>
ffffffffc0201f36:	00007817          	auipc	a6,0x7
ffffffffc0201f3a:	9aa80813          	addi	a6,a6,-1622 # ffffffffc02088e0 <objects.5>
ffffffffc0201f3e:	00002517          	auipc	a0,0x2
ffffffffc0201f42:	31a50513          	addi	a0,a0,794 # ffffffffc0204258 <sizes.6>
    for (unsigned int i = 0; i < N; i++) {
ffffffffc0201f46:	4581                	li	a1,0
ffffffffc0201f48:	48f9                	li	a7,30
        check_bytes(objects[i], sizes[i], i + 1);
ffffffffc0201f4a:	6110                	ld	a2,0(a0)
ffffffffc0201f4c:	2585                	addiw	a1,a1,1
    for (size_t i = 0; i < size; i++) {
ffffffffc0201f4e:	c205                	beqz	a2,ffffffffc0201f6e <slub_check+0x138>
ffffffffc0201f50:	00083703          	ld	a4,0(a6)
ffffffffc0201f54:	0ff5f793          	zext.b	a5,a1
ffffffffc0201f58:	963a                	add	a2,a2,a4
        assert(p[i] == (unsigned char)(tag + i * 17));
ffffffffc0201f5a:	00074683          	lbu	a3,0(a4)
ffffffffc0201f5e:	12f69b63          	bne	a3,a5,ffffffffc0202094 <slub_check+0x25e>
    for (size_t i = 0; i < size; i++) {
ffffffffc0201f62:	27c5                	addiw	a5,a5,17
ffffffffc0201f64:	0705                	addi	a4,a4,1
ffffffffc0201f66:	0ff7f793          	zext.b	a5,a5
ffffffffc0201f6a:	fec718e3          	bne	a4,a2,ffffffffc0201f5a <slub_check+0x124>
    for (unsigned int i = 0; i < N; i++) {
ffffffffc0201f6e:	0521                	addi	a0,a0,8
ffffffffc0201f70:	0821                	addi	a6,a6,8
ffffffffc0201f72:	fd159ce3          	bne	a1,a7,ffffffffc0201f4a <slub_check+0x114>
ffffffffc0201f76:	00007a17          	auipc	s4,0x7
ffffffffc0201f7a:	972a0a13          	addi	s4,s4,-1678 # ffffffffc02088e8 <objects.5+0x8>
ffffffffc0201f7e:	00007a97          	auipc	s5,0x7
ffffffffc0201f82:	a5aa8a93          	addi	s5,s5,-1446 # ffffffffc02089d8 <memory_size>
        kfree(objects[i]);
ffffffffc0201f86:	000a3503          	ld	a0,0(s4)
    for (unsigned int i = 1; i < N; i += 2) {
ffffffffc0201f8a:	0a41                	addi	s4,s4,16
        kfree(objects[i]);
ffffffffc0201f8c:	c4bff0ef          	jal	ffffffffc0201bd6 <kfree>
    for (unsigned int i = 1; i < N; i += 2) {
ffffffffc0201f90:	ff5a1be3          	bne	s4,s5,ffffffffc0201f86 <slub_check+0x150>
ffffffffc0201f94:	00007a17          	auipc	s4,0x7
ffffffffc0201f98:	a3ca0a13          	addi	s4,s4,-1476 # ffffffffc02089d0 <is_panic>
ffffffffc0201f9c:	4a85                	li	s5,1
        check_bytes(objects[i], sizes[i], i + 1);
ffffffffc0201f9e:	00093603          	ld	a2,0(s2)
ffffffffc0201fa2:	6008                	ld	a0,0(s0)
    for (size_t i = 0; i < size; i++) {
ffffffffc0201fa4:	ce11                	beqz	a2,ffffffffc0201fc0 <slub_check+0x18a>
ffffffffc0201fa6:	962a                	add	a2,a2,a0
ffffffffc0201fa8:	872a                	mv	a4,a0
ffffffffc0201faa:	87d6                	mv	a5,s5
        assert(p[i] == (unsigned char)(tag + i * 17));
ffffffffc0201fac:	00074683          	lbu	a3,0(a4)
ffffffffc0201fb0:	0ef69263          	bne	a3,a5,ffffffffc0202094 <slub_check+0x25e>
    for (size_t i = 0; i < size; i++) {
ffffffffc0201fb4:	27c5                	addiw	a5,a5,17
ffffffffc0201fb6:	0705                	addi	a4,a4,1
ffffffffc0201fb8:	0ff7f793          	zext.b	a5,a5
ffffffffc0201fbc:	fec718e3          	bne	a4,a2,ffffffffc0201fac <slub_check+0x176>
    for (unsigned int i = 0; i < N; i += 2) {
ffffffffc0201fc0:	2a89                	addiw	s5,s5,2
ffffffffc0201fc2:	0441                	addi	s0,s0,16
        kfree(objects[i]);
ffffffffc0201fc4:	c13ff0ef          	jal	ffffffffc0201bd6 <kfree>
    for (unsigned int i = 0; i < N; i += 2) {
ffffffffc0201fc8:	0ffafa93          	zext.b	s5,s5
ffffffffc0201fcc:	0941                	addi	s2,s2,16
ffffffffc0201fce:	fd4418e3          	bne	s0,s4,ffffffffc0201f9e <slub_check+0x168>
    assert(nr_free_pages() == before);
ffffffffc0201fd2:	ecaff0ef          	jal	ffffffffc020169c <nr_free_pages>
ffffffffc0201fd6:	0ea99ee3          	bne	s3,a0,ffffffffc02028d2 <slub_check+0xa9c>
    cprintf("slub_sizes_check() succeeded!\n");
ffffffffc0201fda:	00002517          	auipc	a0,0x2
ffffffffc0201fde:	ea650513          	addi	a0,a0,-346 # ffffffffc0203e80 <etext+0xfc6>
ffffffffc0201fe2:	96efe0ef          	jal	ffffffffc0200150 <cprintf>
    size_t before = nr_free_pages();
ffffffffc0201fe6:	eb6ff0ef          	jal	ffffffffc020169c <nr_free_pages>
ffffffffc0201fea:	89aa                	mv	s3,a0
        objects[count] = kmalloc(64);
ffffffffc0201fec:	04000513          	li	a0,64
ffffffffc0201ff0:	959ff0ef          	jal	ffffffffc0201948 <kmalloc>
ffffffffc0201ff4:	00006b17          	auipc	s6,0x6
ffffffffc0201ff8:	6e4b0b13          	addi	s6,s6,1764 # ffffffffc02086d8 <objects.4>
ffffffffc0201ffc:	00ab3023          	sd	a0,0(s6)
        assert(objects[count] != NULL);
ffffffffc0202000:	0a0509e3          	beqz	a0,ffffffffc02028b2 <slub_check+0xa7c>
    } while (ROUNDDOWN((uintptr_t)objects[count - 1], PGSIZE) ==
ffffffffc0202004:	862a                	mv	a2,a0
ffffffffc0202006:	895a                	mv	s2,s6
ffffffffc0202008:	00007a97          	auipc	s5,0x7
ffffffffc020200c:	8d8a8a93          	addi	s5,s5,-1832 # ffffffffc02088e0 <objects.5>
ffffffffc0202010:	8cda                	mv	s9,s6
ffffffffc0202012:	4401                	li	s0,0
ffffffffc0202014:	4d01                	li	s10,0
ffffffffc0202016:	04100c13          	li	s8,65
            first_page = ROUNDDOWN((uintptr_t)objects[0], PGSIZE);
ffffffffc020201a:	7a7d                	lui	s4,0xfffff
    for (size_t i = 0; i < size; i++) {
ffffffffc020201c:	001d079b          	addiw	a5,s10,1
    } while (ROUNDDOWN((uintptr_t)objects[count - 1], PGSIZE) ==
ffffffffc0202020:	8732                	mv	a4,a2
    for (size_t i = 0; i < size; i++) {
ffffffffc0202022:	0117869b          	addiw	a3,a5,17
        p[i] = (unsigned char)(tag + i * 17);
ffffffffc0202026:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc020202a:	0ff6f793          	zext.b	a5,a3
ffffffffc020202e:	0705                	addi	a4,a4,1
ffffffffc0202030:	fefc19e3          	bne	s8,a5,ffffffffc0202022 <slub_check+0x1ec>
        if (count == 0) {
ffffffffc0202034:	000d1663          	bnez	s10,ffffffffc0202040 <slub_check+0x20a>
            first_page = ROUNDDOWN((uintptr_t)objects[0], PGSIZE);
ffffffffc0202038:	000b3403          	ld	s0,0(s6)
ffffffffc020203c:	01447433          	and	s0,s0,s4
    } while (ROUNDDOWN((uintptr_t)objects[count - 1], PGSIZE) ==
ffffffffc0202040:	01467633          	and	a2,a2,s4
        count++;
ffffffffc0202044:	001d0b93          	addi	s7,s10,1
    } while (ROUNDDOWN((uintptr_t)objects[count - 1], PGSIZE) ==
ffffffffc0202048:	06861563          	bne	a2,s0,ffffffffc02020b2 <slub_check+0x27c>
        assert(count < PGSIZE / 64 + 1);
ffffffffc020204c:	008c8d13          	addi	s10,s9,8
ffffffffc0202050:	575d0263          	beq	s10,s5,ffffffffc02025b4 <slub_check+0x77e>
        objects[count] = kmalloc(64);
ffffffffc0202054:	04000513          	li	a0,64
ffffffffc0202058:	8f1ff0ef          	jal	ffffffffc0201948 <kmalloc>
ffffffffc020205c:	00acb423          	sd	a0,8(s9)
        assert(objects[count] != NULL);
ffffffffc0202060:	040509e3          	beqz	a0,ffffffffc02028b2 <slub_check+0xa7c>
        assert(count < PGSIZE / 64 + 1);
ffffffffc0202064:	2c05                	addiw	s8,s8,1
    } while (ROUNDDOWN((uintptr_t)objects[count - 1], PGSIZE) ==
ffffffffc0202066:	862a                	mv	a2,a0
        assert(count < PGSIZE / 64 + 1);
ffffffffc0202068:	0ffc7c13          	zext.b	s8,s8
    assert(x + na <= y || y + nb <= x);
ffffffffc020206c:	04050693          	addi	a3,a0,64
ffffffffc0202070:	00006717          	auipc	a4,0x6
ffffffffc0202074:	66870713          	addi	a4,a4,1640 # ffffffffc02086d8 <objects.4>
    uintptr_t x = (uintptr_t)a, y = (uintptr_t)b;
ffffffffc0202078:	631c                	ld	a5,0(a4)
    assert(x + na <= y || y + nb <= x);
ffffffffc020207a:	00d7f663          	bgeu	a5,a3,ffffffffc0202086 <slub_check+0x250>
ffffffffc020207e:	04078793          	addi	a5,a5,64
ffffffffc0202082:	54f56963          	bltu	a0,a5,ffffffffc02025d4 <slub_check+0x79e>
        for (size_t j = 0; j < count; j++) {
ffffffffc0202086:	00ec8463          	beq	s9,a4,ffffffffc020208e <slub_check+0x258>
ffffffffc020208a:	0721                	addi	a4,a4,8
ffffffffc020208c:	b7f5                	j	ffffffffc0202078 <slub_check+0x242>
ffffffffc020208e:	8cea                	mv	s9,s10
ffffffffc0202090:	8d5e                	mv	s10,s7
ffffffffc0202092:	b769                	j	ffffffffc020201c <slub_check+0x1e6>
        assert(p[i] == (unsigned char)(tag + i * 17));
ffffffffc0202094:	00002697          	auipc	a3,0x2
ffffffffc0202098:	dc468693          	addi	a3,a3,-572 # ffffffffc0203e58 <etext+0xf9e>
ffffffffc020209c:	00001617          	auipc	a2,0x1
ffffffffc02020a0:	09460613          	addi	a2,a2,148 # ffffffffc0203130 <etext+0x276>
ffffffffc02020a4:	45cd                	li	a1,19
ffffffffc02020a6:	00002517          	auipc	a0,0x2
ffffffffc02020aa:	cba50513          	addi	a0,a0,-838 # ffffffffc0203d60 <etext+0xea6>
ffffffffc02020ae:	922fe0ef          	jal	ffffffffc02001d0 <__panic>
    assert(count > 2);
ffffffffc02020b2:	4789                	li	a5,2
ffffffffc02020b4:	0577ffe3          	bgeu	a5,s7,ffffffffc0202912 <slub_check+0xadc>
    assert(nr_free_pages() == before - 2);
ffffffffc02020b8:	de4ff0ef          	jal	ffffffffc020169c <nr_free_pages>
ffffffffc02020bc:	ffe98793          	addi	a5,s3,-2
ffffffffc02020c0:	842a                	mv	s0,a0
ffffffffc02020c2:	06f518e3          	bne	a0,a5,ffffffffc0202932 <slub_check+0xafc>
    void *old = objects[0];
ffffffffc02020c6:	000b3a03          	ld	s4,0(s6)
    kfree(old);  /* full -> partial */
ffffffffc02020ca:	8552                	mv	a0,s4
ffffffffc02020cc:	b0bff0ef          	jal	ffffffffc0201bd6 <kfree>
    objects[0] = kmalloc(64);
ffffffffc02020d0:	04000513          	li	a0,64
ffffffffc02020d4:	875ff0ef          	jal	ffffffffc0201948 <kmalloc>
ffffffffc02020d8:	00ab3023          	sd	a0,0(s6)
    assert(objects[0] == old);
ffffffffc02020dc:	06aa1be3          	bne	s4,a0,ffffffffc0202952 <slub_check+0xb1c>
    assert(nr_free_pages() == before - 2);
ffffffffc02020e0:	dbcff0ef          	jal	ffffffffc020169c <nr_free_pages>
ffffffffc02020e4:	08a417e3          	bne	s0,a0,ffffffffc0202972 <slub_check+0xb3c>
    for (size_t i = 0; i < size; i++) {
ffffffffc02020e8:	000b3783          	ld	a5,0(s6)
    fill_bytes(objects[0], 64, 1);
ffffffffc02020ec:	4a05                	li	s4,1
    for (size_t i = 0; i < size; i++) {
ffffffffc02020ee:	04100693          	li	a3,65
ffffffffc02020f2:	011a071b          	addiw	a4,s4,17 # fffffffffffff011 <end+0x3fdf65dd>
        p[i] = (unsigned char)(tag + i * 17);
ffffffffc02020f6:	01478023          	sb	s4,0(a5)
    for (size_t i = 0; i < size; i++) {
ffffffffc02020fa:	0ff77a13          	zext.b	s4,a4
ffffffffc02020fe:	0785                	addi	a5,a5,1
ffffffffc0202100:	feda19e3          	bne	s4,a3,ffffffffc02020f2 <slub_check+0x2bc>
    check_bytes(objects[count - 1], 64, count);
ffffffffc0202104:	003d1793          	slli	a5,s10,0x3
ffffffffc0202108:	9b3e                	add	s6,s6,a5
ffffffffc020210a:	000b3503          	ld	a0,0(s6)
        assert(p[i] == (unsigned char)(tag + i * 17));
ffffffffc020210e:	0ffbfb93          	zext.b	s7,s7
ffffffffc0202112:	040b869b          	addiw	a3,s7,64
ffffffffc0202116:	87aa                	mv	a5,a0
ffffffffc0202118:	0ff6f693          	zext.b	a3,a3
ffffffffc020211c:	0007c703          	lbu	a4,0(a5)
ffffffffc0202120:	f7771ae3          	bne	a4,s7,ffffffffc0202094 <slub_check+0x25e>
    for (size_t i = 0; i < size; i++) {
ffffffffc0202124:	2bc5                	addiw	s7,s7,17
ffffffffc0202126:	0ffbfb93          	zext.b	s7,s7
ffffffffc020212a:	0785                	addi	a5,a5,1
ffffffffc020212c:	fedb98e3          	bne	s7,a3,ffffffffc020211c <slub_check+0x2e6>
    kfree(objects[count - 1]); /* The second slab now becomes empty. */
ffffffffc0202130:	aa7ff0ef          	jal	ffffffffc0201bd6 <kfree>
    assert(nr_free_pages() == before - 1);
ffffffffc0202134:	d68ff0ef          	jal	ffffffffc020169c <nr_free_pages>
ffffffffc0202138:	fff98a93          	addi	s5,s3,-1
ffffffffc020213c:	4b05                	li	s6,1
ffffffffc020213e:	05551ae3          	bne	a0,s5,ffffffffc0202992 <slub_check+0xb5c>
        check_bytes(objects[i], 64, i + 1);
ffffffffc0202142:	00093503          	ld	a0,0(s2)
    for (size_t i = 0; i < size; i++) {
ffffffffc0202146:	0ffb7413          	zext.b	s0,s6
ffffffffc020214a:	87aa                	mv	a5,a0
        assert(p[i] == (unsigned char)(tag + i * 17));
ffffffffc020214c:	0007c703          	lbu	a4,0(a5)
ffffffffc0202150:	f48712e3          	bne	a4,s0,ffffffffc0202094 <slub_check+0x25e>
    for (size_t i = 0; i < size; i++) {
ffffffffc0202154:	2445                	addiw	s0,s0,17
ffffffffc0202156:	0ff47413          	zext.b	s0,s0
ffffffffc020215a:	0785                	addi	a5,a5,1
ffffffffc020215c:	ff4418e3          	bne	s0,s4,ffffffffc020214c <slub_check+0x316>
        kfree(objects[i]);
ffffffffc0202160:	a77ff0ef          	jal	ffffffffc0201bd6 <kfree>
        if (i + 1 < count - 1) {
ffffffffc0202164:	33ab6063          	bltu	s6,s10,ffffffffc0202484 <slub_check+0x64e>
    assert(nr_free_pages() == before);
ffffffffc0202168:	d34ff0ef          	jal	ffffffffc020169c <nr_free_pages>
ffffffffc020216c:	04a993e3          	bne	s3,a0,ffffffffc02029b2 <slub_check+0xb7c>
    cprintf("slub_reuse_check() succeeded!\n");
ffffffffc0202170:	00002517          	auipc	a0,0x2
ffffffffc0202174:	dc850513          	addi	a0,a0,-568 # ffffffffc0203f38 <etext+0x107e>
ffffffffc0202178:	fd9fd0ef          	jal	ffffffffc0200150 <cprintf>
    size_t before = nr_free_pages();
ffffffffc020217c:	d20ff0ef          	jal	ffffffffc020169c <nr_free_pages>
ffffffffc0202180:	00006d97          	auipc	s11,0x6
ffffffffc0202184:	358d8d93          	addi	s11,s11,856 # ffffffffc02084d8 <ptrs.3>
ffffffffc0202188:	e42a                	sd	a0,8(sp)
ffffffffc020218a:	8aee                	mv	s5,s11
ffffffffc020218c:	87ee                	mv	a5,s11
ffffffffc020218e:	00006b97          	auipc	s7,0x6
ffffffffc0202192:	54ab8b93          	addi	s7,s7,1354 # ffffffffc02086d8 <objects.4>
        ptrs[i] = NULL;
ffffffffc0202196:	0007b023          	sd	zero,0(a5)
    for (unsigned int i = 0; i < SLOTS; i++) {
ffffffffc020219a:	07a1                	addi	a5,a5,8
ffffffffc020219c:	ff779de3          	bne	a5,s7,ffffffffc0202196 <slub_check+0x360>
        state = state * 1664525U + 1013904223U;
ffffffffc02021a0:	3c6ef437          	lui	s0,0x3c6ef
    uint32_t state = 0x12345678U;
ffffffffc02021a4:	12345cb7          	lui	s9,0x12345
        state = state * 1664525U + 1013904223U;
ffffffffc02021a8:	00196937          	lui	s2,0x196
            size_t n = sizes[(state >> 8) %
ffffffffc02021ac:	2e8baa37          	lui	s4,0x2e8ba
    uint32_t state = 0x12345678U;
ffffffffc02021b0:	678c8c93          	addi	s9,s9,1656 # 12345678 <kern_entry-0xffffffffadeba988>
        state = state * 1664525U + 1013904223U;
ffffffffc02021b4:	60d9091b          	addiw	s2,s2,1549 # 19660d <kern_entry-0xffffffffc00699f3>
ffffffffc02021b8:	35f4041b          	addiw	s0,s0,863 # 3c6ef35f <kern_entry-0xffffffff83b10ca1>
            size_t n = sizes[(state >> 8) %
ffffffffc02021bc:	2e9a0a13          	addi	s4,s4,745 # 2e8ba2e9 <kern_entry-0xffffffff91945d17>
ffffffffc02021c0:	4d1d                	li	s10,7
            lengths[slot] = n;
ffffffffc02021c2:	00006997          	auipc	s3,0x6
ffffffffc02021c6:	11698993          	addi	s3,s3,278 # ffffffffc02082d8 <lengths.2>
            for (unsigned int j = 0; j < SLOTS; j++) {
ffffffffc02021ca:	04000c13          	li	s8,64
        state = state * 1664525U + 1013904223U;
ffffffffc02021ce:	032c8cbb          	mulw	s9,s9,s2
ffffffffc02021d2:	01940cbb          	addw	s9,s0,s9
        unsigned int slot = (state >> 16) % SLOTS;
ffffffffc02021d6:	010cd59b          	srliw	a1,s9,0x10
        if (ptrs[slot] != NULL) {
ffffffffc02021da:	03f5fb13          	andi	s6,a1,63
ffffffffc02021de:	003b1793          	slli	a5,s6,0x3
ffffffffc02021e2:	00fa8733          	add	a4,s5,a5
ffffffffc02021e6:	6308                	ld	a0,0(a4)
ffffffffc02021e8:	30050a63          	beqz	a0,ffffffffc02024fc <slub_check+0x6c6>
            check_bytes(ptrs[slot], lengths[slot], tags[slot]);
ffffffffc02021ec:	97ce                	add	a5,a5,s3
ffffffffc02021ee:	6390                	ld	a2,0(a5)
    for (size_t i = 0; i < size; i++) {
ffffffffc02021f0:	c615                	beqz	a2,ffffffffc020221c <slub_check+0x3e6>
            check_bytes(ptrs[slot], lengths[slot], tags[slot]);
ffffffffc02021f2:	002b1713          	slli	a4,s6,0x2
ffffffffc02021f6:	00006797          	auipc	a5,0x6
ffffffffc02021fa:	fe278793          	addi	a5,a5,-30 # ffffffffc02081d8 <tags.1>
ffffffffc02021fe:	97ba                	add	a5,a5,a4
        assert(p[i] == (unsigned char)(tag + i * 17));
ffffffffc0202200:	0007c783          	lbu	a5,0(a5)
ffffffffc0202204:	962a                	add	a2,a2,a0
ffffffffc0202206:	872a                	mv	a4,a0
ffffffffc0202208:	00074683          	lbu	a3,0(a4)
ffffffffc020220c:	e8f694e3          	bne	a3,a5,ffffffffc0202094 <slub_check+0x25e>
    for (size_t i = 0; i < size; i++) {
ffffffffc0202210:	27c5                	addiw	a5,a5,17
ffffffffc0202212:	0705                	addi	a4,a4,1
ffffffffc0202214:	0ff7f793          	zext.b	a5,a5
ffffffffc0202218:	fec718e3          	bne	a4,a2,ffffffffc0202208 <slub_check+0x3d2>
            kfree(ptrs[slot]);
ffffffffc020221c:	9bbff0ef          	jal	ffffffffc0201bd6 <kfree>
            ptrs[slot] = NULL;
ffffffffc0202220:	003b1793          	slli	a5,s6,0x3
ffffffffc0202224:	97d6                	add	a5,a5,s5
ffffffffc0202226:	0007b023          	sd	zero,0(a5)
        if (round % 37 == 0) {
ffffffffc020222a:	914c27b7          	lui	a5,0x914c2
ffffffffc020222e:	ff9d071b          	addiw	a4,s10,-7
ffffffffc0202232:	bad7879b          	addiw	a5,a5,-1107 # ffffffff914c1bad <kern_entry-0x2ed3e453>
ffffffffc0202236:	02e787bb          	mulw	a5,a5,a4
ffffffffc020223a:	06eb4737          	lui	a4,0x6eb4
ffffffffc020223e:	e4570713          	addi	a4,a4,-443 # 6eb3e45 <kern_entry-0xffffffffb934c1bb>
ffffffffc0202242:	26f77a63          	bgeu	a4,a5,ffffffffc02024b6 <slub_check+0x680>
    for (unsigned int round = 0; round < ROUNDS; round++) {
ffffffffc0202246:	6785                	lui	a5,0x1
ffffffffc0202248:	2d05                	addiw	s10,s10,1
ffffffffc020224a:	bbf78793          	addi	a5,a5,-1089 # bbf <kern_entry-0xffffffffc01ff441>
ffffffffc020224e:	f8fd10e3          	bne	s10,a5,ffffffffc02021ce <slub_check+0x398>
ffffffffc0202252:	00006917          	auipc	s2,0x6
ffffffffc0202256:	08690913          	addi	s2,s2,134 # ffffffffc02082d8 <lengths.2>
ffffffffc020225a:	00006417          	auipc	s0,0x6
ffffffffc020225e:	f7e40413          	addi	s0,s0,-130 # ffffffffc02081d8 <tags.1>
        if (ptrs[i] != NULL) {
ffffffffc0202262:	000db503          	ld	a0,0(s11)
ffffffffc0202266:	c515                	beqz	a0,ffffffffc0202292 <slub_check+0x45c>
            check_bytes(ptrs[i], lengths[i], tags[i]);
ffffffffc0202268:	00093603          	ld	a2,0(s2)
    for (size_t i = 0; i < size; i++) {
ffffffffc020226c:	ce19                	beqz	a2,ffffffffc020228a <slub_check+0x454>
        assert(p[i] == (unsigned char)(tag + i * 17));
ffffffffc020226e:	00044783          	lbu	a5,0(s0)
ffffffffc0202272:	962a                	add	a2,a2,a0
ffffffffc0202274:	872a                	mv	a4,a0
ffffffffc0202276:	00074683          	lbu	a3,0(a4)
ffffffffc020227a:	e0f69de3          	bne	a3,a5,ffffffffc0202094 <slub_check+0x25e>
    for (size_t i = 0; i < size; i++) {
ffffffffc020227e:	27c5                	addiw	a5,a5,17
ffffffffc0202280:	0705                	addi	a4,a4,1
ffffffffc0202282:	0ff7f793          	zext.b	a5,a5
ffffffffc0202286:	fec718e3          	bne	a4,a2,ffffffffc0202276 <slub_check+0x440>
            kfree(ptrs[i]);
ffffffffc020228a:	94dff0ef          	jal	ffffffffc0201bd6 <kfree>
            ptrs[i] = NULL;
ffffffffc020228e:	000db023          	sd	zero,0(s11)
    for (unsigned int i = 0; i < SLOTS; i++) {
ffffffffc0202292:	0da1                	addi	s11,s11,8
ffffffffc0202294:	0921                	addi	s2,s2,8
ffffffffc0202296:	0411                	addi	s0,s0,4
ffffffffc0202298:	fd7d95e3          	bne	s11,s7,ffffffffc0202262 <slub_check+0x42c>
    assert(nr_free_pages() == before);
ffffffffc020229c:	c00ff0ef          	jal	ffffffffc020169c <nr_free_pages>
ffffffffc02022a0:	67a2                	ld	a5,8(sp)
ffffffffc02022a2:	54a79863          	bne	a5,a0,ffffffffc02027f2 <slub_check+0x9bc>
    cprintf("slub_stress_check() succeeded!\n");
ffffffffc02022a6:	00002517          	auipc	a0,0x2
ffffffffc02022aa:	cfa50513          	addi	a0,a0,-774 # ffffffffc0203fa0 <etext+0x10e6>
ffffffffc02022ae:	ea3fd0ef          	jal	ffffffffc0200150 <cprintf>
    size_t before = nr_free_pages();
ffffffffc02022b2:	beaff0ef          	jal	ffffffffc020169c <nr_free_pages>
    assert(before > 8);
ffffffffc02022b6:	47a1                	li	a5,8
    size_t before = nr_free_pages();
ffffffffc02022b8:	89aa                	mv	s3,a0
    assert(before > 8);
ffffffffc02022ba:	50a7fc63          	bgeu	a5,a0,ffffffffc02027d2 <slub_check+0x99c>
    void *x = kmalloc(64);
ffffffffc02022be:	04000513          	li	a0,64
ffffffffc02022c2:	e86ff0ef          	jal	ffffffffc0201948 <kmalloc>
ffffffffc02022c6:	892a                	mv	s2,a0
    assert(x != NULL);
ffffffffc02022c8:	4c050563          	beqz	a0,ffffffffc0202792 <slub_check+0x95c>
ffffffffc02022cc:	8aaa                	mv	s5,a0
ffffffffc02022ce:	872a                	mv	a4,a0
ffffffffc02022d0:	03100793          	li	a5,49
    for (size_t i = 0; i < size; i++) {
ffffffffc02022d4:	07100693          	li	a3,113
ffffffffc02022d8:	0117861b          	addiw	a2,a5,17
        p[i] = (unsigned char)(tag + i * 17);
ffffffffc02022dc:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc02022e0:	0ff67793          	zext.b	a5,a2
ffffffffc02022e4:	0705                	addi	a4,a4,1
ffffffffc02022e6:	fed799e3          	bne	a5,a3,ffffffffc02022d8 <slub_check+0x4a2>
ffffffffc02022ea:	03010a13          	addi	s4,sp,48
ffffffffc02022ee:	fc52                	sd	s4,56(sp)
ffffffffc02022f0:	f852                	sd	s4,48(sp)
        assert(count < before - 1);
ffffffffc02022f2:	fff98413          	addi	s0,s3,-1
    while ((p = alloc_page()) != NULL) {
ffffffffc02022f6:	a821                	j	ffffffffc020230e <slub_check+0x4d8>
        assert(count < before - 1);
ffffffffc02022f8:	4a940d63          	beq	s0,s1,ffffffffc02027b2 <slub_check+0x97c>
    __list_add(elm, listelm, listelm->next);
ffffffffc02022fc:	77e2                	ld	a5,56(sp)
        list_add(&held, &p->page_link);
ffffffffc02022fe:	01850713          	addi	a4,a0,24
        count++;
ffffffffc0202302:	0485                	addi	s1,s1,1
    prev->next = next->prev = elm;
ffffffffc0202304:	e398                	sd	a4,0(a5)
ffffffffc0202306:	fc3a                	sd	a4,56(sp)
    elm->next = next;
ffffffffc0202308:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020230a:	01453c23          	sd	s4,24(a0)
    while ((p = alloc_page()) != NULL) {
ffffffffc020230e:	4505                	li	a0,1
ffffffffc0202310:	b74ff0ef          	jal	ffffffffc0201684 <alloc_pages>
ffffffffc0202314:	f175                	bnez	a0,ffffffffc02022f8 <slub_check+0x4c2>
    assert(count == before - 1);
ffffffffc0202316:	44941e63          	bne	s0,s1,ffffffffc0202772 <slub_check+0x93c>
    assert(nr_free_pages() == 0);
ffffffffc020231a:	b82ff0ef          	jal	ffffffffc020169c <nr_free_pages>
ffffffffc020231e:	42051a63          	bnez	a0,ffffffffc0202752 <slub_check+0x91c>
    void *y = kmalloc(64);
ffffffffc0202322:	04000513          	li	a0,64
ffffffffc0202326:	e22ff0ef          	jal	ffffffffc0201948 <kmalloc>
ffffffffc020232a:	842a                	mv	s0,a0
    assert(y != NULL);
ffffffffc020232c:	40050363          	beqz	a0,ffffffffc0202732 <slub_check+0x8fc>
    assert(x + na <= y || y + nb <= x);
ffffffffc0202330:	04090793          	addi	a5,s2,64
    uintptr_t x = (uintptr_t)a, y = (uintptr_t)b;
ffffffffc0202334:	84aa                	mv	s1,a0
    assert(x + na <= y || y + nb <= x);
ffffffffc0202336:	00f57663          	bgeu	a0,a5,ffffffffc0202342 <slub_check+0x50c>
ffffffffc020233a:	04050793          	addi	a5,a0,64
ffffffffc020233e:	28f96b63          	bltu	s2,a5,ffffffffc02025d4 <slub_check+0x79e>
ffffffffc0202342:	8722                	mv	a4,s0
ffffffffc0202344:	09200793          	li	a5,146
    for (size_t i = 0; i < size; i++) {
ffffffffc0202348:	0d200693          	li	a3,210
ffffffffc020234c:	0117861b          	addiw	a2,a5,17
        p[i] = (unsigned char)(tag + i * 17);
ffffffffc0202350:	00f70023          	sb	a5,0(a4)
    for (size_t i = 0; i < size; i++) {
ffffffffc0202354:	0ff67793          	zext.b	a5,a2
ffffffffc0202358:	0705                	addi	a4,a4,1
ffffffffc020235a:	fed799e3          	bne	a5,a3,ffffffffc020234c <slub_check+0x516>
    assert(kmalloc(2048) == NULL);
ffffffffc020235e:	6b05                	lui	s6,0x1
ffffffffc0202360:	800b0513          	addi	a0,s6,-2048 # 800 <kern_entry-0xffffffffc01ff800>
ffffffffc0202364:	de4ff0ef          	jal	ffffffffc0201948 <kmalloc>
ffffffffc0202368:	3a051563          	bnez	a0,ffffffffc0202712 <slub_check+0x8dc>
    assert(kmalloc(4096) == NULL);
ffffffffc020236c:	855a                	mv	a0,s6
ffffffffc020236e:	ddaff0ef          	jal	ffffffffc0201948 <kmalloc>
ffffffffc0202372:	38051063          	bnez	a0,ffffffffc02026f2 <slub_check+0x8bc>
    assert(nr_free_pages() == 0);
ffffffffc0202376:	b26ff0ef          	jal	ffffffffc020169c <nr_free_pages>
ffffffffc020237a:	03100793          	li	a5,49
    for (size_t i = 0; i < size; i++) {
ffffffffc020237e:	07100713          	li	a4,113
    assert(nr_free_pages() == 0);
ffffffffc0202382:	34051863          	bnez	a0,ffffffffc02026d2 <slub_check+0x89c>
        assert(p[i] == (unsigned char)(tag + i * 17));
ffffffffc0202386:	000ac683          	lbu	a3,0(s5)
ffffffffc020238a:	d0f695e3          	bne	a3,a5,ffffffffc0202094 <slub_check+0x25e>
    for (size_t i = 0; i < size; i++) {
ffffffffc020238e:	27c5                	addiw	a5,a5,17
ffffffffc0202390:	0ff7f793          	zext.b	a5,a5
ffffffffc0202394:	0a85                	addi	s5,s5,1
ffffffffc0202396:	fee798e3          	bne	a5,a4,ffffffffc0202386 <slub_check+0x550>
ffffffffc020239a:	09200793          	li	a5,146
ffffffffc020239e:	0d200713          	li	a4,210
        assert(p[i] == (unsigned char)(tag + i * 17));
ffffffffc02023a2:	0004c683          	lbu	a3,0(s1)
ffffffffc02023a6:	cef697e3          	bne	a3,a5,ffffffffc0202094 <slub_check+0x25e>
    for (size_t i = 0; i < size; i++) {
ffffffffc02023aa:	27c5                	addiw	a5,a5,17
ffffffffc02023ac:	0ff7f793          	zext.b	a5,a5
ffffffffc02023b0:	0485                	addi	s1,s1,1
ffffffffc02023b2:	fee798e3          	bne	a5,a4,ffffffffc02023a2 <slub_check+0x56c>
    kfree(y);
ffffffffc02023b6:	8522                	mv	a0,s0
ffffffffc02023b8:	81fff0ef          	jal	ffffffffc0201bd6 <kfree>
    kfree(x);
ffffffffc02023bc:	854a                	mv	a0,s2
ffffffffc02023be:	819ff0ef          	jal	ffffffffc0201bd6 <kfree>
    assert(nr_free_pages() == 1);
ffffffffc02023c2:	adaff0ef          	jal	ffffffffc020169c <nr_free_pages>
ffffffffc02023c6:	4785                	li	a5,1
ffffffffc02023c8:	842a                	mv	s0,a0
ffffffffc02023ca:	2ef51463          	bne	a0,a5,ffffffffc02026b2 <slub_check+0x87c>
    assert(kmalloc(4096) == NULL); /* Header means two pages are needed. */
ffffffffc02023ce:	6505                	lui	a0,0x1
ffffffffc02023d0:	d78ff0ef          	jal	ffffffffc0201948 <kmalloc>
ffffffffc02023d4:	2a051f63          	bnez	a0,ffffffffc0202692 <slub_check+0x85c>
    assert(nr_free_pages() == 1);
ffffffffc02023d8:	ac4ff0ef          	jal	ffffffffc020169c <nr_free_pages>
ffffffffc02023dc:	00850b63          	beq	a0,s0,ffffffffc02023f2 <slub_check+0x5bc>
ffffffffc02023e0:	ac49                	j	ffffffffc0202672 <slub_check+0x83c>
    __list_del(listelm->prev, listelm->next);
ffffffffc02023e2:	6118                	ld	a4,0(a0)
ffffffffc02023e4:	651c                	ld	a5,8(a0)
        free_page(p);
ffffffffc02023e6:	4585                	li	a1,1
ffffffffc02023e8:	1521                	addi	a0,a0,-24 # fe8 <kern_entry-0xffffffffc01ff018>
    prev->next = next;
ffffffffc02023ea:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02023ec:	e398                	sd	a4,0(a5)
ffffffffc02023ee:	aa2ff0ef          	jal	ffffffffc0201690 <free_pages>
    return list->next == list;
ffffffffc02023f2:	7562                	ld	a0,56(sp)
    while (!list_empty(&held)) {
ffffffffc02023f4:	ff4517e3          	bne	a0,s4,ffffffffc02023e2 <slub_check+0x5ac>
    assert(nr_free_pages() == before);
ffffffffc02023f8:	aa4ff0ef          	jal	ffffffffc020169c <nr_free_pages>
ffffffffc02023fc:	24a99b63          	bne	s3,a0,ffffffffc0202652 <slub_check+0x81c>
    x = kmalloc(4096);
ffffffffc0202400:	6505                	lui	a0,0x1
ffffffffc0202402:	d46ff0ef          	jal	ffffffffc0201948 <kmalloc>
    assert(x != NULL);
ffffffffc0202406:	1e050663          	beqz	a0,ffffffffc02025f2 <slub_check+0x7bc>
ffffffffc020240a:	6685                	lui	a3,0x1
ffffffffc020240c:	96aa                	add	a3,a3,a0
ffffffffc020240e:	872a                	mv	a4,a0
ffffffffc0202410:	87aa                	mv	a5,a0
ffffffffc0202412:	05300613          	li	a2,83
        p[i] = (unsigned char)(tag + i * 17);
ffffffffc0202416:	00c78023          	sb	a2,0(a5)
    for (size_t i = 0; i < size; i++) {
ffffffffc020241a:	0785                	addi	a5,a5,1
ffffffffc020241c:	2645                	addiw	a2,a2,17
ffffffffc020241e:	fef69ce3          	bne	a3,a5,ffffffffc0202416 <slub_check+0x5e0>
ffffffffc0202422:	05300793          	li	a5,83
        assert(p[i] == (unsigned char)(tag + i * 17));
ffffffffc0202426:	00074603          	lbu	a2,0(a4)
ffffffffc020242a:	c6f615e3          	bne	a2,a5,ffffffffc0202094 <slub_check+0x25e>
    for (size_t i = 0; i < size; i++) {
ffffffffc020242e:	27c5                	addiw	a5,a5,17
ffffffffc0202430:	0705                	addi	a4,a4,1
ffffffffc0202432:	0ff7f793          	zext.b	a5,a5
ffffffffc0202436:	fed718e3          	bne	a4,a3,ffffffffc0202426 <slub_check+0x5f0>
    kfree(x);
ffffffffc020243a:	f9cff0ef          	jal	ffffffffc0201bd6 <kfree>
    assert(nr_free_pages() == before);
ffffffffc020243e:	a5eff0ef          	jal	ffffffffc020169c <nr_free_pages>
ffffffffc0202442:	1ea99863          	bne	s3,a0,ffffffffc0202632 <slub_check+0x7fc>
    cprintf("slub_exhaustion_check() succeeded!\n");
ffffffffc0202446:	00002517          	auipc	a0,0x2
ffffffffc020244a:	c2250513          	addi	a0,a0,-990 # ffffffffc0204068 <etext+0x11ae>
ffffffffc020244e:	d03fd0ef          	jal	ffffffffc0200150 <cprintf>
    slub_sizes_check();
    slub_reuse_check();
    slub_stress_check();
    slub_exhaustion_check();
    assert(nr_free_pages() == before);
ffffffffc0202452:	a4aff0ef          	jal	ffffffffc020169c <nr_free_pages>
ffffffffc0202456:	6782                	ld	a5,0(sp)
ffffffffc0202458:	1af51d63          	bne	a0,a5,ffffffffc0202612 <slub_check+0x7dc>
    cprintf("slub_check() succeeded!\n");
ffffffffc020245c:	740a                	ld	s0,160(sp)
ffffffffc020245e:	70aa                	ld	ra,168(sp)
ffffffffc0202460:	64ea                	ld	s1,152(sp)
ffffffffc0202462:	694a                	ld	s2,144(sp)
ffffffffc0202464:	69aa                	ld	s3,136(sp)
ffffffffc0202466:	6a0a                	ld	s4,128(sp)
ffffffffc0202468:	7ae6                	ld	s5,120(sp)
ffffffffc020246a:	7b46                	ld	s6,112(sp)
ffffffffc020246c:	7ba6                	ld	s7,104(sp)
ffffffffc020246e:	7c06                	ld	s8,96(sp)
ffffffffc0202470:	6ce6                	ld	s9,88(sp)
ffffffffc0202472:	6d46                	ld	s10,80(sp)
ffffffffc0202474:	6da6                	ld	s11,72(sp)
    cprintf("slub_check() succeeded!\n");
ffffffffc0202476:	00002517          	auipc	a0,0x2
ffffffffc020247a:	c1a50513          	addi	a0,a0,-998 # ffffffffc0204090 <etext+0x11d6>
ffffffffc020247e:	614d                	addi	sp,sp,176
    cprintf("slub_check() succeeded!\n");
ffffffffc0202480:	cd1fd06f          	j	ffffffffc0200150 <cprintf>
            assert(nr_free_pages() == before - 1);
ffffffffc0202484:	2405                	addiw	s0,s0,1
ffffffffc0202486:	a16ff0ef          	jal	ffffffffc020169c <nr_free_pages>
ffffffffc020248a:	0ff47a13          	zext.b	s4,s0
ffffffffc020248e:	0b05                	addi	s6,s6,1
ffffffffc0202490:	0921                	addi	s2,s2,8
ffffffffc0202492:	caaa88e3          	beq	s5,a0,ffffffffc0202142 <slub_check+0x30c>
ffffffffc0202496:	00002697          	auipc	a3,0x2
ffffffffc020249a:	a8268693          	addi	a3,a3,-1406 # ffffffffc0203f18 <etext+0x105e>
ffffffffc020249e:	00001617          	auipc	a2,0x1
ffffffffc02024a2:	c9260613          	addi	a2,a2,-878 # ffffffffc0203130 <etext+0x276>
ffffffffc02024a6:	07100593          	li	a1,113
ffffffffc02024aa:	00002517          	auipc	a0,0x2
ffffffffc02024ae:	8b650513          	addi	a0,a0,-1866 # ffffffffc0203d60 <etext+0xea6>
ffffffffc02024b2:	d1ffd0ef          	jal	ffffffffc02001d0 <__panic>
ffffffffc02024b6:	00006697          	auipc	a3,0x6
ffffffffc02024ba:	e2268693          	addi	a3,a3,-478 # ffffffffc02082d8 <lengths.2>
ffffffffc02024be:	00006617          	auipc	a2,0x6
ffffffffc02024c2:	d1a60613          	addi	a2,a2,-742 # ffffffffc02081d8 <tags.1>
        if (round % 37 == 0) {
ffffffffc02024c6:	00006797          	auipc	a5,0x6
ffffffffc02024ca:	01278793          	addi	a5,a5,18 # ffffffffc02084d8 <ptrs.3>
                if (ptrs[j] != NULL) {
ffffffffc02024ce:	6398                	ld	a4,0(a5)
ffffffffc02024d0:	c305                	beqz	a4,ffffffffc02024f0 <slub_check+0x6ba>
                    check_bytes(ptrs[j], lengths[j], tags[j]);
ffffffffc02024d2:	628c                	ld	a1,0(a3)
    for (size_t i = 0; i < size; i++) {
ffffffffc02024d4:	cd91                	beqz	a1,ffffffffc02024f0 <slub_check+0x6ba>
        assert(p[i] == (unsigned char)(tag + i * 17));
ffffffffc02024d6:	00064503          	lbu	a0,0(a2)
ffffffffc02024da:	95ba                	add	a1,a1,a4
ffffffffc02024dc:	00074883          	lbu	a7,0(a4)
ffffffffc02024e0:	baa89ae3          	bne	a7,a0,ffffffffc0202094 <slub_check+0x25e>
    for (size_t i = 0; i < size; i++) {
ffffffffc02024e4:	2545                	addiw	a0,a0,17
ffffffffc02024e6:	0705                	addi	a4,a4,1
ffffffffc02024e8:	0ff57513          	zext.b	a0,a0
ffffffffc02024ec:	feb718e3          	bne	a4,a1,ffffffffc02024dc <slub_check+0x6a6>
            for (unsigned int j = 0; j < SLOTS; j++) {
ffffffffc02024f0:	07a1                	addi	a5,a5,8
ffffffffc02024f2:	06a1                	addi	a3,a3,8
ffffffffc02024f4:	0611                	addi	a2,a2,4
ffffffffc02024f6:	fd779ce3          	bne	a5,s7,ffffffffc02024ce <slub_check+0x698>
ffffffffc02024fa:	b3b1                	j	ffffffffc0202246 <slub_check+0x410>
            size_t n = sizes[(state >> 8) %
ffffffffc02024fc:	008cd69b          	srliw	a3,s9,0x8
ffffffffc0202500:	03468533          	mul	a0,a3,s4
ffffffffc0202504:	f03e                	sd	a5,32(sp)
ffffffffc0202506:	00002797          	auipc	a5,0x2
ffffffffc020250a:	cfa78793          	addi	a5,a5,-774 # ffffffffc0204200 <sizes.0>
ffffffffc020250e:	f43a                	sd	a4,40(sp)
ffffffffc0202510:	ec5a                	sd	s6,24(sp)
ffffffffc0202512:	9105                	srli	a0,a0,0x21
ffffffffc0202514:	0015161b          	slliw	a2,a0,0x1
ffffffffc0202518:	9e29                	addw	a2,a2,a0
ffffffffc020251a:	0026161b          	slliw	a2,a2,0x2
ffffffffc020251e:	9e09                	subw	a2,a2,a0
ffffffffc0202520:	9e91                	subw	a3,a3,a2
ffffffffc0202522:	02069613          	slli	a2,a3,0x20
ffffffffc0202526:	01d65693          	srli	a3,a2,0x1d
ffffffffc020252a:	96be                	add	a3,a3,a5
ffffffffc020252c:	0006be03          	ld	t3,0(a3)
            ptrs[slot] = kmalloc(n);
ffffffffc0202530:	8572                	mv	a0,t3
ffffffffc0202532:	e872                	sd	t3,16(sp)
ffffffffc0202534:	c14ff0ef          	jal	ffffffffc0201948 <kmalloc>
ffffffffc0202538:	7722                	ld	a4,40(sp)
            assert(ptrs[slot] != NULL);
ffffffffc020253a:	6e42                	ld	t3,16(sp)
ffffffffc020253c:	65e2                	ld	a1,24(sp)
            ptrs[slot] = kmalloc(n);
ffffffffc020253e:	e308                	sd	a0,0(a4)
            assert(ptrs[slot] != NULL);
ffffffffc0202540:	7782                	ld	a5,32(sp)
ffffffffc0202542:	2c050863          	beqz	a0,ffffffffc0202812 <slub_check+0x9dc>
            assert((uintptr_t)ptrs[slot] % SLUB_ALIGNMENT == 0);
ffffffffc0202546:	00f57713          	andi	a4,a0,15
ffffffffc020254a:	8eaa                	mv	t4,a0
ffffffffc020254c:	2e071363          	bnez	a4,ffffffffc0202832 <slub_check+0x9fc>
            tags[slot] = round + 7;
ffffffffc0202550:	002b1893          	slli	a7,s6,0x2
ffffffffc0202554:	00006717          	auipc	a4,0x6
ffffffffc0202558:	c8470713          	addi	a4,a4,-892 # ffffffffc02081d8 <tags.1>
ffffffffc020255c:	9746                	add	a4,a4,a7
            lengths[slot] = n;
ffffffffc020255e:	97ce                	add	a5,a5,s3
ffffffffc0202560:	01c7b023          	sd	t3,0(a5)
            tags[slot] = round + 7;
ffffffffc0202564:	01a72023          	sw	s10,0(a4)
ffffffffc0202568:	00006617          	auipc	a2,0x6
ffffffffc020256c:	d7060613          	addi	a2,a2,-656 # ffffffffc02082d8 <lengths.2>
ffffffffc0202570:	00006697          	auipc	a3,0x6
ffffffffc0202574:	f6868693          	addi	a3,a3,-152 # ffffffffc02084d8 <ptrs.3>
            for (unsigned int j = 0; j < SLOTS; j++) {
ffffffffc0202578:	4781                	li	a5,0
    assert(x + na <= y || y + nb <= x);
ffffffffc020257a:	01c508b3          	add	a7,a0,t3
                if (j != slot && ptrs[j] != NULL) {
ffffffffc020257e:	00f58b63          	beq	a1,a5,ffffffffc0202594 <slub_check+0x75e>
ffffffffc0202582:	6298                	ld	a4,0(a3)
ffffffffc0202584:	cb01                	beqz	a4,ffffffffc0202594 <slub_check+0x75e>
    assert(x + na <= y || y + nb <= x);
ffffffffc0202586:	01177763          	bgeu	a4,a7,ffffffffc0202594 <slub_check+0x75e>
ffffffffc020258a:	00063303          	ld	t1,0(a2)
ffffffffc020258e:	971a                	add	a4,a4,t1
ffffffffc0202590:	04e56263          	bltu	a0,a4,ffffffffc02025d4 <slub_check+0x79e>
            for (unsigned int j = 0; j < SLOTS; j++) {
ffffffffc0202594:	2785                	addiw	a5,a5,1
ffffffffc0202596:	0621                	addi	a2,a2,8
ffffffffc0202598:	06a1                	addi	a3,a3,8
ffffffffc020259a:	ff8792e3          	bne	a5,s8,ffffffffc020257e <slub_check+0x748>
    for (size_t i = 0; i < size; i++) {
ffffffffc020259e:	9572                	add	a0,a0,t3
ffffffffc02025a0:	87ea                	mv	a5,s10
ffffffffc02025a2:	c80e04e3          	beqz	t3,ffffffffc020222a <slub_check+0x3f4>
        p[i] = (unsigned char)(tag + i * 17);
ffffffffc02025a6:	00fe8023          	sb	a5,0(t4)
    for (size_t i = 0; i < size; i++) {
ffffffffc02025aa:	0e85                	addi	t4,t4,1
ffffffffc02025ac:	27c5                	addiw	a5,a5,17
ffffffffc02025ae:	feae9ce3          	bne	t4,a0,ffffffffc02025a6 <slub_check+0x770>
ffffffffc02025b2:	b9a5                	j	ffffffffc020222a <slub_check+0x3f4>
        assert(count < PGSIZE / 64 + 1);
ffffffffc02025b4:	00002697          	auipc	a3,0x2
ffffffffc02025b8:	8ec68693          	addi	a3,a3,-1812 # ffffffffc0203ea0 <etext+0xfe6>
ffffffffc02025bc:	00001617          	auipc	a2,0x1
ffffffffc02025c0:	b7460613          	addi	a2,a2,-1164 # ffffffffc0203130 <etext+0x276>
ffffffffc02025c4:	05200593          	li	a1,82
ffffffffc02025c8:	00001517          	auipc	a0,0x1
ffffffffc02025cc:	79850513          	addi	a0,a0,1944 # ffffffffc0203d60 <etext+0xea6>
ffffffffc02025d0:	c01fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(x + na <= y || y + nb <= x);
ffffffffc02025d4:	00002697          	auipc	a3,0x2
ffffffffc02025d8:	86468693          	addi	a3,a3,-1948 # ffffffffc0203e38 <etext+0xf7e>
ffffffffc02025dc:	00001617          	auipc	a2,0x1
ffffffffc02025e0:	b5460613          	addi	a2,a2,-1196 # ffffffffc0203130 <etext+0x276>
ffffffffc02025e4:	45e9                	li	a1,26
ffffffffc02025e6:	00001517          	auipc	a0,0x1
ffffffffc02025ea:	77a50513          	addi	a0,a0,1914 # ffffffffc0203d60 <etext+0xea6>
ffffffffc02025ee:	be3fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(x != NULL);
ffffffffc02025f2:	00002697          	auipc	a3,0x2
ffffffffc02025f6:	9de68693          	addi	a3,a3,-1570 # ffffffffc0203fd0 <etext+0x1116>
ffffffffc02025fa:	00001617          	auipc	a2,0x1
ffffffffc02025fe:	b3660613          	addi	a2,a2,-1226 # ffffffffc0203130 <etext+0x276>
ffffffffc0202602:	0df00593          	li	a1,223
ffffffffc0202606:	00001517          	auipc	a0,0x1
ffffffffc020260a:	75a50513          	addi	a0,a0,1882 # ffffffffc0203d60 <etext+0xea6>
ffffffffc020260e:	bc3fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free_pages() == before);
ffffffffc0202612:	00001697          	auipc	a3,0x1
ffffffffc0202616:	13668693          	addi	a3,a3,310 # ffffffffc0203748 <etext+0x88e>
ffffffffc020261a:	00001617          	auipc	a2,0x1
ffffffffc020261e:	b1660613          	addi	a2,a2,-1258 # ffffffffc0203130 <etext+0x276>
ffffffffc0202622:	0ee00593          	li	a1,238
ffffffffc0202626:	00001517          	auipc	a0,0x1
ffffffffc020262a:	73a50513          	addi	a0,a0,1850 # ffffffffc0203d60 <etext+0xea6>
ffffffffc020262e:	ba3fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free_pages() == before);
ffffffffc0202632:	00001697          	auipc	a3,0x1
ffffffffc0202636:	11668693          	addi	a3,a3,278 # ffffffffc0203748 <etext+0x88e>
ffffffffc020263a:	00001617          	auipc	a2,0x1
ffffffffc020263e:	af660613          	addi	a2,a2,-1290 # ffffffffc0203130 <etext+0x276>
ffffffffc0202642:	0e300593          	li	a1,227
ffffffffc0202646:	00001517          	auipc	a0,0x1
ffffffffc020264a:	71a50513          	addi	a0,a0,1818 # ffffffffc0203d60 <etext+0xea6>
ffffffffc020264e:	b83fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free_pages() == before);
ffffffffc0202652:	00001697          	auipc	a3,0x1
ffffffffc0202656:	0f668693          	addi	a3,a3,246 # ffffffffc0203748 <etext+0x88e>
ffffffffc020265a:	00001617          	auipc	a2,0x1
ffffffffc020265e:	ad660613          	addi	a2,a2,-1322 # ffffffffc0203130 <etext+0x276>
ffffffffc0202662:	0dc00593          	li	a1,220
ffffffffc0202666:	00001517          	auipc	a0,0x1
ffffffffc020266a:	6fa50513          	addi	a0,a0,1786 # ffffffffc0203d60 <etext+0xea6>
ffffffffc020266e:	b63fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free_pages() == 1);
ffffffffc0202672:	00002697          	auipc	a3,0x2
ffffffffc0202676:	9de68693          	addi	a3,a3,-1570 # ffffffffc0204050 <etext+0x1196>
ffffffffc020267a:	00001617          	auipc	a2,0x1
ffffffffc020267e:	ab660613          	addi	a2,a2,-1354 # ffffffffc0203130 <etext+0x276>
ffffffffc0202682:	0d500593          	li	a1,213
ffffffffc0202686:	00001517          	auipc	a0,0x1
ffffffffc020268a:	6da50513          	addi	a0,a0,1754 # ffffffffc0203d60 <etext+0xea6>
ffffffffc020268e:	b43fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(kmalloc(4096) == NULL); /* Header means two pages are needed. */
ffffffffc0202692:	00002697          	auipc	a3,0x2
ffffffffc0202696:	9a668693          	addi	a3,a3,-1626 # ffffffffc0204038 <etext+0x117e>
ffffffffc020269a:	00001617          	auipc	a2,0x1
ffffffffc020269e:	a9660613          	addi	a2,a2,-1386 # ffffffffc0203130 <etext+0x276>
ffffffffc02026a2:	0d400593          	li	a1,212
ffffffffc02026a6:	00001517          	auipc	a0,0x1
ffffffffc02026aa:	6ba50513          	addi	a0,a0,1722 # ffffffffc0203d60 <etext+0xea6>
ffffffffc02026ae:	b23fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free_pages() == 1);
ffffffffc02026b2:	00002697          	auipc	a3,0x2
ffffffffc02026b6:	99e68693          	addi	a3,a3,-1634 # ffffffffc0204050 <etext+0x1196>
ffffffffc02026ba:	00001617          	auipc	a2,0x1
ffffffffc02026be:	a7660613          	addi	a2,a2,-1418 # ffffffffc0203130 <etext+0x276>
ffffffffc02026c2:	0d300593          	li	a1,211
ffffffffc02026c6:	00001517          	auipc	a0,0x1
ffffffffc02026ca:	69a50513          	addi	a0,a0,1690 # ffffffffc0203d60 <etext+0xea6>
ffffffffc02026ce:	b03fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free_pages() == 0);
ffffffffc02026d2:	00001697          	auipc	a3,0x1
ffffffffc02026d6:	1be68693          	addi	a3,a3,446 # ffffffffc0203890 <etext+0x9d6>
ffffffffc02026da:	00001617          	auipc	a2,0x1
ffffffffc02026de:	a5660613          	addi	a2,a2,-1450 # ffffffffc0203130 <etext+0x276>
ffffffffc02026e2:	0cd00593          	li	a1,205
ffffffffc02026e6:	00001517          	auipc	a0,0x1
ffffffffc02026ea:	67a50513          	addi	a0,a0,1658 # ffffffffc0203d60 <etext+0xea6>
ffffffffc02026ee:	ae3fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(kmalloc(4096) == NULL);
ffffffffc02026f2:	00002697          	auipc	a3,0x2
ffffffffc02026f6:	94668693          	addi	a3,a3,-1722 # ffffffffc0204038 <etext+0x117e>
ffffffffc02026fa:	00001617          	auipc	a2,0x1
ffffffffc02026fe:	a3660613          	addi	a2,a2,-1482 # ffffffffc0203130 <etext+0x276>
ffffffffc0202702:	0cc00593          	li	a1,204
ffffffffc0202706:	00001517          	auipc	a0,0x1
ffffffffc020270a:	65a50513          	addi	a0,a0,1626 # ffffffffc0203d60 <etext+0xea6>
ffffffffc020270e:	ac3fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(kmalloc(2048) == NULL);
ffffffffc0202712:	00002697          	auipc	a3,0x2
ffffffffc0202716:	90e68693          	addi	a3,a3,-1778 # ffffffffc0204020 <etext+0x1166>
ffffffffc020271a:	00001617          	auipc	a2,0x1
ffffffffc020271e:	a1660613          	addi	a2,a2,-1514 # ffffffffc0203130 <etext+0x276>
ffffffffc0202722:	0cb00593          	li	a1,203
ffffffffc0202726:	00001517          	auipc	a0,0x1
ffffffffc020272a:	63a50513          	addi	a0,a0,1594 # ffffffffc0203d60 <etext+0xea6>
ffffffffc020272e:	aa3fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(y != NULL);
ffffffffc0202732:	00002697          	auipc	a3,0x2
ffffffffc0202736:	8de68693          	addi	a3,a3,-1826 # ffffffffc0204010 <etext+0x1156>
ffffffffc020273a:	00001617          	auipc	a2,0x1
ffffffffc020273e:	9f660613          	addi	a2,a2,-1546 # ffffffffc0203130 <etext+0x276>
ffffffffc0202742:	0c800593          	li	a1,200
ffffffffc0202746:	00001517          	auipc	a0,0x1
ffffffffc020274a:	61a50513          	addi	a0,a0,1562 # ffffffffc0203d60 <etext+0xea6>
ffffffffc020274e:	a83fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free_pages() == 0);
ffffffffc0202752:	00001697          	auipc	a3,0x1
ffffffffc0202756:	13e68693          	addi	a3,a3,318 # ffffffffc0203890 <etext+0x9d6>
ffffffffc020275a:	00001617          	auipc	a2,0x1
ffffffffc020275e:	9d660613          	addi	a2,a2,-1578 # ffffffffc0203130 <etext+0x276>
ffffffffc0202762:	0c400593          	li	a1,196
ffffffffc0202766:	00001517          	auipc	a0,0x1
ffffffffc020276a:	5fa50513          	addi	a0,a0,1530 # ffffffffc0203d60 <etext+0xea6>
ffffffffc020276e:	a63fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(count == before - 1);
ffffffffc0202772:	00002697          	auipc	a3,0x2
ffffffffc0202776:	88668693          	addi	a3,a3,-1914 # ffffffffc0203ff8 <etext+0x113e>
ffffffffc020277a:	00001617          	auipc	a2,0x1
ffffffffc020277e:	9b660613          	addi	a2,a2,-1610 # ffffffffc0203130 <etext+0x276>
ffffffffc0202782:	0c300593          	li	a1,195
ffffffffc0202786:	00001517          	auipc	a0,0x1
ffffffffc020278a:	5da50513          	addi	a0,a0,1498 # ffffffffc0203d60 <etext+0xea6>
ffffffffc020278e:	a43fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(x != NULL);
ffffffffc0202792:	00002697          	auipc	a3,0x2
ffffffffc0202796:	83e68693          	addi	a3,a3,-1986 # ffffffffc0203fd0 <etext+0x1116>
ffffffffc020279a:	00001617          	auipc	a2,0x1
ffffffffc020279e:	99660613          	addi	a2,a2,-1642 # ffffffffc0203130 <etext+0x276>
ffffffffc02027a2:	0b600593          	li	a1,182
ffffffffc02027a6:	00001517          	auipc	a0,0x1
ffffffffc02027aa:	5ba50513          	addi	a0,a0,1466 # ffffffffc0203d60 <etext+0xea6>
ffffffffc02027ae:	a23fd0ef          	jal	ffffffffc02001d0 <__panic>
        assert(count < before - 1);
ffffffffc02027b2:	00002697          	auipc	a3,0x2
ffffffffc02027b6:	82e68693          	addi	a3,a3,-2002 # ffffffffc0203fe0 <etext+0x1126>
ffffffffc02027ba:	00001617          	auipc	a2,0x1
ffffffffc02027be:	97660613          	addi	a2,a2,-1674 # ffffffffc0203130 <etext+0x276>
ffffffffc02027c2:	0bf00593          	li	a1,191
ffffffffc02027c6:	00001517          	auipc	a0,0x1
ffffffffc02027ca:	59a50513          	addi	a0,a0,1434 # ffffffffc0203d60 <etext+0xea6>
ffffffffc02027ce:	a03fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(before > 8);
ffffffffc02027d2:	00001697          	auipc	a3,0x1
ffffffffc02027d6:	7ee68693          	addi	a3,a3,2030 # ffffffffc0203fc0 <etext+0x1106>
ffffffffc02027da:	00001617          	auipc	a2,0x1
ffffffffc02027de:	95660613          	addi	a2,a2,-1706 # ffffffffc0203130 <etext+0x276>
ffffffffc02027e2:	0b400593          	li	a1,180
ffffffffc02027e6:	00001517          	auipc	a0,0x1
ffffffffc02027ea:	57a50513          	addi	a0,a0,1402 # ffffffffc0203d60 <etext+0xea6>
ffffffffc02027ee:	9e3fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free_pages() == before);
ffffffffc02027f2:	00001697          	auipc	a3,0x1
ffffffffc02027f6:	f5668693          	addi	a3,a3,-170 # ffffffffc0203748 <etext+0x88e>
ffffffffc02027fa:	00001617          	auipc	a2,0x1
ffffffffc02027fe:	93660613          	addi	a2,a2,-1738 # ffffffffc0203130 <etext+0x276>
ffffffffc0202802:	0ad00593          	li	a1,173
ffffffffc0202806:	00001517          	auipc	a0,0x1
ffffffffc020280a:	55a50513          	addi	a0,a0,1370 # ffffffffc0203d60 <etext+0xea6>
ffffffffc020280e:	9c3fd0ef          	jal	ffffffffc02001d0 <__panic>
            assert(ptrs[slot] != NULL);
ffffffffc0202812:	00001697          	auipc	a3,0x1
ffffffffc0202816:	74668693          	addi	a3,a3,1862 # ffffffffc0203f58 <etext+0x109e>
ffffffffc020281a:	00001617          	auipc	a2,0x1
ffffffffc020281e:	91660613          	addi	a2,a2,-1770 # ffffffffc0203130 <etext+0x276>
ffffffffc0202822:	09300593          	li	a1,147
ffffffffc0202826:	00001517          	auipc	a0,0x1
ffffffffc020282a:	53a50513          	addi	a0,a0,1338 # ffffffffc0203d60 <etext+0xea6>
ffffffffc020282e:	9a3fd0ef          	jal	ffffffffc02001d0 <__panic>
            assert((uintptr_t)ptrs[slot] % SLUB_ALIGNMENT == 0);
ffffffffc0202832:	00001697          	auipc	a3,0x1
ffffffffc0202836:	73e68693          	addi	a3,a3,1854 # ffffffffc0203f70 <etext+0x10b6>
ffffffffc020283a:	00001617          	auipc	a2,0x1
ffffffffc020283e:	8f660613          	addi	a2,a2,-1802 # ffffffffc0203130 <etext+0x276>
ffffffffc0202842:	09400593          	li	a1,148
ffffffffc0202846:	00001517          	auipc	a0,0x1
ffffffffc020284a:	51a50513          	addi	a0,a0,1306 # ffffffffc0203d60 <etext+0xea6>
ffffffffc020284e:	983fd0ef          	jal	ffffffffc02001d0 <__panic>
        assert((uintptr_t)objects[i] % SLUB_ALIGNMENT == 0);
ffffffffc0202852:	00001697          	auipc	a3,0x1
ffffffffc0202856:	5b668693          	addi	a3,a3,1462 # ffffffffc0203e08 <etext+0xf4e>
ffffffffc020285a:	00001617          	auipc	a2,0x1
ffffffffc020285e:	8d660613          	addi	a2,a2,-1834 # ffffffffc0203130 <etext+0x276>
ffffffffc0202862:	03300593          	li	a1,51
ffffffffc0202866:	00001517          	auipc	a0,0x1
ffffffffc020286a:	4fa50513          	addi	a0,a0,1274 # ffffffffc0203d60 <etext+0xea6>
ffffffffc020286e:	963fd0ef          	jal	ffffffffc02001d0 <__panic>
        assert(objects[i] != NULL);
ffffffffc0202872:	00001697          	auipc	a3,0x1
ffffffffc0202876:	57e68693          	addi	a3,a3,1406 # ffffffffc0203df0 <etext+0xf36>
ffffffffc020287a:	00001617          	auipc	a2,0x1
ffffffffc020287e:	8b660613          	addi	a2,a2,-1866 # ffffffffc0203130 <etext+0x276>
ffffffffc0202882:	03200593          	li	a1,50
ffffffffc0202886:	00001517          	auipc	a0,0x1
ffffffffc020288a:	4da50513          	addi	a0,a0,1242 # ffffffffc0203d60 <etext+0xea6>
ffffffffc020288e:	943fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free_pages() == before);
ffffffffc0202892:	00001697          	auipc	a3,0x1
ffffffffc0202896:	eb668693          	addi	a3,a3,-330 # ffffffffc0203748 <etext+0x88e>
ffffffffc020289a:	00001617          	auipc	a2,0x1
ffffffffc020289e:	89660613          	addi	a2,a2,-1898 # ffffffffc0203130 <etext+0x276>
ffffffffc02028a2:	02e00593          	li	a1,46
ffffffffc02028a6:	00001517          	auipc	a0,0x1
ffffffffc02028aa:	4ba50513          	addi	a0,a0,1210 # ffffffffc0203d60 <etext+0xea6>
ffffffffc02028ae:	923fd0ef          	jal	ffffffffc02001d0 <__panic>
        assert(objects[count] != NULL);
ffffffffc02028b2:	00001697          	auipc	a3,0x1
ffffffffc02028b6:	60668693          	addi	a3,a3,1542 # ffffffffc0203eb8 <etext+0xffe>
ffffffffc02028ba:	00001617          	auipc	a2,0x1
ffffffffc02028be:	87660613          	addi	a2,a2,-1930 # ffffffffc0203130 <etext+0x276>
ffffffffc02028c2:	05400593          	li	a1,84
ffffffffc02028c6:	00001517          	auipc	a0,0x1
ffffffffc02028ca:	49a50513          	addi	a0,a0,1178 # ffffffffc0203d60 <etext+0xea6>
ffffffffc02028ce:	903fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free_pages() == before);
ffffffffc02028d2:	00001697          	auipc	a3,0x1
ffffffffc02028d6:	e7668693          	addi	a3,a3,-394 # ffffffffc0203748 <etext+0x88e>
ffffffffc02028da:	00001617          	auipc	a2,0x1
ffffffffc02028de:	85660613          	addi	a2,a2,-1962 # ffffffffc0203130 <etext+0x276>
ffffffffc02028e2:	04500593          	li	a1,69
ffffffffc02028e6:	00001517          	auipc	a0,0x1
ffffffffc02028ea:	47a50513          	addi	a0,a0,1146 # ffffffffc0203d60 <etext+0xea6>
ffffffffc02028ee:	8e3fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(kmalloc((npage - nbase) * PGSIZE) == NULL);
ffffffffc02028f2:	00001697          	auipc	a3,0x1
ffffffffc02028f6:	4ce68693          	addi	a3,a3,1230 # ffffffffc0203dc0 <etext+0xf06>
ffffffffc02028fa:	00001617          	auipc	a2,0x1
ffffffffc02028fe:	83660613          	addi	a2,a2,-1994 # ffffffffc0203130 <etext+0x276>
ffffffffc0202902:	02c00593          	li	a1,44
ffffffffc0202906:	00001517          	auipc	a0,0x1
ffffffffc020290a:	45a50513          	addi	a0,a0,1114 # ffffffffc0203d60 <etext+0xea6>
ffffffffc020290e:	8c3fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(count > 2);
ffffffffc0202912:	00001697          	auipc	a3,0x1
ffffffffc0202916:	5be68693          	addi	a3,a3,1470 # ffffffffc0203ed0 <etext+0x1016>
ffffffffc020291a:	00001617          	auipc	a2,0x1
ffffffffc020291e:	81660613          	addi	a2,a2,-2026 # ffffffffc0203130 <etext+0x276>
ffffffffc0202922:	06000593          	li	a1,96
ffffffffc0202926:	00001517          	auipc	a0,0x1
ffffffffc020292a:	43a50513          	addi	a0,a0,1082 # ffffffffc0203d60 <etext+0xea6>
ffffffffc020292e:	8a3fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free_pages() == before - 2);
ffffffffc0202932:	00001697          	auipc	a3,0x1
ffffffffc0202936:	5ae68693          	addi	a3,a3,1454 # ffffffffc0203ee0 <etext+0x1026>
ffffffffc020293a:	00000617          	auipc	a2,0x0
ffffffffc020293e:	7f660613          	addi	a2,a2,2038 # ffffffffc0203130 <etext+0x276>
ffffffffc0202942:	06100593          	li	a1,97
ffffffffc0202946:	00001517          	auipc	a0,0x1
ffffffffc020294a:	41a50513          	addi	a0,a0,1050 # ffffffffc0203d60 <etext+0xea6>
ffffffffc020294e:	883fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(objects[0] == old);
ffffffffc0202952:	00001697          	auipc	a3,0x1
ffffffffc0202956:	5ae68693          	addi	a3,a3,1454 # ffffffffc0203f00 <etext+0x1046>
ffffffffc020295a:	00000617          	auipc	a2,0x0
ffffffffc020295e:	7d660613          	addi	a2,a2,2006 # ffffffffc0203130 <etext+0x276>
ffffffffc0202962:	06500593          	li	a1,101
ffffffffc0202966:	00001517          	auipc	a0,0x1
ffffffffc020296a:	3fa50513          	addi	a0,a0,1018 # ffffffffc0203d60 <etext+0xea6>
ffffffffc020296e:	863fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free_pages() == before - 2);
ffffffffc0202972:	00001697          	auipc	a3,0x1
ffffffffc0202976:	56e68693          	addi	a3,a3,1390 # ffffffffc0203ee0 <etext+0x1026>
ffffffffc020297a:	00000617          	auipc	a2,0x0
ffffffffc020297e:	7b660613          	addi	a2,a2,1974 # ffffffffc0203130 <etext+0x276>
ffffffffc0202982:	06600593          	li	a1,102
ffffffffc0202986:	00001517          	auipc	a0,0x1
ffffffffc020298a:	3da50513          	addi	a0,a0,986 # ffffffffc0203d60 <etext+0xea6>
ffffffffc020298e:	843fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free_pages() == before - 1);
ffffffffc0202992:	00001697          	auipc	a3,0x1
ffffffffc0202996:	58668693          	addi	a3,a3,1414 # ffffffffc0203f18 <etext+0x105e>
ffffffffc020299a:	00000617          	auipc	a2,0x0
ffffffffc020299e:	79660613          	addi	a2,a2,1942 # ffffffffc0203130 <etext+0x276>
ffffffffc02029a2:	06b00593          	li	a1,107
ffffffffc02029a6:	00001517          	auipc	a0,0x1
ffffffffc02029aa:	3ba50513          	addi	a0,a0,954 # ffffffffc0203d60 <etext+0xea6>
ffffffffc02029ae:	823fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(nr_free_pages() == before);
ffffffffc02029b2:	00001697          	auipc	a3,0x1
ffffffffc02029b6:	d9668693          	addi	a3,a3,-618 # ffffffffc0203748 <etext+0x88e>
ffffffffc02029ba:	00000617          	auipc	a2,0x0
ffffffffc02029be:	77660613          	addi	a2,a2,1910 # ffffffffc0203130 <etext+0x276>
ffffffffc02029c2:	07400593          	li	a1,116
ffffffffc02029c6:	00001517          	auipc	a0,0x1
ffffffffc02029ca:	39a50513          	addi	a0,a0,922 # ffffffffc0203d60 <etext+0xea6>
ffffffffc02029ce:	803fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(kmalloc(0) == NULL);
ffffffffc02029d2:	00001697          	auipc	a3,0x1
ffffffffc02029d6:	37668693          	addi	a3,a3,886 # ffffffffc0203d48 <etext+0xe8e>
ffffffffc02029da:	00000617          	auipc	a2,0x0
ffffffffc02029de:	75660613          	addi	a2,a2,1878 # ffffffffc0203130 <etext+0x276>
ffffffffc02029e2:	02900593          	li	a1,41
ffffffffc02029e6:	00001517          	auipc	a0,0x1
ffffffffc02029ea:	37a50513          	addi	a0,a0,890 # ffffffffc0203d60 <etext+0xea6>
ffffffffc02029ee:	fe2fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(kmalloc((size_t)-1 - 128) == NULL);
ffffffffc02029f2:	00001697          	auipc	a3,0x1
ffffffffc02029f6:	3a668693          	addi	a3,a3,934 # ffffffffc0203d98 <etext+0xede>
ffffffffc02029fa:	00000617          	auipc	a2,0x0
ffffffffc02029fe:	73660613          	addi	a2,a2,1846 # ffffffffc0203130 <etext+0x276>
ffffffffc0202a02:	02b00593          	li	a1,43
ffffffffc0202a06:	00001517          	auipc	a0,0x1
ffffffffc0202a0a:	35a50513          	addi	a0,a0,858 # ffffffffc0203d60 <etext+0xea6>
ffffffffc0202a0e:	fc2fd0ef          	jal	ffffffffc02001d0 <__panic>
    assert(kmalloc((size_t)-1) == NULL);
ffffffffc0202a12:	00001697          	auipc	a3,0x1
ffffffffc0202a16:	36668693          	addi	a3,a3,870 # ffffffffc0203d78 <etext+0xebe>
ffffffffc0202a1a:	00000617          	auipc	a2,0x0
ffffffffc0202a1e:	71660613          	addi	a2,a2,1814 # ffffffffc0203130 <etext+0x276>
ffffffffc0202a22:	02a00593          	li	a1,42
ffffffffc0202a26:	00001517          	auipc	a0,0x1
ffffffffc0202a2a:	33a50513          	addi	a0,a0,826 # ffffffffc0203d60 <etext+0xea6>
ffffffffc0202a2e:	fa2fd0ef          	jal	ffffffffc02001d0 <__panic>

ffffffffc0202a32 <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0202a32:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0202a34:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0202a38:	f022                	sd	s0,32(sp)
ffffffffc0202a3a:	ec26                	sd	s1,24(sp)
ffffffffc0202a3c:	e84a                	sd	s2,16(sp)
ffffffffc0202a3e:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0202a40:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0202a44:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
ffffffffc0202a46:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0202a4a:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0202a4e:	84aa                	mv	s1,a0
ffffffffc0202a50:	892e                	mv	s2,a1
    if (num >= base) {
ffffffffc0202a52:	03067d63          	bgeu	a2,a6,ffffffffc0202a8c <printnum+0x5a>
ffffffffc0202a56:	e44e                	sd	s3,8(sp)
ffffffffc0202a58:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0202a5a:	4785                	li	a5,1
ffffffffc0202a5c:	00e7d763          	bge	a5,a4,ffffffffc0202a6a <printnum+0x38>
            putch(padc, putdat);
ffffffffc0202a60:	85ca                	mv	a1,s2
ffffffffc0202a62:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc0202a64:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0202a66:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0202a68:	fc65                	bnez	s0,ffffffffc0202a60 <printnum+0x2e>
ffffffffc0202a6a:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0202a6c:	00001797          	auipc	a5,0x1
ffffffffc0202a70:	64478793          	addi	a5,a5,1604 # ffffffffc02040b0 <etext+0x11f6>
ffffffffc0202a74:	97d2                	add	a5,a5,s4
}
ffffffffc0202a76:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0202a78:	0007c503          	lbu	a0,0(a5)
}
ffffffffc0202a7c:	70a2                	ld	ra,40(sp)
ffffffffc0202a7e:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0202a80:	85ca                	mv	a1,s2
ffffffffc0202a82:	87a6                	mv	a5,s1
}
ffffffffc0202a84:	6942                	ld	s2,16(sp)
ffffffffc0202a86:	64e2                	ld	s1,24(sp)
ffffffffc0202a88:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0202a8a:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0202a8c:	03065633          	divu	a2,a2,a6
ffffffffc0202a90:	8722                	mv	a4,s0
ffffffffc0202a92:	fa1ff0ef          	jal	ffffffffc0202a32 <printnum>
ffffffffc0202a96:	bfd9                	j	ffffffffc0202a6c <printnum+0x3a>

ffffffffc0202a98 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0202a98:	7119                	addi	sp,sp,-128
ffffffffc0202a9a:	f4a6                	sd	s1,104(sp)
ffffffffc0202a9c:	f0ca                	sd	s2,96(sp)
ffffffffc0202a9e:	ecce                	sd	s3,88(sp)
ffffffffc0202aa0:	e8d2                	sd	s4,80(sp)
ffffffffc0202aa2:	e4d6                	sd	s5,72(sp)
ffffffffc0202aa4:	e0da                	sd	s6,64(sp)
ffffffffc0202aa6:	f862                	sd	s8,48(sp)
ffffffffc0202aa8:	fc86                	sd	ra,120(sp)
ffffffffc0202aaa:	f8a2                	sd	s0,112(sp)
ffffffffc0202aac:	fc5e                	sd	s7,56(sp)
ffffffffc0202aae:	f466                	sd	s9,40(sp)
ffffffffc0202ab0:	f06a                	sd	s10,32(sp)
ffffffffc0202ab2:	ec6e                	sd	s11,24(sp)
ffffffffc0202ab4:	84aa                	mv	s1,a0
ffffffffc0202ab6:	8c32                	mv	s8,a2
ffffffffc0202ab8:	8a36                	mv	s4,a3
ffffffffc0202aba:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0202abc:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202ac0:	05500b13          	li	s6,85
ffffffffc0202ac4:	00002a97          	auipc	s5,0x2
ffffffffc0202ac8:	884a8a93          	addi	s5,s5,-1916 # ffffffffc0204348 <sizes.6+0xf0>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0202acc:	000c4503          	lbu	a0,0(s8)
ffffffffc0202ad0:	001c0413          	addi	s0,s8,1
ffffffffc0202ad4:	01350a63          	beq	a0,s3,ffffffffc0202ae8 <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc0202ad8:	cd0d                	beqz	a0,ffffffffc0202b12 <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc0202ada:	85ca                	mv	a1,s2
ffffffffc0202adc:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0202ade:	00044503          	lbu	a0,0(s0)
ffffffffc0202ae2:	0405                	addi	s0,s0,1
ffffffffc0202ae4:	ff351ae3          	bne	a0,s3,ffffffffc0202ad8 <vprintfmt+0x40>
        width = precision = -1;
ffffffffc0202ae8:	5cfd                	li	s9,-1
ffffffffc0202aea:	8d66                	mv	s10,s9
        char padc = ' ';
ffffffffc0202aec:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc0202af0:	4b81                	li	s7,0
ffffffffc0202af2:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202af4:	00044683          	lbu	a3,0(s0)
ffffffffc0202af8:	00140c13          	addi	s8,s0,1
ffffffffc0202afc:	fdd6859b          	addiw	a1,a3,-35
ffffffffc0202b00:	0ff5f593          	zext.b	a1,a1
ffffffffc0202b04:	02bb6663          	bltu	s6,a1,ffffffffc0202b30 <vprintfmt+0x98>
ffffffffc0202b08:	058a                	slli	a1,a1,0x2
ffffffffc0202b0a:	95d6                	add	a1,a1,s5
ffffffffc0202b0c:	4198                	lw	a4,0(a1)
ffffffffc0202b0e:	9756                	add	a4,a4,s5
ffffffffc0202b10:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0202b12:	70e6                	ld	ra,120(sp)
ffffffffc0202b14:	7446                	ld	s0,112(sp)
ffffffffc0202b16:	74a6                	ld	s1,104(sp)
ffffffffc0202b18:	7906                	ld	s2,96(sp)
ffffffffc0202b1a:	69e6                	ld	s3,88(sp)
ffffffffc0202b1c:	6a46                	ld	s4,80(sp)
ffffffffc0202b1e:	6aa6                	ld	s5,72(sp)
ffffffffc0202b20:	6b06                	ld	s6,64(sp)
ffffffffc0202b22:	7be2                	ld	s7,56(sp)
ffffffffc0202b24:	7c42                	ld	s8,48(sp)
ffffffffc0202b26:	7ca2                	ld	s9,40(sp)
ffffffffc0202b28:	7d02                	ld	s10,32(sp)
ffffffffc0202b2a:	6de2                	ld	s11,24(sp)
ffffffffc0202b2c:	6109                	addi	sp,sp,128
ffffffffc0202b2e:	8082                	ret
            putch('%', putdat);
ffffffffc0202b30:	85ca                	mv	a1,s2
ffffffffc0202b32:	02500513          	li	a0,37
ffffffffc0202b36:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0202b38:	fff44783          	lbu	a5,-1(s0)
ffffffffc0202b3c:	02500713          	li	a4,37
ffffffffc0202b40:	8c22                	mv	s8,s0
ffffffffc0202b42:	f8e785e3          	beq	a5,a4,ffffffffc0202acc <vprintfmt+0x34>
ffffffffc0202b46:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0202b4a:	1c7d                	addi	s8,s8,-1
ffffffffc0202b4c:	fee79de3          	bne	a5,a4,ffffffffc0202b46 <vprintfmt+0xae>
ffffffffc0202b50:	bfb5                	j	ffffffffc0202acc <vprintfmt+0x34>
                ch = *fmt;
ffffffffc0202b52:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc0202b56:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
ffffffffc0202b58:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc0202b5c:	fd06071b          	addiw	a4,a2,-48
ffffffffc0202b60:	24e56a63          	bltu	a0,a4,ffffffffc0202db4 <vprintfmt+0x31c>
                ch = *fmt;
ffffffffc0202b64:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202b66:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
ffffffffc0202b68:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
ffffffffc0202b6c:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0202b70:	0197073b          	addw	a4,a4,s9
ffffffffc0202b74:	0017171b          	slliw	a4,a4,0x1
ffffffffc0202b78:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
ffffffffc0202b7a:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0202b7e:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0202b80:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc0202b84:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
ffffffffc0202b88:	feb570e3          	bgeu	a0,a1,ffffffffc0202b68 <vprintfmt+0xd0>
            if (width < 0)
ffffffffc0202b8c:	f60d54e3          	bgez	s10,ffffffffc0202af4 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc0202b90:	8d66                	mv	s10,s9
ffffffffc0202b92:	5cfd                	li	s9,-1
ffffffffc0202b94:	b785                	j	ffffffffc0202af4 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202b96:	8db6                	mv	s11,a3
ffffffffc0202b98:	8462                	mv	s0,s8
ffffffffc0202b9a:	bfa9                	j	ffffffffc0202af4 <vprintfmt+0x5c>
ffffffffc0202b9c:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc0202b9e:	4b85                	li	s7,1
            goto reswitch;
ffffffffc0202ba0:	bf91                	j	ffffffffc0202af4 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc0202ba2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0202ba4:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0202ba8:	00f74463          	blt	a4,a5,ffffffffc0202bb0 <vprintfmt+0x118>
    else if (lflag) {
ffffffffc0202bac:	1a078763          	beqz	a5,ffffffffc0202d5a <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
ffffffffc0202bb0:	000a3603          	ld	a2,0(s4)
ffffffffc0202bb4:	46c1                	li	a3,16
ffffffffc0202bb6:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0202bb8:	000d879b          	sext.w	a5,s11
ffffffffc0202bbc:	876a                	mv	a4,s10
ffffffffc0202bbe:	85ca                	mv	a1,s2
ffffffffc0202bc0:	8526                	mv	a0,s1
ffffffffc0202bc2:	e71ff0ef          	jal	ffffffffc0202a32 <printnum>
            break;
ffffffffc0202bc6:	b719                	j	ffffffffc0202acc <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0202bc8:	000a2503          	lw	a0,0(s4)
ffffffffc0202bcc:	85ca                	mv	a1,s2
ffffffffc0202bce:	0a21                	addi	s4,s4,8
ffffffffc0202bd0:	9482                	jalr	s1
            break;
ffffffffc0202bd2:	bded                	j	ffffffffc0202acc <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0202bd4:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0202bd6:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0202bda:	00f74463          	blt	a4,a5,ffffffffc0202be2 <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc0202bde:	16078963          	beqz	a5,ffffffffc0202d50 <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
ffffffffc0202be2:	000a3603          	ld	a2,0(s4)
ffffffffc0202be6:	46a9                	li	a3,10
ffffffffc0202be8:	8a2e                	mv	s4,a1
ffffffffc0202bea:	b7f9                	j	ffffffffc0202bb8 <vprintfmt+0x120>
            putch('0', putdat);
ffffffffc0202bec:	85ca                	mv	a1,s2
ffffffffc0202bee:	03000513          	li	a0,48
ffffffffc0202bf2:	9482                	jalr	s1
            putch('x', putdat);
ffffffffc0202bf4:	85ca                	mv	a1,s2
ffffffffc0202bf6:	07800513          	li	a0,120
ffffffffc0202bfa:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0202bfc:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc0202c00:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0202c02:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0202c04:	bf55                	j	ffffffffc0202bb8 <vprintfmt+0x120>
            putch(ch, putdat);
ffffffffc0202c06:	85ca                	mv	a1,s2
ffffffffc0202c08:	02500513          	li	a0,37
ffffffffc0202c0c:	9482                	jalr	s1
            break;
ffffffffc0202c0e:	bd7d                	j	ffffffffc0202acc <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc0202c10:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202c14:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc0202c16:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc0202c18:	bf95                	j	ffffffffc0202b8c <vprintfmt+0xf4>
    if (lflag >= 2) {
ffffffffc0202c1a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0202c1c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0202c20:	00f74463          	blt	a4,a5,ffffffffc0202c28 <vprintfmt+0x190>
    else if (lflag) {
ffffffffc0202c24:	12078163          	beqz	a5,ffffffffc0202d46 <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
ffffffffc0202c28:	000a3603          	ld	a2,0(s4)
ffffffffc0202c2c:	46a1                	li	a3,8
ffffffffc0202c2e:	8a2e                	mv	s4,a1
ffffffffc0202c30:	b761                	j	ffffffffc0202bb8 <vprintfmt+0x120>
            if (width < 0)
ffffffffc0202c32:	876a                	mv	a4,s10
ffffffffc0202c34:	000d5363          	bgez	s10,ffffffffc0202c3a <vprintfmt+0x1a2>
ffffffffc0202c38:	4701                	li	a4,0
ffffffffc0202c3a:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202c3e:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0202c40:	bd55                	j	ffffffffc0202af4 <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
ffffffffc0202c42:	000d841b          	sext.w	s0,s11
ffffffffc0202c46:	fd340793          	addi	a5,s0,-45
ffffffffc0202c4a:	00f037b3          	snez	a5,a5
ffffffffc0202c4e:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0202c52:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
ffffffffc0202c56:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0202c58:	008a0793          	addi	a5,s4,8
ffffffffc0202c5c:	e43e                	sd	a5,8(sp)
ffffffffc0202c5e:	100d8c63          	beqz	s11,ffffffffc0202d76 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc0202c62:	12071363          	bnez	a4,ffffffffc0202d88 <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0202c66:	000dc783          	lbu	a5,0(s11)
ffffffffc0202c6a:	0007851b          	sext.w	a0,a5
ffffffffc0202c6e:	c78d                	beqz	a5,ffffffffc0202c98 <vprintfmt+0x200>
ffffffffc0202c70:	0d85                	addi	s11,s11,1
ffffffffc0202c72:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0202c74:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0202c78:	000cc563          	bltz	s9,ffffffffc0202c82 <vprintfmt+0x1ea>
ffffffffc0202c7c:	3cfd                	addiw	s9,s9,-1
ffffffffc0202c7e:	008c8d63          	beq	s9,s0,ffffffffc0202c98 <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0202c82:	020b9663          	bnez	s7,ffffffffc0202cae <vprintfmt+0x216>
                    putch(ch, putdat);
ffffffffc0202c86:	85ca                	mv	a1,s2
ffffffffc0202c88:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0202c8a:	000dc783          	lbu	a5,0(s11)
ffffffffc0202c8e:	0d85                	addi	s11,s11,1
ffffffffc0202c90:	3d7d                	addiw	s10,s10,-1
ffffffffc0202c92:	0007851b          	sext.w	a0,a5
ffffffffc0202c96:	f3ed                	bnez	a5,ffffffffc0202c78 <vprintfmt+0x1e0>
            for (; width > 0; width --) {
ffffffffc0202c98:	01a05963          	blez	s10,ffffffffc0202caa <vprintfmt+0x212>
                putch(' ', putdat);
ffffffffc0202c9c:	85ca                	mv	a1,s2
ffffffffc0202c9e:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc0202ca2:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
ffffffffc0202ca4:	9482                	jalr	s1
            for (; width > 0; width --) {
ffffffffc0202ca6:	fe0d1be3          	bnez	s10,ffffffffc0202c9c <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0202caa:	6a22                	ld	s4,8(sp)
ffffffffc0202cac:	b505                	j	ffffffffc0202acc <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0202cae:	3781                	addiw	a5,a5,-32
ffffffffc0202cb0:	fcfa7be3          	bgeu	s4,a5,ffffffffc0202c86 <vprintfmt+0x1ee>
                    putch('?', putdat);
ffffffffc0202cb4:	03f00513          	li	a0,63
ffffffffc0202cb8:	85ca                	mv	a1,s2
ffffffffc0202cba:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0202cbc:	000dc783          	lbu	a5,0(s11)
ffffffffc0202cc0:	0d85                	addi	s11,s11,1
ffffffffc0202cc2:	3d7d                	addiw	s10,s10,-1
ffffffffc0202cc4:	0007851b          	sext.w	a0,a5
ffffffffc0202cc8:	dbe1                	beqz	a5,ffffffffc0202c98 <vprintfmt+0x200>
ffffffffc0202cca:	fa0cd9e3          	bgez	s9,ffffffffc0202c7c <vprintfmt+0x1e4>
ffffffffc0202cce:	b7c5                	j	ffffffffc0202cae <vprintfmt+0x216>
            if (err < 0) {
ffffffffc0202cd0:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0202cd4:	4619                	li	a2,6
            err = va_arg(ap, int);
ffffffffc0202cd6:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0202cd8:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc0202cdc:	8fb9                	xor	a5,a5,a4
ffffffffc0202cde:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0202ce2:	02d64563          	blt	a2,a3,ffffffffc0202d0c <vprintfmt+0x274>
ffffffffc0202ce6:	00001797          	auipc	a5,0x1
ffffffffc0202cea:	7ba78793          	addi	a5,a5,1978 # ffffffffc02044a0 <error_string>
ffffffffc0202cee:	00369713          	slli	a4,a3,0x3
ffffffffc0202cf2:	97ba                	add	a5,a5,a4
ffffffffc0202cf4:	639c                	ld	a5,0(a5)
ffffffffc0202cf6:	cb99                	beqz	a5,ffffffffc0202d0c <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
ffffffffc0202cf8:	86be                	mv	a3,a5
ffffffffc0202cfa:	00001617          	auipc	a2,0x1
ffffffffc0202cfe:	3e660613          	addi	a2,a2,998 # ffffffffc02040e0 <etext+0x1226>
ffffffffc0202d02:	85ca                	mv	a1,s2
ffffffffc0202d04:	8526                	mv	a0,s1
ffffffffc0202d06:	0d8000ef          	jal	ffffffffc0202dde <printfmt>
ffffffffc0202d0a:	b3c9                	j	ffffffffc0202acc <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0202d0c:	00001617          	auipc	a2,0x1
ffffffffc0202d10:	3c460613          	addi	a2,a2,964 # ffffffffc02040d0 <etext+0x1216>
ffffffffc0202d14:	85ca                	mv	a1,s2
ffffffffc0202d16:	8526                	mv	a0,s1
ffffffffc0202d18:	0c6000ef          	jal	ffffffffc0202dde <printfmt>
ffffffffc0202d1c:	bb45                	j	ffffffffc0202acc <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0202d1e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0202d20:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc0202d24:	00f74363          	blt	a4,a5,ffffffffc0202d2a <vprintfmt+0x292>
    else if (lflag) {
ffffffffc0202d28:	cf81                	beqz	a5,ffffffffc0202d40 <vprintfmt+0x2a8>
        return va_arg(*ap, long);
ffffffffc0202d2a:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0202d2e:	02044b63          	bltz	s0,ffffffffc0202d64 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc0202d32:	8622                	mv	a2,s0
ffffffffc0202d34:	8a5e                	mv	s4,s7
ffffffffc0202d36:	46a9                	li	a3,10
ffffffffc0202d38:	b541                	j	ffffffffc0202bb8 <vprintfmt+0x120>
            lflag ++;
ffffffffc0202d3a:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202d3c:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0202d3e:	bb5d                	j	ffffffffc0202af4 <vprintfmt+0x5c>
        return va_arg(*ap, int);
ffffffffc0202d40:	000a2403          	lw	s0,0(s4)
ffffffffc0202d44:	b7ed                	j	ffffffffc0202d2e <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
ffffffffc0202d46:	000a6603          	lwu	a2,0(s4)
ffffffffc0202d4a:	46a1                	li	a3,8
ffffffffc0202d4c:	8a2e                	mv	s4,a1
ffffffffc0202d4e:	b5ad                	j	ffffffffc0202bb8 <vprintfmt+0x120>
ffffffffc0202d50:	000a6603          	lwu	a2,0(s4)
ffffffffc0202d54:	46a9                	li	a3,10
ffffffffc0202d56:	8a2e                	mv	s4,a1
ffffffffc0202d58:	b585                	j	ffffffffc0202bb8 <vprintfmt+0x120>
ffffffffc0202d5a:	000a6603          	lwu	a2,0(s4)
ffffffffc0202d5e:	46c1                	li	a3,16
ffffffffc0202d60:	8a2e                	mv	s4,a1
ffffffffc0202d62:	bd99                	j	ffffffffc0202bb8 <vprintfmt+0x120>
                putch('-', putdat);
ffffffffc0202d64:	85ca                	mv	a1,s2
ffffffffc0202d66:	02d00513          	li	a0,45
ffffffffc0202d6a:	9482                	jalr	s1
                num = -(long long)num;
ffffffffc0202d6c:	40800633          	neg	a2,s0
ffffffffc0202d70:	8a5e                	mv	s4,s7
ffffffffc0202d72:	46a9                	li	a3,10
ffffffffc0202d74:	b591                	j	ffffffffc0202bb8 <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
ffffffffc0202d76:	e329                	bnez	a4,ffffffffc0202db8 <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0202d78:	02800793          	li	a5,40
ffffffffc0202d7c:	853e                	mv	a0,a5
ffffffffc0202d7e:	00001d97          	auipc	s11,0x1
ffffffffc0202d82:	34bd8d93          	addi	s11,s11,843 # ffffffffc02040c9 <etext+0x120f>
ffffffffc0202d86:	b5f5                	j	ffffffffc0202c72 <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0202d88:	85e6                	mv	a1,s9
ffffffffc0202d8a:	856e                	mv	a0,s11
ffffffffc0202d8c:	0a4000ef          	jal	ffffffffc0202e30 <strnlen>
ffffffffc0202d90:	40ad0d3b          	subw	s10,s10,a0
ffffffffc0202d94:	01a05863          	blez	s10,ffffffffc0202da4 <vprintfmt+0x30c>
                    putch(padc, putdat);
ffffffffc0202d98:	85ca                	mv	a1,s2
ffffffffc0202d9a:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0202d9c:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
ffffffffc0202d9e:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0202da0:	fe0d1ce3          	bnez	s10,ffffffffc0202d98 <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0202da4:	000dc783          	lbu	a5,0(s11)
ffffffffc0202da8:	0007851b          	sext.w	a0,a5
ffffffffc0202dac:	ec0792e3          	bnez	a5,ffffffffc0202c70 <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0202db0:	6a22                	ld	s4,8(sp)
ffffffffc0202db2:	bb29                	j	ffffffffc0202acc <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202db4:	8462                	mv	s0,s8
ffffffffc0202db6:	bbd9                	j	ffffffffc0202b8c <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0202db8:	85e6                	mv	a1,s9
ffffffffc0202dba:	00001517          	auipc	a0,0x1
ffffffffc0202dbe:	30e50513          	addi	a0,a0,782 # ffffffffc02040c8 <etext+0x120e>
ffffffffc0202dc2:	06e000ef          	jal	ffffffffc0202e30 <strnlen>
ffffffffc0202dc6:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0202dca:	02800793          	li	a5,40
                p = "(null)";
ffffffffc0202dce:	00001d97          	auipc	s11,0x1
ffffffffc0202dd2:	2fad8d93          	addi	s11,s11,762 # ffffffffc02040c8 <etext+0x120e>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0202dd6:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0202dd8:	fda040e3          	bgtz	s10,ffffffffc0202d98 <vprintfmt+0x300>
ffffffffc0202ddc:	bd51                	j	ffffffffc0202c70 <vprintfmt+0x1d8>

ffffffffc0202dde <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0202dde:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0202de0:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0202de4:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0202de6:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0202de8:	ec06                	sd	ra,24(sp)
ffffffffc0202dea:	f83a                	sd	a4,48(sp)
ffffffffc0202dec:	fc3e                	sd	a5,56(sp)
ffffffffc0202dee:	e0c2                	sd	a6,64(sp)
ffffffffc0202df0:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0202df2:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0202df4:	ca5ff0ef          	jal	ffffffffc0202a98 <vprintfmt>
}
ffffffffc0202df8:	60e2                	ld	ra,24(sp)
ffffffffc0202dfa:	6161                	addi	sp,sp,80
ffffffffc0202dfc:	8082                	ret

ffffffffc0202dfe <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0202dfe:	00005717          	auipc	a4,0x5
ffffffffc0202e02:	21273703          	ld	a4,530(a4) # ffffffffc0208010 <SBI_CONSOLE_PUTCHAR>
ffffffffc0202e06:	4781                	li	a5,0
ffffffffc0202e08:	88ba                	mv	a7,a4
ffffffffc0202e0a:	852a                	mv	a0,a0
ffffffffc0202e0c:	85be                	mv	a1,a5
ffffffffc0202e0e:	863e                	mv	a2,a5
ffffffffc0202e10:	00000073          	ecall
ffffffffc0202e14:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0202e16:	8082                	ret

ffffffffc0202e18 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0202e18:	00054783          	lbu	a5,0(a0)
ffffffffc0202e1c:	cb81                	beqz	a5,ffffffffc0202e2c <strlen+0x14>
    size_t cnt = 0;
ffffffffc0202e1e:	4781                	li	a5,0
        cnt ++;
ffffffffc0202e20:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc0202e22:	00f50733          	add	a4,a0,a5
ffffffffc0202e26:	00074703          	lbu	a4,0(a4)
ffffffffc0202e2a:	fb7d                	bnez	a4,ffffffffc0202e20 <strlen+0x8>
    }
    return cnt;
}
ffffffffc0202e2c:	853e                	mv	a0,a5
ffffffffc0202e2e:	8082                	ret

ffffffffc0202e30 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0202e30:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0202e32:	e589                	bnez	a1,ffffffffc0202e3c <strnlen+0xc>
ffffffffc0202e34:	a811                	j	ffffffffc0202e48 <strnlen+0x18>
        cnt ++;
ffffffffc0202e36:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0202e38:	00f58863          	beq	a1,a5,ffffffffc0202e48 <strnlen+0x18>
ffffffffc0202e3c:	00f50733          	add	a4,a0,a5
ffffffffc0202e40:	00074703          	lbu	a4,0(a4)
ffffffffc0202e44:	fb6d                	bnez	a4,ffffffffc0202e36 <strnlen+0x6>
ffffffffc0202e46:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0202e48:	852e                	mv	a0,a1
ffffffffc0202e4a:	8082                	ret

ffffffffc0202e4c <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0202e4c:	00054783          	lbu	a5,0(a0)
ffffffffc0202e50:	e791                	bnez	a5,ffffffffc0202e5c <strcmp+0x10>
ffffffffc0202e52:	a01d                	j	ffffffffc0202e78 <strcmp+0x2c>
ffffffffc0202e54:	00054783          	lbu	a5,0(a0)
ffffffffc0202e58:	cb99                	beqz	a5,ffffffffc0202e6e <strcmp+0x22>
ffffffffc0202e5a:	0585                	addi	a1,a1,1
ffffffffc0202e5c:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc0202e60:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0202e62:	fef709e3          	beq	a4,a5,ffffffffc0202e54 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0202e66:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0202e6a:	9d19                	subw	a0,a0,a4
ffffffffc0202e6c:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0202e6e:	0015c703          	lbu	a4,1(a1)
ffffffffc0202e72:	4501                	li	a0,0
}
ffffffffc0202e74:	9d19                	subw	a0,a0,a4
ffffffffc0202e76:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0202e78:	0005c703          	lbu	a4,0(a1)
ffffffffc0202e7c:	4501                	li	a0,0
ffffffffc0202e7e:	b7f5                	j	ffffffffc0202e6a <strcmp+0x1e>

ffffffffc0202e80 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0202e80:	ce01                	beqz	a2,ffffffffc0202e98 <strncmp+0x18>
ffffffffc0202e82:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0202e86:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0202e88:	cb91                	beqz	a5,ffffffffc0202e9c <strncmp+0x1c>
ffffffffc0202e8a:	0005c703          	lbu	a4,0(a1)
ffffffffc0202e8e:	00f71763          	bne	a4,a5,ffffffffc0202e9c <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc0202e92:	0505                	addi	a0,a0,1
ffffffffc0202e94:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0202e96:	f675                	bnez	a2,ffffffffc0202e82 <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0202e98:	4501                	li	a0,0
ffffffffc0202e9a:	8082                	ret
ffffffffc0202e9c:	00054503          	lbu	a0,0(a0)
ffffffffc0202ea0:	0005c783          	lbu	a5,0(a1)
ffffffffc0202ea4:	9d1d                	subw	a0,a0,a5
}
ffffffffc0202ea6:	8082                	ret

ffffffffc0202ea8 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0202ea8:	ca01                	beqz	a2,ffffffffc0202eb8 <memset+0x10>
ffffffffc0202eaa:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0202eac:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0202eae:	0785                	addi	a5,a5,1
ffffffffc0202eb0:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0202eb4:	fef61de3          	bne	a2,a5,ffffffffc0202eae <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0202eb8:	8082                	ret
