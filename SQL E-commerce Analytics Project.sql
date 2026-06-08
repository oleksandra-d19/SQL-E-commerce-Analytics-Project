--- Q1 ---
select osp.user_id,
       SUM(product_price*quantity) as total_spent
from project.orders_sql_project osp
left join  project.users_sql_project usp
on osp.user_id = usp.user_id
left join project.order_items_sql_project oisp 
on osp.order_id = oisp.order_id 
left join project.products_sql_project psp 
on oisp.product_id = psp.product_id 
group by 1
order by 2 desc;

--- Q2 ---
select user_id,
       order_date,
       order_id
from project.orders_sql_project osp 
union all
select user_id,
       order_date,
       store_order_id  as order_id
from project.store_orders so 
where user_id is not null
order by 1,2,3

--- Q3 ---
select product_id
from project.order_items_sql_project oisp
intersect
select product_id
from project.store_order_items soi 
order by 1;

--- Q4 ---
select user_id
from project.orders_sql_project osp 
where order_id in (select order_id 
                   from project.order_items_sql_project
                   where quantity >2)
intersect                  
select user_id
from project.store_orders so 
where store_order_id in (select store_order_id 
                   from project.store_order_items soi
                   where quantity >2)
      and user_id is not null
order by 1;


--- Q5 ---
with cacl_tb as(
select osp.order_id,
       sum(quantity*product_price) as amount
from project.orders_sql_project osp 
left join project.order_items_sql_project oisp
on osp.order_id = oisp.order_id 
left join project.products_sql_project psp 
on oisp.product_id = psp.product_id 
left join project.payments_sql_project psp2 
on psp2.order_id = oisp.order_id 
where payment_status = 'Оплачено'
group by 1)
select round(AVG(amount),2) as avg_check
from cacl_tb ;


--- Q6 ---
with union_tb as (
select order_id,
       quantity,
       'online' as store_type
from project.order_items_sql_project oisp
union all
select store_order_id,
       quantity,
       'offline' as store_type
from project.store_order_items soi )
select store_type,
       SUM(quantity) as total_quantity,
       count(distinct order_id) as count_orders
from union_tb
group by store_type
order by 1,2,3;
       

--- Q7 ---
with qun_tb as(
select osp.user_id,
       oisp.product_id,
       psp.product_name,
       SUM(quantity) as total_quantity
from project.orders_sql_project osp 
left join project.order_items_sql_project oisp 
on osp.order_id = oisp.order_id 
left join project.products_sql_project psp 
on oisp.product_id = psp.product_id 
group by 1,2,3
union all
select so.user_id,
       soi.product_id,
       psp.product_name,
       SUM(quantity) as total_quantity
from project.store_orders so 
left join project.store_order_items soi 
on soi.store_order_id = so.store_order_id  
left join project.products_sql_project psp 
on soi.product_id = psp.product_id 
where user_id is not null
group by 1,2,3
order by 4 desc)
select product_name,
       count(distinct user_id) as count_users
from qun_tb
group by 1
order by 2 desc
limit 3;


--- Q8 ---
with checks_tb as(
select osp.order_id,
       sum(quantity*product_price) as amount,
       'online' as store_type
from project.orders_sql_project osp 
left join project.order_items_sql_project oisp
on osp.order_id = oisp.order_id 
left join project.products_sql_project psp 
on oisp.product_id = psp.product_id  
group by 1
union all
select so.store_order_id,
       sum(quantity*product_price) as amount,
       'offline' as store_type
from project.store_orders so 
left join project.store_order_items soi
on so.store_order_id = soi.store_order_id 
left join project.products_sql_project psp 
on soi.product_id = psp.product_id  
group by 1)
select store_type,
       round (avg(amount),2)
from checks_tb 
group by 1
order by 2;


--- Q9 ---
with avg_of_pr as(
select AVG(product_price) as avg_off_price
from project.store_orders so 
left join project.store_order_items soi 
on so.store_order_id = soi.store_order_id 
left join project.products_sql_project psp 
on soi.product_id = psp.product_id 
where user_id is not null)
select distinct user_id
from project.orders_sql_project osp
left join project.order_items_sql_project oisp 
on osp.order_id = oisp.order_id 
left join project.products_sql_project psp 
on oisp.product_id = psp.product_id 
where psp.product_price > (select avg_off_price from avg_of_pr)
order by 1;


--- Q10 ---
with checks as(
select osp.order_id,
       sum(quantity*product_price) as amount
from project.orders_sql_project osp 
left join project.order_items_sql_project oisp
on osp.order_id = oisp.order_id 
left join project.products_sql_project psp 
on oisp.product_id = psp.product_id  
group by 1
union all
select so.store_order_id,
       sum(quantity*product_price) as amount
from project.store_orders so 
left join project.store_order_items soi
on so.store_order_id = soi.store_order_id 
left join project.products_sql_project psp 
on soi.product_id = psp.product_id  
group by 1),
avg_check_all as(
select round (avg(amount),2) as avg_check
from checks),
checks_all as(
select osp.order_id,
       date_trunc('month', osp.order_date)::date as order_month,
       osp.user_id,
       quantity*product_price as amount
from project.orders_sql_project osp 
left join project.order_items_sql_project oisp
on osp.order_id = oisp.order_id 
left join project.products_sql_project psp 
on oisp.product_id = psp.product_id
union all
select so.store_order_id,
       date_trunc('month', so.order_date):: date as order_month,
       so.user_id,
       quantity*product_price as amount
from project.store_orders so 
left join project.store_order_items soi
on so.store_order_id = soi.store_order_id 
left join project.products_sql_project psp 
on soi.product_id = psp.product_id
where user_id is not null)
select order_month,
       count(user_id)
from checks_all 
where amount > (select avg_check from avg_check_all)
group by 1
order by 1;
