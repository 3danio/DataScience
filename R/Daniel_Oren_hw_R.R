library(dplyr)
library(ggplot2)
library(DBI)
library(tidyr)



conn <- dbConnect(odbc::odbc(),
                 Driver = "SQL Server",
                 Server = "localhost\\SQLEXPRESS",
                 Database = "CollegeDB",
                 Trusted_Connection = "True")


classrooms<- dbGetQuery(conn, 'SELECT * FROM "CollegeDB"."dbo"."Classrooms"')
courses<- dbGetQuery(conn, 'SELECT * FROM "CollegeDB"."dbo"."Courses"')
departments<- dbGetQuery(conn, 'SELECT * FROM "CollegeDB"."dbo"."Departments"')
students<- dbGetQuery(conn, 'SELECT * FROM "CollegeDB"."dbo"."Students"')
teachers<- dbGetQuery(conn, 'SELECT * FROM "CollegeDB"."dbo"."Teachers"')

# ---- Joined tables
courses_departments <- inner_join(courses, departments, by=c("DepartmentID"="DepartmentId"))
courses_departments_classrooms <- inner_join(courses_departments, classrooms, by="CourseId")

courses_classrooms <- inner_join(courses, classrooms, by="CourseId")
students_courses_classrooms <- inner_join(students, courses_classrooms, by="StudentId")

teachers_courses_classrooms <- inner_join(teachers, courses_classrooms, by='TeacherId')

teachers_courses_departments_classrooms <- inner_join(teachers, courses_departments_classrooms, by='TeacherId')

classrooms_students_L <- left_join(classrooms, students, by='StudentId')
classrooms_students_courses_L <- left_join(classrooms_students_L, courses, by='CourseId')

classrooms_students_courses_departments_L <- left_join(classrooms_students_courses_L, departments, by=c('DepartmentID' = 'DepartmentId'))

# ---- 2a. Number of students by Department

departments_students_no = courses_departments_classrooms %>% 
  group_by(DepartmentName) %>% 
  summarise(students=length(unique(StudentId)))

departments_students_no

# ---- 2b. How many students has the English teacher by course and in total?

english_courses_departments_classrooms = courses_departments_classrooms %>% 
  filter(courses_departments_classrooms$DepartmentID == 1)

english_courses_students_no = english_courses_departments_classrooms %>% 
  group_by(CourseName) %>% 
  summarise(students = n_distinct(StudentId))

v_total_english_students = english_courses_departments_classrooms %>%
  summarise(students=length(unique(StudentId)))

total_row <- data.frame(CourseName = "Total", students = v_total_english_students) 

english_courses_students_no <- rbind(english_courses_students_no, total_row)

english_courses_students_no

# ---- 2c. How many small (<22) and bigger (>=22) Classrooms has the Science Department?

science_courses_departments_classrooms = courses_departments_classrooms %>%
  filter(courses_departments_classrooms$DepartmentID == 2)

science_courses_departments_classrooms

science_courses_students_no = science_courses_departments_classrooms %>%
  group_by(CourseName) %>%
  summarise(students=length(unique(StudentId)))

science_courses_students_no

science_courses_students_no$classroom_size <- NULL
science_courses_students_no$classroom_size[science_courses_students_no$students < 22] <- 'Small classrooms'
science_courses_students_no$classroom_size[science_courses_students_no$students >= 22] <- 'Big classrooms'

classrooms_no_per_size = science_courses_students_no %>%
  group_by(classroom_size) %>%
  summarise(num_classrooms=length(students))

classrooms_no_per_size

# ---- 2d. How many students are by Gender?

students_by_gender = students %>%
  group_by(Gender) %>%
  summarise(num_students = length(unique(StudentId)))

students_by_gender

# ---- 2e. In which courses the percentage of males / females are higher than 70% ?

students_courses_classrooms$Male <- 0
students_courses_classrooms$Female <- 0

students_courses_classrooms

students_courses_classrooms$Male[students_courses_classrooms$Gender == 'M'] <- 1
students_courses_classrooms$Female[students_courses_classrooms$Gender == 'F'] <- 1

