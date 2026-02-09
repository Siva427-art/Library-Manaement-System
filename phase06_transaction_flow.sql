USE library_db;
DELIMITER //
CREATE PROCEDURE sp_borrow_book(IN p_student_id INT, IN p_book_id INT)
BEGIN
    DECLARE v_available INT DEFAULT 0;
    DECLARE v_student_status VARCHAR(10) DEFAULT '';
    DECLARE v_active_borrows INT DEFAULT 0;
    DECLARE v_student_exists INT DEFAULT 0;
    DECLARE v_book_exists INT DEFAULT 0;
    SELECT COUNT(*) INTO v_student_exists FROM students WHERE student_id = p_student_id;
    IF v_student_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Student not found';
    END IF;
    SELECT status INTO v_student_status FROM students WHERE student_id = p_student_id;
    IF v_student_status != 'ACTIVE' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Student account is inactive';
    END IF;
    SELECT COUNT(*) INTO v_book_exists FROM books WHERE book_id = p_book_id;
    IF v_book_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Book not found';
    END IF;
    SELECT COUNT(*) INTO v_active_borrows FROM borrow_transactions
    WHERE student_id = p_student_id AND status IN ('BORROWED', 'OVERDUE');
    IF v_active_borrows >= 5 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Maximum borrowing limit reached (5 books)';
    END IF;
    SELECT available_copies INTO v_available FROM books WHERE book_id = p_book_id;
    IF v_available <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No copies available for borrowing';
    END IF;
    START TRANSACTION;
    INSERT INTO borrow_transactions (student_id, book_id, borrow_date, due_date, status)
    VALUES (p_student_id, p_book_id, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 14 DAY), 'BORROWED');
    UPDATE books SET available_copies = available_copies - 1 WHERE book_id = p_book_id;
    COMMIT;
    SELECT LAST_INSERT_ID() AS transaction_id,
           p_student_id AS student_id,
           p_book_id AS book_id,
           CURDATE() AS borrow_date,
           DATE_ADD(CURDATE(), INTERVAL 14 DAY) AS due_date,
           'Book borrowed successfully' AS message;
END //
CREATE PROCEDURE sp_return_book(IN p_transaction_id INT)
BEGIN
    DECLARE v_book_id INT;
    DECLARE v_student_id INT;
    DECLARE v_due_date DATE;
    DECLARE v_status VARCHAR(10);
    DECLARE v_days_late INT;
    DECLARE v_fine DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_exists INT DEFAULT 0;
    SELECT COUNT(*) INTO v_exists FROM borrow_transactions WHERE transaction_id = p_transaction_id;
    IF v_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Transaction not found';
    END IF;
    SELECT book_id, student_id, due_date, status
    INTO v_book_id, v_student_id, v_due_date, v_status
    FROM borrow_transactions WHERE transaction_id = p_transaction_id;
    IF v_status = 'RETURNED' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Book has already been returned';
    END IF;
    SET v_days_late = DATEDIFF(CURDATE(), v_due_date);
    IF v_days_late > 0 AND v_days_late <= 7 THEN
        SET v_fine = v_days_late * 1.00;
    ELSEIF v_days_late > 7 THEN
        SET v_fine = (7 * 1.00) + ((v_days_late - 7) * 2.00);
    END IF;
    IF v_fine > 50.00 THEN
        SET v_fine = 50.00;
    END IF;
    START TRANSACTION;
    UPDATE borrow_transactions
    SET return_date = CURDATE(),
        fine_amount = v_fine,
        status = 'RETURNED'
    WHERE transaction_id = p_transaction_id;
    UPDATE books SET available_copies = available_copies + 1 WHERE book_id = v_book_id;
    IF v_fine = 0 THEN
        INSERT INTO loyalty_points (student_id, points, reason, transaction_id)
        VALUES (v_student_id, 10, 'On-time book return', p_transaction_id);
    ELSEIF v_days_late <= 3 THEN
        INSERT INTO loyalty_points (student_id, points, reason, transaction_id)
        VALUES (v_student_id, 5, 'Book returned within grace period', p_transaction_id);
    END IF;
    COMMIT;
    SELECT p_transaction_id AS transaction_id,
           v_fine AS fine_amount,
           v_days_late AS days_late,
           'Book returned successfully' AS message;
END //
CREATE PROCEDURE sp_renew_book(IN p_transaction_id INT)
BEGIN
    DECLARE v_renewal_count INT;
    DECLARE v_status VARCHAR(10);
    DECLARE v_due_date DATE;
    DECLARE v_exists INT DEFAULT 0;

    SELECT COUNT(*) INTO v_exists FROM borrow_transactions WHERE transaction_id = p_transaction_id;

    IF v_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Transaction not found';
    END IF;

    SELECT renewal_count, status, due_date
    INTO v_renewal_count, v_status, v_due_date
    FROM borrow_transactions WHERE transaction_id = p_transaction_id;

    IF v_status = 'RETURNED' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Book has already been returned';
    END IF;

    IF v_renewal_count >= 2 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Maximum renewal limit reached (2 renewals)';
    END IF;

    IF v_due_date < CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot renew overdue book - please return it first';
    END IF;

    UPDATE borrow_transactions
    SET due_date = DATE_ADD(due_date, INTERVAL 7 DAY),
        renewal_count = renewal_count + 1
    WHERE transaction_id = p_transaction_id;

    SELECT p_transaction_id AS transaction_id,
           DATE_ADD(v_due_date, INTERVAL 7 DAY) AS new_due_date,
           v_renewal_count + 1 AS total_renewals,
           'Book renewed successfully' AS message;
END //

DELIMITER ;
