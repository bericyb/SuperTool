-- +goose Up
ALTER TABLE users ADD COLUMN username VARCHAR(255) UNIQUE NOT NULL;
