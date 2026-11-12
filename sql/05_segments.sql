-- =========================================================
-- BƯỚC 5. PHÂN TÍCH SÂU (Bước 4 là notebook thống kê)
-- Chạy: mysql -u root -p --default-character-set=utf8mb4 --table < sql/05_segments.sql
-- Dùng 100.0000000 * SUM / COUNT thay cho AVG() để không bị làm tròn 4 chữ số
-- =========================================================
USE marketing_ab;
SET NAMES utf8mb4;

-- 5.1 So sánh ad và psa TRONG TỪNG NGÀY
SELECT most_ads_day                                                    AS ngay,
       SUM(test_group = 'psa')                                         AS n_psa,
       ROUND(100.0000000 * SUM(CASE WHEN test_group = 'ad'  THEN converted ELSE 0 END)
                         / SUM(test_group = 'ad'), 3)                  AS ty_le_ad_pct,
       ROUND(100.0000000 * SUM(CASE WHEN test_group = 'psa' THEN converted ELSE 0 END)
                         / SUM(test_group = 'psa'), 3)                 AS ty_le_psa_pct,
       ROUND(100.0000000 * SUM(CASE WHEN test_group = 'ad'  THEN converted ELSE 0 END) / SUM(test_group = 'ad')
           - 100.0000000 * SUM(CASE WHEN test_group = 'psa' THEN converted ELSE 0 END) / SUM(test_group = 'psa'), 3)
                                                                       AS chenh_lech_pp
FROM ab_clean
GROUP BY most_ads_day, day_no
ORDER BY day_no;

-- 5.2 Chênh lệch ĐÃ ĐIỀU CHỈNH theo ngày (trung bình có trọng số theo số người mỗi ngày)
WITH d AS (
  SELECT COUNT(*)                                                                         AS n,
         100.0000000 * SUM(CASE WHEN test_group = 'ad'  THEN converted ELSE 0 END) / SUM(test_group = 'ad')
       - 100.0000000 * SUM(CASE WHEN test_group = 'psa' THEN converted ELSE 0 END) / SUM(test_group = 'psa') AS diff_pp
  FROM ab_clean
  GROUP BY most_ads_day
)
SELECT ROUND(SUM(n * diff_pp) / SUM(n), 3) AS chenh_lech_dieu_chinh_pp,
       0.769                               AS chenh_lech_chua_dieu_chinh_pp
FROM d;

-- 5.3 Tỷ lệ mua theo SỐ QUẢNG CÁO ĐÃ XEM (cả 2 nhóm)
SELECT CASE WHEN total_ads <= 10  THEN '1) 1-10'
            WHEN total_ads <= 20  THEN '2) 11-20'
            WHEN total_ads <= 50  THEN '3) 21-50'
            WHEN total_ads <= 100 THEN '4) 51-100'
            WHEN total_ads <= 200 THEN '5) 101-200'
            ELSE                       '6) >200' END                   AS so_quang_cao,
       COUNT(*)                                                        AS so_nguoi,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)              AS pct_nguoi,
       ROUND(100.0000000 * SUM(CASE WHEN test_group = 'ad'  THEN converted ELSE 0 END)
                         / NULLIF(SUM(test_group = 'ad'), 0), 2)       AS ty_le_ad_pct,
       ROUND(100.0000000 * SUM(CASE WHEN test_group = 'psa' THEN converted ELSE 0 END)
                         / NULLIF(SUM(test_group = 'psa'), 0), 2)      AS ty_le_psa_pct
FROM ab_clean
GROUP BY so_quang_cao
ORDER BY so_quang_cao;

-- 5.4 Tỷ lệ mua theo NGÀY (chỉ nhóm ad)
SELECT most_ads_day                                               AS ngay,
       COUNT(*)                                                   AS so_nguoi,
       ROUND(100.0000000 * SUM(converted) / COUNT(*), 3)          AS ty_le_pct
FROM ab_clean
WHERE test_group = 'ad'
GROUP BY most_ads_day, day_no
ORDER BY ty_le_pct DESC;

-- 5.5 Tỷ lệ mua theo GIỜ (chỉ nhóm ad)
SELECT most_ads_hour                                              AS gio,
       COUNT(*)                                                   AS so_nguoi,
       ROUND(100.0000000 * SUM(converted) / COUNT(*), 3)          AS ty_le_pct
FROM ab_clean
WHERE test_group = 'ad'
GROUP BY most_ads_hour
ORDER BY gio;
