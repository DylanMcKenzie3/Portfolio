
--Previewing the Columns in Each Table
Select *
From bellabeat..sleepDay_merged$ 

Select *
From bellabeat..weightLogInfo_merged$


Select *
From bellabeat..dailyActivity_merged$ 




--Looking at how Many Unique Users per Table
Select COUNT(Distinct Id)
From bellabeat..sleepDay_merged$ 

Select COUNT(DISTINCT Id)
From bellabeat..weightLogInfo_merged$


Select COUNT(DISTINCT Id)
From bellabeat..dailyActivity_merged$ 


--Setting The Time of Day

Declare 
@MORNING_START INT, @MORNING_END INT, @AFTERNOON_END INT, @EVENING_END INT
SET @MORNING_START = 6
SET @MORNING_END = 12
SET @AFTERNOON_END = 18
SET @EVENING_END = 21 

--Setting Date Format Across Each Table

Select CONVERT(Date, ActivityDate)
From bellabeat..dailyActivity_merged$ 

Update bellabeat..dailyActivity_merged$
SET ActivityDateConverted = CONVERT(Date, ActivityDate) 

Alter Table bellabeat..dailyActivity_merged$ 
Add ActivityDateConverted Date

Update bellabeat..dailyActivity_merged$
SET ActivityDateConverted = CONVERT(Date, ActivityDate) 



Select CONVERT(Date, Date)
From bellabeat..weightLogInfo_merged$

Update bellabeat..weightLogInfo_merged$
SET Date=CONVERT(Date, Date)

Alter Table bellabeat..weightLogInfo_merged$
Add DateConverted Date

Update bellabeat..weightLogInfo_merged$
SET DateConverted = CONVERT(Date, Date) 



Select CONVERT(Date, SleepDay)
From bellabeat..sleepDay_merged$

Update bellabeat..sleepDay_merged$
SET SleepDay=CONVERT(Date, SleepDay)

Alter Table bellabeat..sleepDay_merged$
Add SleepDayConverted Date

Update bellabeat..sleepDay_merged$
SET SleepDayConverted = CONVERT(Date, SleepDay) 

--Changing 1 and 0 to Yes and No in IsManualReport Field

Select Distinct(IsManualReport), COUNT(IsManualReport) 
From bellabeat..weightLogInfo_merged$ 
Group By IsManualReport
Order By 2 

Select IsManualReport 
,	CASE When IsManualReport = '1' Then 'Yes' 
         When IsManualReport = '0' Then 'No' 
		 END
From bellabeat..weightLogInfo_merged$ 

Update bellabeat..weightLogInfo_merged$
SET IsManualReport = CASE When IsManualReport = '1' Then 'Yes' 
         When IsManualReport = '0' Then 'No' 
		 END
From bellabeat..weightLogInfo_merged$ 


--Joining Data for Analysis

Select Distinct da.Id, da.ActivityDateConverted, da.TotalSteps, da.TotalDistance, da.VeryActiveMinutes, da.FairlyActiveMinutes,da.LightlyActiveMinutes
,da.SedentaryMinutes,da.Calories
,sd.TotalMinutesAsleep, sd.TotalTimeInBed, sd.SleepDayConverted
,wl.DateConverted, wl.WeightPounds, wl.BMI, wl.IsManualReport
From bellabeat..dailyActivity_merged$ da 
 JOIN bellabeat..sleepDay_merged$ sd 
	ON da.Id = sd.Id 
 JOIN bellabeat..weightLogInfo_merged$ wl
	ON wl.Id = sd.Id 

--Creating a Temp Table 

Drop Table if exists #DailyActivitySleep
Create Table #DailyActivitySleep
 ( 
 Id float,
 Date date,
 TotalSteps float,
 VeryActiveMinutes float,
 FairlyActiveMinutes float,
 LightlyActiveMinutes float,
 SedentaryMinutes float,
 Calories float,
 TotalMinutesAsleep float,
 TotalTimeInBed float,
 DayofWeek int 
 )
Insert Into #DailyActivitySleep
Select Distinct da.Id, da.ActivityDateConverted, da.TotalSteps, da.VeryActiveMinutes, da.FairlyActiveMinutes,da.LightlyActiveMinutes
,da.SedentaryMinutes,da.Calories
,sd.TotalMinutesAsleep, sd.TotalTimeInBed, DATEPART(weekday, ActivityDateConverted) as DayOfWeek
From bellabeat..dailyActivity_merged$ da 
 JOIN bellabeat..sleepDay_merged$ sd 
	ON da.Id = sd.Id 
	AND da.ActivityDateConverted = sd.SleepDayConverted 

