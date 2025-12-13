# TimescaleDB Installation & Configuration Guide

## 1. System Preparation
sudo apt update
sudo apt install gnupg lsb-release wget

## 2. PostgreSQL Installation
sudo apt install postgresql-15

## 3. TimescaleDB Installation
sudo apt install timescaledb-2-postgresql-15

## 4. Enable Extension
sudo -u postgres psql -c "CREATE EXTENSION timescaledb;"

## 5. Restart Services
sudo systemctl restart postgresql
