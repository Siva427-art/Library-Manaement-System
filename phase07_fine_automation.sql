USE library_db;

DELIMITER //

CREATE FUNCTION fn_calculate_fine(p_due_date DATE, p_return_date DATE)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE v_days_late INT;
    DECLARE v_fine DECIMAL(10,2);

    SET v_days_late = DATEDIFF(p_return_date, p_due_date);

    IF v_days_late <= 0 THEN
        RETURN 0.00;
    END IF;

    IF v_days_late <= 7 THEN
        SET v_fine = v_days_late * 1.00;
    ELSE
        SET v_fine = (7 * 1.00) + ((v_days_late - 7) * 2.00);
    END IF;

    IF v_fine > 50.00 THEN
        SET v_fine = 50.00;
    END IF;

    RETURN v_fine;
END //

CREATE PROCEDURE sp_update_all_fines()
BEGIN
    DECLARE v_updated INT DEFAULT 0;

    UPDATE borrow_transactions
    SET fine_amount = fn_calculate_fine(due_date, CURDATE()),
        status = 'OVERDUE'
    WHERE return_date IS NULL
    AND due_date < CURDATE()
    AND status != 'RETURNED';

    SET v_updated = ROW_COUNT();

    SELECT v_updated AS records_updated, 'Fine update completed' AS message;
END //

CREATE PROCEDURE sp_get_total_fines_by_student(IN p_student_id INT)
BEGIN
    SELECT
        s.student_id,
        CONCAT(s.first_name, ' ', s.last_name) AS student_name,
        s.email,
        SUM(bt.fine_amount) AS total_fines,
        COUNT(CASE WHEN bt.fine_amount > 0 THEN 1 END) AS transactions_with_fines,
        COUNT(CASE WHEN bt.status = 'OVERDUE' THEN 1 END) AS currently_overdue
    FROM students s
    LEFT JOIN borrow_transactions bt ON s.student_id = bt.student_id
    WHERE s.student_id = p_student_id
    GROUP BY s.student_id, s.first_name, s.last_name, s.email;
END //

CREATE PROCEDURE sp_fine_summary_report()
BEGIN
    SELECT
        s.student_id,
        CONCAT(s.first_name, ' ', s.last_name) AS student_name,
        s.department,
        COALESCE(SUM(bt.fine_amount), 0) AS total_fines,
        COUNT(CASE WHEN bt.fine_amount > 0 THEN 1 END) AS late_returns,
        COUNT(CASE WHEN bt.status = 'OVERDUE' THEN 1 END) AS overdue_books,
        CASE
            WHEN COALESCE(SUM(bt.fine_amount), 0) >= 40 THEN 'CRITICAL'
            WHEN COALESCE(SUM(bt.fine_amount), 0) >= 20 THEN 'HIGH'
            WHEN COALESCE(SUM(bt.fine_amount), 0) >= 10 THEN 'MEDIUM'
            WHEN COALESCE(SUM(bt.fine_amount), 0) > 0 THEN 'LOW'
            ELSE 'NONE'
        END AS fine_severity
    FROM students s
    LEFT JOIN borrow_transactions bt ON s.student_id = bt.student_id
    GROUP BY s.student_id, s.first_name, s.last_name, s.department
    HAVING total_fines > 0
    ORDER BY total_fines DESC;
END //

DELIMITER ;
