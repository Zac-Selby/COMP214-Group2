-- File: validate_salary_sp.sql
-- Author: Zac
-- Purpose: Procedure to validate employee salary within job min and max range

CREATE OR REPLACE PROCEDURE validate_salary (
    p_job_id HR_EMPLOYEES.JOB_ID%TYPE,
    p_salary HR_EMPLOYEES.SALARY%TYPE
)
IS
    v_min_salary HR_JOBS.MIN_SALARY%TYPE;
    v_max_salary HR_JOBS.MAX_SALARY%TYPE;
BEGIN
    SELECT MIN_SALARY, MAX_SALARY
    INTO v_min_salary, v_max_salary
    FROM HR_JOBS
    WHERE JOB_ID = p_job_id;

    IF p_salary < v_min_salary OR p_salary > v_max_salary THEN
        RAISE_APPLICATION_ERROR(-20001, 'Salary is out of range for this JOB_ID.');
    END IF;
END;
/

-- Test Example:
-- BEGIN
--   validate_salary('AD_VP', 5000);
-- END;
