
user/_test:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <print_sysinfo>:
	int ppid;
	int syscall_count;
	int page_usage;
};
void print_sysinfo(void)
{
   0:	1101                	addi	sp,sp,-32
   2:	ec06                	sd	ra,24(sp)
   4:	e822                	sd	s0,16(sp)
   6:	e426                	sd	s1,8(sp)
   8:	e04a                	sd	s2,0(sp)
   a:	1000                	addi	s0,sp,32
	int n_active_proc, n_syscalls, n_free_pages;
	n_active_proc = sysinfo(0);
   c:	4501                	li	a0,0
   e:	00000097          	auipc	ra,0x0
  12:	49a080e7          	jalr	1178(ra) # 4a8 <sysinfo>
  16:	84aa                	mv	s1,a0
	n_syscalls = sysinfo(1);
  18:	4505                	li	a0,1
  1a:	00000097          	auipc	ra,0x0
  1e:	48e080e7          	jalr	1166(ra) # 4a8 <sysinfo>
  22:	892a                	mv	s2,a0
	n_free_pages = sysinfo(2);
  24:	4509                	li	a0,2
  26:	00000097          	auipc	ra,0x0
  2a:	482080e7          	jalr	1154(ra) # 4a8 <sysinfo>
  2e:	86aa                	mv	a3,a0
	printf("[sysinfo] active proc: %d, syscalls: %d, free pages: %d\n", n_active_proc, n_syscalls, n_free_pages);
  30:	864a                	mv	a2,s2
  32:	85a6                	mv	a1,s1
  34:	00001517          	auipc	a0,0x1
  38:	90c50513          	addi	a0,a0,-1780 # 940 <malloc+0xf2>
  3c:	00000097          	auipc	ra,0x0
  40:	754080e7          	jalr	1876(ra) # 790 <printf>
}
  44:	60e2                	ld	ra,24(sp)
  46:	6442                	ld	s0,16(sp)
  48:	64a2                	ld	s1,8(sp)
  4a:	6902                	ld	s2,0(sp)
  4c:	6105                	addi	sp,sp,32
  4e:	8082                	ret

0000000000000050 <main>:

int main(int argc, char *argv[])
{
  50:	7159                	addi	sp,sp,-112
  52:	f486                	sd	ra,104(sp)
  54:	f0a2                	sd	s0,96(sp)
  56:	eca6                	sd	s1,88(sp)
  58:	e8ca                	sd	s2,80(sp)
  5a:	e4ce                	sd	s3,72(sp)
  5c:	1880                	addi	s0,sp,112
  5e:	84ae                	mv	s1,a1
	int mem, n_proc, ret, proc_pid[MAX_PROC];
	if (argc < 3) 
  60:	4789                	li	a5,2
  62:	02a7c063          	blt	a5,a0,82 <main+0x32>
	{
		printf("Usage: %s [MEM] [N_PROC]\n", argv[0]);
  66:	618c                	ld	a1,0(a1)
  68:	00001517          	auipc	a0,0x1
  6c:	91850513          	addi	a0,a0,-1768 # 980 <malloc+0x132>
  70:	00000097          	auipc	ra,0x0
  74:	720080e7          	jalr	1824(ra) # 790 <printf>
		exit(-1);
  78:	557d                	li	a0,-1
  7a:	00000097          	auipc	ra,0x0
  7e:	386080e7          	jalr	902(ra) # 400 <exit>
	}	
	mem = atoi(argv[1]);
  82:	6588                	ld	a0,8(a1)
  84:	00000097          	auipc	ra,0x0
  88:	27c080e7          	jalr	636(ra) # 300 <atoi>
  8c:	89aa                	mv	s3,a0
	n_proc = atoi(argv[2]);
  8e:	6888                	ld	a0,16(s1)
  90:	00000097          	auipc	ra,0x0
  94:	270080e7          	jalr	624(ra) # 300 <atoi>
  98:	84aa                	mv	s1,a0
	if (n_proc > MAX_PROC) 
  9a:	47a9                	li	a5,10
  9c:	02a7d063          	bge	a5,a0,bc <main+0x6c>
	{
		printf("Cannot test with more than %d processes\n", MAX_PROC);
  a0:	45a9                	li	a1,10
  a2:	00001517          	auipc	a0,0x1
  a6:	8fe50513          	addi	a0,a0,-1794 # 9a0 <malloc+0x152>
  aa:	00000097          	auipc	ra,0x0
  ae:	6e6080e7          	jalr	1766(ra) # 790 <printf>
		exit(-1);
  b2:	557d                	li	a0,-1
  b4:	00000097          	auipc	ra,0x0
  b8:	34c080e7          	jalr	844(ra) # 400 <exit>
	}
	print_sysinfo();
  bc:	00000097          	auipc	ra,0x0
  c0:	f44080e7          	jalr	-188(ra) # 0 <print_sysinfo>
	for (int i = 0; i < n_proc; i++)
  c4:	4901                	li	s2,0
  c6:	0009079b          	sext.w	a5,s2
  ca:	0697d763          	bge	a5,s1,138 <main+0xe8>
	{
		sleep(1);
  ce:	4505                	li	a0,1
  d0:	00000097          	auipc	ra,0x0
  d4:	3c0080e7          	jalr	960(ra) # 490 <sleep>
		ret = fork();
  d8:	00000097          	auipc	ra,0x0
  dc:	320080e7          	jalr	800(ra) # 3f8 <fork>
		if (ret == 0) // child process
  e0:	e521                	bnez	a0,128 <main+0xd8>
		{
			struct pinfo param;
			malloc(mem); // this triggers a syscall
  e2:	0009851b          	sext.w	a0,s3
  e6:	00000097          	auipc	ra,0x0
  ea:	768080e7          	jalr	1896(ra) # 84e <malloc>
  ee:	44a9                	li	s1,10
			for (int j = 0; j < 10; j++)
				procinfo(&param); // calls 10 times
  f0:	f9840513          	addi	a0,s0,-104
  f4:	00000097          	auipc	ra,0x0
  f8:	3bc080e7          	jalr	956(ra) # 4b0 <procinfo>
			for (int j = 0; j < 10; j++)
  fc:	34fd                	addiw	s1,s1,-1
  fe:	f8ed                	bnez	s1,f0 <main+0xa0>
			printf("[procinfo %d] ppid: %d, syscalls: %d, page usage: %d\n", getpid(), param.ppid, param.syscall_count, param.page_usage);
 100:	00000097          	auipc	ra,0x0
 104:	380080e7          	jalr	896(ra) # 480 <getpid>
 108:	85aa                	mv	a1,a0
 10a:	fa042703          	lw	a4,-96(s0)
 10e:	f9c42683          	lw	a3,-100(s0)
 112:	f9842603          	lw	a2,-104(s0)
 116:	00001517          	auipc	a0,0x1
 11a:	8ba50513          	addi	a0,a0,-1862 # 9d0 <malloc+0x182>
 11e:	00000097          	auipc	ra,0x0
 122:	672080e7          	jalr	1650(ra) # 790 <printf>
			while (1);
 126:	a001                	j	126 <main+0xd6>
		}
		else // parent
		{
			proc_pid[i] = ret;
 128:	00291713          	slli	a4,s2,0x2
 12c:	fa840693          	addi	a3,s0,-88
 130:	9736                	add	a4,a4,a3
 132:	c308                	sw	a0,0(a4)
	for (int i = 0; i < n_proc; i++)
 134:	0905                	addi	s2,s2,1
 136:	bf41                	j	c6 <main+0x76>
			continue;
		}
	}
	sleep(1);
 138:	4505                	li	a0,1
 13a:	00000097          	auipc	ra,0x0
 13e:	356080e7          	jalr	854(ra) # 490 <sleep>
	print_sysinfo();
 142:	00000097          	auipc	ra,0x0
 146:	ebe080e7          	jalr	-322(ra) # 0 <print_sysinfo>
	for (int i = 0; i < n_proc; i++) kill(proc_pid[i]);
 14a:	fa840993          	addi	s3,s0,-88
 14e:	4901                	li	s2,0
 150:	a809                	j	162 <main+0x112>
 152:	0009a503          	lw	a0,0(s3)
 156:	00000097          	auipc	ra,0x0
 15a:	2da080e7          	jalr	730(ra) # 430 <kill>
 15e:	2905                	addiw	s2,s2,1
 160:	0991                	addi	s3,s3,4
 162:	fe9948e3          	blt	s2,s1,152 <main+0x102>
	exit(0);
 166:	4501                	li	a0,0
 168:	00000097          	auipc	ra,0x0
 16c:	298080e7          	jalr	664(ra) # 400 <exit>

0000000000000170 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
 170:	1141                	addi	sp,sp,-16
 172:	e406                	sd	ra,8(sp)
 174:	e022                	sd	s0,0(sp)
 176:	0800                	addi	s0,sp,16
  extern int main();
  main();
 178:	00000097          	auipc	ra,0x0
 17c:	ed8080e7          	jalr	-296(ra) # 50 <main>
  exit(0);
 180:	4501                	li	a0,0
 182:	00000097          	auipc	ra,0x0
 186:	27e080e7          	jalr	638(ra) # 400 <exit>

000000000000018a <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 18a:	1141                	addi	sp,sp,-16
 18c:	e422                	sd	s0,8(sp)
 18e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 190:	87aa                	mv	a5,a0
 192:	0585                	addi	a1,a1,1
 194:	0785                	addi	a5,a5,1
 196:	fff5c703          	lbu	a4,-1(a1)
 19a:	fee78fa3          	sb	a4,-1(a5)
 19e:	fb75                	bnez	a4,192 <strcpy+0x8>
    ;
  return os;
}
 1a0:	6422                	ld	s0,8(sp)
 1a2:	0141                	addi	sp,sp,16
 1a4:	8082                	ret

