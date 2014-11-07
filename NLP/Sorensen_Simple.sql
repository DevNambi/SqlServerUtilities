/* This is a simple script to demonstrate 
how to compute Sorenson similarity 
(http://en.wikipedia.org/wiki/S%C3%B8rensen%E2%80%93Dice_coefficient)
using T-SQL.

It can be easily wrapped into a scalar function.

Sorenson-Dice similarity: sum(letters in common) / ( length(first string) + length(second string) )


WARNING: this implementation is *location sensitive*. Extra spaces and typos will throw this off.
*/

declare @String1 varchar(4000)
   ,@String2 varchar(4000)
   ,@MaxLength int
	
set @String1 = 'Of mice and men';
set @String2 = 'Of lice and wrens';

set @MaxLength = case when len(@String1) < len(@String2)
                        then len(@String2) else len(@String1) end;

with
L0 as (select 0 as c union all select 1),
L1 as (select 0 as c from L0 cross join L0 as b),
L2 as (select 0 as c from L1 cross join L1 as b),
L3 as (select 0 as c from L2 cross join L2 as b),
L4 as (select 0 as c from L3 cross join L3 as b),
L5 as (select 0 as c from L4 cross join L4 as b),
nums as (select row_number() OVER (ORDER BY (select null)) as n from L5),
distance as (
   select
         IsSameLetter = CASE
            WHEN len(@String1) < n THEN 0
            WHEN len(@String2) < n THEN 0
            WHEN SUBSTRING(@String1,n,1) = SUBSTRING(@String2,n,1)
            THEN 1 ELSE 0
            END
         ,String1Length = len(@String1)
		 ,String2Length = len(@String2)		 
   from nums
   where nums.n <= @MaxLength
)

select sum(IsSameLetter) * 1.0
	/ (max(String1Length) + max(String2Length))
from distance
