package main

import (
	"log"

	"github.com/labstack/echo/v4"
	"github.com/satriahrh/tlipra/pkg/config"
	"github.com/satriahrh/tlipra/pkg/handlers"
	"github.com/satriahrh/tlipra/pkg/middleware"
	"github.com/satriahrh/tlipra/pkg/models"
)

func main() {
	// Load configuration
	cfg := config.Load()

	// Initialize database
	if err := config.InitDB(cfg); err != nil {
		log.Fatalf("Failed to initialize database: %v", err)
	}

	db := config.GetDB()

	// Auto migrate models
	if err := db.AutoMigrate(&models.User{}, &models.SleepRecord{}, &models.Followership{}); err != nil {
		log.Fatalf("Failed to migrate database: %v", err)
	}

	// Initialize Echo
	e := echo.New()

	// Initialize handlers
	authHandler := handlers.NewAuthHandler(db, cfg.JWTSecret)
	sleepHandler := handlers.NewSleepHandler(db)
	userHandler := handlers.NewUserHandler(db)

	// Public routes
	e.POST("/api/auth/register", authHandler.Register)
	e.POST("/api/auth/login", authHandler.Login)

	// Protected routes
	protected := e.Group("/api")
	protected.Use(middleware.AuthMiddleware(db, cfg.JWTSecret))

	// Sleep routes
	protected.POST("/sleep/clock_in", sleepHandler.ClockIn)
	protected.POST("/sleep/clock_out", sleepHandler.ClockOut)
	protected.GET("/sleep/records", sleepHandler.GetRecords)

	// User routes
	protected.POST("/users/:id/follow", userHandler.Follow)
	protected.POST("/users/:id/unfollow", userHandler.Unfollow)
	protected.GET("/users/followers", userHandler.GetFollowers)
	protected.GET("/users/following", userHandler.GetFollowing)

	// Start server
	log.Printf("Server starting on port %s", cfg.ServerPort)
	if err := e.Start(cfg.ServerPort); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
