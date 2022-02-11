select tmp_tbl.student
from
    (
        select *
        from (
            select *, row_number() over (partition by student, task_id order by grade_datetime desc) as r_number
            from bcnf_grades
        ) as tmp_tbl
        where r_number = 1
    ) as tmp_tbl
    join bcnf_tasks
    on tmp_tbl.task_id = bcnf_tasks.task_id
    join bcnf_assignment
    on bcnf_tasks.assignment_id = bcnf_assignment.assignment_id
where tmp_tbl.grade_datetime >= date_add(now(), interval -30 day)
group by bcnf_assignment.group_id, tmp_tbl.student
order by sum(tmp_tbl.grade) / count(*) desc
limit 5;

select bcnf_users.login
from
     bcnf_users
     left join bcnf_grades
     on bcnf_users.login = bcnf_grades.grader and  str_to_date(
         concat(year(date_add(now(), interval -1     month)),'-',month(date_add(now(), interval -1 month)),'-',1), '%Y-%m-%d'
        ) <= bcnf_grades.grade_datetime and bcnf_grades.grade_datetime < date_add(str_to_date(
         concat(year(date_add(now(), interval -1 month)),'-',month(date_add(now(), interval -1 month)),'-',1), '%Y-%m-%d'
        ), interval 1 month)
group by bcnf_users.login
order by sum(case when bcnf_grades.grader is null then 0 else 1 end) desc
limit 5;

select first_tbl.group_id, numerator / n_tasks / n_students as fraction
from (
    select bcnf_groups.group_id, count(*) as numerator
    from
    bcnf_groups
    left join bcnf_assignment
    on bcnf_groups.group_id = bcnf_assignment.group_id
    left join bcnf_tasks
    on bcnf_assignment.assignment_id = bcnf_tasks.assignment_id
    join bcnf_solutions
    on bcnf_tasks.task_id = bcnf_solutions.task_id
    where bcnf_assignment.deadline < now()
    group by bcnf_groups.group_id
) as first_tbl
    join (
        select bcnf_user_group.group_id, count(*) as n_students
        from bcnf_user_group
        where not bcnf_user_group.tutor
        group by bcnf_user_group.group_id
    ) as second_tbl
    on first_tbl.group_id = second_tbl.group_id
    join (
        select bcnf_assignment.group_id, count(*) as n_tasks
        from bcnf_assignment
        join bcnf_tasks
        on bcnf_assignment.assignment_id = bcnf_tasks.assignment_id
        group by bcnf_assignment.group_id
    ) as third_tbl
    on second_tbl.group_id = third_tbl.group_id;

select group_id, count(*) as n_students
from bcnf_user_group
where not tutor
group by group_id
order by n_students desc;


