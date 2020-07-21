/****** Script for SelectTopNRows command from SSMS  ******/
use CollegeDB

-- Excercise 2

-- Part a

SELECT DISTINCT departments.DepartmentName AS Department_Name
	,courses.DepartmentID AS Department_ID
	,count(classroom.StudentId) OVER (PARTITION BY courses.DepartmentID) AS Students_Number
FROM dbo.Courses AS courses
INNER JOIN dbo.Classrooms AS classroom ON (courses.CourseId = classroom.CourseId)
INNER JOIN dbo.Departments AS departments ON (courses.DepartmentID = departments.DepartmentId)
ORDER BY courses.DepartmentID

-- Part b

SELECT DISTINCT teachers.TeacherId AS Teacher_Id
	,teachers.FirstName AS Teacher_First_Name
	,teachers.LastName AS Teacher_Last_Name
	,courses.CourseName AS Course_Name
	,courses.DepartmentID AS Department_ID
	,count(classroom.StudentId) OVER (PARTITION BY courses.CourseId) AS Students_number_per_course
	,count(classroom.StudentId) OVER (PARTITION BY teachers.TeacherId) AS Total_students_number
FROM dbo.Courses AS courses
INNER JOIN dbo.Classrooms AS classroom ON (courses.CourseId = classroom.CourseId)
INNER JOIN dbo.Teachers AS teachers ON (courses.TeacherId = teachers.TeacherId)
WHERE courses.DepartmentID IN ('1')

-- Part c

SELECT DISTINCT courses.CourseName AS Course_Name
	,count(classrooms.StudentId) OVER (PARTITION BY courses.CourseName) AS Students_Number
	,CASE 
		WHEN count(classrooms.StudentId) OVER (PARTITION BY courses.CourseName) < 22
			THEN 'Small class'
		WHEN count(classrooms.StudentId) OVER (PARTITION BY courses.CourseName) >= 22
			THEN 'Big class'
		END AS Class_Size
FROM dbo.Courses AS courses
INNER JOIN dbo.Classrooms AS classrooms ON (courses.CourseId = classrooms.CourseId)

-- Part d

SELECT DISTINCT students.Gender AS Stundent_Gender
	,count(students.StudentId) OVER (PARTITION BY students.Gender) AS Students_number
FROM dbo.Students AS students

-- Part e

-- This query will create a table, which will display for each course -> 2 rows: Male gender students number and female gender students number 
SELECT DISTINCT courses.CourseName AS Course_Name
	,count(classrooms.StudentId) OVER (
		PARTITION BY courses.CourseName
		,students.Gender
		) AS Students_Number
	,students.Gender AS Gender
INTO #students_number_for_each_gender
FROM dbo.Courses AS courses
INNER JOIN dbo.Classrooms AS classrooms ON (courses.CourseId = classrooms.CourseId)
INNER JOIN dbo.Students AS students ON (classrooms.StudentId = students.StudentId)

-- This query will create a table, which will present the Male gender students number and female gender students number in the sanme row, so it will be possible to perform calculations between them
SELECT DISTINCT Course_Name
	,FIRST_VALUE(Students_Number) OVER (
		PARTITION BY Course_Name ORDER BY Course_Name
		) AS Males_Number
	,LAST_VALUE(Students_Number) OVER (
		PARTITION BY Course_Name ORDER BY Course_Name
		) AS Females_Number
INTO #both_genders_numbers_in_the_same_row
FROM #students_number_for_each_gender

-- As final step, we will query only the courses in which the male porpotion is larger than 0.7 (which in this case is 0 as such courses not exist)
SELECT Course_Name
	,Males_Number
	,Females_Number
	,cast(cast(Males_Number AS FLOAT) / (Males_Number + Females_Number) * 100 AS DECIMAL(10, 1)) AS Male_porpotion_in_course
FROM #both_genders_numbers_in_the_same_row
WHERE cast(Males_Number AS FLOAT) / (Males_Number + Females_Number) > 0.7

-- Part f and g

-- Table includes all students number by department ID 
SELECT distinct courses.DepartmentID AS Department_ID
	,count(calssrooms.StudentId) over (partition by courses.DepartmentID) AS Students_Number
INTO #students_number_by_department
FROM dbo.Courses AS courses
INNER JOIN dbo.Classrooms AS calssrooms ON (courses.CourseId = calssrooms.CourseId)
ORDER BY courses.DepartmentID


-- Table includes all students number with grade above 80 by department ID (Part f)
SELECT distinct courses.DepartmentID AS Department_ID
	,count(calssrooms.StudentId) over (partition by courses.DepartmentID) AS Students_Number
