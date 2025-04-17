package routes

import (
	"applicationName/internal/auth"
	"applicationName/internal/handlers"
	"net/http"

	"github.com/gin-gonic/gin"
)

func ProtectedRoutes(r *gin.Engine, handler *handlers.Handler) {
	// Protected routes
	auth := r.Group("/").Use(auth.JwtAuthMiddleware())

	auth.GET("/protected", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "You are authenticated"})
	})

	auth.GET("/dashboard", handler.GetDashboard)
}
