 -- File: hr_plsql.sql
 -- Author: Rumsha Ahmed
 -- Purpose: Backend database objects for module

DECLARE
  v_cnt NUMBER;
  v_start NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_cnt FROM USER_SEQUENCES WHERE SEQUENCE_NAME = 'EMPLOYEES_SEQ';
  IF v_cnt = 0 THEN
    SELECT NVL(MAX(EMPLOYEE_ID), 0) + 1 INTO v_start FROM HR_EMPLOYEES;
    EXECUTE IMMEDIATE 'CREATE SEQUENCE EMPLOYEES_SEQ START WITH ' || v_start || ' INCREMENT BY 1';
  END IF;
END;
/


/* ---------- 2) Salary validation procedure ---------- */
CREATE OR REPLACE PROCEDURE VALIDATE_SALARY_SP(
  p_job_id IN HR_JOBS.JOB_ID%TYPE,
  p_salary IN HR_EMPLOYEES.SALARY%TYPE
) AS
  v_min HR_JOBS.MIN_SALARY%TYPE;
  v_max HR_JOBS.MAX_SALARY%TYPE;
BEGIN
  SELECT MIN_SALARY, MAX_SALARY
    INTO v_min, v_max
    FROM HR_JOBS
   WHERE JOB_ID = p_job_id;

  IF p_salary < v_min OR p_salary > v_max THEN
    RAISE_APPLICATION_ERROR(-20010,
      'Salary '||p_salary||' is outside the allowed range ['||v_min||','||v_max||'] for job '||p_job_id);
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20011, 'Job '||p_job_id||' does not exist.');
END VALIDATE_SALARY_SP;
/


/* ---------- 1) Employee hire procedure with exception handling ---------- */
CREATE OR REPLACE PROCEDURE EMPLOYEE_HIRE_SP(
  p_first_name     IN HR_EMPLOYEES.FIRST_NAME%TYPE,
  p_last_name      IN HR_EMPLOYEES.LAST_NAME%TYPE,
  p_email          IN HR_EMPLOYEES.EMAIL%TYPE,
  p_salary         IN HR_EMPLOYEES.SALARY%TYPE,
  p_hire_date      IN HR_EMPLOYEES.HIRE_DATE%TYPE DEFAULT SYSDATE,
  p_phone          IN HR_EMPLOYEES.PHONE_NUMBER%TYPE,
  p_job_id         IN HR_EMPLOYEES.JOB_ID%TYPE,
  p_manager_id     IN HR_EMPLOYEES.MANAGER_ID%TYPE,
  p_department_id  IN HR_EMPLOYEES.DEPARTMENT_ID%TYPE
) AS
  -- Foreign key violation 
  e_fk   EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_fk, -2291);
  -- Check constraint, value out of range 
  e_check  EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_check, -2290);
BEGIN
  -- Validate salary against job range BEFORE insert 
  VALIDATE_SALARY_SP(p_job_id, p_salary);

  INSERT INTO HR_EMPLOYEES
    (EMPLOYEE_ID, FIRST_NAME, LAST_NAME, EMAIL,
     PHONE_NUMBER, HIRE_DATE, JOB_ID, SALARY, MANAGER_ID, DEPARTMENT_ID)
  VALUES
    (EMPLOYEES_SEQ.NEXTVAL, p_first_name, p_last_name, UPPER(p_email),
     p_phone, p_hire_date, p_job_id, p_salary, p_manager_id, p_department_id);

  COMMIT;
EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN
    RAISE_APPLICATION_ERROR(-20001, 'Email already exists. Choose a unique email.');
  WHEN e_fk THEN
    RAISE_APPLICATION_ERROR(-20002, 'Invalid manager_id, department_id, or job_id.');
  WHEN e_check THEN
    RAISE_APPLICATION_ERROR(-20003, 'A check constraint failed (e.g., negative salary).');
  WHEN VALUE_ERROR THEN
    RAISE_APPLICATION_ERROR(-20004, 'Value error: bad data type or format.');
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20005, 'Hire failed: ' || SQLERRM);
END EMPLOYEE_HIRE_SP;
/




/* ---------- 3) Trigger on HR_EMPLOYEES for salary enforcement ---------- */
CREATE OR REPLACE TRIGGER TRG_EMP_SALARY_RANGE
BEFORE INSERT OR UPDATE OF SALARY, JOB_ID ON HR_EMPLOYEES
FOR EACH ROW
BEGIN
  -- Only checks if both job and salary are there 
  IF :NEW.JOB_ID IS NOT NULL AND :NEW.SALARY IS NOT NULL THEN
    VALIDATE_SALARY_SP(:NEW.JOB_ID, :NEW.SALARY);
  END IF;
END;
/