INTO #students_number_by_department_grade_above_80
FROM dbo.Courses AS courses
INNER JOIN dbo.Classrooms AS calssrooms ON (courses.CourseId = calssrooms.CourseId)
WHERE calssrooms.degree > 80
ORDER BY courses.DepartmentID

-- Table includes all students number with grade below 60 by department ID (Part g)
SELECT distinct courses.DepartmentID AS Department_ID
	,count(calssrooms.StudentId) over (partition by  courses.DepartmentID) AS Students_Number
INTO #students_number_by_department_grade_below_60
FROM dbo.Courses AS courses
INNER JOIN dbo.Classrooms AS calssrooms ON (courses.CourseId = calssrooms.CourseId)
WHERE calssrooms.degree < 60
ORDER BY courses.DepartmentID

-- Table combines both tables above, displaying the students number with grade above 80 and the percentages calculation (Part f)
SELECT students_by_dep.Department_ID
	,students_by_dep_above_80.Students_Number AS Students_number_with_grade_above_80
	,cast(cast(students_by_dep_above_80.Students_Number AS FLOAT) / students_by_dep.Students_Number * 100 AS DECIMAL(10, 1)) AS Students_percentage_with_grade_above_80
FROM #students_number_by_department AS students_by_dep
INNER JOIN #students_number_by_department_grade_above_80 AS students_by_dep_above_80 ON (students_by_dep.Department_ID = students_by_dep_above_80.Department_ID)
ORDER BY students_by_dep.Department_ID

-- Table combines both tables above, displaying the students number with grade below 60 and the percentages calculation (Part g)
SELECT students_by_dep.Department_ID
	,students_by_dep_below_60.Students_Number AS Students_number_with_grade_below_60
	,cast(cast(students_by_dep_below_60.Students_Number AS FLOAT) / students_by_dep.Students_Number * 100 AS DECIMAL(10, 1)) AS Students_percentage_with_grade_below_60
FROM #students_number_by_department AS students_by_dep
INNER JOIN #students_number_by_department_grade_below_60 AS students_by_dep_below_60 ON (students_by_dep.Department_ID = students_by_dep_below_60.Department_ID)
ORDER BY students_by_dep.Department_ID

-- Part h

SELECT teachers.TeacherId AS Teacher_ID
	,teachers.FirstName AS First_name
	,teachers.LastName AS Last_name
	,cast(avg(classrooms.degree) AS DECIMAL(10, 1)) AS Average_students_grade
FROM dbo.Courses AS courses
INNER JOIN dbo.Teachers AS teachers ON (courses.TeacherId = teachers.TeacherId)
INNER JOIN dbo.Classrooms AS classrooms ON (courses.CourseId = classrooms.CourseId)
GROUP BY teachers.TeacherId
	,teachers.LastName
	,teachers.FirstName
ORDER BY avg(classrooms.degree) DESC


-- Excercise 3

-- Part a

CREATE VIEW v_courses_departments_teacher_studnets_number
AS
SELECT distinct courses.CourseName AS Course_name
	,courses.DepartmentID AS Department_ID
	,teachers.FirstName AS Teacher_first_name
	,teachers.LastName AS Teacher_last_name
	,count(classrooms.StudentId) over (partition by courses.CourseName) as Students_number
FROM dbo.Courses AS courses
INNER JOIN dbo.Teachers AS teachers ON (courses.TeacherId = teachers.TeacherId)
INNER JOIN dbo.Classrooms AS classrooms ON (courses.CourseId = classrooms.CourseId)

-- Query view
SELECT *
FROM v_courses_departments_teacher_studnets_number
ORDER BY Department_ID
	,Teacher_last_name

-- Part b

CREATE VIEW v_courses_departments_teacher_studnets_number
AS
SELECT DISTINCT students.StudentId AS Student_ID
	,students.FirstName AS Students_first_name
	,students.LastName AS Students_last_name
	,courses.DepartmentID AS Department_ID
	,cast(AVG(classrooms.degree) OVER (
			PARTITION BY students.StudentId
			,courses.DepartmentID
			) AS DECIMAL(10, 1)) AS Average_grade_by_department_ID
	,cast(Avg(classrooms.degree) OVER (PARTITION BY students.StudentId) AS DECIMAL(10, 1)) AS Total_grades_average
FROM dbo.Students AS students
INNER JOIN dbo.Classrooms AS classrooms ON (students.StudentId = classrooms.StudentId)
INNER JOIN dbo.Courses AS courses ON (classrooms.CourseId = courses.CourseId)

-- Query view
SELECT *
FROM v_courses_departments_teacher_studnets_number
ORDER BY Student_ID














