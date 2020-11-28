--1
create or replace view sales_in_4q_2020 as
        select p.*, pmr.region_name, s.sal_date 
            from products p inner join product_manufactured_region pmr
            on (p.product_man_region = pmr.id) inner join sales s on (s.sal_prd_id= p.id) 
            and (extract(year from s.sal_date)=2020 and extract (quarter from s.sal_date)=4)
            
--2
create materialized view sum_sales_in_4q_2020 as
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

--3
select 
p.product_code,
pmr.region_code,
array_agg(p.product_name) as tablica
from products p left join product_manufactured_region pmr on (p.product_man_region=pmr.id)
group by p.product_name, p.product_code, pmr.region_code ;

--4
create table if not exists CTAS_table as
    select 
        p.product_code,
        pmr.region_code,
        array_agg(p.product_name) as tablica, --tu tez moÅ¼e byÄ‡ funkcja zwracajÄ…ca 0 lub 1
        (case
            when array_length(array_agg(p.product_name),1) >1
            then 1
            else 0
        end)::bool array_lenght_over_1
      from products p left join product_manufactured_region pmr on (p.product_man_region=pmr.id)
      group by p.product_name, p.product_code, pmr.region_code ;
  
--5
create table if not exists sales_archive (
    id              serial,
    sal_description text,
    sal_date        date,
    sal_value       numeric(10,2),
    sal_prd_id      int,
    operation_type  varchar(1) not null,
    added_by        text default 'admin',
    archived_at     timestamp default now()
);
    
--6

create or replace function public.sales_archived_function()
returns trigger
language plpgsql
    as
    $$
        begin
            --RAISE NOTICE 'Co jest w TG_OP: %', TG_OP;
                if (tg_op ='DELETE') then
                    insert into public.sales_archive (sal_description, sal_date, sal_value, sal_prd_id, operation_type)
                    values (old.sal_description, old.sal_date, old.sal_value, old.sal_prd_id, 'd' );
                
                        
                elseif (tg_op = 'UPDATE') then
                    insert into public.sales_archive ( sal_description, sal_date, sal_value, sal_prd_id, operation_type)
                    values (old.sal_description, old.sal_date, old.sal_value, old.sal_pr_id, 'u' );
                
                end if; 
          --RAISE NOTICE 'wykonanie_funkcji';  
        return null;
    

        end
    $$;

create trigger trigger_to_sales_archived
after update or delete 
on public.sales
for each row
execute procedure public.sales_archived_function();

--EXPLAIN analyze 
delete from sales where extract(month from sal_date)=10 and extract(year from sal_date)=2020;
  -- zapewne coś robie źle z insertami w funkcji. Analiza pokazuję że trigger jest wywoływany,
  -- a w output-cie zwraca wykonanie funkcji 
  
insert into sales (sal_date, sal_value,sal_prd_id ) values (now(), 96.9,8);
