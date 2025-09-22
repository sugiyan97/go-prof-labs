package main

import (
	"flag"
	"log"
	"os"
	"runtime/pprof"

	"sugiyan97/go-prof-labs/internal/workload"
)

func main() {
	var n int
	var workers int
	var cpuProfile string
	flag.IntVar(&n, "n", 100, "iterations per worker")
	flag.IntVar(&workers, "workers", 4, "number of workers")
	flag.StringVar(&cpuProfile, "cpuprofile", "", "write cpu profile to file")
	flag.Parse()

	if cpuProfile != "" {
		f, err := os.Create(cpuProfile)
		if err != nil {
			log.Fatal(err)
		}
		defer f.Close()
		if err := pprof.StartCPUProfile(f); err != nil {
			log.Fatal(err)
		}
		defer pprof.StopCPUProfile()
	}

	total := workload.BurnCPU(n, workers)
	log.Printf("total=%d", total)
}
