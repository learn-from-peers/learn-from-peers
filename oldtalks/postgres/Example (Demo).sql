
/*******************
 * Writing queries
 *******************/

select  *
from    sensors as s;

select  *
from    readings as r;

select  count(*)
from    readings as r;

select  *
from    readings as r
where   r.range_high - r.range_low > 80;

select  *
from    readings as r
        join sensors as s using (sensor_id)
where   r.range_high - r.range_low > 80;

select  s.sensor_id, count(*)
from    readings as r
        join sensors as s using (sensor_id)
where   r.range_high - r.range_low > 80
group by s.sensor_id;

select  s.sensor_name, s.lat, s.lng, count(*)
from    readings as r
        join sensors as s using (sensor_id)
where   r.range_high - r.range_low > 80
group by s.sensor_id
order by s.sensor_id;


select  s.sensor_id,
        sum(gt_100) as count_gt_100,
        sum(gt_80)  as count_gt_80,
        sum(gt_60)  as count_gt_60,
        sum(gt_40)  as count_gt_40,
        sum(gt_20)  as count_gt_20,
        sum(gt_0)   as count_gt_0
from    (
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
 * - Switch to more complex (i.e. slower) query
 */

-- Find readings with gap > 80, and their corresponding sensors
explain
select  *
from    readings as r
        join sensors as s using (sensor_id)
where   r.range_high - r.range_low > 80;

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
 * - Optimizer uses statistics to choose the most selective condition to evaluate first.
 */

-- Find sensors first, as the sensor name is most selective
explain
select  *
from    readings as r
        join sensors as s using (sensor_id)
where   r.range_high - r.range_low > 20 and s.sensor_name = 'Sensor 1';

-- Use all 3 indexes to access only relevant readings
explain
select  *
from    readings as r
        join sensors as s using (sensor_id)
where   r.range_high - r.range_low > 80 and s.sensor_name = 'Sensor 1';
