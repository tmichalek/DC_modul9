
--M9L13 zad2 Teoria
select distinct
       row_number() over (order by p.product_code, p.product_name)as id_sum_sal,
       p.product_code, 
       p.product_name,
       pmr.region_name,
       s.sal_date, 
       sum(s.sal_value) over (partition by p.product_code) 
    from products p inner join product_manufactured_region pmr
         on (p.product_man_region = pmr.id) inner join sales s on (s.sal_prd_id=p.id) 
         and (extract(year from s.sal_date)=2020 and extract (quarter from s.sal_date)=4)           
    order by s.sal_date , p.product_name
        with data ; 
    
    create unique index ind_sum_sales_in_4q_2020 on sum_sales_in_4q_2020 (id_sum_sal);

    refresh materialized view concurrently sum_sales_in_4q_2020 ;
    

-- zad5 i zad6 projekt

create or replace function expense_tracker.budget()
   returns trigger
   language plpgsql
   as
   $$
        begin
            --RAISE NOTICE 'Co jest w TG_OP: %', TG_OP;
                if (tg_op ='DELETE') then
                    update expense_tracker.monthly_budget_planned set left_budget = (left_budget - old.transaction_value );
                        
                elseif (tg_op = 'UPDATE') then
                    update expense_tracker.monthly_budget_planned set left_budget = (left_budget + new.transaction_value );
                    
                elseif (tg_op ='INSERT') then
                   update expense_tracker.monthly_budget_planned set left_budget = (left_budget + new.transaction_value );
               
                end if; 
    return null;
 end
   $$;
   
create trigger budget_value
after insert or update or delete 
on expense_tracker.transactions 
for each row
execute procedure expense_tracker.budget(); 
                      
 --Trigger nie uwzględnia 
 -- a) dodania kolejnego miesiąca transakcji (chyba że kontrolujemy to inną procedurą), 
--  b) w przypadku usuwania jakiejsć transakcji jesli był to wydatek należało by kwotę tą 
--     dodać do planowanego budżetu, a w przypadku dochodu odjąć 