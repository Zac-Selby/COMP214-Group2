 -- File: get_job_function.sql
-- Author: Zac
-- Purpose: Function to return JOB_TITLE for a given JOB_ID

CREATE OR REPLACE FUNCTION get_job (p_job_id VARCHAR2)
RETURN VARCHAR2
IS
    v_job_title HR_JOBS.JOB_TITLE%TYPE;
BEGIN
    SELECT JOB_TITLE
    INTO v_job_title
    FROM HR_JOBS
    WHERE JOB_ID = p_job_id;

    RETURN v_job_title;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'Invalid JOB_ID';
    WHEN OTHERS THEN
        RETURN 'Error: ' || SQLERRM;
END;
/

-- Test Example:
-- SELECT get_job('AD_VP') FROM DUAL;
