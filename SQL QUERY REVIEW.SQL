Use AdventureWorksDW2019 
Go
Select * from DimDate
Select ProductKey, EnglishProductName 
Into #Product
from DimProduct
select * from #Product

Select * from FactInternetSales
Select * from FactResellerSales

-- 1. Lấy danh sách 5 sản phẩm có tỷ lệ discount lớn nhất theo từng năm:
-- Channel: Reseller Sales
Select p.EnglishProductName, p.ProductKey, LEFT(f.OrderDateKey,4) As Year, f.UnitPriceDiscountPct, f.DiscountAmount,
RANK() OVER (PARTITION BY OrderDateKey ORDER BY DiscountAmount DESC) AS Rank
Into #Discount
from FactResellerSales as f
full outer JOIN #Product as p
ON p.ProductKey = f.ProductKey

Select * from #Discount
Drop table #Discount

select * from #Discount
Where Rank in (1,5) and DiscountAmount is not null

-- Channel: Internet Sales
Select p.EnglishProductName, p.ProductKey, LEFT(f.OrderDateKey,4) As Year, f.UnitPriceDiscountPct, f.DiscountAmount,
RANK() OVER (PARTITION BY OrderDateKey ORDER BY DiscountAmount DESC) AS Rank
Into #InternetDiscount
from FactInternetSales as f
full outer JOIN #Product as p
ON p.ProductKey = f.ProductKey

Select * from #InternetDiscount
Drop table #InternetDiscount

select * from #InternetDiscount
Where Rank in (1,5) and DiscountAmount is not null

-- 2. Tính Biên lợi nhuận gộp cho từng ProductCategory theo từng Tháng, Năm tương ứng (Bao gồm cả InternetSales và ResellerSales):-- Channel: Internet Sales
Select * from DimProductCategory
Select * from DimProductSubcategory
Select * from DimProduct
Select * from FactInternetSales
	
Select  s.ProductCategoryKey, Year(f.OrderDate) As Year, Month(f.OrderDate) As Month, 
		sum(f.TotalProductCost) AS TotalProductCost , sum(f.SalesAmount) As TotalSalesAmount,
		(sum(f.SalesAmount) - sum(f.TotalProductCost))/sum(f.SalesAmount) AS ProfitMargin
		Into #P1
		From FactInternetSales as f
		Join DimProduct As d ON f.ProductKey = d.ProductKey
		Join DimProductSubcategory As s ON s.ProductSubcategoryKey = d.ProductSubcategoryKey	
		Group by Year(f.OrderDate), Month(f.OrderDate),ProductCategoryKey
		Order by Year, Month, ProductCategoryKey ASC

-- Channel: Reseller Sales
	
Select   s.ProductCategoryKey, Year(f.OrderDate) As Year, Month(f.OrderDate) As Month,
		sum(f.TotalProductCost) AS TotalProductCost , sum(f.SalesAmount) As TotalSalesAmount,
		(sum(f.SalesAmount) - sum(f.TotalProductCost))/sum(f.SalesAmount) AS ProfitMargin
		Into #P2
		From FactResellerSales as f
		Join DimProduct As d ON f.ProductKey = d.ProductKey
		Join DimProductSubcategory As s ON s.ProductSubcategoryKey = d.ProductSubcategoryKey	
		Group by Year(f.OrderDate), Month(f.OrderDate),ProductCategoryKey
		Order by Year, Month, ProductCategoryKey ASC

--ProfitMargin = (Tổng SalesAmount – Tổng TotalProductCost)/(Tổng SalesAmount)
Select	p1.Year, p1.Month, p1.ProductCategoryKey, 
		p1.ProfitMargin AS ProfitMarginInternet, p2.ProfitMargin AS ProfitMarginReseller,
		(p1.ProfitMargin + p2.ProfitMargin) AS TotalProfitMargin
		from #P1 As p1
		Join #P2 AS p2 ON 
		p1.ProductCategoryKey = p2.ProductCategoryKey 
		and p1.Year = p2.Year 
		and p1.Month = p2.Month
