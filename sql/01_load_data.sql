-- BƯỚC 1. NẠP DỮ LIỆU MARKETING A/B TESTING VÀO MYSQL
-- Đặt file marketing_AB.csv vào thư mục data/, mở cmd tại data/ rồi chạy:
--   mysql -u root -p --local-infile=1 --default-character-set=utf8mb4 --table < ../sql/01_load_data.sql

SET GLOBAL local_infile = 1;          -- cho phép nạp file từ máy (MySQL 8 mặc định tắt)

DROP DATABASE IF EXISTS marketing_ab;
CREATE DATABASE marketing_ab CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE marketing_ab;
SET NAMES utf8mb4;

-- Bảng thô: giữ nguyên dữ liệu như trong file
CREATE TABLE ab_raw (
    row_no         INT,
    user_id        INT,
    test_group     VARCHAR(10),   -- 'ad' hoặc 'psa'
    converted      VARCHAR(10),   -- 'True' / 'False'
    total_ads      INT,
    most_ads_day   VARCHAR(15),   -- 'Monday' ... 'Sunday'
    most_ads_hour  INT
);

-- Đường dẫn tương đối: đọc file nằm cùng thư mục đang mở cmd
LOAD DATA LOCAL INFILE 'marketing_AB.csv'
INTO TABLE ab_raw
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES                                      -- bỏ dòng tên cột
(@c0, @c1, @c2, @c3, @c4, @c5, @c6)                 -- tên cột trong file có dấu cách và 1 cột không tên
SET row_no        = @c0,
    user_id       = @c1,
    test_group    = @c2,
    converted     = @c3,
    total_ads     = @c4,
    most_ads_day  = @c5,
    most_ads_hour = TRIM(TRAILING '\r' FROM @c6);   -- bỏ ký tự xuống dòng kiểu Windows

SELECT COUNT(*) AS so_dong FROM ab_raw;             -- 588.101
SELECT * FROM ab_raw LIMIT 10;
