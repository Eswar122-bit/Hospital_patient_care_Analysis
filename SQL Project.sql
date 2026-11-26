create database Hospital_Patient_Care_Operations_Analytics;

use Hospital_Patient_Care_Operations_Analytics;
 
select * from appointments limit 3;
select * from doctors limit 3 ;
select * from patients limit 3;
select * from rooms limit 3;
select * from treatments limit 3;

alter table rooms
modify room_id varchar(10) not null,
modify room_type varchar(30),
modify floor int,
modify equipment_type varchar(50),
modify capacity int,
modify last_maintenance_date date,
modify is_available varchar(3);

alter table patients
modify patient_id varchar(20) not null,
modify patient_name varchar(100),
modify age int,
modify gender varchar(10),
modify city varchar(50),
modify  patient_type varchar(20),
modify preferred_time_slot varchar(20),
modify registration_date date;

alter table treatments
modify treatment_id varchar(20) not null,
modify appointment_id varchar(20),
modify doctor_id varchar(10),
modify room_id varchar(10),
modify actual_treatment_date date,
modify status varchar(20),
modify treatment_attempt int,
modify treatment_duration_min int,
modify waiting_time_min int,
modify treatment_cost decimal(10,2);

alter table doctors
modify doctor_id varchar(10) not null,
modify doctor_name varchar(100),
modify specialty varchar(50),
modify hire_date date,
modify rating decimal(3,2),
modify employment_type varchar(20),
modify is_active varchar(3);

alter table appointments
modify appointment_id varchar(20) not null,
modify patient_id varchar(20),
modify appointment_date date,
modify doctor_id varchar(10),
modify service_type varchar(30),
modify  priority varchar(10),
modify estimated_cost decimal(10,2),
modify booking_channel varchar(20);

-- addding the primary keys
alter table patients
add primary key (patient_id);

alter table doctors
add primary key (doctor_id);

alter table rooms
add primary key (room_id);

alter table appointments
add primary key (appointment_id);

alter table treatments
add primary key (treatment_id);


-- adding foreign keys
alter table appointments
add constraint fk_appointments_patients 
foreign key (patient_id) 
references patients(patient_id);

alter table appointments
add constraint fk_appointments_doctors 
foreign key (doctor_id) 
references doctors(doctor_id);

alter table treatments
add constraint fk_treatments_appointments 
foreign key (appointment_id) 
references appointments(appointment_id),

add constraint fk_treatments_doctors 
foreign key (doctor_id) 
references doctors(doctor_id),

add constraint fk_treatments_rooms 
foreign key (room_id) 
references rooms(room_id);

show tables;


select * from appointments;

-- basis analysis and data exploration

-- total number of patients
select count(patient_id) total_patients from patients;

-- total number of appointments
select count(appointment_id) as total_appointments from appointments;

-- total number of treatment records
select count(treatment_id) total_treatments from treatments;

-- number of doctors active
select count(doctor_id)  as active_docs from doctors 
where is_active = 'yes';

-- types of rooms
select distinct room_type from rooms;

-- total_estimated appointment value
select sum(estimated_cost) as estimated_total from appointments;

-- avg treatment duration
select avg(treatment_duration_min) as avg_duration from treatments;

-- medical_services types
select distinct service_type as medical_services from appointments;

-- 4.1 patient and appointment demand
-- which cities have the highest appointments

select p.city,count(a.appointment_id) total_appointments from appointments a
left join patients p on
p.patient_id = p.patient_id
group by p.city 
order by total_appointments desc;

-- Which cities generate the highest estimated appointment value?
select p.city,sum(estimated_cost) as maximum_cost from appointments a
left join patients p on
p.patient_id = a.patient_id
group by p.city
order by maximum_cost desc;

-- How many appointments are recorded under each service type?
select a.service_type,count(appointment_id) as total_appointments from appointments a
group by a.service_type;

-- How does appointment volume differ across priority levels for each service type?
select priority,sum(estimated_cost) as estimated_cost from appointments
group by priority;

-- What are the earliest and latest appointment dates for each priority level?
select max(appointment_date) as earliest_date , min(appointment_date) as latest_date, priority from appointments 
group by priority;

-- What is the average monthly appointment volume by year?
select year,avg(total_appointments) as average_mntly_appointments from (select year(appointment_date)as year,
month(appointment_date) as month,count(appointment_id) as total_appointments
from appointments
group by year(appointment_date),month(appointment_date)) as monthly_data
group by year
order by year;

-- What is the average estimated appointment cost for each patient type?
select p.patient_type,avg(a.estimated_cost) as avg_cost  from appointments a
left join patients p on
a.patient_id = p.patient_id
group by patient_type;

