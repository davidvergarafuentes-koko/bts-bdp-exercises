-- exercise 2.1
SELECT e.first_name, e.last_name, e.email, d.name AS department_name
FROM employee e
JOIN department d ON e.department_id = d.id
ORDER BY e.last_name, e.first_name;

-- exercise 2.2
SELECT d.name AS department_name,
       COUNT(e.id) AS employee_count
FROM department d
LEFT JOIN employee e ON e.department_id = d.id
GROUP BY d.id, d.name
ORDER BY employee_count DESC, department_name;

-- exercise 2.3
SELECT d.name AS department_name, d.location
FROM department d
LEFT JOIN employee e ON e.department_id = d.id
WHERE e.id IS NULL
ORDER BY d.name;

-- exercise 2.4
SELECT d.name AS department_name,
       ROUND(AVG(e.salary), 2) AS avg_salary,
       COUNT(e.id) AS employee_count
FROM department d
JOIN employee e ON e.department_id = d.id
GROUP BY d.id, d.name
ORDER BY avg_salary DESC;

-- exercise 2.5
SELECT e.first_name, e.last_name,
       COUNT(DISTINCT ep.project_id) AS project_count
FROM employee e
JOIN employee_project ep ON ep.employee_id = e.id
GROUP BY e.id, e.first_name, e.last_name
HAVING COUNT(DISTINCT ep.project_id) > 2
ORDER BY project_count DESC, e.last_name, e.first_name;

--exercise 2.6
SELECT e.first_name, e.last_name, e.salary, d.name AS department_name
FROM employee e
LEFT JOIN department d ON e.department_id = d.id
ORDER BY e.salary DESC
LIMIT 3;

--exercise 2.7
SELECT e.first_name, e.last_name,
       sh.change_date, sh.old_salary, sh.new_salary, sh.reason
FROM salary_history sh
JOIN employee e ON e.id = sh.employee_id
WHERE e.first_name = 'Anna' AND e.last_name = 'Garcia'
ORDER BY date(sh.change_date) ASC, sh.id ASC;