00000000000001a6 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 1a6:	1141                	addi	sp,sp,-16
 1a8:	e422                	sd	s0,8(sp)
 1aa:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 1ac:	00054783          	lbu	a5,0(a0)
 1b0:	cb91                	beqz	a5,1c4 <strcmp+0x1e>
 1b2:	0005c703          	lbu	a4,0(a1)
 1b6:	00f71763          	bne	a4,a5,1c4 <strcmp+0x1e>
    p++, q++;
 1ba:	0505                	addi	a0,a0,1
 1bc:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 1be:	00054783          	lbu	a5,0(a0)
 1c2:	fbe5                	bnez	a5,1b2 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 1c4:	0005c503          	lbu	a0,0(a1)
}
 1c8:	40a7853b          	subw	a0,a5,a0
 1cc:	6422                	ld	s0,8(sp)
 1ce:	0141                	addi	sp,sp,16
 1d0:	8082                	ret

00000000000001d2 <strlen>:

uint
strlen(const char *s)
{
 1d2:	1141                	addi	sp,sp,-16
 1d4:	e422                	sd	s0,8(sp)
 1d6:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 1d8:	00054783          	lbu	a5,0(a0)
 1dc:	cf91                	beqz	a5,1f8 <strlen+0x26>
 1de:	0505                	addi	a0,a0,1
 1e0:	87aa                	mv	a5,a0
 1e2:	4685                	li	a3,1
 1e4:	9e89                	subw	a3,a3,a0
 1e6:	00f6853b          	addw	a0,a3,a5
 1ea:	0785                	addi	a5,a5,1
 1ec:	fff7c703          	lbu	a4,-1(a5)
 1f0:	fb7d                	bnez	a4,1e6 <strlen+0x14>
    ;
  return n;
}
 1f2:	6422                	ld	s0,8(sp)
 1f4:	0141                	addi	sp,sp,16
 1f6:	8082                	ret
  for(n = 0; s[n]; n++)
 1f8:	4501                	li	a0,0
 1fa:	bfe5                	j	1f2 <strlen+0x20>

00000000000001fc <memset>:

void*
memset(void *dst, int c, uint n)
{
 1fc:	1141                	addi	sp,sp,-16
 1fe:	e422                	sd	s0,8(sp)
 200:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 202:	ce09                	beqz	a2,21c <memset+0x20>
 204:	87aa                	mv	a5,a0
 206:	fff6071b          	addiw	a4,a2,-1
 20a:	1702                	slli	a4,a4,0x20
 20c:	9301                	srli	a4,a4,0x20
 20e:	0705                	addi	a4,a4,1
 210:	972a                	add	a4,a4,a0
    cdst[i] = c;
 212:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 216:	0785                	addi	a5,a5,1
 218:	fee79de3          	bne	a5,a4,212 <memset+0x16>
  }
  return dst;
}
 21c:	6422                	ld	s0,8(sp)
 21e:	0141                	addi	sp,sp,16
 220:	8082                	ret

