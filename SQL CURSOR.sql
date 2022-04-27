-- BT1
-- TARGET TABLE
CREATE TABLE [dbo].[Locations](
[LocationID] [int] NULL,
[LocationName] [varchar](100) NULL
)
--Source table :
CREATE TABLE [dbo].[Locations_stage](
[LocationID] [int] NULL,
[LocationName] [varchar](100) NULL
)
INSERT INTO Locations values (1,'Richmond Road'),(2,'Brigade Road') ,(3,'Houston Street')
INSERT INTO Locations_stage values (1,'Richmond Cross') ,(3,'Houston Street'), (4,'Canal Street')

SELECT * FROM Locations
SELECT * FROM Locations_stage

MERGE Locations t
    USING Locations_stage s
ON (s.LocationID = t.LocationID)
WHEN MATCHED
    THEN UPDATE SET 
        t.LocationName = s.LocationName
WHEN NOT MATCHED BY TARGET 
    THEN INSERT (LocationID, LocationName)
         VALUES (s.LocationID, s.LocationName)
WHEN NOT MATCHED BY SOURCE 
    THEN DELETE;

--BT2

DECLARE @SoHD int
DECLARE @MaSP nvarchar(200)
DECLARE @SL int
DECLARE @TENSP nvarchar(200)
DECLARE cursorHD CURSOR FOR
select SOHD, cthd.MASP, SL, TENSP
from CTHD, SANPHAM
Open cursorHD
FETCH NEXT FROM cursorHD INTO @SoHD,@MaSP,@SL,@TENSP
WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT N'Số hóa đơn:' + CAST(@SoHD as nvarchar)
    PRINT N'Mã sản phẩm:'+ @MaSP
	PRINT N'Tên sản phẩm:'+ @TENSP
	PRINT N'Số lượng:'+CAST(@SL as nvarchar)
	
    FETCH NEXT FROM cursorHD INTO @SoHD,@MaSP,@SL,@TENSP
END
CLOSE cursorHD
DEALLOCATE cursorHD

--BT3
CREATE PROCEDURE sp_LayTenNhanVienCoDoanhSoCaoNhatTheoNgay(@NGAY date)
AS 
BEGIN
SELECT a.MANV, a.HOTEN, c.NGHD
FROM NHANVIEN a, KHACHHANG b, HOADON c
WHERE b.DOANHSO =  
(SELECT MAX(DOANHSO) 
FROM KHACHHANG)
AND a.SODT=b.SODT AND c.NGHD = @NGAY
END
GO
EXEC sp_LayTenNhanVienCoDoanhSoCaoNhatTheoNgay @NGAY = '2006-10-28' 

IF EXISTS ( select * from sys.procedures where name='sp_LayTenNhanVienCoDoanhSoCaoNhatTheoNgay')
BEGIN 
DROP PROC sp_LayTenNhanVienCoDoanhSoCaoNhatTheoNgay
END 
GO
--BT4
CREATE OR ALTER PROCEDURE HoaHong (@date as Date)
AS
BEGIN
	WITH CTE AS (
		SELECT NV.HOTEN ,HD.MANV, CASE
			WHEN SP.NUOCSX = 'Viet Nam' THEN HD.TRIGIA * 0.1 
			WHEN SP.NUOCSX = 'Trung Quoc' THEN HD.TRIGIA * 0.12
			ELSE HD.TRIGIA * 0.08
			END AS COMMISSION
		FROM HOADON AS HD
		LEFT JOIN NHANVIEN AS NV
		ON HD.MANV = NV.MANV
		LEFT JOIN CTHD
		on CTHD.SOHD = HD.SOHD
		LEFT JOIN SANPHAM AS SP
		ON SP.MASP = CTHD.MASP
		WHERE YEAR(HD.NGHD) = YEAR(@date) AND MONTH(HD.NGHD) = MONTH(@date)
	)
	SELECT @date AS Month_NC,  MANV, HOTEN, SUM(COMMISSION) AS SUM_COMMISSION FROM CTE GROUP BY MANV, HOTEN
END

EXECUTE HoaHong 
	@date = '2006-11-01 00:00:00'

--c2
CREATE OR ALTER PROCEDURE sp_Tinhhoahong
   (@ngay int)
AS
BEGIN
SELECT n.MANV, n.HOTEN, (YEAR(NGHD) * 100) + MONTH(NGHD) as MonthYear,
	   SUM(CASE 
			   WHEN s.NUOCSX = 'Viet Nam' THEN c.SL*s.GIA * 0.1
			   WHEN s.NUOCSX = 'Trung Quoc' THEN c.SL*s.GIA * 0.12
			   ELSE c.SL*s.GIA * 0.08
		   END) AS COMMISION
FROM NHANVIEN n join HOADON h on n.MANV = h.MANV
		        join CTHD c on h.SOHD = c.SOHD
		        join SANPHAM s on s.MASP = c.MASP
WHERE (YEAR(NGHD) * 100) + MONTH(NGHD) = @ngay
GROUP BY n.MANV, n.HOTEN, (YEAR(NGHD) * 100) + MONTH(NGHD)
END;
EXECUTE sp_Tinhhoahong
    @ngay = 200701;

