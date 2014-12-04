
/************** 
 * Setup data
 **************/

-- Drop existing tables
drop table if exists sensors cascade;
drop table if exists readings cascade;

-- Create a table of 1000 random sensors
create table sensors (
    sensor_id   serial primary key,
    sensor_name text not null,
    lat         real not null,
    lng         real not null
);

insert into sensors (sensor_name, lat, lng)
    select
        'Sensor ' || cast(n as text) as sensor_name,
        random() * 180 - 90 as lat,
        random() * 360 - 180 as lng
    from    
        generate_series(1, 1000) as n;

-- Create a table of 10^6 random readings
create table readings (
    sensor_id   integer not null references sensors(sensor_id),
    reading_id  serial primary key,
    range_low   real not null,
    range_high  real not null
);

insert into readings (sensor_id, range_low, range_high)
    select
        cast(random() * 999 + 1 as integer) as sensor_id,
        random() * 50 as range_low,
        random() * 50 + 50 as range_high
    from    
        generate_series(1, 1000 * 1000) as n;

-- Update database statistics
analyze;

/*******************
 * Writing queries
 *******************/

-- 1000 sensors
select  *
from    sensors as s;

-- 10^6 readings
select  *
from    readings as r;

-- Counting 10^6 readings is faster than displaying them
select  count(*)
from    readings as r;

-- Find readings with gap > 80
select  *
from    readings as r
where   r.range_high - r.range_low > 80;

-- Find readings with gap > 80, and their corresponding sensors
select  *
from    readings as r
        join sensors as s using (sensor_id)
where   r.range_high - r.range_low > 80;

-- For each sensor, count the number of readings with gap > 80
select  s.sensor_id, count(*)
from    readings as r
        join sensors as s using (sensor_id)
where   r.range_high - r.range_low > 80
group by s.sensor_id;

-- For each sensor, count the number of readings with gap > 80
-- Also sort the sensors, and display each sensor's name, latitude and longtitude
select  s.sensor_name, s.lat, s.lng, count(*)
from    readings as r
        join sensors as s using (sensor_id)
where   r.range_high - r.range_low > 80
group by s.sensor_id
order by s.sensor_id;


-- For each sensor, count the number of readings with gap > X
select  s.sensor_id,
        sum(gt_100) as count_gt_100,
        sum(gt_80)  as count_gt_80,
        sum(gt_60)  as count_gt_60,
        sum(gt_40)  as count_gt_40,
        sum(gt_20)  as count_gt_20,
        sum(gt_0)   as count_gt_0
from    (
            -- For each reading, indicate whether its gap is greater than X
            select  *,
                    case when r.range_high - r.range_low > 100 then 1 else 0 end as gt_100,
                    case when r.range_high - r.range_low >  80 then 1 else 0 end as gt_80,
                    case when r.range_high - r.range_low >  60 then 1 else 0 end as gt_60,
                    case when r.range_high - r.range_low >  40 then 1 else 0 end as gt_40,
                    case when r.range_high - r.range_low >  20 then 1 else 0 end as gt_20,
                    case when r.range_high - r.range_low >   0 then 1 else 0 end as gt_0
            from    readings as r
        ) as cross_tab
        join sensors as s using (sensor_id)
group by s.sensor_id
order by s.sensor_id;

/*******************
 * Tunning queries
 *******************/

/*
 * - First write correct queries, then improve their performance
 * - Base case: tables are accessed in entirety
 */

-- Access all sensors and readings to find readings of Sensor 1
explain
select  *
from    readings as r
        join sensors as s using (sensor_id)
where   s.sensor_name = 'Sensor 1';

/*
Time: 292ms

Plan:
    "Hash Join  (cost=19.51..19185.51 rows=1000 width=34)"
    "  Hash Cond: (r.sensor_id = s.sensor_id)"
    "  ->  Seq Scan on readings r  (cost=0.00..15406.00 rows=1000000 width=16)"
    "  ->  Hash  (cost=19.50..19.50 rows=1 width=22)"
    "        ->  Seq Scan on sensors s  (cost=0.00..19.50 rows=1 width=22)"
    "              Filter: (sensor_name = 'Sensor 1'::text)"
*/

/*
 * - Indexes are the easiest way to speed up queries.
 * - Optimizer automatically rewrites plans to utilize indexes.
 */

-- Create an index to access a reading by its sensor, and update database statistics
create index on readings(sensor_id);
analyze;

-- 10x faster plan that accesses only readings of Sensor 1
explain
select  *
from    readings as r
        join sensors as s using (sensor_id)
where   s.sensor_name = 'Sensor 1';

/*
Time: 18ms

Plan:
    "Nested Loop  (cost=20.11..2594.94 rows=1000 width=34)"
    "  ->  Seq Scan on sensors s  (cost=0.00..19.50 rows=1 width=22)"
    "        Filter: (sensor_name = 'Sensor 1'::text)"
    "  ->  Bitmap Heap Scan on readings r  (cost=20.11..2562.94 rows=1000 width=16)"
    "        Recheck Cond: (sensor_id = s.sensor_id)"
    "        ->  Bitmap Index Scan on readings_sensor_id_idx  (cost=0.00..19.86 rows=1000 width=0)"
    "              Index Cond: (sensor_id = s.sensor_id)"
*/

/*
 * - Indexes are not always beneficial.
 */

-- Create an index to access a sensor by its name
create index on sensors(sensor_name);
analyze;

-- Comparable (or slightly worse) plan, since it's fast anyway to access 1000 sensors
explain
select  *
from    readings as r
        join sensors as s using (sensor_id)
where   s.sensor_name = 'Sensor 1';

