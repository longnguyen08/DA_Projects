-- Loại bỏ giá trị NULL tại các bảng Employess, Customer, Product, Sales.--
DELETE 
from [dbo].[Employees] 
where Mã_nhân_viên_bán is NULL

DELETE
from [dbo].[Customer]
where Mã_KH is NULL

DELETE
from [dbo].[Product]
where Mã_Sản_phẩm is NULL

DELETE
from [dbo].[Sales]
where [Đơn_hàng] is NULL

-- Giữ lại giá trị '-' và thay bằng NULL--
UPDATE [dbo].[Sales]
SET [Đơn_giá] = NULL
where [Đơn_giá] = '-'

UPDATE [dbo].[Sales]
SET [Doanh_thu] = NULL
where [Doanh_thu] = '-'

UPDATE [dbo].[Sales]
SET [Giá_vốn_hàng_hóa] = NULL
where [Giá_vốn_hàng_hóa] = '-'

--Loại bỏ ký tự không phù hợp ở những cột Đơn_giá, Doanh_thu, Giá_vốn_hàng_hóa--
UPDATE [dbo].[Sales]
SET [Đơn_giá] = REPLACE([Đơn_giá],',','')

UPDATE [dbo].[Sales]
SET [Doanh_thu] = REPLACE([Doanh_thu],',','')

UPDATE [dbo].[Sales]
SET [Giá_vốn_hàng_hóa] = REPLACE([Giá_vốn_hàng_hóa],',','')

--Chuyển đổi kiểu dữ liệu ở những cột Đơn_giá, Doanh_thu, Giá_vốn_hàng_hóa--
ALTER TABLE [dbo].[Sales]
ALTER COLUMN [Đơn_giá] FLOAT;

ALTER TABLE [dbo].[Sales]
ALTER COLUMN [Doanh_thu] FLOAT;

ALTER TABLE [dbo].[Sales]
ALTER COLUMN [Giá_vốn_hàng_hóa] FLOAT;

--Xử lý những dữ liệu '-' bằng giá trị TB của cột--
UPDATE [dbo].[Sales]
SET [Đơn_giá] = (Select CEILING(AVG([Đơn_giá])) from [dbo].[Sales])
where [Đơn_giá] is NULL

UPDATE [dbo].[Sales]
SET [Doanh_thu] = (Select CEILING(AVG([Doanh_thu])) from [dbo].[Sales])
where [Doanh_thu] is NULL

UPDATE [dbo].[Sales]
SET [Giá_vốn_hàng_hóa] = (Select CEILING(AVG([Giá_vốn_hàng_hóa])) from [dbo].[Sales])
where [Giá_vốn_hàng_hóa] is NULL


-- Tên, mã sản phẩm, tổng doanh thu của top 10 sản phẩm bán chạy nhất--
select top 10 s.[Mã_Sản_Phẩm],p.Sản_phẩm, sum([Số_lượng_bán]) Tổng_SP, sum([Doanh_thu]) Tổng_DThu
from[dbo].[Sales] s
JOIN [dbo].[Product] p ON p.[Mã_Sản_phẩm] = s.Mã_Sản_Phẩm
GROUP BY s.[Mã_Sản_Phẩm], p.Sản_phẩm
ORDER BY sum([Số_lượng_bán]) DESC


-- Tổng doanh thu của từng tháng, từng năm sắp xếp theo thứ tự giảm dần--
with cte as (select MONTH([Ngày_hạch_toán]) Tháng, YEAR([Ngày_hạch_toán]) Năm, [Mã_Sản_Phẩm],[Doanh_thu]
from [dbo].[Sales])
select cte.Tháng, cte.Năm, sum(cte.[Doanh_thu]) Tổng_DThu
from cte
GROUP BY cte.Tháng, cte.Năm
ORDER BY sum(cte.[Doanh_thu]) DESC


-- Tên những sản phẩm bán chạy nhất của từng tháng trong các năm--
with cte as (select MONTH([Ngày_hạch_toán]) Tháng, YEAR([Ngày_hạch_toán]) Năm, [Mã_Sản_Phẩm], [Số_lượng_bán]
from[dbo].[Sales]),
cte2 as (select cte.Tháng, cte.Năm, cte.[Mã_Sản_Phẩm], sum(cte.[Số_lượng_bán]) Tổng_SP,
 RANK() OVER(Partition BY cte.Tháng, cte.Năm ORDER BY sum(cte.[Số_lượng_bán]) DESC ) Rank
from cte
GROUP BY cte.Tháng, cte.Năm, cte.[Mã_Sản_Phẩm])
select cte2.Tháng, cte2.Năm, cte2.Tổng_SP, p.Sản_phẩm, p.Nhóm_sản_phẩm
from cte2
JOIN [dbo].[Product] p ON cte2.Mã_Sản_Phẩm = p.Mã_Sản_phẩm
where cte2.Rank = 1
ORDER BY cte2.Năm , cte2.Tháng


-- Doanh thu của từng nhân viên mang lại cho công ty sắp xếp theo thứ tự giảm dần--
select s.[Mã_nhân_viên_bán],sum([Doanh_thu]) Tổng_DThu , e.Nhân_viên_bán
from [dbo].[Sales] s
JOIN [dbo].[Employees] e ON s.Mã_nhân_viên_bán = e.Mã_nhân_viên_bán
GROUP BY s.[Mã_nhân_viên_bán], e.Nhân_viên_bán
ORDER BY sum([Doanh_thu]) DESC


-- Kiểm tra các Chi nhánh có đạt KPI theo năm hay không--
with cte as (SELECT YEAR([Ngày_hạch_toán]) Năm, sum([Doanh_thu]) Tổng_DThu, [Chi_nhánh]
FROM[dbo].[Sales]
GROUP BY [Chi_nhánh], YEAR([Ngày_hạch_toán]))
select cte.*, k.KPI,
case 
    when k.KPI - cte.Tổng_DThu < 0 then N'Đạt'
    when k.KPI - cte.Tổng_DThu >= 0 then N'Chưa Đạt'
    end as 'KPI_Status'
from cte
LEFT JOIN [dbo].[KPI] k ON k.Năm = cte.Năm and k.Chi_nhánh = cte.Chi_nhánh
-- 