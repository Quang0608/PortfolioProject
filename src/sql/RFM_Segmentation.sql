with customer_statistics as (
select customerid , max(Purchase_Date) as latest_purchase_date ,
            datediff(year,min(created_date),'2022-09-01') as contract_age,
            datediff(day,max(Purchase_Date),'2022-09-01') as recency ,
            1.0*count(*)/datediff(year,min(created_date),'2022-09-01') as frequency ,
            1.0*sum(GMV)/datediff(year,min(created_date),'2022-09-01') as monetary ,
            row_number() over (order by datediff(day,max(Purchase_Date),'2022-09-01') asc) as rn_recency ,
            row_number() over (order by 1.0*count(*)/datediff(year,min(created_date),'2022-09-01') asc) as rn_frequency,
            row_number() over (order by 1.0*sum(GMV)/datediff(year,min(created_date),'2022-09-01') asc ) as rn_monetary
--- into #customer_statistics
from customer_transaction ct
join Customer_Registered cr on ct.customerid = cr.ID
where customerid != 0
group by customerID ),
    IQR_R as (
    select min(recency) as min_r ,
           (select recency from customer_statistics where rn_recency = round((select max(rn_recency)*0.25 from customer_statistics),0)) as q1_r,
           ((select recency from customer_statistics where rn_recency = round((select max(rn_recency)*0.5 from customer_statistics),0))) as q2_r,
           ((select recency from customer_statistics where rn_recency = round((select max(rn_recency)*0.75 from customer_statistics),0))) as q3_r
    from customer_statistics
) ,
    IQR_F as (
    select min(frequency) as min_F ,
           (select frequency from customer_statistics where rn_frequency = round((select max(rn_frequency)*0.25 from customer_statistics),0)) as q1_F,
           ((select frequency from customer_statistics where rn_frequency = round((select max(rn_frequency)*0.5 from customer_statistics),0))) as q2_F,
           ((select frequency from customer_statistics where rn_frequency = round((select max(rn_frequency)*0.75 from customer_statistics),0))) as q3_F
    from customer_statistics
),
    IQR_M as (
    select min(monetary) as min_M ,
           (select monetary from customer_statistics where rn_monetary = round((select max(rn_monetary)*0.25 from customer_statistics),0)) as q1_M,
           ((select monetary from customer_statistics where rn_monetary = round((select max(rn_monetary)*0.5 from customer_statistics),0))) as q2_M,
           ((select monetary from customer_statistics where rn_monetary = round((select max(rn_monetary)*0.75 from customer_statistics),0))) as q3_M
    from customer_statistics
)
select cs.* , case
       when cs.recency >= IQR_R.min_r and cs.recency < IQR_R.q1_r then '1'
        when cs.recency >= IQR_R.q1_r and cs.recency < IQR_R.q2_r then '2'
        when cs.recency >= IQR_R.q2_r and cs.recency < IQR_R.q3_r then '3'
        else '4'
        end as R ,
        case
       when cs.frequency >= IQR_R.min_r and cs.frequency < IQR_R.q1_r then '1'
        when cs.frequency >= IQR_R.q1_r and cs.frequency < IQR_R.q2_r then '2'
        when cs.frequency >= IQR_R.q2_r and cs.frequency < IQR_R.q3_r then '3'
        else '4'
        end as F,
    case
       when cs.monetary >= IQR_R.min_r and cs.monetary < IQR_R.q1_r then '1'
        when cs.monetary >= IQR_R.q1_r and cs.monetary < IQR_R.q2_r then '2'
        when cs.monetary >= IQR_R.q2_r and cs.monetary < IQR_R.q3_r then '3'
        else '4'
        end as M
into #RFM
from customer_statistics cs
cross join IQR_R
cross join IQR_F
cross join IQR_M
;
With Segmentation as(
	Select *, concat(R,F,M) as RFM
	From #RFM
)
SELECT *,
    CASE 
        WHEN RFM IN ('444', '443', '424', '423', '344', '343') THEN 'VIP'
        WHEN RFM IN ('422', '421', '414', '413', '412', '411', '314', '313', '312', '311', '214') THEN 'Question Mark'
        WHEN RFM IN ('342', '341', '324', '323', '322', '321', '244', '243', '242', '241', '224', '223', '442', '441') THEN 'Cash Cow'
        ELSE 'Dogs'
    END AS Customer_Segmentation
FROM Segmentation
