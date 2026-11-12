-- =========================================================
-- BƯỚC 2. KIỂM TRA CHẤT LƯỢNG DỮ LIỆU
-- Chạy: mysql -u root -p --default-character-set=utf8mb4 --table < sql/02_data_checks.sql
-- =========================================================
USE marketing_ab;
SET NAMES utf8mb4;

-- 2.1 Số dòng, số người khác nhau -> mỗi người có đúng 1 dòng không?
SELECT COUNT(*)                AS so_dong,
       COUNT(DISTINCT user_id) AS so_nguoi,
       COUNT(*) - COUNT(DISTINCT user_id) AS so_dong_trung
FROM ab_raw;

-- 2.2 Ô trống ở từng cột
SELECT SUM(user_id IS NULL)                                AS thieu_user_id,
       SUM(test_group IS NULL OR test_group = '')          AS thieu_nhom,
       SUM(converted IS NULL OR converted = '')            AS thieu_converted,
       SUM(total_ads IS NULL)                              AS thieu_total_ads,
       SUM(most_ads_day IS NULL OR most_ads_day = '')      AS thieu_ngay,
       SUM(most_ads_hour IS NULL)                          AS thieu_gio
FROM ab_raw;

-- 2.3 Các giá trị xuất hiện trong cột chữ (phát hiện giá trị lạ)
SELECT 'test_group' AS cot, test_group AS gia_tri, COUNT(*) AS so_dong FROM ab_raw GROUP BY test_group
UNION ALL
SELECT 'converted', converted, COUNT(*) FROM ab_raw GROUP BY converted
UNION ALL
SELECT 'most_ads_day', most_ads_day, COUNT(*) FROM ab_raw GROUP BY most_ads_day
ORDER BY cot, gia_tri;

-- 2.4 Có người nằm ở cả 2 nhóm không?
SELECT COUNT(*) AS nguoi_o_ca_2_nhom
FROM (SELECT user_id
      FROM ab_raw
      GROUP BY user_id
      HAVING COUNT(DISTINCT test_group) > 1) t;

-- 2.5 Khoảng giá trị của cột số
SELECT MIN(total_ads) AS ads_min, MAX(total_ads) AS ads_max,
       ROUND(AVG(total_ads), 1) AS ads_tb,
       SUM(total_ads = 0) AS so_nguoi_0_ads,
       MIN(most_ads_hour) AS gio_min, MAX(most_ads_hour) AS gio_max
FROM ab_raw;

-- 2.6 Tỷ lệ chia nhóm (kiểm tra sample ratio mismatch)
SELECT test_group,
       COUNT(*)                                            AS so_nguoi,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)  AS pct
FROM ab_raw
GROUP BY test_group;

-- 2.7 Hai nhóm có giống nhau về mức độ xem quảng cáo không?
SELECT test_group,
       ROUND(AVG(total_ads), 1)                     AS ads_tb,
       ROUND(100.0 * SUM(most_ads_day IN ('Saturday','Sunday')) / COUNT(*), 1) AS pct_cuoi_tuan,
       ROUND(AVG(most_ads_hour), 1)                 AS gio_tb
FROM ab_raw
GROUP BY test_group;

-- 2.8 Tạo bảng sạch cho các bước sau
DROP TABLE IF EXISTS ab_clean;

CREATE TABLE ab_clean AS
SELECT user_id,
       test_group,
       CASE WHEN converted = 'True' THEN 1 ELSE 0 END AS converted,
       total_ads,
       most_ads_day,
       CASE most_ads_day
            WHEN 'Monday' THEN 1 WHEN 'Tuesday' THEN 2 WHEN 'Wednesday' THEN 3
            WHEN 'Thursday' THEN 4 WHEN 'Friday' THEN 5 WHEN 'Saturday' THEN 6
            WHEN 'Sunday' THEN 7 END AS day_no,
       most_ads_hour
FROM ab_raw
WHERE user_id IS NOT NULL
  AND test_group IN ('ad', 'psa')
  AND converted IN ('True', 'False');

ALTER TABLE ab_clean ADD PRIMARY KEY (user_id);

-- 2.9 Kiểm chứng: bảng sạch có bao nhiêu dòng, mất bao nhiêu so với bảng thô
SELECT (SELECT COUNT(*) FROM ab_raw)   AS dong_tho,
       (SELECT COUNT(*) FROM ab_clean) AS dong_sach,
       (SELECT COUNT(*) FROM ab_raw) - (SELECT COUNT(*) FROM ab_clean) AS dong_bi_loai;
