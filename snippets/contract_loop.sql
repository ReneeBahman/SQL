-- =======================================================================================
-- Description: This script identifies and links "premium" active contracts 
--              to a previous matching "basic" contract within a ±30 day window.
--              It ensures one-to-one mapping and resolves duplicates via iterative updates.
-- 
-- Use Case: Historical linkage of upgraded customer contracts (e.g., for churn analysis,
--           product evolution tracking, or customer behavior analytics).
-- 
-- Environment: Sybase ASE
-- =======================================================================================

-- STEP 1: Create temporary table to hold target premium contracts
select 
    c1.aindex, 
    c1.customerid, 
    c1.description, 
    c1.opened, 
    c1.closed, 
    c1.productid, 
    c1.product_name, 
    c1.gsmnumber,
    convert(integer, null) as calc_prev_id -- Placeholder for linking to previous contract
into #t
from your_schema.contract c1  
where c1.description = 'Premium Product Name' -- Replace with actual premium product
  and c1.opened < getdate()
  and c1.closed is null; -- Only include active contracts

-- =======================================================================================
-- STEP 2: First iterative loop to assign potential previous contracts
-- =======================================================================================

while @@rowcount > 0 loop

    -- Assign previous contract if:
    -- - Same customer, product, GSM
    -- - Closed within ±30 days of the premium contract's opened date
    -- - Not already linked to another contract
    update #t t 
    set calc_prev_id = t1.aindex 
    from your_schema.contract t1 
    where t.customerid = t1.customerid 
      and t.productid = t1.productid 
      and t.gsmnumber = t1.gsmnumber 
      and t1.closed between dateadd(dd, -30, t.opened) and dateadd(dd, 30, t.opened)
      and t.calc_prev_id is null 
      and t1.description = 'Basic Product Name' -- Replace with actual basic product
      and t1.aindex not in (
          select calc_prev_id from #t t3 where t3.calc_prev_id is not null
      );

    -- Ensure only the earliest contract keeps the link in case of duplicates
    update #t t 
    set calc_prev_id = null 
    from #t t1 
    where t.calc_prev_id = t1.calc_prev_id  
      and t.aindex > t1.aindex;

end loop;
go

-- =======================================================================================
-- STEP 3: Second loop - Same as above but skips GSM number condition (relaxes criteria)
-- =======================================================================================

while @@rowcount > 0 loop

    update #t t 
    set calc_prev_id = t1.aindex 
    from your_schema.contract t1 
    where t.customerid = t1.customerid 
      and t.productid = t1.productid 
      and t1.closed between dateadd(dd, -30, t.opened) and dateadd(dd, 30, t.opened)
      and t.calc_prev_id is null 
      and t1.description = 'Basic Product Name'
      and t1.aindex not in (
          select calc_prev_id from #t t3 where t3.calc_prev_id is not null
      );

    update #t t 
    set calc_prev_id = null 
    from #t t1 
    where t.calc_prev_id = t1.calc_prev_id  
      and t.aindex > t1.aindex;

end loop;
go

-- =======================================================================================
-- STEP 4: Third (final) loop - Even more relaxed matching (e.g., just by customer)
-- =======================================================================================

while @@rowcount > 0 loop

    update #t t 
    set calc_prev_id = t1.aindex 
    from your_schema.contract t1 
    where t.customerid = t1.customerid 
      and t1.closed between dateadd(dd, -30, t.opened) and dateadd(dd, 30, t.opened)
      and t.calc_prev_id is null 
      and t1.description = 'Basic Product Name'
      and t1.aindex not in (
          select calc_prev_id from #t t3 where t3.calc_prev_id is not null
      );

    update #t t 
    set calc_prev_id = null 
    from #t t1 
    where t.calc_prev_id = t1.calc_prev_id  
      and t.aindex > t1.aindex;

end loop;
go

-- =======================================================================================
-- STEP 5: View final results — only linked contracts
-- =======================================================================================

select * 
from #t 
where calc_prev_id is not null;

-- =======================================================================================
-- [OPTIONAL DEBUGGING / ANALYSIS BLOCK]
-- =======================================================================================

-- -- To reset all matches (for rerun/testing)
-- update #t set calc_prev_id = null;

-- -- Join with original contract to see linked basic contract details
-- select 
--     t.*, 
--     c1.gsmnumber, 
--     c1.description, 
--     c1.product_name, 
--     c1.opened, 
--     c1.closed 
-- from #t as t
-- left join your_schema.contract as c1 
--     on c1.aindex = t.calc_prev_id 
-- where t.calc_prev_id is not null;

-- -- Filter for specific customer (if needed)
-- select * from #t where customerid = 1234567;

-- =======================================================================================

-- End of Script
