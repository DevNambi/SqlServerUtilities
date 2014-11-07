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
set @String2 = 'Of lice and hawks';

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
string1_letters as (
	select SUBSTRING(@String1, n, 1) as Letter
		,count(*) as LetterFrequency
	from nums
	where nums.n <= len(@String1)
	group by SUBSTRING(@String1, n, 1)
), 
string2_letters as (
	select SUBSTRING(@String2, n, 1) as Letter
		,count(*) as LetterFrequency
	from nums
	where nums.n <= len(@String2)
	group by SUBSTRING(@String2, n, 1)
),
intersect_count as
(
select 
	Letter = isnull(s1.Letter,s2.Letter)
	,s1.LetterFrequency as String1_LetterFrequency
	,s2.LetterFrequency as String2_LetterFrequency
	,IntersectionCount = CASE WHEN s1.LetterFrequency > s2.LetterFrequency
							THEN s2.LetterFrequency
							ELSE s1.LetterFrequency --this also deals with the equal-count case
							END
from string1_letters s1
inner join string2_letters s2 --use an inner join b/c we're only interested in intersections
on s1.Letter = s2.Letter -- join on letters
)


select
	sum(IntersectionCount) * 1.0
		/ (len(@String1) + len(@String2))
from intersect_count