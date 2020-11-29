
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
                if (tg_op ='DELETE' and (old.id_trans_type=2 or old.id_trans_type=3)) then 
                    update expense_tracker.monthly_budget_planned set left_budget = (left_budget - old.transaction_value )
                    where expense_tracker.monthly_budget_planned.year_month = concat((extract (year from now()))::text, '_' , (extract (month from now()))::text);
                        
                elseif (tg_op ='UPDATE' and (new.id_trans_type=2 or new.id_trans_type=3)) then
                    update expense_tracker.monthly_budget_planned set left_budget = (left_budget - (old.transaction_value - new.transaction_value))
                where expense_tracker.monthly_budget_planned.year_month = concat(extract (year from now())::text, '_' , (extract (month from now()))::text);
                    
                elseif (tg_op ='INSERT' and (new.id_trans_type=2 or new.id_trans_type=3)) then
                   update expense_tracker.monthly_budget_planned set left_budget = (left_budget + new.transaction_value )
               where expense_tracker.monthly_budget_planned.year_month =concat(extract (year from now())::text,  '_' , (extract (month from now()))::text);
               
                end if; 
    return null;
 end
   $$;
   
create trigger budget_value
after insert or update or delete 
on expense_tracker.transactions 
for each row
execute procedure expense_tracker.budget(); 

-- w trigerze przyjałem format danych w wierszu year_month jako np 11_2020, 07_2020                    
 --Trigger nie uwzglÃ„â„¢dnia 
 -- a) dodania kolejnego miesiÃ„â€¦ca transakcji w przypadku zmiany daty (chyba Ã…Â¼e kontrolujemy to innÃ„â€¦ procedurÃ„â€¦),
 -- b) nie sprecyzowano jaki ma byÅ› dokÅ‚adnie format kolumny z kluczem gÅ‚Ã³wnym varchar(7) dopuszcza różne możliwości tzn czy np 11_2020, lis_2020, 11_20
 -- c) trigger powinien uwzględniać sytuacje, np. usuniecia transakcji na przełomie miesiąca tzn. anulowanie transakcji z danego miesiąca nastąpi w miesiącu następnym,
 -- d) przy scenariuszu update problem co bedzie podlegało zmianie i jakim zakresie (tzn. jeśli tylko kwota to w związku z tym że teoretyczne brane są pod uwgaę tylko kwoty z obciążenia i
 --    wypłaty własnej powinny być ujemne jednak nie można wykluczyć że przez pomyłkę użytkownik zmieni kwotę na dodatnią, co powinno być ptraktowano jako wpływ i posiadać inny typ transakcji.    
 -- e) skad wynika wrtoÅ›c budget_planned czy jest on wpisywany ręcznie za każdym miesiącem czy jest obliczany np. 
--     jako procent dochodów jeśli obliczana trigger powinien uwzględniać tez kolumne z plan. budżetem.