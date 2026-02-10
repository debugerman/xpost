package main

import (
	"log"

	"github.com/missuo/xpost/internal/app"
)

func main() {
	if err := app.RunLocal(); err != nil {
		log.Fatalf("server failed: %v", err)
	}
}
