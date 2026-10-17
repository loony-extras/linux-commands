# perf

CPU profiling and flame graphs.

---

## Files

- [examples.sh](examples.sh)

---

## Performance Tracing — Reading perf Output

```bash
# Record CPU profile for 30 seconds
perf record -F 99 -g -p $(pgrep myapp) sleep 30

# The report shows hottest call paths
perf report --stdio 2>&1 | head -60
```

Reading perf report:
```
Overhead  Command  Symbol
  34.12%  myapp    [.] hashmap_lookup           ← 34% of CPU time here
  18.45%  myapp    [.] parse_json
   9.23%  myapp    [k] __lock_text_start         ← k = kernel function
   7.11%  myapp    [.] malloc
```

If you see kernel lock functions (`[k]` symbols) taking significant time,
you have lock contention. If you see `malloc`, investigate memory allocation
patterns. If you see your own function, optimize it.

```bash
# flamegraph (visual call tree — needs Brendan Gregg's tools)
git clone https://github.com/brendangregg/FlameGraph
perf script | ./FlameGraph/stackcollapse-perf.pl | \
  ./FlameGraph/flamegraph.pl > /tmp/flamegraph.svg
# Open in browser — wider = more time, left = call stack depth
```

