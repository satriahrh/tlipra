package handlers

import (
	"net/http"
	"time"

	"github.com/labstack/echo/v4"
	"gorm.io/gorm"
	"github.com/satriahrh/tlipra/pkg/models"
)

type SleepHandler struct {
	DB *gorm.DB
}

func NewSleepHandler(db *gorm.DB) *SleepHandler {
	return &SleepHandler{DB: db}
}

func (h *SleepHandler) ClockIn(c echo.Context) error {
	userID := c.Get("userID").(uint)
	now := time.Now()

	record := models.SleepRecord{
		UserID:  userID,
		ClockIn: &now,
	}

	if err := h.DB.Create(&record).Error; err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "failed to clock in"})
	}

	return c.JSON(http.StatusOK, map[string]interface{}{
		"sleep_record": record,
	})
}

func (h *SleepHandler) ClockOut(c echo.Context) error {
	userID := c.Get("userID").(uint)
	now := time.Now()

	var record models.SleepRecord
	if err := h.DB.Where("user_id = ? AND clock_out IS NULL", userID).Order("clock_in DESC").First(&record).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return c.JSON(http.StatusBadRequest, map[string]string{"error": "no active sleep session found"})
		}
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "failed to clock out"})
	}

	record.ClockOut = &now
	duration := int(now.Sub(*record.ClockIn).Minutes())
	record.Duration = &duration

	if err := h.DB.Save(&record).Error; err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "failed to update sleep record"})
	}

	return c.JSON(http.StatusOK, map[string]interface{}{
		"sleep_record": record,
	})
}

func (h *SleepHandler) GetRecords(c echo.Context) error {
	userID := c.Get("userID").(uint)

	var records []models.SleepRecord
	if err := h.DB.Where("user_id = ?", userID).Order("clock_in DESC").Find(&records).Error; err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "failed to fetch records"})
	}

	return c.JSON(http.StatusOK, map[string]interface{}{
		"sleep_records": records,
	})
}