0000000000000222 <strchr>:

char*
strchr(const char *s, char c)
{
 222:	1141                	addi	sp,sp,-16
 224:	e422                	sd	s0,8(sp)
 226:	0800                	addi	s0,sp,16
  for(; *s; s++)
 228:	00054783          	lbu	a5,0(a0)
 22c:	cb99                	beqz	a5,242 <strchr+0x20>
    if(*s == c)
 22e:	00f58763          	beq	a1,a5,23c <strchr+0x1a>
  for(; *s; s++)
 232:	0505                	addi	a0,a0,1
 234:	00054783          	lbu	a5,0(a0)
 238:	fbfd                	bnez	a5,22e <strchr+0xc>
      return (char*)s;
  return 0;
 23a:	4501                	li	a0,0
}
 23c:	6422                	ld	s0,8(sp)
 23e:	0141                	addi	sp,sp,16
 240:	8082                	ret
  return 0;
 242:	4501                	li	a0,0
 244:	bfe5                	j	23c <strchr+0x1a>

0000000000000246 <gets>:

char*
gets(char *buf, int max)
{
 246:	711d                	addi	sp,sp,-96
 248:	ec86                	sd	ra,88(sp)
 24a:	e8a2                	sd	s0,80(sp)
 24c:	e4a6                	sd	s1,72(sp)
 24e:	e0ca                	sd	s2,64(sp)
 250:	fc4e                	sd	s3,56(sp)
 252:	f852                	sd	s4,48(sp)
 254:	f456                	sd	s5,40(sp)
 256:	f05a                	sd	s6,32(sp)
 258:	ec5e                	sd	s7,24(sp)
 25a:	1080                	addi	s0,sp,96
 25c:	8baa                	mv	s7,a0
 25e:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 260:	892a                	mv	s2,a0
 262:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 264:	4aa9                	li	s5,10
 266:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 268:	89a6                	mv	s3,s1
 26a:	2485                	addiw	s1,s1,1
 26c:	0344d863          	bge	s1,s4,29c <gets+0x56>
    cc = read(0, &c, 1);
 270:	4605                	li	a2,1
 272:	faf40593          	addi	a1,s0,-81
 276:	4501                	li	a0,0
 278:	00000097          	auipc	ra,0x0
 27c:	1a0080e7          	jalr	416(ra) # 418 <read>
    if(cc < 1)
 280:	00a05e63          	blez	a0,29c <gets+0x56>
    buf[i++] = c;
 284:	faf44783          	lbu	a5,-81(s0)
 288:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 28c:	01578763          	beq	a5,s5,29a <gets+0x54>
 290:	0905                	addi	s2,s2,1
 292:	fd679be3          	bne	a5,s6,268 <gets+0x22>
  for(i=0; i+1 < max; ){
 296:	89a6                	mv	s3,s1
 298:	a011                	j	29c <gets+0x56>
 29a:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 29c:	99de                	add	s3,s3,s7
 29e:	00098023          	sb	zero,0(s3)
  return buf;
}
 2a2:	855e                	mv	a0,s7
 2a4:	60e6                	ld	ra,88(sp)
 2a6:	6446                	ld	s0,80(sp)
 2a8:	64a6                	ld	s1,72(sp)
 2aa:	6906                	ld	s2,64(sp)
 2ac:	79e2                	ld	s3,56(sp)
 2ae:	7a42                	ld	s4,48(sp)
 2b0:	7aa2                	ld	s5,40(sp)
 2b2:	7b02                	ld	s6,32(sp)
 2b4:	6be2                	ld	s7,24(sp)
 2b6:	6125                	addi	sp,sp,96
 2b8:	8082                	ret

00000000000002ba <stat>:

int
stat(const char *n, struct stat *st)
{
 2ba:	1101                	addi	sp,sp,-32
 2bc:	ec06                	sd	ra,24(sp)
 2be:	e822                	sd	s0,16(sp)
 2c0:	e426                	sd	s1,8(sp)
 2c2:	e04a                	sd	s2,0(sp)
 2c4:	1000                	addi	s0,sp,32
 2c6:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 2c8:	4581                	li	a1,0
 2ca:	00000097          	auipc	ra,0x0
 2ce:	176080e7          	jalr	374(ra) # 440 <open>
  if(fd < 0)
 2d2:	02054563          	bltz	a0,2fc <stat+0x42>
 2d6:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 2d8:	85ca                	mv	a1,s2
 2da:	00000097          	auipc	ra,0x0
 2de:	17e080e7          	jalr	382(ra) # 458 <fstat>
 2e2:	892a                	mv	s2,a0
  close(fd);
 2e4:	8526                	mv	a0,s1
 2e6:	00000097          	auipc	ra,0x0
 2ea:	142080e7          	jalr	322(ra) # 428 <close>
  return r;
}
 2ee:	854a                	mv	a0,s2
 2f0:	60e2                	ld	ra,24(sp)
 2f2:	6442                	ld	s0,16(sp)
 2f4:	64a2                	ld	s1,8(sp)
 2f6:	6902                	ld	s2,0(sp)
 2f8:	6105                	addi	sp,sp,32
 2fa:	8082                	ret
    return -1;
 2fc:	597d                	li	s2,-1
 2fe:	bfc5                	j	2ee <stat+0x34>

0000000000000300 <atoi>:

int
atoi(const char *s)
{
 300:	1141                	addi	sp,sp,-16
 302:	e422                	sd	s0,8(sp)
 304:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 306:	00054603          	lbu	a2,0(a0)
 30a:	fd06079b          	addiw	a5,a2,-48
 30e:	0ff7f793          	andi	a5,a5,255
 312:	4725                	li	a4,9
 314:	02f76963          	bltu	a4,a5,346 <atoi+0x46>
 318:	86aa                	mv	a3,a0
  n = 0;
 31a:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 31c:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 31e:	0685                	addi	a3,a3,1
 320:	0025179b          	slliw	a5,a0,0x2
 324:	9fa9                	addw	a5,a5,a0
 326:	0017979b          	slliw	a5,a5,0x1
 32a:	9fb1                	addw	a5,a5,a2
 32c:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 330:	0006c603          	lbu	a2,0(a3)
 334:	fd06071b          	addiw	a4,a2,-48
 338:	0ff77713          	andi	a4,a4,255
 33c:	fee5f1e3          	bgeu	a1,a4,31e <atoi+0x1e>
  return n;
}
 340:	6422                	ld	s0,8(sp)
 342:	0141                	addi	sp,sp,16
 344:	8082                	ret
  n = 0;
 346:	4501                	li	a0,0
 348:	bfe5                	j	340 <atoi+0x40>

000000000000034a <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 34a:	1141                	addi	sp,sp,-16
 34c:	e422                	sd	s0,8(sp)
 34e:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 350:	02b57663          	bgeu	a0,a1,37c <memmove+0x32>
    while(n-- > 0)
 354:	02c05163          	blez	a2,376 <memmove+0x2c>
 358:	fff6079b          	addiw	a5,a2,-1
 35c:	1782                	slli	a5,a5,0x20
 35e:	9381                	srli	a5,a5,0x20
 360:	0785                	addi	a5,a5,1
 362:	97aa                	add	a5,a5,a0
  dst = vdst;
 364:	872a                	mv	a4,a0
      *dst++ = *src++;
 366:	0585                	addi	a1,a1,1
 368:	0705                	addi	a4,a4,1
 36a:	fff5c683          	lbu	a3,-1(a1)
 36e:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 372:	fee79ae3          	bne	a5,a4,366 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 376:	6422                	ld	s0,8(sp)
 378:	0141                	addi	sp,sp,16
 37a:	8082                	ret
    dst += n;
 37c:	00c50733          	add	a4,a0,a2
    src += n;
 380:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 382:	fec05ae3          	blez	a2,376 <memmove+0x2c>
 386:	fff6079b          	addiw	a5,a2,-1
 38a:	1782                	slli	a5,a5,0x20
 38c:	9381                	srli	a5,a5,0x20
 38e:	fff7c793          	not	a5,a5
 392:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 394:	15fd                	addi	a1,a1,-1
 396:	177d                	addi	a4,a4,-1
 398:	0005c683          	lbu	a3,0(a1)
 39c:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 3a0:	fee79ae3          	bne	a5,a4,394 <memmove+0x4a>
 3a4:	bfc9                	j	376 <memmove+0x2c>

00000000000003a6 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 3a6:	1141                	addi	sp,sp,-16
 3a8:	e422                	sd	s0,8(sp)
 3aa:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 3ac:	ca05                	beqz	a2,3dc <memcmp+0x36>
 3ae:	fff6069b          	addiw	a3,a2,-1
 3b2:	1682                	slli	a3,a3,0x20
 3b4:	9281                	srli	a3,a3,0x20
 3b6:	0685                	addi	a3,a3,1
 3b8:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 3ba:	00054783          	lbu	a5,0(a0)
 3be:	0005c703          	lbu	a4,0(a1)
 3c2:	00e79863          	bne	a5,a4,3d2 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 3c6:	0505                	addi	a0,a0,1
    p2++;
 3c8:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 3ca:	fed518e3          	bne	a0,a3,3ba <memcmp+0x14>
  }
  return 0;
 3ce:	4501                	li	a0,0
 3d0:	a019                	j	3d6 <memcmp+0x30>
      return *p1 - *p2;
 3d2:	40e7853b          	subw	a0,a5,a4
}
 3d6:	6422                	ld	s0,8(sp)
 3d8:	0141                	addi	sp,sp,16
 3da:	8082                	ret
  return 0;
 3dc:	4501                	li	a0,0
 3de:	bfe5                	j	3d6 <memcmp+0x30>

