-- DEMO #1: RECOMMENDED UPDATE SYNTAX

-- consider this useless, arbitrary example where we update a table based on self join:

create table #temp (a int, b int);
insert #temp select 1, 2;

update #temp
set t1.b = t2.b
from #temp t1
inner join #temp t2
on t1.a = t2.a
;

-- there's syntax error due to ambiguity.
-- to remedy this, the alias used in the FROM should always be beside the UPDATE:

update t1
set t1.b = t2.b
from #temp t1
inner join #temp t2
on t1.a = t2.a
;

-- this runs fine.




-- DEMO #2: UPDATING WITH A 1-TO-MANY JOIN

create table #temp2 (a int, b int);
insert #temp2 select 1, 2;
create table #temp3 (c int, d int);
insert #temp3 select 1, 3;
insert #temp3 select 1, 4;

select * from #temp2; -- this has values 2 for column b
select * from #temp3; -- this has values 3 or 4 column d

update t2
set t2.b = t3.d -- what value should t2.b be after this: 3 or 4?
from #temp2 t2
inner join #temp3 t3
on t2.a = t3.c
;

-- it's arbitrary and non-deterministic meaning it could be 3 today or 4 tomorrow
-- there's also no error or warning

