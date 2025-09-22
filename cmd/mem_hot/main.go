package main

import (
	"flag"
	"log"
	"os"
	"runtime"
	"runtime/pprof"

	"sugiyan97/go-prof-labs/internal/workload"
)

func main() {
	var bytesPerItem, count int
	var hold bool
	var memProfile string
	flag.IntVar(&bytesPerItem, "bytes", 1024, "bytes per allocation")
	flag.IntVar(&count, "count", 100000, "allocation count")
	flag.BoolVar(&hold, "hold", true, "hold allocations globally to simulate leak")
	flag.StringVar(&memProfile, "memprofile", "", "write heap profile to file")
	flag.Parse()

	n := workload.Allocate(bytesPerItem, count, hold)
	log.Printf("allocated items=%d", n)

	if memProfile != "" {
		f, err := os.Create(memProfile)
		if err != nil {
			log.Fatal(err)
		}
		defer f.Close()
		runtime.GC() // 最新ヒープを反映
		if err := pprof.WriteHeapProfile(f); err != nil {
			log.Fatal(err)
		}
	}
}
