--1

create or replace view Janusz_trasactions
    as
        select 
            tc.category_name, ts.subcategory_name, tt.transaction_type_name, t.transaction_date,
            extract (year from t.transaction_date) trans_year, t.transaction_value, bat.ba_type
            from transactions t 
                inner join transaction_type tt on (t.id_trans_type =tt.id_trans_type)
                inner join transaction_subcategory ts on (t.id_trans_subcat= ts.id_trans_subcat)
                inner join transaction_category tc on (t.id_trans_cat=tc.id_trans_cat)
                inner join transaction_bank_accounts tba on (t.id_trans_ba =tba.id_trans_ba)
                inner join bank_account_types bat on (tba.id_ba_typ=bat.id_ba_type)
                inner join bank_account_owner bao on (bat.id_ba_own=bao.id_ba_own)and bao.owner_name = 'Janusz Kowalski';
        
create or replace view Grazyna_trasactions
    as
        select 
            tc.category_name, ts.subcategory_name, tt.transaction_type_name, t.transaction_date,
            extract (year from t.transaction_date) trans_year, t.transaction_value, bat.ba_type
            from transactions t inner join transaction_type tt on (t.id_trans_type =tt.id_trans_type)
                 inner join transaction_subcategory ts on (t.id_trans_subcat= ts.id_trans_subcat)
                 inner join transaction_category tc on (t.id_trans_cat=tc.id_trans_cat)
                 inner join transaction_bank_accounts tba on (t.id_trans_ba =tba.id_trans_ba)
                 inner join bank_account_types bat on (tba.id_ba_typ=bat.id_ba_type)
                 inner join bank_account_owner bao on (bat.id_ba_own=bao.id_ba_own)and bao.owner_name = 'Gra?yna Kowalska'; 
      
        
create or replace view Grazyna_and_Janusz_trasactions
    as
    select 
        tc.category_name, ts.subcategory_name, tt.transaction_type_name, t.transaction_date,
        extract (year from t.transaction_date) trans_year, t.transaction_value, bat.ba_type
        from transactions t 
            inner join transaction_type tt on (t.id_trans_type =tt.id_trans_type)
            inner join transaction_subcategory ts on (t.id_trans_subcat= ts.id_trans_subcat)
            inner join transaction_category tc on (t.id_trans_cat=tc.id_trans_cat)
            inner join transaction_bank_accounts tba on (t.id_trans_ba =tba.id_trans_ba)
            inner join bank_account_types bat on (tba.id_ba_typ=bat.id_ba_type)
            inner join bank_account_owner bao on (bat.id_ba_own=bao.id_ba_own)and bao.owner_name = 'Janusz i Gra?ynka' ;       
            --2    
      select distinct
            trans_year,
            transaction_type_name,
            category_name,
            array_agg(subcategory_name) over (partition by category_name) list,
            sum(transaction_value)
      from Grazyna_and_Janusz_trasactions
      group by category_name,subcategory_name, trans_year, transaction_type_name 
      order by trans_year ;
      
  --3
  
  create table if not exists monthly_budget_planned (
        year_month varchar(7) primary key,
        budget_planned numeric(10,2),
        left_budget numeric(10,2)
  );
  
  insert into monthly_budget_planned (year_month, budget_planned, left_budget )
              values ('2020_11', 9500, 9500);
     
   --4       
   create function expense_tracker.budget()
   returns trigger
   language plpgsql
   as
   $$
        begin
                if (tg_op ='delete') then
                    update expense_tracker.monthly_budget_planned set left_budget = (left_budget + old.transactions.transaction_value );
                        
                elseif (tg_op = 'update') then
                    update expense_tracker.monthly_budget_planned set left_budget = (left_budget + new.transactions.transaction_value );
                
                elseif (tg_op ='insert') then
                   update expense_tracker.monthly_budget_planned set left_budget = (left_budget + new.transactions.transaction_value );
               RAISE NOTICE 'wykonanie_funkcji';
                end if; 
    return null;
 end
   $$;
   
create trigger budget_value
after insert or update or delete 
on expense_tracker.transactions 
for each row
execute procedure expense_tracker.budget(); 

EXPLAIN analyze insert into transactions (id_trans_ba, id_trans_cat, id_trans_subcat, 
                          id_trans_type, id_user, transaction_date, transaction_value,transaction_description) 
                          values(1,2,2,4,null,now(),26.00,316);
                      
                       