-- How many patients of each patient type use each service type?
select count(p.patient_id) as total_patients,p.patient_type,a.service_type from patients p
left join appointments a on
p.patient_id = a.patient_id
group by p.patient_type,
a.service_type
order by p.patient_type,
a.service_type;

-- How many appointments are booked through each booking channel?
select booking_channel,count(appointment_id) as total_appointments from appointments
group by booking_channel;

-- What percentage of total appointments does each booking channel contribute?
select booking_channel,count(appointment_id) as channel_appointments,
round(count(appointment_id) * 100.0 /(select count(appointment_id) from appointments),2) as appointment_percentage from appointments
group by booking_channel
order by appointment_percentage desc;

-- 4.2 patient appointment behaviour
-- Scenario 1: Patient appointment frequency
-- How many patients have booked only one appointment versus multiple appointments?
select case when appointment_count = 1 then 'single appointment' else 'multiple appointments'
end as patient_category, count(*) as total_patients from (select patient_id, count(appointment_id) as appointment_count
from appointments 
group by patient_id) as patient_frequency 
group by patient_category;

-- Patient behaviour across cities
-- Which cities have the highest number of repeat patients?
select p.city, count(*) as repeat_patients 
from (select patient_id from appointments 
group by patient_id 
having count(appointment_id) > 1) r
inner join patients p on 
r.patient_id = p.patient_id 
group by p.city 
order by repeat_patients desc;

-- Which patient types contribute the most repeat appointments in each city?
select p.city,p.patient_type,count(a.appointment_id) as repeat_appointments,
count(distinct p.patient_id) as repeat_patients
from patients p
inner join appointments a on p.patient_id = a.patient_id
inner join (
select patient_id
from appointments
group by patient_id
having count(appointment_id) > 1
) as repeat_data on p.patient_id = repeat_data.patient_id
group by p.city,p.patient_type
order by p.city,repeat_appointments desc;

-- Patient appointment preferences
-- How does appointment volume vary according to patients preferred time slots?
select p.preferred_time_slot,count(a.appointment_id) as total_appointments
from patients p
inner join appointments a on p.patient_id = a.patient_id
group by p.preferred_time_slot
order by total_appointments desc;

-- Which patient types prefer each appointment time slot?
select p.patient_type,p.preferred_time_slot,count(distinct p.patient_id) as total_patients,
count(a.appointment_id) as total_appointments
from patients p
inner join appointments a on p.patient_id = a.patient_id
group by p.patient_type,p.preferred_time_slot
order by p.patient_type,total_patients desc;

-- New versus returning patients
-- How many patients registered during each year, and how many appointments did they make?
select year(p.registration_date) as registration_year,
count(distinct p.patient_id) as total_patients,
count(a.appointment_id) as total_appointments
from patients p
left join appointments a on p.patient_id = a.patient_id
group by year(p.registration_date)
order by registration_year;

-- Which registration periods have the highest average number of appointments per patient?
select year(p.registration_date) as registration_year,
count(distinct p.patient_id) as total_patients,
count(a.appointment_id) as total_appointments,
round(count(a.appointment_id) / count(distinct p.patient_id),2) as avg_appointments_per_patient
from patients p
left join appointments a on p.patient_id = a.patient_id
group by year(p.registration_date)
order by avg_appointments_per_patient desc;

-- Appointment booking patterns
-- Which booking channels are most frequently used by new and returning patients?
with appointment_ranking as (
select appointment_id,patient_id,booking_channel,appointment_date,
row_number() over(partition by patient_id order by appointment_date,appointment_id) as appointment_number
from appointments
)
select
case
when appointment_number = 1 then 'new'
else 'returning'
end as patient_category,
booking_channel,
count(appointment_id) as total_appointments
from appointment_ranking
group by patient_category,booking_channel
order by patient_category,total_appointments desc;

-- Do appointment priorities differ between new and returning patients?
with appointment_ranking as (
select appointment_id,patient_id,priority,appointment_date,
row_number() over(partition by patient_id order by appointment_date,appointment_id) as appointment_number
from appointments
)
select
case
when appointment_number = 1 then 'new'
else 'returning'
end as patient_category,
priority,
count(appointment_id) as total_appointments
from appointment_ranking
group by patient_category,priority
order by patient_category,total_appointments desc;