--Assigning Each Numeric Value to a Day of the Week

Select Distinct(DayofWeek), COUNT(DayofWeek) 
, CASE When DayofWeek = '1' Then 'Sunday'
	   When DayofWeek = '2' Then 'Monday'
	   When DayofWeek = '3' Then 'Tuesday'
	   When DayofWeek = '4' Then 'Wednesday'
	   When DayofWeek = '5' Then 'Thursday'
	   When DayofWeek = '6' Then 'Friday'
	   When DayofWeek = '7' Then 'Saturday'
	   END
From #DailyActivitySleep
Group By DayofWeek
Order By 2 DESC  


--Summary Statistics

--Calculating totals of active and non-active minutes
Select 
Id,
Date,
SUM(VeryActiveMinutes) as heavy_exercise,
SUM(FairlyActiveMinutes) as moderate_exercise,
SUM(LightlyActiveMinutes) as light_exercise,
SUM(SedentaryMinutes) as sedentary,	
SUM(VeryActiveMinutes + FairlyActiveMinutes + LightlyActiveMinutes) as TotalActiveMinutes,
(SUM(VeryActiveMinutes + FairlyActiveMinutes + LightlyActiveMinutes)/SUM(SedentaryMinutes))*100 as PercentActiveMinutes
From #DailyActivitySleep 
Where 
VeryActiveMinutes <> '0' AND FairlyActiveMinutes <> '0' AND LightlyActiveMinutes <> '0' 
Group By Id, Date 

--View For Later Visualization

Create View DailyActivitySleep as
Select Distinct da.Id, da.ActivityDateConverted, da.TotalSteps, da.VeryActiveMinutes, da.FairlyActiveMinutes,da.LightlyActiveMinutes
,da.SedentaryMinutes,da.Calories
,sd.TotalMinutesAsleep, sd.TotalTimeInBed, DATEPART(weekday, ActivityDateConverted) as DayOfWeek
From bellabeat..dailyActivity_merged$ da 
 JOIN bellabeat..sleepDay_merged$ sd 
	ON da.Id = sd.Id 
	AND da.ActivityDateConverted = sd.SleepDayConverted 

--Calculating Average Steps and Calories Burned per day
Select 
AVG(TotalSteps) as AverageSteps,
AVG(Calories) as AverageCalories
From #DailyActivitySleep

--Adding a Column PercentInBedAsleep by Dividing the Minutes Asleep and Time in Bed
Alter Table #DailyActivitySleep
Add PercentInBedAsleep numeric 

Update #DailyActivitySleep
SET PercentInBedAsleep = (TotalMinutesAsleep/TotalTimeInBed)*100
From #DailyActivitySleep

Select Distinct(Id), (TotalMinutesAsleep/TotalTimeInBed)*100 as PercentInBedAsleep
From #DailyActivitySleep
Order By 2 

--Temp Table, New JOIN below

--Drop Table if exists #DailyTracking
--Create Table #DailyTracking
-- ( 
-- Id float,
-- Date date,
-- TotalSteps float,
-- VeryActiveMinutes float,
-- FairlyActiveMinutes float,
-- LightlyActiveMinutes float,
-- SedentaryMinutes float,
-- Calories float,
-- TotalMinutesAsleep float,
-- TotalTimeInBed float,
-- WeightPounds float,
-- BMI float,
-- IsManualReport nvarchar(255)
-- ) 
--Insert Into #DailyTracking
--Select Distinct da.Id, da.ActivityDateConverted, da.TotalSteps, da.VeryActiveMinutes, da.FairlyActiveMinutes,da.LightlyActiveMinutes
--,da.SedentaryMinutes,da.Calories
--,sd.TotalMinutesAsleep, sd.TotalTimeInBed
--, wl.WeightPounds, wl.BMI, wl.IsManualReport
--From bellabeat..dailyActivity_merged$ da 
-- JOIN bellabeat..sleepDay_merged$ sd 
--	ON da.Id = sd.Id 
-- JOIN bellabeat..weightLogInfo_merged$ wl
--	ON wl.Id = sd.Id

--Select Distinct * 
--From #DailyTracking 



Select Distinct(IsManualReport), COUNT(IsManualReport) 
From bellabeat..weightLogInfo_merged$ 
Group By IsManualReport
Order By 2 

