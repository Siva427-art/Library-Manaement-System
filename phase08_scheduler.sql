USE library_db;

SET GLOBAL event_scheduler = ON;

DELIMITER //

CREATE EVENT IF NOT EXISTS ev_daily_fine_update
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
ON COMPLETION PRESERVE
ENABLE
DO
BEGIN
    UPDATE borrow_transactions
    SET fine_amount = fn_calculate_fine(due_date, CURDATE()),
        status = 'OVERDUE'
    WHERE return_date IS NULL
    AND due_date < CURDATE()
    AND status != 'RETURNED';

    INSERT INTO notifications (student_id, message, notification_type)
    SELECT
        bt.student_id,
        CONCAT('OVERDUE ALERT: "', b.title, '" was due on ', bt.due_date,
               '. Days overdue: ', DATEDIFF(CURDATE(), bt.due_date),
               '. Current fine: $', fn_calculate_fine(bt.due_date, CURDATE())),
        'OVERDUE'
    FROM borrow_transactions bt
    JOIN books b ON bt.book_id = b.book_id
    WHERE bt.return_date IS NULL
    AND bt.due_date < CURDATE()
    AND NOT EXISTS (
        SELECT 1 FROM notifications n
        WHERE n.student_id = bt.student_id
        AND n.notification_type = 'OVERDUE'
        AND DATE(n.created_at) = CURDATE()
    );
END //

CREATE EVENT IF NOT EXISTS ev_daily_return_reminders
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
ON COMPLETION PRESERVE
ENABLE
DO
BEGIN
    INSERT INTO notifications (student_id, message, notification_type)
    SELECT
        bt.student_id,
        CONCAT('REMINDER: "', b.title, '" is due tomorrow (', bt.due_date, '). Please return on time to avoid fines.'),
        'RETURN_REMINDER'
    FROM borrow_transactions bt
    JOIN books b ON bt.book_id = b.book_id
    WHERE bt.return_date IS NULL
    AND bt.due_date = DATE_ADD(CURDATE(), INTERVAL 1 DAY)
    AND bt.status = 'BORROWED'
    AND NOT EXISTS (
        SELECT 1 FROM notifications n
        WHERE n.student_id = bt.student_id
        AND n.notification_type = 'RETURN_REMINDER'
        AND DATE(n.created_at) = CURDATE()
    );
END //

CREATE EVENT IF NOT EXISTS ev_daily_expire_reservations
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
ON COMPLETION PRESERVE
ENABLE
DO
BEGIN
    UPDATE book_reservations
    SET status = 'EXPIRED'
    WHERE status = 'PENDING'
    AND expiry_date < NOW();
END //

DELIMITER ;
