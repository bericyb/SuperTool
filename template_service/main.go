package main

import (
	"applicationName/internal/handlers"
	"applicationName/internal/routes"
	"database/sql"
	"fmt"
	"log"

	"github.com/gin-gonic/gin"
	_ "github.com/lib/pq"
	"github.com/pressly/goose/v3"
)

var db *sql.DB

func main() {
	initDB()
	r := gin.Default()

	// Load templates
	r.LoadHTMLGlob("templates/**/*")

	// Serve static files
	r.Static("/assets", "./assets")

	handler := &handlers.Handler{DB: db}

	// Add public routes
	routes.PublicRoutes(r, handler)

	// Add Protected routes
	routes.ProtectedRoutes(r, handler)

	port := ":4000"
	fmt.Printf("Server running at http://localhost%s\n", port)
	r.Run(port)
}

func initDB() {
	var err error
	connStr := "postgres://postgres:password@localhost:5432/postgres?sslmode=disable"
	db, err = sql.Open("postgres", connStr)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}

	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(25)
	db.SetConnMaxLifetime(0)

	if err := db.Ping(); err != nil {
		log.Fatalf("Database ping failed: %v", err)
	}

	applyMigrations()
}

func applyMigrations() {
	migrationsDir := "migrations"
	if err := goose.Up(db, migrationsDir); err != nil {
		log.Fatalf("Failed to apply migrations: %v", err)
	}
	log.Println("Database migrations applied successfully.")
}