courses_gender_no = students_courses_classrooms %>%
  group_by(CourseName) %>%
  summarise(Male = sum(Male), Female = sum(Female))

courses_gender_no$Ratio <- courses_gender_no$Female / (courses_gender_no$Male + courses_gender_no$Female) * 100

courses_gender_no %>% filter(courses_gender_no$Ratio > 70)

# ---- 2f. getting the number of students with at least one degree with more than 80 per department

courses_departments_classrooms_f <- data.frame(courses_departments_classrooms)

courses_departments_classrooms_f$students_80 <- NULL

courses_departments_classrooms_f$students_80[courses_departments_classrooms_f$degree > 80] = courses_departments_classrooms_f$StudentId[courses_departments_classrooms_f$degree > 80]

departments_grades = courses_departments_classrooms_f %>%
  group_by(DepartmentName) %>%
  summarise(students_80 = length(unique(students_80)), total_students = length(unique(StudentId)))

departments_grades$students_80 <- departments_grades$students_80 - 1 # Reducing the NULL counting (unique counting includes also the NULL value... so we reduce it)

departments_grades$students_80_pct = departments_grades$students_80 / departments_grades$total_students * 100

departments_grades

# ---- 2g. How many students (n and %) have a degree lower than 60 by Department?

courses_departments_classrooms_g <- data.frame(courses_departments_classrooms)

courses_departments_classrooms_g$students_60 <- NULL

courses_departments_classrooms_g$students_60[courses_departments_classrooms_g$degree < 60] = courses_departments_classrooms_g$StudentId[courses_departments_classrooms_f$degree < 60]

departments_grades = courses_departments_classrooms_g %>%
  group_by(DepartmentName) %>%
  summarise(students_60 = length(unique(students_60)), total_students = length(unique(StudentId)))

departments_grades$students_60 <- departments_grades$students_60 - 1 # Reducing the NULL counting (unique counting includes also the NULL value... so we reduce it)

departments_grades$students_60_pct = departments_grades$students_60 / departments_grades$total_students * 100

departments_grades

# ---- 2h Rate in descending order the teachers by their student's mean degree.

teachers_courses_classrooms_h <- data.frame(teachers_courses_classrooms)

teachers_courses_classrooms_h$Teacher <- paste(teachers_courses_classrooms_h$FirstName, teachers_courses_classrooms_h$LastName)

teachers_degree <- teachers_courses_classrooms_h %>% 
  group_by(Teacher) %>%
  summarise(degree = mean(degree))
  
teachers_degree[order(-teachers_degree$degree), ]
  
# ---- 3a. Create a view that shows the courses, departments, teachers and number of students on each

teachers_courses_departments_classrooms_3a <- data.frame(teachers_courses_departments_classrooms)


result = teachers_courses_departments_classrooms_3a %>%
  group_by(CourseId, CourseName, DepartmentName, FirstName, LastName) %>%
  summarise(students_number = length(StudentId))

result

# ---- 3b. Create a view that shows each student, the number of courses taken, 
# ---- their mean degree by department and the total degree mean.

classrooms_students_courses_departments_L_3b <- data.frame(classrooms_students_courses_departments_L)

general_degree_per_student <- classrooms_students_courses_departments_L_3b %>%
  group_by(StudentId) %>%
  summarise(mean_degree = mean(degree))

courses_number_per_student <- classrooms_students_courses_departments_L_3b %>%
  group_by(StudentId) %>%
  summarise(courses = length(CourseId))

degree_by_relevant_departments_per_student <- classrooms_students_courses_departments_L_3b %>% 
  group_by(StudentId, FirstName,  LastName, DepartmentName) %>%
  summarise(degree = mean(degree))

degree_by_all_departments_per_student <- degree_by_relevant_departments_per_student %>%
  pivot_wider(names_from = DepartmentName , values_from = degree)

degree_by_all_departments_per_student$mean_degree <- c(general_degree_per_student$mean_degree)
degree_by_all_departments_per_student$courses <- c(courses_number_per_student$courses)

degree_by_all_departments_per_student
