package models

import (
	"time"

	"gorm.io/gorm"
)

type User struct {
	ID        uint           `gorm:"primarykey" json:"id"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
	Email     string         `gorm:"uniqueIndex;not null" json:"email"`
	Password  string         `gorm:"not null" json:"-"`
	Name      string         `json:"name"`
	
	SleepRecords []SleepRecord `gorm:"foreignKey:UserID" json:"sleep_records,omitempty"`
	Following    []User        `gorm:"many2many:followerships;JoinForeignKey:FollowerID;JoinReferences:FolloweeID" json:"following,omitempty"`
	Followers    []User        `gorm:"many2many:followerships;JoinForeignKey:FolloweeID;JoinReferences:FollowerID" json:"followers,omitempty"`
}

type SleepRecord struct {
	ID        uint           `gorm:"primarykey" json:"id"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
	UserID    uint           `gorm:"not null;index" json:"user_id"`
	ClockIn   *time.Time     `json:"clock_in,omitempty"`
	ClockOut  *time.Time     `json:"clock_out,omitempty"`
	Duration  *int           `gorm:"default:null" json:"duration,omitempty"` // duration in minutes
}

type Followership struct {
	ID          uint      `gorm:"primarykey" json:"id"`
	CreatedAt   time.Time `json:"created_at"`
	FollowerID  uint      `gorm:"not null;uniqueIndex:idx_follower_followee" json:"follower_id"`
	FolloweeID  uint      `gorm:"not null;uniqueIndex:idx_follower_followee" json:"followee_id"`
	Follower    User      `gorm:"foreignKey:FollowerID" json:"-"`
	Followee    User      `gorm:"foreignKey:FolloweeID" json:"-"`
}

func (u *User) BeforeCreate(tx *gorm.DB) error {
	// Hash password before creating user
	// In production, use bcrypt or similar
	return nil
}