-- views and stored procedures
-- view 1
-- purpose of this view : Analyse treatment status, volume, cost, duration, waiting time and repeated treatment attempts.
create view vw_treatment_performance_summary as
select t.status,
count(t.treatment_id) as total_treatments,
sum(t.treatment_cost) as total_treatment_cost,
round(avg(t.treatment_cost),2) as avg_treatment_cost,
round(avg(t.treatment_duration_min),2) as avg_treatment_duration,
round(avg(t.waiting_time_min),2) as avg_waiting_time,
sum(case when t.treatment_attempt > 1 then 1 else 0 end) as multiple_attempt_treatments,
count(distinct a.appointment_id) as total_appointments
from treatments t
left join appointments a on t.appointment_id = a.appointment_id
group by t.status;

select * from vw_treatment_performance_summary;

-- view 2 
-- Doctor and Room Performance
-- purpose of this view : analyse doctor workload, treatment performance, room utilization and treatment costs.
create view vw_doctor_room_performance as
select d.doctor_id,d.doctor_name,d.specialty,d.rating,
r.room_id,r.room_type,
count(distinct t.treatment_id) as total_treatments,
count(distinct t.appointment_id) as total_appointments,
round(avg(t.treatment_duration_min),2) as avg_treatment_duration,
round(avg(t.waiting_time_min),2) as avg_waiting_time,
coalesce(sum(t.treatment_cost),0) as total_treatment_cost
from doctors d
left join treatments t on 
d.doctor_id = t.doctor_id
left join rooms r on 
t.room_id = r.room_id
group by d.doctor_id,d.doctor_name,d.specialty,d.rating,r.room_id,r.room_type;

select * from vw_doctor_room_performance;

-- stored procedure 1
-- purpose : Analyse treatments within a user-selected date range
delimiter //
create procedure sp_treatment_analysis(
in p_start_date date,
in p_end_date date,
in p_status varchar(20))
begin
select t.status,count(t.treatment_id) as total_treatments,coalesce(sum(t.treatment_cost),0) as total_treatment_cost,
round(avg(t.treatment_cost),2) as avg_treatment_cost,
round(avg(t.treatment_duration_min),2) as avg_treatment_duration,
round(avg(t.waiting_time_min),2) as avg_waiting_time,
sum(case when t.treatment_attempt > 1 then 1 else 0 end) as multiple_attempt_treatments from treatments t
where t.actual_treatment_date between p_start_date and p_end_date
and (p_status is null or t.status = p_status)
group by t.status;
end //
delimiter ;

call sp_treatment_analysis('2025-01-01','2025-12-31',null);
call sp_treatment_analysis('2025-01-01','2025-12-31','cancelled');

select distinct status from treatments;


-- stored procedure 2 : sp_doctor_performance_analysis
-- Purpose: Compare doctors based on their treatment workload and performance.

delimiter //
create procedure sp_doctor_performance_analysis(
in p_specialty varchar(50),
in p_is_active varchar(3))
begin
select
d.doctor_id,
d.doctor_name,
d.specialty,
d.rating,
d.employment_type,
d.is_active,
count(distinct t.treatment_id) as total_treatments,
count(distinct t.appointment_id) as total_appointments,
round(avg(t.treatment_duration_min),2) as avg_treatment_duration,
round(avg(t.waiting_time_min),2) as avg_waiting_time,
coalesce(sum(t.treatment_cost),0) as total_treatment_cost
from doctors d
left join treatments t on d.doctor_id = t.doctor_id
where (p_specialty is null or d.specialty = p_specialty)
and (p_is_active is null or d.is_active = p_is_active)
group by d.doctor_id,d.doctor_name,d.specialty,d.rating,d.employment_type,d.is_active
order by total_treatments desc;
end //
delimiter ;

call sp_doctor_performance_analysis(null,null);
call sp_doctor_performance_analysis(null,'yes');

-- stored procedure 3 :sp_room_utilization_analysis
-- Purpose: Understand how frequently rooms are used.
delimiter //
create procedure sp_room_utilization_analysis(
in p_room_type varchar(30),
in p_is_available varchar(3))
begin
select
r.room_id,
r.room_type,
r.floor,
r.equipment_type,
r.capacity,
r.is_available,
count(t.treatment_id) as total_treatments,
round(avg(t.treatment_duration_min),2) as avg_treatment_duration,
round(avg(t.waiting_time_min),2) as avg_waiting_time,
coalesce(sum(t.treatment_cost),0) as total_treatment_cost
from rooms r
left join treatments t on r.room_id = t.room_id
where (p_room_type is null or r.room_type = p_room_type)
and (p_is_available is null or r.is_available = p_is_available)
group by r.room_id,r.room_type,r.floor,r.equipment_type,r.capacity,r.is_available
order by total_treatments desc;
end //
delimiter ;

