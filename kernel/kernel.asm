
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	90013103          	ld	sp,-1792(sp) # 80008900 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	90e70713          	addi	a4,a4,-1778 # 80008960 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	d2c78793          	addi	a5,a5,-724 # 80005d90 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc92f>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	e0878793          	addi	a5,a5,-504 # 80000eb6 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	3d6080e7          	jalr	982(ra) # 80002502 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	794080e7          	jalr	1940(ra) # 800008d0 <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	91450513          	addi	a0,a0,-1772 # 80010aa0 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a78080e7          	jalr	-1416(ra) # 80000c0c <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	90448493          	addi	s1,s1,-1788 # 80010aa0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	99290913          	addi	s2,s2,-1646 # 80010b38 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405b63          	blez	s4,8000022a <consoleread+0xc6>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71763          	bne	a4,a5,800001ee <consoleread+0x8a>
      if(killed(myproc())){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	824080e7          	jalr	-2012(ra) # 800019e8 <myproc>
    800001cc:	00002097          	auipc	ra,0x2
    800001d0:	180080e7          	jalr	384(ra) # 8000234c <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	eca080e7          	jalr	-310(ra) # 800020a4 <sleep>
    while(cons.r == cons.w){
    800001e2:	0984a783          	lw	a5,152(s1)
    800001e6:	09c4a703          	lw	a4,156(s1)
    800001ea:	fcf70de3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ee:	0017871b          	addiw	a4,a5,1
    800001f2:	08e4ac23          	sw	a4,152(s1)
    800001f6:	07f7f713          	andi	a4,a5,127
    800001fa:	9726                	add	a4,a4,s1
    800001fc:	01874703          	lbu	a4,24(a4)
    80000200:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000204:	079c0663          	beq	s8,s9,80000270 <consoleread+0x10c>
    cbuf = c;
    80000208:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f8f40613          	addi	a2,s0,-113
    80000212:	85d6                	mv	a1,s5
    80000214:	855a                	mv	a0,s6
    80000216:	00002097          	auipc	ra,0x2
    8000021a:	296080e7          	jalr	662(ra) # 800024ac <either_copyout>
    8000021e:	01a50663          	beq	a0,s10,8000022a <consoleread+0xc6>
    dst++;
    80000222:	0a85                	addi	s5,s5,1
    --n;
    80000224:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000226:	f9bc17e3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022a:	00011517          	auipc	a0,0x11
    8000022e:	87650513          	addi	a0,a0,-1930 # 80010aa0 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a8e080e7          	jalr	-1394(ra) # 80000cc0 <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	86050513          	addi	a0,a0,-1952 # 80010aa0 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	a78080e7          	jalr	-1416(ra) # 80000cc0 <release>
        return -1;
    80000250:	557d                	li	a0,-1
}
    80000252:	70e6                	ld	ra,120(sp)
    80000254:	7446                	ld	s0,112(sp)
    80000256:	74a6                	ld	s1,104(sp)
    80000258:	7906                	ld	s2,96(sp)
    8000025a:	69e6                	ld	s3,88(sp)
    8000025c:	6a46                	ld	s4,80(sp)
    8000025e:	6aa6                	ld	s5,72(sp)
    80000260:	6b06                	ld	s6,64(sp)
    80000262:	7be2                	ld	s7,56(sp)
    80000264:	7c42                	ld	s8,48(sp)
    80000266:	7ca2                	ld	s9,40(sp)
    80000268:	7d02                	ld	s10,32(sp)
    8000026a:	6de2                	ld	s11,24(sp)
    8000026c:	6109                	addi	sp,sp,128
    8000026e:	8082                	ret
      if(n < target){
    80000270:	000a071b          	sext.w	a4,s4
    80000274:	fb777be3          	bgeu	a4,s7,8000022a <consoleread+0xc6>
        cons.r--;
    80000278:	00011717          	auipc	a4,0x11
    8000027c:	8cf72023          	sw	a5,-1856(a4) # 80010b38 <cons+0x98>
    80000280:	b76d                	j	8000022a <consoleread+0xc6>

0000000080000282 <consputc>:
{
    80000282:	1141                	addi	sp,sp,-16
    80000284:	e406                	sd	ra,8(sp)
    80000286:	e022                	sd	s0,0(sp)
    80000288:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028a:	10000793          	li	a5,256
    8000028e:	00f50a63          	beq	a0,a5,800002a2 <consputc+0x20>
    uartputc_sync(c);
    80000292:	00000097          	auipc	ra,0x0
    80000296:	564080e7          	jalr	1380(ra) # 800007f6 <uartputc_sync>
}
    8000029a:	60a2                	ld	ra,8(sp)
    8000029c:	6402                	ld	s0,0(sp)
    8000029e:	0141                	addi	sp,sp,16
    800002a0:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a2:	4521                	li	a0,8
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	552080e7          	jalr	1362(ra) # 800007f6 <uartputc_sync>
    800002ac:	02000513          	li	a0,32
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	546080e7          	jalr	1350(ra) # 800007f6 <uartputc_sync>
    800002b8:	4521                	li	a0,8
    800002ba:	00000097          	auipc	ra,0x0
    800002be:	53c080e7          	jalr	1340(ra) # 800007f6 <uartputc_sync>
    800002c2:	bfe1                	j	8000029a <consputc+0x18>

00000000800002c4 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c4:	1101                	addi	sp,sp,-32
    800002c6:	ec06                	sd	ra,24(sp)
    800002c8:	e822                	sd	s0,16(sp)
    800002ca:	e426                	sd	s1,8(sp)
    800002cc:	e04a                	sd	s2,0(sp)
    800002ce:	1000                	addi	s0,sp,32
    800002d0:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d2:	00010517          	auipc	a0,0x10
    800002d6:	7ce50513          	addi	a0,a0,1998 # 80010aa0 <cons>
    800002da:	00001097          	auipc	ra,0x1
    800002de:	932080e7          	jalr	-1742(ra) # 80000c0c <acquire>

  switch(c){
    800002e2:	47d5                	li	a5,21
    800002e4:	0af48663          	beq	s1,a5,80000390 <consoleintr+0xcc>
    800002e8:	0297ca63          	blt	a5,s1,8000031c <consoleintr+0x58>
    800002ec:	47a1                	li	a5,8
    800002ee:	0ef48763          	beq	s1,a5,800003dc <consoleintr+0x118>
    800002f2:	47c1                	li	a5,16
    800002f4:	10f49a63          	bne	s1,a5,80000408 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f8:	00002097          	auipc	ra,0x2
    800002fc:	260080e7          	jalr	608(ra) # 80002558 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00010517          	auipc	a0,0x10
    80000304:	7a050513          	addi	a0,a0,1952 # 80010aa0 <cons>
    80000308:	00001097          	auipc	ra,0x1
    8000030c:	9b8080e7          	jalr	-1608(ra) # 80000cc0 <release>
}
    80000310:	60e2                	ld	ra,24(sp)
    80000312:	6442                	ld	s0,16(sp)
    80000314:	64a2                	ld	s1,8(sp)
    80000316:	6902                	ld	s2,0(sp)
    80000318:	6105                	addi	sp,sp,32
    8000031a:	8082                	ret
  switch(c){
    8000031c:	07f00793          	li	a5,127
    80000320:	0af48e63          	beq	s1,a5,800003dc <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000324:	00010717          	auipc	a4,0x10
    80000328:	77c70713          	addi	a4,a4,1916 # 80010aa0 <cons>
    8000032c:	0a072783          	lw	a5,160(a4)
    80000330:	09872703          	lw	a4,152(a4)
    80000334:	9f99                	subw	a5,a5,a4
    80000336:	07f00713          	li	a4,127
    8000033a:	fcf763e3          	bltu	a4,a5,80000300 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033e:	47b5                	li	a5,13
    80000340:	0cf48763          	beq	s1,a5,8000040e <consoleintr+0x14a>
      consputc(c);
    80000344:	8526                	mv	a0,s1
    80000346:	00000097          	auipc	ra,0x0
    8000034a:	f3c080e7          	jalr	-196(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000034e:	00010797          	auipc	a5,0x10
    80000352:	75278793          	addi	a5,a5,1874 # 80010aa0 <cons>
    80000356:	0a07a683          	lw	a3,160(a5)
    8000035a:	0016871b          	addiw	a4,a3,1
    8000035e:	0007061b          	sext.w	a2,a4
    80000362:	0ae7a023          	sw	a4,160(a5)
    80000366:	07f6f693          	andi	a3,a3,127
    8000036a:	97b6                	add	a5,a5,a3
    8000036c:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000370:	47a9                	li	a5,10
    80000372:	0cf48563          	beq	s1,a5,8000043c <consoleintr+0x178>
    80000376:	4791                	li	a5,4
    80000378:	0cf48263          	beq	s1,a5,8000043c <consoleintr+0x178>
    8000037c:	00010797          	auipc	a5,0x10
    80000380:	7bc7a783          	lw	a5,1980(a5) # 80010b38 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00010717          	auipc	a4,0x10
    80000394:	71070713          	addi	a4,a4,1808 # 80010aa0 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00010497          	auipc	s1,0x10
    800003a4:	70048493          	addi	s1,s1,1792 # 80010aa0 <cons>
    while(cons.e != cons.w &&
    800003a8:	4929                	li	s2,10
    800003aa:	f4f70be3          	beq	a4,a5,80000300 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003ae:	37fd                	addiw	a5,a5,-1
    800003b0:	07f7f713          	andi	a4,a5,127
    800003b4:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b6:	01874703          	lbu	a4,24(a4)
    800003ba:	f52703e3          	beq	a4,s2,80000300 <consoleintr+0x3c>
      cons.e--;
    800003be:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c2:	10000513          	li	a0,256
    800003c6:	00000097          	auipc	ra,0x0
    800003ca:	ebc080e7          	jalr	-324(ra) # 80000282 <consputc>
    while(cons.e != cons.w &&
    800003ce:	0a04a783          	lw	a5,160(s1)
    800003d2:	09c4a703          	lw	a4,156(s1)
    800003d6:	fcf71ce3          	bne	a4,a5,800003ae <consoleintr+0xea>
    800003da:	b71d                	j	80000300 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003dc:	00010717          	auipc	a4,0x10
    800003e0:	6c470713          	addi	a4,a4,1732 # 80010aa0 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00010717          	auipc	a4,0x10
    800003f6:	74f72723          	sw	a5,1870(a4) # 80010b40 <cons+0xa0>
      consputc(BACKSPACE);
    800003fa:	10000513          	li	a0,256
    800003fe:	00000097          	auipc	ra,0x0
    80000402:	e84080e7          	jalr	-380(ra) # 80000282 <consputc>
    80000406:	bded                	j	80000300 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000408:	ee048ce3          	beqz	s1,80000300 <consoleintr+0x3c>
    8000040c:	bf21                	j	80000324 <consoleintr+0x60>
      consputc(c);
    8000040e:	4529                	li	a0,10
    80000410:	00000097          	auipc	ra,0x0
    80000414:	e72080e7          	jalr	-398(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000418:	00010797          	auipc	a5,0x10
    8000041c:	68878793          	addi	a5,a5,1672 # 80010aa0 <cons>
    80000420:	0a07a703          	lw	a4,160(a5)
    80000424:	0017069b          	addiw	a3,a4,1
    80000428:	0006861b          	sext.w	a2,a3
    8000042c:	0ad7a023          	sw	a3,160(a5)
    80000430:	07f77713          	andi	a4,a4,127
    80000434:	97ba                	add	a5,a5,a4
    80000436:	4729                	li	a4,10
    80000438:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043c:	00010797          	auipc	a5,0x10
    80000440:	70c7a023          	sw	a2,1792(a5) # 80010b3c <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00010517          	auipc	a0,0x10
    80000448:	6f450513          	addi	a0,a0,1780 # 80010b38 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	cbc080e7          	jalr	-836(ra) # 80002108 <wakeup>
    80000454:	b575                	j	80000300 <consoleintr+0x3c>

0000000080000456 <consoleinit>:

void
consoleinit(void)
{
    80000456:	1141                	addi	sp,sp,-16
    80000458:	e406                	sd	ra,8(sp)
    8000045a:	e022                	sd	s0,0(sp)
    8000045c:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045e:	00008597          	auipc	a1,0x8
    80000462:	bb258593          	addi	a1,a1,-1102 # 80008010 <etext+0x10>
    80000466:	00010517          	auipc	a0,0x10
    8000046a:	63a50513          	addi	a0,a0,1594 # 80010aa0 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	70e080e7          	jalr	1806(ra) # 80000b7c <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00021797          	auipc	a5,0x21
    80000482:	8ba78793          	addi	a5,a5,-1862 # 80020d38 <devsw>
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	cde70713          	addi	a4,a4,-802 # 80000164 <consoleread>
    8000048e:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000490:	00000717          	auipc	a4,0x0
    80000494:	c7270713          	addi	a4,a4,-910 # 80000102 <consolewrite>
    80000498:	ef98                	sd	a4,24(a5)
}
    8000049a:	60a2                	ld	ra,8(sp)
    8000049c:	6402                	ld	s0,0(sp)
    8000049e:	0141                	addi	sp,sp,16
    800004a0:	8082                	ret

00000000800004a2 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a2:	7179                	addi	sp,sp,-48
    800004a4:	f406                	sd	ra,40(sp)
    800004a6:	f022                	sd	s0,32(sp)
    800004a8:	ec26                	sd	s1,24(sp)
    800004aa:	e84a                	sd	s2,16(sp)
    800004ac:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ae:	c219                	beqz	a2,800004b4 <printint+0x12>
    800004b0:	08054663          	bltz	a0,8000053c <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b4:	2501                	sext.w	a0,a0
    800004b6:	4881                	li	a7,0
    800004b8:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004bc:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004be:	2581                	sext.w	a1,a1
    800004c0:	00008617          	auipc	a2,0x8
    800004c4:	b8060613          	addi	a2,a2,-1152 # 80008040 <digits>
    800004c8:	883a                	mv	a6,a4
    800004ca:	2705                	addiw	a4,a4,1
    800004cc:	02b577bb          	remuw	a5,a0,a1
    800004d0:	1782                	slli	a5,a5,0x20
    800004d2:	9381                	srli	a5,a5,0x20
    800004d4:	97b2                	add	a5,a5,a2
    800004d6:	0007c783          	lbu	a5,0(a5)
    800004da:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004de:	0005079b          	sext.w	a5,a0
    800004e2:	02b5553b          	divuw	a0,a0,a1
    800004e6:	0685                	addi	a3,a3,1
    800004e8:	feb7f0e3          	bgeu	a5,a1,800004c8 <printint+0x26>

  if(sign)
    800004ec:	00088b63          	beqz	a7,80000502 <printint+0x60>
    buf[i++] = '-';
    800004f0:	fe040793          	addi	a5,s0,-32
    800004f4:	973e                	add	a4,a4,a5
    800004f6:	02d00793          	li	a5,45
    800004fa:	fef70823          	sb	a5,-16(a4)
    800004fe:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000502:	02e05763          	blez	a4,80000530 <printint+0x8e>
    80000506:	fd040793          	addi	a5,s0,-48
    8000050a:	00e784b3          	add	s1,a5,a4
    8000050e:	fff78913          	addi	s2,a5,-1
    80000512:	993a                	add	s2,s2,a4
    80000514:	377d                	addiw	a4,a4,-1
    80000516:	1702                	slli	a4,a4,0x20
    80000518:	9301                	srli	a4,a4,0x20
    8000051a:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051e:	fff4c503          	lbu	a0,-1(s1)
    80000522:	00000097          	auipc	ra,0x0
    80000526:	d60080e7          	jalr	-672(ra) # 80000282 <consputc>
  while(--i >= 0)
    8000052a:	14fd                	addi	s1,s1,-1
    8000052c:	ff2499e3          	bne	s1,s2,8000051e <printint+0x7c>
}
    80000530:	70a2                	ld	ra,40(sp)
    80000532:	7402                	ld	s0,32(sp)
    80000534:	64e2                	ld	s1,24(sp)
    80000536:	6942                	ld	s2,16(sp)
    80000538:	6145                	addi	sp,sp,48
    8000053a:	8082                	ret
    x = -xx;
    8000053c:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000540:	4885                	li	a7,1
    x = -xx;
    80000542:	bf9d                	j	800004b8 <printint+0x16>

0000000080000544 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000544:	1101                	addi	sp,sp,-32
    80000546:	ec06                	sd	ra,24(sp)
    80000548:	e822                	sd	s0,16(sp)
    8000054a:	e426                	sd	s1,8(sp)
    8000054c:	1000                	addi	s0,sp,32
    8000054e:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000550:	00010797          	auipc	a5,0x10
    80000554:	6007a823          	sw	zero,1552(a5) # 80010b60 <pr+0x18>
  printf("panic: ");
    80000558:	00008517          	auipc	a0,0x8
    8000055c:	ac050513          	addi	a0,a0,-1344 # 80008018 <etext+0x18>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	02e080e7          	jalr	46(ra) # 8000058e <printf>
  printf(s);
    80000568:	8526                	mv	a0,s1
    8000056a:	00000097          	auipc	ra,0x0
    8000056e:	024080e7          	jalr	36(ra) # 8000058e <printf>
  printf("\n");
    80000572:	00008517          	auipc	a0,0x8
    80000576:	b5650513          	addi	a0,a0,-1194 # 800080c8 <digits+0x88>
    8000057a:	00000097          	auipc	ra,0x0
    8000057e:	014080e7          	jalr	20(ra) # 8000058e <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000582:	4785                	li	a5,1
    80000584:	00008717          	auipc	a4,0x8
    80000588:	38f72e23          	sw	a5,924(a4) # 80008920 <panicked>
  for(;;)
    8000058c:	a001                	j	8000058c <panic+0x48>

000000008000058e <printf>:
{
    8000058e:	7131                	addi	sp,sp,-192
    80000590:	fc86                	sd	ra,120(sp)
    80000592:	f8a2                	sd	s0,112(sp)
    80000594:	f4a6                	sd	s1,104(sp)
    80000596:	f0ca                	sd	s2,96(sp)
    80000598:	ecce                	sd	s3,88(sp)
    8000059a:	e8d2                	sd	s4,80(sp)
    8000059c:	e4d6                	sd	s5,72(sp)
    8000059e:	e0da                	sd	s6,64(sp)
    800005a0:	fc5e                	sd	s7,56(sp)
    800005a2:	f862                	sd	s8,48(sp)
    800005a4:	f466                	sd	s9,40(sp)
    800005a6:	f06a                	sd	s10,32(sp)
    800005a8:	ec6e                	sd	s11,24(sp)
    800005aa:	0100                	addi	s0,sp,128
    800005ac:	8a2a                	mv	s4,a0
    800005ae:	e40c                	sd	a1,8(s0)
    800005b0:	e810                	sd	a2,16(s0)
    800005b2:	ec14                	sd	a3,24(s0)
    800005b4:	f018                	sd	a4,32(s0)
    800005b6:	f41c                	sd	a5,40(s0)
    800005b8:	03043823          	sd	a6,48(s0)
    800005bc:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c0:	00010d97          	auipc	s11,0x10
    800005c4:	5a0dad83          	lw	s11,1440(s11) # 80010b60 <pr+0x18>
  if(locking)
    800005c8:	020d9b63          	bnez	s11,800005fe <printf+0x70>
  if (fmt == 0)
    800005cc:	040a0263          	beqz	s4,80000610 <printf+0x82>
  va_start(ap, fmt);
    800005d0:	00840793          	addi	a5,s0,8
    800005d4:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d8:	000a4503          	lbu	a0,0(s4)
    800005dc:	16050263          	beqz	a0,80000740 <printf+0x1b2>
    800005e0:	4481                	li	s1,0
    if(c != '%'){
    800005e2:	02500a93          	li	s5,37
    switch(c){
    800005e6:	07000b13          	li	s6,112
  consputc('x');
    800005ea:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005ec:	00008b97          	auipc	s7,0x8
    800005f0:	a54b8b93          	addi	s7,s7,-1452 # 80008040 <digits>
    switch(c){
    800005f4:	07300c93          	li	s9,115
    800005f8:	06400c13          	li	s8,100
    800005fc:	a82d                	j	80000636 <printf+0xa8>
    acquire(&pr.lock);
    800005fe:	00010517          	auipc	a0,0x10
    80000602:	54a50513          	addi	a0,a0,1354 # 80010b48 <pr>
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	606080e7          	jalr	1542(ra) # 80000c0c <acquire>
    8000060e:	bf7d                	j	800005cc <printf+0x3e>
    panic("null fmt");
    80000610:	00008517          	auipc	a0,0x8
    80000614:	a1850513          	addi	a0,a0,-1512 # 80008028 <etext+0x28>
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	f2c080e7          	jalr	-212(ra) # 80000544 <panic>
      consputc(c);
    80000620:	00000097          	auipc	ra,0x0
    80000624:	c62080e7          	jalr	-926(ra) # 80000282 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000628:	2485                	addiw	s1,s1,1
    8000062a:	009a07b3          	add	a5,s4,s1
    8000062e:	0007c503          	lbu	a0,0(a5)
    80000632:	10050763          	beqz	a0,80000740 <printf+0x1b2>
    if(c != '%'){
    80000636:	ff5515e3          	bne	a0,s5,80000620 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063a:	2485                	addiw	s1,s1,1
    8000063c:	009a07b3          	add	a5,s4,s1
    80000640:	0007c783          	lbu	a5,0(a5)
    80000644:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000648:	cfe5                	beqz	a5,80000740 <printf+0x1b2>
    switch(c){
    8000064a:	05678a63          	beq	a5,s6,8000069e <printf+0x110>
    8000064e:	02fb7663          	bgeu	s6,a5,8000067a <printf+0xec>
    80000652:	09978963          	beq	a5,s9,800006e4 <printf+0x156>
    80000656:	07800713          	li	a4,120
    8000065a:	0ce79863          	bne	a5,a4,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000065e:	f8843783          	ld	a5,-120(s0)
    80000662:	00878713          	addi	a4,a5,8
    80000666:	f8e43423          	sd	a4,-120(s0)
    8000066a:	4605                	li	a2,1
    8000066c:	85ea                	mv	a1,s10
    8000066e:	4388                	lw	a0,0(a5)
    80000670:	00000097          	auipc	ra,0x0
    80000674:	e32080e7          	jalr	-462(ra) # 800004a2 <printint>
      break;
    80000678:	bf45                	j	80000628 <printf+0x9a>
    switch(c){
    8000067a:	0b578263          	beq	a5,s5,8000071e <printf+0x190>
    8000067e:	0b879663          	bne	a5,s8,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000682:	f8843783          	ld	a5,-120(s0)
    80000686:	00878713          	addi	a4,a5,8
    8000068a:	f8e43423          	sd	a4,-120(s0)
    8000068e:	4605                	li	a2,1
    80000690:	45a9                	li	a1,10
    80000692:	4388                	lw	a0,0(a5)
    80000694:	00000097          	auipc	ra,0x0
    80000698:	e0e080e7          	jalr	-498(ra) # 800004a2 <printint>
      break;
    8000069c:	b771                	j	80000628 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069e:	f8843783          	ld	a5,-120(s0)
    800006a2:	00878713          	addi	a4,a5,8
    800006a6:	f8e43423          	sd	a4,-120(s0)
    800006aa:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006ae:	03000513          	li	a0,48
    800006b2:	00000097          	auipc	ra,0x0
    800006b6:	bd0080e7          	jalr	-1072(ra) # 80000282 <consputc>
  consputc('x');
    800006ba:	07800513          	li	a0,120
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bc4080e7          	jalr	-1084(ra) # 80000282 <consputc>
    800006c6:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c8:	03c9d793          	srli	a5,s3,0x3c
    800006cc:	97de                	add	a5,a5,s7
    800006ce:	0007c503          	lbu	a0,0(a5)
    800006d2:	00000097          	auipc	ra,0x0
    800006d6:	bb0080e7          	jalr	-1104(ra) # 80000282 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006da:	0992                	slli	s3,s3,0x4
    800006dc:	397d                	addiw	s2,s2,-1
    800006de:	fe0915e3          	bnez	s2,800006c8 <printf+0x13a>
    800006e2:	b799                	j	80000628 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e4:	f8843783          	ld	a5,-120(s0)
    800006e8:	00878713          	addi	a4,a5,8
    800006ec:	f8e43423          	sd	a4,-120(s0)
    800006f0:	0007b903          	ld	s2,0(a5)
    800006f4:	00090e63          	beqz	s2,80000710 <printf+0x182>
      for(; *s; s++)
    800006f8:	00094503          	lbu	a0,0(s2)
    800006fc:	d515                	beqz	a0,80000628 <printf+0x9a>
        consputc(*s);
    800006fe:	00000097          	auipc	ra,0x0
    80000702:	b84080e7          	jalr	-1148(ra) # 80000282 <consputc>
      for(; *s; s++)
    80000706:	0905                	addi	s2,s2,1
    80000708:	00094503          	lbu	a0,0(s2)
    8000070c:	f96d                	bnez	a0,800006fe <printf+0x170>
    8000070e:	bf29                	j	80000628 <printf+0x9a>
        s = "(null)";
    80000710:	00008917          	auipc	s2,0x8
    80000714:	91090913          	addi	s2,s2,-1776 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000718:	02800513          	li	a0,40
    8000071c:	b7cd                	j	800006fe <printf+0x170>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b62080e7          	jalr	-1182(ra) # 80000282 <consputc>
      break;
    80000728:	b701                	j	80000628 <printf+0x9a>
      consputc('%');
    8000072a:	8556                	mv	a0,s5
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b56080e7          	jalr	-1194(ra) # 80000282 <consputc>
      consputc(c);
    80000734:	854a                	mv	a0,s2
    80000736:	00000097          	auipc	ra,0x0
    8000073a:	b4c080e7          	jalr	-1204(ra) # 80000282 <consputc>
      break;
    8000073e:	b5ed                	j	80000628 <printf+0x9a>
  if(locking)
    80000740:	020d9163          	bnez	s11,80000762 <printf+0x1d4>
}
    80000744:	70e6                	ld	ra,120(sp)
    80000746:	7446                	ld	s0,112(sp)
    80000748:	74a6                	ld	s1,104(sp)
    8000074a:	7906                	ld	s2,96(sp)
    8000074c:	69e6                	ld	s3,88(sp)
    8000074e:	6a46                	ld	s4,80(sp)
    80000750:	6aa6                	ld	s5,72(sp)
    80000752:	6b06                	ld	s6,64(sp)
    80000754:	7be2                	ld	s7,56(sp)
    80000756:	7c42                	ld	s8,48(sp)
    80000758:	7ca2                	ld	s9,40(sp)
    8000075a:	7d02                	ld	s10,32(sp)
    8000075c:	6de2                	ld	s11,24(sp)
    8000075e:	6129                	addi	sp,sp,192
    80000760:	8082                	ret
    release(&pr.lock);
    80000762:	00010517          	auipc	a0,0x10
    80000766:	3e650513          	addi	a0,a0,998 # 80010b48 <pr>
    8000076a:	00000097          	auipc	ra,0x0
    8000076e:	556080e7          	jalr	1366(ra) # 80000cc0 <release>
}
    80000772:	bfc9                	j	80000744 <printf+0x1b6>

0000000080000774 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000774:	1101                	addi	sp,sp,-32
    80000776:	ec06                	sd	ra,24(sp)
    80000778:	e822                	sd	s0,16(sp)
    8000077a:	e426                	sd	s1,8(sp)
    8000077c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000077e:	00010497          	auipc	s1,0x10
    80000782:	3ca48493          	addi	s1,s1,970 # 80010b48 <pr>
    80000786:	00008597          	auipc	a1,0x8
    8000078a:	8b258593          	addi	a1,a1,-1870 # 80008038 <etext+0x38>
    8000078e:	8526                	mv	a0,s1
    80000790:	00000097          	auipc	ra,0x0
    80000794:	3ec080e7          	jalr	1004(ra) # 80000b7c <initlock>
  pr.locking = 1;
    80000798:	4785                	li	a5,1
    8000079a:	cc9c                	sw	a5,24(s1)
}
    8000079c:	60e2                	ld	ra,24(sp)
    8000079e:	6442                	ld	s0,16(sp)
    800007a0:	64a2                	ld	s1,8(sp)
    800007a2:	6105                	addi	sp,sp,32
    800007a4:	8082                	ret

00000000800007a6 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a6:	1141                	addi	sp,sp,-16
    800007a8:	e406                	sd	ra,8(sp)
    800007aa:	e022                	sd	s0,0(sp)
    800007ac:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ae:	100007b7          	lui	a5,0x10000
    800007b2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b6:	f8000713          	li	a4,-128
    800007ba:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007be:	470d                	li	a4,3
    800007c0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007cc:	469d                	li	a3,7
    800007ce:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d6:	00008597          	auipc	a1,0x8
    800007da:	88258593          	addi	a1,a1,-1918 # 80008058 <digits+0x18>
    800007de:	00010517          	auipc	a0,0x10
    800007e2:	38a50513          	addi	a0,a0,906 # 80010b68 <uart_tx_lock>
    800007e6:	00000097          	auipc	ra,0x0
    800007ea:	396080e7          	jalr	918(ra) # 80000b7c <initlock>
}
    800007ee:	60a2                	ld	ra,8(sp)
    800007f0:	6402                	ld	s0,0(sp)
    800007f2:	0141                	addi	sp,sp,16
    800007f4:	8082                	ret

00000000800007f6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f6:	1101                	addi	sp,sp,-32
    800007f8:	ec06                	sd	ra,24(sp)
    800007fa:	e822                	sd	s0,16(sp)
    800007fc:	e426                	sd	s1,8(sp)
    800007fe:	1000                	addi	s0,sp,32
    80000800:	84aa                	mv	s1,a0
  push_off();
    80000802:	00000097          	auipc	ra,0x0
    80000806:	3be080e7          	jalr	958(ra) # 80000bc0 <push_off>

  if(panicked){
    8000080a:	00008797          	auipc	a5,0x8
    8000080e:	1167a783          	lw	a5,278(a5) # 80008920 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000812:	10000737          	lui	a4,0x10000
  if(panicked){
    80000816:	c391                	beqz	a5,8000081a <uartputc_sync+0x24>
    for(;;)
    80000818:	a001                	j	80000818 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000081e:	0ff7f793          	andi	a5,a5,255
    80000822:	0207f793          	andi	a5,a5,32
    80000826:	dbf5                	beqz	a5,8000081a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000828:	0ff4f793          	andi	a5,s1,255
    8000082c:	10000737          	lui	a4,0x10000
    80000830:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000834:	00000097          	auipc	ra,0x0
    80000838:	42c080e7          	jalr	1068(ra) # 80000c60 <pop_off>
}
    8000083c:	60e2                	ld	ra,24(sp)
    8000083e:	6442                	ld	s0,16(sp)
    80000840:	64a2                	ld	s1,8(sp)
    80000842:	6105                	addi	sp,sp,32
    80000844:	8082                	ret

0000000080000846 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000846:	00008717          	auipc	a4,0x8
    8000084a:	0e273703          	ld	a4,226(a4) # 80008928 <uart_tx_r>
    8000084e:	00008797          	auipc	a5,0x8
    80000852:	0e27b783          	ld	a5,226(a5) # 80008930 <uart_tx_w>
    80000856:	06e78c63          	beq	a5,a4,800008ce <uartstart+0x88>
{
    8000085a:	7139                	addi	sp,sp,-64
    8000085c:	fc06                	sd	ra,56(sp)
    8000085e:	f822                	sd	s0,48(sp)
    80000860:	f426                	sd	s1,40(sp)
    80000862:	f04a                	sd	s2,32(sp)
    80000864:	ec4e                	sd	s3,24(sp)
    80000866:	e852                	sd	s4,16(sp)
    80000868:	e456                	sd	s5,8(sp)
    8000086a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000086c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000870:	00010a17          	auipc	s4,0x10
    80000874:	2f8a0a13          	addi	s4,s4,760 # 80010b68 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	0b048493          	addi	s1,s1,176 # 80008928 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	0b098993          	addi	s3,s3,176 # 80008930 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000888:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000088c:	0ff7f793          	andi	a5,a5,255
    80000890:	0207f793          	andi	a5,a5,32
    80000894:	c785                	beqz	a5,800008bc <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000896:	01f77793          	andi	a5,a4,31
    8000089a:	97d2                	add	a5,a5,s4
    8000089c:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    800008a0:	0705                	addi	a4,a4,1
    800008a2:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a4:	8526                	mv	a0,s1
    800008a6:	00002097          	auipc	ra,0x2
    800008aa:	862080e7          	jalr	-1950(ra) # 80002108 <wakeup>
    
    WriteReg(THR, c);
    800008ae:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008b2:	6098                	ld	a4,0(s1)
    800008b4:	0009b783          	ld	a5,0(s3)
    800008b8:	fce798e3          	bne	a5,a4,80000888 <uartstart+0x42>
  }
}
    800008bc:	70e2                	ld	ra,56(sp)
    800008be:	7442                	ld	s0,48(sp)
    800008c0:	74a2                	ld	s1,40(sp)
    800008c2:	7902                	ld	s2,32(sp)
    800008c4:	69e2                	ld	s3,24(sp)
    800008c6:	6a42                	ld	s4,16(sp)
    800008c8:	6aa2                	ld	s5,8(sp)
    800008ca:	6121                	addi	sp,sp,64
    800008cc:	8082                	ret
    800008ce:	8082                	ret

00000000800008d0 <uartputc>:
{
    800008d0:	7179                	addi	sp,sp,-48
    800008d2:	f406                	sd	ra,40(sp)
    800008d4:	f022                	sd	s0,32(sp)
    800008d6:	ec26                	sd	s1,24(sp)
    800008d8:	e84a                	sd	s2,16(sp)
    800008da:	e44e                	sd	s3,8(sp)
    800008dc:	e052                	sd	s4,0(sp)
    800008de:	1800                	addi	s0,sp,48
    800008e0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008e2:	00010517          	auipc	a0,0x10
    800008e6:	28650513          	addi	a0,a0,646 # 80010b68 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	322080e7          	jalr	802(ra) # 80000c0c <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	02e7a783          	lw	a5,46(a5) # 80008920 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008797          	auipc	a5,0x8
    80000900:	0347b783          	ld	a5,52(a5) # 80008930 <uart_tx_w>
    80000904:	00008717          	auipc	a4,0x8
    80000908:	02473703          	ld	a4,36(a4) # 80008928 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010a17          	auipc	s4,0x10
    80000914:	258a0a13          	addi	s4,s4,600 # 80010b68 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	01048493          	addi	s1,s1,16 # 80008928 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	01090913          	addi	s2,s2,16 # 80008930 <uart_tx_w>
    80000928:	00f71f63          	bne	a4,a5,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85d2                	mv	a1,s4
    8000092e:	8526                	mv	a0,s1
    80000930:	00001097          	auipc	ra,0x1
    80000934:	774080e7          	jalr	1908(ra) # 800020a4 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093783          	ld	a5,0(s2)
    8000093c:	6098                	ld	a4,0(s1)
    8000093e:	02070713          	addi	a4,a4,32
    80000942:	fef705e3          	beq	a4,a5,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00010497          	auipc	s1,0x10
    8000094a:	22248493          	addi	s1,s1,546 # 80010b68 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00008717          	auipc	a4,0x8
    8000095e:	fcf73b23          	sd	a5,-42(a4) # 80008930 <uart_tx_w>
  uartstart();
    80000962:	00000097          	auipc	ra,0x0
    80000966:	ee4080e7          	jalr	-284(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    8000096a:	8526                	mv	a0,s1
    8000096c:	00000097          	auipc	ra,0x0
    80000970:	354080e7          	jalr	852(ra) # 80000cc0 <release>
}
    80000974:	70a2                	ld	ra,40(sp)
    80000976:	7402                	ld	s0,32(sp)
    80000978:	64e2                	ld	s1,24(sp)
    8000097a:	6942                	ld	s2,16(sp)
    8000097c:	69a2                	ld	s3,8(sp)
    8000097e:	6a02                	ld	s4,0(sp)
    80000980:	6145                	addi	sp,sp,48
    80000982:	8082                	ret
    for(;;)
    80000984:	a001                	j	80000984 <uartputc+0xb4>

0000000080000986 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000986:	1141                	addi	sp,sp,-16
    80000988:	e422                	sd	s0,8(sp)
    8000098a:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000098c:	100007b7          	lui	a5,0x10000
    80000990:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000994:	8b85                	andi	a5,a5,1
    80000996:	cb91                	beqz	a5,800009aa <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000998:	100007b7          	lui	a5,0x10000
    8000099c:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009a0:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009a4:	6422                	ld	s0,8(sp)
    800009a6:	0141                	addi	sp,sp,16
    800009a8:	8082                	ret
    return -1;
    800009aa:	557d                	li	a0,-1
    800009ac:	bfe5                	j	800009a4 <uartgetc+0x1e>

00000000800009ae <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009ae:	1101                	addi	sp,sp,-32
    800009b0:	ec06                	sd	ra,24(sp)
    800009b2:	e822                	sd	s0,16(sp)
    800009b4:	e426                	sd	s1,8(sp)
    800009b6:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b8:	54fd                	li	s1,-1
    int c = uartgetc();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	fcc080e7          	jalr	-52(ra) # 80000986 <uartgetc>
    if(c == -1)
    800009c2:	00950763          	beq	a0,s1,800009d0 <uartintr+0x22>
      break;
    consoleintr(c);
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	8fe080e7          	jalr	-1794(ra) # 800002c4 <consoleintr>
  while(1){
    800009ce:	b7f5                	j	800009ba <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009d0:	00010497          	auipc	s1,0x10
    800009d4:	19848493          	addi	s1,s1,408 # 80010b68 <uart_tx_lock>
    800009d8:	8526                	mv	a0,s1
    800009da:	00000097          	auipc	ra,0x0
    800009de:	232080e7          	jalr	562(ra) # 80000c0c <acquire>
  uartstart();
    800009e2:	00000097          	auipc	ra,0x0
    800009e6:	e64080e7          	jalr	-412(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    800009ea:	8526                	mv	a0,s1
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	2d4080e7          	jalr	724(ra) # 80000cc0 <release>
}
    800009f4:	60e2                	ld	ra,24(sp)
    800009f6:	6442                	ld	s0,16(sp)
    800009f8:	64a2                	ld	s1,8(sp)
    800009fa:	6105                	addi	sp,sp,32
    800009fc:	8082                	ret

00000000800009fe <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009fe:	1101                	addi	sp,sp,-32
    80000a00:	ec06                	sd	ra,24(sp)
    80000a02:	e822                	sd	s0,16(sp)
    80000a04:	e426                	sd	s1,8(sp)
    80000a06:	e04a                	sd	s2,0(sp)
    80000a08:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a0a:	03451793          	slli	a5,a0,0x34
    80000a0e:	ebb9                	bnez	a5,80000a64 <kfree+0x66>
    80000a10:	84aa                	mv	s1,a0
    80000a12:	00021797          	auipc	a5,0x21
    80000a16:	4be78793          	addi	a5,a5,1214 # 80021ed0 <end>
    80000a1a:	04f56563          	bltu	a0,a5,80000a64 <kfree+0x66>
    80000a1e:	47c5                	li	a5,17
    80000a20:	07ee                	slli	a5,a5,0x1b
    80000a22:	04f57163          	bgeu	a0,a5,80000a64 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a26:	6605                	lui	a2,0x1
    80000a28:	4585                	li	a1,1
    80000a2a:	00000097          	auipc	ra,0x0
    80000a2e:	2de080e7          	jalr	734(ra) # 80000d08 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a32:	00010917          	auipc	s2,0x10
    80000a36:	16e90913          	addi	s2,s2,366 # 80010ba0 <kmem>
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	1d0080e7          	jalr	464(ra) # 80000c0c <acquire>
  r->next = kmem.freelist;
    80000a44:	01893783          	ld	a5,24(s2)
    80000a48:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a4a:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a4e:	854a                	mv	a0,s2
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	270080e7          	jalr	624(ra) # 80000cc0 <release>
}
    80000a58:	60e2                	ld	ra,24(sp)
    80000a5a:	6442                	ld	s0,16(sp)
    80000a5c:	64a2                	ld	s1,8(sp)
    80000a5e:	6902                	ld	s2,0(sp)
    80000a60:	6105                	addi	sp,sp,32
    80000a62:	8082                	ret
    panic("kfree");
    80000a64:	00007517          	auipc	a0,0x7
    80000a68:	5fc50513          	addi	a0,a0,1532 # 80008060 <digits+0x20>
    80000a6c:	00000097          	auipc	ra,0x0
    80000a70:	ad8080e7          	jalr	-1320(ra) # 80000544 <panic>

0000000080000a74 <freerange>:
{
    80000a74:	7179                	addi	sp,sp,-48
    80000a76:	f406                	sd	ra,40(sp)
    80000a78:	f022                	sd	s0,32(sp)
    80000a7a:	ec26                	sd	s1,24(sp)
    80000a7c:	e84a                	sd	s2,16(sp)
    80000a7e:	e44e                	sd	s3,8(sp)
    80000a80:	e052                	sd	s4,0(sp)
    80000a82:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a84:	6785                	lui	a5,0x1
    80000a86:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a8a:	94aa                	add	s1,s1,a0
    80000a8c:	757d                	lui	a0,0xfffff
    80000a8e:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a90:	94be                	add	s1,s1,a5
    80000a92:	0095ee63          	bltu	a1,s1,80000aae <freerange+0x3a>
    80000a96:	892e                	mv	s2,a1
    kfree(p);
    80000a98:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a9a:	6985                	lui	s3,0x1
    kfree(p);
    80000a9c:	01448533          	add	a0,s1,s4
    80000aa0:	00000097          	auipc	ra,0x0
    80000aa4:	f5e080e7          	jalr	-162(ra) # 800009fe <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa8:	94ce                	add	s1,s1,s3
    80000aaa:	fe9979e3          	bgeu	s2,s1,80000a9c <freerange+0x28>
}
    80000aae:	70a2                	ld	ra,40(sp)
    80000ab0:	7402                	ld	s0,32(sp)
    80000ab2:	64e2                	ld	s1,24(sp)
    80000ab4:	6942                	ld	s2,16(sp)
    80000ab6:	69a2                	ld	s3,8(sp)
    80000ab8:	6a02                	ld	s4,0(sp)
    80000aba:	6145                	addi	sp,sp,48
    80000abc:	8082                	ret

0000000080000abe <kinit>:
{
    80000abe:	1141                	addi	sp,sp,-16
    80000ac0:	e406                	sd	ra,8(sp)
    80000ac2:	e022                	sd	s0,0(sp)
    80000ac4:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac6:	00007597          	auipc	a1,0x7
    80000aca:	5a258593          	addi	a1,a1,1442 # 80008068 <digits+0x28>
    80000ace:	00010517          	auipc	a0,0x10
    80000ad2:	0d250513          	addi	a0,a0,210 # 80010ba0 <kmem>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	0a6080e7          	jalr	166(ra) # 80000b7c <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ade:	45c5                	li	a1,17
    80000ae0:	05ee                	slli	a1,a1,0x1b
    80000ae2:	00021517          	auipc	a0,0x21
    80000ae6:	3ee50513          	addi	a0,a0,1006 # 80021ed0 <end>
    80000aea:	00000097          	auipc	ra,0x0
    80000aee:	f8a080e7          	jalr	-118(ra) # 80000a74 <freerange>
}
    80000af2:	60a2                	ld	ra,8(sp)
    80000af4:	6402                	ld	s0,0(sp)
    80000af6:	0141                	addi	sp,sp,16
    80000af8:	8082                	ret

0000000080000afa <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000afa:	1101                	addi	sp,sp,-32
    80000afc:	ec06                	sd	ra,24(sp)
    80000afe:	e822                	sd	s0,16(sp)
    80000b00:	e426                	sd	s1,8(sp)
    80000b02:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b04:	00010497          	auipc	s1,0x10
    80000b08:	09c48493          	addi	s1,s1,156 # 80010ba0 <kmem>
    80000b0c:	8526                	mv	a0,s1
    80000b0e:	00000097          	auipc	ra,0x0
    80000b12:	0fe080e7          	jalr	254(ra) # 80000c0c <acquire>
  r = kmem.freelist;
    80000b16:	6c84                	ld	s1,24(s1)
  if(r)
    80000b18:	c885                	beqz	s1,80000b48 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b1a:	609c                	ld	a5,0(s1)
    80000b1c:	00010517          	auipc	a0,0x10
    80000b20:	08450513          	addi	a0,a0,132 # 80010ba0 <kmem>
    80000b24:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b26:	00000097          	auipc	ra,0x0
    80000b2a:	19a080e7          	jalr	410(ra) # 80000cc0 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b2e:	6605                	lui	a2,0x1
    80000b30:	4595                	li	a1,5
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	1d4080e7          	jalr	468(ra) # 80000d08 <memset>
  return (void*)r;
}
    80000b3c:	8526                	mv	a0,s1
    80000b3e:	60e2                	ld	ra,24(sp)
    80000b40:	6442                	ld	s0,16(sp)
    80000b42:	64a2                	ld	s1,8(sp)
    80000b44:	6105                	addi	sp,sp,32
    80000b46:	8082                	ret
  release(&kmem.lock);
    80000b48:	00010517          	auipc	a0,0x10
    80000b4c:	05850513          	addi	a0,a0,88 # 80010ba0 <kmem>
    80000b50:	00000097          	auipc	ra,0x0
    80000b54:	170080e7          	jalr	368(ra) # 80000cc0 <release>
  if(r)
    80000b58:	b7d5                	j	80000b3c <kalloc+0x42>

0000000080000b5a <free_memory_pages>:

int free_memory_pages(void)
{
    80000b5a:	1141                	addi	sp,sp,-16
    80000b5c:	e422                	sd	s0,8(sp)
    80000b5e:	0800                	addi	s0,sp,16
  int Num_pages = 0;
  struct run * r = kmem.freelist;
    80000b60:	00010797          	auipc	a5,0x10
    80000b64:	0587b783          	ld	a5,88(a5) # 80010bb8 <kmem+0x18>
  while (r != NULL)
    80000b68:	cb81                	beqz	a5,80000b78 <free_memory_pages+0x1e>
  int Num_pages = 0;
    80000b6a:	4501                	li	a0,0
  {
    Num_pages++;
    80000b6c:	2505                	addiw	a0,a0,1
    r = r->next;
    80000b6e:	639c                	ld	a5,0(a5)
  while (r != NULL)
    80000b70:	fff5                	bnez	a5,80000b6c <free_memory_pages+0x12>
  }
  return Num_pages;
    80000b72:	6422                	ld	s0,8(sp)
    80000b74:	0141                	addi	sp,sp,16
    80000b76:	8082                	ret
  int Num_pages = 0;
    80000b78:	4501                	li	a0,0
    80000b7a:	bfe5                	j	80000b72 <free_memory_pages+0x18>

0000000080000b7c <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b7c:	1141                	addi	sp,sp,-16
    80000b7e:	e422                	sd	s0,8(sp)
    80000b80:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b82:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b84:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b88:	00053823          	sd	zero,16(a0)
}
    80000b8c:	6422                	ld	s0,8(sp)
    80000b8e:	0141                	addi	sp,sp,16
    80000b90:	8082                	ret

0000000080000b92 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b92:	411c                	lw	a5,0(a0)
    80000b94:	e399                	bnez	a5,80000b9a <holding+0x8>
    80000b96:	4501                	li	a0,0
  return r;
}
    80000b98:	8082                	ret
{
    80000b9a:	1101                	addi	sp,sp,-32
    80000b9c:	ec06                	sd	ra,24(sp)
    80000b9e:	e822                	sd	s0,16(sp)
    80000ba0:	e426                	sd	s1,8(sp)
    80000ba2:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000ba4:	6904                	ld	s1,16(a0)
    80000ba6:	00001097          	auipc	ra,0x1
    80000baa:	e26080e7          	jalr	-474(ra) # 800019cc <mycpu>
    80000bae:	40a48533          	sub	a0,s1,a0
    80000bb2:	00153513          	seqz	a0,a0
}
    80000bb6:	60e2                	ld	ra,24(sp)
    80000bb8:	6442                	ld	s0,16(sp)
    80000bba:	64a2                	ld	s1,8(sp)
    80000bbc:	6105                	addi	sp,sp,32
    80000bbe:	8082                	ret

0000000080000bc0 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bc0:	1101                	addi	sp,sp,-32
    80000bc2:	ec06                	sd	ra,24(sp)
    80000bc4:	e822                	sd	s0,16(sp)
    80000bc6:	e426                	sd	s1,8(sp)
    80000bc8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bca:	100024f3          	csrr	s1,sstatus
    80000bce:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bd2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bd4:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bd8:	00001097          	auipc	ra,0x1
    80000bdc:	df4080e7          	jalr	-524(ra) # 800019cc <mycpu>
    80000be0:	5d3c                	lw	a5,120(a0)
    80000be2:	cf89                	beqz	a5,80000bfc <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000be4:	00001097          	auipc	ra,0x1
    80000be8:	de8080e7          	jalr	-536(ra) # 800019cc <mycpu>
    80000bec:	5d3c                	lw	a5,120(a0)
    80000bee:	2785                	addiw	a5,a5,1
    80000bf0:	dd3c                	sw	a5,120(a0)
}
    80000bf2:	60e2                	ld	ra,24(sp)
    80000bf4:	6442                	ld	s0,16(sp)
    80000bf6:	64a2                	ld	s1,8(sp)
    80000bf8:	6105                	addi	sp,sp,32
    80000bfa:	8082                	ret
    mycpu()->intena = old;
    80000bfc:	00001097          	auipc	ra,0x1
    80000c00:	dd0080e7          	jalr	-560(ra) # 800019cc <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c04:	8085                	srli	s1,s1,0x1
    80000c06:	8885                	andi	s1,s1,1
    80000c08:	dd64                	sw	s1,124(a0)
    80000c0a:	bfe9                	j	80000be4 <push_off+0x24>

0000000080000c0c <acquire>:
{
    80000c0c:	1101                	addi	sp,sp,-32
    80000c0e:	ec06                	sd	ra,24(sp)
    80000c10:	e822                	sd	s0,16(sp)
    80000c12:	e426                	sd	s1,8(sp)
    80000c14:	1000                	addi	s0,sp,32
    80000c16:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c18:	00000097          	auipc	ra,0x0
    80000c1c:	fa8080e7          	jalr	-88(ra) # 80000bc0 <push_off>
  if(holding(lk))
    80000c20:	8526                	mv	a0,s1
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	f70080e7          	jalr	-144(ra) # 80000b92 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c2a:	4705                	li	a4,1
  if(holding(lk))
    80000c2c:	e115                	bnez	a0,80000c50 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c2e:	87ba                	mv	a5,a4
    80000c30:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c34:	2781                	sext.w	a5,a5
    80000c36:	ffe5                	bnez	a5,80000c2e <acquire+0x22>
  __sync_synchronize();
    80000c38:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c3c:	00001097          	auipc	ra,0x1
    80000c40:	d90080e7          	jalr	-624(ra) # 800019cc <mycpu>
    80000c44:	e888                	sd	a0,16(s1)
}
    80000c46:	60e2                	ld	ra,24(sp)
    80000c48:	6442                	ld	s0,16(sp)
    80000c4a:	64a2                	ld	s1,8(sp)
    80000c4c:	6105                	addi	sp,sp,32
    80000c4e:	8082                	ret
    panic("acquire");
    80000c50:	00007517          	auipc	a0,0x7
    80000c54:	42050513          	addi	a0,a0,1056 # 80008070 <digits+0x30>
    80000c58:	00000097          	auipc	ra,0x0
    80000c5c:	8ec080e7          	jalr	-1812(ra) # 80000544 <panic>

0000000080000c60 <pop_off>:

void
pop_off(void)
{
    80000c60:	1141                	addi	sp,sp,-16
    80000c62:	e406                	sd	ra,8(sp)
    80000c64:	e022                	sd	s0,0(sp)
    80000c66:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c68:	00001097          	auipc	ra,0x1
    80000c6c:	d64080e7          	jalr	-668(ra) # 800019cc <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c70:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c74:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c76:	e78d                	bnez	a5,80000ca0 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c78:	5d3c                	lw	a5,120(a0)
    80000c7a:	02f05b63          	blez	a5,80000cb0 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c7e:	37fd                	addiw	a5,a5,-1
    80000c80:	0007871b          	sext.w	a4,a5
    80000c84:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c86:	eb09                	bnez	a4,80000c98 <pop_off+0x38>
    80000c88:	5d7c                	lw	a5,124(a0)
    80000c8a:	c799                	beqz	a5,80000c98 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c8c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c90:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c94:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c98:	60a2                	ld	ra,8(sp)
    80000c9a:	6402                	ld	s0,0(sp)
    80000c9c:	0141                	addi	sp,sp,16
    80000c9e:	8082                	ret
    panic("pop_off - interruptible");
    80000ca0:	00007517          	auipc	a0,0x7
    80000ca4:	3d850513          	addi	a0,a0,984 # 80008078 <digits+0x38>
    80000ca8:	00000097          	auipc	ra,0x0
    80000cac:	89c080e7          	jalr	-1892(ra) # 80000544 <panic>
    panic("pop_off");
    80000cb0:	00007517          	auipc	a0,0x7
    80000cb4:	3e050513          	addi	a0,a0,992 # 80008090 <digits+0x50>
    80000cb8:	00000097          	auipc	ra,0x0
    80000cbc:	88c080e7          	jalr	-1908(ra) # 80000544 <panic>

0000000080000cc0 <release>:
{
    80000cc0:	1101                	addi	sp,sp,-32
    80000cc2:	ec06                	sd	ra,24(sp)
    80000cc4:	e822                	sd	s0,16(sp)
    80000cc6:	e426                	sd	s1,8(sp)
    80000cc8:	1000                	addi	s0,sp,32
    80000cca:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ccc:	00000097          	auipc	ra,0x0
    80000cd0:	ec6080e7          	jalr	-314(ra) # 80000b92 <holding>
    80000cd4:	c115                	beqz	a0,80000cf8 <release+0x38>
  lk->cpu = 0;
    80000cd6:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cda:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cde:	0f50000f          	fence	iorw,ow
    80000ce2:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000ce6:	00000097          	auipc	ra,0x0
    80000cea:	f7a080e7          	jalr	-134(ra) # 80000c60 <pop_off>
}
    80000cee:	60e2                	ld	ra,24(sp)
    80000cf0:	6442                	ld	s0,16(sp)
    80000cf2:	64a2                	ld	s1,8(sp)
    80000cf4:	6105                	addi	sp,sp,32
    80000cf6:	8082                	ret
    panic("release");
    80000cf8:	00007517          	auipc	a0,0x7
    80000cfc:	3a050513          	addi	a0,a0,928 # 80008098 <digits+0x58>
    80000d00:	00000097          	auipc	ra,0x0
    80000d04:	844080e7          	jalr	-1980(ra) # 80000544 <panic>

0000000080000d08 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d08:	1141                	addi	sp,sp,-16
    80000d0a:	e422                	sd	s0,8(sp)
    80000d0c:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d0e:	ce09                	beqz	a2,80000d28 <memset+0x20>
    80000d10:	87aa                	mv	a5,a0
    80000d12:	fff6071b          	addiw	a4,a2,-1
    80000d16:	1702                	slli	a4,a4,0x20
    80000d18:	9301                	srli	a4,a4,0x20
    80000d1a:	0705                	addi	a4,a4,1
    80000d1c:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d1e:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d22:	0785                	addi	a5,a5,1
    80000d24:	fee79de3          	bne	a5,a4,80000d1e <memset+0x16>
  }
  return dst;
}
    80000d28:	6422                	ld	s0,8(sp)
    80000d2a:	0141                	addi	sp,sp,16
    80000d2c:	8082                	ret

0000000080000d2e <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d34:	ca05                	beqz	a2,80000d64 <memcmp+0x36>
    80000d36:	fff6069b          	addiw	a3,a2,-1
    80000d3a:	1682                	slli	a3,a3,0x20
    80000d3c:	9281                	srli	a3,a3,0x20
    80000d3e:	0685                	addi	a3,a3,1
    80000d40:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d42:	00054783          	lbu	a5,0(a0)
    80000d46:	0005c703          	lbu	a4,0(a1)
    80000d4a:	00e79863          	bne	a5,a4,80000d5a <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d4e:	0505                	addi	a0,a0,1
    80000d50:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d52:	fed518e3          	bne	a0,a3,80000d42 <memcmp+0x14>
  }

  return 0;
    80000d56:	4501                	li	a0,0
    80000d58:	a019                	j	80000d5e <memcmp+0x30>
      return *s1 - *s2;
    80000d5a:	40e7853b          	subw	a0,a5,a4
}
    80000d5e:	6422                	ld	s0,8(sp)
    80000d60:	0141                	addi	sp,sp,16
    80000d62:	8082                	ret
  return 0;
    80000d64:	4501                	li	a0,0
    80000d66:	bfe5                	j	80000d5e <memcmp+0x30>

0000000080000d68 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d68:	1141                	addi	sp,sp,-16
    80000d6a:	e422                	sd	s0,8(sp)
    80000d6c:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d6e:	ca0d                	beqz	a2,80000da0 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d70:	00a5f963          	bgeu	a1,a0,80000d82 <memmove+0x1a>
    80000d74:	02061693          	slli	a3,a2,0x20
    80000d78:	9281                	srli	a3,a3,0x20
    80000d7a:	00d58733          	add	a4,a1,a3
    80000d7e:	02e56463          	bltu	a0,a4,80000da6 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d82:	fff6079b          	addiw	a5,a2,-1
    80000d86:	1782                	slli	a5,a5,0x20
    80000d88:	9381                	srli	a5,a5,0x20
    80000d8a:	0785                	addi	a5,a5,1
    80000d8c:	97ae                	add	a5,a5,a1
    80000d8e:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d90:	0585                	addi	a1,a1,1
    80000d92:	0705                	addi	a4,a4,1
    80000d94:	fff5c683          	lbu	a3,-1(a1)
    80000d98:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d9c:	fef59ae3          	bne	a1,a5,80000d90 <memmove+0x28>

  return dst;
}
    80000da0:	6422                	ld	s0,8(sp)
    80000da2:	0141                	addi	sp,sp,16
    80000da4:	8082                	ret
    d += n;
    80000da6:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000da8:	fff6079b          	addiw	a5,a2,-1
    80000dac:	1782                	slli	a5,a5,0x20
    80000dae:	9381                	srli	a5,a5,0x20
    80000db0:	fff7c793          	not	a5,a5
    80000db4:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000db6:	177d                	addi	a4,a4,-1
    80000db8:	16fd                	addi	a3,a3,-1
    80000dba:	00074603          	lbu	a2,0(a4)
    80000dbe:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000dc2:	fef71ae3          	bne	a4,a5,80000db6 <memmove+0x4e>
    80000dc6:	bfe9                	j	80000da0 <memmove+0x38>

0000000080000dc8 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dc8:	1141                	addi	sp,sp,-16
    80000dca:	e406                	sd	ra,8(sp)
    80000dcc:	e022                	sd	s0,0(sp)
    80000dce:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dd0:	00000097          	auipc	ra,0x0
    80000dd4:	f98080e7          	jalr	-104(ra) # 80000d68 <memmove>
}
    80000dd8:	60a2                	ld	ra,8(sp)
    80000dda:	6402                	ld	s0,0(sp)
    80000ddc:	0141                	addi	sp,sp,16
    80000dde:	8082                	ret

0000000080000de0 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000de0:	1141                	addi	sp,sp,-16
    80000de2:	e422                	sd	s0,8(sp)
    80000de4:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000de6:	ce11                	beqz	a2,80000e02 <strncmp+0x22>
    80000de8:	00054783          	lbu	a5,0(a0)
    80000dec:	cf89                	beqz	a5,80000e06 <strncmp+0x26>
    80000dee:	0005c703          	lbu	a4,0(a1)
    80000df2:	00f71a63          	bne	a4,a5,80000e06 <strncmp+0x26>
    n--, p++, q++;
    80000df6:	367d                	addiw	a2,a2,-1
    80000df8:	0505                	addi	a0,a0,1
    80000dfa:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dfc:	f675                	bnez	a2,80000de8 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dfe:	4501                	li	a0,0
    80000e00:	a809                	j	80000e12 <strncmp+0x32>
    80000e02:	4501                	li	a0,0
    80000e04:	a039                	j	80000e12 <strncmp+0x32>
  if(n == 0)
    80000e06:	ca09                	beqz	a2,80000e18 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e08:	00054503          	lbu	a0,0(a0)
    80000e0c:	0005c783          	lbu	a5,0(a1)
    80000e10:	9d1d                	subw	a0,a0,a5
}
    80000e12:	6422                	ld	s0,8(sp)
    80000e14:	0141                	addi	sp,sp,16
    80000e16:	8082                	ret
    return 0;
    80000e18:	4501                	li	a0,0
    80000e1a:	bfe5                	j	80000e12 <strncmp+0x32>

0000000080000e1c <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e22:	872a                	mv	a4,a0
    80000e24:	8832                	mv	a6,a2
    80000e26:	367d                	addiw	a2,a2,-1
    80000e28:	01005963          	blez	a6,80000e3a <strncpy+0x1e>
    80000e2c:	0705                	addi	a4,a4,1
    80000e2e:	0005c783          	lbu	a5,0(a1)
    80000e32:	fef70fa3          	sb	a5,-1(a4)
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	f7f5                	bnez	a5,80000e24 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e3a:	00c05d63          	blez	a2,80000e54 <strncpy+0x38>
    80000e3e:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e40:	0685                	addi	a3,a3,1
    80000e42:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e46:	fff6c793          	not	a5,a3
    80000e4a:	9fb9                	addw	a5,a5,a4
    80000e4c:	010787bb          	addw	a5,a5,a6
    80000e50:	fef048e3          	bgtz	a5,80000e40 <strncpy+0x24>
  return os;
}
    80000e54:	6422                	ld	s0,8(sp)
    80000e56:	0141                	addi	sp,sp,16
    80000e58:	8082                	ret

0000000080000e5a <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e5a:	1141                	addi	sp,sp,-16
    80000e5c:	e422                	sd	s0,8(sp)
    80000e5e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e60:	02c05363          	blez	a2,80000e86 <safestrcpy+0x2c>
    80000e64:	fff6069b          	addiw	a3,a2,-1
    80000e68:	1682                	slli	a3,a3,0x20
    80000e6a:	9281                	srli	a3,a3,0x20
    80000e6c:	96ae                	add	a3,a3,a1
    80000e6e:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e70:	00d58963          	beq	a1,a3,80000e82 <safestrcpy+0x28>
    80000e74:	0585                	addi	a1,a1,1
    80000e76:	0785                	addi	a5,a5,1
    80000e78:	fff5c703          	lbu	a4,-1(a1)
    80000e7c:	fee78fa3          	sb	a4,-1(a5)
    80000e80:	fb65                	bnez	a4,80000e70 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e82:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e86:	6422                	ld	s0,8(sp)
    80000e88:	0141                	addi	sp,sp,16
    80000e8a:	8082                	ret

0000000080000e8c <strlen>:

int
strlen(const char *s)
{
    80000e8c:	1141                	addi	sp,sp,-16
    80000e8e:	e422                	sd	s0,8(sp)
    80000e90:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e92:	00054783          	lbu	a5,0(a0)
    80000e96:	cf91                	beqz	a5,80000eb2 <strlen+0x26>
    80000e98:	0505                	addi	a0,a0,1
    80000e9a:	87aa                	mv	a5,a0
    80000e9c:	4685                	li	a3,1
    80000e9e:	9e89                	subw	a3,a3,a0
    80000ea0:	00f6853b          	addw	a0,a3,a5
    80000ea4:	0785                	addi	a5,a5,1
    80000ea6:	fff7c703          	lbu	a4,-1(a5)
    80000eaa:	fb7d                	bnez	a4,80000ea0 <strlen+0x14>
    ;
  return n;
}
    80000eac:	6422                	ld	s0,8(sp)
    80000eae:	0141                	addi	sp,sp,16
    80000eb0:	8082                	ret
  for(n = 0; s[n]; n++)
    80000eb2:	4501                	li	a0,0
    80000eb4:	bfe5                	j	80000eac <strlen+0x20>

0000000080000eb6 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000eb6:	1141                	addi	sp,sp,-16
    80000eb8:	e406                	sd	ra,8(sp)
    80000eba:	e022                	sd	s0,0(sp)
    80000ebc:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ebe:	00001097          	auipc	ra,0x1
    80000ec2:	afe080e7          	jalr	-1282(ra) # 800019bc <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ec6:	00008717          	auipc	a4,0x8
    80000eca:	a7270713          	addi	a4,a4,-1422 # 80008938 <started>
  if(cpuid() == 0){
    80000ece:	c139                	beqz	a0,80000f14 <main+0x5e>
    while(started == 0)
    80000ed0:	431c                	lw	a5,0(a4)
    80000ed2:	2781                	sext.w	a5,a5
    80000ed4:	dff5                	beqz	a5,80000ed0 <main+0x1a>
      ;
    __sync_synchronize();
    80000ed6:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eda:	00001097          	auipc	ra,0x1
    80000ede:	ae2080e7          	jalr	-1310(ra) # 800019bc <cpuid>
    80000ee2:	85aa                	mv	a1,a0
    80000ee4:	00007517          	auipc	a0,0x7
    80000ee8:	1d450513          	addi	a0,a0,468 # 800080b8 <digits+0x78>
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	6a2080e7          	jalr	1698(ra) # 8000058e <printf>
    kvminithart();    // turn on paging
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	0d8080e7          	jalr	216(ra) # 80000fcc <kvminithart>
    trapinithart();   // install kernel trap vector
    80000efc:	00002097          	auipc	ra,0x2
    80000f00:	8c4080e7          	jalr	-1852(ra) # 800027c0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f04:	00005097          	auipc	ra,0x5
    80000f08:	ecc080e7          	jalr	-308(ra) # 80005dd0 <plicinithart>
  }

  scheduler();        
    80000f0c:	00001097          	auipc	ra,0x1
    80000f10:	fe6080e7          	jalr	-26(ra) # 80001ef2 <scheduler>
    consoleinit();
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	542080e7          	jalr	1346(ra) # 80000456 <consoleinit>
    printfinit();
    80000f1c:	00000097          	auipc	ra,0x0
    80000f20:	858080e7          	jalr	-1960(ra) # 80000774 <printfinit>
    printf("\n");
    80000f24:	00007517          	auipc	a0,0x7
    80000f28:	1a450513          	addi	a0,a0,420 # 800080c8 <digits+0x88>
    80000f2c:	fffff097          	auipc	ra,0xfffff
    80000f30:	662080e7          	jalr	1634(ra) # 8000058e <printf>
    printf("xv6 kernel is booting\n");
    80000f34:	00007517          	auipc	a0,0x7
    80000f38:	16c50513          	addi	a0,a0,364 # 800080a0 <digits+0x60>
    80000f3c:	fffff097          	auipc	ra,0xfffff
    80000f40:	652080e7          	jalr	1618(ra) # 8000058e <printf>
    printf("\n");
    80000f44:	00007517          	auipc	a0,0x7
    80000f48:	18450513          	addi	a0,a0,388 # 800080c8 <digits+0x88>
    80000f4c:	fffff097          	auipc	ra,0xfffff
    80000f50:	642080e7          	jalr	1602(ra) # 8000058e <printf>
    kinit();         // physical page allocator
    80000f54:	00000097          	auipc	ra,0x0
    80000f58:	b6a080e7          	jalr	-1174(ra) # 80000abe <kinit>
    kvminit();       // create kernel page table
    80000f5c:	00000097          	auipc	ra,0x0
    80000f60:	326080e7          	jalr	806(ra) # 80001282 <kvminit>
    kvminithart();   // turn on paging
    80000f64:	00000097          	auipc	ra,0x0
    80000f68:	068080e7          	jalr	104(ra) # 80000fcc <kvminithart>
    procinit();      // process table
    80000f6c:	00001097          	auipc	ra,0x1
    80000f70:	99c080e7          	jalr	-1636(ra) # 80001908 <procinit>
    trapinit();      // trap vectors
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	824080e7          	jalr	-2012(ra) # 80002798 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f7c:	00002097          	auipc	ra,0x2
    80000f80:	844080e7          	jalr	-1980(ra) # 800027c0 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	e36080e7          	jalr	-458(ra) # 80005dba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	e44080e7          	jalr	-444(ra) # 80005dd0 <plicinithart>
    binit();         // buffer cache
    80000f94:	00002097          	auipc	ra,0x2
    80000f98:	ffa080e7          	jalr	-6(ra) # 80002f8e <binit>
    iinit();         // inode table
    80000f9c:	00002097          	auipc	ra,0x2
    80000fa0:	69e080e7          	jalr	1694(ra) # 8000363a <iinit>
    fileinit();      // file table
    80000fa4:	00003097          	auipc	ra,0x3
    80000fa8:	63c080e7          	jalr	1596(ra) # 800045e0 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fac:	00005097          	auipc	ra,0x5
    80000fb0:	f2c080e7          	jalr	-212(ra) # 80005ed8 <virtio_disk_init>
    userinit();      // first user process
    80000fb4:	00001097          	auipc	ra,0x1
    80000fb8:	d24080e7          	jalr	-732(ra) # 80001cd8 <userinit>
    __sync_synchronize();
    80000fbc:	0ff0000f          	fence
    started = 1;
    80000fc0:	4785                	li	a5,1
    80000fc2:	00008717          	auipc	a4,0x8
    80000fc6:	96f72b23          	sw	a5,-1674(a4) # 80008938 <started>
    80000fca:	b789                	j	80000f0c <main+0x56>

0000000080000fcc <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fcc:	1141                	addi	sp,sp,-16
    80000fce:	e422                	sd	s0,8(sp)
    80000fd0:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fd2:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000fd6:	00008797          	auipc	a5,0x8
    80000fda:	96a7b783          	ld	a5,-1686(a5) # 80008940 <kernel_pagetable>
    80000fde:	83b1                	srli	a5,a5,0xc
    80000fe0:	577d                	li	a4,-1
    80000fe2:	177e                	slli	a4,a4,0x3f
    80000fe4:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fe6:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fea:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fee:	6422                	ld	s0,8(sp)
    80000ff0:	0141                	addi	sp,sp,16
    80000ff2:	8082                	ret

0000000080000ff4 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000ff4:	7139                	addi	sp,sp,-64
    80000ff6:	fc06                	sd	ra,56(sp)
    80000ff8:	f822                	sd	s0,48(sp)
    80000ffa:	f426                	sd	s1,40(sp)
    80000ffc:	f04a                	sd	s2,32(sp)
    80000ffe:	ec4e                	sd	s3,24(sp)
    80001000:	e852                	sd	s4,16(sp)
    80001002:	e456                	sd	s5,8(sp)
    80001004:	e05a                	sd	s6,0(sp)
    80001006:	0080                	addi	s0,sp,64
    80001008:	84aa                	mv	s1,a0
    8000100a:	89ae                	mv	s3,a1
    8000100c:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000100e:	57fd                	li	a5,-1
    80001010:	83e9                	srli	a5,a5,0x1a
    80001012:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001014:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001016:	04b7f263          	bgeu	a5,a1,8000105a <walk+0x66>
    panic("walk");
    8000101a:	00007517          	auipc	a0,0x7
    8000101e:	0b650513          	addi	a0,a0,182 # 800080d0 <digits+0x90>
    80001022:	fffff097          	auipc	ra,0xfffff
    80001026:	522080e7          	jalr	1314(ra) # 80000544 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000102a:	060a8663          	beqz	s5,80001096 <walk+0xa2>
    8000102e:	00000097          	auipc	ra,0x0
    80001032:	acc080e7          	jalr	-1332(ra) # 80000afa <kalloc>
    80001036:	84aa                	mv	s1,a0
    80001038:	c529                	beqz	a0,80001082 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000103a:	6605                	lui	a2,0x1
    8000103c:	4581                	li	a1,0
    8000103e:	00000097          	auipc	ra,0x0
    80001042:	cca080e7          	jalr	-822(ra) # 80000d08 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001046:	00c4d793          	srli	a5,s1,0xc
    8000104a:	07aa                	slli	a5,a5,0xa
    8000104c:	0017e793          	ori	a5,a5,1
    80001050:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001054:	3a5d                	addiw	s4,s4,-9
    80001056:	036a0063          	beq	s4,s6,80001076 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000105a:	0149d933          	srl	s2,s3,s4
    8000105e:	1ff97913          	andi	s2,s2,511
    80001062:	090e                	slli	s2,s2,0x3
    80001064:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001066:	00093483          	ld	s1,0(s2)
    8000106a:	0014f793          	andi	a5,s1,1
    8000106e:	dfd5                	beqz	a5,8000102a <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001070:	80a9                	srli	s1,s1,0xa
    80001072:	04b2                	slli	s1,s1,0xc
    80001074:	b7c5                	j	80001054 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001076:	00c9d513          	srli	a0,s3,0xc
    8000107a:	1ff57513          	andi	a0,a0,511
    8000107e:	050e                	slli	a0,a0,0x3
    80001080:	9526                	add	a0,a0,s1
}
    80001082:	70e2                	ld	ra,56(sp)
    80001084:	7442                	ld	s0,48(sp)
    80001086:	74a2                	ld	s1,40(sp)
    80001088:	7902                	ld	s2,32(sp)
    8000108a:	69e2                	ld	s3,24(sp)
    8000108c:	6a42                	ld	s4,16(sp)
    8000108e:	6aa2                	ld	s5,8(sp)
    80001090:	6b02                	ld	s6,0(sp)
    80001092:	6121                	addi	sp,sp,64
    80001094:	8082                	ret
        return 0;
    80001096:	4501                	li	a0,0
    80001098:	b7ed                	j	80001082 <walk+0x8e>

000000008000109a <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000109a:	57fd                	li	a5,-1
    8000109c:	83e9                	srli	a5,a5,0x1a
    8000109e:	00b7f463          	bgeu	a5,a1,800010a6 <walkaddr+0xc>
    return 0;
    800010a2:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010a4:	8082                	ret
{
    800010a6:	1141                	addi	sp,sp,-16
    800010a8:	e406                	sd	ra,8(sp)
    800010aa:	e022                	sd	s0,0(sp)
    800010ac:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010ae:	4601                	li	a2,0
    800010b0:	00000097          	auipc	ra,0x0
    800010b4:	f44080e7          	jalr	-188(ra) # 80000ff4 <walk>
  if(pte == 0)
    800010b8:	c105                	beqz	a0,800010d8 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010ba:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010bc:	0117f693          	andi	a3,a5,17
    800010c0:	4745                	li	a4,17
    return 0;
    800010c2:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010c4:	00e68663          	beq	a3,a4,800010d0 <walkaddr+0x36>
}
    800010c8:	60a2                	ld	ra,8(sp)
    800010ca:	6402                	ld	s0,0(sp)
    800010cc:	0141                	addi	sp,sp,16
    800010ce:	8082                	ret
  pa = PTE2PA(*pte);
    800010d0:	00a7d513          	srli	a0,a5,0xa
    800010d4:	0532                	slli	a0,a0,0xc
  return pa;
    800010d6:	bfcd                	j	800010c8 <walkaddr+0x2e>
    return 0;
    800010d8:	4501                	li	a0,0
    800010da:	b7fd                	j	800010c8 <walkaddr+0x2e>

00000000800010dc <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010dc:	715d                	addi	sp,sp,-80
    800010de:	e486                	sd	ra,72(sp)
    800010e0:	e0a2                	sd	s0,64(sp)
    800010e2:	fc26                	sd	s1,56(sp)
    800010e4:	f84a                	sd	s2,48(sp)
    800010e6:	f44e                	sd	s3,40(sp)
    800010e8:	f052                	sd	s4,32(sp)
    800010ea:	ec56                	sd	s5,24(sp)
    800010ec:	e85a                	sd	s6,16(sp)
    800010ee:	e45e                	sd	s7,8(sp)
    800010f0:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010f2:	c205                	beqz	a2,80001112 <mappages+0x36>
    800010f4:	8aaa                	mv	s5,a0
    800010f6:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010f8:	77fd                	lui	a5,0xfffff
    800010fa:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010fe:	15fd                	addi	a1,a1,-1
    80001100:	00c589b3          	add	s3,a1,a2
    80001104:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    80001108:	8952                	mv	s2,s4
    8000110a:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000110e:	6b85                	lui	s7,0x1
    80001110:	a015                	j	80001134 <mappages+0x58>
    panic("mappages: size");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fc650513          	addi	a0,a0,-58 # 800080d8 <digits+0x98>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	42a080e7          	jalr	1066(ra) # 80000544 <panic>
      panic("mappages: remap");
    80001122:	00007517          	auipc	a0,0x7
    80001126:	fc650513          	addi	a0,a0,-58 # 800080e8 <digits+0xa8>
    8000112a:	fffff097          	auipc	ra,0xfffff
    8000112e:	41a080e7          	jalr	1050(ra) # 80000544 <panic>
    a += PGSIZE;
    80001132:	995e                	add	s2,s2,s7
  for(;;){
    80001134:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001138:	4605                	li	a2,1
    8000113a:	85ca                	mv	a1,s2
    8000113c:	8556                	mv	a0,s5
    8000113e:	00000097          	auipc	ra,0x0
    80001142:	eb6080e7          	jalr	-330(ra) # 80000ff4 <walk>
    80001146:	cd19                	beqz	a0,80001164 <mappages+0x88>
    if(*pte & PTE_V)
    80001148:	611c                	ld	a5,0(a0)
    8000114a:	8b85                	andi	a5,a5,1
    8000114c:	fbf9                	bnez	a5,80001122 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000114e:	80b1                	srli	s1,s1,0xc
    80001150:	04aa                	slli	s1,s1,0xa
    80001152:	0164e4b3          	or	s1,s1,s6
    80001156:	0014e493          	ori	s1,s1,1
    8000115a:	e104                	sd	s1,0(a0)
    if(a == last)
    8000115c:	fd391be3          	bne	s2,s3,80001132 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001160:	4501                	li	a0,0
    80001162:	a011                	j	80001166 <mappages+0x8a>
      return -1;
    80001164:	557d                	li	a0,-1
}
    80001166:	60a6                	ld	ra,72(sp)
    80001168:	6406                	ld	s0,64(sp)
    8000116a:	74e2                	ld	s1,56(sp)
    8000116c:	7942                	ld	s2,48(sp)
    8000116e:	79a2                	ld	s3,40(sp)
    80001170:	7a02                	ld	s4,32(sp)
    80001172:	6ae2                	ld	s5,24(sp)
    80001174:	6b42                	ld	s6,16(sp)
    80001176:	6ba2                	ld	s7,8(sp)
    80001178:	6161                	addi	sp,sp,80
    8000117a:	8082                	ret

000000008000117c <kvmmap>:
{
    8000117c:	1141                	addi	sp,sp,-16
    8000117e:	e406                	sd	ra,8(sp)
    80001180:	e022                	sd	s0,0(sp)
    80001182:	0800                	addi	s0,sp,16
    80001184:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001186:	86b2                	mv	a3,a2
    80001188:	863e                	mv	a2,a5
    8000118a:	00000097          	auipc	ra,0x0
    8000118e:	f52080e7          	jalr	-174(ra) # 800010dc <mappages>
    80001192:	e509                	bnez	a0,8000119c <kvmmap+0x20>
}
    80001194:	60a2                	ld	ra,8(sp)
    80001196:	6402                	ld	s0,0(sp)
    80001198:	0141                	addi	sp,sp,16
    8000119a:	8082                	ret
    panic("kvmmap");
    8000119c:	00007517          	auipc	a0,0x7
    800011a0:	f5c50513          	addi	a0,a0,-164 # 800080f8 <digits+0xb8>
    800011a4:	fffff097          	auipc	ra,0xfffff
    800011a8:	3a0080e7          	jalr	928(ra) # 80000544 <panic>

00000000800011ac <kvmmake>:
{
    800011ac:	1101                	addi	sp,sp,-32
    800011ae:	ec06                	sd	ra,24(sp)
    800011b0:	e822                	sd	s0,16(sp)
    800011b2:	e426                	sd	s1,8(sp)
    800011b4:	e04a                	sd	s2,0(sp)
    800011b6:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800011b8:	00000097          	auipc	ra,0x0
    800011bc:	942080e7          	jalr	-1726(ra) # 80000afa <kalloc>
    800011c0:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011c2:	6605                	lui	a2,0x1
    800011c4:	4581                	li	a1,0
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	b42080e7          	jalr	-1214(ra) # 80000d08 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	6685                	lui	a3,0x1
    800011d2:	10000637          	lui	a2,0x10000
    800011d6:	100005b7          	lui	a1,0x10000
    800011da:	8526                	mv	a0,s1
    800011dc:	00000097          	auipc	ra,0x0
    800011e0:	fa0080e7          	jalr	-96(ra) # 8000117c <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011e4:	4719                	li	a4,6
    800011e6:	6685                	lui	a3,0x1
    800011e8:	10001637          	lui	a2,0x10001
    800011ec:	100015b7          	lui	a1,0x10001
    800011f0:	8526                	mv	a0,s1
    800011f2:	00000097          	auipc	ra,0x0
    800011f6:	f8a080e7          	jalr	-118(ra) # 8000117c <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011fa:	4719                	li	a4,6
    800011fc:	004006b7          	lui	a3,0x400
    80001200:	0c000637          	lui	a2,0xc000
    80001204:	0c0005b7          	lui	a1,0xc000
    80001208:	8526                	mv	a0,s1
    8000120a:	00000097          	auipc	ra,0x0
    8000120e:	f72080e7          	jalr	-142(ra) # 8000117c <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001212:	00007917          	auipc	s2,0x7
    80001216:	dee90913          	addi	s2,s2,-530 # 80008000 <etext>
    8000121a:	4729                	li	a4,10
    8000121c:	80007697          	auipc	a3,0x80007
    80001220:	de468693          	addi	a3,a3,-540 # 8000 <_entry-0x7fff8000>
    80001224:	4605                	li	a2,1
    80001226:	067e                	slli	a2,a2,0x1f
    80001228:	85b2                	mv	a1,a2
    8000122a:	8526                	mv	a0,s1
    8000122c:	00000097          	auipc	ra,0x0
    80001230:	f50080e7          	jalr	-176(ra) # 8000117c <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001234:	4719                	li	a4,6
    80001236:	46c5                	li	a3,17
    80001238:	06ee                	slli	a3,a3,0x1b
    8000123a:	412686b3          	sub	a3,a3,s2
    8000123e:	864a                	mv	a2,s2
    80001240:	85ca                	mv	a1,s2
    80001242:	8526                	mv	a0,s1
    80001244:	00000097          	auipc	ra,0x0
    80001248:	f38080e7          	jalr	-200(ra) # 8000117c <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000124c:	4729                	li	a4,10
    8000124e:	6685                	lui	a3,0x1
    80001250:	00006617          	auipc	a2,0x6
    80001254:	db060613          	addi	a2,a2,-592 # 80007000 <_trampoline>
    80001258:	040005b7          	lui	a1,0x4000
    8000125c:	15fd                	addi	a1,a1,-1
    8000125e:	05b2                	slli	a1,a1,0xc
    80001260:	8526                	mv	a0,s1
    80001262:	00000097          	auipc	ra,0x0
    80001266:	f1a080e7          	jalr	-230(ra) # 8000117c <kvmmap>
  proc_mapstacks(kpgtbl);
    8000126a:	8526                	mv	a0,s1
    8000126c:	00000097          	auipc	ra,0x0
    80001270:	606080e7          	jalr	1542(ra) # 80001872 <proc_mapstacks>
}
    80001274:	8526                	mv	a0,s1
    80001276:	60e2                	ld	ra,24(sp)
    80001278:	6442                	ld	s0,16(sp)
    8000127a:	64a2                	ld	s1,8(sp)
    8000127c:	6902                	ld	s2,0(sp)
    8000127e:	6105                	addi	sp,sp,32
    80001280:	8082                	ret

0000000080001282 <kvminit>:
{
    80001282:	1141                	addi	sp,sp,-16
    80001284:	e406                	sd	ra,8(sp)
    80001286:	e022                	sd	s0,0(sp)
    80001288:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000128a:	00000097          	auipc	ra,0x0
    8000128e:	f22080e7          	jalr	-222(ra) # 800011ac <kvmmake>
    80001292:	00007797          	auipc	a5,0x7
    80001296:	6aa7b723          	sd	a0,1710(a5) # 80008940 <kernel_pagetable>
}
    8000129a:	60a2                	ld	ra,8(sp)
    8000129c:	6402                	ld	s0,0(sp)
    8000129e:	0141                	addi	sp,sp,16
    800012a0:	8082                	ret

00000000800012a2 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012a2:	715d                	addi	sp,sp,-80
    800012a4:	e486                	sd	ra,72(sp)
    800012a6:	e0a2                	sd	s0,64(sp)
    800012a8:	fc26                	sd	s1,56(sp)
    800012aa:	f84a                	sd	s2,48(sp)
    800012ac:	f44e                	sd	s3,40(sp)
    800012ae:	f052                	sd	s4,32(sp)
    800012b0:	ec56                	sd	s5,24(sp)
    800012b2:	e85a                	sd	s6,16(sp)
    800012b4:	e45e                	sd	s7,8(sp)
    800012b6:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012b8:	03459793          	slli	a5,a1,0x34
    800012bc:	e795                	bnez	a5,800012e8 <uvmunmap+0x46>
    800012be:	8a2a                	mv	s4,a0
    800012c0:	892e                	mv	s2,a1
    800012c2:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012c4:	0632                	slli	a2,a2,0xc
    800012c6:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012ca:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012cc:	6b05                	lui	s6,0x1
    800012ce:	0735e863          	bltu	a1,s3,8000133e <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012d2:	60a6                	ld	ra,72(sp)
    800012d4:	6406                	ld	s0,64(sp)
    800012d6:	74e2                	ld	s1,56(sp)
    800012d8:	7942                	ld	s2,48(sp)
    800012da:	79a2                	ld	s3,40(sp)
    800012dc:	7a02                	ld	s4,32(sp)
    800012de:	6ae2                	ld	s5,24(sp)
    800012e0:	6b42                	ld	s6,16(sp)
    800012e2:	6ba2                	ld	s7,8(sp)
    800012e4:	6161                	addi	sp,sp,80
    800012e6:	8082                	ret
    panic("uvmunmap: not aligned");
    800012e8:	00007517          	auipc	a0,0x7
    800012ec:	e1850513          	addi	a0,a0,-488 # 80008100 <digits+0xc0>
    800012f0:	fffff097          	auipc	ra,0xfffff
    800012f4:	254080e7          	jalr	596(ra) # 80000544 <panic>
      panic("uvmunmap: walk");
    800012f8:	00007517          	auipc	a0,0x7
    800012fc:	e2050513          	addi	a0,a0,-480 # 80008118 <digits+0xd8>
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	244080e7          	jalr	580(ra) # 80000544 <panic>
      panic("uvmunmap: not mapped");
    80001308:	00007517          	auipc	a0,0x7
    8000130c:	e2050513          	addi	a0,a0,-480 # 80008128 <digits+0xe8>
    80001310:	fffff097          	auipc	ra,0xfffff
    80001314:	234080e7          	jalr	564(ra) # 80000544 <panic>
      panic("uvmunmap: not a leaf");
    80001318:	00007517          	auipc	a0,0x7
    8000131c:	e2850513          	addi	a0,a0,-472 # 80008140 <digits+0x100>
    80001320:	fffff097          	auipc	ra,0xfffff
    80001324:	224080e7          	jalr	548(ra) # 80000544 <panic>
      uint64 pa = PTE2PA(*pte);
    80001328:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000132a:	0532                	slli	a0,a0,0xc
    8000132c:	fffff097          	auipc	ra,0xfffff
    80001330:	6d2080e7          	jalr	1746(ra) # 800009fe <kfree>
    *pte = 0;
    80001334:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001338:	995a                	add	s2,s2,s6
    8000133a:	f9397ce3          	bgeu	s2,s3,800012d2 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000133e:	4601                	li	a2,0
    80001340:	85ca                	mv	a1,s2
    80001342:	8552                	mv	a0,s4
    80001344:	00000097          	auipc	ra,0x0
    80001348:	cb0080e7          	jalr	-848(ra) # 80000ff4 <walk>
    8000134c:	84aa                	mv	s1,a0
    8000134e:	d54d                	beqz	a0,800012f8 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001350:	6108                	ld	a0,0(a0)
    80001352:	00157793          	andi	a5,a0,1
    80001356:	dbcd                	beqz	a5,80001308 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001358:	3ff57793          	andi	a5,a0,1023
    8000135c:	fb778ee3          	beq	a5,s7,80001318 <uvmunmap+0x76>
    if(do_free){
    80001360:	fc0a8ae3          	beqz	s5,80001334 <uvmunmap+0x92>
    80001364:	b7d1                	j	80001328 <uvmunmap+0x86>

0000000080001366 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001366:	1101                	addi	sp,sp,-32
    80001368:	ec06                	sd	ra,24(sp)
    8000136a:	e822                	sd	s0,16(sp)
    8000136c:	e426                	sd	s1,8(sp)
    8000136e:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001370:	fffff097          	auipc	ra,0xfffff
    80001374:	78a080e7          	jalr	1930(ra) # 80000afa <kalloc>
    80001378:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000137a:	c519                	beqz	a0,80001388 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	988080e7          	jalr	-1656(ra) # 80000d08 <memset>
  return pagetable;
}
    80001388:	8526                	mv	a0,s1
    8000138a:	60e2                	ld	ra,24(sp)
    8000138c:	6442                	ld	s0,16(sp)
    8000138e:	64a2                	ld	s1,8(sp)
    80001390:	6105                	addi	sp,sp,32
    80001392:	8082                	ret

0000000080001394 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001394:	7179                	addi	sp,sp,-48
    80001396:	f406                	sd	ra,40(sp)
    80001398:	f022                	sd	s0,32(sp)
    8000139a:	ec26                	sd	s1,24(sp)
    8000139c:	e84a                	sd	s2,16(sp)
    8000139e:	e44e                	sd	s3,8(sp)
    800013a0:	e052                	sd	s4,0(sp)
    800013a2:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013a4:	6785                	lui	a5,0x1
    800013a6:	04f67863          	bgeu	a2,a5,800013f6 <uvmfirst+0x62>
    800013aa:	8a2a                	mv	s4,a0
    800013ac:	89ae                	mv	s3,a1
    800013ae:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800013b0:	fffff097          	auipc	ra,0xfffff
    800013b4:	74a080e7          	jalr	1866(ra) # 80000afa <kalloc>
    800013b8:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013ba:	6605                	lui	a2,0x1
    800013bc:	4581                	li	a1,0
    800013be:	00000097          	auipc	ra,0x0
    800013c2:	94a080e7          	jalr	-1718(ra) # 80000d08 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013c6:	4779                	li	a4,30
    800013c8:	86ca                	mv	a3,s2
    800013ca:	6605                	lui	a2,0x1
    800013cc:	4581                	li	a1,0
    800013ce:	8552                	mv	a0,s4
    800013d0:	00000097          	auipc	ra,0x0
    800013d4:	d0c080e7          	jalr	-756(ra) # 800010dc <mappages>
  memmove(mem, src, sz);
    800013d8:	8626                	mv	a2,s1
    800013da:	85ce                	mv	a1,s3
    800013dc:	854a                	mv	a0,s2
    800013de:	00000097          	auipc	ra,0x0
    800013e2:	98a080e7          	jalr	-1654(ra) # 80000d68 <memmove>
}
    800013e6:	70a2                	ld	ra,40(sp)
    800013e8:	7402                	ld	s0,32(sp)
    800013ea:	64e2                	ld	s1,24(sp)
    800013ec:	6942                	ld	s2,16(sp)
    800013ee:	69a2                	ld	s3,8(sp)
    800013f0:	6a02                	ld	s4,0(sp)
    800013f2:	6145                	addi	sp,sp,48
    800013f4:	8082                	ret
    panic("uvmfirst: more than a page");
    800013f6:	00007517          	auipc	a0,0x7
    800013fa:	d6250513          	addi	a0,a0,-670 # 80008158 <digits+0x118>
    800013fe:	fffff097          	auipc	ra,0xfffff
    80001402:	146080e7          	jalr	326(ra) # 80000544 <panic>

0000000080001406 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001406:	1101                	addi	sp,sp,-32
    80001408:	ec06                	sd	ra,24(sp)
    8000140a:	e822                	sd	s0,16(sp)
    8000140c:	e426                	sd	s1,8(sp)
    8000140e:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001410:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001412:	00b67d63          	bgeu	a2,a1,8000142c <uvmdealloc+0x26>
    80001416:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001418:	6785                	lui	a5,0x1
    8000141a:	17fd                	addi	a5,a5,-1
    8000141c:	00f60733          	add	a4,a2,a5
    80001420:	767d                	lui	a2,0xfffff
    80001422:	8f71                	and	a4,a4,a2
    80001424:	97ae                	add	a5,a5,a1
    80001426:	8ff1                	and	a5,a5,a2
    80001428:	00f76863          	bltu	a4,a5,80001438 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000142c:	8526                	mv	a0,s1
    8000142e:	60e2                	ld	ra,24(sp)
    80001430:	6442                	ld	s0,16(sp)
    80001432:	64a2                	ld	s1,8(sp)
    80001434:	6105                	addi	sp,sp,32
    80001436:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001438:	8f99                	sub	a5,a5,a4
    8000143a:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000143c:	4685                	li	a3,1
    8000143e:	0007861b          	sext.w	a2,a5
    80001442:	85ba                	mv	a1,a4
    80001444:	00000097          	auipc	ra,0x0
    80001448:	e5e080e7          	jalr	-418(ra) # 800012a2 <uvmunmap>
    8000144c:	b7c5                	j	8000142c <uvmdealloc+0x26>

000000008000144e <uvmalloc>:
  if(newsz < oldsz)
    8000144e:	0ab66563          	bltu	a2,a1,800014f8 <uvmalloc+0xaa>
{
    80001452:	7139                	addi	sp,sp,-64
    80001454:	fc06                	sd	ra,56(sp)
    80001456:	f822                	sd	s0,48(sp)
    80001458:	f426                	sd	s1,40(sp)
    8000145a:	f04a                	sd	s2,32(sp)
    8000145c:	ec4e                	sd	s3,24(sp)
    8000145e:	e852                	sd	s4,16(sp)
    80001460:	e456                	sd	s5,8(sp)
    80001462:	e05a                	sd	s6,0(sp)
    80001464:	0080                	addi	s0,sp,64
    80001466:	8aaa                	mv	s5,a0
    80001468:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000146a:	6985                	lui	s3,0x1
    8000146c:	19fd                	addi	s3,s3,-1
    8000146e:	95ce                	add	a1,a1,s3
    80001470:	79fd                	lui	s3,0xfffff
    80001472:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001476:	08c9f363          	bgeu	s3,a2,800014fc <uvmalloc+0xae>
    8000147a:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000147c:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001480:	fffff097          	auipc	ra,0xfffff
    80001484:	67a080e7          	jalr	1658(ra) # 80000afa <kalloc>
    80001488:	84aa                	mv	s1,a0
    if(mem == 0){
    8000148a:	c51d                	beqz	a0,800014b8 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000148c:	6605                	lui	a2,0x1
    8000148e:	4581                	li	a1,0
    80001490:	00000097          	auipc	ra,0x0
    80001494:	878080e7          	jalr	-1928(ra) # 80000d08 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001498:	875a                	mv	a4,s6
    8000149a:	86a6                	mv	a3,s1
    8000149c:	6605                	lui	a2,0x1
    8000149e:	85ca                	mv	a1,s2
    800014a0:	8556                	mv	a0,s5
    800014a2:	00000097          	auipc	ra,0x0
    800014a6:	c3a080e7          	jalr	-966(ra) # 800010dc <mappages>
    800014aa:	e90d                	bnez	a0,800014dc <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014ac:	6785                	lui	a5,0x1
    800014ae:	993e                	add	s2,s2,a5
    800014b0:	fd4968e3          	bltu	s2,s4,80001480 <uvmalloc+0x32>
  return newsz;
    800014b4:	8552                	mv	a0,s4
    800014b6:	a809                	j	800014c8 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    800014b8:	864e                	mv	a2,s3
    800014ba:	85ca                	mv	a1,s2
    800014bc:	8556                	mv	a0,s5
    800014be:	00000097          	auipc	ra,0x0
    800014c2:	f48080e7          	jalr	-184(ra) # 80001406 <uvmdealloc>
      return 0;
    800014c6:	4501                	li	a0,0
}
    800014c8:	70e2                	ld	ra,56(sp)
    800014ca:	7442                	ld	s0,48(sp)
    800014cc:	74a2                	ld	s1,40(sp)
    800014ce:	7902                	ld	s2,32(sp)
    800014d0:	69e2                	ld	s3,24(sp)
    800014d2:	6a42                	ld	s4,16(sp)
    800014d4:	6aa2                	ld	s5,8(sp)
    800014d6:	6b02                	ld	s6,0(sp)
    800014d8:	6121                	addi	sp,sp,64
    800014da:	8082                	ret
      kfree(mem);
    800014dc:	8526                	mv	a0,s1
    800014de:	fffff097          	auipc	ra,0xfffff
    800014e2:	520080e7          	jalr	1312(ra) # 800009fe <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014e6:	864e                	mv	a2,s3
    800014e8:	85ca                	mv	a1,s2
    800014ea:	8556                	mv	a0,s5
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	f1a080e7          	jalr	-230(ra) # 80001406 <uvmdealloc>
      return 0;
    800014f4:	4501                	li	a0,0
    800014f6:	bfc9                	j	800014c8 <uvmalloc+0x7a>
    return oldsz;
    800014f8:	852e                	mv	a0,a1
}
    800014fa:	8082                	ret
  return newsz;
    800014fc:	8532                	mv	a0,a2
    800014fe:	b7e9                	j	800014c8 <uvmalloc+0x7a>

0000000080001500 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001500:	7179                	addi	sp,sp,-48
    80001502:	f406                	sd	ra,40(sp)
    80001504:	f022                	sd	s0,32(sp)
    80001506:	ec26                	sd	s1,24(sp)
    80001508:	e84a                	sd	s2,16(sp)
    8000150a:	e44e                	sd	s3,8(sp)
    8000150c:	e052                	sd	s4,0(sp)
    8000150e:	1800                	addi	s0,sp,48
    80001510:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001512:	84aa                	mv	s1,a0
    80001514:	6905                	lui	s2,0x1
    80001516:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001518:	4985                	li	s3,1
    8000151a:	a821                	j	80001532 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000151c:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000151e:	0532                	slli	a0,a0,0xc
    80001520:	00000097          	auipc	ra,0x0
    80001524:	fe0080e7          	jalr	-32(ra) # 80001500 <freewalk>
      pagetable[i] = 0;
    80001528:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000152c:	04a1                	addi	s1,s1,8
    8000152e:	03248163          	beq	s1,s2,80001550 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001532:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001534:	00f57793          	andi	a5,a0,15
    80001538:	ff3782e3          	beq	a5,s3,8000151c <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000153c:	8905                	andi	a0,a0,1
    8000153e:	d57d                	beqz	a0,8000152c <freewalk+0x2c>
      panic("freewalk: leaf");
    80001540:	00007517          	auipc	a0,0x7
    80001544:	c3850513          	addi	a0,a0,-968 # 80008178 <digits+0x138>
    80001548:	fffff097          	auipc	ra,0xfffff
    8000154c:	ffc080e7          	jalr	-4(ra) # 80000544 <panic>
    }
  }
  kfree((void*)pagetable);
    80001550:	8552                	mv	a0,s4
    80001552:	fffff097          	auipc	ra,0xfffff
    80001556:	4ac080e7          	jalr	1196(ra) # 800009fe <kfree>
}
    8000155a:	70a2                	ld	ra,40(sp)
    8000155c:	7402                	ld	s0,32(sp)
    8000155e:	64e2                	ld	s1,24(sp)
    80001560:	6942                	ld	s2,16(sp)
    80001562:	69a2                	ld	s3,8(sp)
    80001564:	6a02                	ld	s4,0(sp)
    80001566:	6145                	addi	sp,sp,48
    80001568:	8082                	ret

000000008000156a <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000156a:	1101                	addi	sp,sp,-32
    8000156c:	ec06                	sd	ra,24(sp)
    8000156e:	e822                	sd	s0,16(sp)
    80001570:	e426                	sd	s1,8(sp)
    80001572:	1000                	addi	s0,sp,32
    80001574:	84aa                	mv	s1,a0
  if(sz > 0)
    80001576:	e999                	bnez	a1,8000158c <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001578:	8526                	mv	a0,s1
    8000157a:	00000097          	auipc	ra,0x0
    8000157e:	f86080e7          	jalr	-122(ra) # 80001500 <freewalk>
}
    80001582:	60e2                	ld	ra,24(sp)
    80001584:	6442                	ld	s0,16(sp)
    80001586:	64a2                	ld	s1,8(sp)
    80001588:	6105                	addi	sp,sp,32
    8000158a:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000158c:	6605                	lui	a2,0x1
    8000158e:	167d                	addi	a2,a2,-1
    80001590:	962e                	add	a2,a2,a1
    80001592:	4685                	li	a3,1
    80001594:	8231                	srli	a2,a2,0xc
    80001596:	4581                	li	a1,0
    80001598:	00000097          	auipc	ra,0x0
    8000159c:	d0a080e7          	jalr	-758(ra) # 800012a2 <uvmunmap>
    800015a0:	bfe1                	j	80001578 <uvmfree+0xe>

00000000800015a2 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015a2:	c679                	beqz	a2,80001670 <uvmcopy+0xce>
{
    800015a4:	715d                	addi	sp,sp,-80
    800015a6:	e486                	sd	ra,72(sp)
    800015a8:	e0a2                	sd	s0,64(sp)
    800015aa:	fc26                	sd	s1,56(sp)
    800015ac:	f84a                	sd	s2,48(sp)
    800015ae:	f44e                	sd	s3,40(sp)
    800015b0:	f052                	sd	s4,32(sp)
    800015b2:	ec56                	sd	s5,24(sp)
    800015b4:	e85a                	sd	s6,16(sp)
    800015b6:	e45e                	sd	s7,8(sp)
    800015b8:	0880                	addi	s0,sp,80
    800015ba:	8b2a                	mv	s6,a0
    800015bc:	8aae                	mv	s5,a1
    800015be:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015c0:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015c2:	4601                	li	a2,0
    800015c4:	85ce                	mv	a1,s3
    800015c6:	855a                	mv	a0,s6
    800015c8:	00000097          	auipc	ra,0x0
    800015cc:	a2c080e7          	jalr	-1492(ra) # 80000ff4 <walk>
    800015d0:	c531                	beqz	a0,8000161c <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015d2:	6118                	ld	a4,0(a0)
    800015d4:	00177793          	andi	a5,a4,1
    800015d8:	cbb1                	beqz	a5,8000162c <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015da:	00a75593          	srli	a1,a4,0xa
    800015de:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015e2:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015e6:	fffff097          	auipc	ra,0xfffff
    800015ea:	514080e7          	jalr	1300(ra) # 80000afa <kalloc>
    800015ee:	892a                	mv	s2,a0
    800015f0:	c939                	beqz	a0,80001646 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015f2:	6605                	lui	a2,0x1
    800015f4:	85de                	mv	a1,s7
    800015f6:	fffff097          	auipc	ra,0xfffff
    800015fa:	772080e7          	jalr	1906(ra) # 80000d68 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015fe:	8726                	mv	a4,s1
    80001600:	86ca                	mv	a3,s2
    80001602:	6605                	lui	a2,0x1
    80001604:	85ce                	mv	a1,s3
    80001606:	8556                	mv	a0,s5
    80001608:	00000097          	auipc	ra,0x0
    8000160c:	ad4080e7          	jalr	-1324(ra) # 800010dc <mappages>
    80001610:	e515                	bnez	a0,8000163c <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001612:	6785                	lui	a5,0x1
    80001614:	99be                	add	s3,s3,a5
    80001616:	fb49e6e3          	bltu	s3,s4,800015c2 <uvmcopy+0x20>
    8000161a:	a081                	j	8000165a <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000161c:	00007517          	auipc	a0,0x7
    80001620:	b6c50513          	addi	a0,a0,-1172 # 80008188 <digits+0x148>
    80001624:	fffff097          	auipc	ra,0xfffff
    80001628:	f20080e7          	jalr	-224(ra) # 80000544 <panic>
      panic("uvmcopy: page not present");
    8000162c:	00007517          	auipc	a0,0x7
    80001630:	b7c50513          	addi	a0,a0,-1156 # 800081a8 <digits+0x168>
    80001634:	fffff097          	auipc	ra,0xfffff
    80001638:	f10080e7          	jalr	-240(ra) # 80000544 <panic>
      kfree(mem);
    8000163c:	854a                	mv	a0,s2
    8000163e:	fffff097          	auipc	ra,0xfffff
    80001642:	3c0080e7          	jalr	960(ra) # 800009fe <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001646:	4685                	li	a3,1
    80001648:	00c9d613          	srli	a2,s3,0xc
    8000164c:	4581                	li	a1,0
    8000164e:	8556                	mv	a0,s5
    80001650:	00000097          	auipc	ra,0x0
    80001654:	c52080e7          	jalr	-942(ra) # 800012a2 <uvmunmap>
  return -1;
    80001658:	557d                	li	a0,-1
}
    8000165a:	60a6                	ld	ra,72(sp)
    8000165c:	6406                	ld	s0,64(sp)
    8000165e:	74e2                	ld	s1,56(sp)
    80001660:	7942                	ld	s2,48(sp)
    80001662:	79a2                	ld	s3,40(sp)
    80001664:	7a02                	ld	s4,32(sp)
    80001666:	6ae2                	ld	s5,24(sp)
    80001668:	6b42                	ld	s6,16(sp)
    8000166a:	6ba2                	ld	s7,8(sp)
    8000166c:	6161                	addi	sp,sp,80
    8000166e:	8082                	ret
  return 0;
    80001670:	4501                	li	a0,0
}
    80001672:	8082                	ret

0000000080001674 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001674:	1141                	addi	sp,sp,-16
    80001676:	e406                	sd	ra,8(sp)
    80001678:	e022                	sd	s0,0(sp)
    8000167a:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000167c:	4601                	li	a2,0
    8000167e:	00000097          	auipc	ra,0x0
    80001682:	976080e7          	jalr	-1674(ra) # 80000ff4 <walk>
  if(pte == 0)
    80001686:	c901                	beqz	a0,80001696 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001688:	611c                	ld	a5,0(a0)
    8000168a:	9bbd                	andi	a5,a5,-17
    8000168c:	e11c                	sd	a5,0(a0)
}
    8000168e:	60a2                	ld	ra,8(sp)
    80001690:	6402                	ld	s0,0(sp)
    80001692:	0141                	addi	sp,sp,16
    80001694:	8082                	ret
    panic("uvmclear");
    80001696:	00007517          	auipc	a0,0x7
    8000169a:	b3250513          	addi	a0,a0,-1230 # 800081c8 <digits+0x188>
    8000169e:	fffff097          	auipc	ra,0xfffff
    800016a2:	ea6080e7          	jalr	-346(ra) # 80000544 <panic>

00000000800016a6 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016a6:	c6bd                	beqz	a3,80001714 <copyout+0x6e>
{
    800016a8:	715d                	addi	sp,sp,-80
    800016aa:	e486                	sd	ra,72(sp)
    800016ac:	e0a2                	sd	s0,64(sp)
    800016ae:	fc26                	sd	s1,56(sp)
    800016b0:	f84a                	sd	s2,48(sp)
    800016b2:	f44e                	sd	s3,40(sp)
    800016b4:	f052                	sd	s4,32(sp)
    800016b6:	ec56                	sd	s5,24(sp)
    800016b8:	e85a                	sd	s6,16(sp)
    800016ba:	e45e                	sd	s7,8(sp)
    800016bc:	e062                	sd	s8,0(sp)
    800016be:	0880                	addi	s0,sp,80
    800016c0:	8b2a                	mv	s6,a0
    800016c2:	8c2e                	mv	s8,a1
    800016c4:	8a32                	mv	s4,a2
    800016c6:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016c8:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016ca:	6a85                	lui	s5,0x1
    800016cc:	a015                	j	800016f0 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016ce:	9562                	add	a0,a0,s8
    800016d0:	0004861b          	sext.w	a2,s1
    800016d4:	85d2                	mv	a1,s4
    800016d6:	41250533          	sub	a0,a0,s2
    800016da:	fffff097          	auipc	ra,0xfffff
    800016de:	68e080e7          	jalr	1678(ra) # 80000d68 <memmove>

    len -= n;
    800016e2:	409989b3          	sub	s3,s3,s1
    src += n;
    800016e6:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016e8:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ec:	02098263          	beqz	s3,80001710 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016f0:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016f4:	85ca                	mv	a1,s2
    800016f6:	855a                	mv	a0,s6
    800016f8:	00000097          	auipc	ra,0x0
    800016fc:	9a2080e7          	jalr	-1630(ra) # 8000109a <walkaddr>
    if(pa0 == 0)
    80001700:	cd01                	beqz	a0,80001718 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001702:	418904b3          	sub	s1,s2,s8
    80001706:	94d6                	add	s1,s1,s5
    if(n > len)
    80001708:	fc99f3e3          	bgeu	s3,s1,800016ce <copyout+0x28>
    8000170c:	84ce                	mv	s1,s3
    8000170e:	b7c1                	j	800016ce <copyout+0x28>
  }
  return 0;
    80001710:	4501                	li	a0,0
    80001712:	a021                	j	8000171a <copyout+0x74>
    80001714:	4501                	li	a0,0
}
    80001716:	8082                	ret
      return -1;
    80001718:	557d                	li	a0,-1
}
    8000171a:	60a6                	ld	ra,72(sp)
    8000171c:	6406                	ld	s0,64(sp)
    8000171e:	74e2                	ld	s1,56(sp)
    80001720:	7942                	ld	s2,48(sp)
    80001722:	79a2                	ld	s3,40(sp)
    80001724:	7a02                	ld	s4,32(sp)
    80001726:	6ae2                	ld	s5,24(sp)
    80001728:	6b42                	ld	s6,16(sp)
    8000172a:	6ba2                	ld	s7,8(sp)
    8000172c:	6c02                	ld	s8,0(sp)
    8000172e:	6161                	addi	sp,sp,80
    80001730:	8082                	ret

0000000080001732 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001732:	c6bd                	beqz	a3,800017a0 <copyin+0x6e>
{
    80001734:	715d                	addi	sp,sp,-80
    80001736:	e486                	sd	ra,72(sp)
    80001738:	e0a2                	sd	s0,64(sp)
    8000173a:	fc26                	sd	s1,56(sp)
    8000173c:	f84a                	sd	s2,48(sp)
    8000173e:	f44e                	sd	s3,40(sp)
    80001740:	f052                	sd	s4,32(sp)
    80001742:	ec56                	sd	s5,24(sp)
    80001744:	e85a                	sd	s6,16(sp)
    80001746:	e45e                	sd	s7,8(sp)
    80001748:	e062                	sd	s8,0(sp)
    8000174a:	0880                	addi	s0,sp,80
    8000174c:	8b2a                	mv	s6,a0
    8000174e:	8a2e                	mv	s4,a1
    80001750:	8c32                	mv	s8,a2
    80001752:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001754:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001756:	6a85                	lui	s5,0x1
    80001758:	a015                	j	8000177c <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000175a:	9562                	add	a0,a0,s8
    8000175c:	0004861b          	sext.w	a2,s1
    80001760:	412505b3          	sub	a1,a0,s2
    80001764:	8552                	mv	a0,s4
    80001766:	fffff097          	auipc	ra,0xfffff
    8000176a:	602080e7          	jalr	1538(ra) # 80000d68 <memmove>

    len -= n;
    8000176e:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001772:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001774:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001778:	02098263          	beqz	s3,8000179c <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000177c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001780:	85ca                	mv	a1,s2
    80001782:	855a                	mv	a0,s6
    80001784:	00000097          	auipc	ra,0x0
    80001788:	916080e7          	jalr	-1770(ra) # 8000109a <walkaddr>
    if(pa0 == 0)
    8000178c:	cd01                	beqz	a0,800017a4 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000178e:	418904b3          	sub	s1,s2,s8
    80001792:	94d6                	add	s1,s1,s5
    if(n > len)
    80001794:	fc99f3e3          	bgeu	s3,s1,8000175a <copyin+0x28>
    80001798:	84ce                	mv	s1,s3
    8000179a:	b7c1                	j	8000175a <copyin+0x28>
  }
  return 0;
    8000179c:	4501                	li	a0,0
    8000179e:	a021                	j	800017a6 <copyin+0x74>
    800017a0:	4501                	li	a0,0
}
    800017a2:	8082                	ret
      return -1;
    800017a4:	557d                	li	a0,-1
}
    800017a6:	60a6                	ld	ra,72(sp)
    800017a8:	6406                	ld	s0,64(sp)
    800017aa:	74e2                	ld	s1,56(sp)
    800017ac:	7942                	ld	s2,48(sp)
    800017ae:	79a2                	ld	s3,40(sp)
    800017b0:	7a02                	ld	s4,32(sp)
    800017b2:	6ae2                	ld	s5,24(sp)
    800017b4:	6b42                	ld	s6,16(sp)
    800017b6:	6ba2                	ld	s7,8(sp)
    800017b8:	6c02                	ld	s8,0(sp)
    800017ba:	6161                	addi	sp,sp,80
    800017bc:	8082                	ret

00000000800017be <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017be:	c6c5                	beqz	a3,80001866 <copyinstr+0xa8>
{
    800017c0:	715d                	addi	sp,sp,-80
    800017c2:	e486                	sd	ra,72(sp)
    800017c4:	e0a2                	sd	s0,64(sp)
    800017c6:	fc26                	sd	s1,56(sp)
    800017c8:	f84a                	sd	s2,48(sp)
    800017ca:	f44e                	sd	s3,40(sp)
    800017cc:	f052                	sd	s4,32(sp)
    800017ce:	ec56                	sd	s5,24(sp)
    800017d0:	e85a                	sd	s6,16(sp)
    800017d2:	e45e                	sd	s7,8(sp)
    800017d4:	0880                	addi	s0,sp,80
    800017d6:	8a2a                	mv	s4,a0
    800017d8:	8b2e                	mv	s6,a1
    800017da:	8bb2                	mv	s7,a2
    800017dc:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017de:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017e0:	6985                	lui	s3,0x1
    800017e2:	a035                	j	8000180e <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017e4:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017e8:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017ea:	0017b793          	seqz	a5,a5
    800017ee:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017f2:	60a6                	ld	ra,72(sp)
    800017f4:	6406                	ld	s0,64(sp)
    800017f6:	74e2                	ld	s1,56(sp)
    800017f8:	7942                	ld	s2,48(sp)
    800017fa:	79a2                	ld	s3,40(sp)
    800017fc:	7a02                	ld	s4,32(sp)
    800017fe:	6ae2                	ld	s5,24(sp)
    80001800:	6b42                	ld	s6,16(sp)
    80001802:	6ba2                	ld	s7,8(sp)
    80001804:	6161                	addi	sp,sp,80
    80001806:	8082                	ret
    srcva = va0 + PGSIZE;
    80001808:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000180c:	c8a9                	beqz	s1,8000185e <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000180e:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001812:	85ca                	mv	a1,s2
    80001814:	8552                	mv	a0,s4
    80001816:	00000097          	auipc	ra,0x0
    8000181a:	884080e7          	jalr	-1916(ra) # 8000109a <walkaddr>
    if(pa0 == 0)
    8000181e:	c131                	beqz	a0,80001862 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001820:	41790833          	sub	a6,s2,s7
    80001824:	984e                	add	a6,a6,s3
    if(n > max)
    80001826:	0104f363          	bgeu	s1,a6,8000182c <copyinstr+0x6e>
    8000182a:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000182c:	955e                	add	a0,a0,s7
    8000182e:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001832:	fc080be3          	beqz	a6,80001808 <copyinstr+0x4a>
    80001836:	985a                	add	a6,a6,s6
    80001838:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000183a:	41650633          	sub	a2,a0,s6
    8000183e:	14fd                	addi	s1,s1,-1
    80001840:	9b26                	add	s6,s6,s1
    80001842:	00f60733          	add	a4,a2,a5
    80001846:	00074703          	lbu	a4,0(a4)
    8000184a:	df49                	beqz	a4,800017e4 <copyinstr+0x26>
        *dst = *p;
    8000184c:	00e78023          	sb	a4,0(a5)
      --max;
    80001850:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001854:	0785                	addi	a5,a5,1
    while(n > 0){
    80001856:	ff0796e3          	bne	a5,a6,80001842 <copyinstr+0x84>
      dst++;
    8000185a:	8b42                	mv	s6,a6
    8000185c:	b775                	j	80001808 <copyinstr+0x4a>
    8000185e:	4781                	li	a5,0
    80001860:	b769                	j	800017ea <copyinstr+0x2c>
      return -1;
    80001862:	557d                	li	a0,-1
    80001864:	b779                	j	800017f2 <copyinstr+0x34>
  int got_null = 0;
    80001866:	4781                	li	a5,0
  if(got_null){
    80001868:	0017b793          	seqz	a5,a5
    8000186c:	40f00533          	neg	a0,a5
}
    80001870:	8082                	ret

0000000080001872 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001872:	7139                	addi	sp,sp,-64
    80001874:	fc06                	sd	ra,56(sp)
    80001876:	f822                	sd	s0,48(sp)
    80001878:	f426                	sd	s1,40(sp)
    8000187a:	f04a                	sd	s2,32(sp)
    8000187c:	ec4e                	sd	s3,24(sp)
    8000187e:	e852                	sd	s4,16(sp)
    80001880:	e456                	sd	s5,8(sp)
    80001882:	e05a                	sd	s6,0(sp)
    80001884:	0080                	addi	s0,sp,64
    80001886:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001888:	00010497          	auipc	s1,0x10
    8000188c:	86848493          	addi	s1,s1,-1944 # 800110f0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001890:	8b26                	mv	s6,s1
    80001892:	00006a97          	auipc	s5,0x6
    80001896:	76ea8a93          	addi	s5,s5,1902 # 80008000 <etext>
    8000189a:	04000937          	lui	s2,0x4000
    8000189e:	197d                	addi	s2,s2,-1
    800018a0:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a2:	00015a17          	auipc	s4,0x15
    800018a6:	24ea0a13          	addi	s4,s4,590 # 80016af0 <tickslock>
    char *pa = kalloc();
    800018aa:	fffff097          	auipc	ra,0xfffff
    800018ae:	250080e7          	jalr	592(ra) # 80000afa <kalloc>
    800018b2:	862a                	mv	a2,a0
    if(pa == 0)
    800018b4:	c131                	beqz	a0,800018f8 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800018b6:	416485b3          	sub	a1,s1,s6
    800018ba:	858d                	srai	a1,a1,0x3
    800018bc:	000ab783          	ld	a5,0(s5)
    800018c0:	02f585b3          	mul	a1,a1,a5
    800018c4:	2585                	addiw	a1,a1,1
    800018c6:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018ca:	4719                	li	a4,6
    800018cc:	6685                	lui	a3,0x1
    800018ce:	40b905b3          	sub	a1,s2,a1
    800018d2:	854e                	mv	a0,s3
    800018d4:	00000097          	auipc	ra,0x0
    800018d8:	8a8080e7          	jalr	-1880(ra) # 8000117c <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018dc:	16848493          	addi	s1,s1,360
    800018e0:	fd4495e3          	bne	s1,s4,800018aa <proc_mapstacks+0x38>
  }
}
    800018e4:	70e2                	ld	ra,56(sp)
    800018e6:	7442                	ld	s0,48(sp)
    800018e8:	74a2                	ld	s1,40(sp)
    800018ea:	7902                	ld	s2,32(sp)
    800018ec:	69e2                	ld	s3,24(sp)
    800018ee:	6a42                	ld	s4,16(sp)
    800018f0:	6aa2                	ld	s5,8(sp)
    800018f2:	6b02                	ld	s6,0(sp)
    800018f4:	6121                	addi	sp,sp,64
    800018f6:	8082                	ret
      panic("kalloc");
    800018f8:	00007517          	auipc	a0,0x7
    800018fc:	8e050513          	addi	a0,a0,-1824 # 800081d8 <digits+0x198>
    80001900:	fffff097          	auipc	ra,0xfffff
    80001904:	c44080e7          	jalr	-956(ra) # 80000544 <panic>

0000000080001908 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001908:	7139                	addi	sp,sp,-64
    8000190a:	fc06                	sd	ra,56(sp)
    8000190c:	f822                	sd	s0,48(sp)
    8000190e:	f426                	sd	s1,40(sp)
    80001910:	f04a                	sd	s2,32(sp)
    80001912:	ec4e                	sd	s3,24(sp)
    80001914:	e852                	sd	s4,16(sp)
    80001916:	e456                	sd	s5,8(sp)
    80001918:	e05a                	sd	s6,0(sp)
    8000191a:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    8000191c:	00007597          	auipc	a1,0x7
    80001920:	8c458593          	addi	a1,a1,-1852 # 800081e0 <digits+0x1a0>
    80001924:	0000f517          	auipc	a0,0xf
    80001928:	29c50513          	addi	a0,a0,668 # 80010bc0 <pid_lock>
    8000192c:	fffff097          	auipc	ra,0xfffff
    80001930:	250080e7          	jalr	592(ra) # 80000b7c <initlock>
  initlock(&wait_lock, "wait_lock");
    80001934:	00007597          	auipc	a1,0x7
    80001938:	8b458593          	addi	a1,a1,-1868 # 800081e8 <digits+0x1a8>
    8000193c:	0000f517          	auipc	a0,0xf
    80001940:	29c50513          	addi	a0,a0,668 # 80010bd8 <wait_lock>
    80001944:	fffff097          	auipc	ra,0xfffff
    80001948:	238080e7          	jalr	568(ra) # 80000b7c <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194c:	0000f497          	auipc	s1,0xf
    80001950:	7a448493          	addi	s1,s1,1956 # 800110f0 <proc>
      initlock(&p->lock, "proc");
    80001954:	00007b17          	auipc	s6,0x7
    80001958:	8a4b0b13          	addi	s6,s6,-1884 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    8000195c:	8aa6                	mv	s5,s1
    8000195e:	00006a17          	auipc	s4,0x6
    80001962:	6a2a0a13          	addi	s4,s4,1698 # 80008000 <etext>
    80001966:	04000937          	lui	s2,0x4000
    8000196a:	197d                	addi	s2,s2,-1
    8000196c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000196e:	00015997          	auipc	s3,0x15
    80001972:	18298993          	addi	s3,s3,386 # 80016af0 <tickslock>
      initlock(&p->lock, "proc");
    80001976:	85da                	mv	a1,s6
    80001978:	8526                	mv	a0,s1
    8000197a:	fffff097          	auipc	ra,0xfffff
    8000197e:	202080e7          	jalr	514(ra) # 80000b7c <initlock>
      p->state = UNUSED;
    80001982:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001986:	415487b3          	sub	a5,s1,s5
    8000198a:	878d                	srai	a5,a5,0x3
    8000198c:	000a3703          	ld	a4,0(s4)
    80001990:	02e787b3          	mul	a5,a5,a4
    80001994:	2785                	addiw	a5,a5,1
    80001996:	00d7979b          	slliw	a5,a5,0xd
    8000199a:	40f907b3          	sub	a5,s2,a5
    8000199e:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019a0:	16848493          	addi	s1,s1,360
    800019a4:	fd3499e3          	bne	s1,s3,80001976 <procinit+0x6e>
  }
}
    800019a8:	70e2                	ld	ra,56(sp)
    800019aa:	7442                	ld	s0,48(sp)
    800019ac:	74a2                	ld	s1,40(sp)
    800019ae:	7902                	ld	s2,32(sp)
    800019b0:	69e2                	ld	s3,24(sp)
    800019b2:	6a42                	ld	s4,16(sp)
    800019b4:	6aa2                	ld	s5,8(sp)
    800019b6:	6b02                	ld	s6,0(sp)
    800019b8:	6121                	addi	sp,sp,64
    800019ba:	8082                	ret

00000000800019bc <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019bc:	1141                	addi	sp,sp,-16
    800019be:	e422                	sd	s0,8(sp)
    800019c0:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019c2:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019c4:	2501                	sext.w	a0,a0
    800019c6:	6422                	ld	s0,8(sp)
    800019c8:	0141                	addi	sp,sp,16
    800019ca:	8082                	ret

00000000800019cc <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800019cc:	1141                	addi	sp,sp,-16
    800019ce:	e422                	sd	s0,8(sp)
    800019d0:	0800                	addi	s0,sp,16
    800019d2:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019d4:	2781                	sext.w	a5,a5
    800019d6:	079e                	slli	a5,a5,0x7
  return c;
}
    800019d8:	0000f517          	auipc	a0,0xf
    800019dc:	21850513          	addi	a0,a0,536 # 80010bf0 <cpus>
    800019e0:	953e                	add	a0,a0,a5
    800019e2:	6422                	ld	s0,8(sp)
    800019e4:	0141                	addi	sp,sp,16
    800019e6:	8082                	ret

00000000800019e8 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019e8:	1101                	addi	sp,sp,-32
    800019ea:	ec06                	sd	ra,24(sp)
    800019ec:	e822                	sd	s0,16(sp)
    800019ee:	e426                	sd	s1,8(sp)
    800019f0:	1000                	addi	s0,sp,32
  push_off();
    800019f2:	fffff097          	auipc	ra,0xfffff
    800019f6:	1ce080e7          	jalr	462(ra) # 80000bc0 <push_off>
    800019fa:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019fc:	2781                	sext.w	a5,a5
    800019fe:	079e                	slli	a5,a5,0x7
    80001a00:	0000f717          	auipc	a4,0xf
    80001a04:	1c070713          	addi	a4,a4,448 # 80010bc0 <pid_lock>
    80001a08:	97ba                	add	a5,a5,a4
    80001a0a:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a0c:	fffff097          	auipc	ra,0xfffff
    80001a10:	254080e7          	jalr	596(ra) # 80000c60 <pop_off>
  return p;
}
    80001a14:	8526                	mv	a0,s1
    80001a16:	60e2                	ld	ra,24(sp)
    80001a18:	6442                	ld	s0,16(sp)
    80001a1a:	64a2                	ld	s1,8(sp)
    80001a1c:	6105                	addi	sp,sp,32
    80001a1e:	8082                	ret

0000000080001a20 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a20:	1141                	addi	sp,sp,-16
    80001a22:	e406                	sd	ra,8(sp)
    80001a24:	e022                	sd	s0,0(sp)
    80001a26:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a28:	00000097          	auipc	ra,0x0
    80001a2c:	fc0080e7          	jalr	-64(ra) # 800019e8 <myproc>
    80001a30:	fffff097          	auipc	ra,0xfffff
    80001a34:	290080e7          	jalr	656(ra) # 80000cc0 <release>

  if (first) {
    80001a38:	00007797          	auipc	a5,0x7
    80001a3c:	e787a783          	lw	a5,-392(a5) # 800088b0 <first.1693>
    80001a40:	eb89                	bnez	a5,80001a52 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a42:	00001097          	auipc	ra,0x1
    80001a46:	d96080e7          	jalr	-618(ra) # 800027d8 <usertrapret>
}
    80001a4a:	60a2                	ld	ra,8(sp)
    80001a4c:	6402                	ld	s0,0(sp)
    80001a4e:	0141                	addi	sp,sp,16
    80001a50:	8082                	ret
    first = 0;
    80001a52:	00007797          	auipc	a5,0x7
    80001a56:	e407af23          	sw	zero,-418(a5) # 800088b0 <first.1693>
    fsinit(ROOTDEV);
    80001a5a:	4505                	li	a0,1
    80001a5c:	00002097          	auipc	ra,0x2
    80001a60:	b5e080e7          	jalr	-1186(ra) # 800035ba <fsinit>
    80001a64:	bff9                	j	80001a42 <forkret+0x22>

0000000080001a66 <allocpid>:
{
    80001a66:	1101                	addi	sp,sp,-32
    80001a68:	ec06                	sd	ra,24(sp)
    80001a6a:	e822                	sd	s0,16(sp)
    80001a6c:	e426                	sd	s1,8(sp)
    80001a6e:	e04a                	sd	s2,0(sp)
    80001a70:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a72:	0000f917          	auipc	s2,0xf
    80001a76:	14e90913          	addi	s2,s2,334 # 80010bc0 <pid_lock>
    80001a7a:	854a                	mv	a0,s2
    80001a7c:	fffff097          	auipc	ra,0xfffff
    80001a80:	190080e7          	jalr	400(ra) # 80000c0c <acquire>
  pid = nextpid;
    80001a84:	00007797          	auipc	a5,0x7
    80001a88:	e3078793          	addi	a5,a5,-464 # 800088b4 <nextpid>
    80001a8c:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a8e:	0014871b          	addiw	a4,s1,1
    80001a92:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a94:	854a                	mv	a0,s2
    80001a96:	fffff097          	auipc	ra,0xfffff
    80001a9a:	22a080e7          	jalr	554(ra) # 80000cc0 <release>
}
    80001a9e:	8526                	mv	a0,s1
    80001aa0:	60e2                	ld	ra,24(sp)
    80001aa2:	6442                	ld	s0,16(sp)
    80001aa4:	64a2                	ld	s1,8(sp)
    80001aa6:	6902                	ld	s2,0(sp)
    80001aa8:	6105                	addi	sp,sp,32
    80001aaa:	8082                	ret

0000000080001aac <proc_pagetable>:
{
    80001aac:	1101                	addi	sp,sp,-32
    80001aae:	ec06                	sd	ra,24(sp)
    80001ab0:	e822                	sd	s0,16(sp)
    80001ab2:	e426                	sd	s1,8(sp)
    80001ab4:	e04a                	sd	s2,0(sp)
    80001ab6:	1000                	addi	s0,sp,32
    80001ab8:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001aba:	00000097          	auipc	ra,0x0
    80001abe:	8ac080e7          	jalr	-1876(ra) # 80001366 <uvmcreate>
    80001ac2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001ac4:	c121                	beqz	a0,80001b04 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ac6:	4729                	li	a4,10
    80001ac8:	00005697          	auipc	a3,0x5
    80001acc:	53868693          	addi	a3,a3,1336 # 80007000 <_trampoline>
    80001ad0:	6605                	lui	a2,0x1
    80001ad2:	040005b7          	lui	a1,0x4000
    80001ad6:	15fd                	addi	a1,a1,-1
    80001ad8:	05b2                	slli	a1,a1,0xc
    80001ada:	fffff097          	auipc	ra,0xfffff
    80001ade:	602080e7          	jalr	1538(ra) # 800010dc <mappages>
    80001ae2:	02054863          	bltz	a0,80001b12 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ae6:	4719                	li	a4,6
    80001ae8:	05893683          	ld	a3,88(s2)
    80001aec:	6605                	lui	a2,0x1
    80001aee:	020005b7          	lui	a1,0x2000
    80001af2:	15fd                	addi	a1,a1,-1
    80001af4:	05b6                	slli	a1,a1,0xd
    80001af6:	8526                	mv	a0,s1
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	5e4080e7          	jalr	1508(ra) # 800010dc <mappages>
    80001b00:	02054163          	bltz	a0,80001b22 <proc_pagetable+0x76>
}
    80001b04:	8526                	mv	a0,s1
    80001b06:	60e2                	ld	ra,24(sp)
    80001b08:	6442                	ld	s0,16(sp)
    80001b0a:	64a2                	ld	s1,8(sp)
    80001b0c:	6902                	ld	s2,0(sp)
    80001b0e:	6105                	addi	sp,sp,32
    80001b10:	8082                	ret
    uvmfree(pagetable, 0);
    80001b12:	4581                	li	a1,0
    80001b14:	8526                	mv	a0,s1
    80001b16:	00000097          	auipc	ra,0x0
    80001b1a:	a54080e7          	jalr	-1452(ra) # 8000156a <uvmfree>
    return 0;
    80001b1e:	4481                	li	s1,0
    80001b20:	b7d5                	j	80001b04 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b22:	4681                	li	a3,0
    80001b24:	4605                	li	a2,1
    80001b26:	040005b7          	lui	a1,0x4000
    80001b2a:	15fd                	addi	a1,a1,-1
    80001b2c:	05b2                	slli	a1,a1,0xc
    80001b2e:	8526                	mv	a0,s1
    80001b30:	fffff097          	auipc	ra,0xfffff
    80001b34:	772080e7          	jalr	1906(ra) # 800012a2 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b38:	4581                	li	a1,0
    80001b3a:	8526                	mv	a0,s1
    80001b3c:	00000097          	auipc	ra,0x0
    80001b40:	a2e080e7          	jalr	-1490(ra) # 8000156a <uvmfree>
    return 0;
    80001b44:	4481                	li	s1,0
    80001b46:	bf7d                	j	80001b04 <proc_pagetable+0x58>

0000000080001b48 <proc_freepagetable>:
{
    80001b48:	1101                	addi	sp,sp,-32
    80001b4a:	ec06                	sd	ra,24(sp)
    80001b4c:	e822                	sd	s0,16(sp)
    80001b4e:	e426                	sd	s1,8(sp)
    80001b50:	e04a                	sd	s2,0(sp)
    80001b52:	1000                	addi	s0,sp,32
    80001b54:	84aa                	mv	s1,a0
    80001b56:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b58:	4681                	li	a3,0
    80001b5a:	4605                	li	a2,1
    80001b5c:	040005b7          	lui	a1,0x4000
    80001b60:	15fd                	addi	a1,a1,-1
    80001b62:	05b2                	slli	a1,a1,0xc
    80001b64:	fffff097          	auipc	ra,0xfffff
    80001b68:	73e080e7          	jalr	1854(ra) # 800012a2 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b6c:	4681                	li	a3,0
    80001b6e:	4605                	li	a2,1
    80001b70:	020005b7          	lui	a1,0x2000
    80001b74:	15fd                	addi	a1,a1,-1
    80001b76:	05b6                	slli	a1,a1,0xd
    80001b78:	8526                	mv	a0,s1
    80001b7a:	fffff097          	auipc	ra,0xfffff
    80001b7e:	728080e7          	jalr	1832(ra) # 800012a2 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b82:	85ca                	mv	a1,s2
    80001b84:	8526                	mv	a0,s1
    80001b86:	00000097          	auipc	ra,0x0
    80001b8a:	9e4080e7          	jalr	-1564(ra) # 8000156a <uvmfree>
}
    80001b8e:	60e2                	ld	ra,24(sp)
    80001b90:	6442                	ld	s0,16(sp)
    80001b92:	64a2                	ld	s1,8(sp)
    80001b94:	6902                	ld	s2,0(sp)
    80001b96:	6105                	addi	sp,sp,32
    80001b98:	8082                	ret

0000000080001b9a <freeproc>:
{
    80001b9a:	1101                	addi	sp,sp,-32
    80001b9c:	ec06                	sd	ra,24(sp)
    80001b9e:	e822                	sd	s0,16(sp)
    80001ba0:	e426                	sd	s1,8(sp)
    80001ba2:	1000                	addi	s0,sp,32
    80001ba4:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001ba6:	6d28                	ld	a0,88(a0)
    80001ba8:	c509                	beqz	a0,80001bb2 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001baa:	fffff097          	auipc	ra,0xfffff
    80001bae:	e54080e7          	jalr	-428(ra) # 800009fe <kfree>
  p->trapframe = 0;
    80001bb2:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bb6:	68a8                	ld	a0,80(s1)
    80001bb8:	c511                	beqz	a0,80001bc4 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bba:	64ac                	ld	a1,72(s1)
    80001bbc:	00000097          	auipc	ra,0x0
    80001bc0:	f8c080e7          	jalr	-116(ra) # 80001b48 <proc_freepagetable>
  p->pagetable = 0;
    80001bc4:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bc8:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bcc:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bd0:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bd4:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bd8:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bdc:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001be0:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001be4:	0004ac23          	sw	zero,24(s1)
  systemcall_count[p->pid] = 0;
    80001be8:	0000f797          	auipc	a5,0xf
    80001bec:	4007a423          	sw	zero,1032(a5) # 80010ff0 <systemcall_count>
}
    80001bf0:	60e2                	ld	ra,24(sp)
    80001bf2:	6442                	ld	s0,16(sp)
    80001bf4:	64a2                	ld	s1,8(sp)
    80001bf6:	6105                	addi	sp,sp,32
    80001bf8:	8082                	ret

0000000080001bfa <allocproc>:
{
    80001bfa:	1101                	addi	sp,sp,-32
    80001bfc:	ec06                	sd	ra,24(sp)
    80001bfe:	e822                	sd	s0,16(sp)
    80001c00:	e426                	sd	s1,8(sp)
    80001c02:	e04a                	sd	s2,0(sp)
    80001c04:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c06:	0000f497          	auipc	s1,0xf
    80001c0a:	4ea48493          	addi	s1,s1,1258 # 800110f0 <proc>
    80001c0e:	00015917          	auipc	s2,0x15
    80001c12:	ee290913          	addi	s2,s2,-286 # 80016af0 <tickslock>
    acquire(&p->lock);
    80001c16:	8526                	mv	a0,s1
    80001c18:	fffff097          	auipc	ra,0xfffff
    80001c1c:	ff4080e7          	jalr	-12(ra) # 80000c0c <acquire>
    if(p->state == UNUSED) {
    80001c20:	4c9c                	lw	a5,24(s1)
    80001c22:	cf81                	beqz	a5,80001c3a <allocproc+0x40>
      release(&p->lock);
    80001c24:	8526                	mv	a0,s1
    80001c26:	fffff097          	auipc	ra,0xfffff
    80001c2a:	09a080e7          	jalr	154(ra) # 80000cc0 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c2e:	16848493          	addi	s1,s1,360
    80001c32:	ff2492e3          	bne	s1,s2,80001c16 <allocproc+0x1c>
  return 0;
    80001c36:	4481                	li	s1,0
    80001c38:	a08d                	j	80001c9a <allocproc+0xa0>
  p->pid = allocpid();
    80001c3a:	00000097          	auipc	ra,0x0
    80001c3e:	e2c080e7          	jalr	-468(ra) # 80001a66 <allocpid>
    80001c42:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c44:	4785                	li	a5,1
    80001c46:	cc9c                	sw	a5,24(s1)
  systemcall_count[p->pid] = 0; //reset system call to zero for new process
    80001c48:	050a                	slli	a0,a0,0x2
    80001c4a:	0000f797          	auipc	a5,0xf
    80001c4e:	f7678793          	addi	a5,a5,-138 # 80010bc0 <pid_lock>
    80001c52:	953e                	add	a0,a0,a5
    80001c54:	42052823          	sw	zero,1072(a0)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c58:	fffff097          	auipc	ra,0xfffff
    80001c5c:	ea2080e7          	jalr	-350(ra) # 80000afa <kalloc>
    80001c60:	892a                	mv	s2,a0
    80001c62:	eca8                	sd	a0,88(s1)
    80001c64:	c131                	beqz	a0,80001ca8 <allocproc+0xae>
  p->pagetable = proc_pagetable(p);
    80001c66:	8526                	mv	a0,s1
    80001c68:	00000097          	auipc	ra,0x0
    80001c6c:	e44080e7          	jalr	-444(ra) # 80001aac <proc_pagetable>
    80001c70:	892a                	mv	s2,a0
    80001c72:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c74:	c531                	beqz	a0,80001cc0 <allocproc+0xc6>
  memset(&p->context, 0, sizeof(p->context));
    80001c76:	07000613          	li	a2,112
    80001c7a:	4581                	li	a1,0
    80001c7c:	06048513          	addi	a0,s1,96
    80001c80:	fffff097          	auipc	ra,0xfffff
    80001c84:	088080e7          	jalr	136(ra) # 80000d08 <memset>
  p->context.ra = (uint64)forkret;
    80001c88:	00000797          	auipc	a5,0x0
    80001c8c:	d9878793          	addi	a5,a5,-616 # 80001a20 <forkret>
    80001c90:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c92:	60bc                	ld	a5,64(s1)
    80001c94:	6705                	lui	a4,0x1
    80001c96:	97ba                	add	a5,a5,a4
    80001c98:	f4bc                	sd	a5,104(s1)
}
    80001c9a:	8526                	mv	a0,s1
    80001c9c:	60e2                	ld	ra,24(sp)
    80001c9e:	6442                	ld	s0,16(sp)
    80001ca0:	64a2                	ld	s1,8(sp)
    80001ca2:	6902                	ld	s2,0(sp)
    80001ca4:	6105                	addi	sp,sp,32
    80001ca6:	8082                	ret
    freeproc(p);
    80001ca8:	8526                	mv	a0,s1
    80001caa:	00000097          	auipc	ra,0x0
    80001cae:	ef0080e7          	jalr	-272(ra) # 80001b9a <freeproc>
    release(&p->lock);
    80001cb2:	8526                	mv	a0,s1
    80001cb4:	fffff097          	auipc	ra,0xfffff
    80001cb8:	00c080e7          	jalr	12(ra) # 80000cc0 <release>
    return 0;
    80001cbc:	84ca                	mv	s1,s2
    80001cbe:	bff1                	j	80001c9a <allocproc+0xa0>
    freeproc(p);
    80001cc0:	8526                	mv	a0,s1
    80001cc2:	00000097          	auipc	ra,0x0
    80001cc6:	ed8080e7          	jalr	-296(ra) # 80001b9a <freeproc>
    release(&p->lock);
    80001cca:	8526                	mv	a0,s1
    80001ccc:	fffff097          	auipc	ra,0xfffff
    80001cd0:	ff4080e7          	jalr	-12(ra) # 80000cc0 <release>
    return 0;
    80001cd4:	84ca                	mv	s1,s2
    80001cd6:	b7d1                	j	80001c9a <allocproc+0xa0>

0000000080001cd8 <userinit>:
{
    80001cd8:	1101                	addi	sp,sp,-32
    80001cda:	ec06                	sd	ra,24(sp)
    80001cdc:	e822                	sd	s0,16(sp)
    80001cde:	e426                	sd	s1,8(sp)
    80001ce0:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ce2:	00000097          	auipc	ra,0x0
    80001ce6:	f18080e7          	jalr	-232(ra) # 80001bfa <allocproc>
    80001cea:	84aa                	mv	s1,a0
  initproc = p;
    80001cec:	00007797          	auipc	a5,0x7
    80001cf0:	c4a7be23          	sd	a0,-932(a5) # 80008948 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cf4:	03400613          	li	a2,52
    80001cf8:	00007597          	auipc	a1,0x7
    80001cfc:	bc858593          	addi	a1,a1,-1080 # 800088c0 <initcode>
    80001d00:	6928                	ld	a0,80(a0)
    80001d02:	fffff097          	auipc	ra,0xfffff
    80001d06:	692080e7          	jalr	1682(ra) # 80001394 <uvmfirst>
  p->sz = PGSIZE;
    80001d0a:	6785                	lui	a5,0x1
    80001d0c:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d0e:	6cb8                	ld	a4,88(s1)
    80001d10:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d14:	6cb8                	ld	a4,88(s1)
    80001d16:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d18:	4641                	li	a2,16
    80001d1a:	00006597          	auipc	a1,0x6
    80001d1e:	4e658593          	addi	a1,a1,1254 # 80008200 <digits+0x1c0>
    80001d22:	15848513          	addi	a0,s1,344
    80001d26:	fffff097          	auipc	ra,0xfffff
    80001d2a:	134080e7          	jalr	308(ra) # 80000e5a <safestrcpy>
  p->cwd = namei("/");
    80001d2e:	00006517          	auipc	a0,0x6
    80001d32:	4e250513          	addi	a0,a0,1250 # 80008210 <digits+0x1d0>
    80001d36:	00002097          	auipc	ra,0x2
    80001d3a:	2a6080e7          	jalr	678(ra) # 80003fdc <namei>
    80001d3e:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d42:	478d                	li	a5,3
    80001d44:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d46:	8526                	mv	a0,s1
    80001d48:	fffff097          	auipc	ra,0xfffff
    80001d4c:	f78080e7          	jalr	-136(ra) # 80000cc0 <release>
}
    80001d50:	60e2                	ld	ra,24(sp)
    80001d52:	6442                	ld	s0,16(sp)
    80001d54:	64a2                	ld	s1,8(sp)
    80001d56:	6105                	addi	sp,sp,32
    80001d58:	8082                	ret

0000000080001d5a <growproc>:
{
    80001d5a:	1101                	addi	sp,sp,-32
    80001d5c:	ec06                	sd	ra,24(sp)
    80001d5e:	e822                	sd	s0,16(sp)
    80001d60:	e426                	sd	s1,8(sp)
    80001d62:	e04a                	sd	s2,0(sp)
    80001d64:	1000                	addi	s0,sp,32
    80001d66:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d68:	00000097          	auipc	ra,0x0
    80001d6c:	c80080e7          	jalr	-896(ra) # 800019e8 <myproc>
    80001d70:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d72:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d74:	01204c63          	bgtz	s2,80001d8c <growproc+0x32>
  } else if(n < 0){
    80001d78:	02094663          	bltz	s2,80001da4 <growproc+0x4a>
  p->sz = sz;
    80001d7c:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d7e:	4501                	li	a0,0
}
    80001d80:	60e2                	ld	ra,24(sp)
    80001d82:	6442                	ld	s0,16(sp)
    80001d84:	64a2                	ld	s1,8(sp)
    80001d86:	6902                	ld	s2,0(sp)
    80001d88:	6105                	addi	sp,sp,32
    80001d8a:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d8c:	4691                	li	a3,4
    80001d8e:	00b90633          	add	a2,s2,a1
    80001d92:	6928                	ld	a0,80(a0)
    80001d94:	fffff097          	auipc	ra,0xfffff
    80001d98:	6ba080e7          	jalr	1722(ra) # 8000144e <uvmalloc>
    80001d9c:	85aa                	mv	a1,a0
    80001d9e:	fd79                	bnez	a0,80001d7c <growproc+0x22>
      return -1;
    80001da0:	557d                	li	a0,-1
    80001da2:	bff9                	j	80001d80 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001da4:	00b90633          	add	a2,s2,a1
    80001da8:	6928                	ld	a0,80(a0)
    80001daa:	fffff097          	auipc	ra,0xfffff
    80001dae:	65c080e7          	jalr	1628(ra) # 80001406 <uvmdealloc>
    80001db2:	85aa                	mv	a1,a0
    80001db4:	b7e1                	j	80001d7c <growproc+0x22>

0000000080001db6 <fork>:
{
    80001db6:	7179                	addi	sp,sp,-48
    80001db8:	f406                	sd	ra,40(sp)
    80001dba:	f022                	sd	s0,32(sp)
    80001dbc:	ec26                	sd	s1,24(sp)
    80001dbe:	e84a                	sd	s2,16(sp)
    80001dc0:	e44e                	sd	s3,8(sp)
    80001dc2:	e052                	sd	s4,0(sp)
    80001dc4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001dc6:	00000097          	auipc	ra,0x0
    80001dca:	c22080e7          	jalr	-990(ra) # 800019e8 <myproc>
    80001dce:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001dd0:	00000097          	auipc	ra,0x0
    80001dd4:	e2a080e7          	jalr	-470(ra) # 80001bfa <allocproc>
    80001dd8:	10050b63          	beqz	a0,80001eee <fork+0x138>
    80001ddc:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dde:	04893603          	ld	a2,72(s2)
    80001de2:	692c                	ld	a1,80(a0)
    80001de4:	05093503          	ld	a0,80(s2)
    80001de8:	fffff097          	auipc	ra,0xfffff
    80001dec:	7ba080e7          	jalr	1978(ra) # 800015a2 <uvmcopy>
    80001df0:	04054663          	bltz	a0,80001e3c <fork+0x86>
  np->sz = p->sz;
    80001df4:	04893783          	ld	a5,72(s2)
    80001df8:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dfc:	05893683          	ld	a3,88(s2)
    80001e00:	87b6                	mv	a5,a3
    80001e02:	0589b703          	ld	a4,88(s3)
    80001e06:	12068693          	addi	a3,a3,288
    80001e0a:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e0e:	6788                	ld	a0,8(a5)
    80001e10:	6b8c                	ld	a1,16(a5)
    80001e12:	6f90                	ld	a2,24(a5)
    80001e14:	01073023          	sd	a6,0(a4)
    80001e18:	e708                	sd	a0,8(a4)
    80001e1a:	eb0c                	sd	a1,16(a4)
    80001e1c:	ef10                	sd	a2,24(a4)
    80001e1e:	02078793          	addi	a5,a5,32
    80001e22:	02070713          	addi	a4,a4,32
    80001e26:	fed792e3          	bne	a5,a3,80001e0a <fork+0x54>
  np->trapframe->a0 = 0;
    80001e2a:	0589b783          	ld	a5,88(s3)
    80001e2e:	0607b823          	sd	zero,112(a5)
    80001e32:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e36:	15000a13          	li	s4,336
    80001e3a:	a03d                	j	80001e68 <fork+0xb2>
    freeproc(np);
    80001e3c:	854e                	mv	a0,s3
    80001e3e:	00000097          	auipc	ra,0x0
    80001e42:	d5c080e7          	jalr	-676(ra) # 80001b9a <freeproc>
    release(&np->lock);
    80001e46:	854e                	mv	a0,s3
    80001e48:	fffff097          	auipc	ra,0xfffff
    80001e4c:	e78080e7          	jalr	-392(ra) # 80000cc0 <release>
    return -1;
    80001e50:	5a7d                	li	s4,-1
    80001e52:	a069                	j	80001edc <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e54:	00003097          	auipc	ra,0x3
    80001e58:	81e080e7          	jalr	-2018(ra) # 80004672 <filedup>
    80001e5c:	009987b3          	add	a5,s3,s1
    80001e60:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e62:	04a1                	addi	s1,s1,8
    80001e64:	01448763          	beq	s1,s4,80001e72 <fork+0xbc>
    if(p->ofile[i])
    80001e68:	009907b3          	add	a5,s2,s1
    80001e6c:	6388                	ld	a0,0(a5)
    80001e6e:	f17d                	bnez	a0,80001e54 <fork+0x9e>
    80001e70:	bfcd                	j	80001e62 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e72:	15093503          	ld	a0,336(s2)
    80001e76:	00002097          	auipc	ra,0x2
    80001e7a:	982080e7          	jalr	-1662(ra) # 800037f8 <idup>
    80001e7e:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e82:	4641                	li	a2,16
    80001e84:	15890593          	addi	a1,s2,344
    80001e88:	15898513          	addi	a0,s3,344
    80001e8c:	fffff097          	auipc	ra,0xfffff
    80001e90:	fce080e7          	jalr	-50(ra) # 80000e5a <safestrcpy>
  pid = np->pid;
    80001e94:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e98:	854e                	mv	a0,s3
    80001e9a:	fffff097          	auipc	ra,0xfffff
    80001e9e:	e26080e7          	jalr	-474(ra) # 80000cc0 <release>
  acquire(&wait_lock);
    80001ea2:	0000f497          	auipc	s1,0xf
    80001ea6:	d3648493          	addi	s1,s1,-714 # 80010bd8 <wait_lock>
    80001eaa:	8526                	mv	a0,s1
    80001eac:	fffff097          	auipc	ra,0xfffff
    80001eb0:	d60080e7          	jalr	-672(ra) # 80000c0c <acquire>
  np->parent = p;
    80001eb4:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001eb8:	8526                	mv	a0,s1
    80001eba:	fffff097          	auipc	ra,0xfffff
    80001ebe:	e06080e7          	jalr	-506(ra) # 80000cc0 <release>
  acquire(&np->lock);
    80001ec2:	854e                	mv	a0,s3
    80001ec4:	fffff097          	auipc	ra,0xfffff
    80001ec8:	d48080e7          	jalr	-696(ra) # 80000c0c <acquire>
  np->state = RUNNABLE;
    80001ecc:	478d                	li	a5,3
    80001ece:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ed2:	854e                	mv	a0,s3
    80001ed4:	fffff097          	auipc	ra,0xfffff
    80001ed8:	dec080e7          	jalr	-532(ra) # 80000cc0 <release>
}
    80001edc:	8552                	mv	a0,s4
    80001ede:	70a2                	ld	ra,40(sp)
    80001ee0:	7402                	ld	s0,32(sp)
    80001ee2:	64e2                	ld	s1,24(sp)
    80001ee4:	6942                	ld	s2,16(sp)
    80001ee6:	69a2                	ld	s3,8(sp)
    80001ee8:	6a02                	ld	s4,0(sp)
    80001eea:	6145                	addi	sp,sp,48
    80001eec:	8082                	ret
    return -1;
    80001eee:	5a7d                	li	s4,-1
    80001ef0:	b7f5                	j	80001edc <fork+0x126>

0000000080001ef2 <scheduler>:
{
    80001ef2:	7139                	addi	sp,sp,-64
    80001ef4:	fc06                	sd	ra,56(sp)
    80001ef6:	f822                	sd	s0,48(sp)
    80001ef8:	f426                	sd	s1,40(sp)
    80001efa:	f04a                	sd	s2,32(sp)
    80001efc:	ec4e                	sd	s3,24(sp)
    80001efe:	e852                	sd	s4,16(sp)
    80001f00:	e456                	sd	s5,8(sp)
    80001f02:	e05a                	sd	s6,0(sp)
    80001f04:	0080                	addi	s0,sp,64
    80001f06:	8792                	mv	a5,tp
  int id = r_tp();
    80001f08:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f0a:	00779a93          	slli	s5,a5,0x7
    80001f0e:	0000f717          	auipc	a4,0xf
    80001f12:	cb270713          	addi	a4,a4,-846 # 80010bc0 <pid_lock>
    80001f16:	9756                	add	a4,a4,s5
    80001f18:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f1c:	0000f717          	auipc	a4,0xf
    80001f20:	cdc70713          	addi	a4,a4,-804 # 80010bf8 <cpus+0x8>
    80001f24:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f26:	498d                	li	s3,3
        p->state = RUNNING;
    80001f28:	4b11                	li	s6,4
        c->proc = p;
    80001f2a:	079e                	slli	a5,a5,0x7
    80001f2c:	0000fa17          	auipc	s4,0xf
    80001f30:	c94a0a13          	addi	s4,s4,-876 # 80010bc0 <pid_lock>
    80001f34:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f36:	00015917          	auipc	s2,0x15
    80001f3a:	bba90913          	addi	s2,s2,-1094 # 80016af0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f3e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f42:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f46:	10079073          	csrw	sstatus,a5
    80001f4a:	0000f497          	auipc	s1,0xf
    80001f4e:	1a648493          	addi	s1,s1,422 # 800110f0 <proc>
    80001f52:	a03d                	j	80001f80 <scheduler+0x8e>
        p->state = RUNNING;
    80001f54:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f58:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f5c:	06048593          	addi	a1,s1,96
    80001f60:	8556                	mv	a0,s5
    80001f62:	00000097          	auipc	ra,0x0
    80001f66:	7cc080e7          	jalr	1996(ra) # 8000272e <swtch>
        c->proc = 0;
    80001f6a:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80001f6e:	8526                	mv	a0,s1
    80001f70:	fffff097          	auipc	ra,0xfffff
    80001f74:	d50080e7          	jalr	-688(ra) # 80000cc0 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f78:	16848493          	addi	s1,s1,360
    80001f7c:	fd2481e3          	beq	s1,s2,80001f3e <scheduler+0x4c>
      acquire(&p->lock);
    80001f80:	8526                	mv	a0,s1
    80001f82:	fffff097          	auipc	ra,0xfffff
    80001f86:	c8a080e7          	jalr	-886(ra) # 80000c0c <acquire>
      if(p->state == RUNNABLE) {
    80001f8a:	4c9c                	lw	a5,24(s1)
    80001f8c:	ff3791e3          	bne	a5,s3,80001f6e <scheduler+0x7c>
    80001f90:	b7d1                	j	80001f54 <scheduler+0x62>

0000000080001f92 <sched>:
{
    80001f92:	7179                	addi	sp,sp,-48
    80001f94:	f406                	sd	ra,40(sp)
    80001f96:	f022                	sd	s0,32(sp)
    80001f98:	ec26                	sd	s1,24(sp)
    80001f9a:	e84a                	sd	s2,16(sp)
    80001f9c:	e44e                	sd	s3,8(sp)
    80001f9e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fa0:	00000097          	auipc	ra,0x0
    80001fa4:	a48080e7          	jalr	-1464(ra) # 800019e8 <myproc>
    80001fa8:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001faa:	fffff097          	auipc	ra,0xfffff
    80001fae:	be8080e7          	jalr	-1048(ra) # 80000b92 <holding>
    80001fb2:	c93d                	beqz	a0,80002028 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fb4:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001fb6:	2781                	sext.w	a5,a5
    80001fb8:	079e                	slli	a5,a5,0x7
    80001fba:	0000f717          	auipc	a4,0xf
    80001fbe:	c0670713          	addi	a4,a4,-1018 # 80010bc0 <pid_lock>
    80001fc2:	97ba                	add	a5,a5,a4
    80001fc4:	0a87a703          	lw	a4,168(a5)
    80001fc8:	4785                	li	a5,1
    80001fca:	06f71763          	bne	a4,a5,80002038 <sched+0xa6>
  if(p->state == RUNNING)
    80001fce:	4c98                	lw	a4,24(s1)
    80001fd0:	4791                	li	a5,4
    80001fd2:	06f70b63          	beq	a4,a5,80002048 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fd6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fda:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fdc:	efb5                	bnez	a5,80002058 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fde:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fe0:	0000f917          	auipc	s2,0xf
    80001fe4:	be090913          	addi	s2,s2,-1056 # 80010bc0 <pid_lock>
    80001fe8:	2781                	sext.w	a5,a5
    80001fea:	079e                	slli	a5,a5,0x7
    80001fec:	97ca                	add	a5,a5,s2
    80001fee:	0ac7a983          	lw	s3,172(a5)
    80001ff2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001ff4:	2781                	sext.w	a5,a5
    80001ff6:	079e                	slli	a5,a5,0x7
    80001ff8:	0000f597          	auipc	a1,0xf
    80001ffc:	c0058593          	addi	a1,a1,-1024 # 80010bf8 <cpus+0x8>
    80002000:	95be                	add	a1,a1,a5
    80002002:	06048513          	addi	a0,s1,96
    80002006:	00000097          	auipc	ra,0x0
    8000200a:	728080e7          	jalr	1832(ra) # 8000272e <swtch>
    8000200e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002010:	2781                	sext.w	a5,a5
    80002012:	079e                	slli	a5,a5,0x7
    80002014:	97ca                	add	a5,a5,s2
    80002016:	0b37a623          	sw	s3,172(a5)
}
    8000201a:	70a2                	ld	ra,40(sp)
    8000201c:	7402                	ld	s0,32(sp)
    8000201e:	64e2                	ld	s1,24(sp)
    80002020:	6942                	ld	s2,16(sp)
    80002022:	69a2                	ld	s3,8(sp)
    80002024:	6145                	addi	sp,sp,48
    80002026:	8082                	ret
    panic("sched p->lock");
    80002028:	00006517          	auipc	a0,0x6
    8000202c:	1f050513          	addi	a0,a0,496 # 80008218 <digits+0x1d8>
    80002030:	ffffe097          	auipc	ra,0xffffe
    80002034:	514080e7          	jalr	1300(ra) # 80000544 <panic>
    panic("sched locks");
    80002038:	00006517          	auipc	a0,0x6
    8000203c:	1f050513          	addi	a0,a0,496 # 80008228 <digits+0x1e8>
    80002040:	ffffe097          	auipc	ra,0xffffe
    80002044:	504080e7          	jalr	1284(ra) # 80000544 <panic>
    panic("sched running");
    80002048:	00006517          	auipc	a0,0x6
    8000204c:	1f050513          	addi	a0,a0,496 # 80008238 <digits+0x1f8>
    80002050:	ffffe097          	auipc	ra,0xffffe
    80002054:	4f4080e7          	jalr	1268(ra) # 80000544 <panic>
    panic("sched interruptible");
    80002058:	00006517          	auipc	a0,0x6
    8000205c:	1f050513          	addi	a0,a0,496 # 80008248 <digits+0x208>
    80002060:	ffffe097          	auipc	ra,0xffffe
    80002064:	4e4080e7          	jalr	1252(ra) # 80000544 <panic>

0000000080002068 <yield>:
{
    80002068:	1101                	addi	sp,sp,-32
    8000206a:	ec06                	sd	ra,24(sp)
    8000206c:	e822                	sd	s0,16(sp)
    8000206e:	e426                	sd	s1,8(sp)
    80002070:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002072:	00000097          	auipc	ra,0x0
    80002076:	976080e7          	jalr	-1674(ra) # 800019e8 <myproc>
    8000207a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000207c:	fffff097          	auipc	ra,0xfffff
    80002080:	b90080e7          	jalr	-1136(ra) # 80000c0c <acquire>
  p->state = RUNNABLE;
    80002084:	478d                	li	a5,3
    80002086:	cc9c                	sw	a5,24(s1)
  sched();
    80002088:	00000097          	auipc	ra,0x0
    8000208c:	f0a080e7          	jalr	-246(ra) # 80001f92 <sched>
  release(&p->lock);
    80002090:	8526                	mv	a0,s1
    80002092:	fffff097          	auipc	ra,0xfffff
    80002096:	c2e080e7          	jalr	-978(ra) # 80000cc0 <release>
}
    8000209a:	60e2                	ld	ra,24(sp)
    8000209c:	6442                	ld	s0,16(sp)
    8000209e:	64a2                	ld	s1,8(sp)
    800020a0:	6105                	addi	sp,sp,32
    800020a2:	8082                	ret

00000000800020a4 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020a4:	7179                	addi	sp,sp,-48
    800020a6:	f406                	sd	ra,40(sp)
    800020a8:	f022                	sd	s0,32(sp)
    800020aa:	ec26                	sd	s1,24(sp)
    800020ac:	e84a                	sd	s2,16(sp)
    800020ae:	e44e                	sd	s3,8(sp)
    800020b0:	1800                	addi	s0,sp,48
    800020b2:	89aa                	mv	s3,a0
    800020b4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020b6:	00000097          	auipc	ra,0x0
    800020ba:	932080e7          	jalr	-1742(ra) # 800019e8 <myproc>
    800020be:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800020c0:	fffff097          	auipc	ra,0xfffff
    800020c4:	b4c080e7          	jalr	-1204(ra) # 80000c0c <acquire>
  release(lk);
    800020c8:	854a                	mv	a0,s2
    800020ca:	fffff097          	auipc	ra,0xfffff
    800020ce:	bf6080e7          	jalr	-1034(ra) # 80000cc0 <release>

  // Go to sleep.
  p->chan = chan;
    800020d2:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020d6:	4789                	li	a5,2
    800020d8:	cc9c                	sw	a5,24(s1)

  sched();
    800020da:	00000097          	auipc	ra,0x0
    800020de:	eb8080e7          	jalr	-328(ra) # 80001f92 <sched>

  // Tidy up.
  p->chan = 0;
    800020e2:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020e6:	8526                	mv	a0,s1
    800020e8:	fffff097          	auipc	ra,0xfffff
    800020ec:	bd8080e7          	jalr	-1064(ra) # 80000cc0 <release>
  acquire(lk);
    800020f0:	854a                	mv	a0,s2
    800020f2:	fffff097          	auipc	ra,0xfffff
    800020f6:	b1a080e7          	jalr	-1254(ra) # 80000c0c <acquire>
}
    800020fa:	70a2                	ld	ra,40(sp)
    800020fc:	7402                	ld	s0,32(sp)
    800020fe:	64e2                	ld	s1,24(sp)
    80002100:	6942                	ld	s2,16(sp)
    80002102:	69a2                	ld	s3,8(sp)
    80002104:	6145                	addi	sp,sp,48
    80002106:	8082                	ret

0000000080002108 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002108:	7139                	addi	sp,sp,-64
    8000210a:	fc06                	sd	ra,56(sp)
    8000210c:	f822                	sd	s0,48(sp)
    8000210e:	f426                	sd	s1,40(sp)
    80002110:	f04a                	sd	s2,32(sp)
    80002112:	ec4e                	sd	s3,24(sp)
    80002114:	e852                	sd	s4,16(sp)
    80002116:	e456                	sd	s5,8(sp)
    80002118:	0080                	addi	s0,sp,64
    8000211a:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000211c:	0000f497          	auipc	s1,0xf
    80002120:	fd448493          	addi	s1,s1,-44 # 800110f0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002124:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002126:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002128:	00015917          	auipc	s2,0x15
    8000212c:	9c890913          	addi	s2,s2,-1592 # 80016af0 <tickslock>
    80002130:	a821                	j	80002148 <wakeup+0x40>
        p->state = RUNNABLE;
    80002132:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    80002136:	8526                	mv	a0,s1
    80002138:	fffff097          	auipc	ra,0xfffff
    8000213c:	b88080e7          	jalr	-1144(ra) # 80000cc0 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002140:	16848493          	addi	s1,s1,360
    80002144:	03248463          	beq	s1,s2,8000216c <wakeup+0x64>
    if(p != myproc()){
    80002148:	00000097          	auipc	ra,0x0
    8000214c:	8a0080e7          	jalr	-1888(ra) # 800019e8 <myproc>
    80002150:	fea488e3          	beq	s1,a0,80002140 <wakeup+0x38>
      acquire(&p->lock);
    80002154:	8526                	mv	a0,s1
    80002156:	fffff097          	auipc	ra,0xfffff
    8000215a:	ab6080e7          	jalr	-1354(ra) # 80000c0c <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000215e:	4c9c                	lw	a5,24(s1)
    80002160:	fd379be3          	bne	a5,s3,80002136 <wakeup+0x2e>
    80002164:	709c                	ld	a5,32(s1)
    80002166:	fd4798e3          	bne	a5,s4,80002136 <wakeup+0x2e>
    8000216a:	b7e1                	j	80002132 <wakeup+0x2a>
    }
  }
}
    8000216c:	70e2                	ld	ra,56(sp)
    8000216e:	7442                	ld	s0,48(sp)
    80002170:	74a2                	ld	s1,40(sp)
    80002172:	7902                	ld	s2,32(sp)
    80002174:	69e2                	ld	s3,24(sp)
    80002176:	6a42                	ld	s4,16(sp)
    80002178:	6aa2                	ld	s5,8(sp)
    8000217a:	6121                	addi	sp,sp,64
    8000217c:	8082                	ret

000000008000217e <reparent>:
{
    8000217e:	7179                	addi	sp,sp,-48
    80002180:	f406                	sd	ra,40(sp)
    80002182:	f022                	sd	s0,32(sp)
    80002184:	ec26                	sd	s1,24(sp)
    80002186:	e84a                	sd	s2,16(sp)
    80002188:	e44e                	sd	s3,8(sp)
    8000218a:	e052                	sd	s4,0(sp)
    8000218c:	1800                	addi	s0,sp,48
    8000218e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002190:	0000f497          	auipc	s1,0xf
    80002194:	f6048493          	addi	s1,s1,-160 # 800110f0 <proc>
      pp->parent = initproc;
    80002198:	00006a17          	auipc	s4,0x6
    8000219c:	7b0a0a13          	addi	s4,s4,1968 # 80008948 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021a0:	00015997          	auipc	s3,0x15
    800021a4:	95098993          	addi	s3,s3,-1712 # 80016af0 <tickslock>
    800021a8:	a029                	j	800021b2 <reparent+0x34>
    800021aa:	16848493          	addi	s1,s1,360
    800021ae:	01348d63          	beq	s1,s3,800021c8 <reparent+0x4a>
    if(pp->parent == p){
    800021b2:	7c9c                	ld	a5,56(s1)
    800021b4:	ff279be3          	bne	a5,s2,800021aa <reparent+0x2c>
      pp->parent = initproc;
    800021b8:	000a3503          	ld	a0,0(s4)
    800021bc:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800021be:	00000097          	auipc	ra,0x0
    800021c2:	f4a080e7          	jalr	-182(ra) # 80002108 <wakeup>
    800021c6:	b7d5                	j	800021aa <reparent+0x2c>
}
    800021c8:	70a2                	ld	ra,40(sp)
    800021ca:	7402                	ld	s0,32(sp)
    800021cc:	64e2                	ld	s1,24(sp)
    800021ce:	6942                	ld	s2,16(sp)
    800021d0:	69a2                	ld	s3,8(sp)
    800021d2:	6a02                	ld	s4,0(sp)
    800021d4:	6145                	addi	sp,sp,48
    800021d6:	8082                	ret

00000000800021d8 <exit>:
{
    800021d8:	7179                	addi	sp,sp,-48
    800021da:	f406                	sd	ra,40(sp)
    800021dc:	f022                	sd	s0,32(sp)
    800021de:	ec26                	sd	s1,24(sp)
    800021e0:	e84a                	sd	s2,16(sp)
    800021e2:	e44e                	sd	s3,8(sp)
    800021e4:	e052                	sd	s4,0(sp)
    800021e6:	1800                	addi	s0,sp,48
    800021e8:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021ea:	fffff097          	auipc	ra,0xfffff
    800021ee:	7fe080e7          	jalr	2046(ra) # 800019e8 <myproc>
    800021f2:	89aa                	mv	s3,a0
  if(p == initproc)
    800021f4:	00006797          	auipc	a5,0x6
    800021f8:	7547b783          	ld	a5,1876(a5) # 80008948 <initproc>
    800021fc:	0d050493          	addi	s1,a0,208
    80002200:	15050913          	addi	s2,a0,336
    80002204:	02a79363          	bne	a5,a0,8000222a <exit+0x52>
    panic("init exiting");
    80002208:	00006517          	auipc	a0,0x6
    8000220c:	05850513          	addi	a0,a0,88 # 80008260 <digits+0x220>
    80002210:	ffffe097          	auipc	ra,0xffffe
    80002214:	334080e7          	jalr	820(ra) # 80000544 <panic>
      fileclose(f);
    80002218:	00002097          	auipc	ra,0x2
    8000221c:	4ac080e7          	jalr	1196(ra) # 800046c4 <fileclose>
      p->ofile[fd] = 0;
    80002220:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002224:	04a1                	addi	s1,s1,8
    80002226:	01248563          	beq	s1,s2,80002230 <exit+0x58>
    if(p->ofile[fd]){
    8000222a:	6088                	ld	a0,0(s1)
    8000222c:	f575                	bnez	a0,80002218 <exit+0x40>
    8000222e:	bfdd                	j	80002224 <exit+0x4c>
  begin_op();
    80002230:	00002097          	auipc	ra,0x2
    80002234:	fc8080e7          	jalr	-56(ra) # 800041f8 <begin_op>
  iput(p->cwd);
    80002238:	1509b503          	ld	a0,336(s3)
    8000223c:	00001097          	auipc	ra,0x1
    80002240:	7b4080e7          	jalr	1972(ra) # 800039f0 <iput>
  end_op();
    80002244:	00002097          	auipc	ra,0x2
    80002248:	034080e7          	jalr	52(ra) # 80004278 <end_op>
  p->cwd = 0;
    8000224c:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002250:	0000f497          	auipc	s1,0xf
    80002254:	98848493          	addi	s1,s1,-1656 # 80010bd8 <wait_lock>
    80002258:	8526                	mv	a0,s1
    8000225a:	fffff097          	auipc	ra,0xfffff
    8000225e:	9b2080e7          	jalr	-1614(ra) # 80000c0c <acquire>
  reparent(p);
    80002262:	854e                	mv	a0,s3
    80002264:	00000097          	auipc	ra,0x0
    80002268:	f1a080e7          	jalr	-230(ra) # 8000217e <reparent>
  wakeup(p->parent);
    8000226c:	0389b503          	ld	a0,56(s3)
    80002270:	00000097          	auipc	ra,0x0
    80002274:	e98080e7          	jalr	-360(ra) # 80002108 <wakeup>
  acquire(&p->lock);
    80002278:	854e                	mv	a0,s3
    8000227a:	fffff097          	auipc	ra,0xfffff
    8000227e:	992080e7          	jalr	-1646(ra) # 80000c0c <acquire>
  p->xstate = status;
    80002282:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002286:	4795                	li	a5,5
    80002288:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000228c:	8526                	mv	a0,s1
    8000228e:	fffff097          	auipc	ra,0xfffff
    80002292:	a32080e7          	jalr	-1486(ra) # 80000cc0 <release>
  sched();
    80002296:	00000097          	auipc	ra,0x0
    8000229a:	cfc080e7          	jalr	-772(ra) # 80001f92 <sched>
  panic("zombie exit");
    8000229e:	00006517          	auipc	a0,0x6
    800022a2:	fd250513          	addi	a0,a0,-46 # 80008270 <digits+0x230>
    800022a6:	ffffe097          	auipc	ra,0xffffe
    800022aa:	29e080e7          	jalr	670(ra) # 80000544 <panic>

00000000800022ae <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800022ae:	7179                	addi	sp,sp,-48
    800022b0:	f406                	sd	ra,40(sp)
    800022b2:	f022                	sd	s0,32(sp)
    800022b4:	ec26                	sd	s1,24(sp)
    800022b6:	e84a                	sd	s2,16(sp)
    800022b8:	e44e                	sd	s3,8(sp)
    800022ba:	1800                	addi	s0,sp,48
    800022bc:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800022be:	0000f497          	auipc	s1,0xf
    800022c2:	e3248493          	addi	s1,s1,-462 # 800110f0 <proc>
    800022c6:	00015997          	auipc	s3,0x15
    800022ca:	82a98993          	addi	s3,s3,-2006 # 80016af0 <tickslock>
    acquire(&p->lock);
    800022ce:	8526                	mv	a0,s1
    800022d0:	fffff097          	auipc	ra,0xfffff
    800022d4:	93c080e7          	jalr	-1732(ra) # 80000c0c <acquire>
    if(p->pid == pid){
    800022d8:	589c                	lw	a5,48(s1)
    800022da:	01278d63          	beq	a5,s2,800022f4 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022de:	8526                	mv	a0,s1
    800022e0:	fffff097          	auipc	ra,0xfffff
    800022e4:	9e0080e7          	jalr	-1568(ra) # 80000cc0 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800022e8:	16848493          	addi	s1,s1,360
    800022ec:	ff3491e3          	bne	s1,s3,800022ce <kill+0x20>
  }
  return -1;
    800022f0:	557d                	li	a0,-1
    800022f2:	a829                	j	8000230c <kill+0x5e>
      p->killed = 1;
    800022f4:	4785                	li	a5,1
    800022f6:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800022f8:	4c98                	lw	a4,24(s1)
    800022fa:	4789                	li	a5,2
    800022fc:	00f70f63          	beq	a4,a5,8000231a <kill+0x6c>
      release(&p->lock);
    80002300:	8526                	mv	a0,s1
    80002302:	fffff097          	auipc	ra,0xfffff
    80002306:	9be080e7          	jalr	-1602(ra) # 80000cc0 <release>
      return 0;
    8000230a:	4501                	li	a0,0
}
    8000230c:	70a2                	ld	ra,40(sp)
    8000230e:	7402                	ld	s0,32(sp)
    80002310:	64e2                	ld	s1,24(sp)
    80002312:	6942                	ld	s2,16(sp)
    80002314:	69a2                	ld	s3,8(sp)
    80002316:	6145                	addi	sp,sp,48
    80002318:	8082                	ret
        p->state = RUNNABLE;
    8000231a:	478d                	li	a5,3
    8000231c:	cc9c                	sw	a5,24(s1)
    8000231e:	b7cd                	j	80002300 <kill+0x52>

0000000080002320 <setkilled>:

void
setkilled(struct proc *p)
{
    80002320:	1101                	addi	sp,sp,-32
    80002322:	ec06                	sd	ra,24(sp)
    80002324:	e822                	sd	s0,16(sp)
    80002326:	e426                	sd	s1,8(sp)
    80002328:	1000                	addi	s0,sp,32
    8000232a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000232c:	fffff097          	auipc	ra,0xfffff
    80002330:	8e0080e7          	jalr	-1824(ra) # 80000c0c <acquire>
  p->killed = 1;
    80002334:	4785                	li	a5,1
    80002336:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002338:	8526                	mv	a0,s1
    8000233a:	fffff097          	auipc	ra,0xfffff
    8000233e:	986080e7          	jalr	-1658(ra) # 80000cc0 <release>
}
    80002342:	60e2                	ld	ra,24(sp)
    80002344:	6442                	ld	s0,16(sp)
    80002346:	64a2                	ld	s1,8(sp)
    80002348:	6105                	addi	sp,sp,32
    8000234a:	8082                	ret

000000008000234c <killed>:

int
killed(struct proc *p)
{
    8000234c:	1101                	addi	sp,sp,-32
    8000234e:	ec06                	sd	ra,24(sp)
    80002350:	e822                	sd	s0,16(sp)
    80002352:	e426                	sd	s1,8(sp)
    80002354:	e04a                	sd	s2,0(sp)
    80002356:	1000                	addi	s0,sp,32
    80002358:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	8b2080e7          	jalr	-1870(ra) # 80000c0c <acquire>
  k = p->killed;
    80002362:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002366:	8526                	mv	a0,s1
    80002368:	fffff097          	auipc	ra,0xfffff
    8000236c:	958080e7          	jalr	-1704(ra) # 80000cc0 <release>
  return k;
}
    80002370:	854a                	mv	a0,s2
    80002372:	60e2                	ld	ra,24(sp)
    80002374:	6442                	ld	s0,16(sp)
    80002376:	64a2                	ld	s1,8(sp)
    80002378:	6902                	ld	s2,0(sp)
    8000237a:	6105                	addi	sp,sp,32
    8000237c:	8082                	ret

000000008000237e <wait>:
{
    8000237e:	715d                	addi	sp,sp,-80
    80002380:	e486                	sd	ra,72(sp)
    80002382:	e0a2                	sd	s0,64(sp)
    80002384:	fc26                	sd	s1,56(sp)
    80002386:	f84a                	sd	s2,48(sp)
    80002388:	f44e                	sd	s3,40(sp)
    8000238a:	f052                	sd	s4,32(sp)
    8000238c:	ec56                	sd	s5,24(sp)
    8000238e:	e85a                	sd	s6,16(sp)
    80002390:	e45e                	sd	s7,8(sp)
    80002392:	e062                	sd	s8,0(sp)
    80002394:	0880                	addi	s0,sp,80
    80002396:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	650080e7          	jalr	1616(ra) # 800019e8 <myproc>
    800023a0:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023a2:	0000f517          	auipc	a0,0xf
    800023a6:	83650513          	addi	a0,a0,-1994 # 80010bd8 <wait_lock>
    800023aa:	fffff097          	auipc	ra,0xfffff
    800023ae:	862080e7          	jalr	-1950(ra) # 80000c0c <acquire>
    havekids = 0;
    800023b2:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    800023b4:	4a15                	li	s4,5
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023b6:	00014997          	auipc	s3,0x14
    800023ba:	73a98993          	addi	s3,s3,1850 # 80016af0 <tickslock>
        havekids = 1;
    800023be:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023c0:	0000fc17          	auipc	s8,0xf
    800023c4:	818c0c13          	addi	s8,s8,-2024 # 80010bd8 <wait_lock>
    havekids = 0;
    800023c8:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023ca:	0000f497          	auipc	s1,0xf
    800023ce:	d2648493          	addi	s1,s1,-730 # 800110f0 <proc>
    800023d2:	a0bd                	j	80002440 <wait+0xc2>
          pid = pp->pid;
    800023d4:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800023d8:	000b0e63          	beqz	s6,800023f4 <wait+0x76>
    800023dc:	4691                	li	a3,4
    800023de:	02c48613          	addi	a2,s1,44
    800023e2:	85da                	mv	a1,s6
    800023e4:	05093503          	ld	a0,80(s2)
    800023e8:	fffff097          	auipc	ra,0xfffff
    800023ec:	2be080e7          	jalr	702(ra) # 800016a6 <copyout>
    800023f0:	02054563          	bltz	a0,8000241a <wait+0x9c>
          freeproc(pp);
    800023f4:	8526                	mv	a0,s1
    800023f6:	fffff097          	auipc	ra,0xfffff
    800023fa:	7a4080e7          	jalr	1956(ra) # 80001b9a <freeproc>
          release(&pp->lock);
    800023fe:	8526                	mv	a0,s1
    80002400:	fffff097          	auipc	ra,0xfffff
    80002404:	8c0080e7          	jalr	-1856(ra) # 80000cc0 <release>
          release(&wait_lock);
    80002408:	0000e517          	auipc	a0,0xe
    8000240c:	7d050513          	addi	a0,a0,2000 # 80010bd8 <wait_lock>
    80002410:	fffff097          	auipc	ra,0xfffff
    80002414:	8b0080e7          	jalr	-1872(ra) # 80000cc0 <release>
          return pid;
    80002418:	a0b5                	j	80002484 <wait+0x106>
            release(&pp->lock);
    8000241a:	8526                	mv	a0,s1
    8000241c:	fffff097          	auipc	ra,0xfffff
    80002420:	8a4080e7          	jalr	-1884(ra) # 80000cc0 <release>
            release(&wait_lock);
    80002424:	0000e517          	auipc	a0,0xe
    80002428:	7b450513          	addi	a0,a0,1972 # 80010bd8 <wait_lock>
    8000242c:	fffff097          	auipc	ra,0xfffff
    80002430:	894080e7          	jalr	-1900(ra) # 80000cc0 <release>
            return -1;
    80002434:	59fd                	li	s3,-1
    80002436:	a0b9                	j	80002484 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002438:	16848493          	addi	s1,s1,360
    8000243c:	03348463          	beq	s1,s3,80002464 <wait+0xe6>
      if(pp->parent == p){
    80002440:	7c9c                	ld	a5,56(s1)
    80002442:	ff279be3          	bne	a5,s2,80002438 <wait+0xba>
        acquire(&pp->lock);
    80002446:	8526                	mv	a0,s1
    80002448:	ffffe097          	auipc	ra,0xffffe
    8000244c:	7c4080e7          	jalr	1988(ra) # 80000c0c <acquire>
        if(pp->state == ZOMBIE){
    80002450:	4c9c                	lw	a5,24(s1)
    80002452:	f94781e3          	beq	a5,s4,800023d4 <wait+0x56>
        release(&pp->lock);
    80002456:	8526                	mv	a0,s1
    80002458:	fffff097          	auipc	ra,0xfffff
    8000245c:	868080e7          	jalr	-1944(ra) # 80000cc0 <release>
        havekids = 1;
    80002460:	8756                	mv	a4,s5
    80002462:	bfd9                	j	80002438 <wait+0xba>
    if(!havekids || killed(p)){
    80002464:	c719                	beqz	a4,80002472 <wait+0xf4>
    80002466:	854a                	mv	a0,s2
    80002468:	00000097          	auipc	ra,0x0
    8000246c:	ee4080e7          	jalr	-284(ra) # 8000234c <killed>
    80002470:	c51d                	beqz	a0,8000249e <wait+0x120>
      release(&wait_lock);
    80002472:	0000e517          	auipc	a0,0xe
    80002476:	76650513          	addi	a0,a0,1894 # 80010bd8 <wait_lock>
    8000247a:	fffff097          	auipc	ra,0xfffff
    8000247e:	846080e7          	jalr	-1978(ra) # 80000cc0 <release>
      return -1;
    80002482:	59fd                	li	s3,-1
}
    80002484:	854e                	mv	a0,s3
    80002486:	60a6                	ld	ra,72(sp)
    80002488:	6406                	ld	s0,64(sp)
    8000248a:	74e2                	ld	s1,56(sp)
    8000248c:	7942                	ld	s2,48(sp)
    8000248e:	79a2                	ld	s3,40(sp)
    80002490:	7a02                	ld	s4,32(sp)
    80002492:	6ae2                	ld	s5,24(sp)
    80002494:	6b42                	ld	s6,16(sp)
    80002496:	6ba2                	ld	s7,8(sp)
    80002498:	6c02                	ld	s8,0(sp)
    8000249a:	6161                	addi	sp,sp,80
    8000249c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000249e:	85e2                	mv	a1,s8
    800024a0:	854a                	mv	a0,s2
    800024a2:	00000097          	auipc	ra,0x0
    800024a6:	c02080e7          	jalr	-1022(ra) # 800020a4 <sleep>
    havekids = 0;
    800024aa:	bf39                	j	800023c8 <wait+0x4a>

00000000800024ac <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024ac:	7179                	addi	sp,sp,-48
    800024ae:	f406                	sd	ra,40(sp)
    800024b0:	f022                	sd	s0,32(sp)
    800024b2:	ec26                	sd	s1,24(sp)
    800024b4:	e84a                	sd	s2,16(sp)
    800024b6:	e44e                	sd	s3,8(sp)
    800024b8:	e052                	sd	s4,0(sp)
    800024ba:	1800                	addi	s0,sp,48
    800024bc:	84aa                	mv	s1,a0
    800024be:	892e                	mv	s2,a1
    800024c0:	89b2                	mv	s3,a2
    800024c2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024c4:	fffff097          	auipc	ra,0xfffff
    800024c8:	524080e7          	jalr	1316(ra) # 800019e8 <myproc>
  if(user_dst){
    800024cc:	c08d                	beqz	s1,800024ee <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024ce:	86d2                	mv	a3,s4
    800024d0:	864e                	mv	a2,s3
    800024d2:	85ca                	mv	a1,s2
    800024d4:	6928                	ld	a0,80(a0)
    800024d6:	fffff097          	auipc	ra,0xfffff
    800024da:	1d0080e7          	jalr	464(ra) # 800016a6 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024de:	70a2                	ld	ra,40(sp)
    800024e0:	7402                	ld	s0,32(sp)
    800024e2:	64e2                	ld	s1,24(sp)
    800024e4:	6942                	ld	s2,16(sp)
    800024e6:	69a2                	ld	s3,8(sp)
    800024e8:	6a02                	ld	s4,0(sp)
    800024ea:	6145                	addi	sp,sp,48
    800024ec:	8082                	ret
    memmove((char *)dst, src, len);
    800024ee:	000a061b          	sext.w	a2,s4
    800024f2:	85ce                	mv	a1,s3
    800024f4:	854a                	mv	a0,s2
    800024f6:	fffff097          	auipc	ra,0xfffff
    800024fa:	872080e7          	jalr	-1934(ra) # 80000d68 <memmove>
    return 0;
    800024fe:	8526                	mv	a0,s1
    80002500:	bff9                	j	800024de <either_copyout+0x32>

0000000080002502 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002502:	7179                	addi	sp,sp,-48
    80002504:	f406                	sd	ra,40(sp)
    80002506:	f022                	sd	s0,32(sp)
    80002508:	ec26                	sd	s1,24(sp)
    8000250a:	e84a                	sd	s2,16(sp)
    8000250c:	e44e                	sd	s3,8(sp)
    8000250e:	e052                	sd	s4,0(sp)
    80002510:	1800                	addi	s0,sp,48
    80002512:	892a                	mv	s2,a0
    80002514:	84ae                	mv	s1,a1
    80002516:	89b2                	mv	s3,a2
    80002518:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000251a:	fffff097          	auipc	ra,0xfffff
    8000251e:	4ce080e7          	jalr	1230(ra) # 800019e8 <myproc>
  if(user_src){
    80002522:	c08d                	beqz	s1,80002544 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002524:	86d2                	mv	a3,s4
    80002526:	864e                	mv	a2,s3
    80002528:	85ca                	mv	a1,s2
    8000252a:	6928                	ld	a0,80(a0)
    8000252c:	fffff097          	auipc	ra,0xfffff
    80002530:	206080e7          	jalr	518(ra) # 80001732 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002534:	70a2                	ld	ra,40(sp)
    80002536:	7402                	ld	s0,32(sp)
    80002538:	64e2                	ld	s1,24(sp)
    8000253a:	6942                	ld	s2,16(sp)
    8000253c:	69a2                	ld	s3,8(sp)
    8000253e:	6a02                	ld	s4,0(sp)
    80002540:	6145                	addi	sp,sp,48
    80002542:	8082                	ret
    memmove(dst, (char*)src, len);
    80002544:	000a061b          	sext.w	a2,s4
    80002548:	85ce                	mv	a1,s3
    8000254a:	854a                	mv	a0,s2
    8000254c:	fffff097          	auipc	ra,0xfffff
    80002550:	81c080e7          	jalr	-2020(ra) # 80000d68 <memmove>
    return 0;
    80002554:	8526                	mv	a0,s1
    80002556:	bff9                	j	80002534 <either_copyin+0x32>

0000000080002558 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002558:	715d                	addi	sp,sp,-80
    8000255a:	e486                	sd	ra,72(sp)
    8000255c:	e0a2                	sd	s0,64(sp)
    8000255e:	fc26                	sd	s1,56(sp)
    80002560:	f84a                	sd	s2,48(sp)
    80002562:	f44e                	sd	s3,40(sp)
    80002564:	f052                	sd	s4,32(sp)
    80002566:	ec56                	sd	s5,24(sp)
    80002568:	e85a                	sd	s6,16(sp)
    8000256a:	e45e                	sd	s7,8(sp)
    8000256c:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000256e:	00006517          	auipc	a0,0x6
    80002572:	b5a50513          	addi	a0,a0,-1190 # 800080c8 <digits+0x88>
    80002576:	ffffe097          	auipc	ra,0xffffe
    8000257a:	018080e7          	jalr	24(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000257e:	0000f497          	auipc	s1,0xf
    80002582:	cca48493          	addi	s1,s1,-822 # 80011248 <proc+0x158>
    80002586:	00014917          	auipc	s2,0x14
    8000258a:	6c290913          	addi	s2,s2,1730 # 80016c48 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000258e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002590:	00006997          	auipc	s3,0x6
    80002594:	cf098993          	addi	s3,s3,-784 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002598:	00006a97          	auipc	s5,0x6
    8000259c:	cf0a8a93          	addi	s5,s5,-784 # 80008288 <digits+0x248>
    printf("\n");
    800025a0:	00006a17          	auipc	s4,0x6
    800025a4:	b28a0a13          	addi	s4,s4,-1240 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025a8:	00006b97          	auipc	s7,0x6
    800025ac:	d70b8b93          	addi	s7,s7,-656 # 80008318 <states.1737>
    800025b0:	a00d                	j	800025d2 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025b2:	ed86a583          	lw	a1,-296(a3)
    800025b6:	8556                	mv	a0,s5
    800025b8:	ffffe097          	auipc	ra,0xffffe
    800025bc:	fd6080e7          	jalr	-42(ra) # 8000058e <printf>
    printf("\n");
    800025c0:	8552                	mv	a0,s4
    800025c2:	ffffe097          	auipc	ra,0xffffe
    800025c6:	fcc080e7          	jalr	-52(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025ca:	16848493          	addi	s1,s1,360
    800025ce:	03248163          	beq	s1,s2,800025f0 <procdump+0x98>
    if(p->state == UNUSED)
    800025d2:	86a6                	mv	a3,s1
    800025d4:	ec04a783          	lw	a5,-320(s1)
    800025d8:	dbed                	beqz	a5,800025ca <procdump+0x72>
      state = "???";
    800025da:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025dc:	fcfb6be3          	bltu	s6,a5,800025b2 <procdump+0x5a>
    800025e0:	1782                	slli	a5,a5,0x20
    800025e2:	9381                	srli	a5,a5,0x20
    800025e4:	078e                	slli	a5,a5,0x3
    800025e6:	97de                	add	a5,a5,s7
    800025e8:	6390                	ld	a2,0(a5)
    800025ea:	f661                	bnez	a2,800025b2 <procdump+0x5a>
      state = "???";
    800025ec:	864e                	mv	a2,s3
    800025ee:	b7d1                	j	800025b2 <procdump+0x5a>
  }
}
    800025f0:	60a6                	ld	ra,72(sp)
    800025f2:	6406                	ld	s0,64(sp)
    800025f4:	74e2                	ld	s1,56(sp)
    800025f6:	7942                	ld	s2,48(sp)
    800025f8:	79a2                	ld	s3,40(sp)
    800025fa:	7a02                	ld	s4,32(sp)
    800025fc:	6ae2                	ld	s5,24(sp)
    800025fe:	6b42                	ld	s6,16(sp)
    80002600:	6ba2                	ld	s7,8(sp)
    80002602:	6161                	addi	sp,sp,80
    80002604:	8082                	ret

0000000080002606 <hello>:


void hello(void)
{
    80002606:	1141                	addi	sp,sp,-16
    80002608:	e406                	sd	ra,8(sp)
    8000260a:	e022                	sd	s0,0(sp)
    8000260c:	0800                	addi	s0,sp,16
  printf("Hello world, from kernel\n");
    8000260e:	00006517          	auipc	a0,0x6
    80002612:	c8a50513          	addi	a0,a0,-886 # 80008298 <digits+0x258>
    80002616:	ffffe097          	auipc	ra,0xffffe
    8000261a:	f78080e7          	jalr	-136(ra) # 8000058e <printf>
}
    8000261e:	60a2                	ld	ra,8(sp)
    80002620:	6402                	ld	s0,0(sp)
    80002622:	0141                	addi	sp,sp,16
    80002624:	8082                	ret

0000000080002626 <sysinfo>:

int sysinfo(int param)
{
    80002626:	1101                	addi	sp,sp,-32
    80002628:	ec06                	sd	ra,24(sp)
    8000262a:	e822                	sd	s0,16(sp)
    8000262c:	e426                	sd	s1,8(sp)
    8000262e:	1000                	addi	s0,sp,32
    80002630:	84aa                	mv	s1,a0
  struct proc * p = myproc();// struct proc * p = myproc();
    80002632:	fffff097          	auipc	ra,0xfffff
    80002636:	3b6080e7          	jalr	950(ra) # 800019e8 <myproc>
  int number_result = 0; //initialize

  if (param == 0)
    8000263a:	c085                	beqz	s1,8000265a <sysinfo+0x34>
    }
    printf("Total number of active processes in the system:");
    return number_result;
  }

  else if (param == 1)
    8000263c:	4785                	li	a5,1
    8000263e:	04f48963          	beq	s1,a5,80002690 <sysinfo+0x6a>
  {
    // printf("Total number of system calls since boot up: %d", systemcall_count[p->pid]);
    return systemcallcount -1;
  }

  else if (param == 2)
    80002642:	4789                	li	a5,2
    80002644:	04f49c63          	bne	s1,a5,8000269c <sysinfo+0x76>
  {
    // printf("The number of free memory pages in the system:");
    return free_memory_pages();
    80002648:	ffffe097          	auipc	ra,0xffffe
    8000264c:	512080e7          	jalr	1298(ra) # 80000b5a <free_memory_pages>
  }
  return -1;
}
    80002650:	60e2                	ld	ra,24(sp)
    80002652:	6442                	ld	s0,16(sp)
    80002654:	64a2                	ld	s1,8(sp)
    80002656:	6105                	addi	sp,sp,32
    80002658:	8082                	ret
    for(p = proc; p < &proc[NPROC]; p++)
    8000265a:	0000f797          	auipc	a5,0xf
    8000265e:	a9678793          	addi	a5,a5,-1386 # 800110f0 <proc>
    80002662:	00014697          	auipc	a3,0x14
    80002666:	48e68693          	addi	a3,a3,1166 # 80016af0 <tickslock>
    8000266a:	a029                	j	80002674 <sysinfo+0x4e>
    8000266c:	16878793          	addi	a5,a5,360
    80002670:	00d78663          	beq	a5,a3,8000267c <sysinfo+0x56>
      if(p->state != UNUSED)
    80002674:	4f98                	lw	a4,24(a5)
    80002676:	db7d                	beqz	a4,8000266c <sysinfo+0x46>
        number_result++;
    80002678:	2485                	addiw	s1,s1,1
    8000267a:	bfcd                	j	8000266c <sysinfo+0x46>
    printf("Total number of active processes in the system:");
    8000267c:	00006517          	auipc	a0,0x6
    80002680:	c3c50513          	addi	a0,a0,-964 # 800082b8 <digits+0x278>
    80002684:	ffffe097          	auipc	ra,0xffffe
    80002688:	f0a080e7          	jalr	-246(ra) # 8000058e <printf>
    return number_result;
    8000268c:	8526                	mv	a0,s1
    8000268e:	b7c9                	j	80002650 <sysinfo+0x2a>
    return systemcallcount -1;
    80002690:	00006517          	auipc	a0,0x6
    80002694:	2c452503          	lw	a0,708(a0) # 80008954 <systemcallcount>
    80002698:	357d                	addiw	a0,a0,-1
    8000269a:	bf5d                	j	80002650 <sysinfo+0x2a>
  return -1;
    8000269c:	557d                	li	a0,-1
    8000269e:	bf4d                	j	80002650 <sysinfo+0x2a>

00000000800026a0 <procinfo>:

int procinfo(struct pinfo *in)
{
    800026a0:	7179                	addi	sp,sp,-48
    800026a2:	f406                	sd	ra,40(sp)
    800026a4:	f022                	sd	s0,32(sp)
    800026a6:	ec26                	sd	s1,24(sp)
    800026a8:	e84a                	sd	s2,16(sp)
    800026aa:	1800                	addi	s0,sp,48
    800026ac:	892a                	mv	s2,a0
  struct proc * p = myproc();
    800026ae:	fffff097          	auipc	ra,0xfffff
    800026b2:	33a080e7          	jalr	826(ra) # 800019e8 <myproc>
    800026b6:	84aa                	mv	s1,a0

  int n = p->parent->pid;
    800026b8:	7d1c                	ld	a5,56(a0)
    800026ba:	5b9c                	lw	a5,48(a5)
    800026bc:	fcf42e23          	sw	a5,-36(s0)
  copyout(p->pagetable, (uint64)&in->ppid, (char *)&n, sizeof(n));
    800026c0:	4691                	li	a3,4
    800026c2:	fdc40613          	addi	a2,s0,-36
    800026c6:	85ca                	mv	a1,s2
    800026c8:	6928                	ld	a0,80(a0)
    800026ca:	fffff097          	auipc	ra,0xfffff
    800026ce:	fdc080e7          	jalr	-36(ra) # 800016a6 <copyout>

  int m = systemcall_count[p->pid];
    800026d2:	589c                	lw	a5,48(s1)
    800026d4:	00279713          	slli	a4,a5,0x2
    800026d8:	0000e797          	auipc	a5,0xe
    800026dc:	4e878793          	addi	a5,a5,1256 # 80010bc0 <pid_lock>
    800026e0:	97ba                	add	a5,a5,a4
    800026e2:	4307a783          	lw	a5,1072(a5)
    800026e6:	fcf42c23          	sw	a5,-40(s0)
  copyout(p->pagetable, (uint64)&in->syscall_count, (char *)&m, sizeof(m));
    800026ea:	4691                	li	a3,4
    800026ec:	fd840613          	addi	a2,s0,-40
    800026f0:	00490593          	addi	a1,s2,4
    800026f4:	68a8                	ld	a0,80(s1)
    800026f6:	fffff097          	auipc	ra,0xfffff
    800026fa:	fb0080e7          	jalr	-80(ra) # 800016a6 <copyout>
  
  uint64 mem_size = p->sz; //memory size of process
  int mem_page = (PGROUNDUP(mem_size))/PGSIZE; // page size
    800026fe:	64bc                	ld	a5,72(s1)
    80002700:	6705                	lui	a4,0x1
    80002702:	177d                	addi	a4,a4,-1
    80002704:	97ba                	add	a5,a5,a4
    80002706:	83b1                	srli	a5,a5,0xc
    80002708:	fcf42a23          	sw	a5,-44(s0)

  copyout(p->pagetable, (uint64)&in->page_usage, (char *)&mem_page, sizeof(mem_page));
    8000270c:	4691                	li	a3,4
    8000270e:	fd440613          	addi	a2,s0,-44
    80002712:	00890593          	addi	a1,s2,8
    80002716:	68a8                	ld	a0,80(s1)
    80002718:	fffff097          	auipc	ra,0xfffff
    8000271c:	f8e080e7          	jalr	-114(ra) # 800016a6 <copyout>
  
  return 0;
    80002720:	4501                	li	a0,0
    80002722:	70a2                	ld	ra,40(sp)
    80002724:	7402                	ld	s0,32(sp)
    80002726:	64e2                	ld	s1,24(sp)
    80002728:	6942                	ld	s2,16(sp)
    8000272a:	6145                	addi	sp,sp,48
    8000272c:	8082                	ret

000000008000272e <swtch>:
    8000272e:	00153023          	sd	ra,0(a0)
    80002732:	00253423          	sd	sp,8(a0)
    80002736:	e900                	sd	s0,16(a0)
    80002738:	ed04                	sd	s1,24(a0)
    8000273a:	03253023          	sd	s2,32(a0)
    8000273e:	03353423          	sd	s3,40(a0)
    80002742:	03453823          	sd	s4,48(a0)
    80002746:	03553c23          	sd	s5,56(a0)
    8000274a:	05653023          	sd	s6,64(a0)
    8000274e:	05753423          	sd	s7,72(a0)
    80002752:	05853823          	sd	s8,80(a0)
    80002756:	05953c23          	sd	s9,88(a0)
    8000275a:	07a53023          	sd	s10,96(a0)
    8000275e:	07b53423          	sd	s11,104(a0)
    80002762:	0005b083          	ld	ra,0(a1)
    80002766:	0085b103          	ld	sp,8(a1)
    8000276a:	6980                	ld	s0,16(a1)
    8000276c:	6d84                	ld	s1,24(a1)
    8000276e:	0205b903          	ld	s2,32(a1)
    80002772:	0285b983          	ld	s3,40(a1)
    80002776:	0305ba03          	ld	s4,48(a1)
    8000277a:	0385ba83          	ld	s5,56(a1)
    8000277e:	0405bb03          	ld	s6,64(a1)
    80002782:	0485bb83          	ld	s7,72(a1)
    80002786:	0505bc03          	ld	s8,80(a1)
    8000278a:	0585bc83          	ld	s9,88(a1)
    8000278e:	0605bd03          	ld	s10,96(a1)
    80002792:	0685bd83          	ld	s11,104(a1)
    80002796:	8082                	ret

0000000080002798 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002798:	1141                	addi	sp,sp,-16
    8000279a:	e406                	sd	ra,8(sp)
    8000279c:	e022                	sd	s0,0(sp)
    8000279e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800027a0:	00006597          	auipc	a1,0x6
    800027a4:	ba858593          	addi	a1,a1,-1112 # 80008348 <states.1737+0x30>
    800027a8:	00014517          	auipc	a0,0x14
    800027ac:	34850513          	addi	a0,a0,840 # 80016af0 <tickslock>
    800027b0:	ffffe097          	auipc	ra,0xffffe
    800027b4:	3cc080e7          	jalr	972(ra) # 80000b7c <initlock>
}
    800027b8:	60a2                	ld	ra,8(sp)
    800027ba:	6402                	ld	s0,0(sp)
    800027bc:	0141                	addi	sp,sp,16
    800027be:	8082                	ret

00000000800027c0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800027c0:	1141                	addi	sp,sp,-16
    800027c2:	e422                	sd	s0,8(sp)
    800027c4:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027c6:	00003797          	auipc	a5,0x3
    800027ca:	53a78793          	addi	a5,a5,1338 # 80005d00 <kernelvec>
    800027ce:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800027d2:	6422                	ld	s0,8(sp)
    800027d4:	0141                	addi	sp,sp,16
    800027d6:	8082                	ret

00000000800027d8 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800027d8:	1141                	addi	sp,sp,-16
    800027da:	e406                	sd	ra,8(sp)
    800027dc:	e022                	sd	s0,0(sp)
    800027de:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800027e0:	fffff097          	auipc	ra,0xfffff
    800027e4:	208080e7          	jalr	520(ra) # 800019e8 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027e8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800027ec:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027ee:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800027f2:	00005617          	auipc	a2,0x5
    800027f6:	80e60613          	addi	a2,a2,-2034 # 80007000 <_trampoline>
    800027fa:	00005697          	auipc	a3,0x5
    800027fe:	80668693          	addi	a3,a3,-2042 # 80007000 <_trampoline>
    80002802:	8e91                	sub	a3,a3,a2
    80002804:	040007b7          	lui	a5,0x4000
    80002808:	17fd                	addi	a5,a5,-1
    8000280a:	07b2                	slli	a5,a5,0xc
    8000280c:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000280e:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002812:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002814:	180026f3          	csrr	a3,satp
    80002818:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000281a:	6d38                	ld	a4,88(a0)
    8000281c:	6134                	ld	a3,64(a0)
    8000281e:	6585                	lui	a1,0x1
    80002820:	96ae                	add	a3,a3,a1
    80002822:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002824:	6d38                	ld	a4,88(a0)
    80002826:	00000697          	auipc	a3,0x0
    8000282a:	13068693          	addi	a3,a3,304 # 80002956 <usertrap>
    8000282e:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002830:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002832:	8692                	mv	a3,tp
    80002834:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002836:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000283a:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000283e:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002842:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002846:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002848:	6f18                	ld	a4,24(a4)
    8000284a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000284e:	6928                	ld	a0,80(a0)
    80002850:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002852:	00005717          	auipc	a4,0x5
    80002856:	84a70713          	addi	a4,a4,-1974 # 8000709c <userret>
    8000285a:	8f11                	sub	a4,a4,a2
    8000285c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    8000285e:	577d                	li	a4,-1
    80002860:	177e                	slli	a4,a4,0x3f
    80002862:	8d59                	or	a0,a0,a4
    80002864:	9782                	jalr	a5
}
    80002866:	60a2                	ld	ra,8(sp)
    80002868:	6402                	ld	s0,0(sp)
    8000286a:	0141                	addi	sp,sp,16
    8000286c:	8082                	ret

000000008000286e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000286e:	1101                	addi	sp,sp,-32
    80002870:	ec06                	sd	ra,24(sp)
    80002872:	e822                	sd	s0,16(sp)
    80002874:	e426                	sd	s1,8(sp)
    80002876:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002878:	00014497          	auipc	s1,0x14
    8000287c:	27848493          	addi	s1,s1,632 # 80016af0 <tickslock>
    80002880:	8526                	mv	a0,s1
    80002882:	ffffe097          	auipc	ra,0xffffe
    80002886:	38a080e7          	jalr	906(ra) # 80000c0c <acquire>
  ticks++;
    8000288a:	00006517          	auipc	a0,0x6
    8000288e:	0c650513          	addi	a0,a0,198 # 80008950 <ticks>
    80002892:	411c                	lw	a5,0(a0)
    80002894:	2785                	addiw	a5,a5,1
    80002896:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002898:	00000097          	auipc	ra,0x0
    8000289c:	870080e7          	jalr	-1936(ra) # 80002108 <wakeup>
  release(&tickslock);
    800028a0:	8526                	mv	a0,s1
    800028a2:	ffffe097          	auipc	ra,0xffffe
    800028a6:	41e080e7          	jalr	1054(ra) # 80000cc0 <release>
}
    800028aa:	60e2                	ld	ra,24(sp)
    800028ac:	6442                	ld	s0,16(sp)
    800028ae:	64a2                	ld	s1,8(sp)
    800028b0:	6105                	addi	sp,sp,32
    800028b2:	8082                	ret

00000000800028b4 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800028b4:	1101                	addi	sp,sp,-32
    800028b6:	ec06                	sd	ra,24(sp)
    800028b8:	e822                	sd	s0,16(sp)
    800028ba:	e426                	sd	s1,8(sp)
    800028bc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028be:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800028c2:	00074d63          	bltz	a4,800028dc <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800028c6:	57fd                	li	a5,-1
    800028c8:	17fe                	slli	a5,a5,0x3f
    800028ca:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800028cc:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800028ce:	06f70363          	beq	a4,a5,80002934 <devintr+0x80>
  }
}
    800028d2:	60e2                	ld	ra,24(sp)
    800028d4:	6442                	ld	s0,16(sp)
    800028d6:	64a2                	ld	s1,8(sp)
    800028d8:	6105                	addi	sp,sp,32
    800028da:	8082                	ret
     (scause & 0xff) == 9){
    800028dc:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800028e0:	46a5                	li	a3,9
    800028e2:	fed792e3          	bne	a5,a3,800028c6 <devintr+0x12>
    int irq = plic_claim();
    800028e6:	00003097          	auipc	ra,0x3
    800028ea:	522080e7          	jalr	1314(ra) # 80005e08 <plic_claim>
    800028ee:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800028f0:	47a9                	li	a5,10
    800028f2:	02f50763          	beq	a0,a5,80002920 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800028f6:	4785                	li	a5,1
    800028f8:	02f50963          	beq	a0,a5,8000292a <devintr+0x76>
    return 1;
    800028fc:	4505                	li	a0,1
    } else if(irq){
    800028fe:	d8f1                	beqz	s1,800028d2 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002900:	85a6                	mv	a1,s1
    80002902:	00006517          	auipc	a0,0x6
    80002906:	a4e50513          	addi	a0,a0,-1458 # 80008350 <states.1737+0x38>
    8000290a:	ffffe097          	auipc	ra,0xffffe
    8000290e:	c84080e7          	jalr	-892(ra) # 8000058e <printf>
      plic_complete(irq);
    80002912:	8526                	mv	a0,s1
    80002914:	00003097          	auipc	ra,0x3
    80002918:	518080e7          	jalr	1304(ra) # 80005e2c <plic_complete>
    return 1;
    8000291c:	4505                	li	a0,1
    8000291e:	bf55                	j	800028d2 <devintr+0x1e>
      uartintr();
    80002920:	ffffe097          	auipc	ra,0xffffe
    80002924:	08e080e7          	jalr	142(ra) # 800009ae <uartintr>
    80002928:	b7ed                	j	80002912 <devintr+0x5e>
      virtio_disk_intr();
    8000292a:	00004097          	auipc	ra,0x4
    8000292e:	a2c080e7          	jalr	-1492(ra) # 80006356 <virtio_disk_intr>
    80002932:	b7c5                	j	80002912 <devintr+0x5e>
    if(cpuid() == 0){
    80002934:	fffff097          	auipc	ra,0xfffff
    80002938:	088080e7          	jalr	136(ra) # 800019bc <cpuid>
    8000293c:	c901                	beqz	a0,8000294c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000293e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002942:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002944:	14479073          	csrw	sip,a5
    return 2;
    80002948:	4509                	li	a0,2
    8000294a:	b761                	j	800028d2 <devintr+0x1e>
      clockintr();
    8000294c:	00000097          	auipc	ra,0x0
    80002950:	f22080e7          	jalr	-222(ra) # 8000286e <clockintr>
    80002954:	b7ed                	j	8000293e <devintr+0x8a>

0000000080002956 <usertrap>:
{
    80002956:	1101                	addi	sp,sp,-32
    80002958:	ec06                	sd	ra,24(sp)
    8000295a:	e822                	sd	s0,16(sp)
    8000295c:	e426                	sd	s1,8(sp)
    8000295e:	e04a                	sd	s2,0(sp)
    80002960:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002962:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002966:	1007f793          	andi	a5,a5,256
    8000296a:	e3b1                	bnez	a5,800029ae <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000296c:	00003797          	auipc	a5,0x3
    80002970:	39478793          	addi	a5,a5,916 # 80005d00 <kernelvec>
    80002974:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002978:	fffff097          	auipc	ra,0xfffff
    8000297c:	070080e7          	jalr	112(ra) # 800019e8 <myproc>
    80002980:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002982:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002984:	14102773          	csrr	a4,sepc
    80002988:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000298a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000298e:	47a1                	li	a5,8
    80002990:	02f70763          	beq	a4,a5,800029be <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002994:	00000097          	auipc	ra,0x0
    80002998:	f20080e7          	jalr	-224(ra) # 800028b4 <devintr>
    8000299c:	892a                	mv	s2,a0
    8000299e:	c151                	beqz	a0,80002a22 <usertrap+0xcc>
  if(killed(p))
    800029a0:	8526                	mv	a0,s1
    800029a2:	00000097          	auipc	ra,0x0
    800029a6:	9aa080e7          	jalr	-1622(ra) # 8000234c <killed>
    800029aa:	c929                	beqz	a0,800029fc <usertrap+0xa6>
    800029ac:	a099                	j	800029f2 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    800029ae:	00006517          	auipc	a0,0x6
    800029b2:	9c250513          	addi	a0,a0,-1598 # 80008370 <states.1737+0x58>
    800029b6:	ffffe097          	auipc	ra,0xffffe
    800029ba:	b8e080e7          	jalr	-1138(ra) # 80000544 <panic>
    if(killed(p))
    800029be:	00000097          	auipc	ra,0x0
    800029c2:	98e080e7          	jalr	-1650(ra) # 8000234c <killed>
    800029c6:	e921                	bnez	a0,80002a16 <usertrap+0xc0>
    p->trapframe->epc += 4;
    800029c8:	6cb8                	ld	a4,88(s1)
    800029ca:	6f1c                	ld	a5,24(a4)
    800029cc:	0791                	addi	a5,a5,4
    800029ce:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029d0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800029d4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029d8:	10079073          	csrw	sstatus,a5
    syscall();
    800029dc:	00000097          	auipc	ra,0x0
    800029e0:	2d4080e7          	jalr	724(ra) # 80002cb0 <syscall>
  if(killed(p))
    800029e4:	8526                	mv	a0,s1
    800029e6:	00000097          	auipc	ra,0x0
    800029ea:	966080e7          	jalr	-1690(ra) # 8000234c <killed>
    800029ee:	c911                	beqz	a0,80002a02 <usertrap+0xac>
    800029f0:	4901                	li	s2,0
    exit(-1);
    800029f2:	557d                	li	a0,-1
    800029f4:	fffff097          	auipc	ra,0xfffff
    800029f8:	7e4080e7          	jalr	2020(ra) # 800021d8 <exit>
  if(which_dev == 2)
    800029fc:	4789                	li	a5,2
    800029fe:	04f90f63          	beq	s2,a5,80002a5c <usertrap+0x106>
  usertrapret();
    80002a02:	00000097          	auipc	ra,0x0
    80002a06:	dd6080e7          	jalr	-554(ra) # 800027d8 <usertrapret>
}
    80002a0a:	60e2                	ld	ra,24(sp)
    80002a0c:	6442                	ld	s0,16(sp)
    80002a0e:	64a2                	ld	s1,8(sp)
    80002a10:	6902                	ld	s2,0(sp)
    80002a12:	6105                	addi	sp,sp,32
    80002a14:	8082                	ret
      exit(-1);
    80002a16:	557d                	li	a0,-1
    80002a18:	fffff097          	auipc	ra,0xfffff
    80002a1c:	7c0080e7          	jalr	1984(ra) # 800021d8 <exit>
    80002a20:	b765                	j	800029c8 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a22:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a26:	5890                	lw	a2,48(s1)
    80002a28:	00006517          	auipc	a0,0x6
    80002a2c:	96850513          	addi	a0,a0,-1688 # 80008390 <states.1737+0x78>
    80002a30:	ffffe097          	auipc	ra,0xffffe
    80002a34:	b5e080e7          	jalr	-1186(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a38:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a3c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a40:	00006517          	auipc	a0,0x6
    80002a44:	98050513          	addi	a0,a0,-1664 # 800083c0 <states.1737+0xa8>
    80002a48:	ffffe097          	auipc	ra,0xffffe
    80002a4c:	b46080e7          	jalr	-1210(ra) # 8000058e <printf>
    setkilled(p);
    80002a50:	8526                	mv	a0,s1
    80002a52:	00000097          	auipc	ra,0x0
    80002a56:	8ce080e7          	jalr	-1842(ra) # 80002320 <setkilled>
    80002a5a:	b769                	j	800029e4 <usertrap+0x8e>
    yield();
    80002a5c:	fffff097          	auipc	ra,0xfffff
    80002a60:	60c080e7          	jalr	1548(ra) # 80002068 <yield>
    80002a64:	bf79                	j	80002a02 <usertrap+0xac>

0000000080002a66 <kerneltrap>:
{
    80002a66:	7179                	addi	sp,sp,-48
    80002a68:	f406                	sd	ra,40(sp)
    80002a6a:	f022                	sd	s0,32(sp)
    80002a6c:	ec26                	sd	s1,24(sp)
    80002a6e:	e84a                	sd	s2,16(sp)
    80002a70:	e44e                	sd	s3,8(sp)
    80002a72:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a74:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a78:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a7c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a80:	1004f793          	andi	a5,s1,256
    80002a84:	cb85                	beqz	a5,80002ab4 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a86:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a8a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a8c:	ef85                	bnez	a5,80002ac4 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a8e:	00000097          	auipc	ra,0x0
    80002a92:	e26080e7          	jalr	-474(ra) # 800028b4 <devintr>
    80002a96:	cd1d                	beqz	a0,80002ad4 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a98:	4789                	li	a5,2
    80002a9a:	06f50a63          	beq	a0,a5,80002b0e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a9e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002aa2:	10049073          	csrw	sstatus,s1
}
    80002aa6:	70a2                	ld	ra,40(sp)
    80002aa8:	7402                	ld	s0,32(sp)
    80002aaa:	64e2                	ld	s1,24(sp)
    80002aac:	6942                	ld	s2,16(sp)
    80002aae:	69a2                	ld	s3,8(sp)
    80002ab0:	6145                	addi	sp,sp,48
    80002ab2:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002ab4:	00006517          	auipc	a0,0x6
    80002ab8:	92c50513          	addi	a0,a0,-1748 # 800083e0 <states.1737+0xc8>
    80002abc:	ffffe097          	auipc	ra,0xffffe
    80002ac0:	a88080e7          	jalr	-1400(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    80002ac4:	00006517          	auipc	a0,0x6
    80002ac8:	94450513          	addi	a0,a0,-1724 # 80008408 <states.1737+0xf0>
    80002acc:	ffffe097          	auipc	ra,0xffffe
    80002ad0:	a78080e7          	jalr	-1416(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    80002ad4:	85ce                	mv	a1,s3
    80002ad6:	00006517          	auipc	a0,0x6
    80002ada:	95250513          	addi	a0,a0,-1710 # 80008428 <states.1737+0x110>
    80002ade:	ffffe097          	auipc	ra,0xffffe
    80002ae2:	ab0080e7          	jalr	-1360(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ae6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002aea:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002aee:	00006517          	auipc	a0,0x6
    80002af2:	94a50513          	addi	a0,a0,-1718 # 80008438 <states.1737+0x120>
    80002af6:	ffffe097          	auipc	ra,0xffffe
    80002afa:	a98080e7          	jalr	-1384(ra) # 8000058e <printf>
    panic("kerneltrap");
    80002afe:	00006517          	auipc	a0,0x6
    80002b02:	95250513          	addi	a0,a0,-1710 # 80008450 <states.1737+0x138>
    80002b06:	ffffe097          	auipc	ra,0xffffe
    80002b0a:	a3e080e7          	jalr	-1474(ra) # 80000544 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b0e:	fffff097          	auipc	ra,0xfffff
    80002b12:	eda080e7          	jalr	-294(ra) # 800019e8 <myproc>
    80002b16:	d541                	beqz	a0,80002a9e <kerneltrap+0x38>
    80002b18:	fffff097          	auipc	ra,0xfffff
    80002b1c:	ed0080e7          	jalr	-304(ra) # 800019e8 <myproc>
    80002b20:	4d18                	lw	a4,24(a0)
    80002b22:	4791                	li	a5,4
    80002b24:	f6f71de3          	bne	a4,a5,80002a9e <kerneltrap+0x38>
    yield();
    80002b28:	fffff097          	auipc	ra,0xfffff
    80002b2c:	540080e7          	jalr	1344(ra) # 80002068 <yield>
    80002b30:	b7bd                	j	80002a9e <kerneltrap+0x38>

0000000080002b32 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b32:	1101                	addi	sp,sp,-32
    80002b34:	ec06                	sd	ra,24(sp)
    80002b36:	e822                	sd	s0,16(sp)
    80002b38:	e426                	sd	s1,8(sp)
    80002b3a:	1000                	addi	s0,sp,32
    80002b3c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b3e:	fffff097          	auipc	ra,0xfffff
    80002b42:	eaa080e7          	jalr	-342(ra) # 800019e8 <myproc>
  switch (n) {
    80002b46:	4795                	li	a5,5
    80002b48:	0497e163          	bltu	a5,s1,80002b8a <argraw+0x58>
    80002b4c:	048a                	slli	s1,s1,0x2
    80002b4e:	00006717          	auipc	a4,0x6
    80002b52:	93a70713          	addi	a4,a4,-1734 # 80008488 <states.1737+0x170>
    80002b56:	94ba                	add	s1,s1,a4
    80002b58:	409c                	lw	a5,0(s1)
    80002b5a:	97ba                	add	a5,a5,a4
    80002b5c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b5e:	6d3c                	ld	a5,88(a0)
    80002b60:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b62:	60e2                	ld	ra,24(sp)
    80002b64:	6442                	ld	s0,16(sp)
    80002b66:	64a2                	ld	s1,8(sp)
    80002b68:	6105                	addi	sp,sp,32
    80002b6a:	8082                	ret
    return p->trapframe->a1;
    80002b6c:	6d3c                	ld	a5,88(a0)
    80002b6e:	7fa8                	ld	a0,120(a5)
    80002b70:	bfcd                	j	80002b62 <argraw+0x30>
    return p->trapframe->a2;
    80002b72:	6d3c                	ld	a5,88(a0)
    80002b74:	63c8                	ld	a0,128(a5)
    80002b76:	b7f5                	j	80002b62 <argraw+0x30>
    return p->trapframe->a3;
    80002b78:	6d3c                	ld	a5,88(a0)
    80002b7a:	67c8                	ld	a0,136(a5)
    80002b7c:	b7dd                	j	80002b62 <argraw+0x30>
    return p->trapframe->a4;
    80002b7e:	6d3c                	ld	a5,88(a0)
    80002b80:	6bc8                	ld	a0,144(a5)
    80002b82:	b7c5                	j	80002b62 <argraw+0x30>
    return p->trapframe->a5;
    80002b84:	6d3c                	ld	a5,88(a0)
    80002b86:	6fc8                	ld	a0,152(a5)
    80002b88:	bfe9                	j	80002b62 <argraw+0x30>
  panic("argraw");
    80002b8a:	00006517          	auipc	a0,0x6
    80002b8e:	8d650513          	addi	a0,a0,-1834 # 80008460 <states.1737+0x148>
    80002b92:	ffffe097          	auipc	ra,0xffffe
    80002b96:	9b2080e7          	jalr	-1614(ra) # 80000544 <panic>

0000000080002b9a <fetchaddr>:
{
    80002b9a:	1101                	addi	sp,sp,-32
    80002b9c:	ec06                	sd	ra,24(sp)
    80002b9e:	e822                	sd	s0,16(sp)
    80002ba0:	e426                	sd	s1,8(sp)
    80002ba2:	e04a                	sd	s2,0(sp)
    80002ba4:	1000                	addi	s0,sp,32
    80002ba6:	84aa                	mv	s1,a0
    80002ba8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002baa:	fffff097          	auipc	ra,0xfffff
    80002bae:	e3e080e7          	jalr	-450(ra) # 800019e8 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002bb2:	653c                	ld	a5,72(a0)
    80002bb4:	02f4f863          	bgeu	s1,a5,80002be4 <fetchaddr+0x4a>
    80002bb8:	00848713          	addi	a4,s1,8
    80002bbc:	02e7e663          	bltu	a5,a4,80002be8 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002bc0:	46a1                	li	a3,8
    80002bc2:	8626                	mv	a2,s1
    80002bc4:	85ca                	mv	a1,s2
    80002bc6:	6928                	ld	a0,80(a0)
    80002bc8:	fffff097          	auipc	ra,0xfffff
    80002bcc:	b6a080e7          	jalr	-1174(ra) # 80001732 <copyin>
    80002bd0:	00a03533          	snez	a0,a0
    80002bd4:	40a00533          	neg	a0,a0
}
    80002bd8:	60e2                	ld	ra,24(sp)
    80002bda:	6442                	ld	s0,16(sp)
    80002bdc:	64a2                	ld	s1,8(sp)
    80002bde:	6902                	ld	s2,0(sp)
    80002be0:	6105                	addi	sp,sp,32
    80002be2:	8082                	ret
    return -1;
    80002be4:	557d                	li	a0,-1
    80002be6:	bfcd                	j	80002bd8 <fetchaddr+0x3e>
    80002be8:	557d                	li	a0,-1
    80002bea:	b7fd                	j	80002bd8 <fetchaddr+0x3e>

0000000080002bec <fetchstr>:
{
    80002bec:	7179                	addi	sp,sp,-48
    80002bee:	f406                	sd	ra,40(sp)
    80002bf0:	f022                	sd	s0,32(sp)
    80002bf2:	ec26                	sd	s1,24(sp)
    80002bf4:	e84a                	sd	s2,16(sp)
    80002bf6:	e44e                	sd	s3,8(sp)
    80002bf8:	1800                	addi	s0,sp,48
    80002bfa:	892a                	mv	s2,a0
    80002bfc:	84ae                	mv	s1,a1
    80002bfe:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c00:	fffff097          	auipc	ra,0xfffff
    80002c04:	de8080e7          	jalr	-536(ra) # 800019e8 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002c08:	86ce                	mv	a3,s3
    80002c0a:	864a                	mv	a2,s2
    80002c0c:	85a6                	mv	a1,s1
    80002c0e:	6928                	ld	a0,80(a0)
    80002c10:	fffff097          	auipc	ra,0xfffff
    80002c14:	bae080e7          	jalr	-1106(ra) # 800017be <copyinstr>
    80002c18:	00054e63          	bltz	a0,80002c34 <fetchstr+0x48>
  return strlen(buf);
    80002c1c:	8526                	mv	a0,s1
    80002c1e:	ffffe097          	auipc	ra,0xffffe
    80002c22:	26e080e7          	jalr	622(ra) # 80000e8c <strlen>
}
    80002c26:	70a2                	ld	ra,40(sp)
    80002c28:	7402                	ld	s0,32(sp)
    80002c2a:	64e2                	ld	s1,24(sp)
    80002c2c:	6942                	ld	s2,16(sp)
    80002c2e:	69a2                	ld	s3,8(sp)
    80002c30:	6145                	addi	sp,sp,48
    80002c32:	8082                	ret
    return -1;
    80002c34:	557d                	li	a0,-1
    80002c36:	bfc5                	j	80002c26 <fetchstr+0x3a>

0000000080002c38 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002c38:	1101                	addi	sp,sp,-32
    80002c3a:	ec06                	sd	ra,24(sp)
    80002c3c:	e822                	sd	s0,16(sp)
    80002c3e:	e426                	sd	s1,8(sp)
    80002c40:	1000                	addi	s0,sp,32
    80002c42:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c44:	00000097          	auipc	ra,0x0
    80002c48:	eee080e7          	jalr	-274(ra) # 80002b32 <argraw>
    80002c4c:	c088                	sw	a0,0(s1)
}
    80002c4e:	60e2                	ld	ra,24(sp)
    80002c50:	6442                	ld	s0,16(sp)
    80002c52:	64a2                	ld	s1,8(sp)
    80002c54:	6105                	addi	sp,sp,32
    80002c56:	8082                	ret

0000000080002c58 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002c58:	1101                	addi	sp,sp,-32
    80002c5a:	ec06                	sd	ra,24(sp)
    80002c5c:	e822                	sd	s0,16(sp)
    80002c5e:	e426                	sd	s1,8(sp)
    80002c60:	1000                	addi	s0,sp,32
    80002c62:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c64:	00000097          	auipc	ra,0x0
    80002c68:	ece080e7          	jalr	-306(ra) # 80002b32 <argraw>
    80002c6c:	e088                	sd	a0,0(s1)
}
    80002c6e:	60e2                	ld	ra,24(sp)
    80002c70:	6442                	ld	s0,16(sp)
    80002c72:	64a2                	ld	s1,8(sp)
    80002c74:	6105                	addi	sp,sp,32
    80002c76:	8082                	ret

0000000080002c78 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c78:	7179                	addi	sp,sp,-48
    80002c7a:	f406                	sd	ra,40(sp)
    80002c7c:	f022                	sd	s0,32(sp)
    80002c7e:	ec26                	sd	s1,24(sp)
    80002c80:	e84a                	sd	s2,16(sp)
    80002c82:	1800                	addi	s0,sp,48
    80002c84:	84ae                	mv	s1,a1
    80002c86:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002c88:	fd840593          	addi	a1,s0,-40
    80002c8c:	00000097          	auipc	ra,0x0
    80002c90:	fcc080e7          	jalr	-52(ra) # 80002c58 <argaddr>
  return fetchstr(addr, buf, max);
    80002c94:	864a                	mv	a2,s2
    80002c96:	85a6                	mv	a1,s1
    80002c98:	fd843503          	ld	a0,-40(s0)
    80002c9c:	00000097          	auipc	ra,0x0
    80002ca0:	f50080e7          	jalr	-176(ra) # 80002bec <fetchstr>
}
    80002ca4:	70a2                	ld	ra,40(sp)
    80002ca6:	7402                	ld	s0,32(sp)
    80002ca8:	64e2                	ld	s1,24(sp)
    80002caa:	6942                	ld	s2,16(sp)
    80002cac:	6145                	addi	sp,sp,48
    80002cae:	8082                	ret

0000000080002cb0 <syscall>:
[SYS_procinfo] sys_procinfo,
};

void
syscall(void)
{
    80002cb0:	1101                	addi	sp,sp,-32
    80002cb2:	ec06                	sd	ra,24(sp)
    80002cb4:	e822                	sd	s0,16(sp)
    80002cb6:	e426                	sd	s1,8(sp)
    80002cb8:	e04a                	sd	s2,0(sp)
    80002cba:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002cbc:	fffff097          	auipc	ra,0xfffff
    80002cc0:	d2c080e7          	jalr	-724(ra) # 800019e8 <myproc>
    80002cc4:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002cc6:	05853903          	ld	s2,88(a0)
    80002cca:	0a893783          	ld	a5,168(s2)
    80002cce:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002cd2:	37fd                	addiw	a5,a5,-1
    80002cd4:	475d                	li	a4,23
    80002cd6:	04f76163          	bltu	a4,a5,80002d18 <syscall+0x68>
    80002cda:	00369713          	slli	a4,a3,0x3
    80002cde:	00005797          	auipc	a5,0x5
    80002ce2:	7c278793          	addi	a5,a5,1986 # 800084a0 <syscalls>
    80002ce6:	97ba                	add	a5,a5,a4
    80002ce8:	639c                	ld	a5,0(a5)
    80002cea:	c79d                	beqz	a5,80002d18 <syscall+0x68>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002cec:	9782                	jalr	a5
    80002cee:	06a93823          	sd	a0,112(s2)
    systemcall_count[p->pid]++;
    80002cf2:	589c                	lw	a5,48(s1)
    80002cf4:	00279713          	slli	a4,a5,0x2
    80002cf8:	0000e797          	auipc	a5,0xe
    80002cfc:	2f878793          	addi	a5,a5,760 # 80010ff0 <systemcall_count>
    80002d00:	97ba                	add	a5,a5,a4
    80002d02:	4398                	lw	a4,0(a5)
    80002d04:	2705                	addiw	a4,a4,1
    80002d06:	c398                	sw	a4,0(a5)
    systemcallcount++;
    80002d08:	00006717          	auipc	a4,0x6
    80002d0c:	c4c70713          	addi	a4,a4,-948 # 80008954 <systemcallcount>
    80002d10:	431c                	lw	a5,0(a4)
    80002d12:	2785                	addiw	a5,a5,1
    80002d14:	c31c                	sw	a5,0(a4)
    80002d16:	a839                	j	80002d34 <syscall+0x84>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d18:	15848613          	addi	a2,s1,344
    80002d1c:	588c                	lw	a1,48(s1)
    80002d1e:	00005517          	auipc	a0,0x5
    80002d22:	74a50513          	addi	a0,a0,1866 # 80008468 <states.1737+0x150>
    80002d26:	ffffe097          	auipc	ra,0xffffe
    80002d2a:	868080e7          	jalr	-1944(ra) # 8000058e <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d2e:	6cbc                	ld	a5,88(s1)
    80002d30:	577d                	li	a4,-1
    80002d32:	fbb8                	sd	a4,112(a5)
  }
}
    80002d34:	60e2                	ld	ra,24(sp)
    80002d36:	6442                	ld	s0,16(sp)
    80002d38:	64a2                	ld	s1,8(sp)
    80002d3a:	6902                	ld	s2,0(sp)
    80002d3c:	6105                	addi	sp,sp,32
    80002d3e:	8082                	ret

0000000080002d40 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d40:	1101                	addi	sp,sp,-32
    80002d42:	ec06                	sd	ra,24(sp)
    80002d44:	e822                	sd	s0,16(sp)
    80002d46:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002d48:	fec40593          	addi	a1,s0,-20
    80002d4c:	4501                	li	a0,0
    80002d4e:	00000097          	auipc	ra,0x0
    80002d52:	eea080e7          	jalr	-278(ra) # 80002c38 <argint>
  exit(n);
    80002d56:	fec42503          	lw	a0,-20(s0)
    80002d5a:	fffff097          	auipc	ra,0xfffff
    80002d5e:	47e080e7          	jalr	1150(ra) # 800021d8 <exit>
  return 0;  // not reached
}
    80002d62:	4501                	li	a0,0
    80002d64:	60e2                	ld	ra,24(sp)
    80002d66:	6442                	ld	s0,16(sp)
    80002d68:	6105                	addi	sp,sp,32
    80002d6a:	8082                	ret

0000000080002d6c <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d6c:	1141                	addi	sp,sp,-16
    80002d6e:	e406                	sd	ra,8(sp)
    80002d70:	e022                	sd	s0,0(sp)
    80002d72:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d74:	fffff097          	auipc	ra,0xfffff
    80002d78:	c74080e7          	jalr	-908(ra) # 800019e8 <myproc>
}
    80002d7c:	5908                	lw	a0,48(a0)
    80002d7e:	60a2                	ld	ra,8(sp)
    80002d80:	6402                	ld	s0,0(sp)
    80002d82:	0141                	addi	sp,sp,16
    80002d84:	8082                	ret

0000000080002d86 <sys_fork>:

uint64
sys_fork(void)
{
    80002d86:	1141                	addi	sp,sp,-16
    80002d88:	e406                	sd	ra,8(sp)
    80002d8a:	e022                	sd	s0,0(sp)
    80002d8c:	0800                	addi	s0,sp,16
  return fork();
    80002d8e:	fffff097          	auipc	ra,0xfffff
    80002d92:	028080e7          	jalr	40(ra) # 80001db6 <fork>
}
    80002d96:	60a2                	ld	ra,8(sp)
    80002d98:	6402                	ld	s0,0(sp)
    80002d9a:	0141                	addi	sp,sp,16
    80002d9c:	8082                	ret

0000000080002d9e <sys_wait>:

uint64
sys_wait(void)
{
    80002d9e:	1101                	addi	sp,sp,-32
    80002da0:	ec06                	sd	ra,24(sp)
    80002da2:	e822                	sd	s0,16(sp)
    80002da4:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002da6:	fe840593          	addi	a1,s0,-24
    80002daa:	4501                	li	a0,0
    80002dac:	00000097          	auipc	ra,0x0
    80002db0:	eac080e7          	jalr	-340(ra) # 80002c58 <argaddr>
  return wait(p);
    80002db4:	fe843503          	ld	a0,-24(s0)
    80002db8:	fffff097          	auipc	ra,0xfffff
    80002dbc:	5c6080e7          	jalr	1478(ra) # 8000237e <wait>
}
    80002dc0:	60e2                	ld	ra,24(sp)
    80002dc2:	6442                	ld	s0,16(sp)
    80002dc4:	6105                	addi	sp,sp,32
    80002dc6:	8082                	ret

0000000080002dc8 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002dc8:	7179                	addi	sp,sp,-48
    80002dca:	f406                	sd	ra,40(sp)
    80002dcc:	f022                	sd	s0,32(sp)
    80002dce:	ec26                	sd	s1,24(sp)
    80002dd0:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002dd2:	fdc40593          	addi	a1,s0,-36
    80002dd6:	4501                	li	a0,0
    80002dd8:	00000097          	auipc	ra,0x0
    80002ddc:	e60080e7          	jalr	-416(ra) # 80002c38 <argint>
  addr = myproc()->sz;
    80002de0:	fffff097          	auipc	ra,0xfffff
    80002de4:	c08080e7          	jalr	-1016(ra) # 800019e8 <myproc>
    80002de8:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002dea:	fdc42503          	lw	a0,-36(s0)
    80002dee:	fffff097          	auipc	ra,0xfffff
    80002df2:	f6c080e7          	jalr	-148(ra) # 80001d5a <growproc>
    80002df6:	00054863          	bltz	a0,80002e06 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002dfa:	8526                	mv	a0,s1
    80002dfc:	70a2                	ld	ra,40(sp)
    80002dfe:	7402                	ld	s0,32(sp)
    80002e00:	64e2                	ld	s1,24(sp)
    80002e02:	6145                	addi	sp,sp,48
    80002e04:	8082                	ret
    return -1;
    80002e06:	54fd                	li	s1,-1
    80002e08:	bfcd                	j	80002dfa <sys_sbrk+0x32>

0000000080002e0a <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e0a:	7139                	addi	sp,sp,-64
    80002e0c:	fc06                	sd	ra,56(sp)
    80002e0e:	f822                	sd	s0,48(sp)
    80002e10:	f426                	sd	s1,40(sp)
    80002e12:	f04a                	sd	s2,32(sp)
    80002e14:	ec4e                	sd	s3,24(sp)
    80002e16:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002e18:	fcc40593          	addi	a1,s0,-52
    80002e1c:	4501                	li	a0,0
    80002e1e:	00000097          	auipc	ra,0x0
    80002e22:	e1a080e7          	jalr	-486(ra) # 80002c38 <argint>
  acquire(&tickslock);
    80002e26:	00014517          	auipc	a0,0x14
    80002e2a:	cca50513          	addi	a0,a0,-822 # 80016af0 <tickslock>
    80002e2e:	ffffe097          	auipc	ra,0xffffe
    80002e32:	dde080e7          	jalr	-546(ra) # 80000c0c <acquire>
  ticks0 = ticks;
    80002e36:	00006917          	auipc	s2,0x6
    80002e3a:	b1a92903          	lw	s2,-1254(s2) # 80008950 <ticks>
  while(ticks - ticks0 < n){
    80002e3e:	fcc42783          	lw	a5,-52(s0)
    80002e42:	cf9d                	beqz	a5,80002e80 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e44:	00014997          	auipc	s3,0x14
    80002e48:	cac98993          	addi	s3,s3,-852 # 80016af0 <tickslock>
    80002e4c:	00006497          	auipc	s1,0x6
    80002e50:	b0448493          	addi	s1,s1,-1276 # 80008950 <ticks>
    if(killed(myproc())){
    80002e54:	fffff097          	auipc	ra,0xfffff
    80002e58:	b94080e7          	jalr	-1132(ra) # 800019e8 <myproc>
    80002e5c:	fffff097          	auipc	ra,0xfffff
    80002e60:	4f0080e7          	jalr	1264(ra) # 8000234c <killed>
    80002e64:	ed15                	bnez	a0,80002ea0 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002e66:	85ce                	mv	a1,s3
    80002e68:	8526                	mv	a0,s1
    80002e6a:	fffff097          	auipc	ra,0xfffff
    80002e6e:	23a080e7          	jalr	570(ra) # 800020a4 <sleep>
  while(ticks - ticks0 < n){
    80002e72:	409c                	lw	a5,0(s1)
    80002e74:	412787bb          	subw	a5,a5,s2
    80002e78:	fcc42703          	lw	a4,-52(s0)
    80002e7c:	fce7ece3          	bltu	a5,a4,80002e54 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002e80:	00014517          	auipc	a0,0x14
    80002e84:	c7050513          	addi	a0,a0,-912 # 80016af0 <tickslock>
    80002e88:	ffffe097          	auipc	ra,0xffffe
    80002e8c:	e38080e7          	jalr	-456(ra) # 80000cc0 <release>
  return 0;
    80002e90:	4501                	li	a0,0
}
    80002e92:	70e2                	ld	ra,56(sp)
    80002e94:	7442                	ld	s0,48(sp)
    80002e96:	74a2                	ld	s1,40(sp)
    80002e98:	7902                	ld	s2,32(sp)
    80002e9a:	69e2                	ld	s3,24(sp)
    80002e9c:	6121                	addi	sp,sp,64
    80002e9e:	8082                	ret
      release(&tickslock);
    80002ea0:	00014517          	auipc	a0,0x14
    80002ea4:	c5050513          	addi	a0,a0,-944 # 80016af0 <tickslock>
    80002ea8:	ffffe097          	auipc	ra,0xffffe
    80002eac:	e18080e7          	jalr	-488(ra) # 80000cc0 <release>
      return -1;
    80002eb0:	557d                	li	a0,-1
    80002eb2:	b7c5                	j	80002e92 <sys_sleep+0x88>

0000000080002eb4 <sys_kill>:

uint64
sys_kill(void)
{
    80002eb4:	1101                	addi	sp,sp,-32
    80002eb6:	ec06                	sd	ra,24(sp)
    80002eb8:	e822                	sd	s0,16(sp)
    80002eba:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002ebc:	fec40593          	addi	a1,s0,-20
    80002ec0:	4501                	li	a0,0
    80002ec2:	00000097          	auipc	ra,0x0
    80002ec6:	d76080e7          	jalr	-650(ra) # 80002c38 <argint>
  return kill(pid);
    80002eca:	fec42503          	lw	a0,-20(s0)
    80002ece:	fffff097          	auipc	ra,0xfffff
    80002ed2:	3e0080e7          	jalr	992(ra) # 800022ae <kill>
}
    80002ed6:	60e2                	ld	ra,24(sp)
    80002ed8:	6442                	ld	s0,16(sp)
    80002eda:	6105                	addi	sp,sp,32
    80002edc:	8082                	ret

0000000080002ede <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002ede:	1101                	addi	sp,sp,-32
    80002ee0:	ec06                	sd	ra,24(sp)
    80002ee2:	e822                	sd	s0,16(sp)
    80002ee4:	e426                	sd	s1,8(sp)
    80002ee6:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002ee8:	00014517          	auipc	a0,0x14
    80002eec:	c0850513          	addi	a0,a0,-1016 # 80016af0 <tickslock>
    80002ef0:	ffffe097          	auipc	ra,0xffffe
    80002ef4:	d1c080e7          	jalr	-740(ra) # 80000c0c <acquire>
  xticks = ticks;
    80002ef8:	00006497          	auipc	s1,0x6
    80002efc:	a584a483          	lw	s1,-1448(s1) # 80008950 <ticks>
  release(&tickslock);
    80002f00:	00014517          	auipc	a0,0x14
    80002f04:	bf050513          	addi	a0,a0,-1040 # 80016af0 <tickslock>
    80002f08:	ffffe097          	auipc	ra,0xffffe
    80002f0c:	db8080e7          	jalr	-584(ra) # 80000cc0 <release>
  return xticks;
}
    80002f10:	02049513          	slli	a0,s1,0x20
    80002f14:	9101                	srli	a0,a0,0x20
    80002f16:	60e2                	ld	ra,24(sp)
    80002f18:	6442                	ld	s0,16(sp)
    80002f1a:	64a2                	ld	s1,8(sp)
    80002f1c:	6105                	addi	sp,sp,32
    80002f1e:	8082                	ret

0000000080002f20 <sys_hello>:


uint64
sys_hello(void)
{
    80002f20:	1141                	addi	sp,sp,-16
    80002f22:	e406                	sd	ra,8(sp)
    80002f24:	e022                	sd	s0,0(sp)
    80002f26:	0800                	addi	s0,sp,16
  hello();
    80002f28:	fffff097          	auipc	ra,0xfffff
    80002f2c:	6de080e7          	jalr	1758(ra) # 80002606 <hello>
  return 0;	
}
    80002f30:	4501                	li	a0,0
    80002f32:	60a2                	ld	ra,8(sp)
    80002f34:	6402                	ld	s0,0(sp)
    80002f36:	0141                	addi	sp,sp,16
    80002f38:	8082                	ret

0000000080002f3a <sys_info>:

uint64
sys_info(void)
{
    80002f3a:	1101                	addi	sp,sp,-32
    80002f3c:	ec06                	sd	ra,24(sp)
    80002f3e:	e822                	sd	s0,16(sp)
    80002f40:	1000                	addi	s0,sp,32
  int param;
  argint(0, &param);
    80002f42:	fec40593          	addi	a1,s0,-20
    80002f46:	4501                	li	a0,0
    80002f48:	00000097          	auipc	ra,0x0
    80002f4c:	cf0080e7          	jalr	-784(ra) # 80002c38 <argint>
  
  return sysinfo(param);
    80002f50:	fec42503          	lw	a0,-20(s0)
    80002f54:	fffff097          	auipc	ra,0xfffff
    80002f58:	6d2080e7          	jalr	1746(ra) # 80002626 <sysinfo>
}
    80002f5c:	60e2                	ld	ra,24(sp)
    80002f5e:	6442                	ld	s0,16(sp)
    80002f60:	6105                	addi	sp,sp,32
    80002f62:	8082                	ret

0000000080002f64 <sys_procinfo>:

uint64
sys_procinfo(void)
{
    80002f64:	1101                	addi	sp,sp,-32
    80002f66:	ec06                	sd	ra,24(sp)
    80002f68:	e822                	sd	s0,16(sp)
    80002f6a:	1000                	addi	s0,sp,32
  uint64 addr;

  argaddr(0, &addr);
    80002f6c:	fe840593          	addi	a1,s0,-24
    80002f70:	4501                	li	a0,0
    80002f72:	00000097          	auipc	ra,0x0
    80002f76:	ce6080e7          	jalr	-794(ra) # 80002c58 <argaddr>
  struct pinfo* pi = (struct pinfo*)addr;
  
  return procinfo(pi);
    80002f7a:	fe843503          	ld	a0,-24(s0)
    80002f7e:	fffff097          	auipc	ra,0xfffff
    80002f82:	722080e7          	jalr	1826(ra) # 800026a0 <procinfo>
    80002f86:	60e2                	ld	ra,24(sp)
    80002f88:	6442                	ld	s0,16(sp)
    80002f8a:	6105                	addi	sp,sp,32
    80002f8c:	8082                	ret

0000000080002f8e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f8e:	7179                	addi	sp,sp,-48
    80002f90:	f406                	sd	ra,40(sp)
    80002f92:	f022                	sd	s0,32(sp)
    80002f94:	ec26                	sd	s1,24(sp)
    80002f96:	e84a                	sd	s2,16(sp)
    80002f98:	e44e                	sd	s3,8(sp)
    80002f9a:	e052                	sd	s4,0(sp)
    80002f9c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f9e:	00005597          	auipc	a1,0x5
    80002fa2:	5ca58593          	addi	a1,a1,1482 # 80008568 <syscalls+0xc8>
    80002fa6:	00014517          	auipc	a0,0x14
    80002faa:	b6250513          	addi	a0,a0,-1182 # 80016b08 <bcache>
    80002fae:	ffffe097          	auipc	ra,0xffffe
    80002fb2:	bce080e7          	jalr	-1074(ra) # 80000b7c <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002fb6:	0001c797          	auipc	a5,0x1c
    80002fba:	b5278793          	addi	a5,a5,-1198 # 8001eb08 <bcache+0x8000>
    80002fbe:	0001c717          	auipc	a4,0x1c
    80002fc2:	db270713          	addi	a4,a4,-590 # 8001ed70 <bcache+0x8268>
    80002fc6:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002fca:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fce:	00014497          	auipc	s1,0x14
    80002fd2:	b5248493          	addi	s1,s1,-1198 # 80016b20 <bcache+0x18>
    b->next = bcache.head.next;
    80002fd6:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002fd8:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002fda:	00005a17          	auipc	s4,0x5
    80002fde:	596a0a13          	addi	s4,s4,1430 # 80008570 <syscalls+0xd0>
    b->next = bcache.head.next;
    80002fe2:	2b893783          	ld	a5,696(s2)
    80002fe6:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002fe8:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002fec:	85d2                	mv	a1,s4
    80002fee:	01048513          	addi	a0,s1,16
    80002ff2:	00001097          	auipc	ra,0x1
    80002ff6:	4c4080e7          	jalr	1220(ra) # 800044b6 <initsleeplock>
    bcache.head.next->prev = b;
    80002ffa:	2b893783          	ld	a5,696(s2)
    80002ffe:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003000:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003004:	45848493          	addi	s1,s1,1112
    80003008:	fd349de3          	bne	s1,s3,80002fe2 <binit+0x54>
  }
}
    8000300c:	70a2                	ld	ra,40(sp)
    8000300e:	7402                	ld	s0,32(sp)
    80003010:	64e2                	ld	s1,24(sp)
    80003012:	6942                	ld	s2,16(sp)
    80003014:	69a2                	ld	s3,8(sp)
    80003016:	6a02                	ld	s4,0(sp)
    80003018:	6145                	addi	sp,sp,48
    8000301a:	8082                	ret

000000008000301c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000301c:	7179                	addi	sp,sp,-48
    8000301e:	f406                	sd	ra,40(sp)
    80003020:	f022                	sd	s0,32(sp)
    80003022:	ec26                	sd	s1,24(sp)
    80003024:	e84a                	sd	s2,16(sp)
    80003026:	e44e                	sd	s3,8(sp)
    80003028:	1800                	addi	s0,sp,48
    8000302a:	89aa                	mv	s3,a0
    8000302c:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000302e:	00014517          	auipc	a0,0x14
    80003032:	ada50513          	addi	a0,a0,-1318 # 80016b08 <bcache>
    80003036:	ffffe097          	auipc	ra,0xffffe
    8000303a:	bd6080e7          	jalr	-1066(ra) # 80000c0c <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000303e:	0001c497          	auipc	s1,0x1c
    80003042:	d824b483          	ld	s1,-638(s1) # 8001edc0 <bcache+0x82b8>
    80003046:	0001c797          	auipc	a5,0x1c
    8000304a:	d2a78793          	addi	a5,a5,-726 # 8001ed70 <bcache+0x8268>
    8000304e:	02f48f63          	beq	s1,a5,8000308c <bread+0x70>
    80003052:	873e                	mv	a4,a5
    80003054:	a021                	j	8000305c <bread+0x40>
    80003056:	68a4                	ld	s1,80(s1)
    80003058:	02e48a63          	beq	s1,a4,8000308c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000305c:	449c                	lw	a5,8(s1)
    8000305e:	ff379ce3          	bne	a5,s3,80003056 <bread+0x3a>
    80003062:	44dc                	lw	a5,12(s1)
    80003064:	ff2799e3          	bne	a5,s2,80003056 <bread+0x3a>
      b->refcnt++;
    80003068:	40bc                	lw	a5,64(s1)
    8000306a:	2785                	addiw	a5,a5,1
    8000306c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000306e:	00014517          	auipc	a0,0x14
    80003072:	a9a50513          	addi	a0,a0,-1382 # 80016b08 <bcache>
    80003076:	ffffe097          	auipc	ra,0xffffe
    8000307a:	c4a080e7          	jalr	-950(ra) # 80000cc0 <release>
      acquiresleep(&b->lock);
    8000307e:	01048513          	addi	a0,s1,16
    80003082:	00001097          	auipc	ra,0x1
    80003086:	46e080e7          	jalr	1134(ra) # 800044f0 <acquiresleep>
      return b;
    8000308a:	a8b9                	j	800030e8 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000308c:	0001c497          	auipc	s1,0x1c
    80003090:	d2c4b483          	ld	s1,-724(s1) # 8001edb8 <bcache+0x82b0>
    80003094:	0001c797          	auipc	a5,0x1c
    80003098:	cdc78793          	addi	a5,a5,-804 # 8001ed70 <bcache+0x8268>
    8000309c:	00f48863          	beq	s1,a5,800030ac <bread+0x90>
    800030a0:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800030a2:	40bc                	lw	a5,64(s1)
    800030a4:	cf81                	beqz	a5,800030bc <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030a6:	64a4                	ld	s1,72(s1)
    800030a8:	fee49de3          	bne	s1,a4,800030a2 <bread+0x86>
  panic("bget: no buffers");
    800030ac:	00005517          	auipc	a0,0x5
    800030b0:	4cc50513          	addi	a0,a0,1228 # 80008578 <syscalls+0xd8>
    800030b4:	ffffd097          	auipc	ra,0xffffd
    800030b8:	490080e7          	jalr	1168(ra) # 80000544 <panic>
      b->dev = dev;
    800030bc:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800030c0:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800030c4:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800030c8:	4785                	li	a5,1
    800030ca:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030cc:	00014517          	auipc	a0,0x14
    800030d0:	a3c50513          	addi	a0,a0,-1476 # 80016b08 <bcache>
    800030d4:	ffffe097          	auipc	ra,0xffffe
    800030d8:	bec080e7          	jalr	-1044(ra) # 80000cc0 <release>
      acquiresleep(&b->lock);
    800030dc:	01048513          	addi	a0,s1,16
    800030e0:	00001097          	auipc	ra,0x1
    800030e4:	410080e7          	jalr	1040(ra) # 800044f0 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800030e8:	409c                	lw	a5,0(s1)
    800030ea:	cb89                	beqz	a5,800030fc <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800030ec:	8526                	mv	a0,s1
    800030ee:	70a2                	ld	ra,40(sp)
    800030f0:	7402                	ld	s0,32(sp)
    800030f2:	64e2                	ld	s1,24(sp)
    800030f4:	6942                	ld	s2,16(sp)
    800030f6:	69a2                	ld	s3,8(sp)
    800030f8:	6145                	addi	sp,sp,48
    800030fa:	8082                	ret
    virtio_disk_rw(b, 0);
    800030fc:	4581                	li	a1,0
    800030fe:	8526                	mv	a0,s1
    80003100:	00003097          	auipc	ra,0x3
    80003104:	fc8080e7          	jalr	-56(ra) # 800060c8 <virtio_disk_rw>
    b->valid = 1;
    80003108:	4785                	li	a5,1
    8000310a:	c09c                	sw	a5,0(s1)
  return b;
    8000310c:	b7c5                	j	800030ec <bread+0xd0>

000000008000310e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000310e:	1101                	addi	sp,sp,-32
    80003110:	ec06                	sd	ra,24(sp)
    80003112:	e822                	sd	s0,16(sp)
    80003114:	e426                	sd	s1,8(sp)
    80003116:	1000                	addi	s0,sp,32
    80003118:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000311a:	0541                	addi	a0,a0,16
    8000311c:	00001097          	auipc	ra,0x1
    80003120:	46e080e7          	jalr	1134(ra) # 8000458a <holdingsleep>
    80003124:	cd01                	beqz	a0,8000313c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003126:	4585                	li	a1,1
    80003128:	8526                	mv	a0,s1
    8000312a:	00003097          	auipc	ra,0x3
    8000312e:	f9e080e7          	jalr	-98(ra) # 800060c8 <virtio_disk_rw>
}
    80003132:	60e2                	ld	ra,24(sp)
    80003134:	6442                	ld	s0,16(sp)
    80003136:	64a2                	ld	s1,8(sp)
    80003138:	6105                	addi	sp,sp,32
    8000313a:	8082                	ret
    panic("bwrite");
    8000313c:	00005517          	auipc	a0,0x5
    80003140:	45450513          	addi	a0,a0,1108 # 80008590 <syscalls+0xf0>
    80003144:	ffffd097          	auipc	ra,0xffffd
    80003148:	400080e7          	jalr	1024(ra) # 80000544 <panic>

000000008000314c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000314c:	1101                	addi	sp,sp,-32
    8000314e:	ec06                	sd	ra,24(sp)
    80003150:	e822                	sd	s0,16(sp)
    80003152:	e426                	sd	s1,8(sp)
    80003154:	e04a                	sd	s2,0(sp)
    80003156:	1000                	addi	s0,sp,32
    80003158:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000315a:	01050913          	addi	s2,a0,16
    8000315e:	854a                	mv	a0,s2
    80003160:	00001097          	auipc	ra,0x1
    80003164:	42a080e7          	jalr	1066(ra) # 8000458a <holdingsleep>
    80003168:	c92d                	beqz	a0,800031da <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000316a:	854a                	mv	a0,s2
    8000316c:	00001097          	auipc	ra,0x1
    80003170:	3da080e7          	jalr	986(ra) # 80004546 <releasesleep>

  acquire(&bcache.lock);
    80003174:	00014517          	auipc	a0,0x14
    80003178:	99450513          	addi	a0,a0,-1644 # 80016b08 <bcache>
    8000317c:	ffffe097          	auipc	ra,0xffffe
    80003180:	a90080e7          	jalr	-1392(ra) # 80000c0c <acquire>
  b->refcnt--;
    80003184:	40bc                	lw	a5,64(s1)
    80003186:	37fd                	addiw	a5,a5,-1
    80003188:	0007871b          	sext.w	a4,a5
    8000318c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000318e:	eb05                	bnez	a4,800031be <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003190:	68bc                	ld	a5,80(s1)
    80003192:	64b8                	ld	a4,72(s1)
    80003194:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003196:	64bc                	ld	a5,72(s1)
    80003198:	68b8                	ld	a4,80(s1)
    8000319a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000319c:	0001c797          	auipc	a5,0x1c
    800031a0:	96c78793          	addi	a5,a5,-1684 # 8001eb08 <bcache+0x8000>
    800031a4:	2b87b703          	ld	a4,696(a5)
    800031a8:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800031aa:	0001c717          	auipc	a4,0x1c
    800031ae:	bc670713          	addi	a4,a4,-1082 # 8001ed70 <bcache+0x8268>
    800031b2:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800031b4:	2b87b703          	ld	a4,696(a5)
    800031b8:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800031ba:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800031be:	00014517          	auipc	a0,0x14
    800031c2:	94a50513          	addi	a0,a0,-1718 # 80016b08 <bcache>
    800031c6:	ffffe097          	auipc	ra,0xffffe
    800031ca:	afa080e7          	jalr	-1286(ra) # 80000cc0 <release>
}
    800031ce:	60e2                	ld	ra,24(sp)
    800031d0:	6442                	ld	s0,16(sp)
    800031d2:	64a2                	ld	s1,8(sp)
    800031d4:	6902                	ld	s2,0(sp)
    800031d6:	6105                	addi	sp,sp,32
    800031d8:	8082                	ret
    panic("brelse");
    800031da:	00005517          	auipc	a0,0x5
    800031de:	3be50513          	addi	a0,a0,958 # 80008598 <syscalls+0xf8>
    800031e2:	ffffd097          	auipc	ra,0xffffd
    800031e6:	362080e7          	jalr	866(ra) # 80000544 <panic>

00000000800031ea <bpin>:

void
bpin(struct buf *b) {
    800031ea:	1101                	addi	sp,sp,-32
    800031ec:	ec06                	sd	ra,24(sp)
    800031ee:	e822                	sd	s0,16(sp)
    800031f0:	e426                	sd	s1,8(sp)
    800031f2:	1000                	addi	s0,sp,32
    800031f4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031f6:	00014517          	auipc	a0,0x14
    800031fa:	91250513          	addi	a0,a0,-1774 # 80016b08 <bcache>
    800031fe:	ffffe097          	auipc	ra,0xffffe
    80003202:	a0e080e7          	jalr	-1522(ra) # 80000c0c <acquire>
  b->refcnt++;
    80003206:	40bc                	lw	a5,64(s1)
    80003208:	2785                	addiw	a5,a5,1
    8000320a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000320c:	00014517          	auipc	a0,0x14
    80003210:	8fc50513          	addi	a0,a0,-1796 # 80016b08 <bcache>
    80003214:	ffffe097          	auipc	ra,0xffffe
    80003218:	aac080e7          	jalr	-1364(ra) # 80000cc0 <release>
}
    8000321c:	60e2                	ld	ra,24(sp)
    8000321e:	6442                	ld	s0,16(sp)
    80003220:	64a2                	ld	s1,8(sp)
    80003222:	6105                	addi	sp,sp,32
    80003224:	8082                	ret

0000000080003226 <bunpin>:

void
bunpin(struct buf *b) {
    80003226:	1101                	addi	sp,sp,-32
    80003228:	ec06                	sd	ra,24(sp)
    8000322a:	e822                	sd	s0,16(sp)
    8000322c:	e426                	sd	s1,8(sp)
    8000322e:	1000                	addi	s0,sp,32
    80003230:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003232:	00014517          	auipc	a0,0x14
    80003236:	8d650513          	addi	a0,a0,-1834 # 80016b08 <bcache>
    8000323a:	ffffe097          	auipc	ra,0xffffe
    8000323e:	9d2080e7          	jalr	-1582(ra) # 80000c0c <acquire>
  b->refcnt--;
    80003242:	40bc                	lw	a5,64(s1)
    80003244:	37fd                	addiw	a5,a5,-1
    80003246:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003248:	00014517          	auipc	a0,0x14
    8000324c:	8c050513          	addi	a0,a0,-1856 # 80016b08 <bcache>
    80003250:	ffffe097          	auipc	ra,0xffffe
    80003254:	a70080e7          	jalr	-1424(ra) # 80000cc0 <release>
}
    80003258:	60e2                	ld	ra,24(sp)
    8000325a:	6442                	ld	s0,16(sp)
    8000325c:	64a2                	ld	s1,8(sp)
    8000325e:	6105                	addi	sp,sp,32
    80003260:	8082                	ret

0000000080003262 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003262:	1101                	addi	sp,sp,-32
    80003264:	ec06                	sd	ra,24(sp)
    80003266:	e822                	sd	s0,16(sp)
    80003268:	e426                	sd	s1,8(sp)
    8000326a:	e04a                	sd	s2,0(sp)
    8000326c:	1000                	addi	s0,sp,32
    8000326e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003270:	00d5d59b          	srliw	a1,a1,0xd
    80003274:	0001c797          	auipc	a5,0x1c
    80003278:	f707a783          	lw	a5,-144(a5) # 8001f1e4 <sb+0x1c>
    8000327c:	9dbd                	addw	a1,a1,a5
    8000327e:	00000097          	auipc	ra,0x0
    80003282:	d9e080e7          	jalr	-610(ra) # 8000301c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003286:	0074f713          	andi	a4,s1,7
    8000328a:	4785                	li	a5,1
    8000328c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003290:	14ce                	slli	s1,s1,0x33
    80003292:	90d9                	srli	s1,s1,0x36
    80003294:	00950733          	add	a4,a0,s1
    80003298:	05874703          	lbu	a4,88(a4)
    8000329c:	00e7f6b3          	and	a3,a5,a4
    800032a0:	c69d                	beqz	a3,800032ce <bfree+0x6c>
    800032a2:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800032a4:	94aa                	add	s1,s1,a0
    800032a6:	fff7c793          	not	a5,a5
    800032aa:	8ff9                	and	a5,a5,a4
    800032ac:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800032b0:	00001097          	auipc	ra,0x1
    800032b4:	120080e7          	jalr	288(ra) # 800043d0 <log_write>
  brelse(bp);
    800032b8:	854a                	mv	a0,s2
    800032ba:	00000097          	auipc	ra,0x0
    800032be:	e92080e7          	jalr	-366(ra) # 8000314c <brelse>
}
    800032c2:	60e2                	ld	ra,24(sp)
    800032c4:	6442                	ld	s0,16(sp)
    800032c6:	64a2                	ld	s1,8(sp)
    800032c8:	6902                	ld	s2,0(sp)
    800032ca:	6105                	addi	sp,sp,32
    800032cc:	8082                	ret
    panic("freeing free block");
    800032ce:	00005517          	auipc	a0,0x5
    800032d2:	2d250513          	addi	a0,a0,722 # 800085a0 <syscalls+0x100>
    800032d6:	ffffd097          	auipc	ra,0xffffd
    800032da:	26e080e7          	jalr	622(ra) # 80000544 <panic>

00000000800032de <balloc>:
{
    800032de:	711d                	addi	sp,sp,-96
    800032e0:	ec86                	sd	ra,88(sp)
    800032e2:	e8a2                	sd	s0,80(sp)
    800032e4:	e4a6                	sd	s1,72(sp)
    800032e6:	e0ca                	sd	s2,64(sp)
    800032e8:	fc4e                	sd	s3,56(sp)
    800032ea:	f852                	sd	s4,48(sp)
    800032ec:	f456                	sd	s5,40(sp)
    800032ee:	f05a                	sd	s6,32(sp)
    800032f0:	ec5e                	sd	s7,24(sp)
    800032f2:	e862                	sd	s8,16(sp)
    800032f4:	e466                	sd	s9,8(sp)
    800032f6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800032f8:	0001c797          	auipc	a5,0x1c
    800032fc:	ed47a783          	lw	a5,-300(a5) # 8001f1cc <sb+0x4>
    80003300:	10078163          	beqz	a5,80003402 <balloc+0x124>
    80003304:	8baa                	mv	s7,a0
    80003306:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003308:	0001cb17          	auipc	s6,0x1c
    8000330c:	ec0b0b13          	addi	s6,s6,-320 # 8001f1c8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003310:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003312:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003314:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003316:	6c89                	lui	s9,0x2
    80003318:	a061                	j	800033a0 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000331a:	974a                	add	a4,a4,s2
    8000331c:	8fd5                	or	a5,a5,a3
    8000331e:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003322:	854a                	mv	a0,s2
    80003324:	00001097          	auipc	ra,0x1
    80003328:	0ac080e7          	jalr	172(ra) # 800043d0 <log_write>
        brelse(bp);
    8000332c:	854a                	mv	a0,s2
    8000332e:	00000097          	auipc	ra,0x0
    80003332:	e1e080e7          	jalr	-482(ra) # 8000314c <brelse>
  bp = bread(dev, bno);
    80003336:	85a6                	mv	a1,s1
    80003338:	855e                	mv	a0,s7
    8000333a:	00000097          	auipc	ra,0x0
    8000333e:	ce2080e7          	jalr	-798(ra) # 8000301c <bread>
    80003342:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003344:	40000613          	li	a2,1024
    80003348:	4581                	li	a1,0
    8000334a:	05850513          	addi	a0,a0,88
    8000334e:	ffffe097          	auipc	ra,0xffffe
    80003352:	9ba080e7          	jalr	-1606(ra) # 80000d08 <memset>
  log_write(bp);
    80003356:	854a                	mv	a0,s2
    80003358:	00001097          	auipc	ra,0x1
    8000335c:	078080e7          	jalr	120(ra) # 800043d0 <log_write>
  brelse(bp);
    80003360:	854a                	mv	a0,s2
    80003362:	00000097          	auipc	ra,0x0
    80003366:	dea080e7          	jalr	-534(ra) # 8000314c <brelse>
}
    8000336a:	8526                	mv	a0,s1
    8000336c:	60e6                	ld	ra,88(sp)
    8000336e:	6446                	ld	s0,80(sp)
    80003370:	64a6                	ld	s1,72(sp)
    80003372:	6906                	ld	s2,64(sp)
    80003374:	79e2                	ld	s3,56(sp)
    80003376:	7a42                	ld	s4,48(sp)
    80003378:	7aa2                	ld	s5,40(sp)
    8000337a:	7b02                	ld	s6,32(sp)
    8000337c:	6be2                	ld	s7,24(sp)
    8000337e:	6c42                	ld	s8,16(sp)
    80003380:	6ca2                	ld	s9,8(sp)
    80003382:	6125                	addi	sp,sp,96
    80003384:	8082                	ret
    brelse(bp);
    80003386:	854a                	mv	a0,s2
    80003388:	00000097          	auipc	ra,0x0
    8000338c:	dc4080e7          	jalr	-572(ra) # 8000314c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003390:	015c87bb          	addw	a5,s9,s5
    80003394:	00078a9b          	sext.w	s5,a5
    80003398:	004b2703          	lw	a4,4(s6)
    8000339c:	06eaf363          	bgeu	s5,a4,80003402 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    800033a0:	41fad79b          	sraiw	a5,s5,0x1f
    800033a4:	0137d79b          	srliw	a5,a5,0x13
    800033a8:	015787bb          	addw	a5,a5,s5
    800033ac:	40d7d79b          	sraiw	a5,a5,0xd
    800033b0:	01cb2583          	lw	a1,28(s6)
    800033b4:	9dbd                	addw	a1,a1,a5
    800033b6:	855e                	mv	a0,s7
    800033b8:	00000097          	auipc	ra,0x0
    800033bc:	c64080e7          	jalr	-924(ra) # 8000301c <bread>
    800033c0:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033c2:	004b2503          	lw	a0,4(s6)
    800033c6:	000a849b          	sext.w	s1,s5
    800033ca:	8662                	mv	a2,s8
    800033cc:	faa4fde3          	bgeu	s1,a0,80003386 <balloc+0xa8>
      m = 1 << (bi % 8);
    800033d0:	41f6579b          	sraiw	a5,a2,0x1f
    800033d4:	01d7d69b          	srliw	a3,a5,0x1d
    800033d8:	00c6873b          	addw	a4,a3,a2
    800033dc:	00777793          	andi	a5,a4,7
    800033e0:	9f95                	subw	a5,a5,a3
    800033e2:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800033e6:	4037571b          	sraiw	a4,a4,0x3
    800033ea:	00e906b3          	add	a3,s2,a4
    800033ee:	0586c683          	lbu	a3,88(a3)
    800033f2:	00d7f5b3          	and	a1,a5,a3
    800033f6:	d195                	beqz	a1,8000331a <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033f8:	2605                	addiw	a2,a2,1
    800033fa:	2485                	addiw	s1,s1,1
    800033fc:	fd4618e3          	bne	a2,s4,800033cc <balloc+0xee>
    80003400:	b759                	j	80003386 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003402:	00005517          	auipc	a0,0x5
    80003406:	1b650513          	addi	a0,a0,438 # 800085b8 <syscalls+0x118>
    8000340a:	ffffd097          	auipc	ra,0xffffd
    8000340e:	184080e7          	jalr	388(ra) # 8000058e <printf>
  return 0;
    80003412:	4481                	li	s1,0
    80003414:	bf99                	j	8000336a <balloc+0x8c>

0000000080003416 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003416:	7179                	addi	sp,sp,-48
    80003418:	f406                	sd	ra,40(sp)
    8000341a:	f022                	sd	s0,32(sp)
    8000341c:	ec26                	sd	s1,24(sp)
    8000341e:	e84a                	sd	s2,16(sp)
    80003420:	e44e                	sd	s3,8(sp)
    80003422:	e052                	sd	s4,0(sp)
    80003424:	1800                	addi	s0,sp,48
    80003426:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003428:	47ad                	li	a5,11
    8000342a:	02b7e763          	bltu	a5,a1,80003458 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    8000342e:	02059493          	slli	s1,a1,0x20
    80003432:	9081                	srli	s1,s1,0x20
    80003434:	048a                	slli	s1,s1,0x2
    80003436:	94aa                	add	s1,s1,a0
    80003438:	0504a903          	lw	s2,80(s1)
    8000343c:	06091e63          	bnez	s2,800034b8 <bmap+0xa2>
      addr = balloc(ip->dev);
    80003440:	4108                	lw	a0,0(a0)
    80003442:	00000097          	auipc	ra,0x0
    80003446:	e9c080e7          	jalr	-356(ra) # 800032de <balloc>
    8000344a:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000344e:	06090563          	beqz	s2,800034b8 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003452:	0524a823          	sw	s2,80(s1)
    80003456:	a08d                	j	800034b8 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003458:	ff45849b          	addiw	s1,a1,-12
    8000345c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003460:	0ff00793          	li	a5,255
    80003464:	08e7e563          	bltu	a5,a4,800034ee <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003468:	08052903          	lw	s2,128(a0)
    8000346c:	00091d63          	bnez	s2,80003486 <bmap+0x70>
      addr = balloc(ip->dev);
    80003470:	4108                	lw	a0,0(a0)
    80003472:	00000097          	auipc	ra,0x0
    80003476:	e6c080e7          	jalr	-404(ra) # 800032de <balloc>
    8000347a:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000347e:	02090d63          	beqz	s2,800034b8 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003482:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003486:	85ca                	mv	a1,s2
    80003488:	0009a503          	lw	a0,0(s3)
    8000348c:	00000097          	auipc	ra,0x0
    80003490:	b90080e7          	jalr	-1136(ra) # 8000301c <bread>
    80003494:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003496:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000349a:	02049593          	slli	a1,s1,0x20
    8000349e:	9181                	srli	a1,a1,0x20
    800034a0:	058a                	slli	a1,a1,0x2
    800034a2:	00b784b3          	add	s1,a5,a1
    800034a6:	0004a903          	lw	s2,0(s1)
    800034aa:	02090063          	beqz	s2,800034ca <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800034ae:	8552                	mv	a0,s4
    800034b0:	00000097          	auipc	ra,0x0
    800034b4:	c9c080e7          	jalr	-868(ra) # 8000314c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800034b8:	854a                	mv	a0,s2
    800034ba:	70a2                	ld	ra,40(sp)
    800034bc:	7402                	ld	s0,32(sp)
    800034be:	64e2                	ld	s1,24(sp)
    800034c0:	6942                	ld	s2,16(sp)
    800034c2:	69a2                	ld	s3,8(sp)
    800034c4:	6a02                	ld	s4,0(sp)
    800034c6:	6145                	addi	sp,sp,48
    800034c8:	8082                	ret
      addr = balloc(ip->dev);
    800034ca:	0009a503          	lw	a0,0(s3)
    800034ce:	00000097          	auipc	ra,0x0
    800034d2:	e10080e7          	jalr	-496(ra) # 800032de <balloc>
    800034d6:	0005091b          	sext.w	s2,a0
      if(addr){
    800034da:	fc090ae3          	beqz	s2,800034ae <bmap+0x98>
        a[bn] = addr;
    800034de:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800034e2:	8552                	mv	a0,s4
    800034e4:	00001097          	auipc	ra,0x1
    800034e8:	eec080e7          	jalr	-276(ra) # 800043d0 <log_write>
    800034ec:	b7c9                	j	800034ae <bmap+0x98>
  panic("bmap: out of range");
    800034ee:	00005517          	auipc	a0,0x5
    800034f2:	0e250513          	addi	a0,a0,226 # 800085d0 <syscalls+0x130>
    800034f6:	ffffd097          	auipc	ra,0xffffd
    800034fa:	04e080e7          	jalr	78(ra) # 80000544 <panic>

00000000800034fe <iget>:
{
    800034fe:	7179                	addi	sp,sp,-48
    80003500:	f406                	sd	ra,40(sp)
    80003502:	f022                	sd	s0,32(sp)
    80003504:	ec26                	sd	s1,24(sp)
    80003506:	e84a                	sd	s2,16(sp)
    80003508:	e44e                	sd	s3,8(sp)
    8000350a:	e052                	sd	s4,0(sp)
    8000350c:	1800                	addi	s0,sp,48
    8000350e:	89aa                	mv	s3,a0
    80003510:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003512:	0001c517          	auipc	a0,0x1c
    80003516:	cd650513          	addi	a0,a0,-810 # 8001f1e8 <itable>
    8000351a:	ffffd097          	auipc	ra,0xffffd
    8000351e:	6f2080e7          	jalr	1778(ra) # 80000c0c <acquire>
  empty = 0;
    80003522:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003524:	0001c497          	auipc	s1,0x1c
    80003528:	cdc48493          	addi	s1,s1,-804 # 8001f200 <itable+0x18>
    8000352c:	0001d697          	auipc	a3,0x1d
    80003530:	76468693          	addi	a3,a3,1892 # 80020c90 <log>
    80003534:	a039                	j	80003542 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003536:	02090b63          	beqz	s2,8000356c <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000353a:	08848493          	addi	s1,s1,136
    8000353e:	02d48a63          	beq	s1,a3,80003572 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003542:	449c                	lw	a5,8(s1)
    80003544:	fef059e3          	blez	a5,80003536 <iget+0x38>
    80003548:	4098                	lw	a4,0(s1)
    8000354a:	ff3716e3          	bne	a4,s3,80003536 <iget+0x38>
    8000354e:	40d8                	lw	a4,4(s1)
    80003550:	ff4713e3          	bne	a4,s4,80003536 <iget+0x38>
      ip->ref++;
    80003554:	2785                	addiw	a5,a5,1
    80003556:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003558:	0001c517          	auipc	a0,0x1c
    8000355c:	c9050513          	addi	a0,a0,-880 # 8001f1e8 <itable>
    80003560:	ffffd097          	auipc	ra,0xffffd
    80003564:	760080e7          	jalr	1888(ra) # 80000cc0 <release>
      return ip;
    80003568:	8926                	mv	s2,s1
    8000356a:	a03d                	j	80003598 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000356c:	f7f9                	bnez	a5,8000353a <iget+0x3c>
    8000356e:	8926                	mv	s2,s1
    80003570:	b7e9                	j	8000353a <iget+0x3c>
  if(empty == 0)
    80003572:	02090c63          	beqz	s2,800035aa <iget+0xac>
  ip->dev = dev;
    80003576:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000357a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000357e:	4785                	li	a5,1
    80003580:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003584:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003588:	0001c517          	auipc	a0,0x1c
    8000358c:	c6050513          	addi	a0,a0,-928 # 8001f1e8 <itable>
    80003590:	ffffd097          	auipc	ra,0xffffd
    80003594:	730080e7          	jalr	1840(ra) # 80000cc0 <release>
}
    80003598:	854a                	mv	a0,s2
    8000359a:	70a2                	ld	ra,40(sp)
    8000359c:	7402                	ld	s0,32(sp)
    8000359e:	64e2                	ld	s1,24(sp)
    800035a0:	6942                	ld	s2,16(sp)
    800035a2:	69a2                	ld	s3,8(sp)
    800035a4:	6a02                	ld	s4,0(sp)
    800035a6:	6145                	addi	sp,sp,48
    800035a8:	8082                	ret
    panic("iget: no inodes");
    800035aa:	00005517          	auipc	a0,0x5
    800035ae:	03e50513          	addi	a0,a0,62 # 800085e8 <syscalls+0x148>
    800035b2:	ffffd097          	auipc	ra,0xffffd
    800035b6:	f92080e7          	jalr	-110(ra) # 80000544 <panic>

00000000800035ba <fsinit>:
fsinit(int dev) {
    800035ba:	7179                	addi	sp,sp,-48
    800035bc:	f406                	sd	ra,40(sp)
    800035be:	f022                	sd	s0,32(sp)
    800035c0:	ec26                	sd	s1,24(sp)
    800035c2:	e84a                	sd	s2,16(sp)
    800035c4:	e44e                	sd	s3,8(sp)
    800035c6:	1800                	addi	s0,sp,48
    800035c8:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800035ca:	4585                	li	a1,1
    800035cc:	00000097          	auipc	ra,0x0
    800035d0:	a50080e7          	jalr	-1456(ra) # 8000301c <bread>
    800035d4:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800035d6:	0001c997          	auipc	s3,0x1c
    800035da:	bf298993          	addi	s3,s3,-1038 # 8001f1c8 <sb>
    800035de:	02000613          	li	a2,32
    800035e2:	05850593          	addi	a1,a0,88
    800035e6:	854e                	mv	a0,s3
    800035e8:	ffffd097          	auipc	ra,0xffffd
    800035ec:	780080e7          	jalr	1920(ra) # 80000d68 <memmove>
  brelse(bp);
    800035f0:	8526                	mv	a0,s1
    800035f2:	00000097          	auipc	ra,0x0
    800035f6:	b5a080e7          	jalr	-1190(ra) # 8000314c <brelse>
  if(sb.magic != FSMAGIC)
    800035fa:	0009a703          	lw	a4,0(s3)
    800035fe:	102037b7          	lui	a5,0x10203
    80003602:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003606:	02f71263          	bne	a4,a5,8000362a <fsinit+0x70>
  initlog(dev, &sb);
    8000360a:	0001c597          	auipc	a1,0x1c
    8000360e:	bbe58593          	addi	a1,a1,-1090 # 8001f1c8 <sb>
    80003612:	854a                	mv	a0,s2
    80003614:	00001097          	auipc	ra,0x1
    80003618:	b40080e7          	jalr	-1216(ra) # 80004154 <initlog>
}
    8000361c:	70a2                	ld	ra,40(sp)
    8000361e:	7402                	ld	s0,32(sp)
    80003620:	64e2                	ld	s1,24(sp)
    80003622:	6942                	ld	s2,16(sp)
    80003624:	69a2                	ld	s3,8(sp)
    80003626:	6145                	addi	sp,sp,48
    80003628:	8082                	ret
    panic("invalid file system");
    8000362a:	00005517          	auipc	a0,0x5
    8000362e:	fce50513          	addi	a0,a0,-50 # 800085f8 <syscalls+0x158>
    80003632:	ffffd097          	auipc	ra,0xffffd
    80003636:	f12080e7          	jalr	-238(ra) # 80000544 <panic>

000000008000363a <iinit>:
{
    8000363a:	7179                	addi	sp,sp,-48
    8000363c:	f406                	sd	ra,40(sp)
    8000363e:	f022                	sd	s0,32(sp)
    80003640:	ec26                	sd	s1,24(sp)
    80003642:	e84a                	sd	s2,16(sp)
    80003644:	e44e                	sd	s3,8(sp)
    80003646:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003648:	00005597          	auipc	a1,0x5
    8000364c:	fc858593          	addi	a1,a1,-56 # 80008610 <syscalls+0x170>
    80003650:	0001c517          	auipc	a0,0x1c
    80003654:	b9850513          	addi	a0,a0,-1128 # 8001f1e8 <itable>
    80003658:	ffffd097          	auipc	ra,0xffffd
    8000365c:	524080e7          	jalr	1316(ra) # 80000b7c <initlock>
  for(i = 0; i < NINODE; i++) {
    80003660:	0001c497          	auipc	s1,0x1c
    80003664:	bb048493          	addi	s1,s1,-1104 # 8001f210 <itable+0x28>
    80003668:	0001d997          	auipc	s3,0x1d
    8000366c:	63898993          	addi	s3,s3,1592 # 80020ca0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003670:	00005917          	auipc	s2,0x5
    80003674:	fa890913          	addi	s2,s2,-88 # 80008618 <syscalls+0x178>
    80003678:	85ca                	mv	a1,s2
    8000367a:	8526                	mv	a0,s1
    8000367c:	00001097          	auipc	ra,0x1
    80003680:	e3a080e7          	jalr	-454(ra) # 800044b6 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003684:	08848493          	addi	s1,s1,136
    80003688:	ff3498e3          	bne	s1,s3,80003678 <iinit+0x3e>
}
    8000368c:	70a2                	ld	ra,40(sp)
    8000368e:	7402                	ld	s0,32(sp)
    80003690:	64e2                	ld	s1,24(sp)
    80003692:	6942                	ld	s2,16(sp)
    80003694:	69a2                	ld	s3,8(sp)
    80003696:	6145                	addi	sp,sp,48
    80003698:	8082                	ret

000000008000369a <ialloc>:
{
    8000369a:	715d                	addi	sp,sp,-80
    8000369c:	e486                	sd	ra,72(sp)
    8000369e:	e0a2                	sd	s0,64(sp)
    800036a0:	fc26                	sd	s1,56(sp)
    800036a2:	f84a                	sd	s2,48(sp)
    800036a4:	f44e                	sd	s3,40(sp)
    800036a6:	f052                	sd	s4,32(sp)
    800036a8:	ec56                	sd	s5,24(sp)
    800036aa:	e85a                	sd	s6,16(sp)
    800036ac:	e45e                	sd	s7,8(sp)
    800036ae:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800036b0:	0001c717          	auipc	a4,0x1c
    800036b4:	b2472703          	lw	a4,-1244(a4) # 8001f1d4 <sb+0xc>
    800036b8:	4785                	li	a5,1
    800036ba:	04e7fa63          	bgeu	a5,a4,8000370e <ialloc+0x74>
    800036be:	8aaa                	mv	s5,a0
    800036c0:	8bae                	mv	s7,a1
    800036c2:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800036c4:	0001ca17          	auipc	s4,0x1c
    800036c8:	b04a0a13          	addi	s4,s4,-1276 # 8001f1c8 <sb>
    800036cc:	00048b1b          	sext.w	s6,s1
    800036d0:	0044d593          	srli	a1,s1,0x4
    800036d4:	018a2783          	lw	a5,24(s4)
    800036d8:	9dbd                	addw	a1,a1,a5
    800036da:	8556                	mv	a0,s5
    800036dc:	00000097          	auipc	ra,0x0
    800036e0:	940080e7          	jalr	-1728(ra) # 8000301c <bread>
    800036e4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800036e6:	05850993          	addi	s3,a0,88
    800036ea:	00f4f793          	andi	a5,s1,15
    800036ee:	079a                	slli	a5,a5,0x6
    800036f0:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800036f2:	00099783          	lh	a5,0(s3)
    800036f6:	c3a1                	beqz	a5,80003736 <ialloc+0x9c>
    brelse(bp);
    800036f8:	00000097          	auipc	ra,0x0
    800036fc:	a54080e7          	jalr	-1452(ra) # 8000314c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003700:	0485                	addi	s1,s1,1
    80003702:	00ca2703          	lw	a4,12(s4)
    80003706:	0004879b          	sext.w	a5,s1
    8000370a:	fce7e1e3          	bltu	a5,a4,800036cc <ialloc+0x32>
  printf("ialloc: no inodes\n");
    8000370e:	00005517          	auipc	a0,0x5
    80003712:	f1250513          	addi	a0,a0,-238 # 80008620 <syscalls+0x180>
    80003716:	ffffd097          	auipc	ra,0xffffd
    8000371a:	e78080e7          	jalr	-392(ra) # 8000058e <printf>
  return 0;
    8000371e:	4501                	li	a0,0
}
    80003720:	60a6                	ld	ra,72(sp)
    80003722:	6406                	ld	s0,64(sp)
    80003724:	74e2                	ld	s1,56(sp)
    80003726:	7942                	ld	s2,48(sp)
    80003728:	79a2                	ld	s3,40(sp)
    8000372a:	7a02                	ld	s4,32(sp)
    8000372c:	6ae2                	ld	s5,24(sp)
    8000372e:	6b42                	ld	s6,16(sp)
    80003730:	6ba2                	ld	s7,8(sp)
    80003732:	6161                	addi	sp,sp,80
    80003734:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003736:	04000613          	li	a2,64
    8000373a:	4581                	li	a1,0
    8000373c:	854e                	mv	a0,s3
    8000373e:	ffffd097          	auipc	ra,0xffffd
    80003742:	5ca080e7          	jalr	1482(ra) # 80000d08 <memset>
      dip->type = type;
    80003746:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000374a:	854a                	mv	a0,s2
    8000374c:	00001097          	auipc	ra,0x1
    80003750:	c84080e7          	jalr	-892(ra) # 800043d0 <log_write>
      brelse(bp);
    80003754:	854a                	mv	a0,s2
    80003756:	00000097          	auipc	ra,0x0
    8000375a:	9f6080e7          	jalr	-1546(ra) # 8000314c <brelse>
      return iget(dev, inum);
    8000375e:	85da                	mv	a1,s6
    80003760:	8556                	mv	a0,s5
    80003762:	00000097          	auipc	ra,0x0
    80003766:	d9c080e7          	jalr	-612(ra) # 800034fe <iget>
    8000376a:	bf5d                	j	80003720 <ialloc+0x86>

000000008000376c <iupdate>:
{
    8000376c:	1101                	addi	sp,sp,-32
    8000376e:	ec06                	sd	ra,24(sp)
    80003770:	e822                	sd	s0,16(sp)
    80003772:	e426                	sd	s1,8(sp)
    80003774:	e04a                	sd	s2,0(sp)
    80003776:	1000                	addi	s0,sp,32
    80003778:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000377a:	415c                	lw	a5,4(a0)
    8000377c:	0047d79b          	srliw	a5,a5,0x4
    80003780:	0001c597          	auipc	a1,0x1c
    80003784:	a605a583          	lw	a1,-1440(a1) # 8001f1e0 <sb+0x18>
    80003788:	9dbd                	addw	a1,a1,a5
    8000378a:	4108                	lw	a0,0(a0)
    8000378c:	00000097          	auipc	ra,0x0
    80003790:	890080e7          	jalr	-1904(ra) # 8000301c <bread>
    80003794:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003796:	05850793          	addi	a5,a0,88
    8000379a:	40c8                	lw	a0,4(s1)
    8000379c:	893d                	andi	a0,a0,15
    8000379e:	051a                	slli	a0,a0,0x6
    800037a0:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800037a2:	04449703          	lh	a4,68(s1)
    800037a6:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800037aa:	04649703          	lh	a4,70(s1)
    800037ae:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800037b2:	04849703          	lh	a4,72(s1)
    800037b6:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800037ba:	04a49703          	lh	a4,74(s1)
    800037be:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800037c2:	44f8                	lw	a4,76(s1)
    800037c4:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800037c6:	03400613          	li	a2,52
    800037ca:	05048593          	addi	a1,s1,80
    800037ce:	0531                	addi	a0,a0,12
    800037d0:	ffffd097          	auipc	ra,0xffffd
    800037d4:	598080e7          	jalr	1432(ra) # 80000d68 <memmove>
  log_write(bp);
    800037d8:	854a                	mv	a0,s2
    800037da:	00001097          	auipc	ra,0x1
    800037de:	bf6080e7          	jalr	-1034(ra) # 800043d0 <log_write>
  brelse(bp);
    800037e2:	854a                	mv	a0,s2
    800037e4:	00000097          	auipc	ra,0x0
    800037e8:	968080e7          	jalr	-1688(ra) # 8000314c <brelse>
}
    800037ec:	60e2                	ld	ra,24(sp)
    800037ee:	6442                	ld	s0,16(sp)
    800037f0:	64a2                	ld	s1,8(sp)
    800037f2:	6902                	ld	s2,0(sp)
    800037f4:	6105                	addi	sp,sp,32
    800037f6:	8082                	ret

00000000800037f8 <idup>:
{
    800037f8:	1101                	addi	sp,sp,-32
    800037fa:	ec06                	sd	ra,24(sp)
    800037fc:	e822                	sd	s0,16(sp)
    800037fe:	e426                	sd	s1,8(sp)
    80003800:	1000                	addi	s0,sp,32
    80003802:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003804:	0001c517          	auipc	a0,0x1c
    80003808:	9e450513          	addi	a0,a0,-1564 # 8001f1e8 <itable>
    8000380c:	ffffd097          	auipc	ra,0xffffd
    80003810:	400080e7          	jalr	1024(ra) # 80000c0c <acquire>
  ip->ref++;
    80003814:	449c                	lw	a5,8(s1)
    80003816:	2785                	addiw	a5,a5,1
    80003818:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000381a:	0001c517          	auipc	a0,0x1c
    8000381e:	9ce50513          	addi	a0,a0,-1586 # 8001f1e8 <itable>
    80003822:	ffffd097          	auipc	ra,0xffffd
    80003826:	49e080e7          	jalr	1182(ra) # 80000cc0 <release>
}
    8000382a:	8526                	mv	a0,s1
    8000382c:	60e2                	ld	ra,24(sp)
    8000382e:	6442                	ld	s0,16(sp)
    80003830:	64a2                	ld	s1,8(sp)
    80003832:	6105                	addi	sp,sp,32
    80003834:	8082                	ret

0000000080003836 <ilock>:
{
    80003836:	1101                	addi	sp,sp,-32
    80003838:	ec06                	sd	ra,24(sp)
    8000383a:	e822                	sd	s0,16(sp)
    8000383c:	e426                	sd	s1,8(sp)
    8000383e:	e04a                	sd	s2,0(sp)
    80003840:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003842:	c115                	beqz	a0,80003866 <ilock+0x30>
    80003844:	84aa                	mv	s1,a0
    80003846:	451c                	lw	a5,8(a0)
    80003848:	00f05f63          	blez	a5,80003866 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000384c:	0541                	addi	a0,a0,16
    8000384e:	00001097          	auipc	ra,0x1
    80003852:	ca2080e7          	jalr	-862(ra) # 800044f0 <acquiresleep>
  if(ip->valid == 0){
    80003856:	40bc                	lw	a5,64(s1)
    80003858:	cf99                	beqz	a5,80003876 <ilock+0x40>
}
    8000385a:	60e2                	ld	ra,24(sp)
    8000385c:	6442                	ld	s0,16(sp)
    8000385e:	64a2                	ld	s1,8(sp)
    80003860:	6902                	ld	s2,0(sp)
    80003862:	6105                	addi	sp,sp,32
    80003864:	8082                	ret
    panic("ilock");
    80003866:	00005517          	auipc	a0,0x5
    8000386a:	dd250513          	addi	a0,a0,-558 # 80008638 <syscalls+0x198>
    8000386e:	ffffd097          	auipc	ra,0xffffd
    80003872:	cd6080e7          	jalr	-810(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003876:	40dc                	lw	a5,4(s1)
    80003878:	0047d79b          	srliw	a5,a5,0x4
    8000387c:	0001c597          	auipc	a1,0x1c
    80003880:	9645a583          	lw	a1,-1692(a1) # 8001f1e0 <sb+0x18>
    80003884:	9dbd                	addw	a1,a1,a5
    80003886:	4088                	lw	a0,0(s1)
    80003888:	fffff097          	auipc	ra,0xfffff
    8000388c:	794080e7          	jalr	1940(ra) # 8000301c <bread>
    80003890:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003892:	05850593          	addi	a1,a0,88
    80003896:	40dc                	lw	a5,4(s1)
    80003898:	8bbd                	andi	a5,a5,15
    8000389a:	079a                	slli	a5,a5,0x6
    8000389c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000389e:	00059783          	lh	a5,0(a1)
    800038a2:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800038a6:	00259783          	lh	a5,2(a1)
    800038aa:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800038ae:	00459783          	lh	a5,4(a1)
    800038b2:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800038b6:	00659783          	lh	a5,6(a1)
    800038ba:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800038be:	459c                	lw	a5,8(a1)
    800038c0:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800038c2:	03400613          	li	a2,52
    800038c6:	05b1                	addi	a1,a1,12
    800038c8:	05048513          	addi	a0,s1,80
    800038cc:	ffffd097          	auipc	ra,0xffffd
    800038d0:	49c080e7          	jalr	1180(ra) # 80000d68 <memmove>
    brelse(bp);
    800038d4:	854a                	mv	a0,s2
    800038d6:	00000097          	auipc	ra,0x0
    800038da:	876080e7          	jalr	-1930(ra) # 8000314c <brelse>
    ip->valid = 1;
    800038de:	4785                	li	a5,1
    800038e0:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800038e2:	04449783          	lh	a5,68(s1)
    800038e6:	fbb5                	bnez	a5,8000385a <ilock+0x24>
      panic("ilock: no type");
    800038e8:	00005517          	auipc	a0,0x5
    800038ec:	d5850513          	addi	a0,a0,-680 # 80008640 <syscalls+0x1a0>
    800038f0:	ffffd097          	auipc	ra,0xffffd
    800038f4:	c54080e7          	jalr	-940(ra) # 80000544 <panic>

00000000800038f8 <iunlock>:
{
    800038f8:	1101                	addi	sp,sp,-32
    800038fa:	ec06                	sd	ra,24(sp)
    800038fc:	e822                	sd	s0,16(sp)
    800038fe:	e426                	sd	s1,8(sp)
    80003900:	e04a                	sd	s2,0(sp)
    80003902:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003904:	c905                	beqz	a0,80003934 <iunlock+0x3c>
    80003906:	84aa                	mv	s1,a0
    80003908:	01050913          	addi	s2,a0,16
    8000390c:	854a                	mv	a0,s2
    8000390e:	00001097          	auipc	ra,0x1
    80003912:	c7c080e7          	jalr	-900(ra) # 8000458a <holdingsleep>
    80003916:	cd19                	beqz	a0,80003934 <iunlock+0x3c>
    80003918:	449c                	lw	a5,8(s1)
    8000391a:	00f05d63          	blez	a5,80003934 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000391e:	854a                	mv	a0,s2
    80003920:	00001097          	auipc	ra,0x1
    80003924:	c26080e7          	jalr	-986(ra) # 80004546 <releasesleep>
}
    80003928:	60e2                	ld	ra,24(sp)
    8000392a:	6442                	ld	s0,16(sp)
    8000392c:	64a2                	ld	s1,8(sp)
    8000392e:	6902                	ld	s2,0(sp)
    80003930:	6105                	addi	sp,sp,32
    80003932:	8082                	ret
    panic("iunlock");
    80003934:	00005517          	auipc	a0,0x5
    80003938:	d1c50513          	addi	a0,a0,-740 # 80008650 <syscalls+0x1b0>
    8000393c:	ffffd097          	auipc	ra,0xffffd
    80003940:	c08080e7          	jalr	-1016(ra) # 80000544 <panic>

0000000080003944 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003944:	7179                	addi	sp,sp,-48
    80003946:	f406                	sd	ra,40(sp)
    80003948:	f022                	sd	s0,32(sp)
    8000394a:	ec26                	sd	s1,24(sp)
    8000394c:	e84a                	sd	s2,16(sp)
    8000394e:	e44e                	sd	s3,8(sp)
    80003950:	e052                	sd	s4,0(sp)
    80003952:	1800                	addi	s0,sp,48
    80003954:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003956:	05050493          	addi	s1,a0,80
    8000395a:	08050913          	addi	s2,a0,128
    8000395e:	a021                	j	80003966 <itrunc+0x22>
    80003960:	0491                	addi	s1,s1,4
    80003962:	01248d63          	beq	s1,s2,8000397c <itrunc+0x38>
    if(ip->addrs[i]){
    80003966:	408c                	lw	a1,0(s1)
    80003968:	dde5                	beqz	a1,80003960 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000396a:	0009a503          	lw	a0,0(s3)
    8000396e:	00000097          	auipc	ra,0x0
    80003972:	8f4080e7          	jalr	-1804(ra) # 80003262 <bfree>
      ip->addrs[i] = 0;
    80003976:	0004a023          	sw	zero,0(s1)
    8000397a:	b7dd                	j	80003960 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000397c:	0809a583          	lw	a1,128(s3)
    80003980:	e185                	bnez	a1,800039a0 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003982:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003986:	854e                	mv	a0,s3
    80003988:	00000097          	auipc	ra,0x0
    8000398c:	de4080e7          	jalr	-540(ra) # 8000376c <iupdate>
}
    80003990:	70a2                	ld	ra,40(sp)
    80003992:	7402                	ld	s0,32(sp)
    80003994:	64e2                	ld	s1,24(sp)
    80003996:	6942                	ld	s2,16(sp)
    80003998:	69a2                	ld	s3,8(sp)
    8000399a:	6a02                	ld	s4,0(sp)
    8000399c:	6145                	addi	sp,sp,48
    8000399e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800039a0:	0009a503          	lw	a0,0(s3)
    800039a4:	fffff097          	auipc	ra,0xfffff
    800039a8:	678080e7          	jalr	1656(ra) # 8000301c <bread>
    800039ac:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800039ae:	05850493          	addi	s1,a0,88
    800039b2:	45850913          	addi	s2,a0,1112
    800039b6:	a811                	j	800039ca <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800039b8:	0009a503          	lw	a0,0(s3)
    800039bc:	00000097          	auipc	ra,0x0
    800039c0:	8a6080e7          	jalr	-1882(ra) # 80003262 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800039c4:	0491                	addi	s1,s1,4
    800039c6:	01248563          	beq	s1,s2,800039d0 <itrunc+0x8c>
      if(a[j])
    800039ca:	408c                	lw	a1,0(s1)
    800039cc:	dde5                	beqz	a1,800039c4 <itrunc+0x80>
    800039ce:	b7ed                	j	800039b8 <itrunc+0x74>
    brelse(bp);
    800039d0:	8552                	mv	a0,s4
    800039d2:	fffff097          	auipc	ra,0xfffff
    800039d6:	77a080e7          	jalr	1914(ra) # 8000314c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800039da:	0809a583          	lw	a1,128(s3)
    800039de:	0009a503          	lw	a0,0(s3)
    800039e2:	00000097          	auipc	ra,0x0
    800039e6:	880080e7          	jalr	-1920(ra) # 80003262 <bfree>
    ip->addrs[NDIRECT] = 0;
    800039ea:	0809a023          	sw	zero,128(s3)
    800039ee:	bf51                	j	80003982 <itrunc+0x3e>

00000000800039f0 <iput>:
{
    800039f0:	1101                	addi	sp,sp,-32
    800039f2:	ec06                	sd	ra,24(sp)
    800039f4:	e822                	sd	s0,16(sp)
    800039f6:	e426                	sd	s1,8(sp)
    800039f8:	e04a                	sd	s2,0(sp)
    800039fa:	1000                	addi	s0,sp,32
    800039fc:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800039fe:	0001b517          	auipc	a0,0x1b
    80003a02:	7ea50513          	addi	a0,a0,2026 # 8001f1e8 <itable>
    80003a06:	ffffd097          	auipc	ra,0xffffd
    80003a0a:	206080e7          	jalr	518(ra) # 80000c0c <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a0e:	4498                	lw	a4,8(s1)
    80003a10:	4785                	li	a5,1
    80003a12:	02f70363          	beq	a4,a5,80003a38 <iput+0x48>
  ip->ref--;
    80003a16:	449c                	lw	a5,8(s1)
    80003a18:	37fd                	addiw	a5,a5,-1
    80003a1a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a1c:	0001b517          	auipc	a0,0x1b
    80003a20:	7cc50513          	addi	a0,a0,1996 # 8001f1e8 <itable>
    80003a24:	ffffd097          	auipc	ra,0xffffd
    80003a28:	29c080e7          	jalr	668(ra) # 80000cc0 <release>
}
    80003a2c:	60e2                	ld	ra,24(sp)
    80003a2e:	6442                	ld	s0,16(sp)
    80003a30:	64a2                	ld	s1,8(sp)
    80003a32:	6902                	ld	s2,0(sp)
    80003a34:	6105                	addi	sp,sp,32
    80003a36:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a38:	40bc                	lw	a5,64(s1)
    80003a3a:	dff1                	beqz	a5,80003a16 <iput+0x26>
    80003a3c:	04a49783          	lh	a5,74(s1)
    80003a40:	fbf9                	bnez	a5,80003a16 <iput+0x26>
    acquiresleep(&ip->lock);
    80003a42:	01048913          	addi	s2,s1,16
    80003a46:	854a                	mv	a0,s2
    80003a48:	00001097          	auipc	ra,0x1
    80003a4c:	aa8080e7          	jalr	-1368(ra) # 800044f0 <acquiresleep>
    release(&itable.lock);
    80003a50:	0001b517          	auipc	a0,0x1b
    80003a54:	79850513          	addi	a0,a0,1944 # 8001f1e8 <itable>
    80003a58:	ffffd097          	auipc	ra,0xffffd
    80003a5c:	268080e7          	jalr	616(ra) # 80000cc0 <release>
    itrunc(ip);
    80003a60:	8526                	mv	a0,s1
    80003a62:	00000097          	auipc	ra,0x0
    80003a66:	ee2080e7          	jalr	-286(ra) # 80003944 <itrunc>
    ip->type = 0;
    80003a6a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a6e:	8526                	mv	a0,s1
    80003a70:	00000097          	auipc	ra,0x0
    80003a74:	cfc080e7          	jalr	-772(ra) # 8000376c <iupdate>
    ip->valid = 0;
    80003a78:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a7c:	854a                	mv	a0,s2
    80003a7e:	00001097          	auipc	ra,0x1
    80003a82:	ac8080e7          	jalr	-1336(ra) # 80004546 <releasesleep>
    acquire(&itable.lock);
    80003a86:	0001b517          	auipc	a0,0x1b
    80003a8a:	76250513          	addi	a0,a0,1890 # 8001f1e8 <itable>
    80003a8e:	ffffd097          	auipc	ra,0xffffd
    80003a92:	17e080e7          	jalr	382(ra) # 80000c0c <acquire>
    80003a96:	b741                	j	80003a16 <iput+0x26>

0000000080003a98 <iunlockput>:
{
    80003a98:	1101                	addi	sp,sp,-32
    80003a9a:	ec06                	sd	ra,24(sp)
    80003a9c:	e822                	sd	s0,16(sp)
    80003a9e:	e426                	sd	s1,8(sp)
    80003aa0:	1000                	addi	s0,sp,32
    80003aa2:	84aa                	mv	s1,a0
  iunlock(ip);
    80003aa4:	00000097          	auipc	ra,0x0
    80003aa8:	e54080e7          	jalr	-428(ra) # 800038f8 <iunlock>
  iput(ip);
    80003aac:	8526                	mv	a0,s1
    80003aae:	00000097          	auipc	ra,0x0
    80003ab2:	f42080e7          	jalr	-190(ra) # 800039f0 <iput>
}
    80003ab6:	60e2                	ld	ra,24(sp)
    80003ab8:	6442                	ld	s0,16(sp)
    80003aba:	64a2                	ld	s1,8(sp)
    80003abc:	6105                	addi	sp,sp,32
    80003abe:	8082                	ret

0000000080003ac0 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003ac0:	1141                	addi	sp,sp,-16
    80003ac2:	e422                	sd	s0,8(sp)
    80003ac4:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ac6:	411c                	lw	a5,0(a0)
    80003ac8:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003aca:	415c                	lw	a5,4(a0)
    80003acc:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ace:	04451783          	lh	a5,68(a0)
    80003ad2:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003ad6:	04a51783          	lh	a5,74(a0)
    80003ada:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ade:	04c56783          	lwu	a5,76(a0)
    80003ae2:	e99c                	sd	a5,16(a1)
}
    80003ae4:	6422                	ld	s0,8(sp)
    80003ae6:	0141                	addi	sp,sp,16
    80003ae8:	8082                	ret

0000000080003aea <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003aea:	457c                	lw	a5,76(a0)
    80003aec:	0ed7e963          	bltu	a5,a3,80003bde <readi+0xf4>
{
    80003af0:	7159                	addi	sp,sp,-112
    80003af2:	f486                	sd	ra,104(sp)
    80003af4:	f0a2                	sd	s0,96(sp)
    80003af6:	eca6                	sd	s1,88(sp)
    80003af8:	e8ca                	sd	s2,80(sp)
    80003afa:	e4ce                	sd	s3,72(sp)
    80003afc:	e0d2                	sd	s4,64(sp)
    80003afe:	fc56                	sd	s5,56(sp)
    80003b00:	f85a                	sd	s6,48(sp)
    80003b02:	f45e                	sd	s7,40(sp)
    80003b04:	f062                	sd	s8,32(sp)
    80003b06:	ec66                	sd	s9,24(sp)
    80003b08:	e86a                	sd	s10,16(sp)
    80003b0a:	e46e                	sd	s11,8(sp)
    80003b0c:	1880                	addi	s0,sp,112
    80003b0e:	8b2a                	mv	s6,a0
    80003b10:	8bae                	mv	s7,a1
    80003b12:	8a32                	mv	s4,a2
    80003b14:	84b6                	mv	s1,a3
    80003b16:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003b18:	9f35                	addw	a4,a4,a3
    return 0;
    80003b1a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b1c:	0ad76063          	bltu	a4,a3,80003bbc <readi+0xd2>
  if(off + n > ip->size)
    80003b20:	00e7f463          	bgeu	a5,a4,80003b28 <readi+0x3e>
    n = ip->size - off;
    80003b24:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b28:	0a0a8963          	beqz	s5,80003bda <readi+0xf0>
    80003b2c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b2e:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b32:	5c7d                	li	s8,-1
    80003b34:	a82d                	j	80003b6e <readi+0x84>
    80003b36:	020d1d93          	slli	s11,s10,0x20
    80003b3a:	020ddd93          	srli	s11,s11,0x20
    80003b3e:	05890613          	addi	a2,s2,88
    80003b42:	86ee                	mv	a3,s11
    80003b44:	963a                	add	a2,a2,a4
    80003b46:	85d2                	mv	a1,s4
    80003b48:	855e                	mv	a0,s7
    80003b4a:	fffff097          	auipc	ra,0xfffff
    80003b4e:	962080e7          	jalr	-1694(ra) # 800024ac <either_copyout>
    80003b52:	05850d63          	beq	a0,s8,80003bac <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b56:	854a                	mv	a0,s2
    80003b58:	fffff097          	auipc	ra,0xfffff
    80003b5c:	5f4080e7          	jalr	1524(ra) # 8000314c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b60:	013d09bb          	addw	s3,s10,s3
    80003b64:	009d04bb          	addw	s1,s10,s1
    80003b68:	9a6e                	add	s4,s4,s11
    80003b6a:	0559f763          	bgeu	s3,s5,80003bb8 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003b6e:	00a4d59b          	srliw	a1,s1,0xa
    80003b72:	855a                	mv	a0,s6
    80003b74:	00000097          	auipc	ra,0x0
    80003b78:	8a2080e7          	jalr	-1886(ra) # 80003416 <bmap>
    80003b7c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003b80:	cd85                	beqz	a1,80003bb8 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003b82:	000b2503          	lw	a0,0(s6)
    80003b86:	fffff097          	auipc	ra,0xfffff
    80003b8a:	496080e7          	jalr	1174(ra) # 8000301c <bread>
    80003b8e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b90:	3ff4f713          	andi	a4,s1,1023
    80003b94:	40ec87bb          	subw	a5,s9,a4
    80003b98:	413a86bb          	subw	a3,s5,s3
    80003b9c:	8d3e                	mv	s10,a5
    80003b9e:	2781                	sext.w	a5,a5
    80003ba0:	0006861b          	sext.w	a2,a3
    80003ba4:	f8f679e3          	bgeu	a2,a5,80003b36 <readi+0x4c>
    80003ba8:	8d36                	mv	s10,a3
    80003baa:	b771                	j	80003b36 <readi+0x4c>
      brelse(bp);
    80003bac:	854a                	mv	a0,s2
    80003bae:	fffff097          	auipc	ra,0xfffff
    80003bb2:	59e080e7          	jalr	1438(ra) # 8000314c <brelse>
      tot = -1;
    80003bb6:	59fd                	li	s3,-1
  }
  return tot;
    80003bb8:	0009851b          	sext.w	a0,s3
}
    80003bbc:	70a6                	ld	ra,104(sp)
    80003bbe:	7406                	ld	s0,96(sp)
    80003bc0:	64e6                	ld	s1,88(sp)
    80003bc2:	6946                	ld	s2,80(sp)
    80003bc4:	69a6                	ld	s3,72(sp)
    80003bc6:	6a06                	ld	s4,64(sp)
    80003bc8:	7ae2                	ld	s5,56(sp)
    80003bca:	7b42                	ld	s6,48(sp)
    80003bcc:	7ba2                	ld	s7,40(sp)
    80003bce:	7c02                	ld	s8,32(sp)
    80003bd0:	6ce2                	ld	s9,24(sp)
    80003bd2:	6d42                	ld	s10,16(sp)
    80003bd4:	6da2                	ld	s11,8(sp)
    80003bd6:	6165                	addi	sp,sp,112
    80003bd8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bda:	89d6                	mv	s3,s5
    80003bdc:	bff1                	j	80003bb8 <readi+0xce>
    return 0;
    80003bde:	4501                	li	a0,0
}
    80003be0:	8082                	ret

0000000080003be2 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003be2:	457c                	lw	a5,76(a0)
    80003be4:	10d7e863          	bltu	a5,a3,80003cf4 <writei+0x112>
{
    80003be8:	7159                	addi	sp,sp,-112
    80003bea:	f486                	sd	ra,104(sp)
    80003bec:	f0a2                	sd	s0,96(sp)
    80003bee:	eca6                	sd	s1,88(sp)
    80003bf0:	e8ca                	sd	s2,80(sp)
    80003bf2:	e4ce                	sd	s3,72(sp)
    80003bf4:	e0d2                	sd	s4,64(sp)
    80003bf6:	fc56                	sd	s5,56(sp)
    80003bf8:	f85a                	sd	s6,48(sp)
    80003bfa:	f45e                	sd	s7,40(sp)
    80003bfc:	f062                	sd	s8,32(sp)
    80003bfe:	ec66                	sd	s9,24(sp)
    80003c00:	e86a                	sd	s10,16(sp)
    80003c02:	e46e                	sd	s11,8(sp)
    80003c04:	1880                	addi	s0,sp,112
    80003c06:	8aaa                	mv	s5,a0
    80003c08:	8bae                	mv	s7,a1
    80003c0a:	8a32                	mv	s4,a2
    80003c0c:	8936                	mv	s2,a3
    80003c0e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c10:	00e687bb          	addw	a5,a3,a4
    80003c14:	0ed7e263          	bltu	a5,a3,80003cf8 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c18:	00043737          	lui	a4,0x43
    80003c1c:	0ef76063          	bltu	a4,a5,80003cfc <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c20:	0c0b0863          	beqz	s6,80003cf0 <writei+0x10e>
    80003c24:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c26:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c2a:	5c7d                	li	s8,-1
    80003c2c:	a091                	j	80003c70 <writei+0x8e>
    80003c2e:	020d1d93          	slli	s11,s10,0x20
    80003c32:	020ddd93          	srli	s11,s11,0x20
    80003c36:	05848513          	addi	a0,s1,88
    80003c3a:	86ee                	mv	a3,s11
    80003c3c:	8652                	mv	a2,s4
    80003c3e:	85de                	mv	a1,s7
    80003c40:	953a                	add	a0,a0,a4
    80003c42:	fffff097          	auipc	ra,0xfffff
    80003c46:	8c0080e7          	jalr	-1856(ra) # 80002502 <either_copyin>
    80003c4a:	07850263          	beq	a0,s8,80003cae <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c4e:	8526                	mv	a0,s1
    80003c50:	00000097          	auipc	ra,0x0
    80003c54:	780080e7          	jalr	1920(ra) # 800043d0 <log_write>
    brelse(bp);
    80003c58:	8526                	mv	a0,s1
    80003c5a:	fffff097          	auipc	ra,0xfffff
    80003c5e:	4f2080e7          	jalr	1266(ra) # 8000314c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c62:	013d09bb          	addw	s3,s10,s3
    80003c66:	012d093b          	addw	s2,s10,s2
    80003c6a:	9a6e                	add	s4,s4,s11
    80003c6c:	0569f663          	bgeu	s3,s6,80003cb8 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003c70:	00a9559b          	srliw	a1,s2,0xa
    80003c74:	8556                	mv	a0,s5
    80003c76:	fffff097          	auipc	ra,0xfffff
    80003c7a:	7a0080e7          	jalr	1952(ra) # 80003416 <bmap>
    80003c7e:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003c82:	c99d                	beqz	a1,80003cb8 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003c84:	000aa503          	lw	a0,0(s5)
    80003c88:	fffff097          	auipc	ra,0xfffff
    80003c8c:	394080e7          	jalr	916(ra) # 8000301c <bread>
    80003c90:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c92:	3ff97713          	andi	a4,s2,1023
    80003c96:	40ec87bb          	subw	a5,s9,a4
    80003c9a:	413b06bb          	subw	a3,s6,s3
    80003c9e:	8d3e                	mv	s10,a5
    80003ca0:	2781                	sext.w	a5,a5
    80003ca2:	0006861b          	sext.w	a2,a3
    80003ca6:	f8f674e3          	bgeu	a2,a5,80003c2e <writei+0x4c>
    80003caa:	8d36                	mv	s10,a3
    80003cac:	b749                	j	80003c2e <writei+0x4c>
      brelse(bp);
    80003cae:	8526                	mv	a0,s1
    80003cb0:	fffff097          	auipc	ra,0xfffff
    80003cb4:	49c080e7          	jalr	1180(ra) # 8000314c <brelse>
  }

  if(off > ip->size)
    80003cb8:	04caa783          	lw	a5,76(s5)
    80003cbc:	0127f463          	bgeu	a5,s2,80003cc4 <writei+0xe2>
    ip->size = off;
    80003cc0:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003cc4:	8556                	mv	a0,s5
    80003cc6:	00000097          	auipc	ra,0x0
    80003cca:	aa6080e7          	jalr	-1370(ra) # 8000376c <iupdate>

  return tot;
    80003cce:	0009851b          	sext.w	a0,s3
}
    80003cd2:	70a6                	ld	ra,104(sp)
    80003cd4:	7406                	ld	s0,96(sp)
    80003cd6:	64e6                	ld	s1,88(sp)
    80003cd8:	6946                	ld	s2,80(sp)
    80003cda:	69a6                	ld	s3,72(sp)
    80003cdc:	6a06                	ld	s4,64(sp)
    80003cde:	7ae2                	ld	s5,56(sp)
    80003ce0:	7b42                	ld	s6,48(sp)
    80003ce2:	7ba2                	ld	s7,40(sp)
    80003ce4:	7c02                	ld	s8,32(sp)
    80003ce6:	6ce2                	ld	s9,24(sp)
    80003ce8:	6d42                	ld	s10,16(sp)
    80003cea:	6da2                	ld	s11,8(sp)
    80003cec:	6165                	addi	sp,sp,112
    80003cee:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cf0:	89da                	mv	s3,s6
    80003cf2:	bfc9                	j	80003cc4 <writei+0xe2>
    return -1;
    80003cf4:	557d                	li	a0,-1
}
    80003cf6:	8082                	ret
    return -1;
    80003cf8:	557d                	li	a0,-1
    80003cfa:	bfe1                	j	80003cd2 <writei+0xf0>
    return -1;
    80003cfc:	557d                	li	a0,-1
    80003cfe:	bfd1                	j	80003cd2 <writei+0xf0>

0000000080003d00 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d00:	1141                	addi	sp,sp,-16
    80003d02:	e406                	sd	ra,8(sp)
    80003d04:	e022                	sd	s0,0(sp)
    80003d06:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d08:	4639                	li	a2,14
    80003d0a:	ffffd097          	auipc	ra,0xffffd
    80003d0e:	0d6080e7          	jalr	214(ra) # 80000de0 <strncmp>
}
    80003d12:	60a2                	ld	ra,8(sp)
    80003d14:	6402                	ld	s0,0(sp)
    80003d16:	0141                	addi	sp,sp,16
    80003d18:	8082                	ret

0000000080003d1a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d1a:	7139                	addi	sp,sp,-64
    80003d1c:	fc06                	sd	ra,56(sp)
    80003d1e:	f822                	sd	s0,48(sp)
    80003d20:	f426                	sd	s1,40(sp)
    80003d22:	f04a                	sd	s2,32(sp)
    80003d24:	ec4e                	sd	s3,24(sp)
    80003d26:	e852                	sd	s4,16(sp)
    80003d28:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d2a:	04451703          	lh	a4,68(a0)
    80003d2e:	4785                	li	a5,1
    80003d30:	00f71a63          	bne	a4,a5,80003d44 <dirlookup+0x2a>
    80003d34:	892a                	mv	s2,a0
    80003d36:	89ae                	mv	s3,a1
    80003d38:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d3a:	457c                	lw	a5,76(a0)
    80003d3c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d3e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d40:	e79d                	bnez	a5,80003d6e <dirlookup+0x54>
    80003d42:	a8a5                	j	80003dba <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d44:	00005517          	auipc	a0,0x5
    80003d48:	91450513          	addi	a0,a0,-1772 # 80008658 <syscalls+0x1b8>
    80003d4c:	ffffc097          	auipc	ra,0xffffc
    80003d50:	7f8080e7          	jalr	2040(ra) # 80000544 <panic>
      panic("dirlookup read");
    80003d54:	00005517          	auipc	a0,0x5
    80003d58:	91c50513          	addi	a0,a0,-1764 # 80008670 <syscalls+0x1d0>
    80003d5c:	ffffc097          	auipc	ra,0xffffc
    80003d60:	7e8080e7          	jalr	2024(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d64:	24c1                	addiw	s1,s1,16
    80003d66:	04c92783          	lw	a5,76(s2)
    80003d6a:	04f4f763          	bgeu	s1,a5,80003db8 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d6e:	4741                	li	a4,16
    80003d70:	86a6                	mv	a3,s1
    80003d72:	fc040613          	addi	a2,s0,-64
    80003d76:	4581                	li	a1,0
    80003d78:	854a                	mv	a0,s2
    80003d7a:	00000097          	auipc	ra,0x0
    80003d7e:	d70080e7          	jalr	-656(ra) # 80003aea <readi>
    80003d82:	47c1                	li	a5,16
    80003d84:	fcf518e3          	bne	a0,a5,80003d54 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d88:	fc045783          	lhu	a5,-64(s0)
    80003d8c:	dfe1                	beqz	a5,80003d64 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d8e:	fc240593          	addi	a1,s0,-62
    80003d92:	854e                	mv	a0,s3
    80003d94:	00000097          	auipc	ra,0x0
    80003d98:	f6c080e7          	jalr	-148(ra) # 80003d00 <namecmp>
    80003d9c:	f561                	bnez	a0,80003d64 <dirlookup+0x4a>
      if(poff)
    80003d9e:	000a0463          	beqz	s4,80003da6 <dirlookup+0x8c>
        *poff = off;
    80003da2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003da6:	fc045583          	lhu	a1,-64(s0)
    80003daa:	00092503          	lw	a0,0(s2)
    80003dae:	fffff097          	auipc	ra,0xfffff
    80003db2:	750080e7          	jalr	1872(ra) # 800034fe <iget>
    80003db6:	a011                	j	80003dba <dirlookup+0xa0>
  return 0;
    80003db8:	4501                	li	a0,0
}
    80003dba:	70e2                	ld	ra,56(sp)
    80003dbc:	7442                	ld	s0,48(sp)
    80003dbe:	74a2                	ld	s1,40(sp)
    80003dc0:	7902                	ld	s2,32(sp)
    80003dc2:	69e2                	ld	s3,24(sp)
    80003dc4:	6a42                	ld	s4,16(sp)
    80003dc6:	6121                	addi	sp,sp,64
    80003dc8:	8082                	ret

0000000080003dca <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003dca:	711d                	addi	sp,sp,-96
    80003dcc:	ec86                	sd	ra,88(sp)
    80003dce:	e8a2                	sd	s0,80(sp)
    80003dd0:	e4a6                	sd	s1,72(sp)
    80003dd2:	e0ca                	sd	s2,64(sp)
    80003dd4:	fc4e                	sd	s3,56(sp)
    80003dd6:	f852                	sd	s4,48(sp)
    80003dd8:	f456                	sd	s5,40(sp)
    80003dda:	f05a                	sd	s6,32(sp)
    80003ddc:	ec5e                	sd	s7,24(sp)
    80003dde:	e862                	sd	s8,16(sp)
    80003de0:	e466                	sd	s9,8(sp)
    80003de2:	1080                	addi	s0,sp,96
    80003de4:	84aa                	mv	s1,a0
    80003de6:	8b2e                	mv	s6,a1
    80003de8:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003dea:	00054703          	lbu	a4,0(a0)
    80003dee:	02f00793          	li	a5,47
    80003df2:	02f70363          	beq	a4,a5,80003e18 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003df6:	ffffe097          	auipc	ra,0xffffe
    80003dfa:	bf2080e7          	jalr	-1038(ra) # 800019e8 <myproc>
    80003dfe:	15053503          	ld	a0,336(a0)
    80003e02:	00000097          	auipc	ra,0x0
    80003e06:	9f6080e7          	jalr	-1546(ra) # 800037f8 <idup>
    80003e0a:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e0c:	02f00913          	li	s2,47
  len = path - s;
    80003e10:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003e12:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e14:	4c05                	li	s8,1
    80003e16:	a865                	j	80003ece <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e18:	4585                	li	a1,1
    80003e1a:	4505                	li	a0,1
    80003e1c:	fffff097          	auipc	ra,0xfffff
    80003e20:	6e2080e7          	jalr	1762(ra) # 800034fe <iget>
    80003e24:	89aa                	mv	s3,a0
    80003e26:	b7dd                	j	80003e0c <namex+0x42>
      iunlockput(ip);
    80003e28:	854e                	mv	a0,s3
    80003e2a:	00000097          	auipc	ra,0x0
    80003e2e:	c6e080e7          	jalr	-914(ra) # 80003a98 <iunlockput>
      return 0;
    80003e32:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e34:	854e                	mv	a0,s3
    80003e36:	60e6                	ld	ra,88(sp)
    80003e38:	6446                	ld	s0,80(sp)
    80003e3a:	64a6                	ld	s1,72(sp)
    80003e3c:	6906                	ld	s2,64(sp)
    80003e3e:	79e2                	ld	s3,56(sp)
    80003e40:	7a42                	ld	s4,48(sp)
    80003e42:	7aa2                	ld	s5,40(sp)
    80003e44:	7b02                	ld	s6,32(sp)
    80003e46:	6be2                	ld	s7,24(sp)
    80003e48:	6c42                	ld	s8,16(sp)
    80003e4a:	6ca2                	ld	s9,8(sp)
    80003e4c:	6125                	addi	sp,sp,96
    80003e4e:	8082                	ret
      iunlock(ip);
    80003e50:	854e                	mv	a0,s3
    80003e52:	00000097          	auipc	ra,0x0
    80003e56:	aa6080e7          	jalr	-1370(ra) # 800038f8 <iunlock>
      return ip;
    80003e5a:	bfe9                	j	80003e34 <namex+0x6a>
      iunlockput(ip);
    80003e5c:	854e                	mv	a0,s3
    80003e5e:	00000097          	auipc	ra,0x0
    80003e62:	c3a080e7          	jalr	-966(ra) # 80003a98 <iunlockput>
      return 0;
    80003e66:	89d2                	mv	s3,s4
    80003e68:	b7f1                	j	80003e34 <namex+0x6a>
  len = path - s;
    80003e6a:	40b48633          	sub	a2,s1,a1
    80003e6e:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003e72:	094cd463          	bge	s9,s4,80003efa <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e76:	4639                	li	a2,14
    80003e78:	8556                	mv	a0,s5
    80003e7a:	ffffd097          	auipc	ra,0xffffd
    80003e7e:	eee080e7          	jalr	-274(ra) # 80000d68 <memmove>
  while(*path == '/')
    80003e82:	0004c783          	lbu	a5,0(s1)
    80003e86:	01279763          	bne	a5,s2,80003e94 <namex+0xca>
    path++;
    80003e8a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e8c:	0004c783          	lbu	a5,0(s1)
    80003e90:	ff278de3          	beq	a5,s2,80003e8a <namex+0xc0>
    ilock(ip);
    80003e94:	854e                	mv	a0,s3
    80003e96:	00000097          	auipc	ra,0x0
    80003e9a:	9a0080e7          	jalr	-1632(ra) # 80003836 <ilock>
    if(ip->type != T_DIR){
    80003e9e:	04499783          	lh	a5,68(s3)
    80003ea2:	f98793e3          	bne	a5,s8,80003e28 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003ea6:	000b0563          	beqz	s6,80003eb0 <namex+0xe6>
    80003eaa:	0004c783          	lbu	a5,0(s1)
    80003eae:	d3cd                	beqz	a5,80003e50 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003eb0:	865e                	mv	a2,s7
    80003eb2:	85d6                	mv	a1,s5
    80003eb4:	854e                	mv	a0,s3
    80003eb6:	00000097          	auipc	ra,0x0
    80003eba:	e64080e7          	jalr	-412(ra) # 80003d1a <dirlookup>
    80003ebe:	8a2a                	mv	s4,a0
    80003ec0:	dd51                	beqz	a0,80003e5c <namex+0x92>
    iunlockput(ip);
    80003ec2:	854e                	mv	a0,s3
    80003ec4:	00000097          	auipc	ra,0x0
    80003ec8:	bd4080e7          	jalr	-1068(ra) # 80003a98 <iunlockput>
    ip = next;
    80003ecc:	89d2                	mv	s3,s4
  while(*path == '/')
    80003ece:	0004c783          	lbu	a5,0(s1)
    80003ed2:	05279763          	bne	a5,s2,80003f20 <namex+0x156>
    path++;
    80003ed6:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ed8:	0004c783          	lbu	a5,0(s1)
    80003edc:	ff278de3          	beq	a5,s2,80003ed6 <namex+0x10c>
  if(*path == 0)
    80003ee0:	c79d                	beqz	a5,80003f0e <namex+0x144>
    path++;
    80003ee2:	85a6                	mv	a1,s1
  len = path - s;
    80003ee4:	8a5e                	mv	s4,s7
    80003ee6:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003ee8:	01278963          	beq	a5,s2,80003efa <namex+0x130>
    80003eec:	dfbd                	beqz	a5,80003e6a <namex+0xa0>
    path++;
    80003eee:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003ef0:	0004c783          	lbu	a5,0(s1)
    80003ef4:	ff279ce3          	bne	a5,s2,80003eec <namex+0x122>
    80003ef8:	bf8d                	j	80003e6a <namex+0xa0>
    memmove(name, s, len);
    80003efa:	2601                	sext.w	a2,a2
    80003efc:	8556                	mv	a0,s5
    80003efe:	ffffd097          	auipc	ra,0xffffd
    80003f02:	e6a080e7          	jalr	-406(ra) # 80000d68 <memmove>
    name[len] = 0;
    80003f06:	9a56                	add	s4,s4,s5
    80003f08:	000a0023          	sb	zero,0(s4)
    80003f0c:	bf9d                	j	80003e82 <namex+0xb8>
  if(nameiparent){
    80003f0e:	f20b03e3          	beqz	s6,80003e34 <namex+0x6a>
    iput(ip);
    80003f12:	854e                	mv	a0,s3
    80003f14:	00000097          	auipc	ra,0x0
    80003f18:	adc080e7          	jalr	-1316(ra) # 800039f0 <iput>
    return 0;
    80003f1c:	4981                	li	s3,0
    80003f1e:	bf19                	j	80003e34 <namex+0x6a>
  if(*path == 0)
    80003f20:	d7fd                	beqz	a5,80003f0e <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f22:	0004c783          	lbu	a5,0(s1)
    80003f26:	85a6                	mv	a1,s1
    80003f28:	b7d1                	j	80003eec <namex+0x122>

0000000080003f2a <dirlink>:
{
    80003f2a:	7139                	addi	sp,sp,-64
    80003f2c:	fc06                	sd	ra,56(sp)
    80003f2e:	f822                	sd	s0,48(sp)
    80003f30:	f426                	sd	s1,40(sp)
    80003f32:	f04a                	sd	s2,32(sp)
    80003f34:	ec4e                	sd	s3,24(sp)
    80003f36:	e852                	sd	s4,16(sp)
    80003f38:	0080                	addi	s0,sp,64
    80003f3a:	892a                	mv	s2,a0
    80003f3c:	8a2e                	mv	s4,a1
    80003f3e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f40:	4601                	li	a2,0
    80003f42:	00000097          	auipc	ra,0x0
    80003f46:	dd8080e7          	jalr	-552(ra) # 80003d1a <dirlookup>
    80003f4a:	e93d                	bnez	a0,80003fc0 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f4c:	04c92483          	lw	s1,76(s2)
    80003f50:	c49d                	beqz	s1,80003f7e <dirlink+0x54>
    80003f52:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f54:	4741                	li	a4,16
    80003f56:	86a6                	mv	a3,s1
    80003f58:	fc040613          	addi	a2,s0,-64
    80003f5c:	4581                	li	a1,0
    80003f5e:	854a                	mv	a0,s2
    80003f60:	00000097          	auipc	ra,0x0
    80003f64:	b8a080e7          	jalr	-1142(ra) # 80003aea <readi>
    80003f68:	47c1                	li	a5,16
    80003f6a:	06f51163          	bne	a0,a5,80003fcc <dirlink+0xa2>
    if(de.inum == 0)
    80003f6e:	fc045783          	lhu	a5,-64(s0)
    80003f72:	c791                	beqz	a5,80003f7e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f74:	24c1                	addiw	s1,s1,16
    80003f76:	04c92783          	lw	a5,76(s2)
    80003f7a:	fcf4ede3          	bltu	s1,a5,80003f54 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f7e:	4639                	li	a2,14
    80003f80:	85d2                	mv	a1,s4
    80003f82:	fc240513          	addi	a0,s0,-62
    80003f86:	ffffd097          	auipc	ra,0xffffd
    80003f8a:	e96080e7          	jalr	-362(ra) # 80000e1c <strncpy>
  de.inum = inum;
    80003f8e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f92:	4741                	li	a4,16
    80003f94:	86a6                	mv	a3,s1
    80003f96:	fc040613          	addi	a2,s0,-64
    80003f9a:	4581                	li	a1,0
    80003f9c:	854a                	mv	a0,s2
    80003f9e:	00000097          	auipc	ra,0x0
    80003fa2:	c44080e7          	jalr	-956(ra) # 80003be2 <writei>
    80003fa6:	1541                	addi	a0,a0,-16
    80003fa8:	00a03533          	snez	a0,a0
    80003fac:	40a00533          	neg	a0,a0
}
    80003fb0:	70e2                	ld	ra,56(sp)
    80003fb2:	7442                	ld	s0,48(sp)
    80003fb4:	74a2                	ld	s1,40(sp)
    80003fb6:	7902                	ld	s2,32(sp)
    80003fb8:	69e2                	ld	s3,24(sp)
    80003fba:	6a42                	ld	s4,16(sp)
    80003fbc:	6121                	addi	sp,sp,64
    80003fbe:	8082                	ret
    iput(ip);
    80003fc0:	00000097          	auipc	ra,0x0
    80003fc4:	a30080e7          	jalr	-1488(ra) # 800039f0 <iput>
    return -1;
    80003fc8:	557d                	li	a0,-1
    80003fca:	b7dd                	j	80003fb0 <dirlink+0x86>
      panic("dirlink read");
    80003fcc:	00004517          	auipc	a0,0x4
    80003fd0:	6b450513          	addi	a0,a0,1716 # 80008680 <syscalls+0x1e0>
    80003fd4:	ffffc097          	auipc	ra,0xffffc
    80003fd8:	570080e7          	jalr	1392(ra) # 80000544 <panic>

0000000080003fdc <namei>:

struct inode*
namei(char *path)
{
    80003fdc:	1101                	addi	sp,sp,-32
    80003fde:	ec06                	sd	ra,24(sp)
    80003fe0:	e822                	sd	s0,16(sp)
    80003fe2:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003fe4:	fe040613          	addi	a2,s0,-32
    80003fe8:	4581                	li	a1,0
    80003fea:	00000097          	auipc	ra,0x0
    80003fee:	de0080e7          	jalr	-544(ra) # 80003dca <namex>
}
    80003ff2:	60e2                	ld	ra,24(sp)
    80003ff4:	6442                	ld	s0,16(sp)
    80003ff6:	6105                	addi	sp,sp,32
    80003ff8:	8082                	ret

0000000080003ffa <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003ffa:	1141                	addi	sp,sp,-16
    80003ffc:	e406                	sd	ra,8(sp)
    80003ffe:	e022                	sd	s0,0(sp)
    80004000:	0800                	addi	s0,sp,16
    80004002:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004004:	4585                	li	a1,1
    80004006:	00000097          	auipc	ra,0x0
    8000400a:	dc4080e7          	jalr	-572(ra) # 80003dca <namex>
}
    8000400e:	60a2                	ld	ra,8(sp)
    80004010:	6402                	ld	s0,0(sp)
    80004012:	0141                	addi	sp,sp,16
    80004014:	8082                	ret

0000000080004016 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004016:	1101                	addi	sp,sp,-32
    80004018:	ec06                	sd	ra,24(sp)
    8000401a:	e822                	sd	s0,16(sp)
    8000401c:	e426                	sd	s1,8(sp)
    8000401e:	e04a                	sd	s2,0(sp)
    80004020:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004022:	0001d917          	auipc	s2,0x1d
    80004026:	c6e90913          	addi	s2,s2,-914 # 80020c90 <log>
    8000402a:	01892583          	lw	a1,24(s2)
    8000402e:	02892503          	lw	a0,40(s2)
    80004032:	fffff097          	auipc	ra,0xfffff
    80004036:	fea080e7          	jalr	-22(ra) # 8000301c <bread>
    8000403a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000403c:	02c92683          	lw	a3,44(s2)
    80004040:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004042:	02d05763          	blez	a3,80004070 <write_head+0x5a>
    80004046:	0001d797          	auipc	a5,0x1d
    8000404a:	c7a78793          	addi	a5,a5,-902 # 80020cc0 <log+0x30>
    8000404e:	05c50713          	addi	a4,a0,92
    80004052:	36fd                	addiw	a3,a3,-1
    80004054:	1682                	slli	a3,a3,0x20
    80004056:	9281                	srli	a3,a3,0x20
    80004058:	068a                	slli	a3,a3,0x2
    8000405a:	0001d617          	auipc	a2,0x1d
    8000405e:	c6a60613          	addi	a2,a2,-918 # 80020cc4 <log+0x34>
    80004062:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004064:	4390                	lw	a2,0(a5)
    80004066:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004068:	0791                	addi	a5,a5,4
    8000406a:	0711                	addi	a4,a4,4
    8000406c:	fed79ce3          	bne	a5,a3,80004064 <write_head+0x4e>
  }
  bwrite(buf);
    80004070:	8526                	mv	a0,s1
    80004072:	fffff097          	auipc	ra,0xfffff
    80004076:	09c080e7          	jalr	156(ra) # 8000310e <bwrite>
  brelse(buf);
    8000407a:	8526                	mv	a0,s1
    8000407c:	fffff097          	auipc	ra,0xfffff
    80004080:	0d0080e7          	jalr	208(ra) # 8000314c <brelse>
}
    80004084:	60e2                	ld	ra,24(sp)
    80004086:	6442                	ld	s0,16(sp)
    80004088:	64a2                	ld	s1,8(sp)
    8000408a:	6902                	ld	s2,0(sp)
    8000408c:	6105                	addi	sp,sp,32
    8000408e:	8082                	ret

0000000080004090 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004090:	0001d797          	auipc	a5,0x1d
    80004094:	c2c7a783          	lw	a5,-980(a5) # 80020cbc <log+0x2c>
    80004098:	0af05d63          	blez	a5,80004152 <install_trans+0xc2>
{
    8000409c:	7139                	addi	sp,sp,-64
    8000409e:	fc06                	sd	ra,56(sp)
    800040a0:	f822                	sd	s0,48(sp)
    800040a2:	f426                	sd	s1,40(sp)
    800040a4:	f04a                	sd	s2,32(sp)
    800040a6:	ec4e                	sd	s3,24(sp)
    800040a8:	e852                	sd	s4,16(sp)
    800040aa:	e456                	sd	s5,8(sp)
    800040ac:	e05a                	sd	s6,0(sp)
    800040ae:	0080                	addi	s0,sp,64
    800040b0:	8b2a                	mv	s6,a0
    800040b2:	0001da97          	auipc	s5,0x1d
    800040b6:	c0ea8a93          	addi	s5,s5,-1010 # 80020cc0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040ba:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040bc:	0001d997          	auipc	s3,0x1d
    800040c0:	bd498993          	addi	s3,s3,-1068 # 80020c90 <log>
    800040c4:	a035                	j	800040f0 <install_trans+0x60>
      bunpin(dbuf);
    800040c6:	8526                	mv	a0,s1
    800040c8:	fffff097          	auipc	ra,0xfffff
    800040cc:	15e080e7          	jalr	350(ra) # 80003226 <bunpin>
    brelse(lbuf);
    800040d0:	854a                	mv	a0,s2
    800040d2:	fffff097          	auipc	ra,0xfffff
    800040d6:	07a080e7          	jalr	122(ra) # 8000314c <brelse>
    brelse(dbuf);
    800040da:	8526                	mv	a0,s1
    800040dc:	fffff097          	auipc	ra,0xfffff
    800040e0:	070080e7          	jalr	112(ra) # 8000314c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040e4:	2a05                	addiw	s4,s4,1
    800040e6:	0a91                	addi	s5,s5,4
    800040e8:	02c9a783          	lw	a5,44(s3)
    800040ec:	04fa5963          	bge	s4,a5,8000413e <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040f0:	0189a583          	lw	a1,24(s3)
    800040f4:	014585bb          	addw	a1,a1,s4
    800040f8:	2585                	addiw	a1,a1,1
    800040fa:	0289a503          	lw	a0,40(s3)
    800040fe:	fffff097          	auipc	ra,0xfffff
    80004102:	f1e080e7          	jalr	-226(ra) # 8000301c <bread>
    80004106:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004108:	000aa583          	lw	a1,0(s5)
    8000410c:	0289a503          	lw	a0,40(s3)
    80004110:	fffff097          	auipc	ra,0xfffff
    80004114:	f0c080e7          	jalr	-244(ra) # 8000301c <bread>
    80004118:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000411a:	40000613          	li	a2,1024
    8000411e:	05890593          	addi	a1,s2,88
    80004122:	05850513          	addi	a0,a0,88
    80004126:	ffffd097          	auipc	ra,0xffffd
    8000412a:	c42080e7          	jalr	-958(ra) # 80000d68 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000412e:	8526                	mv	a0,s1
    80004130:	fffff097          	auipc	ra,0xfffff
    80004134:	fde080e7          	jalr	-34(ra) # 8000310e <bwrite>
    if(recovering == 0)
    80004138:	f80b1ce3          	bnez	s6,800040d0 <install_trans+0x40>
    8000413c:	b769                	j	800040c6 <install_trans+0x36>
}
    8000413e:	70e2                	ld	ra,56(sp)
    80004140:	7442                	ld	s0,48(sp)
    80004142:	74a2                	ld	s1,40(sp)
    80004144:	7902                	ld	s2,32(sp)
    80004146:	69e2                	ld	s3,24(sp)
    80004148:	6a42                	ld	s4,16(sp)
    8000414a:	6aa2                	ld	s5,8(sp)
    8000414c:	6b02                	ld	s6,0(sp)
    8000414e:	6121                	addi	sp,sp,64
    80004150:	8082                	ret
    80004152:	8082                	ret

0000000080004154 <initlog>:
{
    80004154:	7179                	addi	sp,sp,-48
    80004156:	f406                	sd	ra,40(sp)
    80004158:	f022                	sd	s0,32(sp)
    8000415a:	ec26                	sd	s1,24(sp)
    8000415c:	e84a                	sd	s2,16(sp)
    8000415e:	e44e                	sd	s3,8(sp)
    80004160:	1800                	addi	s0,sp,48
    80004162:	892a                	mv	s2,a0
    80004164:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004166:	0001d497          	auipc	s1,0x1d
    8000416a:	b2a48493          	addi	s1,s1,-1238 # 80020c90 <log>
    8000416e:	00004597          	auipc	a1,0x4
    80004172:	52258593          	addi	a1,a1,1314 # 80008690 <syscalls+0x1f0>
    80004176:	8526                	mv	a0,s1
    80004178:	ffffd097          	auipc	ra,0xffffd
    8000417c:	a04080e7          	jalr	-1532(ra) # 80000b7c <initlock>
  log.start = sb->logstart;
    80004180:	0149a583          	lw	a1,20(s3)
    80004184:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004186:	0109a783          	lw	a5,16(s3)
    8000418a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000418c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004190:	854a                	mv	a0,s2
    80004192:	fffff097          	auipc	ra,0xfffff
    80004196:	e8a080e7          	jalr	-374(ra) # 8000301c <bread>
  log.lh.n = lh->n;
    8000419a:	4d3c                	lw	a5,88(a0)
    8000419c:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000419e:	02f05563          	blez	a5,800041c8 <initlog+0x74>
    800041a2:	05c50713          	addi	a4,a0,92
    800041a6:	0001d697          	auipc	a3,0x1d
    800041aa:	b1a68693          	addi	a3,a3,-1254 # 80020cc0 <log+0x30>
    800041ae:	37fd                	addiw	a5,a5,-1
    800041b0:	1782                	slli	a5,a5,0x20
    800041b2:	9381                	srli	a5,a5,0x20
    800041b4:	078a                	slli	a5,a5,0x2
    800041b6:	06050613          	addi	a2,a0,96
    800041ba:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800041bc:	4310                	lw	a2,0(a4)
    800041be:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800041c0:	0711                	addi	a4,a4,4
    800041c2:	0691                	addi	a3,a3,4
    800041c4:	fef71ce3          	bne	a4,a5,800041bc <initlog+0x68>
  brelse(buf);
    800041c8:	fffff097          	auipc	ra,0xfffff
    800041cc:	f84080e7          	jalr	-124(ra) # 8000314c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800041d0:	4505                	li	a0,1
    800041d2:	00000097          	auipc	ra,0x0
    800041d6:	ebe080e7          	jalr	-322(ra) # 80004090 <install_trans>
  log.lh.n = 0;
    800041da:	0001d797          	auipc	a5,0x1d
    800041de:	ae07a123          	sw	zero,-1310(a5) # 80020cbc <log+0x2c>
  write_head(); // clear the log
    800041e2:	00000097          	auipc	ra,0x0
    800041e6:	e34080e7          	jalr	-460(ra) # 80004016 <write_head>
}
    800041ea:	70a2                	ld	ra,40(sp)
    800041ec:	7402                	ld	s0,32(sp)
    800041ee:	64e2                	ld	s1,24(sp)
    800041f0:	6942                	ld	s2,16(sp)
    800041f2:	69a2                	ld	s3,8(sp)
    800041f4:	6145                	addi	sp,sp,48
    800041f6:	8082                	ret

00000000800041f8 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800041f8:	1101                	addi	sp,sp,-32
    800041fa:	ec06                	sd	ra,24(sp)
    800041fc:	e822                	sd	s0,16(sp)
    800041fe:	e426                	sd	s1,8(sp)
    80004200:	e04a                	sd	s2,0(sp)
    80004202:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004204:	0001d517          	auipc	a0,0x1d
    80004208:	a8c50513          	addi	a0,a0,-1396 # 80020c90 <log>
    8000420c:	ffffd097          	auipc	ra,0xffffd
    80004210:	a00080e7          	jalr	-1536(ra) # 80000c0c <acquire>
  while(1){
    if(log.committing){
    80004214:	0001d497          	auipc	s1,0x1d
    80004218:	a7c48493          	addi	s1,s1,-1412 # 80020c90 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000421c:	4979                	li	s2,30
    8000421e:	a039                	j	8000422c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004220:	85a6                	mv	a1,s1
    80004222:	8526                	mv	a0,s1
    80004224:	ffffe097          	auipc	ra,0xffffe
    80004228:	e80080e7          	jalr	-384(ra) # 800020a4 <sleep>
    if(log.committing){
    8000422c:	50dc                	lw	a5,36(s1)
    8000422e:	fbed                	bnez	a5,80004220 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004230:	509c                	lw	a5,32(s1)
    80004232:	0017871b          	addiw	a4,a5,1
    80004236:	0007069b          	sext.w	a3,a4
    8000423a:	0027179b          	slliw	a5,a4,0x2
    8000423e:	9fb9                	addw	a5,a5,a4
    80004240:	0017979b          	slliw	a5,a5,0x1
    80004244:	54d8                	lw	a4,44(s1)
    80004246:	9fb9                	addw	a5,a5,a4
    80004248:	00f95963          	bge	s2,a5,8000425a <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000424c:	85a6                	mv	a1,s1
    8000424e:	8526                	mv	a0,s1
    80004250:	ffffe097          	auipc	ra,0xffffe
    80004254:	e54080e7          	jalr	-428(ra) # 800020a4 <sleep>
    80004258:	bfd1                	j	8000422c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000425a:	0001d517          	auipc	a0,0x1d
    8000425e:	a3650513          	addi	a0,a0,-1482 # 80020c90 <log>
    80004262:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004264:	ffffd097          	auipc	ra,0xffffd
    80004268:	a5c080e7          	jalr	-1444(ra) # 80000cc0 <release>
      break;
    }
  }
}
    8000426c:	60e2                	ld	ra,24(sp)
    8000426e:	6442                	ld	s0,16(sp)
    80004270:	64a2                	ld	s1,8(sp)
    80004272:	6902                	ld	s2,0(sp)
    80004274:	6105                	addi	sp,sp,32
    80004276:	8082                	ret

0000000080004278 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004278:	7139                	addi	sp,sp,-64
    8000427a:	fc06                	sd	ra,56(sp)
    8000427c:	f822                	sd	s0,48(sp)
    8000427e:	f426                	sd	s1,40(sp)
    80004280:	f04a                	sd	s2,32(sp)
    80004282:	ec4e                	sd	s3,24(sp)
    80004284:	e852                	sd	s4,16(sp)
    80004286:	e456                	sd	s5,8(sp)
    80004288:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000428a:	0001d497          	auipc	s1,0x1d
    8000428e:	a0648493          	addi	s1,s1,-1530 # 80020c90 <log>
    80004292:	8526                	mv	a0,s1
    80004294:	ffffd097          	auipc	ra,0xffffd
    80004298:	978080e7          	jalr	-1672(ra) # 80000c0c <acquire>
  log.outstanding -= 1;
    8000429c:	509c                	lw	a5,32(s1)
    8000429e:	37fd                	addiw	a5,a5,-1
    800042a0:	0007891b          	sext.w	s2,a5
    800042a4:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800042a6:	50dc                	lw	a5,36(s1)
    800042a8:	efb9                	bnez	a5,80004306 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800042aa:	06091663          	bnez	s2,80004316 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800042ae:	0001d497          	auipc	s1,0x1d
    800042b2:	9e248493          	addi	s1,s1,-1566 # 80020c90 <log>
    800042b6:	4785                	li	a5,1
    800042b8:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800042ba:	8526                	mv	a0,s1
    800042bc:	ffffd097          	auipc	ra,0xffffd
    800042c0:	a04080e7          	jalr	-1532(ra) # 80000cc0 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800042c4:	54dc                	lw	a5,44(s1)
    800042c6:	06f04763          	bgtz	a5,80004334 <end_op+0xbc>
    acquire(&log.lock);
    800042ca:	0001d497          	auipc	s1,0x1d
    800042ce:	9c648493          	addi	s1,s1,-1594 # 80020c90 <log>
    800042d2:	8526                	mv	a0,s1
    800042d4:	ffffd097          	auipc	ra,0xffffd
    800042d8:	938080e7          	jalr	-1736(ra) # 80000c0c <acquire>
    log.committing = 0;
    800042dc:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800042e0:	8526                	mv	a0,s1
    800042e2:	ffffe097          	auipc	ra,0xffffe
    800042e6:	e26080e7          	jalr	-474(ra) # 80002108 <wakeup>
    release(&log.lock);
    800042ea:	8526                	mv	a0,s1
    800042ec:	ffffd097          	auipc	ra,0xffffd
    800042f0:	9d4080e7          	jalr	-1580(ra) # 80000cc0 <release>
}
    800042f4:	70e2                	ld	ra,56(sp)
    800042f6:	7442                	ld	s0,48(sp)
    800042f8:	74a2                	ld	s1,40(sp)
    800042fa:	7902                	ld	s2,32(sp)
    800042fc:	69e2                	ld	s3,24(sp)
    800042fe:	6a42                	ld	s4,16(sp)
    80004300:	6aa2                	ld	s5,8(sp)
    80004302:	6121                	addi	sp,sp,64
    80004304:	8082                	ret
    panic("log.committing");
    80004306:	00004517          	auipc	a0,0x4
    8000430a:	39250513          	addi	a0,a0,914 # 80008698 <syscalls+0x1f8>
    8000430e:	ffffc097          	auipc	ra,0xffffc
    80004312:	236080e7          	jalr	566(ra) # 80000544 <panic>
    wakeup(&log);
    80004316:	0001d497          	auipc	s1,0x1d
    8000431a:	97a48493          	addi	s1,s1,-1670 # 80020c90 <log>
    8000431e:	8526                	mv	a0,s1
    80004320:	ffffe097          	auipc	ra,0xffffe
    80004324:	de8080e7          	jalr	-536(ra) # 80002108 <wakeup>
  release(&log.lock);
    80004328:	8526                	mv	a0,s1
    8000432a:	ffffd097          	auipc	ra,0xffffd
    8000432e:	996080e7          	jalr	-1642(ra) # 80000cc0 <release>
  if(do_commit){
    80004332:	b7c9                	j	800042f4 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004334:	0001da97          	auipc	s5,0x1d
    80004338:	98ca8a93          	addi	s5,s5,-1652 # 80020cc0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000433c:	0001da17          	auipc	s4,0x1d
    80004340:	954a0a13          	addi	s4,s4,-1708 # 80020c90 <log>
    80004344:	018a2583          	lw	a1,24(s4)
    80004348:	012585bb          	addw	a1,a1,s2
    8000434c:	2585                	addiw	a1,a1,1
    8000434e:	028a2503          	lw	a0,40(s4)
    80004352:	fffff097          	auipc	ra,0xfffff
    80004356:	cca080e7          	jalr	-822(ra) # 8000301c <bread>
    8000435a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000435c:	000aa583          	lw	a1,0(s5)
    80004360:	028a2503          	lw	a0,40(s4)
    80004364:	fffff097          	auipc	ra,0xfffff
    80004368:	cb8080e7          	jalr	-840(ra) # 8000301c <bread>
    8000436c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000436e:	40000613          	li	a2,1024
    80004372:	05850593          	addi	a1,a0,88
    80004376:	05848513          	addi	a0,s1,88
    8000437a:	ffffd097          	auipc	ra,0xffffd
    8000437e:	9ee080e7          	jalr	-1554(ra) # 80000d68 <memmove>
    bwrite(to);  // write the log
    80004382:	8526                	mv	a0,s1
    80004384:	fffff097          	auipc	ra,0xfffff
    80004388:	d8a080e7          	jalr	-630(ra) # 8000310e <bwrite>
    brelse(from);
    8000438c:	854e                	mv	a0,s3
    8000438e:	fffff097          	auipc	ra,0xfffff
    80004392:	dbe080e7          	jalr	-578(ra) # 8000314c <brelse>
    brelse(to);
    80004396:	8526                	mv	a0,s1
    80004398:	fffff097          	auipc	ra,0xfffff
    8000439c:	db4080e7          	jalr	-588(ra) # 8000314c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043a0:	2905                	addiw	s2,s2,1
    800043a2:	0a91                	addi	s5,s5,4
    800043a4:	02ca2783          	lw	a5,44(s4)
    800043a8:	f8f94ee3          	blt	s2,a5,80004344 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800043ac:	00000097          	auipc	ra,0x0
    800043b0:	c6a080e7          	jalr	-918(ra) # 80004016 <write_head>
    install_trans(0); // Now install writes to home locations
    800043b4:	4501                	li	a0,0
    800043b6:	00000097          	auipc	ra,0x0
    800043ba:	cda080e7          	jalr	-806(ra) # 80004090 <install_trans>
    log.lh.n = 0;
    800043be:	0001d797          	auipc	a5,0x1d
    800043c2:	8e07af23          	sw	zero,-1794(a5) # 80020cbc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800043c6:	00000097          	auipc	ra,0x0
    800043ca:	c50080e7          	jalr	-944(ra) # 80004016 <write_head>
    800043ce:	bdf5                	j	800042ca <end_op+0x52>

00000000800043d0 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800043d0:	1101                	addi	sp,sp,-32
    800043d2:	ec06                	sd	ra,24(sp)
    800043d4:	e822                	sd	s0,16(sp)
    800043d6:	e426                	sd	s1,8(sp)
    800043d8:	e04a                	sd	s2,0(sp)
    800043da:	1000                	addi	s0,sp,32
    800043dc:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800043de:	0001d917          	auipc	s2,0x1d
    800043e2:	8b290913          	addi	s2,s2,-1870 # 80020c90 <log>
    800043e6:	854a                	mv	a0,s2
    800043e8:	ffffd097          	auipc	ra,0xffffd
    800043ec:	824080e7          	jalr	-2012(ra) # 80000c0c <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800043f0:	02c92603          	lw	a2,44(s2)
    800043f4:	47f5                	li	a5,29
    800043f6:	06c7c563          	blt	a5,a2,80004460 <log_write+0x90>
    800043fa:	0001d797          	auipc	a5,0x1d
    800043fe:	8b27a783          	lw	a5,-1870(a5) # 80020cac <log+0x1c>
    80004402:	37fd                	addiw	a5,a5,-1
    80004404:	04f65e63          	bge	a2,a5,80004460 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004408:	0001d797          	auipc	a5,0x1d
    8000440c:	8a87a783          	lw	a5,-1880(a5) # 80020cb0 <log+0x20>
    80004410:	06f05063          	blez	a5,80004470 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004414:	4781                	li	a5,0
    80004416:	06c05563          	blez	a2,80004480 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000441a:	44cc                	lw	a1,12(s1)
    8000441c:	0001d717          	auipc	a4,0x1d
    80004420:	8a470713          	addi	a4,a4,-1884 # 80020cc0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004424:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004426:	4314                	lw	a3,0(a4)
    80004428:	04b68c63          	beq	a3,a1,80004480 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000442c:	2785                	addiw	a5,a5,1
    8000442e:	0711                	addi	a4,a4,4
    80004430:	fef61be3          	bne	a2,a5,80004426 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004434:	0621                	addi	a2,a2,8
    80004436:	060a                	slli	a2,a2,0x2
    80004438:	0001d797          	auipc	a5,0x1d
    8000443c:	85878793          	addi	a5,a5,-1960 # 80020c90 <log>
    80004440:	963e                	add	a2,a2,a5
    80004442:	44dc                	lw	a5,12(s1)
    80004444:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004446:	8526                	mv	a0,s1
    80004448:	fffff097          	auipc	ra,0xfffff
    8000444c:	da2080e7          	jalr	-606(ra) # 800031ea <bpin>
    log.lh.n++;
    80004450:	0001d717          	auipc	a4,0x1d
    80004454:	84070713          	addi	a4,a4,-1984 # 80020c90 <log>
    80004458:	575c                	lw	a5,44(a4)
    8000445a:	2785                	addiw	a5,a5,1
    8000445c:	d75c                	sw	a5,44(a4)
    8000445e:	a835                	j	8000449a <log_write+0xca>
    panic("too big a transaction");
    80004460:	00004517          	auipc	a0,0x4
    80004464:	24850513          	addi	a0,a0,584 # 800086a8 <syscalls+0x208>
    80004468:	ffffc097          	auipc	ra,0xffffc
    8000446c:	0dc080e7          	jalr	220(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    80004470:	00004517          	auipc	a0,0x4
    80004474:	25050513          	addi	a0,a0,592 # 800086c0 <syscalls+0x220>
    80004478:	ffffc097          	auipc	ra,0xffffc
    8000447c:	0cc080e7          	jalr	204(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    80004480:	00878713          	addi	a4,a5,8
    80004484:	00271693          	slli	a3,a4,0x2
    80004488:	0001d717          	auipc	a4,0x1d
    8000448c:	80870713          	addi	a4,a4,-2040 # 80020c90 <log>
    80004490:	9736                	add	a4,a4,a3
    80004492:	44d4                	lw	a3,12(s1)
    80004494:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004496:	faf608e3          	beq	a2,a5,80004446 <log_write+0x76>
  }
  release(&log.lock);
    8000449a:	0001c517          	auipc	a0,0x1c
    8000449e:	7f650513          	addi	a0,a0,2038 # 80020c90 <log>
    800044a2:	ffffd097          	auipc	ra,0xffffd
    800044a6:	81e080e7          	jalr	-2018(ra) # 80000cc0 <release>
}
    800044aa:	60e2                	ld	ra,24(sp)
    800044ac:	6442                	ld	s0,16(sp)
    800044ae:	64a2                	ld	s1,8(sp)
    800044b0:	6902                	ld	s2,0(sp)
    800044b2:	6105                	addi	sp,sp,32
    800044b4:	8082                	ret

00000000800044b6 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800044b6:	1101                	addi	sp,sp,-32
    800044b8:	ec06                	sd	ra,24(sp)
    800044ba:	e822                	sd	s0,16(sp)
    800044bc:	e426                	sd	s1,8(sp)
    800044be:	e04a                	sd	s2,0(sp)
    800044c0:	1000                	addi	s0,sp,32
    800044c2:	84aa                	mv	s1,a0
    800044c4:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800044c6:	00004597          	auipc	a1,0x4
    800044ca:	21a58593          	addi	a1,a1,538 # 800086e0 <syscalls+0x240>
    800044ce:	0521                	addi	a0,a0,8
    800044d0:	ffffc097          	auipc	ra,0xffffc
    800044d4:	6ac080e7          	jalr	1708(ra) # 80000b7c <initlock>
  lk->name = name;
    800044d8:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800044dc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044e0:	0204a423          	sw	zero,40(s1)
}
    800044e4:	60e2                	ld	ra,24(sp)
    800044e6:	6442                	ld	s0,16(sp)
    800044e8:	64a2                	ld	s1,8(sp)
    800044ea:	6902                	ld	s2,0(sp)
    800044ec:	6105                	addi	sp,sp,32
    800044ee:	8082                	ret

00000000800044f0 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800044f0:	1101                	addi	sp,sp,-32
    800044f2:	ec06                	sd	ra,24(sp)
    800044f4:	e822                	sd	s0,16(sp)
    800044f6:	e426                	sd	s1,8(sp)
    800044f8:	e04a                	sd	s2,0(sp)
    800044fa:	1000                	addi	s0,sp,32
    800044fc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044fe:	00850913          	addi	s2,a0,8
    80004502:	854a                	mv	a0,s2
    80004504:	ffffc097          	auipc	ra,0xffffc
    80004508:	708080e7          	jalr	1800(ra) # 80000c0c <acquire>
  while (lk->locked) {
    8000450c:	409c                	lw	a5,0(s1)
    8000450e:	cb89                	beqz	a5,80004520 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004510:	85ca                	mv	a1,s2
    80004512:	8526                	mv	a0,s1
    80004514:	ffffe097          	auipc	ra,0xffffe
    80004518:	b90080e7          	jalr	-1136(ra) # 800020a4 <sleep>
  while (lk->locked) {
    8000451c:	409c                	lw	a5,0(s1)
    8000451e:	fbed                	bnez	a5,80004510 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004520:	4785                	li	a5,1
    80004522:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004524:	ffffd097          	auipc	ra,0xffffd
    80004528:	4c4080e7          	jalr	1220(ra) # 800019e8 <myproc>
    8000452c:	591c                	lw	a5,48(a0)
    8000452e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004530:	854a                	mv	a0,s2
    80004532:	ffffc097          	auipc	ra,0xffffc
    80004536:	78e080e7          	jalr	1934(ra) # 80000cc0 <release>
}
    8000453a:	60e2                	ld	ra,24(sp)
    8000453c:	6442                	ld	s0,16(sp)
    8000453e:	64a2                	ld	s1,8(sp)
    80004540:	6902                	ld	s2,0(sp)
    80004542:	6105                	addi	sp,sp,32
    80004544:	8082                	ret

0000000080004546 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004546:	1101                	addi	sp,sp,-32
    80004548:	ec06                	sd	ra,24(sp)
    8000454a:	e822                	sd	s0,16(sp)
    8000454c:	e426                	sd	s1,8(sp)
    8000454e:	e04a                	sd	s2,0(sp)
    80004550:	1000                	addi	s0,sp,32
    80004552:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004554:	00850913          	addi	s2,a0,8
    80004558:	854a                	mv	a0,s2
    8000455a:	ffffc097          	auipc	ra,0xffffc
    8000455e:	6b2080e7          	jalr	1714(ra) # 80000c0c <acquire>
  lk->locked = 0;
    80004562:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004566:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000456a:	8526                	mv	a0,s1
    8000456c:	ffffe097          	auipc	ra,0xffffe
    80004570:	b9c080e7          	jalr	-1124(ra) # 80002108 <wakeup>
  release(&lk->lk);
    80004574:	854a                	mv	a0,s2
    80004576:	ffffc097          	auipc	ra,0xffffc
    8000457a:	74a080e7          	jalr	1866(ra) # 80000cc0 <release>
}
    8000457e:	60e2                	ld	ra,24(sp)
    80004580:	6442                	ld	s0,16(sp)
    80004582:	64a2                	ld	s1,8(sp)
    80004584:	6902                	ld	s2,0(sp)
    80004586:	6105                	addi	sp,sp,32
    80004588:	8082                	ret

000000008000458a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000458a:	7179                	addi	sp,sp,-48
    8000458c:	f406                	sd	ra,40(sp)
    8000458e:	f022                	sd	s0,32(sp)
    80004590:	ec26                	sd	s1,24(sp)
    80004592:	e84a                	sd	s2,16(sp)
    80004594:	e44e                	sd	s3,8(sp)
    80004596:	1800                	addi	s0,sp,48
    80004598:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000459a:	00850913          	addi	s2,a0,8
    8000459e:	854a                	mv	a0,s2
    800045a0:	ffffc097          	auipc	ra,0xffffc
    800045a4:	66c080e7          	jalr	1644(ra) # 80000c0c <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800045a8:	409c                	lw	a5,0(s1)
    800045aa:	ef99                	bnez	a5,800045c8 <holdingsleep+0x3e>
    800045ac:	4481                	li	s1,0
  release(&lk->lk);
    800045ae:	854a                	mv	a0,s2
    800045b0:	ffffc097          	auipc	ra,0xffffc
    800045b4:	710080e7          	jalr	1808(ra) # 80000cc0 <release>
  return r;
}
    800045b8:	8526                	mv	a0,s1
    800045ba:	70a2                	ld	ra,40(sp)
    800045bc:	7402                	ld	s0,32(sp)
    800045be:	64e2                	ld	s1,24(sp)
    800045c0:	6942                	ld	s2,16(sp)
    800045c2:	69a2                	ld	s3,8(sp)
    800045c4:	6145                	addi	sp,sp,48
    800045c6:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800045c8:	0284a983          	lw	s3,40(s1)
    800045cc:	ffffd097          	auipc	ra,0xffffd
    800045d0:	41c080e7          	jalr	1052(ra) # 800019e8 <myproc>
    800045d4:	5904                	lw	s1,48(a0)
    800045d6:	413484b3          	sub	s1,s1,s3
    800045da:	0014b493          	seqz	s1,s1
    800045de:	bfc1                	j	800045ae <holdingsleep+0x24>

00000000800045e0 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800045e0:	1141                	addi	sp,sp,-16
    800045e2:	e406                	sd	ra,8(sp)
    800045e4:	e022                	sd	s0,0(sp)
    800045e6:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800045e8:	00004597          	auipc	a1,0x4
    800045ec:	10858593          	addi	a1,a1,264 # 800086f0 <syscalls+0x250>
    800045f0:	0001c517          	auipc	a0,0x1c
    800045f4:	7e850513          	addi	a0,a0,2024 # 80020dd8 <ftable>
    800045f8:	ffffc097          	auipc	ra,0xffffc
    800045fc:	584080e7          	jalr	1412(ra) # 80000b7c <initlock>
}
    80004600:	60a2                	ld	ra,8(sp)
    80004602:	6402                	ld	s0,0(sp)
    80004604:	0141                	addi	sp,sp,16
    80004606:	8082                	ret

0000000080004608 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004608:	1101                	addi	sp,sp,-32
    8000460a:	ec06                	sd	ra,24(sp)
    8000460c:	e822                	sd	s0,16(sp)
    8000460e:	e426                	sd	s1,8(sp)
    80004610:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004612:	0001c517          	auipc	a0,0x1c
    80004616:	7c650513          	addi	a0,a0,1990 # 80020dd8 <ftable>
    8000461a:	ffffc097          	auipc	ra,0xffffc
    8000461e:	5f2080e7          	jalr	1522(ra) # 80000c0c <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004622:	0001c497          	auipc	s1,0x1c
    80004626:	7ce48493          	addi	s1,s1,1998 # 80020df0 <ftable+0x18>
    8000462a:	0001d717          	auipc	a4,0x1d
    8000462e:	76670713          	addi	a4,a4,1894 # 80021d90 <disk>
    if(f->ref == 0){
    80004632:	40dc                	lw	a5,4(s1)
    80004634:	cf99                	beqz	a5,80004652 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004636:	02848493          	addi	s1,s1,40
    8000463a:	fee49ce3          	bne	s1,a4,80004632 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000463e:	0001c517          	auipc	a0,0x1c
    80004642:	79a50513          	addi	a0,a0,1946 # 80020dd8 <ftable>
    80004646:	ffffc097          	auipc	ra,0xffffc
    8000464a:	67a080e7          	jalr	1658(ra) # 80000cc0 <release>
  return 0;
    8000464e:	4481                	li	s1,0
    80004650:	a819                	j	80004666 <filealloc+0x5e>
      f->ref = 1;
    80004652:	4785                	li	a5,1
    80004654:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004656:	0001c517          	auipc	a0,0x1c
    8000465a:	78250513          	addi	a0,a0,1922 # 80020dd8 <ftable>
    8000465e:	ffffc097          	auipc	ra,0xffffc
    80004662:	662080e7          	jalr	1634(ra) # 80000cc0 <release>
}
    80004666:	8526                	mv	a0,s1
    80004668:	60e2                	ld	ra,24(sp)
    8000466a:	6442                	ld	s0,16(sp)
    8000466c:	64a2                	ld	s1,8(sp)
    8000466e:	6105                	addi	sp,sp,32
    80004670:	8082                	ret

0000000080004672 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004672:	1101                	addi	sp,sp,-32
    80004674:	ec06                	sd	ra,24(sp)
    80004676:	e822                	sd	s0,16(sp)
    80004678:	e426                	sd	s1,8(sp)
    8000467a:	1000                	addi	s0,sp,32
    8000467c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000467e:	0001c517          	auipc	a0,0x1c
    80004682:	75a50513          	addi	a0,a0,1882 # 80020dd8 <ftable>
    80004686:	ffffc097          	auipc	ra,0xffffc
    8000468a:	586080e7          	jalr	1414(ra) # 80000c0c <acquire>
  if(f->ref < 1)
    8000468e:	40dc                	lw	a5,4(s1)
    80004690:	02f05263          	blez	a5,800046b4 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004694:	2785                	addiw	a5,a5,1
    80004696:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004698:	0001c517          	auipc	a0,0x1c
    8000469c:	74050513          	addi	a0,a0,1856 # 80020dd8 <ftable>
    800046a0:	ffffc097          	auipc	ra,0xffffc
    800046a4:	620080e7          	jalr	1568(ra) # 80000cc0 <release>
  return f;
}
    800046a8:	8526                	mv	a0,s1
    800046aa:	60e2                	ld	ra,24(sp)
    800046ac:	6442                	ld	s0,16(sp)
    800046ae:	64a2                	ld	s1,8(sp)
    800046b0:	6105                	addi	sp,sp,32
    800046b2:	8082                	ret
    panic("filedup");
    800046b4:	00004517          	auipc	a0,0x4
    800046b8:	04450513          	addi	a0,a0,68 # 800086f8 <syscalls+0x258>
    800046bc:	ffffc097          	auipc	ra,0xffffc
    800046c0:	e88080e7          	jalr	-376(ra) # 80000544 <panic>

00000000800046c4 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800046c4:	7139                	addi	sp,sp,-64
    800046c6:	fc06                	sd	ra,56(sp)
    800046c8:	f822                	sd	s0,48(sp)
    800046ca:	f426                	sd	s1,40(sp)
    800046cc:	f04a                	sd	s2,32(sp)
    800046ce:	ec4e                	sd	s3,24(sp)
    800046d0:	e852                	sd	s4,16(sp)
    800046d2:	e456                	sd	s5,8(sp)
    800046d4:	0080                	addi	s0,sp,64
    800046d6:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800046d8:	0001c517          	auipc	a0,0x1c
    800046dc:	70050513          	addi	a0,a0,1792 # 80020dd8 <ftable>
    800046e0:	ffffc097          	auipc	ra,0xffffc
    800046e4:	52c080e7          	jalr	1324(ra) # 80000c0c <acquire>
  if(f->ref < 1)
    800046e8:	40dc                	lw	a5,4(s1)
    800046ea:	06f05163          	blez	a5,8000474c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800046ee:	37fd                	addiw	a5,a5,-1
    800046f0:	0007871b          	sext.w	a4,a5
    800046f4:	c0dc                	sw	a5,4(s1)
    800046f6:	06e04363          	bgtz	a4,8000475c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800046fa:	0004a903          	lw	s2,0(s1)
    800046fe:	0094ca83          	lbu	s5,9(s1)
    80004702:	0104ba03          	ld	s4,16(s1)
    80004706:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000470a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000470e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004712:	0001c517          	auipc	a0,0x1c
    80004716:	6c650513          	addi	a0,a0,1734 # 80020dd8 <ftable>
    8000471a:	ffffc097          	auipc	ra,0xffffc
    8000471e:	5a6080e7          	jalr	1446(ra) # 80000cc0 <release>

  if(ff.type == FD_PIPE){
    80004722:	4785                	li	a5,1
    80004724:	04f90d63          	beq	s2,a5,8000477e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004728:	3979                	addiw	s2,s2,-2
    8000472a:	4785                	li	a5,1
    8000472c:	0527e063          	bltu	a5,s2,8000476c <fileclose+0xa8>
    begin_op();
    80004730:	00000097          	auipc	ra,0x0
    80004734:	ac8080e7          	jalr	-1336(ra) # 800041f8 <begin_op>
    iput(ff.ip);
    80004738:	854e                	mv	a0,s3
    8000473a:	fffff097          	auipc	ra,0xfffff
    8000473e:	2b6080e7          	jalr	694(ra) # 800039f0 <iput>
    end_op();
    80004742:	00000097          	auipc	ra,0x0
    80004746:	b36080e7          	jalr	-1226(ra) # 80004278 <end_op>
    8000474a:	a00d                	j	8000476c <fileclose+0xa8>
    panic("fileclose");
    8000474c:	00004517          	auipc	a0,0x4
    80004750:	fb450513          	addi	a0,a0,-76 # 80008700 <syscalls+0x260>
    80004754:	ffffc097          	auipc	ra,0xffffc
    80004758:	df0080e7          	jalr	-528(ra) # 80000544 <panic>
    release(&ftable.lock);
    8000475c:	0001c517          	auipc	a0,0x1c
    80004760:	67c50513          	addi	a0,a0,1660 # 80020dd8 <ftable>
    80004764:	ffffc097          	auipc	ra,0xffffc
    80004768:	55c080e7          	jalr	1372(ra) # 80000cc0 <release>
  }
}
    8000476c:	70e2                	ld	ra,56(sp)
    8000476e:	7442                	ld	s0,48(sp)
    80004770:	74a2                	ld	s1,40(sp)
    80004772:	7902                	ld	s2,32(sp)
    80004774:	69e2                	ld	s3,24(sp)
    80004776:	6a42                	ld	s4,16(sp)
    80004778:	6aa2                	ld	s5,8(sp)
    8000477a:	6121                	addi	sp,sp,64
    8000477c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000477e:	85d6                	mv	a1,s5
    80004780:	8552                	mv	a0,s4
    80004782:	00000097          	auipc	ra,0x0
    80004786:	34c080e7          	jalr	844(ra) # 80004ace <pipeclose>
    8000478a:	b7cd                	j	8000476c <fileclose+0xa8>

000000008000478c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000478c:	715d                	addi	sp,sp,-80
    8000478e:	e486                	sd	ra,72(sp)
    80004790:	e0a2                	sd	s0,64(sp)
    80004792:	fc26                	sd	s1,56(sp)
    80004794:	f84a                	sd	s2,48(sp)
    80004796:	f44e                	sd	s3,40(sp)
    80004798:	0880                	addi	s0,sp,80
    8000479a:	84aa                	mv	s1,a0
    8000479c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000479e:	ffffd097          	auipc	ra,0xffffd
    800047a2:	24a080e7          	jalr	586(ra) # 800019e8 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800047a6:	409c                	lw	a5,0(s1)
    800047a8:	37f9                	addiw	a5,a5,-2
    800047aa:	4705                	li	a4,1
    800047ac:	04f76763          	bltu	a4,a5,800047fa <filestat+0x6e>
    800047b0:	892a                	mv	s2,a0
    ilock(f->ip);
    800047b2:	6c88                	ld	a0,24(s1)
    800047b4:	fffff097          	auipc	ra,0xfffff
    800047b8:	082080e7          	jalr	130(ra) # 80003836 <ilock>
    stati(f->ip, &st);
    800047bc:	fb840593          	addi	a1,s0,-72
    800047c0:	6c88                	ld	a0,24(s1)
    800047c2:	fffff097          	auipc	ra,0xfffff
    800047c6:	2fe080e7          	jalr	766(ra) # 80003ac0 <stati>
    iunlock(f->ip);
    800047ca:	6c88                	ld	a0,24(s1)
    800047cc:	fffff097          	auipc	ra,0xfffff
    800047d0:	12c080e7          	jalr	300(ra) # 800038f8 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800047d4:	46e1                	li	a3,24
    800047d6:	fb840613          	addi	a2,s0,-72
    800047da:	85ce                	mv	a1,s3
    800047dc:	05093503          	ld	a0,80(s2)
    800047e0:	ffffd097          	auipc	ra,0xffffd
    800047e4:	ec6080e7          	jalr	-314(ra) # 800016a6 <copyout>
    800047e8:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800047ec:	60a6                	ld	ra,72(sp)
    800047ee:	6406                	ld	s0,64(sp)
    800047f0:	74e2                	ld	s1,56(sp)
    800047f2:	7942                	ld	s2,48(sp)
    800047f4:	79a2                	ld	s3,40(sp)
    800047f6:	6161                	addi	sp,sp,80
    800047f8:	8082                	ret
  return -1;
    800047fa:	557d                	li	a0,-1
    800047fc:	bfc5                	j	800047ec <filestat+0x60>

00000000800047fe <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800047fe:	7179                	addi	sp,sp,-48
    80004800:	f406                	sd	ra,40(sp)
    80004802:	f022                	sd	s0,32(sp)
    80004804:	ec26                	sd	s1,24(sp)
    80004806:	e84a                	sd	s2,16(sp)
    80004808:	e44e                	sd	s3,8(sp)
    8000480a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000480c:	00854783          	lbu	a5,8(a0)
    80004810:	c3d5                	beqz	a5,800048b4 <fileread+0xb6>
    80004812:	84aa                	mv	s1,a0
    80004814:	89ae                	mv	s3,a1
    80004816:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004818:	411c                	lw	a5,0(a0)
    8000481a:	4705                	li	a4,1
    8000481c:	04e78963          	beq	a5,a4,8000486e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004820:	470d                	li	a4,3
    80004822:	04e78d63          	beq	a5,a4,8000487c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004826:	4709                	li	a4,2
    80004828:	06e79e63          	bne	a5,a4,800048a4 <fileread+0xa6>
    ilock(f->ip);
    8000482c:	6d08                	ld	a0,24(a0)
    8000482e:	fffff097          	auipc	ra,0xfffff
    80004832:	008080e7          	jalr	8(ra) # 80003836 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004836:	874a                	mv	a4,s2
    80004838:	5094                	lw	a3,32(s1)
    8000483a:	864e                	mv	a2,s3
    8000483c:	4585                	li	a1,1
    8000483e:	6c88                	ld	a0,24(s1)
    80004840:	fffff097          	auipc	ra,0xfffff
    80004844:	2aa080e7          	jalr	682(ra) # 80003aea <readi>
    80004848:	892a                	mv	s2,a0
    8000484a:	00a05563          	blez	a0,80004854 <fileread+0x56>
      f->off += r;
    8000484e:	509c                	lw	a5,32(s1)
    80004850:	9fa9                	addw	a5,a5,a0
    80004852:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004854:	6c88                	ld	a0,24(s1)
    80004856:	fffff097          	auipc	ra,0xfffff
    8000485a:	0a2080e7          	jalr	162(ra) # 800038f8 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000485e:	854a                	mv	a0,s2
    80004860:	70a2                	ld	ra,40(sp)
    80004862:	7402                	ld	s0,32(sp)
    80004864:	64e2                	ld	s1,24(sp)
    80004866:	6942                	ld	s2,16(sp)
    80004868:	69a2                	ld	s3,8(sp)
    8000486a:	6145                	addi	sp,sp,48
    8000486c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000486e:	6908                	ld	a0,16(a0)
    80004870:	00000097          	auipc	ra,0x0
    80004874:	3ce080e7          	jalr	974(ra) # 80004c3e <piperead>
    80004878:	892a                	mv	s2,a0
    8000487a:	b7d5                	j	8000485e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000487c:	02451783          	lh	a5,36(a0)
    80004880:	03079693          	slli	a3,a5,0x30
    80004884:	92c1                	srli	a3,a3,0x30
    80004886:	4725                	li	a4,9
    80004888:	02d76863          	bltu	a4,a3,800048b8 <fileread+0xba>
    8000488c:	0792                	slli	a5,a5,0x4
    8000488e:	0001c717          	auipc	a4,0x1c
    80004892:	4aa70713          	addi	a4,a4,1194 # 80020d38 <devsw>
    80004896:	97ba                	add	a5,a5,a4
    80004898:	639c                	ld	a5,0(a5)
    8000489a:	c38d                	beqz	a5,800048bc <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000489c:	4505                	li	a0,1
    8000489e:	9782                	jalr	a5
    800048a0:	892a                	mv	s2,a0
    800048a2:	bf75                	j	8000485e <fileread+0x60>
    panic("fileread");
    800048a4:	00004517          	auipc	a0,0x4
    800048a8:	e6c50513          	addi	a0,a0,-404 # 80008710 <syscalls+0x270>
    800048ac:	ffffc097          	auipc	ra,0xffffc
    800048b0:	c98080e7          	jalr	-872(ra) # 80000544 <panic>
    return -1;
    800048b4:	597d                	li	s2,-1
    800048b6:	b765                	j	8000485e <fileread+0x60>
      return -1;
    800048b8:	597d                	li	s2,-1
    800048ba:	b755                	j	8000485e <fileread+0x60>
    800048bc:	597d                	li	s2,-1
    800048be:	b745                	j	8000485e <fileread+0x60>

00000000800048c0 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800048c0:	715d                	addi	sp,sp,-80
    800048c2:	e486                	sd	ra,72(sp)
    800048c4:	e0a2                	sd	s0,64(sp)
    800048c6:	fc26                	sd	s1,56(sp)
    800048c8:	f84a                	sd	s2,48(sp)
    800048ca:	f44e                	sd	s3,40(sp)
    800048cc:	f052                	sd	s4,32(sp)
    800048ce:	ec56                	sd	s5,24(sp)
    800048d0:	e85a                	sd	s6,16(sp)
    800048d2:	e45e                	sd	s7,8(sp)
    800048d4:	e062                	sd	s8,0(sp)
    800048d6:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800048d8:	00954783          	lbu	a5,9(a0)
    800048dc:	10078663          	beqz	a5,800049e8 <filewrite+0x128>
    800048e0:	892a                	mv	s2,a0
    800048e2:	8aae                	mv	s5,a1
    800048e4:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800048e6:	411c                	lw	a5,0(a0)
    800048e8:	4705                	li	a4,1
    800048ea:	02e78263          	beq	a5,a4,8000490e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048ee:	470d                	li	a4,3
    800048f0:	02e78663          	beq	a5,a4,8000491c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800048f4:	4709                	li	a4,2
    800048f6:	0ee79163          	bne	a5,a4,800049d8 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800048fa:	0ac05d63          	blez	a2,800049b4 <filewrite+0xf4>
    int i = 0;
    800048fe:	4981                	li	s3,0
    80004900:	6b05                	lui	s6,0x1
    80004902:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004906:	6b85                	lui	s7,0x1
    80004908:	c00b8b9b          	addiw	s7,s7,-1024
    8000490c:	a861                	j	800049a4 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000490e:	6908                	ld	a0,16(a0)
    80004910:	00000097          	auipc	ra,0x0
    80004914:	22e080e7          	jalr	558(ra) # 80004b3e <pipewrite>
    80004918:	8a2a                	mv	s4,a0
    8000491a:	a045                	j	800049ba <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000491c:	02451783          	lh	a5,36(a0)
    80004920:	03079693          	slli	a3,a5,0x30
    80004924:	92c1                	srli	a3,a3,0x30
    80004926:	4725                	li	a4,9
    80004928:	0cd76263          	bltu	a4,a3,800049ec <filewrite+0x12c>
    8000492c:	0792                	slli	a5,a5,0x4
    8000492e:	0001c717          	auipc	a4,0x1c
    80004932:	40a70713          	addi	a4,a4,1034 # 80020d38 <devsw>
    80004936:	97ba                	add	a5,a5,a4
    80004938:	679c                	ld	a5,8(a5)
    8000493a:	cbdd                	beqz	a5,800049f0 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000493c:	4505                	li	a0,1
    8000493e:	9782                	jalr	a5
    80004940:	8a2a                	mv	s4,a0
    80004942:	a8a5                	j	800049ba <filewrite+0xfa>
    80004944:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004948:	00000097          	auipc	ra,0x0
    8000494c:	8b0080e7          	jalr	-1872(ra) # 800041f8 <begin_op>
      ilock(f->ip);
    80004950:	01893503          	ld	a0,24(s2)
    80004954:	fffff097          	auipc	ra,0xfffff
    80004958:	ee2080e7          	jalr	-286(ra) # 80003836 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000495c:	8762                	mv	a4,s8
    8000495e:	02092683          	lw	a3,32(s2)
    80004962:	01598633          	add	a2,s3,s5
    80004966:	4585                	li	a1,1
    80004968:	01893503          	ld	a0,24(s2)
    8000496c:	fffff097          	auipc	ra,0xfffff
    80004970:	276080e7          	jalr	630(ra) # 80003be2 <writei>
    80004974:	84aa                	mv	s1,a0
    80004976:	00a05763          	blez	a0,80004984 <filewrite+0xc4>
        f->off += r;
    8000497a:	02092783          	lw	a5,32(s2)
    8000497e:	9fa9                	addw	a5,a5,a0
    80004980:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004984:	01893503          	ld	a0,24(s2)
    80004988:	fffff097          	auipc	ra,0xfffff
    8000498c:	f70080e7          	jalr	-144(ra) # 800038f8 <iunlock>
      end_op();
    80004990:	00000097          	auipc	ra,0x0
    80004994:	8e8080e7          	jalr	-1816(ra) # 80004278 <end_op>

      if(r != n1){
    80004998:	009c1f63          	bne	s8,s1,800049b6 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000499c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800049a0:	0149db63          	bge	s3,s4,800049b6 <filewrite+0xf6>
      int n1 = n - i;
    800049a4:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800049a8:	84be                	mv	s1,a5
    800049aa:	2781                	sext.w	a5,a5
    800049ac:	f8fb5ce3          	bge	s6,a5,80004944 <filewrite+0x84>
    800049b0:	84de                	mv	s1,s7
    800049b2:	bf49                	j	80004944 <filewrite+0x84>
    int i = 0;
    800049b4:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800049b6:	013a1f63          	bne	s4,s3,800049d4 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800049ba:	8552                	mv	a0,s4
    800049bc:	60a6                	ld	ra,72(sp)
    800049be:	6406                	ld	s0,64(sp)
    800049c0:	74e2                	ld	s1,56(sp)
    800049c2:	7942                	ld	s2,48(sp)
    800049c4:	79a2                	ld	s3,40(sp)
    800049c6:	7a02                	ld	s4,32(sp)
    800049c8:	6ae2                	ld	s5,24(sp)
    800049ca:	6b42                	ld	s6,16(sp)
    800049cc:	6ba2                	ld	s7,8(sp)
    800049ce:	6c02                	ld	s8,0(sp)
    800049d0:	6161                	addi	sp,sp,80
    800049d2:	8082                	ret
    ret = (i == n ? n : -1);
    800049d4:	5a7d                	li	s4,-1
    800049d6:	b7d5                	j	800049ba <filewrite+0xfa>
    panic("filewrite");
    800049d8:	00004517          	auipc	a0,0x4
    800049dc:	d4850513          	addi	a0,a0,-696 # 80008720 <syscalls+0x280>
    800049e0:	ffffc097          	auipc	ra,0xffffc
    800049e4:	b64080e7          	jalr	-1180(ra) # 80000544 <panic>
    return -1;
    800049e8:	5a7d                	li	s4,-1
    800049ea:	bfc1                	j	800049ba <filewrite+0xfa>
      return -1;
    800049ec:	5a7d                	li	s4,-1
    800049ee:	b7f1                	j	800049ba <filewrite+0xfa>
    800049f0:	5a7d                	li	s4,-1
    800049f2:	b7e1                	j	800049ba <filewrite+0xfa>

00000000800049f4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800049f4:	7179                	addi	sp,sp,-48
    800049f6:	f406                	sd	ra,40(sp)
    800049f8:	f022                	sd	s0,32(sp)
    800049fa:	ec26                	sd	s1,24(sp)
    800049fc:	e84a                	sd	s2,16(sp)
    800049fe:	e44e                	sd	s3,8(sp)
    80004a00:	e052                	sd	s4,0(sp)
    80004a02:	1800                	addi	s0,sp,48
    80004a04:	84aa                	mv	s1,a0
    80004a06:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a08:	0005b023          	sd	zero,0(a1)
    80004a0c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a10:	00000097          	auipc	ra,0x0
    80004a14:	bf8080e7          	jalr	-1032(ra) # 80004608 <filealloc>
    80004a18:	e088                	sd	a0,0(s1)
    80004a1a:	c551                	beqz	a0,80004aa6 <pipealloc+0xb2>
    80004a1c:	00000097          	auipc	ra,0x0
    80004a20:	bec080e7          	jalr	-1044(ra) # 80004608 <filealloc>
    80004a24:	00aa3023          	sd	a0,0(s4)
    80004a28:	c92d                	beqz	a0,80004a9a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a2a:	ffffc097          	auipc	ra,0xffffc
    80004a2e:	0d0080e7          	jalr	208(ra) # 80000afa <kalloc>
    80004a32:	892a                	mv	s2,a0
    80004a34:	c125                	beqz	a0,80004a94 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a36:	4985                	li	s3,1
    80004a38:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a3c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a40:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a44:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a48:	00004597          	auipc	a1,0x4
    80004a4c:	ce858593          	addi	a1,a1,-792 # 80008730 <syscalls+0x290>
    80004a50:	ffffc097          	auipc	ra,0xffffc
    80004a54:	12c080e7          	jalr	300(ra) # 80000b7c <initlock>
  (*f0)->type = FD_PIPE;
    80004a58:	609c                	ld	a5,0(s1)
    80004a5a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a5e:	609c                	ld	a5,0(s1)
    80004a60:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a64:	609c                	ld	a5,0(s1)
    80004a66:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a6a:	609c                	ld	a5,0(s1)
    80004a6c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a70:	000a3783          	ld	a5,0(s4)
    80004a74:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a78:	000a3783          	ld	a5,0(s4)
    80004a7c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a80:	000a3783          	ld	a5,0(s4)
    80004a84:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a88:	000a3783          	ld	a5,0(s4)
    80004a8c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a90:	4501                	li	a0,0
    80004a92:	a025                	j	80004aba <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a94:	6088                	ld	a0,0(s1)
    80004a96:	e501                	bnez	a0,80004a9e <pipealloc+0xaa>
    80004a98:	a039                	j	80004aa6 <pipealloc+0xb2>
    80004a9a:	6088                	ld	a0,0(s1)
    80004a9c:	c51d                	beqz	a0,80004aca <pipealloc+0xd6>
    fileclose(*f0);
    80004a9e:	00000097          	auipc	ra,0x0
    80004aa2:	c26080e7          	jalr	-986(ra) # 800046c4 <fileclose>
  if(*f1)
    80004aa6:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004aaa:	557d                	li	a0,-1
  if(*f1)
    80004aac:	c799                	beqz	a5,80004aba <pipealloc+0xc6>
    fileclose(*f1);
    80004aae:	853e                	mv	a0,a5
    80004ab0:	00000097          	auipc	ra,0x0
    80004ab4:	c14080e7          	jalr	-1004(ra) # 800046c4 <fileclose>
  return -1;
    80004ab8:	557d                	li	a0,-1
}
    80004aba:	70a2                	ld	ra,40(sp)
    80004abc:	7402                	ld	s0,32(sp)
    80004abe:	64e2                	ld	s1,24(sp)
    80004ac0:	6942                	ld	s2,16(sp)
    80004ac2:	69a2                	ld	s3,8(sp)
    80004ac4:	6a02                	ld	s4,0(sp)
    80004ac6:	6145                	addi	sp,sp,48
    80004ac8:	8082                	ret
  return -1;
    80004aca:	557d                	li	a0,-1
    80004acc:	b7fd                	j	80004aba <pipealloc+0xc6>

0000000080004ace <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004ace:	1101                	addi	sp,sp,-32
    80004ad0:	ec06                	sd	ra,24(sp)
    80004ad2:	e822                	sd	s0,16(sp)
    80004ad4:	e426                	sd	s1,8(sp)
    80004ad6:	e04a                	sd	s2,0(sp)
    80004ad8:	1000                	addi	s0,sp,32
    80004ada:	84aa                	mv	s1,a0
    80004adc:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004ade:	ffffc097          	auipc	ra,0xffffc
    80004ae2:	12e080e7          	jalr	302(ra) # 80000c0c <acquire>
  if(writable){
    80004ae6:	02090d63          	beqz	s2,80004b20 <pipeclose+0x52>
    pi->writeopen = 0;
    80004aea:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004aee:	21848513          	addi	a0,s1,536
    80004af2:	ffffd097          	auipc	ra,0xffffd
    80004af6:	616080e7          	jalr	1558(ra) # 80002108 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004afa:	2204b783          	ld	a5,544(s1)
    80004afe:	eb95                	bnez	a5,80004b32 <pipeclose+0x64>
    release(&pi->lock);
    80004b00:	8526                	mv	a0,s1
    80004b02:	ffffc097          	auipc	ra,0xffffc
    80004b06:	1be080e7          	jalr	446(ra) # 80000cc0 <release>
    kfree((char*)pi);
    80004b0a:	8526                	mv	a0,s1
    80004b0c:	ffffc097          	auipc	ra,0xffffc
    80004b10:	ef2080e7          	jalr	-270(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    80004b14:	60e2                	ld	ra,24(sp)
    80004b16:	6442                	ld	s0,16(sp)
    80004b18:	64a2                	ld	s1,8(sp)
    80004b1a:	6902                	ld	s2,0(sp)
    80004b1c:	6105                	addi	sp,sp,32
    80004b1e:	8082                	ret
    pi->readopen = 0;
    80004b20:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b24:	21c48513          	addi	a0,s1,540
    80004b28:	ffffd097          	auipc	ra,0xffffd
    80004b2c:	5e0080e7          	jalr	1504(ra) # 80002108 <wakeup>
    80004b30:	b7e9                	j	80004afa <pipeclose+0x2c>
    release(&pi->lock);
    80004b32:	8526                	mv	a0,s1
    80004b34:	ffffc097          	auipc	ra,0xffffc
    80004b38:	18c080e7          	jalr	396(ra) # 80000cc0 <release>
}
    80004b3c:	bfe1                	j	80004b14 <pipeclose+0x46>

0000000080004b3e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b3e:	7159                	addi	sp,sp,-112
    80004b40:	f486                	sd	ra,104(sp)
    80004b42:	f0a2                	sd	s0,96(sp)
    80004b44:	eca6                	sd	s1,88(sp)
    80004b46:	e8ca                	sd	s2,80(sp)
    80004b48:	e4ce                	sd	s3,72(sp)
    80004b4a:	e0d2                	sd	s4,64(sp)
    80004b4c:	fc56                	sd	s5,56(sp)
    80004b4e:	f85a                	sd	s6,48(sp)
    80004b50:	f45e                	sd	s7,40(sp)
    80004b52:	f062                	sd	s8,32(sp)
    80004b54:	ec66                	sd	s9,24(sp)
    80004b56:	1880                	addi	s0,sp,112
    80004b58:	84aa                	mv	s1,a0
    80004b5a:	8aae                	mv	s5,a1
    80004b5c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004b5e:	ffffd097          	auipc	ra,0xffffd
    80004b62:	e8a080e7          	jalr	-374(ra) # 800019e8 <myproc>
    80004b66:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b68:	8526                	mv	a0,s1
    80004b6a:	ffffc097          	auipc	ra,0xffffc
    80004b6e:	0a2080e7          	jalr	162(ra) # 80000c0c <acquire>
  while(i < n){
    80004b72:	0d405463          	blez	s4,80004c3a <pipewrite+0xfc>
    80004b76:	8ba6                	mv	s7,s1
  int i = 0;
    80004b78:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b7a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b7c:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b80:	21c48c13          	addi	s8,s1,540
    80004b84:	a08d                	j	80004be6 <pipewrite+0xa8>
      release(&pi->lock);
    80004b86:	8526                	mv	a0,s1
    80004b88:	ffffc097          	auipc	ra,0xffffc
    80004b8c:	138080e7          	jalr	312(ra) # 80000cc0 <release>
      return -1;
    80004b90:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b92:	854a                	mv	a0,s2
    80004b94:	70a6                	ld	ra,104(sp)
    80004b96:	7406                	ld	s0,96(sp)
    80004b98:	64e6                	ld	s1,88(sp)
    80004b9a:	6946                	ld	s2,80(sp)
    80004b9c:	69a6                	ld	s3,72(sp)
    80004b9e:	6a06                	ld	s4,64(sp)
    80004ba0:	7ae2                	ld	s5,56(sp)
    80004ba2:	7b42                	ld	s6,48(sp)
    80004ba4:	7ba2                	ld	s7,40(sp)
    80004ba6:	7c02                	ld	s8,32(sp)
    80004ba8:	6ce2                	ld	s9,24(sp)
    80004baa:	6165                	addi	sp,sp,112
    80004bac:	8082                	ret
      wakeup(&pi->nread);
    80004bae:	8566                	mv	a0,s9
    80004bb0:	ffffd097          	auipc	ra,0xffffd
    80004bb4:	558080e7          	jalr	1368(ra) # 80002108 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004bb8:	85de                	mv	a1,s7
    80004bba:	8562                	mv	a0,s8
    80004bbc:	ffffd097          	auipc	ra,0xffffd
    80004bc0:	4e8080e7          	jalr	1256(ra) # 800020a4 <sleep>
    80004bc4:	a839                	j	80004be2 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004bc6:	21c4a783          	lw	a5,540(s1)
    80004bca:	0017871b          	addiw	a4,a5,1
    80004bce:	20e4ae23          	sw	a4,540(s1)
    80004bd2:	1ff7f793          	andi	a5,a5,511
    80004bd6:	97a6                	add	a5,a5,s1
    80004bd8:	f9f44703          	lbu	a4,-97(s0)
    80004bdc:	00e78c23          	sb	a4,24(a5)
      i++;
    80004be0:	2905                	addiw	s2,s2,1
  while(i < n){
    80004be2:	05495063          	bge	s2,s4,80004c22 <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    80004be6:	2204a783          	lw	a5,544(s1)
    80004bea:	dfd1                	beqz	a5,80004b86 <pipewrite+0x48>
    80004bec:	854e                	mv	a0,s3
    80004bee:	ffffd097          	auipc	ra,0xffffd
    80004bf2:	75e080e7          	jalr	1886(ra) # 8000234c <killed>
    80004bf6:	f941                	bnez	a0,80004b86 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004bf8:	2184a783          	lw	a5,536(s1)
    80004bfc:	21c4a703          	lw	a4,540(s1)
    80004c00:	2007879b          	addiw	a5,a5,512
    80004c04:	faf705e3          	beq	a4,a5,80004bae <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c08:	4685                	li	a3,1
    80004c0a:	01590633          	add	a2,s2,s5
    80004c0e:	f9f40593          	addi	a1,s0,-97
    80004c12:	0509b503          	ld	a0,80(s3)
    80004c16:	ffffd097          	auipc	ra,0xffffd
    80004c1a:	b1c080e7          	jalr	-1252(ra) # 80001732 <copyin>
    80004c1e:	fb6514e3          	bne	a0,s6,80004bc6 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004c22:	21848513          	addi	a0,s1,536
    80004c26:	ffffd097          	auipc	ra,0xffffd
    80004c2a:	4e2080e7          	jalr	1250(ra) # 80002108 <wakeup>
  release(&pi->lock);
    80004c2e:	8526                	mv	a0,s1
    80004c30:	ffffc097          	auipc	ra,0xffffc
    80004c34:	090080e7          	jalr	144(ra) # 80000cc0 <release>
  return i;
    80004c38:	bfa9                	j	80004b92 <pipewrite+0x54>
  int i = 0;
    80004c3a:	4901                	li	s2,0
    80004c3c:	b7dd                	j	80004c22 <pipewrite+0xe4>

0000000080004c3e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c3e:	715d                	addi	sp,sp,-80
    80004c40:	e486                	sd	ra,72(sp)
    80004c42:	e0a2                	sd	s0,64(sp)
    80004c44:	fc26                	sd	s1,56(sp)
    80004c46:	f84a                	sd	s2,48(sp)
    80004c48:	f44e                	sd	s3,40(sp)
    80004c4a:	f052                	sd	s4,32(sp)
    80004c4c:	ec56                	sd	s5,24(sp)
    80004c4e:	e85a                	sd	s6,16(sp)
    80004c50:	0880                	addi	s0,sp,80
    80004c52:	84aa                	mv	s1,a0
    80004c54:	892e                	mv	s2,a1
    80004c56:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c58:	ffffd097          	auipc	ra,0xffffd
    80004c5c:	d90080e7          	jalr	-624(ra) # 800019e8 <myproc>
    80004c60:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c62:	8b26                	mv	s6,s1
    80004c64:	8526                	mv	a0,s1
    80004c66:	ffffc097          	auipc	ra,0xffffc
    80004c6a:	fa6080e7          	jalr	-90(ra) # 80000c0c <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c6e:	2184a703          	lw	a4,536(s1)
    80004c72:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c76:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c7a:	02f71763          	bne	a4,a5,80004ca8 <piperead+0x6a>
    80004c7e:	2244a783          	lw	a5,548(s1)
    80004c82:	c39d                	beqz	a5,80004ca8 <piperead+0x6a>
    if(killed(pr)){
    80004c84:	8552                	mv	a0,s4
    80004c86:	ffffd097          	auipc	ra,0xffffd
    80004c8a:	6c6080e7          	jalr	1734(ra) # 8000234c <killed>
    80004c8e:	e941                	bnez	a0,80004d1e <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c90:	85da                	mv	a1,s6
    80004c92:	854e                	mv	a0,s3
    80004c94:	ffffd097          	auipc	ra,0xffffd
    80004c98:	410080e7          	jalr	1040(ra) # 800020a4 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c9c:	2184a703          	lw	a4,536(s1)
    80004ca0:	21c4a783          	lw	a5,540(s1)
    80004ca4:	fcf70de3          	beq	a4,a5,80004c7e <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ca8:	09505263          	blez	s5,80004d2c <piperead+0xee>
    80004cac:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cae:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004cb0:	2184a783          	lw	a5,536(s1)
    80004cb4:	21c4a703          	lw	a4,540(s1)
    80004cb8:	02f70d63          	beq	a4,a5,80004cf2 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004cbc:	0017871b          	addiw	a4,a5,1
    80004cc0:	20e4ac23          	sw	a4,536(s1)
    80004cc4:	1ff7f793          	andi	a5,a5,511
    80004cc8:	97a6                	add	a5,a5,s1
    80004cca:	0187c783          	lbu	a5,24(a5)
    80004cce:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cd2:	4685                	li	a3,1
    80004cd4:	fbf40613          	addi	a2,s0,-65
    80004cd8:	85ca                	mv	a1,s2
    80004cda:	050a3503          	ld	a0,80(s4)
    80004cde:	ffffd097          	auipc	ra,0xffffd
    80004ce2:	9c8080e7          	jalr	-1592(ra) # 800016a6 <copyout>
    80004ce6:	01650663          	beq	a0,s6,80004cf2 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cea:	2985                	addiw	s3,s3,1
    80004cec:	0905                	addi	s2,s2,1
    80004cee:	fd3a91e3          	bne	s5,s3,80004cb0 <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004cf2:	21c48513          	addi	a0,s1,540
    80004cf6:	ffffd097          	auipc	ra,0xffffd
    80004cfa:	412080e7          	jalr	1042(ra) # 80002108 <wakeup>
  release(&pi->lock);
    80004cfe:	8526                	mv	a0,s1
    80004d00:	ffffc097          	auipc	ra,0xffffc
    80004d04:	fc0080e7          	jalr	-64(ra) # 80000cc0 <release>
  return i;
}
    80004d08:	854e                	mv	a0,s3
    80004d0a:	60a6                	ld	ra,72(sp)
    80004d0c:	6406                	ld	s0,64(sp)
    80004d0e:	74e2                	ld	s1,56(sp)
    80004d10:	7942                	ld	s2,48(sp)
    80004d12:	79a2                	ld	s3,40(sp)
    80004d14:	7a02                	ld	s4,32(sp)
    80004d16:	6ae2                	ld	s5,24(sp)
    80004d18:	6b42                	ld	s6,16(sp)
    80004d1a:	6161                	addi	sp,sp,80
    80004d1c:	8082                	ret
      release(&pi->lock);
    80004d1e:	8526                	mv	a0,s1
    80004d20:	ffffc097          	auipc	ra,0xffffc
    80004d24:	fa0080e7          	jalr	-96(ra) # 80000cc0 <release>
      return -1;
    80004d28:	59fd                	li	s3,-1
    80004d2a:	bff9                	j	80004d08 <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d2c:	4981                	li	s3,0
    80004d2e:	b7d1                	j	80004cf2 <piperead+0xb4>

0000000080004d30 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004d30:	1141                	addi	sp,sp,-16
    80004d32:	e422                	sd	s0,8(sp)
    80004d34:	0800                	addi	s0,sp,16
    80004d36:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004d38:	8905                	andi	a0,a0,1
    80004d3a:	c111                	beqz	a0,80004d3e <flags2perm+0xe>
      perm = PTE_X;
    80004d3c:	4521                	li	a0,8
    if(flags & 0x2)
    80004d3e:	8b89                	andi	a5,a5,2
    80004d40:	c399                	beqz	a5,80004d46 <flags2perm+0x16>
      perm |= PTE_W;
    80004d42:	00456513          	ori	a0,a0,4
    return perm;
}
    80004d46:	6422                	ld	s0,8(sp)
    80004d48:	0141                	addi	sp,sp,16
    80004d4a:	8082                	ret

0000000080004d4c <exec>:

int
exec(char *path, char **argv)
{
    80004d4c:	df010113          	addi	sp,sp,-528
    80004d50:	20113423          	sd	ra,520(sp)
    80004d54:	20813023          	sd	s0,512(sp)
    80004d58:	ffa6                	sd	s1,504(sp)
    80004d5a:	fbca                	sd	s2,496(sp)
    80004d5c:	f7ce                	sd	s3,488(sp)
    80004d5e:	f3d2                	sd	s4,480(sp)
    80004d60:	efd6                	sd	s5,472(sp)
    80004d62:	ebda                	sd	s6,464(sp)
    80004d64:	e7de                	sd	s7,456(sp)
    80004d66:	e3e2                	sd	s8,448(sp)
    80004d68:	ff66                	sd	s9,440(sp)
    80004d6a:	fb6a                	sd	s10,432(sp)
    80004d6c:	f76e                	sd	s11,424(sp)
    80004d6e:	0c00                	addi	s0,sp,528
    80004d70:	84aa                	mv	s1,a0
    80004d72:	dea43c23          	sd	a0,-520(s0)
    80004d76:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d7a:	ffffd097          	auipc	ra,0xffffd
    80004d7e:	c6e080e7          	jalr	-914(ra) # 800019e8 <myproc>
    80004d82:	892a                	mv	s2,a0

  begin_op();
    80004d84:	fffff097          	auipc	ra,0xfffff
    80004d88:	474080e7          	jalr	1140(ra) # 800041f8 <begin_op>

  if((ip = namei(path)) == 0){
    80004d8c:	8526                	mv	a0,s1
    80004d8e:	fffff097          	auipc	ra,0xfffff
    80004d92:	24e080e7          	jalr	590(ra) # 80003fdc <namei>
    80004d96:	c92d                	beqz	a0,80004e08 <exec+0xbc>
    80004d98:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d9a:	fffff097          	auipc	ra,0xfffff
    80004d9e:	a9c080e7          	jalr	-1380(ra) # 80003836 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004da2:	04000713          	li	a4,64
    80004da6:	4681                	li	a3,0
    80004da8:	e5040613          	addi	a2,s0,-432
    80004dac:	4581                	li	a1,0
    80004dae:	8526                	mv	a0,s1
    80004db0:	fffff097          	auipc	ra,0xfffff
    80004db4:	d3a080e7          	jalr	-710(ra) # 80003aea <readi>
    80004db8:	04000793          	li	a5,64
    80004dbc:	00f51a63          	bne	a0,a5,80004dd0 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004dc0:	e5042703          	lw	a4,-432(s0)
    80004dc4:	464c47b7          	lui	a5,0x464c4
    80004dc8:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004dcc:	04f70463          	beq	a4,a5,80004e14 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004dd0:	8526                	mv	a0,s1
    80004dd2:	fffff097          	auipc	ra,0xfffff
    80004dd6:	cc6080e7          	jalr	-826(ra) # 80003a98 <iunlockput>
    end_op();
    80004dda:	fffff097          	auipc	ra,0xfffff
    80004dde:	49e080e7          	jalr	1182(ra) # 80004278 <end_op>
  }
  return -1;
    80004de2:	557d                	li	a0,-1
}
    80004de4:	20813083          	ld	ra,520(sp)
    80004de8:	20013403          	ld	s0,512(sp)
    80004dec:	74fe                	ld	s1,504(sp)
    80004dee:	795e                	ld	s2,496(sp)
    80004df0:	79be                	ld	s3,488(sp)
    80004df2:	7a1e                	ld	s4,480(sp)
    80004df4:	6afe                	ld	s5,472(sp)
    80004df6:	6b5e                	ld	s6,464(sp)
    80004df8:	6bbe                	ld	s7,456(sp)
    80004dfa:	6c1e                	ld	s8,448(sp)
    80004dfc:	7cfa                	ld	s9,440(sp)
    80004dfe:	7d5a                	ld	s10,432(sp)
    80004e00:	7dba                	ld	s11,424(sp)
    80004e02:	21010113          	addi	sp,sp,528
    80004e06:	8082                	ret
    end_op();
    80004e08:	fffff097          	auipc	ra,0xfffff
    80004e0c:	470080e7          	jalr	1136(ra) # 80004278 <end_op>
    return -1;
    80004e10:	557d                	li	a0,-1
    80004e12:	bfc9                	j	80004de4 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e14:	854a                	mv	a0,s2
    80004e16:	ffffd097          	auipc	ra,0xffffd
    80004e1a:	c96080e7          	jalr	-874(ra) # 80001aac <proc_pagetable>
    80004e1e:	8baa                	mv	s7,a0
    80004e20:	d945                	beqz	a0,80004dd0 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e22:	e7042983          	lw	s3,-400(s0)
    80004e26:	e8845783          	lhu	a5,-376(s0)
    80004e2a:	c7ad                	beqz	a5,80004e94 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e2c:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e2e:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004e30:	6c85                	lui	s9,0x1
    80004e32:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004e36:	def43823          	sd	a5,-528(s0)
    80004e3a:	ac0d                	j	8000506c <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e3c:	00004517          	auipc	a0,0x4
    80004e40:	8fc50513          	addi	a0,a0,-1796 # 80008738 <syscalls+0x298>
    80004e44:	ffffb097          	auipc	ra,0xffffb
    80004e48:	700080e7          	jalr	1792(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e4c:	8756                	mv	a4,s5
    80004e4e:	012d86bb          	addw	a3,s11,s2
    80004e52:	4581                	li	a1,0
    80004e54:	8526                	mv	a0,s1
    80004e56:	fffff097          	auipc	ra,0xfffff
    80004e5a:	c94080e7          	jalr	-876(ra) # 80003aea <readi>
    80004e5e:	2501                	sext.w	a0,a0
    80004e60:	1aaa9a63          	bne	s5,a0,80005014 <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    80004e64:	6785                	lui	a5,0x1
    80004e66:	0127893b          	addw	s2,a5,s2
    80004e6a:	77fd                	lui	a5,0xfffff
    80004e6c:	01478a3b          	addw	s4,a5,s4
    80004e70:	1f897563          	bgeu	s2,s8,8000505a <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    80004e74:	02091593          	slli	a1,s2,0x20
    80004e78:	9181                	srli	a1,a1,0x20
    80004e7a:	95ea                	add	a1,a1,s10
    80004e7c:	855e                	mv	a0,s7
    80004e7e:	ffffc097          	auipc	ra,0xffffc
    80004e82:	21c080e7          	jalr	540(ra) # 8000109a <walkaddr>
    80004e86:	862a                	mv	a2,a0
    if(pa == 0)
    80004e88:	d955                	beqz	a0,80004e3c <exec+0xf0>
      n = PGSIZE;
    80004e8a:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004e8c:	fd9a70e3          	bgeu	s4,s9,80004e4c <exec+0x100>
      n = sz - i;
    80004e90:	8ad2                	mv	s5,s4
    80004e92:	bf6d                	j	80004e4c <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e94:	4a01                	li	s4,0
  iunlockput(ip);
    80004e96:	8526                	mv	a0,s1
    80004e98:	fffff097          	auipc	ra,0xfffff
    80004e9c:	c00080e7          	jalr	-1024(ra) # 80003a98 <iunlockput>
  end_op();
    80004ea0:	fffff097          	auipc	ra,0xfffff
    80004ea4:	3d8080e7          	jalr	984(ra) # 80004278 <end_op>
  p = myproc();
    80004ea8:	ffffd097          	auipc	ra,0xffffd
    80004eac:	b40080e7          	jalr	-1216(ra) # 800019e8 <myproc>
    80004eb0:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004eb2:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004eb6:	6785                	lui	a5,0x1
    80004eb8:	17fd                	addi	a5,a5,-1
    80004eba:	9a3e                	add	s4,s4,a5
    80004ebc:	757d                	lui	a0,0xfffff
    80004ebe:	00aa77b3          	and	a5,s4,a0
    80004ec2:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004ec6:	4691                	li	a3,4
    80004ec8:	6609                	lui	a2,0x2
    80004eca:	963e                	add	a2,a2,a5
    80004ecc:	85be                	mv	a1,a5
    80004ece:	855e                	mv	a0,s7
    80004ed0:	ffffc097          	auipc	ra,0xffffc
    80004ed4:	57e080e7          	jalr	1406(ra) # 8000144e <uvmalloc>
    80004ed8:	8b2a                	mv	s6,a0
  ip = 0;
    80004eda:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004edc:	12050c63          	beqz	a0,80005014 <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004ee0:	75f9                	lui	a1,0xffffe
    80004ee2:	95aa                	add	a1,a1,a0
    80004ee4:	855e                	mv	a0,s7
    80004ee6:	ffffc097          	auipc	ra,0xffffc
    80004eea:	78e080e7          	jalr	1934(ra) # 80001674 <uvmclear>
  stackbase = sp - PGSIZE;
    80004eee:	7c7d                	lui	s8,0xfffff
    80004ef0:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ef2:	e0043783          	ld	a5,-512(s0)
    80004ef6:	6388                	ld	a0,0(a5)
    80004ef8:	c535                	beqz	a0,80004f64 <exec+0x218>
    80004efa:	e9040993          	addi	s3,s0,-368
    80004efe:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004f02:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004f04:	ffffc097          	auipc	ra,0xffffc
    80004f08:	f88080e7          	jalr	-120(ra) # 80000e8c <strlen>
    80004f0c:	2505                	addiw	a0,a0,1
    80004f0e:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f12:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f16:	13896663          	bltu	s2,s8,80005042 <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f1a:	e0043d83          	ld	s11,-512(s0)
    80004f1e:	000dba03          	ld	s4,0(s11)
    80004f22:	8552                	mv	a0,s4
    80004f24:	ffffc097          	auipc	ra,0xffffc
    80004f28:	f68080e7          	jalr	-152(ra) # 80000e8c <strlen>
    80004f2c:	0015069b          	addiw	a3,a0,1
    80004f30:	8652                	mv	a2,s4
    80004f32:	85ca                	mv	a1,s2
    80004f34:	855e                	mv	a0,s7
    80004f36:	ffffc097          	auipc	ra,0xffffc
    80004f3a:	770080e7          	jalr	1904(ra) # 800016a6 <copyout>
    80004f3e:	10054663          	bltz	a0,8000504a <exec+0x2fe>
    ustack[argc] = sp;
    80004f42:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f46:	0485                	addi	s1,s1,1
    80004f48:	008d8793          	addi	a5,s11,8
    80004f4c:	e0f43023          	sd	a5,-512(s0)
    80004f50:	008db503          	ld	a0,8(s11)
    80004f54:	c911                	beqz	a0,80004f68 <exec+0x21c>
    if(argc >= MAXARG)
    80004f56:	09a1                	addi	s3,s3,8
    80004f58:	fb3c96e3          	bne	s9,s3,80004f04 <exec+0x1b8>
  sz = sz1;
    80004f5c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f60:	4481                	li	s1,0
    80004f62:	a84d                	j	80005014 <exec+0x2c8>
  sp = sz;
    80004f64:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f66:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f68:	00349793          	slli	a5,s1,0x3
    80004f6c:	f9040713          	addi	a4,s0,-112
    80004f70:	97ba                	add	a5,a5,a4
    80004f72:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004f76:	00148693          	addi	a3,s1,1
    80004f7a:	068e                	slli	a3,a3,0x3
    80004f7c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f80:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f84:	01897663          	bgeu	s2,s8,80004f90 <exec+0x244>
  sz = sz1;
    80004f88:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f8c:	4481                	li	s1,0
    80004f8e:	a059                	j	80005014 <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f90:	e9040613          	addi	a2,s0,-368
    80004f94:	85ca                	mv	a1,s2
    80004f96:	855e                	mv	a0,s7
    80004f98:	ffffc097          	auipc	ra,0xffffc
    80004f9c:	70e080e7          	jalr	1806(ra) # 800016a6 <copyout>
    80004fa0:	0a054963          	bltz	a0,80005052 <exec+0x306>
  p->trapframe->a1 = sp;
    80004fa4:	058ab783          	ld	a5,88(s5)
    80004fa8:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004fac:	df843783          	ld	a5,-520(s0)
    80004fb0:	0007c703          	lbu	a4,0(a5)
    80004fb4:	cf11                	beqz	a4,80004fd0 <exec+0x284>
    80004fb6:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004fb8:	02f00693          	li	a3,47
    80004fbc:	a039                	j	80004fca <exec+0x27e>
      last = s+1;
    80004fbe:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004fc2:	0785                	addi	a5,a5,1
    80004fc4:	fff7c703          	lbu	a4,-1(a5)
    80004fc8:	c701                	beqz	a4,80004fd0 <exec+0x284>
    if(*s == '/')
    80004fca:	fed71ce3          	bne	a4,a3,80004fc2 <exec+0x276>
    80004fce:	bfc5                	j	80004fbe <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    80004fd0:	4641                	li	a2,16
    80004fd2:	df843583          	ld	a1,-520(s0)
    80004fd6:	158a8513          	addi	a0,s5,344
    80004fda:	ffffc097          	auipc	ra,0xffffc
    80004fde:	e80080e7          	jalr	-384(ra) # 80000e5a <safestrcpy>
  oldpagetable = p->pagetable;
    80004fe2:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004fe6:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004fea:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004fee:	058ab783          	ld	a5,88(s5)
    80004ff2:	e6843703          	ld	a4,-408(s0)
    80004ff6:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004ff8:	058ab783          	ld	a5,88(s5)
    80004ffc:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005000:	85ea                	mv	a1,s10
    80005002:	ffffd097          	auipc	ra,0xffffd
    80005006:	b46080e7          	jalr	-1210(ra) # 80001b48 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000500a:	0004851b          	sext.w	a0,s1
    8000500e:	bbd9                	j	80004de4 <exec+0x98>
    80005010:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005014:	e0843583          	ld	a1,-504(s0)
    80005018:	855e                	mv	a0,s7
    8000501a:	ffffd097          	auipc	ra,0xffffd
    8000501e:	b2e080e7          	jalr	-1234(ra) # 80001b48 <proc_freepagetable>
  if(ip){
    80005022:	da0497e3          	bnez	s1,80004dd0 <exec+0x84>
  return -1;
    80005026:	557d                	li	a0,-1
    80005028:	bb75                	j	80004de4 <exec+0x98>
    8000502a:	e1443423          	sd	s4,-504(s0)
    8000502e:	b7dd                	j	80005014 <exec+0x2c8>
    80005030:	e1443423          	sd	s4,-504(s0)
    80005034:	b7c5                	j	80005014 <exec+0x2c8>
    80005036:	e1443423          	sd	s4,-504(s0)
    8000503a:	bfe9                	j	80005014 <exec+0x2c8>
    8000503c:	e1443423          	sd	s4,-504(s0)
    80005040:	bfd1                	j	80005014 <exec+0x2c8>
  sz = sz1;
    80005042:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005046:	4481                	li	s1,0
    80005048:	b7f1                	j	80005014 <exec+0x2c8>
  sz = sz1;
    8000504a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000504e:	4481                	li	s1,0
    80005050:	b7d1                	j	80005014 <exec+0x2c8>
  sz = sz1;
    80005052:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005056:	4481                	li	s1,0
    80005058:	bf75                	j	80005014 <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000505a:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000505e:	2b05                	addiw	s6,s6,1
    80005060:	0389899b          	addiw	s3,s3,56
    80005064:	e8845783          	lhu	a5,-376(s0)
    80005068:	e2fb57e3          	bge	s6,a5,80004e96 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000506c:	2981                	sext.w	s3,s3
    8000506e:	03800713          	li	a4,56
    80005072:	86ce                	mv	a3,s3
    80005074:	e1840613          	addi	a2,s0,-488
    80005078:	4581                	li	a1,0
    8000507a:	8526                	mv	a0,s1
    8000507c:	fffff097          	auipc	ra,0xfffff
    80005080:	a6e080e7          	jalr	-1426(ra) # 80003aea <readi>
    80005084:	03800793          	li	a5,56
    80005088:	f8f514e3          	bne	a0,a5,80005010 <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    8000508c:	e1842783          	lw	a5,-488(s0)
    80005090:	4705                	li	a4,1
    80005092:	fce796e3          	bne	a5,a4,8000505e <exec+0x312>
    if(ph.memsz < ph.filesz)
    80005096:	e4043903          	ld	s2,-448(s0)
    8000509a:	e3843783          	ld	a5,-456(s0)
    8000509e:	f8f966e3          	bltu	s2,a5,8000502a <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800050a2:	e2843783          	ld	a5,-472(s0)
    800050a6:	993e                	add	s2,s2,a5
    800050a8:	f8f964e3          	bltu	s2,a5,80005030 <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    800050ac:	df043703          	ld	a4,-528(s0)
    800050b0:	8ff9                	and	a5,a5,a4
    800050b2:	f3d1                	bnez	a5,80005036 <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800050b4:	e1c42503          	lw	a0,-484(s0)
    800050b8:	00000097          	auipc	ra,0x0
    800050bc:	c78080e7          	jalr	-904(ra) # 80004d30 <flags2perm>
    800050c0:	86aa                	mv	a3,a0
    800050c2:	864a                	mv	a2,s2
    800050c4:	85d2                	mv	a1,s4
    800050c6:	855e                	mv	a0,s7
    800050c8:	ffffc097          	auipc	ra,0xffffc
    800050cc:	386080e7          	jalr	902(ra) # 8000144e <uvmalloc>
    800050d0:	e0a43423          	sd	a0,-504(s0)
    800050d4:	d525                	beqz	a0,8000503c <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800050d6:	e2843d03          	ld	s10,-472(s0)
    800050da:	e2042d83          	lw	s11,-480(s0)
    800050de:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800050e2:	f60c0ce3          	beqz	s8,8000505a <exec+0x30e>
    800050e6:	8a62                	mv	s4,s8
    800050e8:	4901                	li	s2,0
    800050ea:	b369                	j	80004e74 <exec+0x128>

00000000800050ec <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800050ec:	7179                	addi	sp,sp,-48
    800050ee:	f406                	sd	ra,40(sp)
    800050f0:	f022                	sd	s0,32(sp)
    800050f2:	ec26                	sd	s1,24(sp)
    800050f4:	e84a                	sd	s2,16(sp)
    800050f6:	1800                	addi	s0,sp,48
    800050f8:	892e                	mv	s2,a1
    800050fa:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800050fc:	fdc40593          	addi	a1,s0,-36
    80005100:	ffffe097          	auipc	ra,0xffffe
    80005104:	b38080e7          	jalr	-1224(ra) # 80002c38 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005108:	fdc42703          	lw	a4,-36(s0)
    8000510c:	47bd                	li	a5,15
    8000510e:	02e7eb63          	bltu	a5,a4,80005144 <argfd+0x58>
    80005112:	ffffd097          	auipc	ra,0xffffd
    80005116:	8d6080e7          	jalr	-1834(ra) # 800019e8 <myproc>
    8000511a:	fdc42703          	lw	a4,-36(s0)
    8000511e:	01a70793          	addi	a5,a4,26
    80005122:	078e                	slli	a5,a5,0x3
    80005124:	953e                	add	a0,a0,a5
    80005126:	611c                	ld	a5,0(a0)
    80005128:	c385                	beqz	a5,80005148 <argfd+0x5c>
    return -1;
  if(pfd)
    8000512a:	00090463          	beqz	s2,80005132 <argfd+0x46>
    *pfd = fd;
    8000512e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005132:	4501                	li	a0,0
  if(pf)
    80005134:	c091                	beqz	s1,80005138 <argfd+0x4c>
    *pf = f;
    80005136:	e09c                	sd	a5,0(s1)
}
    80005138:	70a2                	ld	ra,40(sp)
    8000513a:	7402                	ld	s0,32(sp)
    8000513c:	64e2                	ld	s1,24(sp)
    8000513e:	6942                	ld	s2,16(sp)
    80005140:	6145                	addi	sp,sp,48
    80005142:	8082                	ret
    return -1;
    80005144:	557d                	li	a0,-1
    80005146:	bfcd                	j	80005138 <argfd+0x4c>
    80005148:	557d                	li	a0,-1
    8000514a:	b7fd                	j	80005138 <argfd+0x4c>

000000008000514c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000514c:	1101                	addi	sp,sp,-32
    8000514e:	ec06                	sd	ra,24(sp)
    80005150:	e822                	sd	s0,16(sp)
    80005152:	e426                	sd	s1,8(sp)
    80005154:	1000                	addi	s0,sp,32
    80005156:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005158:	ffffd097          	auipc	ra,0xffffd
    8000515c:	890080e7          	jalr	-1904(ra) # 800019e8 <myproc>
    80005160:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005162:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffdd200>
    80005166:	4501                	li	a0,0
    80005168:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000516a:	6398                	ld	a4,0(a5)
    8000516c:	cb19                	beqz	a4,80005182 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000516e:	2505                	addiw	a0,a0,1
    80005170:	07a1                	addi	a5,a5,8
    80005172:	fed51ce3          	bne	a0,a3,8000516a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005176:	557d                	li	a0,-1
}
    80005178:	60e2                	ld	ra,24(sp)
    8000517a:	6442                	ld	s0,16(sp)
    8000517c:	64a2                	ld	s1,8(sp)
    8000517e:	6105                	addi	sp,sp,32
    80005180:	8082                	ret
      p->ofile[fd] = f;
    80005182:	01a50793          	addi	a5,a0,26
    80005186:	078e                	slli	a5,a5,0x3
    80005188:	963e                	add	a2,a2,a5
    8000518a:	e204                	sd	s1,0(a2)
      return fd;
    8000518c:	b7f5                	j	80005178 <fdalloc+0x2c>

000000008000518e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000518e:	715d                	addi	sp,sp,-80
    80005190:	e486                	sd	ra,72(sp)
    80005192:	e0a2                	sd	s0,64(sp)
    80005194:	fc26                	sd	s1,56(sp)
    80005196:	f84a                	sd	s2,48(sp)
    80005198:	f44e                	sd	s3,40(sp)
    8000519a:	f052                	sd	s4,32(sp)
    8000519c:	ec56                	sd	s5,24(sp)
    8000519e:	e85a                	sd	s6,16(sp)
    800051a0:	0880                	addi	s0,sp,80
    800051a2:	8b2e                	mv	s6,a1
    800051a4:	89b2                	mv	s3,a2
    800051a6:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800051a8:	fb040593          	addi	a1,s0,-80
    800051ac:	fffff097          	auipc	ra,0xfffff
    800051b0:	e4e080e7          	jalr	-434(ra) # 80003ffa <nameiparent>
    800051b4:	84aa                	mv	s1,a0
    800051b6:	16050063          	beqz	a0,80005316 <create+0x188>
    return 0;

  ilock(dp);
    800051ba:	ffffe097          	auipc	ra,0xffffe
    800051be:	67c080e7          	jalr	1660(ra) # 80003836 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800051c2:	4601                	li	a2,0
    800051c4:	fb040593          	addi	a1,s0,-80
    800051c8:	8526                	mv	a0,s1
    800051ca:	fffff097          	auipc	ra,0xfffff
    800051ce:	b50080e7          	jalr	-1200(ra) # 80003d1a <dirlookup>
    800051d2:	8aaa                	mv	s5,a0
    800051d4:	c931                	beqz	a0,80005228 <create+0x9a>
    iunlockput(dp);
    800051d6:	8526                	mv	a0,s1
    800051d8:	fffff097          	auipc	ra,0xfffff
    800051dc:	8c0080e7          	jalr	-1856(ra) # 80003a98 <iunlockput>
    ilock(ip);
    800051e0:	8556                	mv	a0,s5
    800051e2:	ffffe097          	auipc	ra,0xffffe
    800051e6:	654080e7          	jalr	1620(ra) # 80003836 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800051ea:	000b059b          	sext.w	a1,s6
    800051ee:	4789                	li	a5,2
    800051f0:	02f59563          	bne	a1,a5,8000521a <create+0x8c>
    800051f4:	044ad783          	lhu	a5,68(s5)
    800051f8:	37f9                	addiw	a5,a5,-2
    800051fa:	17c2                	slli	a5,a5,0x30
    800051fc:	93c1                	srli	a5,a5,0x30
    800051fe:	4705                	li	a4,1
    80005200:	00f76d63          	bltu	a4,a5,8000521a <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005204:	8556                	mv	a0,s5
    80005206:	60a6                	ld	ra,72(sp)
    80005208:	6406                	ld	s0,64(sp)
    8000520a:	74e2                	ld	s1,56(sp)
    8000520c:	7942                	ld	s2,48(sp)
    8000520e:	79a2                	ld	s3,40(sp)
    80005210:	7a02                	ld	s4,32(sp)
    80005212:	6ae2                	ld	s5,24(sp)
    80005214:	6b42                	ld	s6,16(sp)
    80005216:	6161                	addi	sp,sp,80
    80005218:	8082                	ret
    iunlockput(ip);
    8000521a:	8556                	mv	a0,s5
    8000521c:	fffff097          	auipc	ra,0xfffff
    80005220:	87c080e7          	jalr	-1924(ra) # 80003a98 <iunlockput>
    return 0;
    80005224:	4a81                	li	s5,0
    80005226:	bff9                	j	80005204 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005228:	85da                	mv	a1,s6
    8000522a:	4088                	lw	a0,0(s1)
    8000522c:	ffffe097          	auipc	ra,0xffffe
    80005230:	46e080e7          	jalr	1134(ra) # 8000369a <ialloc>
    80005234:	8a2a                	mv	s4,a0
    80005236:	c921                	beqz	a0,80005286 <create+0xf8>
  ilock(ip);
    80005238:	ffffe097          	auipc	ra,0xffffe
    8000523c:	5fe080e7          	jalr	1534(ra) # 80003836 <ilock>
  ip->major = major;
    80005240:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005244:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005248:	4785                	li	a5,1
    8000524a:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    8000524e:	8552                	mv	a0,s4
    80005250:	ffffe097          	auipc	ra,0xffffe
    80005254:	51c080e7          	jalr	1308(ra) # 8000376c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005258:	000b059b          	sext.w	a1,s6
    8000525c:	4785                	li	a5,1
    8000525e:	02f58b63          	beq	a1,a5,80005294 <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    80005262:	004a2603          	lw	a2,4(s4)
    80005266:	fb040593          	addi	a1,s0,-80
    8000526a:	8526                	mv	a0,s1
    8000526c:	fffff097          	auipc	ra,0xfffff
    80005270:	cbe080e7          	jalr	-834(ra) # 80003f2a <dirlink>
    80005274:	06054f63          	bltz	a0,800052f2 <create+0x164>
  iunlockput(dp);
    80005278:	8526                	mv	a0,s1
    8000527a:	fffff097          	auipc	ra,0xfffff
    8000527e:	81e080e7          	jalr	-2018(ra) # 80003a98 <iunlockput>
  return ip;
    80005282:	8ad2                	mv	s5,s4
    80005284:	b741                	j	80005204 <create+0x76>
    iunlockput(dp);
    80005286:	8526                	mv	a0,s1
    80005288:	fffff097          	auipc	ra,0xfffff
    8000528c:	810080e7          	jalr	-2032(ra) # 80003a98 <iunlockput>
    return 0;
    80005290:	8ad2                	mv	s5,s4
    80005292:	bf8d                	j	80005204 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005294:	004a2603          	lw	a2,4(s4)
    80005298:	00003597          	auipc	a1,0x3
    8000529c:	4c058593          	addi	a1,a1,1216 # 80008758 <syscalls+0x2b8>
    800052a0:	8552                	mv	a0,s4
    800052a2:	fffff097          	auipc	ra,0xfffff
    800052a6:	c88080e7          	jalr	-888(ra) # 80003f2a <dirlink>
    800052aa:	04054463          	bltz	a0,800052f2 <create+0x164>
    800052ae:	40d0                	lw	a2,4(s1)
    800052b0:	00003597          	auipc	a1,0x3
    800052b4:	4b058593          	addi	a1,a1,1200 # 80008760 <syscalls+0x2c0>
    800052b8:	8552                	mv	a0,s4
    800052ba:	fffff097          	auipc	ra,0xfffff
    800052be:	c70080e7          	jalr	-912(ra) # 80003f2a <dirlink>
    800052c2:	02054863          	bltz	a0,800052f2 <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    800052c6:	004a2603          	lw	a2,4(s4)
    800052ca:	fb040593          	addi	a1,s0,-80
    800052ce:	8526                	mv	a0,s1
    800052d0:	fffff097          	auipc	ra,0xfffff
    800052d4:	c5a080e7          	jalr	-934(ra) # 80003f2a <dirlink>
    800052d8:	00054d63          	bltz	a0,800052f2 <create+0x164>
    dp->nlink++;  // for ".."
    800052dc:	04a4d783          	lhu	a5,74(s1)
    800052e0:	2785                	addiw	a5,a5,1
    800052e2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800052e6:	8526                	mv	a0,s1
    800052e8:	ffffe097          	auipc	ra,0xffffe
    800052ec:	484080e7          	jalr	1156(ra) # 8000376c <iupdate>
    800052f0:	b761                	j	80005278 <create+0xea>
  ip->nlink = 0;
    800052f2:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800052f6:	8552                	mv	a0,s4
    800052f8:	ffffe097          	auipc	ra,0xffffe
    800052fc:	474080e7          	jalr	1140(ra) # 8000376c <iupdate>
  iunlockput(ip);
    80005300:	8552                	mv	a0,s4
    80005302:	ffffe097          	auipc	ra,0xffffe
    80005306:	796080e7          	jalr	1942(ra) # 80003a98 <iunlockput>
  iunlockput(dp);
    8000530a:	8526                	mv	a0,s1
    8000530c:	ffffe097          	auipc	ra,0xffffe
    80005310:	78c080e7          	jalr	1932(ra) # 80003a98 <iunlockput>
  return 0;
    80005314:	bdc5                	j	80005204 <create+0x76>
    return 0;
    80005316:	8aaa                	mv	s5,a0
    80005318:	b5f5                	j	80005204 <create+0x76>

000000008000531a <sys_dup>:
{
    8000531a:	7179                	addi	sp,sp,-48
    8000531c:	f406                	sd	ra,40(sp)
    8000531e:	f022                	sd	s0,32(sp)
    80005320:	ec26                	sd	s1,24(sp)
    80005322:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005324:	fd840613          	addi	a2,s0,-40
    80005328:	4581                	li	a1,0
    8000532a:	4501                	li	a0,0
    8000532c:	00000097          	auipc	ra,0x0
    80005330:	dc0080e7          	jalr	-576(ra) # 800050ec <argfd>
    return -1;
    80005334:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005336:	02054363          	bltz	a0,8000535c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000533a:	fd843503          	ld	a0,-40(s0)
    8000533e:	00000097          	auipc	ra,0x0
    80005342:	e0e080e7          	jalr	-498(ra) # 8000514c <fdalloc>
    80005346:	84aa                	mv	s1,a0
    return -1;
    80005348:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000534a:	00054963          	bltz	a0,8000535c <sys_dup+0x42>
  filedup(f);
    8000534e:	fd843503          	ld	a0,-40(s0)
    80005352:	fffff097          	auipc	ra,0xfffff
    80005356:	320080e7          	jalr	800(ra) # 80004672 <filedup>
  return fd;
    8000535a:	87a6                	mv	a5,s1
}
    8000535c:	853e                	mv	a0,a5
    8000535e:	70a2                	ld	ra,40(sp)
    80005360:	7402                	ld	s0,32(sp)
    80005362:	64e2                	ld	s1,24(sp)
    80005364:	6145                	addi	sp,sp,48
    80005366:	8082                	ret

0000000080005368 <sys_read>:
{
    80005368:	7179                	addi	sp,sp,-48
    8000536a:	f406                	sd	ra,40(sp)
    8000536c:	f022                	sd	s0,32(sp)
    8000536e:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005370:	fd840593          	addi	a1,s0,-40
    80005374:	4505                	li	a0,1
    80005376:	ffffe097          	auipc	ra,0xffffe
    8000537a:	8e2080e7          	jalr	-1822(ra) # 80002c58 <argaddr>
  argint(2, &n);
    8000537e:	fe440593          	addi	a1,s0,-28
    80005382:	4509                	li	a0,2
    80005384:	ffffe097          	auipc	ra,0xffffe
    80005388:	8b4080e7          	jalr	-1868(ra) # 80002c38 <argint>
  if(argfd(0, 0, &f) < 0)
    8000538c:	fe840613          	addi	a2,s0,-24
    80005390:	4581                	li	a1,0
    80005392:	4501                	li	a0,0
    80005394:	00000097          	auipc	ra,0x0
    80005398:	d58080e7          	jalr	-680(ra) # 800050ec <argfd>
    8000539c:	87aa                	mv	a5,a0
    return -1;
    8000539e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800053a0:	0007cc63          	bltz	a5,800053b8 <sys_read+0x50>
  return fileread(f, p, n);
    800053a4:	fe442603          	lw	a2,-28(s0)
    800053a8:	fd843583          	ld	a1,-40(s0)
    800053ac:	fe843503          	ld	a0,-24(s0)
    800053b0:	fffff097          	auipc	ra,0xfffff
    800053b4:	44e080e7          	jalr	1102(ra) # 800047fe <fileread>
}
    800053b8:	70a2                	ld	ra,40(sp)
    800053ba:	7402                	ld	s0,32(sp)
    800053bc:	6145                	addi	sp,sp,48
    800053be:	8082                	ret

00000000800053c0 <sys_write>:
{
    800053c0:	7179                	addi	sp,sp,-48
    800053c2:	f406                	sd	ra,40(sp)
    800053c4:	f022                	sd	s0,32(sp)
    800053c6:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800053c8:	fd840593          	addi	a1,s0,-40
    800053cc:	4505                	li	a0,1
    800053ce:	ffffe097          	auipc	ra,0xffffe
    800053d2:	88a080e7          	jalr	-1910(ra) # 80002c58 <argaddr>
  argint(2, &n);
    800053d6:	fe440593          	addi	a1,s0,-28
    800053da:	4509                	li	a0,2
    800053dc:	ffffe097          	auipc	ra,0xffffe
    800053e0:	85c080e7          	jalr	-1956(ra) # 80002c38 <argint>
  if(argfd(0, 0, &f) < 0)
    800053e4:	fe840613          	addi	a2,s0,-24
    800053e8:	4581                	li	a1,0
    800053ea:	4501                	li	a0,0
    800053ec:	00000097          	auipc	ra,0x0
    800053f0:	d00080e7          	jalr	-768(ra) # 800050ec <argfd>
    800053f4:	87aa                	mv	a5,a0
    return -1;
    800053f6:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800053f8:	0007cc63          	bltz	a5,80005410 <sys_write+0x50>
  return filewrite(f, p, n);
    800053fc:	fe442603          	lw	a2,-28(s0)
    80005400:	fd843583          	ld	a1,-40(s0)
    80005404:	fe843503          	ld	a0,-24(s0)
    80005408:	fffff097          	auipc	ra,0xfffff
    8000540c:	4b8080e7          	jalr	1208(ra) # 800048c0 <filewrite>
}
    80005410:	70a2                	ld	ra,40(sp)
    80005412:	7402                	ld	s0,32(sp)
    80005414:	6145                	addi	sp,sp,48
    80005416:	8082                	ret

0000000080005418 <sys_close>:
{
    80005418:	1101                	addi	sp,sp,-32
    8000541a:	ec06                	sd	ra,24(sp)
    8000541c:	e822                	sd	s0,16(sp)
    8000541e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005420:	fe040613          	addi	a2,s0,-32
    80005424:	fec40593          	addi	a1,s0,-20
    80005428:	4501                	li	a0,0
    8000542a:	00000097          	auipc	ra,0x0
    8000542e:	cc2080e7          	jalr	-830(ra) # 800050ec <argfd>
    return -1;
    80005432:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005434:	02054463          	bltz	a0,8000545c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005438:	ffffc097          	auipc	ra,0xffffc
    8000543c:	5b0080e7          	jalr	1456(ra) # 800019e8 <myproc>
    80005440:	fec42783          	lw	a5,-20(s0)
    80005444:	07e9                	addi	a5,a5,26
    80005446:	078e                	slli	a5,a5,0x3
    80005448:	97aa                	add	a5,a5,a0
    8000544a:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000544e:	fe043503          	ld	a0,-32(s0)
    80005452:	fffff097          	auipc	ra,0xfffff
    80005456:	272080e7          	jalr	626(ra) # 800046c4 <fileclose>
  return 0;
    8000545a:	4781                	li	a5,0
}
    8000545c:	853e                	mv	a0,a5
    8000545e:	60e2                	ld	ra,24(sp)
    80005460:	6442                	ld	s0,16(sp)
    80005462:	6105                	addi	sp,sp,32
    80005464:	8082                	ret

0000000080005466 <sys_fstat>:
{
    80005466:	1101                	addi	sp,sp,-32
    80005468:	ec06                	sd	ra,24(sp)
    8000546a:	e822                	sd	s0,16(sp)
    8000546c:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    8000546e:	fe040593          	addi	a1,s0,-32
    80005472:	4505                	li	a0,1
    80005474:	ffffd097          	auipc	ra,0xffffd
    80005478:	7e4080e7          	jalr	2020(ra) # 80002c58 <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000547c:	fe840613          	addi	a2,s0,-24
    80005480:	4581                	li	a1,0
    80005482:	4501                	li	a0,0
    80005484:	00000097          	auipc	ra,0x0
    80005488:	c68080e7          	jalr	-920(ra) # 800050ec <argfd>
    8000548c:	87aa                	mv	a5,a0
    return -1;
    8000548e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005490:	0007ca63          	bltz	a5,800054a4 <sys_fstat+0x3e>
  return filestat(f, st);
    80005494:	fe043583          	ld	a1,-32(s0)
    80005498:	fe843503          	ld	a0,-24(s0)
    8000549c:	fffff097          	auipc	ra,0xfffff
    800054a0:	2f0080e7          	jalr	752(ra) # 8000478c <filestat>
}
    800054a4:	60e2                	ld	ra,24(sp)
    800054a6:	6442                	ld	s0,16(sp)
    800054a8:	6105                	addi	sp,sp,32
    800054aa:	8082                	ret

00000000800054ac <sys_link>:
{
    800054ac:	7169                	addi	sp,sp,-304
    800054ae:	f606                	sd	ra,296(sp)
    800054b0:	f222                	sd	s0,288(sp)
    800054b2:	ee26                	sd	s1,280(sp)
    800054b4:	ea4a                	sd	s2,272(sp)
    800054b6:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054b8:	08000613          	li	a2,128
    800054bc:	ed040593          	addi	a1,s0,-304
    800054c0:	4501                	li	a0,0
    800054c2:	ffffd097          	auipc	ra,0xffffd
    800054c6:	7b6080e7          	jalr	1974(ra) # 80002c78 <argstr>
    return -1;
    800054ca:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054cc:	10054e63          	bltz	a0,800055e8 <sys_link+0x13c>
    800054d0:	08000613          	li	a2,128
    800054d4:	f5040593          	addi	a1,s0,-176
    800054d8:	4505                	li	a0,1
    800054da:	ffffd097          	auipc	ra,0xffffd
    800054de:	79e080e7          	jalr	1950(ra) # 80002c78 <argstr>
    return -1;
    800054e2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054e4:	10054263          	bltz	a0,800055e8 <sys_link+0x13c>
  begin_op();
    800054e8:	fffff097          	auipc	ra,0xfffff
    800054ec:	d10080e7          	jalr	-752(ra) # 800041f8 <begin_op>
  if((ip = namei(old)) == 0){
    800054f0:	ed040513          	addi	a0,s0,-304
    800054f4:	fffff097          	auipc	ra,0xfffff
    800054f8:	ae8080e7          	jalr	-1304(ra) # 80003fdc <namei>
    800054fc:	84aa                	mv	s1,a0
    800054fe:	c551                	beqz	a0,8000558a <sys_link+0xde>
  ilock(ip);
    80005500:	ffffe097          	auipc	ra,0xffffe
    80005504:	336080e7          	jalr	822(ra) # 80003836 <ilock>
  if(ip->type == T_DIR){
    80005508:	04449703          	lh	a4,68(s1)
    8000550c:	4785                	li	a5,1
    8000550e:	08f70463          	beq	a4,a5,80005596 <sys_link+0xea>
  ip->nlink++;
    80005512:	04a4d783          	lhu	a5,74(s1)
    80005516:	2785                	addiw	a5,a5,1
    80005518:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000551c:	8526                	mv	a0,s1
    8000551e:	ffffe097          	auipc	ra,0xffffe
    80005522:	24e080e7          	jalr	590(ra) # 8000376c <iupdate>
  iunlock(ip);
    80005526:	8526                	mv	a0,s1
    80005528:	ffffe097          	auipc	ra,0xffffe
    8000552c:	3d0080e7          	jalr	976(ra) # 800038f8 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005530:	fd040593          	addi	a1,s0,-48
    80005534:	f5040513          	addi	a0,s0,-176
    80005538:	fffff097          	auipc	ra,0xfffff
    8000553c:	ac2080e7          	jalr	-1342(ra) # 80003ffa <nameiparent>
    80005540:	892a                	mv	s2,a0
    80005542:	c935                	beqz	a0,800055b6 <sys_link+0x10a>
  ilock(dp);
    80005544:	ffffe097          	auipc	ra,0xffffe
    80005548:	2f2080e7          	jalr	754(ra) # 80003836 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000554c:	00092703          	lw	a4,0(s2)
    80005550:	409c                	lw	a5,0(s1)
    80005552:	04f71d63          	bne	a4,a5,800055ac <sys_link+0x100>
    80005556:	40d0                	lw	a2,4(s1)
    80005558:	fd040593          	addi	a1,s0,-48
    8000555c:	854a                	mv	a0,s2
    8000555e:	fffff097          	auipc	ra,0xfffff
    80005562:	9cc080e7          	jalr	-1588(ra) # 80003f2a <dirlink>
    80005566:	04054363          	bltz	a0,800055ac <sys_link+0x100>
  iunlockput(dp);
    8000556a:	854a                	mv	a0,s2
    8000556c:	ffffe097          	auipc	ra,0xffffe
    80005570:	52c080e7          	jalr	1324(ra) # 80003a98 <iunlockput>
  iput(ip);
    80005574:	8526                	mv	a0,s1
    80005576:	ffffe097          	auipc	ra,0xffffe
    8000557a:	47a080e7          	jalr	1146(ra) # 800039f0 <iput>
  end_op();
    8000557e:	fffff097          	auipc	ra,0xfffff
    80005582:	cfa080e7          	jalr	-774(ra) # 80004278 <end_op>
  return 0;
    80005586:	4781                	li	a5,0
    80005588:	a085                	j	800055e8 <sys_link+0x13c>
    end_op();
    8000558a:	fffff097          	auipc	ra,0xfffff
    8000558e:	cee080e7          	jalr	-786(ra) # 80004278 <end_op>
    return -1;
    80005592:	57fd                	li	a5,-1
    80005594:	a891                	j	800055e8 <sys_link+0x13c>
    iunlockput(ip);
    80005596:	8526                	mv	a0,s1
    80005598:	ffffe097          	auipc	ra,0xffffe
    8000559c:	500080e7          	jalr	1280(ra) # 80003a98 <iunlockput>
    end_op();
    800055a0:	fffff097          	auipc	ra,0xfffff
    800055a4:	cd8080e7          	jalr	-808(ra) # 80004278 <end_op>
    return -1;
    800055a8:	57fd                	li	a5,-1
    800055aa:	a83d                	j	800055e8 <sys_link+0x13c>
    iunlockput(dp);
    800055ac:	854a                	mv	a0,s2
    800055ae:	ffffe097          	auipc	ra,0xffffe
    800055b2:	4ea080e7          	jalr	1258(ra) # 80003a98 <iunlockput>
  ilock(ip);
    800055b6:	8526                	mv	a0,s1
    800055b8:	ffffe097          	auipc	ra,0xffffe
    800055bc:	27e080e7          	jalr	638(ra) # 80003836 <ilock>
  ip->nlink--;
    800055c0:	04a4d783          	lhu	a5,74(s1)
    800055c4:	37fd                	addiw	a5,a5,-1
    800055c6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055ca:	8526                	mv	a0,s1
    800055cc:	ffffe097          	auipc	ra,0xffffe
    800055d0:	1a0080e7          	jalr	416(ra) # 8000376c <iupdate>
  iunlockput(ip);
    800055d4:	8526                	mv	a0,s1
    800055d6:	ffffe097          	auipc	ra,0xffffe
    800055da:	4c2080e7          	jalr	1218(ra) # 80003a98 <iunlockput>
  end_op();
    800055de:	fffff097          	auipc	ra,0xfffff
    800055e2:	c9a080e7          	jalr	-870(ra) # 80004278 <end_op>
  return -1;
    800055e6:	57fd                	li	a5,-1
}
    800055e8:	853e                	mv	a0,a5
    800055ea:	70b2                	ld	ra,296(sp)
    800055ec:	7412                	ld	s0,288(sp)
    800055ee:	64f2                	ld	s1,280(sp)
    800055f0:	6952                	ld	s2,272(sp)
    800055f2:	6155                	addi	sp,sp,304
    800055f4:	8082                	ret

00000000800055f6 <sys_unlink>:
{
    800055f6:	7151                	addi	sp,sp,-240
    800055f8:	f586                	sd	ra,232(sp)
    800055fa:	f1a2                	sd	s0,224(sp)
    800055fc:	eda6                	sd	s1,216(sp)
    800055fe:	e9ca                	sd	s2,208(sp)
    80005600:	e5ce                	sd	s3,200(sp)
    80005602:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005604:	08000613          	li	a2,128
    80005608:	f3040593          	addi	a1,s0,-208
    8000560c:	4501                	li	a0,0
    8000560e:	ffffd097          	auipc	ra,0xffffd
    80005612:	66a080e7          	jalr	1642(ra) # 80002c78 <argstr>
    80005616:	18054163          	bltz	a0,80005798 <sys_unlink+0x1a2>
  begin_op();
    8000561a:	fffff097          	auipc	ra,0xfffff
    8000561e:	bde080e7          	jalr	-1058(ra) # 800041f8 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005622:	fb040593          	addi	a1,s0,-80
    80005626:	f3040513          	addi	a0,s0,-208
    8000562a:	fffff097          	auipc	ra,0xfffff
    8000562e:	9d0080e7          	jalr	-1584(ra) # 80003ffa <nameiparent>
    80005632:	84aa                	mv	s1,a0
    80005634:	c979                	beqz	a0,8000570a <sys_unlink+0x114>
  ilock(dp);
    80005636:	ffffe097          	auipc	ra,0xffffe
    8000563a:	200080e7          	jalr	512(ra) # 80003836 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000563e:	00003597          	auipc	a1,0x3
    80005642:	11a58593          	addi	a1,a1,282 # 80008758 <syscalls+0x2b8>
    80005646:	fb040513          	addi	a0,s0,-80
    8000564a:	ffffe097          	auipc	ra,0xffffe
    8000564e:	6b6080e7          	jalr	1718(ra) # 80003d00 <namecmp>
    80005652:	14050a63          	beqz	a0,800057a6 <sys_unlink+0x1b0>
    80005656:	00003597          	auipc	a1,0x3
    8000565a:	10a58593          	addi	a1,a1,266 # 80008760 <syscalls+0x2c0>
    8000565e:	fb040513          	addi	a0,s0,-80
    80005662:	ffffe097          	auipc	ra,0xffffe
    80005666:	69e080e7          	jalr	1694(ra) # 80003d00 <namecmp>
    8000566a:	12050e63          	beqz	a0,800057a6 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000566e:	f2c40613          	addi	a2,s0,-212
    80005672:	fb040593          	addi	a1,s0,-80
    80005676:	8526                	mv	a0,s1
    80005678:	ffffe097          	auipc	ra,0xffffe
    8000567c:	6a2080e7          	jalr	1698(ra) # 80003d1a <dirlookup>
    80005680:	892a                	mv	s2,a0
    80005682:	12050263          	beqz	a0,800057a6 <sys_unlink+0x1b0>
  ilock(ip);
    80005686:	ffffe097          	auipc	ra,0xffffe
    8000568a:	1b0080e7          	jalr	432(ra) # 80003836 <ilock>
  if(ip->nlink < 1)
    8000568e:	04a91783          	lh	a5,74(s2)
    80005692:	08f05263          	blez	a5,80005716 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005696:	04491703          	lh	a4,68(s2)
    8000569a:	4785                	li	a5,1
    8000569c:	08f70563          	beq	a4,a5,80005726 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800056a0:	4641                	li	a2,16
    800056a2:	4581                	li	a1,0
    800056a4:	fc040513          	addi	a0,s0,-64
    800056a8:	ffffb097          	auipc	ra,0xffffb
    800056ac:	660080e7          	jalr	1632(ra) # 80000d08 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056b0:	4741                	li	a4,16
    800056b2:	f2c42683          	lw	a3,-212(s0)
    800056b6:	fc040613          	addi	a2,s0,-64
    800056ba:	4581                	li	a1,0
    800056bc:	8526                	mv	a0,s1
    800056be:	ffffe097          	auipc	ra,0xffffe
    800056c2:	524080e7          	jalr	1316(ra) # 80003be2 <writei>
    800056c6:	47c1                	li	a5,16
    800056c8:	0af51563          	bne	a0,a5,80005772 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800056cc:	04491703          	lh	a4,68(s2)
    800056d0:	4785                	li	a5,1
    800056d2:	0af70863          	beq	a4,a5,80005782 <sys_unlink+0x18c>
  iunlockput(dp);
    800056d6:	8526                	mv	a0,s1
    800056d8:	ffffe097          	auipc	ra,0xffffe
    800056dc:	3c0080e7          	jalr	960(ra) # 80003a98 <iunlockput>
  ip->nlink--;
    800056e0:	04a95783          	lhu	a5,74(s2)
    800056e4:	37fd                	addiw	a5,a5,-1
    800056e6:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800056ea:	854a                	mv	a0,s2
    800056ec:	ffffe097          	auipc	ra,0xffffe
    800056f0:	080080e7          	jalr	128(ra) # 8000376c <iupdate>
  iunlockput(ip);
    800056f4:	854a                	mv	a0,s2
    800056f6:	ffffe097          	auipc	ra,0xffffe
    800056fa:	3a2080e7          	jalr	930(ra) # 80003a98 <iunlockput>
  end_op();
    800056fe:	fffff097          	auipc	ra,0xfffff
    80005702:	b7a080e7          	jalr	-1158(ra) # 80004278 <end_op>
  return 0;
    80005706:	4501                	li	a0,0
    80005708:	a84d                	j	800057ba <sys_unlink+0x1c4>
    end_op();
    8000570a:	fffff097          	auipc	ra,0xfffff
    8000570e:	b6e080e7          	jalr	-1170(ra) # 80004278 <end_op>
    return -1;
    80005712:	557d                	li	a0,-1
    80005714:	a05d                	j	800057ba <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005716:	00003517          	auipc	a0,0x3
    8000571a:	05250513          	addi	a0,a0,82 # 80008768 <syscalls+0x2c8>
    8000571e:	ffffb097          	auipc	ra,0xffffb
    80005722:	e26080e7          	jalr	-474(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005726:	04c92703          	lw	a4,76(s2)
    8000572a:	02000793          	li	a5,32
    8000572e:	f6e7f9e3          	bgeu	a5,a4,800056a0 <sys_unlink+0xaa>
    80005732:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005736:	4741                	li	a4,16
    80005738:	86ce                	mv	a3,s3
    8000573a:	f1840613          	addi	a2,s0,-232
    8000573e:	4581                	li	a1,0
    80005740:	854a                	mv	a0,s2
    80005742:	ffffe097          	auipc	ra,0xffffe
    80005746:	3a8080e7          	jalr	936(ra) # 80003aea <readi>
    8000574a:	47c1                	li	a5,16
    8000574c:	00f51b63          	bne	a0,a5,80005762 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005750:	f1845783          	lhu	a5,-232(s0)
    80005754:	e7a1                	bnez	a5,8000579c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005756:	29c1                	addiw	s3,s3,16
    80005758:	04c92783          	lw	a5,76(s2)
    8000575c:	fcf9ede3          	bltu	s3,a5,80005736 <sys_unlink+0x140>
    80005760:	b781                	j	800056a0 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005762:	00003517          	auipc	a0,0x3
    80005766:	01e50513          	addi	a0,a0,30 # 80008780 <syscalls+0x2e0>
    8000576a:	ffffb097          	auipc	ra,0xffffb
    8000576e:	dda080e7          	jalr	-550(ra) # 80000544 <panic>
    panic("unlink: writei");
    80005772:	00003517          	auipc	a0,0x3
    80005776:	02650513          	addi	a0,a0,38 # 80008798 <syscalls+0x2f8>
    8000577a:	ffffb097          	auipc	ra,0xffffb
    8000577e:	dca080e7          	jalr	-566(ra) # 80000544 <panic>
    dp->nlink--;
    80005782:	04a4d783          	lhu	a5,74(s1)
    80005786:	37fd                	addiw	a5,a5,-1
    80005788:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000578c:	8526                	mv	a0,s1
    8000578e:	ffffe097          	auipc	ra,0xffffe
    80005792:	fde080e7          	jalr	-34(ra) # 8000376c <iupdate>
    80005796:	b781                	j	800056d6 <sys_unlink+0xe0>
    return -1;
    80005798:	557d                	li	a0,-1
    8000579a:	a005                	j	800057ba <sys_unlink+0x1c4>
    iunlockput(ip);
    8000579c:	854a                	mv	a0,s2
    8000579e:	ffffe097          	auipc	ra,0xffffe
    800057a2:	2fa080e7          	jalr	762(ra) # 80003a98 <iunlockput>
  iunlockput(dp);
    800057a6:	8526                	mv	a0,s1
    800057a8:	ffffe097          	auipc	ra,0xffffe
    800057ac:	2f0080e7          	jalr	752(ra) # 80003a98 <iunlockput>
  end_op();
    800057b0:	fffff097          	auipc	ra,0xfffff
    800057b4:	ac8080e7          	jalr	-1336(ra) # 80004278 <end_op>
  return -1;
    800057b8:	557d                	li	a0,-1
}
    800057ba:	70ae                	ld	ra,232(sp)
    800057bc:	740e                	ld	s0,224(sp)
    800057be:	64ee                	ld	s1,216(sp)
    800057c0:	694e                	ld	s2,208(sp)
    800057c2:	69ae                	ld	s3,200(sp)
    800057c4:	616d                	addi	sp,sp,240
    800057c6:	8082                	ret

00000000800057c8 <sys_open>:

uint64
sys_open(void)
{
    800057c8:	7131                	addi	sp,sp,-192
    800057ca:	fd06                	sd	ra,184(sp)
    800057cc:	f922                	sd	s0,176(sp)
    800057ce:	f526                	sd	s1,168(sp)
    800057d0:	f14a                	sd	s2,160(sp)
    800057d2:	ed4e                	sd	s3,152(sp)
    800057d4:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800057d6:	f4c40593          	addi	a1,s0,-180
    800057da:	4505                	li	a0,1
    800057dc:	ffffd097          	auipc	ra,0xffffd
    800057e0:	45c080e7          	jalr	1116(ra) # 80002c38 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800057e4:	08000613          	li	a2,128
    800057e8:	f5040593          	addi	a1,s0,-176
    800057ec:	4501                	li	a0,0
    800057ee:	ffffd097          	auipc	ra,0xffffd
    800057f2:	48a080e7          	jalr	1162(ra) # 80002c78 <argstr>
    800057f6:	87aa                	mv	a5,a0
    return -1;
    800057f8:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800057fa:	0a07c963          	bltz	a5,800058ac <sys_open+0xe4>

  begin_op();
    800057fe:	fffff097          	auipc	ra,0xfffff
    80005802:	9fa080e7          	jalr	-1542(ra) # 800041f8 <begin_op>

  if(omode & O_CREATE){
    80005806:	f4c42783          	lw	a5,-180(s0)
    8000580a:	2007f793          	andi	a5,a5,512
    8000580e:	cfc5                	beqz	a5,800058c6 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005810:	4681                	li	a3,0
    80005812:	4601                	li	a2,0
    80005814:	4589                	li	a1,2
    80005816:	f5040513          	addi	a0,s0,-176
    8000581a:	00000097          	auipc	ra,0x0
    8000581e:	974080e7          	jalr	-1676(ra) # 8000518e <create>
    80005822:	84aa                	mv	s1,a0
    if(ip == 0){
    80005824:	c959                	beqz	a0,800058ba <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005826:	04449703          	lh	a4,68(s1)
    8000582a:	478d                	li	a5,3
    8000582c:	00f71763          	bne	a4,a5,8000583a <sys_open+0x72>
    80005830:	0464d703          	lhu	a4,70(s1)
    80005834:	47a5                	li	a5,9
    80005836:	0ce7ed63          	bltu	a5,a4,80005910 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000583a:	fffff097          	auipc	ra,0xfffff
    8000583e:	dce080e7          	jalr	-562(ra) # 80004608 <filealloc>
    80005842:	89aa                	mv	s3,a0
    80005844:	10050363          	beqz	a0,8000594a <sys_open+0x182>
    80005848:	00000097          	auipc	ra,0x0
    8000584c:	904080e7          	jalr	-1788(ra) # 8000514c <fdalloc>
    80005850:	892a                	mv	s2,a0
    80005852:	0e054763          	bltz	a0,80005940 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005856:	04449703          	lh	a4,68(s1)
    8000585a:	478d                	li	a5,3
    8000585c:	0cf70563          	beq	a4,a5,80005926 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005860:	4789                	li	a5,2
    80005862:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005866:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000586a:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000586e:	f4c42783          	lw	a5,-180(s0)
    80005872:	0017c713          	xori	a4,a5,1
    80005876:	8b05                	andi	a4,a4,1
    80005878:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000587c:	0037f713          	andi	a4,a5,3
    80005880:	00e03733          	snez	a4,a4
    80005884:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005888:	4007f793          	andi	a5,a5,1024
    8000588c:	c791                	beqz	a5,80005898 <sys_open+0xd0>
    8000588e:	04449703          	lh	a4,68(s1)
    80005892:	4789                	li	a5,2
    80005894:	0af70063          	beq	a4,a5,80005934 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005898:	8526                	mv	a0,s1
    8000589a:	ffffe097          	auipc	ra,0xffffe
    8000589e:	05e080e7          	jalr	94(ra) # 800038f8 <iunlock>
  end_op();
    800058a2:	fffff097          	auipc	ra,0xfffff
    800058a6:	9d6080e7          	jalr	-1578(ra) # 80004278 <end_op>

  return fd;
    800058aa:	854a                	mv	a0,s2
}
    800058ac:	70ea                	ld	ra,184(sp)
    800058ae:	744a                	ld	s0,176(sp)
    800058b0:	74aa                	ld	s1,168(sp)
    800058b2:	790a                	ld	s2,160(sp)
    800058b4:	69ea                	ld	s3,152(sp)
    800058b6:	6129                	addi	sp,sp,192
    800058b8:	8082                	ret
      end_op();
    800058ba:	fffff097          	auipc	ra,0xfffff
    800058be:	9be080e7          	jalr	-1602(ra) # 80004278 <end_op>
      return -1;
    800058c2:	557d                	li	a0,-1
    800058c4:	b7e5                	j	800058ac <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800058c6:	f5040513          	addi	a0,s0,-176
    800058ca:	ffffe097          	auipc	ra,0xffffe
    800058ce:	712080e7          	jalr	1810(ra) # 80003fdc <namei>
    800058d2:	84aa                	mv	s1,a0
    800058d4:	c905                	beqz	a0,80005904 <sys_open+0x13c>
    ilock(ip);
    800058d6:	ffffe097          	auipc	ra,0xffffe
    800058da:	f60080e7          	jalr	-160(ra) # 80003836 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800058de:	04449703          	lh	a4,68(s1)
    800058e2:	4785                	li	a5,1
    800058e4:	f4f711e3          	bne	a4,a5,80005826 <sys_open+0x5e>
    800058e8:	f4c42783          	lw	a5,-180(s0)
    800058ec:	d7b9                	beqz	a5,8000583a <sys_open+0x72>
      iunlockput(ip);
    800058ee:	8526                	mv	a0,s1
    800058f0:	ffffe097          	auipc	ra,0xffffe
    800058f4:	1a8080e7          	jalr	424(ra) # 80003a98 <iunlockput>
      end_op();
    800058f8:	fffff097          	auipc	ra,0xfffff
    800058fc:	980080e7          	jalr	-1664(ra) # 80004278 <end_op>
      return -1;
    80005900:	557d                	li	a0,-1
    80005902:	b76d                	j	800058ac <sys_open+0xe4>
      end_op();
    80005904:	fffff097          	auipc	ra,0xfffff
    80005908:	974080e7          	jalr	-1676(ra) # 80004278 <end_op>
      return -1;
    8000590c:	557d                	li	a0,-1
    8000590e:	bf79                	j	800058ac <sys_open+0xe4>
    iunlockput(ip);
    80005910:	8526                	mv	a0,s1
    80005912:	ffffe097          	auipc	ra,0xffffe
    80005916:	186080e7          	jalr	390(ra) # 80003a98 <iunlockput>
    end_op();
    8000591a:	fffff097          	auipc	ra,0xfffff
    8000591e:	95e080e7          	jalr	-1698(ra) # 80004278 <end_op>
    return -1;
    80005922:	557d                	li	a0,-1
    80005924:	b761                	j	800058ac <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005926:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000592a:	04649783          	lh	a5,70(s1)
    8000592e:	02f99223          	sh	a5,36(s3)
    80005932:	bf25                	j	8000586a <sys_open+0xa2>
    itrunc(ip);
    80005934:	8526                	mv	a0,s1
    80005936:	ffffe097          	auipc	ra,0xffffe
    8000593a:	00e080e7          	jalr	14(ra) # 80003944 <itrunc>
    8000593e:	bfa9                	j	80005898 <sys_open+0xd0>
      fileclose(f);
    80005940:	854e                	mv	a0,s3
    80005942:	fffff097          	auipc	ra,0xfffff
    80005946:	d82080e7          	jalr	-638(ra) # 800046c4 <fileclose>
    iunlockput(ip);
    8000594a:	8526                	mv	a0,s1
    8000594c:	ffffe097          	auipc	ra,0xffffe
    80005950:	14c080e7          	jalr	332(ra) # 80003a98 <iunlockput>
    end_op();
    80005954:	fffff097          	auipc	ra,0xfffff
    80005958:	924080e7          	jalr	-1756(ra) # 80004278 <end_op>
    return -1;
    8000595c:	557d                	li	a0,-1
    8000595e:	b7b9                	j	800058ac <sys_open+0xe4>

0000000080005960 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005960:	7175                	addi	sp,sp,-144
    80005962:	e506                	sd	ra,136(sp)
    80005964:	e122                	sd	s0,128(sp)
    80005966:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005968:	fffff097          	auipc	ra,0xfffff
    8000596c:	890080e7          	jalr	-1904(ra) # 800041f8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005970:	08000613          	li	a2,128
    80005974:	f7040593          	addi	a1,s0,-144
    80005978:	4501                	li	a0,0
    8000597a:	ffffd097          	auipc	ra,0xffffd
    8000597e:	2fe080e7          	jalr	766(ra) # 80002c78 <argstr>
    80005982:	02054963          	bltz	a0,800059b4 <sys_mkdir+0x54>
    80005986:	4681                	li	a3,0
    80005988:	4601                	li	a2,0
    8000598a:	4585                	li	a1,1
    8000598c:	f7040513          	addi	a0,s0,-144
    80005990:	fffff097          	auipc	ra,0xfffff
    80005994:	7fe080e7          	jalr	2046(ra) # 8000518e <create>
    80005998:	cd11                	beqz	a0,800059b4 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000599a:	ffffe097          	auipc	ra,0xffffe
    8000599e:	0fe080e7          	jalr	254(ra) # 80003a98 <iunlockput>
  end_op();
    800059a2:	fffff097          	auipc	ra,0xfffff
    800059a6:	8d6080e7          	jalr	-1834(ra) # 80004278 <end_op>
  return 0;
    800059aa:	4501                	li	a0,0
}
    800059ac:	60aa                	ld	ra,136(sp)
    800059ae:	640a                	ld	s0,128(sp)
    800059b0:	6149                	addi	sp,sp,144
    800059b2:	8082                	ret
    end_op();
    800059b4:	fffff097          	auipc	ra,0xfffff
    800059b8:	8c4080e7          	jalr	-1852(ra) # 80004278 <end_op>
    return -1;
    800059bc:	557d                	li	a0,-1
    800059be:	b7fd                	j	800059ac <sys_mkdir+0x4c>

00000000800059c0 <sys_mknod>:

uint64
sys_mknod(void)
{
    800059c0:	7135                	addi	sp,sp,-160
    800059c2:	ed06                	sd	ra,152(sp)
    800059c4:	e922                	sd	s0,144(sp)
    800059c6:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800059c8:	fffff097          	auipc	ra,0xfffff
    800059cc:	830080e7          	jalr	-2000(ra) # 800041f8 <begin_op>
  argint(1, &major);
    800059d0:	f6c40593          	addi	a1,s0,-148
    800059d4:	4505                	li	a0,1
    800059d6:	ffffd097          	auipc	ra,0xffffd
    800059da:	262080e7          	jalr	610(ra) # 80002c38 <argint>
  argint(2, &minor);
    800059de:	f6840593          	addi	a1,s0,-152
    800059e2:	4509                	li	a0,2
    800059e4:	ffffd097          	auipc	ra,0xffffd
    800059e8:	254080e7          	jalr	596(ra) # 80002c38 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059ec:	08000613          	li	a2,128
    800059f0:	f7040593          	addi	a1,s0,-144
    800059f4:	4501                	li	a0,0
    800059f6:	ffffd097          	auipc	ra,0xffffd
    800059fa:	282080e7          	jalr	642(ra) # 80002c78 <argstr>
    800059fe:	02054b63          	bltz	a0,80005a34 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a02:	f6841683          	lh	a3,-152(s0)
    80005a06:	f6c41603          	lh	a2,-148(s0)
    80005a0a:	458d                	li	a1,3
    80005a0c:	f7040513          	addi	a0,s0,-144
    80005a10:	fffff097          	auipc	ra,0xfffff
    80005a14:	77e080e7          	jalr	1918(ra) # 8000518e <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a18:	cd11                	beqz	a0,80005a34 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a1a:	ffffe097          	auipc	ra,0xffffe
    80005a1e:	07e080e7          	jalr	126(ra) # 80003a98 <iunlockput>
  end_op();
    80005a22:	fffff097          	auipc	ra,0xfffff
    80005a26:	856080e7          	jalr	-1962(ra) # 80004278 <end_op>
  return 0;
    80005a2a:	4501                	li	a0,0
}
    80005a2c:	60ea                	ld	ra,152(sp)
    80005a2e:	644a                	ld	s0,144(sp)
    80005a30:	610d                	addi	sp,sp,160
    80005a32:	8082                	ret
    end_op();
    80005a34:	fffff097          	auipc	ra,0xfffff
    80005a38:	844080e7          	jalr	-1980(ra) # 80004278 <end_op>
    return -1;
    80005a3c:	557d                	li	a0,-1
    80005a3e:	b7fd                	j	80005a2c <sys_mknod+0x6c>

0000000080005a40 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a40:	7135                	addi	sp,sp,-160
    80005a42:	ed06                	sd	ra,152(sp)
    80005a44:	e922                	sd	s0,144(sp)
    80005a46:	e526                	sd	s1,136(sp)
    80005a48:	e14a                	sd	s2,128(sp)
    80005a4a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a4c:	ffffc097          	auipc	ra,0xffffc
    80005a50:	f9c080e7          	jalr	-100(ra) # 800019e8 <myproc>
    80005a54:	892a                	mv	s2,a0
  
  begin_op();
    80005a56:	ffffe097          	auipc	ra,0xffffe
    80005a5a:	7a2080e7          	jalr	1954(ra) # 800041f8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a5e:	08000613          	li	a2,128
    80005a62:	f6040593          	addi	a1,s0,-160
    80005a66:	4501                	li	a0,0
    80005a68:	ffffd097          	auipc	ra,0xffffd
    80005a6c:	210080e7          	jalr	528(ra) # 80002c78 <argstr>
    80005a70:	04054b63          	bltz	a0,80005ac6 <sys_chdir+0x86>
    80005a74:	f6040513          	addi	a0,s0,-160
    80005a78:	ffffe097          	auipc	ra,0xffffe
    80005a7c:	564080e7          	jalr	1380(ra) # 80003fdc <namei>
    80005a80:	84aa                	mv	s1,a0
    80005a82:	c131                	beqz	a0,80005ac6 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a84:	ffffe097          	auipc	ra,0xffffe
    80005a88:	db2080e7          	jalr	-590(ra) # 80003836 <ilock>
  if(ip->type != T_DIR){
    80005a8c:	04449703          	lh	a4,68(s1)
    80005a90:	4785                	li	a5,1
    80005a92:	04f71063          	bne	a4,a5,80005ad2 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a96:	8526                	mv	a0,s1
    80005a98:	ffffe097          	auipc	ra,0xffffe
    80005a9c:	e60080e7          	jalr	-416(ra) # 800038f8 <iunlock>
  iput(p->cwd);
    80005aa0:	15093503          	ld	a0,336(s2)
    80005aa4:	ffffe097          	auipc	ra,0xffffe
    80005aa8:	f4c080e7          	jalr	-180(ra) # 800039f0 <iput>
  end_op();
    80005aac:	ffffe097          	auipc	ra,0xffffe
    80005ab0:	7cc080e7          	jalr	1996(ra) # 80004278 <end_op>
  p->cwd = ip;
    80005ab4:	14993823          	sd	s1,336(s2)
  return 0;
    80005ab8:	4501                	li	a0,0
}
    80005aba:	60ea                	ld	ra,152(sp)
    80005abc:	644a                	ld	s0,144(sp)
    80005abe:	64aa                	ld	s1,136(sp)
    80005ac0:	690a                	ld	s2,128(sp)
    80005ac2:	610d                	addi	sp,sp,160
    80005ac4:	8082                	ret
    end_op();
    80005ac6:	ffffe097          	auipc	ra,0xffffe
    80005aca:	7b2080e7          	jalr	1970(ra) # 80004278 <end_op>
    return -1;
    80005ace:	557d                	li	a0,-1
    80005ad0:	b7ed                	j	80005aba <sys_chdir+0x7a>
    iunlockput(ip);
    80005ad2:	8526                	mv	a0,s1
    80005ad4:	ffffe097          	auipc	ra,0xffffe
    80005ad8:	fc4080e7          	jalr	-60(ra) # 80003a98 <iunlockput>
    end_op();
    80005adc:	ffffe097          	auipc	ra,0xffffe
    80005ae0:	79c080e7          	jalr	1948(ra) # 80004278 <end_op>
    return -1;
    80005ae4:	557d                	li	a0,-1
    80005ae6:	bfd1                	j	80005aba <sys_chdir+0x7a>

0000000080005ae8 <sys_exec>:

uint64
sys_exec(void)
{
    80005ae8:	7145                	addi	sp,sp,-464
    80005aea:	e786                	sd	ra,456(sp)
    80005aec:	e3a2                	sd	s0,448(sp)
    80005aee:	ff26                	sd	s1,440(sp)
    80005af0:	fb4a                	sd	s2,432(sp)
    80005af2:	f74e                	sd	s3,424(sp)
    80005af4:	f352                	sd	s4,416(sp)
    80005af6:	ef56                	sd	s5,408(sp)
    80005af8:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005afa:	e3840593          	addi	a1,s0,-456
    80005afe:	4505                	li	a0,1
    80005b00:	ffffd097          	auipc	ra,0xffffd
    80005b04:	158080e7          	jalr	344(ra) # 80002c58 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005b08:	08000613          	li	a2,128
    80005b0c:	f4040593          	addi	a1,s0,-192
    80005b10:	4501                	li	a0,0
    80005b12:	ffffd097          	auipc	ra,0xffffd
    80005b16:	166080e7          	jalr	358(ra) # 80002c78 <argstr>
    80005b1a:	87aa                	mv	a5,a0
    return -1;
    80005b1c:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005b1e:	0c07c263          	bltz	a5,80005be2 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005b22:	10000613          	li	a2,256
    80005b26:	4581                	li	a1,0
    80005b28:	e4040513          	addi	a0,s0,-448
    80005b2c:	ffffb097          	auipc	ra,0xffffb
    80005b30:	1dc080e7          	jalr	476(ra) # 80000d08 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b34:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b38:	89a6                	mv	s3,s1
    80005b3a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b3c:	02000a13          	li	s4,32
    80005b40:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b44:	00391513          	slli	a0,s2,0x3
    80005b48:	e3040593          	addi	a1,s0,-464
    80005b4c:	e3843783          	ld	a5,-456(s0)
    80005b50:	953e                	add	a0,a0,a5
    80005b52:	ffffd097          	auipc	ra,0xffffd
    80005b56:	048080e7          	jalr	72(ra) # 80002b9a <fetchaddr>
    80005b5a:	02054a63          	bltz	a0,80005b8e <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005b5e:	e3043783          	ld	a5,-464(s0)
    80005b62:	c3b9                	beqz	a5,80005ba8 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b64:	ffffb097          	auipc	ra,0xffffb
    80005b68:	f96080e7          	jalr	-106(ra) # 80000afa <kalloc>
    80005b6c:	85aa                	mv	a1,a0
    80005b6e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b72:	cd11                	beqz	a0,80005b8e <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b74:	6605                	lui	a2,0x1
    80005b76:	e3043503          	ld	a0,-464(s0)
    80005b7a:	ffffd097          	auipc	ra,0xffffd
    80005b7e:	072080e7          	jalr	114(ra) # 80002bec <fetchstr>
    80005b82:	00054663          	bltz	a0,80005b8e <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005b86:	0905                	addi	s2,s2,1
    80005b88:	09a1                	addi	s3,s3,8
    80005b8a:	fb491be3          	bne	s2,s4,80005b40 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b8e:	10048913          	addi	s2,s1,256
    80005b92:	6088                	ld	a0,0(s1)
    80005b94:	c531                	beqz	a0,80005be0 <sys_exec+0xf8>
    kfree(argv[i]);
    80005b96:	ffffb097          	auipc	ra,0xffffb
    80005b9a:	e68080e7          	jalr	-408(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b9e:	04a1                	addi	s1,s1,8
    80005ba0:	ff2499e3          	bne	s1,s2,80005b92 <sys_exec+0xaa>
  return -1;
    80005ba4:	557d                	li	a0,-1
    80005ba6:	a835                	j	80005be2 <sys_exec+0xfa>
      argv[i] = 0;
    80005ba8:	0a8e                	slli	s5,s5,0x3
    80005baa:	fc040793          	addi	a5,s0,-64
    80005bae:	9abe                	add	s5,s5,a5
    80005bb0:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005bb4:	e4040593          	addi	a1,s0,-448
    80005bb8:	f4040513          	addi	a0,s0,-192
    80005bbc:	fffff097          	auipc	ra,0xfffff
    80005bc0:	190080e7          	jalr	400(ra) # 80004d4c <exec>
    80005bc4:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bc6:	10048993          	addi	s3,s1,256
    80005bca:	6088                	ld	a0,0(s1)
    80005bcc:	c901                	beqz	a0,80005bdc <sys_exec+0xf4>
    kfree(argv[i]);
    80005bce:	ffffb097          	auipc	ra,0xffffb
    80005bd2:	e30080e7          	jalr	-464(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bd6:	04a1                	addi	s1,s1,8
    80005bd8:	ff3499e3          	bne	s1,s3,80005bca <sys_exec+0xe2>
  return ret;
    80005bdc:	854a                	mv	a0,s2
    80005bde:	a011                	j	80005be2 <sys_exec+0xfa>
  return -1;
    80005be0:	557d                	li	a0,-1
}
    80005be2:	60be                	ld	ra,456(sp)
    80005be4:	641e                	ld	s0,448(sp)
    80005be6:	74fa                	ld	s1,440(sp)
    80005be8:	795a                	ld	s2,432(sp)
    80005bea:	79ba                	ld	s3,424(sp)
    80005bec:	7a1a                	ld	s4,416(sp)
    80005bee:	6afa                	ld	s5,408(sp)
    80005bf0:	6179                	addi	sp,sp,464
    80005bf2:	8082                	ret

0000000080005bf4 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005bf4:	7139                	addi	sp,sp,-64
    80005bf6:	fc06                	sd	ra,56(sp)
    80005bf8:	f822                	sd	s0,48(sp)
    80005bfa:	f426                	sd	s1,40(sp)
    80005bfc:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005bfe:	ffffc097          	auipc	ra,0xffffc
    80005c02:	dea080e7          	jalr	-534(ra) # 800019e8 <myproc>
    80005c06:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005c08:	fd840593          	addi	a1,s0,-40
    80005c0c:	4501                	li	a0,0
    80005c0e:	ffffd097          	auipc	ra,0xffffd
    80005c12:	04a080e7          	jalr	74(ra) # 80002c58 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005c16:	fc840593          	addi	a1,s0,-56
    80005c1a:	fd040513          	addi	a0,s0,-48
    80005c1e:	fffff097          	auipc	ra,0xfffff
    80005c22:	dd6080e7          	jalr	-554(ra) # 800049f4 <pipealloc>
    return -1;
    80005c26:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c28:	0c054463          	bltz	a0,80005cf0 <sys_pipe+0xfc>
  fd0 = -1;
    80005c2c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c30:	fd043503          	ld	a0,-48(s0)
    80005c34:	fffff097          	auipc	ra,0xfffff
    80005c38:	518080e7          	jalr	1304(ra) # 8000514c <fdalloc>
    80005c3c:	fca42223          	sw	a0,-60(s0)
    80005c40:	08054b63          	bltz	a0,80005cd6 <sys_pipe+0xe2>
    80005c44:	fc843503          	ld	a0,-56(s0)
    80005c48:	fffff097          	auipc	ra,0xfffff
    80005c4c:	504080e7          	jalr	1284(ra) # 8000514c <fdalloc>
    80005c50:	fca42023          	sw	a0,-64(s0)
    80005c54:	06054863          	bltz	a0,80005cc4 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c58:	4691                	li	a3,4
    80005c5a:	fc440613          	addi	a2,s0,-60
    80005c5e:	fd843583          	ld	a1,-40(s0)
    80005c62:	68a8                	ld	a0,80(s1)
    80005c64:	ffffc097          	auipc	ra,0xffffc
    80005c68:	a42080e7          	jalr	-1470(ra) # 800016a6 <copyout>
    80005c6c:	02054063          	bltz	a0,80005c8c <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c70:	4691                	li	a3,4
    80005c72:	fc040613          	addi	a2,s0,-64
    80005c76:	fd843583          	ld	a1,-40(s0)
    80005c7a:	0591                	addi	a1,a1,4
    80005c7c:	68a8                	ld	a0,80(s1)
    80005c7e:	ffffc097          	auipc	ra,0xffffc
    80005c82:	a28080e7          	jalr	-1496(ra) # 800016a6 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c86:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c88:	06055463          	bgez	a0,80005cf0 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005c8c:	fc442783          	lw	a5,-60(s0)
    80005c90:	07e9                	addi	a5,a5,26
    80005c92:	078e                	slli	a5,a5,0x3
    80005c94:	97a6                	add	a5,a5,s1
    80005c96:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c9a:	fc042503          	lw	a0,-64(s0)
    80005c9e:	0569                	addi	a0,a0,26
    80005ca0:	050e                	slli	a0,a0,0x3
    80005ca2:	94aa                	add	s1,s1,a0
    80005ca4:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005ca8:	fd043503          	ld	a0,-48(s0)
    80005cac:	fffff097          	auipc	ra,0xfffff
    80005cb0:	a18080e7          	jalr	-1512(ra) # 800046c4 <fileclose>
    fileclose(wf);
    80005cb4:	fc843503          	ld	a0,-56(s0)
    80005cb8:	fffff097          	auipc	ra,0xfffff
    80005cbc:	a0c080e7          	jalr	-1524(ra) # 800046c4 <fileclose>
    return -1;
    80005cc0:	57fd                	li	a5,-1
    80005cc2:	a03d                	j	80005cf0 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005cc4:	fc442783          	lw	a5,-60(s0)
    80005cc8:	0007c763          	bltz	a5,80005cd6 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005ccc:	07e9                	addi	a5,a5,26
    80005cce:	078e                	slli	a5,a5,0x3
    80005cd0:	94be                	add	s1,s1,a5
    80005cd2:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005cd6:	fd043503          	ld	a0,-48(s0)
    80005cda:	fffff097          	auipc	ra,0xfffff
    80005cde:	9ea080e7          	jalr	-1558(ra) # 800046c4 <fileclose>
    fileclose(wf);
    80005ce2:	fc843503          	ld	a0,-56(s0)
    80005ce6:	fffff097          	auipc	ra,0xfffff
    80005cea:	9de080e7          	jalr	-1570(ra) # 800046c4 <fileclose>
    return -1;
    80005cee:	57fd                	li	a5,-1
}
    80005cf0:	853e                	mv	a0,a5
    80005cf2:	70e2                	ld	ra,56(sp)
    80005cf4:	7442                	ld	s0,48(sp)
    80005cf6:	74a2                	ld	s1,40(sp)
    80005cf8:	6121                	addi	sp,sp,64
    80005cfa:	8082                	ret
    80005cfc:	0000                	unimp
	...

0000000080005d00 <kernelvec>:
    80005d00:	7111                	addi	sp,sp,-256
    80005d02:	e006                	sd	ra,0(sp)
    80005d04:	e40a                	sd	sp,8(sp)
    80005d06:	e80e                	sd	gp,16(sp)
    80005d08:	ec12                	sd	tp,24(sp)
    80005d0a:	f016                	sd	t0,32(sp)
    80005d0c:	f41a                	sd	t1,40(sp)
    80005d0e:	f81e                	sd	t2,48(sp)
    80005d10:	fc22                	sd	s0,56(sp)
    80005d12:	e0a6                	sd	s1,64(sp)
    80005d14:	e4aa                	sd	a0,72(sp)
    80005d16:	e8ae                	sd	a1,80(sp)
    80005d18:	ecb2                	sd	a2,88(sp)
    80005d1a:	f0b6                	sd	a3,96(sp)
    80005d1c:	f4ba                	sd	a4,104(sp)
    80005d1e:	f8be                	sd	a5,112(sp)
    80005d20:	fcc2                	sd	a6,120(sp)
    80005d22:	e146                	sd	a7,128(sp)
    80005d24:	e54a                	sd	s2,136(sp)
    80005d26:	e94e                	sd	s3,144(sp)
    80005d28:	ed52                	sd	s4,152(sp)
    80005d2a:	f156                	sd	s5,160(sp)
    80005d2c:	f55a                	sd	s6,168(sp)
    80005d2e:	f95e                	sd	s7,176(sp)
    80005d30:	fd62                	sd	s8,184(sp)
    80005d32:	e1e6                	sd	s9,192(sp)
    80005d34:	e5ea                	sd	s10,200(sp)
    80005d36:	e9ee                	sd	s11,208(sp)
    80005d38:	edf2                	sd	t3,216(sp)
    80005d3a:	f1f6                	sd	t4,224(sp)
    80005d3c:	f5fa                	sd	t5,232(sp)
    80005d3e:	f9fe                	sd	t6,240(sp)
    80005d40:	d27fc0ef          	jal	ra,80002a66 <kerneltrap>
    80005d44:	6082                	ld	ra,0(sp)
    80005d46:	6122                	ld	sp,8(sp)
    80005d48:	61c2                	ld	gp,16(sp)
    80005d4a:	7282                	ld	t0,32(sp)
    80005d4c:	7322                	ld	t1,40(sp)
    80005d4e:	73c2                	ld	t2,48(sp)
    80005d50:	7462                	ld	s0,56(sp)
    80005d52:	6486                	ld	s1,64(sp)
    80005d54:	6526                	ld	a0,72(sp)
    80005d56:	65c6                	ld	a1,80(sp)
    80005d58:	6666                	ld	a2,88(sp)
    80005d5a:	7686                	ld	a3,96(sp)
    80005d5c:	7726                	ld	a4,104(sp)
    80005d5e:	77c6                	ld	a5,112(sp)
    80005d60:	7866                	ld	a6,120(sp)
    80005d62:	688a                	ld	a7,128(sp)
    80005d64:	692a                	ld	s2,136(sp)
    80005d66:	69ca                	ld	s3,144(sp)
    80005d68:	6a6a                	ld	s4,152(sp)
    80005d6a:	7a8a                	ld	s5,160(sp)
    80005d6c:	7b2a                	ld	s6,168(sp)
    80005d6e:	7bca                	ld	s7,176(sp)
    80005d70:	7c6a                	ld	s8,184(sp)
    80005d72:	6c8e                	ld	s9,192(sp)
    80005d74:	6d2e                	ld	s10,200(sp)
    80005d76:	6dce                	ld	s11,208(sp)
    80005d78:	6e6e                	ld	t3,216(sp)
    80005d7a:	7e8e                	ld	t4,224(sp)
    80005d7c:	7f2e                	ld	t5,232(sp)
    80005d7e:	7fce                	ld	t6,240(sp)
    80005d80:	6111                	addi	sp,sp,256
    80005d82:	10200073          	sret
    80005d86:	00000013          	nop
    80005d8a:	00000013          	nop
    80005d8e:	0001                	nop

0000000080005d90 <timervec>:
    80005d90:	34051573          	csrrw	a0,mscratch,a0
    80005d94:	e10c                	sd	a1,0(a0)
    80005d96:	e510                	sd	a2,8(a0)
    80005d98:	e914                	sd	a3,16(a0)
    80005d9a:	6d0c                	ld	a1,24(a0)
    80005d9c:	7110                	ld	a2,32(a0)
    80005d9e:	6194                	ld	a3,0(a1)
    80005da0:	96b2                	add	a3,a3,a2
    80005da2:	e194                	sd	a3,0(a1)
    80005da4:	4589                	li	a1,2
    80005da6:	14459073          	csrw	sip,a1
    80005daa:	6914                	ld	a3,16(a0)
    80005dac:	6510                	ld	a2,8(a0)
    80005dae:	610c                	ld	a1,0(a0)
    80005db0:	34051573          	csrrw	a0,mscratch,a0
    80005db4:	30200073          	mret
	...

0000000080005dba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005dba:	1141                	addi	sp,sp,-16
    80005dbc:	e422                	sd	s0,8(sp)
    80005dbe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005dc0:	0c0007b7          	lui	a5,0xc000
    80005dc4:	4705                	li	a4,1
    80005dc6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005dc8:	c3d8                	sw	a4,4(a5)
}
    80005dca:	6422                	ld	s0,8(sp)
    80005dcc:	0141                	addi	sp,sp,16
    80005dce:	8082                	ret

0000000080005dd0 <plicinithart>:

void
plicinithart(void)
{
    80005dd0:	1141                	addi	sp,sp,-16
    80005dd2:	e406                	sd	ra,8(sp)
    80005dd4:	e022                	sd	s0,0(sp)
    80005dd6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005dd8:	ffffc097          	auipc	ra,0xffffc
    80005ddc:	be4080e7          	jalr	-1052(ra) # 800019bc <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005de0:	0085171b          	slliw	a4,a0,0x8
    80005de4:	0c0027b7          	lui	a5,0xc002
    80005de8:	97ba                	add	a5,a5,a4
    80005dea:	40200713          	li	a4,1026
    80005dee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005df2:	00d5151b          	slliw	a0,a0,0xd
    80005df6:	0c2017b7          	lui	a5,0xc201
    80005dfa:	953e                	add	a0,a0,a5
    80005dfc:	00052023          	sw	zero,0(a0)
}
    80005e00:	60a2                	ld	ra,8(sp)
    80005e02:	6402                	ld	s0,0(sp)
    80005e04:	0141                	addi	sp,sp,16
    80005e06:	8082                	ret

0000000080005e08 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e08:	1141                	addi	sp,sp,-16
    80005e0a:	e406                	sd	ra,8(sp)
    80005e0c:	e022                	sd	s0,0(sp)
    80005e0e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e10:	ffffc097          	auipc	ra,0xffffc
    80005e14:	bac080e7          	jalr	-1108(ra) # 800019bc <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e18:	00d5179b          	slliw	a5,a0,0xd
    80005e1c:	0c201537          	lui	a0,0xc201
    80005e20:	953e                	add	a0,a0,a5
  return irq;
}
    80005e22:	4148                	lw	a0,4(a0)
    80005e24:	60a2                	ld	ra,8(sp)
    80005e26:	6402                	ld	s0,0(sp)
    80005e28:	0141                	addi	sp,sp,16
    80005e2a:	8082                	ret

0000000080005e2c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e2c:	1101                	addi	sp,sp,-32
    80005e2e:	ec06                	sd	ra,24(sp)
    80005e30:	e822                	sd	s0,16(sp)
    80005e32:	e426                	sd	s1,8(sp)
    80005e34:	1000                	addi	s0,sp,32
    80005e36:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e38:	ffffc097          	auipc	ra,0xffffc
    80005e3c:	b84080e7          	jalr	-1148(ra) # 800019bc <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e40:	00d5151b          	slliw	a0,a0,0xd
    80005e44:	0c2017b7          	lui	a5,0xc201
    80005e48:	97aa                	add	a5,a5,a0
    80005e4a:	c3c4                	sw	s1,4(a5)
}
    80005e4c:	60e2                	ld	ra,24(sp)
    80005e4e:	6442                	ld	s0,16(sp)
    80005e50:	64a2                	ld	s1,8(sp)
    80005e52:	6105                	addi	sp,sp,32
    80005e54:	8082                	ret

0000000080005e56 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e56:	1141                	addi	sp,sp,-16
    80005e58:	e406                	sd	ra,8(sp)
    80005e5a:	e022                	sd	s0,0(sp)
    80005e5c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e5e:	479d                	li	a5,7
    80005e60:	04a7cc63          	blt	a5,a0,80005eb8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005e64:	0001c797          	auipc	a5,0x1c
    80005e68:	f2c78793          	addi	a5,a5,-212 # 80021d90 <disk>
    80005e6c:	97aa                	add	a5,a5,a0
    80005e6e:	0187c783          	lbu	a5,24(a5)
    80005e72:	ebb9                	bnez	a5,80005ec8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e74:	00451613          	slli	a2,a0,0x4
    80005e78:	0001c797          	auipc	a5,0x1c
    80005e7c:	f1878793          	addi	a5,a5,-232 # 80021d90 <disk>
    80005e80:	6394                	ld	a3,0(a5)
    80005e82:	96b2                	add	a3,a3,a2
    80005e84:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005e88:	6398                	ld	a4,0(a5)
    80005e8a:	9732                	add	a4,a4,a2
    80005e8c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005e90:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005e94:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005e98:	953e                	add	a0,a0,a5
    80005e9a:	4785                	li	a5,1
    80005e9c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005ea0:	0001c517          	auipc	a0,0x1c
    80005ea4:	f0850513          	addi	a0,a0,-248 # 80021da8 <disk+0x18>
    80005ea8:	ffffc097          	auipc	ra,0xffffc
    80005eac:	260080e7          	jalr	608(ra) # 80002108 <wakeup>
}
    80005eb0:	60a2                	ld	ra,8(sp)
    80005eb2:	6402                	ld	s0,0(sp)
    80005eb4:	0141                	addi	sp,sp,16
    80005eb6:	8082                	ret
    panic("free_desc 1");
    80005eb8:	00003517          	auipc	a0,0x3
    80005ebc:	8f050513          	addi	a0,a0,-1808 # 800087a8 <syscalls+0x308>
    80005ec0:	ffffa097          	auipc	ra,0xffffa
    80005ec4:	684080e7          	jalr	1668(ra) # 80000544 <panic>
    panic("free_desc 2");
    80005ec8:	00003517          	auipc	a0,0x3
    80005ecc:	8f050513          	addi	a0,a0,-1808 # 800087b8 <syscalls+0x318>
    80005ed0:	ffffa097          	auipc	ra,0xffffa
    80005ed4:	674080e7          	jalr	1652(ra) # 80000544 <panic>

0000000080005ed8 <virtio_disk_init>:
{
    80005ed8:	1101                	addi	sp,sp,-32
    80005eda:	ec06                	sd	ra,24(sp)
    80005edc:	e822                	sd	s0,16(sp)
    80005ede:	e426                	sd	s1,8(sp)
    80005ee0:	e04a                	sd	s2,0(sp)
    80005ee2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005ee4:	00003597          	auipc	a1,0x3
    80005ee8:	8e458593          	addi	a1,a1,-1820 # 800087c8 <syscalls+0x328>
    80005eec:	0001c517          	auipc	a0,0x1c
    80005ef0:	fcc50513          	addi	a0,a0,-52 # 80021eb8 <disk+0x128>
    80005ef4:	ffffb097          	auipc	ra,0xffffb
    80005ef8:	c88080e7          	jalr	-888(ra) # 80000b7c <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005efc:	100017b7          	lui	a5,0x10001
    80005f00:	4398                	lw	a4,0(a5)
    80005f02:	2701                	sext.w	a4,a4
    80005f04:	747277b7          	lui	a5,0x74727
    80005f08:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f0c:	14f71e63          	bne	a4,a5,80006068 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005f10:	100017b7          	lui	a5,0x10001
    80005f14:	43dc                	lw	a5,4(a5)
    80005f16:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f18:	4709                	li	a4,2
    80005f1a:	14e79763          	bne	a5,a4,80006068 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f1e:	100017b7          	lui	a5,0x10001
    80005f22:	479c                	lw	a5,8(a5)
    80005f24:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005f26:	14e79163          	bne	a5,a4,80006068 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f2a:	100017b7          	lui	a5,0x10001
    80005f2e:	47d8                	lw	a4,12(a5)
    80005f30:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f32:	554d47b7          	lui	a5,0x554d4
    80005f36:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f3a:	12f71763          	bne	a4,a5,80006068 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f3e:	100017b7          	lui	a5,0x10001
    80005f42:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f46:	4705                	li	a4,1
    80005f48:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f4a:	470d                	li	a4,3
    80005f4c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f4e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f50:	c7ffe737          	lui	a4,0xc7ffe
    80005f54:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc88f>
    80005f58:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f5a:	2701                	sext.w	a4,a4
    80005f5c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f5e:	472d                	li	a4,11
    80005f60:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005f62:	0707a903          	lw	s2,112(a5)
    80005f66:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005f68:	00897793          	andi	a5,s2,8
    80005f6c:	10078663          	beqz	a5,80006078 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f70:	100017b7          	lui	a5,0x10001
    80005f74:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005f78:	43fc                	lw	a5,68(a5)
    80005f7a:	2781                	sext.w	a5,a5
    80005f7c:	10079663          	bnez	a5,80006088 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f80:	100017b7          	lui	a5,0x10001
    80005f84:	5bdc                	lw	a5,52(a5)
    80005f86:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f88:	10078863          	beqz	a5,80006098 <virtio_disk_init+0x1c0>
  if(max < NUM)
    80005f8c:	471d                	li	a4,7
    80005f8e:	10f77d63          	bgeu	a4,a5,800060a8 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    80005f92:	ffffb097          	auipc	ra,0xffffb
    80005f96:	b68080e7          	jalr	-1176(ra) # 80000afa <kalloc>
    80005f9a:	0001c497          	auipc	s1,0x1c
    80005f9e:	df648493          	addi	s1,s1,-522 # 80021d90 <disk>
    80005fa2:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005fa4:	ffffb097          	auipc	ra,0xffffb
    80005fa8:	b56080e7          	jalr	-1194(ra) # 80000afa <kalloc>
    80005fac:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005fae:	ffffb097          	auipc	ra,0xffffb
    80005fb2:	b4c080e7          	jalr	-1204(ra) # 80000afa <kalloc>
    80005fb6:	87aa                	mv	a5,a0
    80005fb8:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005fba:	6088                	ld	a0,0(s1)
    80005fbc:	cd75                	beqz	a0,800060b8 <virtio_disk_init+0x1e0>
    80005fbe:	0001c717          	auipc	a4,0x1c
    80005fc2:	dda73703          	ld	a4,-550(a4) # 80021d98 <disk+0x8>
    80005fc6:	cb6d                	beqz	a4,800060b8 <virtio_disk_init+0x1e0>
    80005fc8:	cbe5                	beqz	a5,800060b8 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    80005fca:	6605                	lui	a2,0x1
    80005fcc:	4581                	li	a1,0
    80005fce:	ffffb097          	auipc	ra,0xffffb
    80005fd2:	d3a080e7          	jalr	-710(ra) # 80000d08 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005fd6:	0001c497          	auipc	s1,0x1c
    80005fda:	dba48493          	addi	s1,s1,-582 # 80021d90 <disk>
    80005fde:	6605                	lui	a2,0x1
    80005fe0:	4581                	li	a1,0
    80005fe2:	6488                	ld	a0,8(s1)
    80005fe4:	ffffb097          	auipc	ra,0xffffb
    80005fe8:	d24080e7          	jalr	-732(ra) # 80000d08 <memset>
  memset(disk.used, 0, PGSIZE);
    80005fec:	6605                	lui	a2,0x1
    80005fee:	4581                	li	a1,0
    80005ff0:	6888                	ld	a0,16(s1)
    80005ff2:	ffffb097          	auipc	ra,0xffffb
    80005ff6:	d16080e7          	jalr	-746(ra) # 80000d08 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005ffa:	100017b7          	lui	a5,0x10001
    80005ffe:	4721                	li	a4,8
    80006000:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006002:	4098                	lw	a4,0(s1)
    80006004:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006008:	40d8                	lw	a4,4(s1)
    8000600a:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000600e:	6498                	ld	a4,8(s1)
    80006010:	0007069b          	sext.w	a3,a4
    80006014:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006018:	9701                	srai	a4,a4,0x20
    8000601a:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000601e:	6898                	ld	a4,16(s1)
    80006020:	0007069b          	sext.w	a3,a4
    80006024:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006028:	9701                	srai	a4,a4,0x20
    8000602a:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000602e:	4685                	li	a3,1
    80006030:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    80006032:	4705                	li	a4,1
    80006034:	00d48c23          	sb	a3,24(s1)
    80006038:	00e48ca3          	sb	a4,25(s1)
    8000603c:	00e48d23          	sb	a4,26(s1)
    80006040:	00e48da3          	sb	a4,27(s1)
    80006044:	00e48e23          	sb	a4,28(s1)
    80006048:	00e48ea3          	sb	a4,29(s1)
    8000604c:	00e48f23          	sb	a4,30(s1)
    80006050:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006054:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006058:	0727a823          	sw	s2,112(a5)
}
    8000605c:	60e2                	ld	ra,24(sp)
    8000605e:	6442                	ld	s0,16(sp)
    80006060:	64a2                	ld	s1,8(sp)
    80006062:	6902                	ld	s2,0(sp)
    80006064:	6105                	addi	sp,sp,32
    80006066:	8082                	ret
    panic("could not find virtio disk");
    80006068:	00002517          	auipc	a0,0x2
    8000606c:	77050513          	addi	a0,a0,1904 # 800087d8 <syscalls+0x338>
    80006070:	ffffa097          	auipc	ra,0xffffa
    80006074:	4d4080e7          	jalr	1236(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006078:	00002517          	auipc	a0,0x2
    8000607c:	78050513          	addi	a0,a0,1920 # 800087f8 <syscalls+0x358>
    80006080:	ffffa097          	auipc	ra,0xffffa
    80006084:	4c4080e7          	jalr	1220(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    80006088:	00002517          	auipc	a0,0x2
    8000608c:	79050513          	addi	a0,a0,1936 # 80008818 <syscalls+0x378>
    80006090:	ffffa097          	auipc	ra,0xffffa
    80006094:	4b4080e7          	jalr	1204(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    80006098:	00002517          	auipc	a0,0x2
    8000609c:	7a050513          	addi	a0,a0,1952 # 80008838 <syscalls+0x398>
    800060a0:	ffffa097          	auipc	ra,0xffffa
    800060a4:	4a4080e7          	jalr	1188(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    800060a8:	00002517          	auipc	a0,0x2
    800060ac:	7b050513          	addi	a0,a0,1968 # 80008858 <syscalls+0x3b8>
    800060b0:	ffffa097          	auipc	ra,0xffffa
    800060b4:	494080e7          	jalr	1172(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    800060b8:	00002517          	auipc	a0,0x2
    800060bc:	7c050513          	addi	a0,a0,1984 # 80008878 <syscalls+0x3d8>
    800060c0:	ffffa097          	auipc	ra,0xffffa
    800060c4:	484080e7          	jalr	1156(ra) # 80000544 <panic>

00000000800060c8 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800060c8:	7159                	addi	sp,sp,-112
    800060ca:	f486                	sd	ra,104(sp)
    800060cc:	f0a2                	sd	s0,96(sp)
    800060ce:	eca6                	sd	s1,88(sp)
    800060d0:	e8ca                	sd	s2,80(sp)
    800060d2:	e4ce                	sd	s3,72(sp)
    800060d4:	e0d2                	sd	s4,64(sp)
    800060d6:	fc56                	sd	s5,56(sp)
    800060d8:	f85a                	sd	s6,48(sp)
    800060da:	f45e                	sd	s7,40(sp)
    800060dc:	f062                	sd	s8,32(sp)
    800060de:	ec66                	sd	s9,24(sp)
    800060e0:	e86a                	sd	s10,16(sp)
    800060e2:	1880                	addi	s0,sp,112
    800060e4:	892a                	mv	s2,a0
    800060e6:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800060e8:	00c52c83          	lw	s9,12(a0)
    800060ec:	001c9c9b          	slliw	s9,s9,0x1
    800060f0:	1c82                	slli	s9,s9,0x20
    800060f2:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800060f6:	0001c517          	auipc	a0,0x1c
    800060fa:	dc250513          	addi	a0,a0,-574 # 80021eb8 <disk+0x128>
    800060fe:	ffffb097          	auipc	ra,0xffffb
    80006102:	b0e080e7          	jalr	-1266(ra) # 80000c0c <acquire>
  for(int i = 0; i < 3; i++){
    80006106:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006108:	4ba1                	li	s7,8
      disk.free[i] = 0;
    8000610a:	0001cb17          	auipc	s6,0x1c
    8000610e:	c86b0b13          	addi	s6,s6,-890 # 80021d90 <disk>
  for(int i = 0; i < 3; i++){
    80006112:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006114:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006116:	0001cc17          	auipc	s8,0x1c
    8000611a:	da2c0c13          	addi	s8,s8,-606 # 80021eb8 <disk+0x128>
    8000611e:	a8b5                	j	8000619a <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    80006120:	00fb06b3          	add	a3,s6,a5
    80006124:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006128:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000612a:	0207c563          	bltz	a5,80006154 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000612e:	2485                	addiw	s1,s1,1
    80006130:	0711                	addi	a4,a4,4
    80006132:	1f548a63          	beq	s1,s5,80006326 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    80006136:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006138:	0001c697          	auipc	a3,0x1c
    8000613c:	c5868693          	addi	a3,a3,-936 # 80021d90 <disk>
    80006140:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006142:	0186c583          	lbu	a1,24(a3)
    80006146:	fde9                	bnez	a1,80006120 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006148:	2785                	addiw	a5,a5,1
    8000614a:	0685                	addi	a3,a3,1
    8000614c:	ff779be3          	bne	a5,s7,80006142 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80006150:	57fd                	li	a5,-1
    80006152:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006154:	02905a63          	blez	s1,80006188 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006158:	f9042503          	lw	a0,-112(s0)
    8000615c:	00000097          	auipc	ra,0x0
    80006160:	cfa080e7          	jalr	-774(ra) # 80005e56 <free_desc>
      for(int j = 0; j < i; j++)
    80006164:	4785                	li	a5,1
    80006166:	0297d163          	bge	a5,s1,80006188 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000616a:	f9442503          	lw	a0,-108(s0)
    8000616e:	00000097          	auipc	ra,0x0
    80006172:	ce8080e7          	jalr	-792(ra) # 80005e56 <free_desc>
      for(int j = 0; j < i; j++)
    80006176:	4789                	li	a5,2
    80006178:	0097d863          	bge	a5,s1,80006188 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000617c:	f9842503          	lw	a0,-104(s0)
    80006180:	00000097          	auipc	ra,0x0
    80006184:	cd6080e7          	jalr	-810(ra) # 80005e56 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006188:	85e2                	mv	a1,s8
    8000618a:	0001c517          	auipc	a0,0x1c
    8000618e:	c1e50513          	addi	a0,a0,-994 # 80021da8 <disk+0x18>
    80006192:	ffffc097          	auipc	ra,0xffffc
    80006196:	f12080e7          	jalr	-238(ra) # 800020a4 <sleep>
  for(int i = 0; i < 3; i++){
    8000619a:	f9040713          	addi	a4,s0,-112
    8000619e:	84ce                	mv	s1,s3
    800061a0:	bf59                	j	80006136 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800061a2:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    800061a6:	00479693          	slli	a3,a5,0x4
    800061aa:	0001c797          	auipc	a5,0x1c
    800061ae:	be678793          	addi	a5,a5,-1050 # 80021d90 <disk>
    800061b2:	97b6                	add	a5,a5,a3
    800061b4:	4685                	li	a3,1
    800061b6:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800061b8:	0001c597          	auipc	a1,0x1c
    800061bc:	bd858593          	addi	a1,a1,-1064 # 80021d90 <disk>
    800061c0:	00a60793          	addi	a5,a2,10
    800061c4:	0792                	slli	a5,a5,0x4
    800061c6:	97ae                	add	a5,a5,a1
    800061c8:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    800061cc:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800061d0:	f6070693          	addi	a3,a4,-160
    800061d4:	619c                	ld	a5,0(a1)
    800061d6:	97b6                	add	a5,a5,a3
    800061d8:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800061da:	6188                	ld	a0,0(a1)
    800061dc:	96aa                	add	a3,a3,a0
    800061de:	47c1                	li	a5,16
    800061e0:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800061e2:	4785                	li	a5,1
    800061e4:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    800061e8:	f9442783          	lw	a5,-108(s0)
    800061ec:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800061f0:	0792                	slli	a5,a5,0x4
    800061f2:	953e                	add	a0,a0,a5
    800061f4:	05890693          	addi	a3,s2,88
    800061f8:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    800061fa:	6188                	ld	a0,0(a1)
    800061fc:	97aa                	add	a5,a5,a0
    800061fe:	40000693          	li	a3,1024
    80006202:	c794                	sw	a3,8(a5)
  if(write)
    80006204:	100d0d63          	beqz	s10,8000631e <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006208:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000620c:	00c7d683          	lhu	a3,12(a5)
    80006210:	0016e693          	ori	a3,a3,1
    80006214:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    80006218:	f9842583          	lw	a1,-104(s0)
    8000621c:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006220:	0001c697          	auipc	a3,0x1c
    80006224:	b7068693          	addi	a3,a3,-1168 # 80021d90 <disk>
    80006228:	00260793          	addi	a5,a2,2
    8000622c:	0792                	slli	a5,a5,0x4
    8000622e:	97b6                	add	a5,a5,a3
    80006230:	587d                	li	a6,-1
    80006232:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006236:	0592                	slli	a1,a1,0x4
    80006238:	952e                	add	a0,a0,a1
    8000623a:	f9070713          	addi	a4,a4,-112
    8000623e:	9736                	add	a4,a4,a3
    80006240:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    80006242:	6298                	ld	a4,0(a3)
    80006244:	972e                	add	a4,a4,a1
    80006246:	4585                	li	a1,1
    80006248:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000624a:	4509                	li	a0,2
    8000624c:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    80006250:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006254:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006258:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    8000625c:	6698                	ld	a4,8(a3)
    8000625e:	00275783          	lhu	a5,2(a4)
    80006262:	8b9d                	andi	a5,a5,7
    80006264:	0786                	slli	a5,a5,0x1
    80006266:	97ba                	add	a5,a5,a4
    80006268:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    8000626c:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006270:	6698                	ld	a4,8(a3)
    80006272:	00275783          	lhu	a5,2(a4)
    80006276:	2785                	addiw	a5,a5,1
    80006278:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    8000627c:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006280:	100017b7          	lui	a5,0x10001
    80006284:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006288:	00492703          	lw	a4,4(s2)
    8000628c:	4785                	li	a5,1
    8000628e:	02f71163          	bne	a4,a5,800062b0 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    80006292:	0001c997          	auipc	s3,0x1c
    80006296:	c2698993          	addi	s3,s3,-986 # 80021eb8 <disk+0x128>
  while(b->disk == 1) {
    8000629a:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000629c:	85ce                	mv	a1,s3
    8000629e:	854a                	mv	a0,s2
    800062a0:	ffffc097          	auipc	ra,0xffffc
    800062a4:	e04080e7          	jalr	-508(ra) # 800020a4 <sleep>
  while(b->disk == 1) {
    800062a8:	00492783          	lw	a5,4(s2)
    800062ac:	fe9788e3          	beq	a5,s1,8000629c <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    800062b0:	f9042903          	lw	s2,-112(s0)
    800062b4:	00290793          	addi	a5,s2,2
    800062b8:	00479713          	slli	a4,a5,0x4
    800062bc:	0001c797          	auipc	a5,0x1c
    800062c0:	ad478793          	addi	a5,a5,-1324 # 80021d90 <disk>
    800062c4:	97ba                	add	a5,a5,a4
    800062c6:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800062ca:	0001c997          	auipc	s3,0x1c
    800062ce:	ac698993          	addi	s3,s3,-1338 # 80021d90 <disk>
    800062d2:	00491713          	slli	a4,s2,0x4
    800062d6:	0009b783          	ld	a5,0(s3)
    800062da:	97ba                	add	a5,a5,a4
    800062dc:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800062e0:	854a                	mv	a0,s2
    800062e2:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800062e6:	00000097          	auipc	ra,0x0
    800062ea:	b70080e7          	jalr	-1168(ra) # 80005e56 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800062ee:	8885                	andi	s1,s1,1
    800062f0:	f0ed                	bnez	s1,800062d2 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800062f2:	0001c517          	auipc	a0,0x1c
    800062f6:	bc650513          	addi	a0,a0,-1082 # 80021eb8 <disk+0x128>
    800062fa:	ffffb097          	auipc	ra,0xffffb
    800062fe:	9c6080e7          	jalr	-1594(ra) # 80000cc0 <release>
}
    80006302:	70a6                	ld	ra,104(sp)
    80006304:	7406                	ld	s0,96(sp)
    80006306:	64e6                	ld	s1,88(sp)
    80006308:	6946                	ld	s2,80(sp)
    8000630a:	69a6                	ld	s3,72(sp)
    8000630c:	6a06                	ld	s4,64(sp)
    8000630e:	7ae2                	ld	s5,56(sp)
    80006310:	7b42                	ld	s6,48(sp)
    80006312:	7ba2                	ld	s7,40(sp)
    80006314:	7c02                	ld	s8,32(sp)
    80006316:	6ce2                	ld	s9,24(sp)
    80006318:	6d42                	ld	s10,16(sp)
    8000631a:	6165                	addi	sp,sp,112
    8000631c:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000631e:	4689                	li	a3,2
    80006320:	00d79623          	sh	a3,12(a5)
    80006324:	b5e5                	j	8000620c <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006326:	f9042603          	lw	a2,-112(s0)
    8000632a:	00a60713          	addi	a4,a2,10
    8000632e:	0712                	slli	a4,a4,0x4
    80006330:	0001c517          	auipc	a0,0x1c
    80006334:	a6850513          	addi	a0,a0,-1432 # 80021d98 <disk+0x8>
    80006338:	953a                	add	a0,a0,a4
  if(write)
    8000633a:	e60d14e3          	bnez	s10,800061a2 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    8000633e:	00a60793          	addi	a5,a2,10
    80006342:	00479693          	slli	a3,a5,0x4
    80006346:	0001c797          	auipc	a5,0x1c
    8000634a:	a4a78793          	addi	a5,a5,-1462 # 80021d90 <disk>
    8000634e:	97b6                	add	a5,a5,a3
    80006350:	0007a423          	sw	zero,8(a5)
    80006354:	b595                	j	800061b8 <virtio_disk_rw+0xf0>

0000000080006356 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006356:	1101                	addi	sp,sp,-32
    80006358:	ec06                	sd	ra,24(sp)
    8000635a:	e822                	sd	s0,16(sp)
    8000635c:	e426                	sd	s1,8(sp)
    8000635e:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006360:	0001c497          	auipc	s1,0x1c
    80006364:	a3048493          	addi	s1,s1,-1488 # 80021d90 <disk>
    80006368:	0001c517          	auipc	a0,0x1c
    8000636c:	b5050513          	addi	a0,a0,-1200 # 80021eb8 <disk+0x128>
    80006370:	ffffb097          	auipc	ra,0xffffb
    80006374:	89c080e7          	jalr	-1892(ra) # 80000c0c <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006378:	10001737          	lui	a4,0x10001
    8000637c:	533c                	lw	a5,96(a4)
    8000637e:	8b8d                	andi	a5,a5,3
    80006380:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006382:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006386:	689c                	ld	a5,16(s1)
    80006388:	0204d703          	lhu	a4,32(s1)
    8000638c:	0027d783          	lhu	a5,2(a5)
    80006390:	04f70863          	beq	a4,a5,800063e0 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006394:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006398:	6898                	ld	a4,16(s1)
    8000639a:	0204d783          	lhu	a5,32(s1)
    8000639e:	8b9d                	andi	a5,a5,7
    800063a0:	078e                	slli	a5,a5,0x3
    800063a2:	97ba                	add	a5,a5,a4
    800063a4:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800063a6:	00278713          	addi	a4,a5,2
    800063aa:	0712                	slli	a4,a4,0x4
    800063ac:	9726                	add	a4,a4,s1
    800063ae:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800063b2:	e721                	bnez	a4,800063fa <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800063b4:	0789                	addi	a5,a5,2
    800063b6:	0792                	slli	a5,a5,0x4
    800063b8:	97a6                	add	a5,a5,s1
    800063ba:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800063bc:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800063c0:	ffffc097          	auipc	ra,0xffffc
    800063c4:	d48080e7          	jalr	-696(ra) # 80002108 <wakeup>

    disk.used_idx += 1;
    800063c8:	0204d783          	lhu	a5,32(s1)
    800063cc:	2785                	addiw	a5,a5,1
    800063ce:	17c2                	slli	a5,a5,0x30
    800063d0:	93c1                	srli	a5,a5,0x30
    800063d2:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800063d6:	6898                	ld	a4,16(s1)
    800063d8:	00275703          	lhu	a4,2(a4)
    800063dc:	faf71ce3          	bne	a4,a5,80006394 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800063e0:	0001c517          	auipc	a0,0x1c
    800063e4:	ad850513          	addi	a0,a0,-1320 # 80021eb8 <disk+0x128>
    800063e8:	ffffb097          	auipc	ra,0xffffb
    800063ec:	8d8080e7          	jalr	-1832(ra) # 80000cc0 <release>
}
    800063f0:	60e2                	ld	ra,24(sp)
    800063f2:	6442                	ld	s0,16(sp)
    800063f4:	64a2                	ld	s1,8(sp)
    800063f6:	6105                	addi	sp,sp,32
    800063f8:	8082                	ret
      panic("virtio_disk_intr status");
    800063fa:	00002517          	auipc	a0,0x2
    800063fe:	49650513          	addi	a0,a0,1174 # 80008890 <syscalls+0x3f0>
    80006402:	ffffa097          	auipc	ra,0xffffa
    80006406:	142080e7          	jalr	322(ra) # 80000544 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