00000000000003e0 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 3e0:	1141                	addi	sp,sp,-16
 3e2:	e406                	sd	ra,8(sp)
 3e4:	e022                	sd	s0,0(sp)
 3e6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 3e8:	00000097          	auipc	ra,0x0
 3ec:	f62080e7          	jalr	-158(ra) # 34a <memmove>
}
 3f0:	60a2                	ld	ra,8(sp)
 3f2:	6402                	ld	s0,0(sp)
 3f4:	0141                	addi	sp,sp,16
 3f6:	8082                	ret

00000000000003f8 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 3f8:	4885                	li	a7,1
 ecall
 3fa:	00000073          	ecall
 ret
 3fe:	8082                	ret

0000000000000400 <exit>:
.global exit
exit:
 li a7, SYS_exit
 400:	4889                	li	a7,2
 ecall
 402:	00000073          	ecall
 ret
 406:	8082                	ret

0000000000000408 <wait>:
.global wait
wait:
 li a7, SYS_wait
 408:	488d                	li	a7,3
 ecall
 40a:	00000073          	ecall
 ret
 40e:	8082                	ret

0000000000000410 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 410:	4891                	li	a7,4
 ecall
 412:	00000073          	ecall
 ret
 416:	8082                	ret

0000000000000418 <read>:
.global read
read:
 li a7, SYS_read
 418:	4895                	li	a7,5
 ecall
 41a:	00000073          	ecall
 ret
 41e:	8082                	ret

0000000000000420 <write>:
.global write
write:
 li a7, SYS_write
 420:	48c1                	li	a7,16
 ecall
 422:	00000073          	ecall
 ret
 426:	8082                	ret

0000000000000428 <close>:
.global close
close:
 li a7, SYS_close
 428:	48d5                	li	a7,21
 ecall
 42a:	00000073          	ecall
 ret
 42e:	8082                	ret

0000000000000430 <kill>:
.global kill
kill:
 li a7, SYS_kill
 430:	4899                	li	a7,6
 ecall
 432:	00000073          	ecall
 ret
 436:	8082                	ret

0000000000000438 <exec>:
.global exec
exec:
 li a7, SYS_exec
 438:	489d                	li	a7,7
 ecall
 43a:	00000073          	ecall
 ret
 43e:	8082                	ret

0000000000000440 <open>:
.global open
open:
 li a7, SYS_open
 440:	48bd                	li	a7,15
 ecall
 442:	00000073          	ecall
 ret
 446:	8082                	ret

