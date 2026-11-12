-- =========================================================
-- BƯỚC 3. TỶ LỆ CHUYỂN ĐỔI VÀ LIFT
-- Chạy: mysql -u root -p --default-character-set=utf8mb4 --table < sql/03_conversion.sql
-- =========================================================
USE marketing_ab;
SET NAMES utf8mb4;

-- 3.1 Tỷ lệ chuyển đổi theo nhóm
SELECT test_group,
       COUNT(*)                                       AS so_nguoi,
       SUM(converted)                                 AS so_nguoi_mua,
       ROUND(100.0000000 * SUM(converted) / COUNT(*), 3) AS ty_le_pct
FROM ab_clean
GROUP BY test_group;

-- 3.2 Chênh lệch tuyệt đối, lift, và z-score (p-value tính trong notebook)
WITH g AS (
  SELECT SUM(CASE WHEN test_group = 'ad'  THEN 1 ELSE 0 END)         AS n_ad,
         SUM(CASE WHEN test_group = 'ad'  THEN converted ELSE 0 END) AS x_ad,
         SUM(CASE WHEN test_group = 'psa' THEN 1 ELSE 0 END)         AS n_psa,
         SUM(CASE WHEN test_group = 'psa' THEN converted ELSE 0 END) AS x_psa
  FROM ab_clean
), r AS (
  SELECT n_ad, x_ad, n_psa, x_psa,
         1.0 * x_ad  / n_ad                    AS p_ad,
         1.0 * x_psa / n_psa                   AS p_psa,
         1.0 * (x_ad + x_psa) / (n_ad + n_psa) AS p_chung   -- tỷ lệ gộp 2 nhóm
  FROM g
)
SELECT ROUND(100 * p_ad, 3)                         AS ty_le_ad_pct,
       ROUND(100 * p_psa, 3)                        AS ty_le_psa_pct,
       ROUND(100 * (p_ad - p_psa), 3)               AS chenh_lech_pp,
       ROUND(100 * (p_ad - p_psa) / p_psa, 1)       AS lift_pct,
       ROUND((p_ad - p_psa)
             / SQRT(p_chung * (1 - p_chung) * (1.0 / n_ad + 1.0 / n_psa)), 2) AS z_score
FROM r;

-- 3.3 Quy ra kinh doanh: số người mua TĂNG THÊM nhờ quảng cáo
--     Không dùng AVG(): MySQL chỉ giữ 4 chữ số thập phân, gây sai số khi nhân với số lớn
WITH g AS (
  SELECT SUM(test_group = 'ad')                               AS n_ad,
         SUM(CASE WHEN test_group = 'ad'  THEN converted END) AS x_ad,
         SUM(test_group = 'psa')                              AS n_psa,
         SUM(CASE WHEN test_group = 'psa' THEN converted END) AS x_psa
  FROM ab_clean
)
SELECT x_ad                                  AS nguoi_mua_thuc_te_nhom_ad,
       ROUND(n_ad * x_psa / n_psa)           AS nguoi_mua_neu_khong_quang_cao,
       ROUND(x_ad - n_ad * x_psa / n_psa)    AS nguoi_mua_tang_them,
       ROUND(100000 * x_ad / n_ad - 100000 * x_psa / n_psa) AS tang_them_moi_100k_nguoi
FROM g;
