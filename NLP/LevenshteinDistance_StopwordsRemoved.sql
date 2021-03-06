/* This is a simple script to demonstrate 
how to compute Levenshtein distance
(https://en.wikipedia.org/wiki/Levenshtein_distance)
using T-SQL.

It can be easily wrapped into a scalar function.

The modification here is the removal of stopwords.
This example is intended for *phrases*, not words

Ideally the same replace() technique
would also remove punctuation. Feel free to add that
into your implementation.
*/

declare @String1 varchar(4000)
   ,@String2 varchar(4000)
   ,@CleanedUpString1 varchar(4000)
   ,@CleanedUpString2 varchar(4000)
   ,@MaxLength int
	
set @String1 = 'Of mice and men'
set @String2 = 'Of lice and wrens';

-- Clean up the strings by removing stopwords.
set @CleanedUpString1 = ' ' +@String1 + ' '
set @CleanedUpString1 = replace(
                           replace(
                              replace(
                                 replace(
                                    replace(@CleanedUpString1,' and ','')
                                    ,' the ','')
                                 ,' of '
                                 ,'')
                              ,' is ','')
                           ,' on ','')
set @CleanedUpString1 = ltrim(rtrim(@CleanedUpString1));
                           

set @CleanedUpString2 = ' ' +@String2 + ' ';
set @CleanedUpString2 = replace(
                           replace(
                              replace(
                                 replace(
                                    replace(@CleanedUpString2,' and ','')
                                    ,' the ','')
                                 ,' of '
                                 ,'')
                              ,' is ','')
                           ,' on ','')
set @CleanedUpString2 = ltrim(rtrim(@CleanedUpString2));

set @MaxLength = case when len(@CleanedUpString1) < len(@CleanedUpString2)
                        then len(@CleanedUpString2) else len(@CleanedUpString1) end;

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
      CASE
         WHEN len(@CleanedUpString1) < n THEN 1
         WHEN len(@CleanedUpString2) < n THEN 1
         WHEN SUBSTRING(@CleanedUpString1,n,1) = SUBSTRING(@CleanedUpString2,n,1)
         THEN 0 ELSE 1
         END
         ,String1Letter = SUBSTRING(@CleanedUpString1,n,1)
         ,String2Letter = SUBSTRING(@CleanedUpString2,n,1)
         ,n
   from nums
   where nums.n <= @MaxLength
)