0000000000000448 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 448:	48c5                	li	a7,17
 ecall
 44a:	00000073          	ecall
 ret
 44e:	8082                	ret

0000000000000450 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 450:	48c9                	li	a7,18
 ecall
 452:	00000073          	ecall
 ret
 456:	8082                	ret

0000000000000458 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 458:	48a1                	li	a7,8
 ecall
 45a:	00000073          	ecall
 ret
 45e:	8082                	ret

0000000000000460 <link>:
.global link
link:
 li a7, SYS_link
 460:	48cd                	li	a7,19
 ecall
 462:	00000073          	ecall
 ret
 466:	8082                	ret

0000000000000468 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 468:	48d1                	li	a7,20
 ecall
 46a:	00000073          	ecall
 ret
 46e:	8082                	ret

0000000000000470 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 470:	48a5                	li	a7,9
 ecall
 472:	00000073          	ecall
 ret
 476:	8082                	ret

0000000000000478 <dup>:
.global dup
dup:
 li a7, SYS_dup
 478:	48a9                	li	a7,10
 ecall
 47a:	00000073          	ecall
 ret
 47e:	8082                	ret

0000000000000480 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 480:	48ad                	li	a7,11
 ecall
 482:	00000073          	ecall
 ret
 486:	8082                	ret

0000000000000488 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 488:	48b1                	li	a7,12
 ecall
 48a:	00000073          	ecall
 ret
 48e:	8082                	ret

0000000000000490 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 490:	48b5                	li	a7,13
 ecall
 492:	00000073          	ecall
 ret
 496:	8082                	ret

0000000000000498 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 498:	48b9                	li	a7,14
 ecall
 49a:	00000073          	ecall
 ret
 49e:	8082                	ret

00000000000004a0 <hello>:
.global hello
hello:
 li a7, SYS_hello
 4a0:	48d9                	li	a7,22
 ecall
 4a2:	00000073          	ecall
 ret
 4a6:	8082                	ret

00000000000004a8 <sysinfo>:
.global sysinfo
sysinfo:
 li a7, SYS_sysinfo
 4a8:	48dd                	li	a7,23
 ecall
 4aa:	00000073          	ecall
 ret
 4ae:	8082                	ret

00000000000004b0 <procinfo>:
.global procinfo
procinfo:
 li a7, SYS_procinfo
 4b0:	48e1                	li	a7,24
 ecall
 4b2:	00000073          	ecall
 ret
 4b6:	8082                	ret

00000000000004b8 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 4b8:	1101                	addi	sp,sp,-32
 4ba:	ec06                	sd	ra,24(sp)
 4bc:	e822                	sd	s0,16(sp)
 4be:	1000                	addi	s0,sp,32
 4c0:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 4c4:	4605                	li	a2,1
 4c6:	fef40593          	addi	a1,s0,-17
 4ca:	00000097          	auipc	ra,0x0
 4ce:	f56080e7          	jalr	-170(ra) # 420 <write>
}
 4d2:	60e2                	ld	ra,24(sp)
 4d4:	6442                	ld	s0,16(sp)
 4d6:	6105                	addi	sp,sp,32
 4d8:	8082                	ret

00000000000004da <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 4da:	7139                	addi	sp,sp,-64
 4dc:	fc06                	sd	ra,56(sp)
 4de:	f822                	sd	s0,48(sp)
 4e0:	f426                	sd	s1,40(sp)
 4e2:	f04a                	sd	s2,32(sp)
 4e4:	ec4e                	sd	s3,24(sp)
 4e6:	0080                	addi	s0,sp,64
 4e8:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 4ea:	c299                	beqz	a3,4f0 <printint+0x16>
 4ec:	0805c863          	bltz	a1,57c <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 4f0:	2581                	sext.w	a1,a1
  neg = 0;
 4f2:	4881                	li	a7,0
 4f4:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 4f8:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 4fa:	2601                	sext.w	a2,a2
 4fc:	00000517          	auipc	a0,0x0
 500:	51450513          	addi	a0,a0,1300 # a10 <digits>
 504:	883a                	mv	a6,a4
 506:	2705                	addiw	a4,a4,1
 508:	02c5f7bb          	remuw	a5,a1,a2
 50c:	1782                	slli	a5,a5,0x20
 50e:	9381                	srli	a5,a5,0x20
 510:	97aa                	add	a5,a5,a0
 512:	0007c783          	lbu	a5,0(a5)
 516:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 51a:	0005879b          	sext.w	a5,a1
 51e:	02c5d5bb          	divuw	a1,a1,a2
 522:	0685                	addi	a3,a3,1
 524:	fec7f0e3          	bgeu	a5,a2,504 <printint+0x2a>
  if(neg)
 528:	00088b63          	beqz	a7,53e <printint+0x64>
    buf[i++] = '-';
 52c:	fd040793          	addi	a5,s0,-48
 530:	973e                	add	a4,a4,a5
 532:	02d00793          	li	a5,45
 536:	fef70823          	sb	a5,-16(a4)
 53a:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 53e:	02e05863          	blez	a4,56e <printint+0x94>
 542:	fc040793          	addi	a5,s0,-64
 546:	00e78933          	add	s2,a5,a4
 54a:	fff78993          	addi	s3,a5,-1
 54e:	99ba                	add	s3,s3,a4
 550:	377d                	addiw	a4,a4,-1
 552:	1702                	slli	a4,a4,0x20
 554:	9301                	srli	a4,a4,0x20
 556:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 55a:	fff94583          	lbu	a1,-1(s2)
 55e:	8526                	mv	a0,s1
 560:	00000097          	auipc	ra,0x0
 564:	f58080e7          	jalr	-168(ra) # 4b8 <putc>
  while(--i >= 0)
 568:	197d                	addi	s2,s2,-1
 56a:	ff3918e3          	bne	s2,s3,55a <printint+0x80>
}
 56e:	70e2                	ld	ra,56(sp)
 570:	7442                	ld	s0,48(sp)
 572:	74a2                	ld	s1,40(sp)
 574:	7902                	ld	s2,32(sp)
 576:	69e2                	ld	s3,24(sp)
 578:	6121                	addi	sp,sp,64
 57a:	8082                	ret
    x = -xx;
 57c:	40b005bb          	negw	a1,a1
    neg = 1;
 580:	4885                	li	a7,1
    x = -xx;
 582:	bf8d                	j	4f4 <printint+0x1a>