/*
Time: 21ms

Plan:
    "Nested Loop  (cost=20.11..2583.71 rows=1000 width=34)"
    "  ->  Index Scan using sensors_sensor_name_idx on sensors s  (cost=0.00..8.27 rows=1 width=22)"
    "        Index Cond: (sensor_name = 'Sensor 1'::text)"
    "  ->  Bitmap Heap Scan on readings r  (cost=20.11..2562.94 rows=1000 width=16)"
    "        Recheck Cond: (sensor_id = s.sensor_id)"
    "        ->  Bitmap Index Scan on readings_sensor_id_idx  (cost=0.00..19.86 rows=1000 width=0)"
    "              Index Cond: (sensor_id = s.sensor_id)"
*/

/*
 * - Switch to more complex (i.e. slower) query
 */

-- Find readings with gap > 80, and their corresponding sensors
explain
select  *
from    readings as r
        join sensors as s using (sensor_id)
where   r.range_high - r.range_low > 80;

/*
Time: 763ms

Plan:
    "Hash Join  (cost=29.50..25018.83 rows=333333 width=34)"
    "  Hash Cond: (r.sensor_id = s.sensor_id)"
    "  ->  Seq Scan on readings r  (cost=0.00..20406.00 rows=333333 width=16)"
    "        Filter: ((range_high - range_low) > 80::double precision)"
    "  ->  Hash  (cost=17.00..17.00 rows=1000 width=22)"
    "        ->  Seq Scan on sensors s  (cost=0.00..17.00 rows=1000 width=22)"
*/


-- Indexes can also be created on expressions
create index on readings((range_high - range_low));
analyze;

-- 2x faster plan that accesses readings of gap > 80
explain
select  *
from    readings as r
        join sensors as s using (sensor_id)
where   r.range_high - r.range_low > 80;

/*
Time: 364ms

Plan:
    "Hash Join  (cost=6273.19..21262.52 rows=333333 width=34)"
    "  Hash Cond: (r.sensor_id = s.sensor_id)"
    "  ->  Bitmap Heap Scan on readings r  (cost=6243.69..16649.69 rows=333333 width=16)"
    "        Recheck Cond: ((range_high - range_low) > 80::double precision)"
    "        ->  Bitmap Index Scan on readings_expr_idx  (cost=0.00..6160.36 rows=333333 width=0)"
    "              Index Cond: ((range_high - range_low) > 80::double precision)"
    "  ->  Hash  (cost=17.00..17.00 rows=1000 width=22)"
    "        ->  Seq Scan on sensors s  (cost=0.00..17.00 rows=1000 width=22)"
*/

/*
 * - Database also uses histograms (i.e. statistics) to track distribution of data values.
 * - Optimizer uses statistics to choose better plans.
 */

-- Since most readings have gap > 20, the best plan is to access all readings via sequential disk I/O (instead of random disk I/O)
explain
select  *
from    readings as r
        join sensors as s using (sensor_id)
where   range_high - range_low > 20;

/*
Time:
4192ms

Plan:
"Hash Join  (cost=29.50..33073.74 rows=919145 width=34)"
"  Hash Cond: (r.sensor_id = s.sensor_id)"
"  ->  Seq Scan on readings r  (cost=0.00..20406.00 rows=919145 width=16)"
"        Filter: ((range_high - range_low) > 20::double precision)"
"  ->  Hash  (cost=17.00..17.00 rows=1000 width=22)"
"        ->  Seq Scan on sensors s  (cost=0.00..17.00 rows=1000 width=22)"
*/

/*
 * - Optimizer uses statistics to choose the most selective condition to evaluate first.
 */

-- Find sensors first, as the sensor name is most selective
explain
select  *
from    readings as r
        join sensors as s using (sensor_id)
where   r.range_high - r.range_low > 20 and s.sensor_name = 'Sensor 1';

/*
Time: 26ms

Plan:
    "Nested Loop  (cost=20.09..2588.69 rows=919 width=34)"
    "  ->  Index Scan using sensors_sensor_name_idx on sensors s  (cost=0.00..8.27 rows=1 width=22)"
    "        Index Cond: (sensor_name = 'Sensor 1'::text)"
    "  ->  Bitmap Heap Scan on readings r  (cost=20.09..2567.92 rows=1000 width=16)"
    "        Recheck Cond: (sensor_id = s.sensor_id)"
    "        Filter: ((range_high - range_low) > 20::double precision)"
    "        ->  Bitmap Index Scan on readings_sensor_id_idx  (cost=0.00..19.86 rows=1000 width=0)"
    "              Index Cond: (sensor_id = s.sensor_id)"
*/

-- Use all 3 indexes to access only relevant readings
explain
select  *
from    readings as r
        join sensors as s using (sensor_id)
where   r.range_high - r.range_low > 80 and s.sensor_name = 'Sensor 1';

/*
Time: 22ms

Plan:
    "Nested Loop  (cost=1465.65..1756.47 rows=77 width=34)"
    "  ->  Index Scan using sensors_sensor_name_idx on sensors s  (cost=0.00..8.27 rows=1 width=22)"
    "        Index Cond: (sensor_name = 'Sensor 1'::text)"
    "  ->  Bitmap Heap Scan on readings r  (cost=1465.65..1747.24 rows=77 width=16)"
    "        Recheck Cond: ((sensor_id = s.sensor_id) AND ((range_high - range_low) > 80::double precision))"
    "        ->  BitmapAnd  (cost=1465.65..1465.65 rows=77 width=0)"
    "              ->  Bitmap Index Scan on readings_sensor_id_idx  (cost=0.00..19.86 rows=1000 width=0)"
    "                    Index Cond: (sensor_id = s.sensor_id)"
    "              ->  Bitmap Index Scan on readings_expr_idx  (cost=0.00..1426.26 rows=77053 width=0)"
    "                    Index Cond: ((range_high - range_low) > 80::double precision)"
*/



