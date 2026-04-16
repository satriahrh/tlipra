package handlers

import (
	"net/http"
	"strconv"

	"github.com/labstack/echo/v4"
	"gorm.io/gorm"
	"github.com/satriahrh/tlipra/pkg/models"
)

type UserHandler struct {
	DB *gorm.DB
}

func NewUserHandler(db *gorm.DB) *UserHandler {
	return &UserHandler{DB: db}
}

func (h *UserHandler) Follow(c echo.Context) error {
	followerID := c.Get("userID").(uint)
	followeeID, err := parseParam(c.Param("id"))
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid user id"})
	}

	if followerID == followeeID {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "cannot follow yourself"})
	}

	// Check if followee exists
	var followee models.User
	if err := h.DB.First(&followee, followeeID).Error; err != nil {
		return c.JSON(http.StatusNotFound, map[string]string{"error": "user not found"})
	}

	// Check if already following
	var existingFollowership models.Followership
	if err := h.DB.Where("follower_id = ? AND followee_id = ?", followerID, followeeID).First(&existingFollowership).Error; err == nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "already following this user"})
	}

	followership := models.Followership{
		FollowerID: followerID,
		FolloweeID: followeeID,
	}

	if err := h.DB.Create(&followership).Error; err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "failed to follow user"})
	}

	return c.JSON(http.StatusOK, map[string]string{"message": "successfully followed user"})
}

func (h *UserHandler) Unfollow(c echo.Context) error {
	followerID := c.Get("userID").(uint)
	followeeID, err := parseParam(c.Param("id"))
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid user id"})
	}

	if err := h.DB.Where("follower_id = ? AND followee_id = ?", followerID, followeeID).Delete(&models.Followership{}).Error; err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "failed to unfollow user"})
	}

	return c.JSON(http.StatusOK, map[string]string{"message": "successfully unfollowed user"})
}

func (h *UserHandler) GetFollowers(c echo.Context) error {
	userID := c.Get("userID").(uint)

	var user models.User
	if err := h.DB.Preload("Followers").First(&user, userID).Error; err != nil {
		return c.JSON(http.StatusNotFound, map[string]string{"error": "user not found"})
	}

	return c.JSON(http.StatusOK, map[string]interface{}{
		"followers": user.Followers,
	})
}

func (h *UserHandler) GetFollowing(c echo.Context) error {
	userID := c.Get("userID").(uint)

	var user models.User
	if err := h.DB.Preload("Following").First(&user, userID).Error; err != nil {
		return c.JSON(http.StatusNotFound, map[string]string{"error": "user not found"})
	}

	return c.JSON(http.StatusOK, map[string]interface{}{
		"following": user.Following,
	})
}

func parseParam(param string) (uint, error) {
	id, err := strconv.Atoi(param)
	if err != nil {
		return 0, err
	}
	return uint(id), nil
}
