package handlers

import (
	"applicationName/internal/services"
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt"
)

func getClaims(c *gin.Context) (services.Claims, error) {
	claimsValue, ok := c.Get("claims")
	if !ok {
		fmt.Println("error getting claims")
		return services.Claims{}, fmt.Errorf("error getting claims")
	}
	claims, ok := claimsValue.(jwt.MapClaims)
	if !ok {
		fmt.Println("error converting claims")
		return services.Claims{}, fmt.Errorf("error getting claims")
	}

	structClaims := services.Claims{
		ID:       claims["id"].(string),
		Username: claims["username"].(string),
		Email:    claims["email"].(string),
	}
	return structClaims, nil
}

func (h *Handler) GetDashboard(c *gin.Context) {
	c.HTML(http.StatusOK, "dashboard.html", gin.H{})
}
