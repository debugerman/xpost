package main

import (
	"log"
	"os"

	"github.com/missuo/xpost/internal/app"
)

func main() {
	if err := app.RunCLI(os.Args[1:]); err != nil {
		log.Fatalf("xpost failed: %v", err)
	}
}
