set nocount on;


-- Scenario 0: No function. 
Declare @str   varchar(max) = ''
declare @getdate date = getdate() 


;With cte as
 ( Select database_id, 
      'db' + '-' + name   as DBName,
      create_date
   From sys.databases)

Select @str += dbname + ';'
From cte
Order By create_date

Print '0:' + @str
go



-- Scenario 1: function in the ORDER BY
Declare @str   varchar(max) = ''
declare @getdate date = getdate() 

;With cte as
 ( Select database_id, 
      'db' + '-' + name   as DBName,
      create_date
   From sys.databases)

Select @str += dbname + ';'
From cte
Order By datediff(day,create_date,getdate())

Print '1:' + @str
go

-- Scenario 2: function in the CTE
Declare @str   varchar(max) = ''
declare @getdate date = getdate() 

;With cte as
 ( Select database_id, 
      'db' + '-' + name   as DBName,
      datediff(second,create_date,@getdate) as DBAge--,'2016-01-01') as DBAGE--
   From sys.databases)

Select @str += dbname + ';'
From cte
Order By DBAge

Print '2:' + @str
go


-- Scenario 3: function in the name
Declare @str   varchar(max) = ''
declare @getdate date = getdate();

;With cte as
 ( Select database_id, 
      'db' + '-' + name + cast(@getdate as varchar(24)) as DBName,
      create_date
   From sys.databases)

Select @str += dbname + ';'
From cte
Order By dbName

Print '3:' + @str
go

-- Scenario 4: function -> string in the CTE
Declare @str   varchar(max) = ''
declare @getdate date = getdate();

;With cte as
 ( Select database_id, 
      'db' + '-' + name + cast(getdate() as varchar(36)) as DBName,
      create_date
   From sys.databases)

Select @str += dbname + ';'
From cte
Order By dbName

Print '4:' + @str
go

-- Scenario 5: use old-style formatting
Declare @str   varchar(max) = ''
declare @getdate date = getdate() 

;With cte as
 ( Select database_id, 
      'db' + '-' + name   as DBName,
      create_date
   From sys.databases)

Select @str = @str + dbname + ';'
From cte
Order By datediff(day,create_date,getdate())

Print '5:' + @str
go

-- Scenario 6: string and not getdate()
Declare @str   varchar(max) = ''
declare @getdate date = getdate() 

;With cte as
 ( Select database_id, 
      'db' + '-' + name   as DBName,
      datediff(second,create_date,'2016-01-01') as DBAGE
   From sys.databases)

Select @str += dbname + ';'
From cte
Order By DBAge

Print '6:' + @str
go