Select IsManualReport 
,	CASE When IsManualReport = '1' Then 'Yes' 
         When IsManualReport = '0' Then 'No' 
		 END
From bellabeat..weightLogInfo_merged$ 

Update bellabeat..weightLogInfo_merged$
SET IsManualReport = CASE When IsManualReport = '1' Then 'Yes' 
         When IsManualReport = '0' Then 'No' 
		 END
From bellabeat..weightLogInfo_merged$ 

Select Id, (TotalMinutesAsleep/TotalTimeInBed)*100 as PercentInBedAsleep
From bellabeat..sleepDay_merged$
Order By 2 


--New Join for Temp Table


Drop Table if exists #DailyActivitySleep
Create Table #DailyActivitySleep
 ( 
 Id float,
 Date date,
 TotalSteps float,
 VeryActiveMinutes float,
 FairlyActiveMinutes float,
 LightlyActiveMinutes float,
 SedentaryMinutes float,
 Calories float,
 TotalMinutesAsleep float,
 TotalTimeInBed float,
 DayofWeek int 
 )
Insert Into #DailyActivitySleep
Select Distinct da.Id, da.ActivityDateConverted, da.TotalSteps, da.VeryActiveMinutes, da.FairlyActiveMinutes,da.LightlyActiveMinutes
,da.SedentaryMinutes,da.Calories
,sd.TotalMinutesAsleep, sd.TotalTimeInBed, DATEPART(weekday, ActivityDateConverted) as DayOfWeek
From bellabeat..dailyActivity_merged$ da 
 JOIN bellabeat..sleepDay_merged$ sd 
	ON da.Id = sd.Id 
	AND da.ActivityDateConverted = sd.SleepDayConverted 

Select * 
From #DailyActivitySleep
Order By PercentInBedAsleep 


--Summary Statistics

--Calculating totals of active and non-active minutes
Select 
Id,
Date,
SUM(VeryActiveMinutes) as heavy_exercise,
SUM(FairlyActiveMinutes) as moderate_exercise,
SUM(LightlyActiveMinutes) as light_exercise,
SUM(SedentaryMinutes) as sedentary,	
SUM(VeryActiveMinutes + FairlyActiveMinutes + LightlyActiveMinutes) as TotalActiveMinutes,
(SUM(VeryActiveMinutes + FairlyActiveMinutes + LightlyActiveMinutes)/SUM(SedentaryMinutes))*100 as PercentActiveMinutes
From #DailyActivitySleep 
Where 
VeryActiveMinutes <> '0' AND FairlyActiveMinutes <> '0' AND LightlyActiveMinutes <> '0' 
Group By Id, Date

--View 

Create View DailyActivitySleep as
Select Distinct da.Id, da.ActivityDateConverted, da.TotalSteps, da.VeryActiveMinutes, da.FairlyActiveMinutes,da.LightlyActiveMinutes
,da.SedentaryMinutes,da.Calories
,sd.TotalMinutesAsleep, sd.TotalTimeInBed, DATEPART(weekday, ActivityDateConverted) as DayOfWeek
From bellabeat..dailyActivity_merged$ da 
 JOIN bellabeat..sleepDay_merged$ sd 
	ON da.Id = sd.Id 
	AND da.ActivityDateConverted = sd.SleepDayConverted 



--Average steps and calories burned per day
Select 
AVG(TotalSteps) as AverageSteps,
AVG(Calories) as AverageCalories
From #DailyActivitySleep

Alter Table #DailyActivitySleep
Add PercentInBedAsleep numeric 

Update #DailyActivitySleep
SET PercentInBedAsleep = (TotalMinutesAsleep/TotalTimeInBed)*100
From #DailyActivitySleep

Select Distinct(Id), (TotalMinutesAsleep/TotalTimeInBed)*100 as PercentInBedAsleep
From #DailyActivitySleep
Order By 2 


Select Distinct(DayofWeek), COUNT(DayofWeek) 
, CASE When DayofWeek = '1' Then 'Sunday'
	   When DayofWeek = '2' Then 'Monday'
	   When DayofWeek = '3' Then 'Tuesday'
	   When DayofWeek = '4' Then 'Wednesday'
	   When DayofWeek = '5' Then 'Thursday'
	   When DayofWeek = '6' Then 'Friday'
	   When DayofWeek = '7' Then 'Saturday'
	   END
From #DailyActivitySleep
Group By DayofWeek
Order By 2 DESC  


