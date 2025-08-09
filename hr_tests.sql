 -- File: hr_plsql.sql
 -- Author: Rumsha Ahmed
 -- Purpose: Backend database objects for module

SET SERVEROUTPUT ON



DECLARE
  PROCEDURE p(msg VARCHAR2) IS 
  BEGIN 
    DBMS_OUTPUT.PUT_LINE(msg); 
  END;
BEGIN
  p('=== Smoke check: salary range for SA_REP with 8,000 ===');
  BEGIN
    VALIDATE_SALARY_SP('SA_REP', 8000);
    p('OK: 8000 is within SA_REP range.');
  EXCEPTION 
    WHEN OTHERS THEN p('FAILED: '||SQLERRM); 
  END;

  p('=== 1) VALID HIRE – within range ===');
  BEGIN
    EMPLOYEE_HIRE_SP(
      p_first_name    => 'Elenor',
      p_last_name     => 'Valid',
      p_email         => 'ELENOR.VALID@example.com',
      p_salary        => 9000,          
      p_hire_date     => SYSDATE,
      p_phone         => '650.555.0101',
      p_job_id        => 'SA_REP',
      p_manager_id    => 145,
      p_department_id => 30
    );
    p('Hired Elenor Valid.');
  EXCEPTION 
    WHEN OTHERS THEN p('Hire failed: '||SQLERRM); 
  END;

  p('=== 2) INVALID HIRE – salary too LOW for SA_REP (expected error) ===');
  BEGIN
    EMPLOYEE_HIRE_SP(
      p_first_name    => 'Elenor',
      p_last_name     => 'Beh',
      p_email         => 'ELENOR.BEH@example.com',
      p_salary        => 1000,           -- too low 
      p_hire_date     => SYSDATE,
      p_phone         => '650.555.0102',
      p_job_id        => 'SA_REP',
      p_manager_id    => 145,
      p_department_id => 30
    );
    p('UNEXPECTED: hire succeeded but should have failed.');
  EXCEPTION 
    WHEN OTHERS THEN p('Expected failure: '||SQLERRM); 
  END;

  p('=== 3) UPDATE salary of employee 115 to 2000 (expected error) ===');
  BEGIN
    UPDATE HR_EMPLOYEES SET SALARY = 2000 WHERE EMPLOYEE_ID = 115;
    COMMIT;
    p('UNEXPECTED: update committed.');
  EXCEPTION 
    WHEN OTHERS THEN p('Expected failure on trigger: '||SQLERRM); 
    ROLLBACK; 
  END;

  p('=== 4) UPDATE employee 115 job to HR_REP keeping salary (may error if out of range) ===');
  BEGIN
    UPDATE HR_EMPLOYEES SET JOB_ID = 'HR_REP' WHERE EMPLOYEE_ID = 115;
    COMMIT;
    p('If salary not in HR_REP range, trigger should have failed above.');
  EXCEPTION 
    WHEN OTHERS THEN p('Expected/possible failure: '||SQLERRM); 
    ROLLBACK; 
  END;

  p('=== 5) COMMIT vs ROLLBACK demo ===');
  DECLARE 
    v_cnt_before NUMBER; 
    v_cnt_after NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_cnt_before FROM HR_EMPLOYEES;
    INSERT INTO HR_EMPLOYEES(EMPLOYEE_ID, FIRST_NAME, LAST_NAME, EMAIL, PHONE_NUMBER, HIRE_DATE, JOB_ID, SALARY, MANAGER_ID, DEPARTMENT_ID)
    VALUES (EMPLOYEES_SEQ.NEXTVAL, 'Temp', 'Rollback', 'TEMP.ROLLBACK@example.com', '650.555.0110', SYSDATE, 'SA_REP', 9000, 145, 30);
    ROLLBACK; -- undo it
    SELECT COUNT(*) INTO v_cnt_after FROM HR_EMPLOYEES;
    p('Rows before: '||v_cnt_before||'  after rollback: '||v_cnt_after);
  END;
END;
/

-- Show last few hires
COL FIRST_NAME FORMAT A12
COL LAST_NAME  FORMAT A12
COL EMAIL      FORMAT A25

SELECT EMPLOYEE_ID, FIRST_NAME, LAST_NAME, EMAIL, JOB_ID, SALARY, HIRE_DATE
  FROM HR_EMPLOYEES
 WHERE EMAIL LIKE 'ELENOR%'
 ORDER BY EMPLOYEE_ID DESC;