0000000000000584 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 584:	7119                	addi	sp,sp,-128
 586:	fc86                	sd	ra,120(sp)
 588:	f8a2                	sd	s0,112(sp)
 58a:	f4a6                	sd	s1,104(sp)
 58c:	f0ca                	sd	s2,96(sp)
 58e:	ecce                	sd	s3,88(sp)
 590:	e8d2                	sd	s4,80(sp)
 592:	e4d6                	sd	s5,72(sp)
 594:	e0da                	sd	s6,64(sp)
 596:	fc5e                	sd	s7,56(sp)
 598:	f862                	sd	s8,48(sp)
 59a:	f466                	sd	s9,40(sp)
 59c:	f06a                	sd	s10,32(sp)
 59e:	ec6e                	sd	s11,24(sp)
 5a0:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 5a2:	0005c903          	lbu	s2,0(a1)
 5a6:	18090f63          	beqz	s2,744 <vprintf+0x1c0>
 5aa:	8aaa                	mv	s5,a0
 5ac:	8b32                	mv	s6,a2
 5ae:	00158493          	addi	s1,a1,1
  state = 0;
 5b2:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 5b4:	02500a13          	li	s4,37
      if(c == 'd'){
 5b8:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 5bc:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 5c0:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 5c4:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5c8:	00000b97          	auipc	s7,0x0
 5cc:	448b8b93          	addi	s7,s7,1096 # a10 <digits>
 5d0:	a839                	j	5ee <vprintf+0x6a>
        putc(fd, c);
 5d2:	85ca                	mv	a1,s2
 5d4:	8556                	mv	a0,s5
 5d6:	00000097          	auipc	ra,0x0
 5da:	ee2080e7          	jalr	-286(ra) # 4b8 <putc>
 5de:	a019                	j	5e4 <vprintf+0x60>
    } else if(state == '%'){
 5e0:	01498f63          	beq	s3,s4,5fe <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 5e4:	0485                	addi	s1,s1,1
 5e6:	fff4c903          	lbu	s2,-1(s1)
 5ea:	14090d63          	beqz	s2,744 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 5ee:	0009079b          	sext.w	a5,s2
    if(state == 0){
 5f2:	fe0997e3          	bnez	s3,5e0 <vprintf+0x5c>
      if(c == '%'){
 5f6:	fd479ee3          	bne	a5,s4,5d2 <vprintf+0x4e>
        state = '%';
 5fa:	89be                	mv	s3,a5
 5fc:	b7e5                	j	5e4 <vprintf+0x60>
      if(c == 'd'){
 5fe:	05878063          	beq	a5,s8,63e <vprintf+0xba>
      } else if(c == 'l') {
 602:	05978c63          	beq	a5,s9,65a <vprintf+0xd6>
      } else if(c == 'x') {
 606:	07a78863          	beq	a5,s10,676 <vprintf+0xf2>
      } else if(c == 'p') {
 60a:	09b78463          	beq	a5,s11,692 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 60e:	07300713          	li	a4,115
 612:	0ce78663          	beq	a5,a4,6de <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 616:	06300713          	li	a4,99
 61a:	0ee78e63          	beq	a5,a4,716 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 61e:	11478863          	beq	a5,s4,72e <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 622:	85d2                	mv	a1,s4
 624:	8556                	mv	a0,s5
 626:	00000097          	auipc	ra,0x0
 62a:	e92080e7          	jalr	-366(ra) # 4b8 <putc>
        putc(fd, c);
 62e:	85ca                	mv	a1,s2
 630:	8556                	mv	a0,s5
 632:	00000097          	auipc	ra,0x0
 636:	e86080e7          	jalr	-378(ra) # 4b8 <putc>
      }
      state = 0;
 63a:	4981                	li	s3,0
 63c:	b765                	j	5e4 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 63e:	008b0913          	addi	s2,s6,8
 642:	4685                	li	a3,1
 644:	4629                	li	a2,10
 646:	000b2583          	lw	a1,0(s6)
 64a:	8556                	mv	a0,s5
 64c:	00000097          	auipc	ra,0x0
 650:	e8e080e7          	jalr	-370(ra) # 4da <printint>
 654:	8b4a                	mv	s6,s2
      state = 0;
 656:	4981                	li	s3,0
 658:	b771                	j	5e4 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 65a:	008b0913          	addi	s2,s6,8
 65e:	4681                	li	a3,0
 660:	4629                	li	a2,10
 662:	000b2583          	lw	a1,0(s6)
 666:	8556                	mv	a0,s5
 668:	00000097          	auipc	ra,0x0
 66c:	e72080e7          	jalr	-398(ra) # 4da <printint>
 670:	8b4a                	mv	s6,s2
      state = 0;
 672:	4981                	li	s3,0
 674:	bf85                	j	5e4 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 676:	008b0913          	addi	s2,s6,8
 67a:	4681                	li	a3,0
 67c:	4641                	li	a2,16
 67e:	000b2583          	lw	a1,0(s6)
 682:	8556                	mv	a0,s5
 684:	00000097          	auipc	ra,0x0
 688:	e56080e7          	jalr	-426(ra) # 4da <printint>
 68c:	8b4a                	mv	s6,s2
      state = 0;
 68e:	4981                	li	s3,0
 690:	bf91                	j	5e4 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 692:	008b0793          	addi	a5,s6,8
 696:	f8f43423          	sd	a5,-120(s0)
 69a:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 69e:	03000593          	li	a1,48
 6a2:	8556                	mv	a0,s5
 6a4:	00000097          	auipc	ra,0x0
 6a8:	e14080e7          	jalr	-492(ra) # 4b8 <putc>
  putc(fd, 'x');
 6ac:	85ea                	mv	a1,s10
 6ae:	8556                	mv	a0,s5
 6b0:	00000097          	auipc	ra,0x0
 6b4:	e08080e7          	jalr	-504(ra) # 4b8 <putc>
 6b8:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6ba:	03c9d793          	srli	a5,s3,0x3c
 6be:	97de                	add	a5,a5,s7
 6c0:	0007c583          	lbu	a1,0(a5)
 6c4:	8556                	mv	a0,s5
 6c6:	00000097          	auipc	ra,0x0
 6ca:	df2080e7          	jalr	-526(ra) # 4b8 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 6ce:	0992                	slli	s3,s3,0x4
 6d0:	397d                	addiw	s2,s2,-1
 6d2:	fe0914e3          	bnez	s2,6ba <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 6d6:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 6da:	4981                	li	s3,0
 6dc:	b721                	j	5e4 <vprintf+0x60>
        s = va_arg(ap, char*);
 6de:	008b0993          	addi	s3,s6,8
 6e2:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 6e6:	02090163          	beqz	s2,708 <vprintf+0x184>
        while(*s != 0){
 6ea:	00094583          	lbu	a1,0(s2)
 6ee:	c9a1                	beqz	a1,73e <vprintf+0x1ba>
          putc(fd, *s);
 6f0:	8556                	mv	a0,s5
 6f2:	00000097          	auipc	ra,0x0
 6f6:	dc6080e7          	jalr	-570(ra) # 4b8 <putc>
          s++;
 6fa:	0905                	addi	s2,s2,1
        while(*s != 0){
 6fc:	00094583          	lbu	a1,0(s2)
 700:	f9e5                	bnez	a1,6f0 <vprintf+0x16c>
        s = va_arg(ap, char*);
 702:	8b4e                	mv	s6,s3
      state = 0;
 704:	4981                	li	s3,0
 706:	bdf9                	j	5e4 <vprintf+0x60>
          s = "(null)";
 708:	00000917          	auipc	s2,0x0
 70c:	30090913          	addi	s2,s2,768 # a08 <malloc+0x1ba>
        while(*s != 0){
 710:	02800593          	li	a1,40
 714:	bff1                	j	6f0 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 716:	008b0913          	addi	s2,s6,8
 71a:	000b4583          	lbu	a1,0(s6)
 71e:	8556                	mv	a0,s5
 720:	00000097          	auipc	ra,0x0
 724:	d98080e7          	jalr	-616(ra) # 4b8 <putc>
 728:	8b4a                	mv	s6,s2
      state = 0;
 72a:	4981                	li	s3,0
 72c:	bd65                	j	5e4 <vprintf+0x60>
        putc(fd, c);
 72e:	85d2                	mv	a1,s4
 730:	8556                	mv	a0,s5
 732:	00000097          	auipc	ra,0x0
 736:	d86080e7          	jalr	-634(ra) # 4b8 <putc>
      state = 0;
 73a:	4981                	li	s3,0
 73c:	b565                	j	5e4 <vprintf+0x60>
        s = va_arg(ap, char*);
 73e:	8b4e                	mv	s6,s3
      state = 0;
 740:	4981                	li	s3,0
 742:	b54d                	j	5e4 <vprintf+0x60>
    }
  }
}
 744:	70e6                	ld	ra,120(sp)
 746:	7446                	ld	s0,112(sp)
 748:	74a6                	ld	s1,104(sp)
 74a:	7906                	ld	s2,96(sp)
 74c:	69e6                	ld	s3,88(sp)
 74e:	6a46                	ld	s4,80(sp)
 750:	6aa6                	ld	s5,72(sp)
 752:	6b06                	ld	s6,64(sp)
 754:	7be2                	ld	s7,56(sp)
 756:	7c42                	ld	s8,48(sp)
 758:	7ca2                	ld	s9,40(sp)
 75a:	7d02                	ld	s10,32(sp)
 75c:	6de2                	ld	s11,24(sp)
 75e:	6109                	addi	sp,sp,128
 760:	8082                	ret

0000000000000762 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 762:	715d                	addi	sp,sp,-80
 764:	ec06                	sd	ra,24(sp)
 766:	e822                	sd	s0,16(sp)
 768:	1000                	addi	s0,sp,32
 76a:	e010                	sd	a2,0(s0)
 76c:	e414                	sd	a3,8(s0)
 76e:	e818                	sd	a4,16(s0)
 770:	ec1c                	sd	a5,24(s0)
 772:	03043023          	sd	a6,32(s0)
 776:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 77a:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 77e:	8622                	mv	a2,s0
 780:	00000097          	auipc	ra,0x0
 784:	e04080e7          	jalr	-508(ra) # 584 <vprintf>
}
 788:	60e2                	ld	ra,24(sp)
 78a:	6442                	ld	s0,16(sp)
 78c:	6161                	addi	sp,sp,80
 78e:	8082                	ret

0000000000000790 <printf>:

void
printf(const char *fmt, ...)
{
 790:	711d                	addi	sp,sp,-96
 792:	ec06                	sd	ra,24(sp)
 794:	e822                	sd	s0,16(sp)
 796:	1000                	addi	s0,sp,32
 798:	e40c                	sd	a1,8(s0)
 79a:	e810                	sd	a2,16(s0)
 79c:	ec14                	sd	a3,24(s0)
 79e:	f018                	sd	a4,32(s0)
 7a0:	f41c                	sd	a5,40(s0)
 7a2:	03043823          	sd	a6,48(s0)
 7a6:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 7aa:	00840613          	addi	a2,s0,8
 7ae:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 7b2:	85aa                	mv	a1,a0
 7b4:	4505                	li	a0,1
 7b6:	00000097          	auipc	ra,0x0
 7ba:	dce080e7          	jalr	-562(ra) # 584 <vprintf>
}
 7be:	60e2                	ld	ra,24(sp)
 7c0:	6442                	ld	s0,16(sp)
 7c2:	6125                	addi	sp,sp,96
 7c4:	8082                	ret

00000000000007c6 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 7c6:	1141                	addi	sp,sp,-16
 7c8:	e422                	sd	s0,8(sp)
 7ca:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 7cc:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7d0:	00001797          	auipc	a5,0x1
 7d4:	8307b783          	ld	a5,-2000(a5) # 1000 <freep>
 7d8:	a805                	j	808 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 7da:	4618                	lw	a4,8(a2)
 7dc:	9db9                	addw	a1,a1,a4
 7de:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 7e2:	6398                	ld	a4,0(a5)
 7e4:	6318                	ld	a4,0(a4)
 7e6:	fee53823          	sd	a4,-16(a0)
 7ea:	a091                	j	82e <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 7ec:	ff852703          	lw	a4,-8(a0)
 7f0:	9e39                	addw	a2,a2,a4
 7f2:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 7f4:	ff053703          	ld	a4,-16(a0)
 7f8:	e398                	sd	a4,0(a5)
 7fa:	a099                	j	840 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7fc:	6398                	ld	a4,0(a5)
 7fe:	00e7e463          	bltu	a5,a4,806 <free+0x40>
 802:	00e6ea63          	bltu	a3,a4,816 <free+0x50>
{
 806:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 808:	fed7fae3          	bgeu	a5,a3,7fc <free+0x36>
 80c:	6398                	ld	a4,0(a5)
 80e:	00e6e463          	bltu	a3,a4,816 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 812:	fee7eae3          	bltu	a5,a4,806 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 816:	ff852583          	lw	a1,-8(a0)
 81a:	6390                	ld	a2,0(a5)
 81c:	02059713          	slli	a4,a1,0x20
 820:	9301                	srli	a4,a4,0x20
 822:	0712                	slli	a4,a4,0x4
 824:	9736                	add	a4,a4,a3
 826:	fae60ae3          	beq	a2,a4,7da <free+0x14>
    bp->s.ptr = p->s.ptr;
 82a:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 82e:	4790                	lw	a2,8(a5)
 830:	02061713          	slli	a4,a2,0x20
 834:	9301                	srli	a4,a4,0x20
 836:	0712                	slli	a4,a4,0x4
 838:	973e                	add	a4,a4,a5
 83a:	fae689e3          	beq	a3,a4,7ec <free+0x26>
  } else
    p->s.ptr = bp;
 83e:	e394                	sd	a3,0(a5)
  freep = p;
 840:	00000717          	auipc	a4,0x0
 844:	7cf73023          	sd	a5,1984(a4) # 1000 <freep>
}
 848:	6422                	ld	s0,8(sp)
 84a:	0141                	addi	sp,sp,16
 84c:	8082                	ret

000000000000084e <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 84e:	7139                	addi	sp,sp,-64
 850:	fc06                	sd	ra,56(sp)
 852:	f822                	sd	s0,48(sp)
 854:	f426                	sd	s1,40(sp)
 856:	f04a                	sd	s2,32(sp)
 858:	ec4e                	sd	s3,24(sp)
 85a:	e852                	sd	s4,16(sp)
 85c:	e456                	sd	s5,8(sp)
 85e:	e05a                	sd	s6,0(sp)
 860:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 862:	02051493          	slli	s1,a0,0x20
 866:	9081                	srli	s1,s1,0x20
 868:	04bd                	addi	s1,s1,15
 86a:	8091                	srli	s1,s1,0x4
 86c:	0014899b          	addiw	s3,s1,1
 870:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 872:	00000517          	auipc	a0,0x0
 876:	78e53503          	ld	a0,1934(a0) # 1000 <freep>
 87a:	c515                	beqz	a0,8a6 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 87c:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 87e:	4798                	lw	a4,8(a5)
 880:	02977f63          	bgeu	a4,s1,8be <malloc+0x70>
 884:	8a4e                	mv	s4,s3
 886:	0009871b          	sext.w	a4,s3
 88a:	6685                	lui	a3,0x1
 88c:	00d77363          	bgeu	a4,a3,892 <malloc+0x44>
 890:	6a05                	lui	s4,0x1
 892:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 896:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 89a:	00000917          	auipc	s2,0x0
 89e:	76690913          	addi	s2,s2,1894 # 1000 <freep>
  if(p == (char*)-1)
 8a2:	5afd                	li	s5,-1
 8a4:	a88d                	j	916 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 8a6:	00000797          	auipc	a5,0x0
 8aa:	76a78793          	addi	a5,a5,1898 # 1010 <base>
 8ae:	00000717          	auipc	a4,0x0
 8b2:	74f73923          	sd	a5,1874(a4) # 1000 <freep>
 8b6:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 8b8:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 8bc:	b7e1                	j	884 <malloc+0x36>
      if(p->s.size == nunits)
 8be:	02e48b63          	beq	s1,a4,8f4 <malloc+0xa6>
        p->s.size -= nunits;
 8c2:	4137073b          	subw	a4,a4,s3
 8c6:	c798                	sw	a4,8(a5)
        p += p->s.size;
 8c8:	1702                	slli	a4,a4,0x20
 8ca:	9301                	srli	a4,a4,0x20
 8cc:	0712                	slli	a4,a4,0x4
 8ce:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 8d0:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 8d4:	00000717          	auipc	a4,0x0
 8d8:	72a73623          	sd	a0,1836(a4) # 1000 <freep>
      return (void*)(p + 1);
 8dc:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 8e0:	70e2                	ld	ra,56(sp)
 8e2:	7442                	ld	s0,48(sp)
 8e4:	74a2                	ld	s1,40(sp)
 8e6:	7902                	ld	s2,32(sp)
 8e8:	69e2                	ld	s3,24(sp)
 8ea:	6a42                	ld	s4,16(sp)
 8ec:	6aa2                	ld	s5,8(sp)
 8ee:	6b02                	ld	s6,0(sp)
 8f0:	6121                	addi	sp,sp,64
 8f2:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 8f4:	6398                	ld	a4,0(a5)
 8f6:	e118                	sd	a4,0(a0)
 8f8:	bff1                	j	8d4 <malloc+0x86>
  hp->s.size = nu;
 8fa:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 8fe:	0541                	addi	a0,a0,16
 900:	00000097          	auipc	ra,0x0
 904:	ec6080e7          	jalr	-314(ra) # 7c6 <free>
  return freep;
 908:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 90c:	d971                	beqz	a0,8e0 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 90e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 910:	4798                	lw	a4,8(a5)
 912:	fa9776e3          	bgeu	a4,s1,8be <malloc+0x70>
    if(p == freep)
 916:	00093703          	ld	a4,0(s2)
 91a:	853e                	mv	a0,a5
 91c:	fef719e3          	bne	a4,a5,90e <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 920:	8552                	mv	a0,s4
 922:	00000097          	auipc	ra,0x0
 926:	b66080e7          	jalr	-1178(ra) # 488 <sbrk>
  if(p == (char*)-1)
 92a:	fd5518e3          	bne	a0,s5,8fa <malloc+0xac>
        return 0;
 92e:	4501                	li	a0,0
 930:	bf45                	j	8e0 <malloc+0x92>
