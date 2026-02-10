package handler

import (
	"net/http"
	"sync"

	"github.com/missuo/xpost/internal/app"
)

var (
	once       sync.Once
	httpHandle http.Handler
	initErr    error
)

func Handler(w http.ResponseWriter, r *http.Request) {
	once.Do(func() {
		httpHandle, initErr = app.NewVercelHandler()
	})

	if initErr != nil {
		http.Error(w, "service initialization failed", http.StatusInternalServerError)
		return
	}
	httpHandle.ServeHTTP(w, r)
}
