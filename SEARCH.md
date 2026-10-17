# Search & Navigation — search.sh

`search.sh` searches every `<category>/<program>/` folder: READMEs, `examples.sh`,
scripts and configs. Run it from anywhere; it finds the repo root itself.

```
./search.sh                     Interactive menu (numbered choices)
./search.sh <keyword>           Search everything, grouped by category
./search.sh -t <tool>           Show examples for a program or command
./search.sh -c <tool>           Examples + README + mentions in other READMEs
./search.sh -s <1-5>            List commands in a tier (1=Basic … 5=Extreme)
./search.sh -d <name>           Open a program or category README
./search.sh -f <word>           Find files whose name or content matches
./search.sh -l                  List all categories and programs
./search.sh -a                  Map of all headings across every README
./search.sh -h                  Show help
```

## Examples

```bash
./search.sh nginx               # every mention of nginx
./search.sh -t grep             # commands/grep/examples.sh
./search.sh -t gdb              # only the gdb block of debugging/binary-tools/examples.sh
./search.sh -c awk              # awk examples, README and mentions elsewhere
./search.sh -s 5                # strace, perf, bpftrace, kernel tools, one-liners
./search.sh -d ssh              # networking/ssh/README.md
./search.sh -d security         # security/README.md (category index)
./search.sh -t wrangler         # every wrangler block in services/cloudflare/examples.sh
./search.sh -f firewall         # every file related to firewalls
```

## How names are resolved

`-t`, `-c` and `-d` accept a program folder name, a category name, or a command
covered inside a folder. The lookup tries, in order:

1. An exact program folder name: `ssh`, `lvm`, `prometheus`
2. A built-in alias: `k8s` → `devops/kubernetes`, `ps` → `system/processes`,
   `nftables` → `networking/firewall`, `gzip` → `commands/compression`, …
3. A category name: `networking`, `security`, …
4. A `### <name>` block title inside any `examples.sh`: `gdb` → `debugging/binary-tools`
5. A partial folder name: `exporter` → `monitoring/node-exporter`

## Tiers

Each `examples.sh` header lists the tiers its commands belong to:

| Tier | Contents |
|------|----------|
| `-s 1` | **Basic**: ls, cd, pwd, cp, mv, rm, touch, mkdir, cat, head/tail, wc, less, ln |
| `-s 2` | **Intermediate**: grep, awk, sed, find, xargs, tar, compression, zip |
| `-s 3` | **Advanced**: processes, ss/ip/curl/wget, vmstat/iostat/free, pipes & redirection |
| `-s 4` | **Expert**: bash scripting, job control, cron/at, log parsing pipelines |
| `-s 5` | **Extreme**: one-liners, strace/ltrace/lsof, perf/bpftrace/tcpdump, kernel tools |
