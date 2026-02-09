USE library_db;

DELIMITER //

CREATE PROCEDURE sp_check_inactive_students()
BEGIN
    DECLARE v_count INT DEFAULT 0;

    UPDATE students
    SET status = 'INACTIVE'
    WHERE student_id NOT IN (
        SELECT DISTINCT student_id
        FROM borrow_transactions
        WHERE borrow_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
    )
    AND status = 'ACTIVE'
    AND enrollment_date < DATE_SUB(CURDATE(), INTERVAL 6 MONTH);

    SET v_count = ROW_COUNT();

    SELECT v_count AS students_marked_inactive,
           CURDATE() AS check_date,
           'Inactive student check completed' AS message;
END //

CREATE PROCEDURE sp_reactivate_student(IN p_student_id INT)
BEGIN
    DECLARE v_current_status VARCHAR(10);

    SELECT status INTO v_current_status FROM students WHERE student_id = p_student_id;

    IF v_current_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Student not found';
    END IF;

    IF v_current_status = 'ACTIVE' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Student is already active';
    END IF;

    UPDATE students SET status = 'ACTIVE' WHERE student_id = p_student_id;

    SELECT p_student_id AS student_id, 'Student reactivated successfully' AS message;
END //

CREATE PROCEDURE sp_inactive_students_report()
BEGIN
    SELECT
        s.student_id,
        CONCAT(s.first_name, ' ', s.last_name) AS student_name,
        s.email,
        s.department,
        s.enrollment_date,
        s.status,
        MAX(bt.borrow_date) AS last_borrow_date,
        DATEDIFF(CURDATE(), COALESCE(MAX(bt.borrow_date), s.enrollment_date)) AS days_since_last_activity
    FROM students s
    LEFT JOIN borrow_transactions bt ON s.student_id = bt.student_id
    WHERE s.status = 'INACTIVE'
    GROUP BY s.student_id, s.first_name, s.last_name, s.email, s.department, s.enrollment_date, s.status
    ORDER BY days_since_last_activity DESC;
END //

CREATE EVENT IF NOT EXISTS ev_monthly_inactive_check
ON SCHEDULE EVERY 1 MONTH
STARTS CURRENT_TIMESTAMP
ON COMPLETION PRESERVE
ENABLE
DO
BEGIN
    CALL sp_check_inactive_students();
END //

DELIMITER ;
