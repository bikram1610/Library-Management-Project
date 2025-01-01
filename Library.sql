---------------------------------------------------------------
-- TABLE CREATION
---------------------------------------------------------------

-- Book table creation
drop table if exists book;
create table book
(
isbn varchar(40) primary key,
book_title varchar(200),
category varchar(40),
rental_price decimal(10,2),
status varchar(40),
author varchar(40),
publisher varchar(40)
)

-- Branch table creation
drop table if exists branch;
create table branch
(
branch_id varchar(10) primary key,
manager_id varchar(10),
branch_address varchar(50),
contact_no varchar(20)
)

-- Employee table creation
drop table if exists employee;
create table employee
(
emp_id varchar(10) primary key,
emp_name varchar(30),
position varchar(30),
salary decimal(10,2),
branch_id varchar(10)
)

-- Issue status table creation
drop table if exists issue_status;
create table issue_status
(
issued_id varchar(10) primary key,
issued_member_id varchar(10),
issued_book_name varchar(200),
issued_date date,
issued_book_isbn varchar(20),
issued_emp_id varchar(20)
)

-- Member table creation
drop table if exists member;
create table member
(
member_id varchar(20) primary key,
member_name varchar(40),
member_address varchar(40),
reg_date date
)

-- Return status table creation
drop table if exists return_status;
create table return_status
(
return_id varchar(10) primary key,
issued_id varchar(10),
return_book_name varchar(30),
return_date date,
return_book_isbn varchar(40)
)
----------------------------------------------------------------------------------
-- Adding constraints
----------------------------------------------------------------------------------
alter table issue_status
add constraint fk_book
foreign key(issued_book_isbn) references book(isbn);

alter table issue_status
add constraint fk_member
foreign key(issued_member_id) references member(member_id);

alter table issue_status
add constraint fk_employee
foreign key(issued_emp_id) references employee(emp_id);

alter table employee
add constraint fk_branch
foreign key(branch_id) references branch(branch_id);

alter table return_status
add constraint fk_issue_status
foreign key(issued_id) references issue_status(issued_id);

------------------------------------------------------------------------------------
-- Show all the tables
------------------------------------------------------------------------------------
select * from book;
select * from branch;
select * from employee;
select * from issue_status;
select * from member;
select * from return_status;
-------------------------------------------------------------------------------------
-- Basic and intermediate SQL operations
-------------------------------------------------------------------------------------

-- 1) Create a New Book Record:
-- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.'

insert into book
values('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')

-- 2) Update an Existing Member's Address

update member 
set member_address = '130 Apple St'
where member_id = 'C109'

-- 3) Delete a Record from the Issued Status Table:
-- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.

delete from issue_status 
where issued_id = 'IS121'

-- 4) Update existing return_status table
update return_status 
set return_date = null
where return_id in ('RS107', 'RS115')

-- 5) Retrieve All Books Issued by a Specific Employee:
-- Objective: Select all books issued by the employee with emp_id = 'E101'

select 
issued_book_name as book, 
issued_emp_id
from issue_status
where issued_emp_id = 'E101'
order by book

-- 6) List members who have issued more than one book

select 
e.emp_name, 
count(*) as book_count
from
employee as e
join
issue_status i
on e.emp_id = i.issued_emp_id
group by 1
having count(*) > 1
order by 1

-- 7) Retrieve All Books in a Specific Category

select book_title
from book
where category = 'History'
order by 1

-- 8) Find Total Rental Income by Category

select 
category, 
sum(rental_price) as Income
from book
group by 1
order by 1

-- 9) List Members Who Registered in the Last 500 Days

select member_name 
from member
where 
reg_date >= current_date - interval '500 days'

-- 10) Create a Table of Books with Rental Price Above a Certain Threshold

create table book_more_than_five_rent
as
(
	select 
	book_title as book, 
	rental_price as rent
	from book
	where rental_price > 5
)

select * from book_more_than_five_rent

-- 11) Retrieve the List of Books Not Yet Returned

select 
ist.issued_book_name as book
from 
issue_status as ist
left join 
return_status as rst
on ist.issued_id = rst.issued_id
where rst.return_book_isbn = 'Null'

-- 12) List Employees with Their Branch Manager's Name and their branch details

select
e.emp_name as name,
e2.emp_name as manager,
b.branch_id,
branch_address
contact_no
from
employee as e
join
branch as b
on e.branch_id = b.branch_id
join
employee as e2
on e2.emp_id = b.manager_id

---------------------------------------------------------------------------------------------
-- ADVANCED SQL OPERATIONS
---------------------------------------------------------------------------------------------

-- 1) Create Summary Tables:
-- Use CTAS to generate new tables based on query results - each book and total book_issued_count

create table report
as
(
	select 
	b.isbn as book_id, 
	b.book_title as book_name, 
	count(issued_id) as book_count
	from
	issue_status as ist
	join
	book as b
	on ist.issued_book_isbn = b.isbn
	group by 1
	order by 2
)

select * from report
-- 2) Identify Members with Overdue Books
-- Write a query to identify members who have overdue books (assume a 30-day return period)
-- Display the member's_id, member's name, book title, issue date, and days overdue

select 
member_id, 
member_name, 
issued_book_name as book, 
issued_date,
return_date,
current_date - (issued_date + interval '30 days') as over_due
from
issue_status as ist
join 
member as m
on ist.issued_member_id = m.member_id
join
return_status as rst
on ist.issued_id = rst.issued_id
where return_date is NULL
order by 6 desc

-- 3) Branch Performance Report
-- Create a query that generates a performance report for each branch, showing the number of books issued,
-- the number of books returned, and the total revenue generated from book rentals

create table revenue_report
as
(
	select 
	branch_id,
	count(issued_book_isbn) as no_of_book_issued,
	count(return_date) as no_of_book_returned,
	sum(rental_price) as revenue_genereted
	from 
	employee as e
	join
	issue_status as ist
	on e.emp_id = ist.issued_emp_id
	left join 
	return_status as rst
	on 
	ist.issued_id = rst.issued_id
	join
	book as b
	on ist.issued_book_isbn = b.isbn
	group by 1
	order by 1
)

select * from revenue_report

-- 4) Create a Table of Active Members Use the CREATE TABLE AS (CTAS) statement to
-- create a new table active_members containing members who have issued at least two books

create table active_members
as
(
	select
	issued_member_id as member_id,
	member_name, 
	count(issued_id) as book_issued
	from 
	issue_status as ist
	join 
	member as m
	on ist.issued_member_id = m.member_id
	group by 1, 2
	having count(issued_id) > 1
	order by 1
)

select * from active_members

-- 5) Find Employees with the Most Book Issues Processed
-- Write a query to find the top 3 employees who have processed the most book issues. Same number will be considered
-- Display the employee name, number of books processed, and their branch details

with top_employee
as
(
	select 
	e.emp_name as name,
	count(issued_id) as book_issued,
	e.branch_id,
	branch_address,
	contact_no,
	dense_rank() over(order by count(issued_id) desc) as rank
	from 
	employee as e
	join
	issue_status as ist
	on e.emp_id = ist.issued_emp_id
	join
	branch as b
	on e.branch_id = b.branch_id
	group by 1,3,4,5
	order by 2 desc
)
select 
name,
book_issued,
branch_id,
branch_address,
contact_no
from
top_employee
where rank <= 3