call sp_room_utilization_analysis('minor surgery',null);


-- 4.5 Identify Treatment and Appointment Problems

-- Which doctors handled the highest number of treatments requiring multiple attempts? 
create view vw_doctors_maximum_attempt as
select d.doctor_id,d.doctor_name,
sum(case when t.treatment_attempt >1 then 1 else 0 end) as maximum_attempt from doctors d
left join treatments t on
d.doctor_id = t.doctor_id
group by d.doctor_id,d.doctor_name
having maximum_attempt > 0
order by maximum_attempt desc;

select * from vw_doctors_maximum_attempt;

-- What is the distribution of treatment statuses across all treatments?
create view vw_treatment_distribution_across_status as
select status,count(treatment_id) as total_treatments,round(count(treatment_id)*100/(select count(*) from treatments),2) as percentage
from treatments
group by status
order by total_treatments desc;

select * from vw_treatment_distribution_across_status;

-- Which treatment statuses have the highest average treatment cost and waiting time?
create view vw_avg_cost_and_waiting_time as
select status,count(treatment_id) as total_treatments,
round(avg(treatment_cost),2) as avg_cost,
round(avg(waiting_time_min),2) as avg_waiting_time
from treatments 
group by status
order by avg_waiting_time desc;

select * from vw_avg_cost_and_waiting_time;

-- How does the average waiting time differ between appointments requiring single and multiple treatment attempts? sp
delimiter //
create procedure sp_avg_waiting_time_analysis(in start_date date,in end_date date)
begin 
select case
when treatment_attempt = 1 then 'single attempt'
when treatment_attempt > 1 then 'multiple attempts'
else 'unknown'
end as attempt_category,
count(treatment_id) as total_treatments,
round(avg(waiting_time_min),2) as avg_waiting_time
from treatments
where actual_treatment_date between start_date and end_date
group by attempt_category
order by avg_waiting_time desc;
end //
delimiter ;

call sp_avg_waiting_time_analysis('2025-01-01','2025-05-30');
-- Which service types have the highest average waiting time for treatments requiring multiple attempts?
create view vw_avg_waiting_time_for_multiple_attempts as
select a.service_type,count(treatment_id) as total_treatments,
avg(t.waiting_time_min) as avg_waiting_time,
avg(treatment_duration_min) as avg_duration
from treatments t
join appointments a on
t.appointment_id = a.appointment_id
where t.treatment_attempt > 1
group by a.service_type
order by avg_waiting_time desc;

select * from vw_avg_waiting_time_for_multiple_attempts;

-- Which cities have the highest numbers of cancelled, no-show and rescheduled appointments?
create view vw_status_count_per_city as
select p.city,
sum(case when t.status = 'no-show'then 1 else 0 end) as no_show_count,
sum(case when t.status = 'completed'then 1 else 0 end) as completed_count,
sum(case when t.status = 'rescheduled'then 1 else 0 end) as rescheduled_count,
sum(case when t.status = 'in progress'then 1 else 0 end) as in_progress_count,
sum(case when t.status = 'cancelled'then 1 else 0 end) as cancelled_count,
count(t.treatment_id) as total_treatments 
from treatments t
join appointments a on 
a.appointment_id = t.appointment_id
join patients p on 
p.patient_id = a.patient_id 
where t.status in ('no-show','completed','rescheduled','in progress','cancelled')
group by p.city
order by total_treatments desc;

select * from vw_status_count_per_city;
-- Which service types have the highest cancellation, no-show and rescheduling rates? sp
delimiter //

create procedure sp_service_type_problem_analysis(
in p_service_type varchar(30)
)
begin
select
a.service_type,
count(t.treatment_id) as total_treatments,
sum(case when t.status = 'Cancelled' then 1 else 0 end) as cancelled_count,
sum(case when t.status = 'No-Show' then 1 else 0 end) as no_show_count,
sum(case when t.status = 'Rescheduled' then 1 else 0 end) as rescheduled_count,
round(sum(case when t.status = 'Cancelled' then 1 else 0 end)*100/count(t.treatment_id),2) as cancellation_rate,
round(sum(case when t.status = 'No-Show' then 1 else 0 end)*100/count(t.treatment_id),2) as no_show_rate,
round(sum(case when t.status = 'Rescheduled' then 1 else 0 end)*100/count(t.treatment_id),2) as rescheduling_rate
from treatments t
join appointments a on t.appointment_id = a.appointment_id
where p_service_type is null or a.service_type = p_service_type
group by a.service_type
order by cancellation_rate desc;
end //

delimiter ;

call sp_service_type_problem_analysis(null);