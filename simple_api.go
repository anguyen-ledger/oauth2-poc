package main

import (
	"fmt"
	"net/http"
)

func info(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "This is the info route")
}

func status(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "This is the status route")
}

func main() {
	http.HandleFunc("/info", info)
	http.HandleFunc("/status", status)
	http.ListenAndServe("127.0.0.1:8080", nil)
}
