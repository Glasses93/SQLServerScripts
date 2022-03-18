select TOP 0

 Account_ID, DriveID, Trip_Mode, User_label, email, Overall_Points
, accel_Points

, Braking_Points = CONVERT(numeric(18, 6), NULL) -- that's the datatype of the source.

,Cornering_Points, Speeding_Points, Phone_Motion_Points
, Star_Rating_Overall, Star_Rating_Accel, Star_Rating_Braking
, Star_Rating_Cornering, Star_Rating_Speeding, Star_Rating_Phone_Motion
, Nighttime_Driving_Minutes, Classification_Confidence
, InsertedDate 

INTO #YourNewTable
from staging.dbo.CMTTripSummaryCombined

