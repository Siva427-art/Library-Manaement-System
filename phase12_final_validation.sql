USE library_db;

SELECT '=== PHASE 12: FINAL VALIDATION ===' AS test_header;

SELECT '--- TEST 1: BORROW BOOKS ---' AS test_step;
CALL sp_borrow_book(1, 1);
CALL sp_borrow_book(1, 8);
CALL sp_borrow_book(2, 12);
CALL sp_borrow_book(3, 16);
CALL sp_borrow_book(3, 21);
CALL sp_borrow_book(4, 33);
CALL sp_borrow_book(5, 46);
CALL sp_borrow_book(6, 4);
CALL sp_borrow_book(7, 11);
CALL sp_borrow_book(8, 25);
CALL sp_borrow_book(9, 39);
CALL sp_borrow_book(10, 49);
CALL sp_borrow_book(11, 2);
CALL sp_borrow_book(12, 17);
CALL sp_borrow_book(13, 28);
CALL sp_borrow_book(14, 36);
CALL sp_borrow_book(15, 45);

SELECT '--- TEST 2: VERIFY BORROW RECORDS ---' AS test_step;
SELECT transaction_id, student_id, book_id, borrow_date, due_date, status
FROM borrow_transactions ORDER BY transaction_id;

SELECT '--- TEST 3: VERIFY BOOK COPIES DECREASED ---' AS test_step;
SELECT book_id, title, total_copies, available_copies
FROM books WHERE book_id IN (1, 8, 12, 16, 21, 33, 46, 4, 11, 25);

SELECT '--- TEST 4: RETURN BOOKS ---' AS test_step;
CALL sp_return_book(1);
CALL sp_return_book(3);

SELECT '--- TEST 5: VERIFY RETURN RECORDS ---' AS test_step;
SELECT transaction_id, student_id, book_id, return_date, fine_amount, status
FROM borrow_transactions WHERE transaction_id IN (1, 3);

SELECT '--- TEST 6: VERIFY BOOK COPIES RESTORED ---' AS test_step;
SELECT book_id, title, total_copies, available_copies
FROM books WHERE book_id IN (1, 12);

SELECT '--- TEST 7: RENEW A BOOK ---' AS test_step;
CALL sp_renew_book(2);

SELECT '--- TEST 8: VERIFY RENEWAL ---' AS test_step;
SELECT transaction_id, due_date, renewal_count, status
FROM borrow_transactions WHERE transaction_id = 2;

SELECT '--- TEST 9: INSERT HISTORICAL OVERDUE RECORDS ---' AS test_step;
INSERT INTO borrow_transactions (student_id, book_id, borrow_date, due_date, status) VALUES
(20, 7, '2025-12-01', '2025-12-15', 'BORROWED'),
(21, 13, '2025-11-15', '2025-11-29', 'BORROWED'),
(22, 19, '2025-12-20', '2026-01-03', 'BORROWED'),
(23, 26, '2025-10-01', '2025-10-15', 'BORROWED'),
(24, 32, '2025-09-01', '2025-09-15', 'BORROWED');

UPDATE books SET available_copies = available_copies - 1 WHERE book_id IN (7, 13, 19, 26, 32);

SELECT '--- TEST 10: UPDATE FINES FOR OVERDUE ---' AS test_step;
CALL sp_update_all_fines();

SELECT '--- TEST 11: VERIFY OVERDUE FINES ---' AS test_step;
SELECT transaction_id, student_id, book_id, borrow_date, due_date,
       DATEDIFF(CURDATE(), due_date) AS days_overdue, fine_amount, status
FROM borrow_transactions WHERE status = 'OVERDUE';

SELECT '--- TEST 12: INSERT HISTORICAL RETURNED WITH FINES ---' AS test_step;
INSERT INTO borrow_transactions (student_id, book_id, borrow_date, due_date, return_date, fine_amount, status) VALUES
(25, 1, '2025-10-01', '2025-10-15', '2025-10-20', 5.00, 'RETURNED'),
(26, 4, '2025-11-01', '2025-11-15', '2025-11-25', 13.00, 'RETURNED'),
(27, 9, '2025-09-01', '2025-09-15', '2025-09-18', 3.00, 'RETURNED'),
(28, 15, '2025-08-01', '2025-08-15', '2025-08-15', 0.00, 'RETURNED'),
(29, 22, '2025-07-01', '2025-07-15', '2025-07-14', 0.00, 'RETURNED'),
(30, 37, '2025-11-10', '2025-11-24', '2025-12-05', 15.00, 'RETURNED'),
(31, 40, '2025-10-15', '2025-10-29', '2025-11-02', 4.00, 'RETURNED'),
(32, 44, '2025-09-20', '2025-10-04', '2025-10-12', 15.00, 'RETURNED'),
(33, 48, '2025-12-05', '2025-12-19', '2026-01-05', 27.00, 'RETURNED'),
(34, 50, '2025-08-10', '2025-08-24', '2025-08-30', 6.00, 'RETURNED');

SELECT '--- TEST 13: FINE CALCULATION FUNCTION TEST ---' AS test_step;
SELECT fn_calculate_fine('2025-01-01', '2025-01-01') AS on_time_fine;
SELECT fn_calculate_fine('2025-01-01', '2025-01-05') AS four_days_late;
SELECT fn_calculate_fine('2025-01-01', '2025-01-10') AS nine_days_late;
SELECT fn_calculate_fine('2025-01-01', '2025-02-15') AS fortyfive_days_late;
SELECT fn_calculate_fine('2025-01-01', '2025-12-31') AS max_capped_fine;

SELECT '--- TEST 14: LOYALTY POINTS CHECK ---' AS test_step;
SELECT * FROM loyalty_points ORDER BY point_id;

SELECT '--- TEST 15: OVERDUE BOOKS REPORT ---' AS test_step;
SELECT * FROM vw_overdue_books;

SELECT '--- TEST 16: HIGHEST FINES REPORT ---' AS test_step;
SELECT * FROM vw_highest_fines;

SELECT '--- TEST 17: MOST BORROWED BOOKS ---' AS test_step;
SELECT * FROM vw_most_borrowed LIMIT 10;

SELECT '--- TEST 18: STUDENT STATUS DISTRIBUTION ---' AS test_step;
SELECT * FROM vw_student_status;

SELECT '--- TEST 19: MONTHLY BORROWING SUMMARY ---' AS test_step;
SELECT * FROM vw_monthly_summary;

SELECT '--- TEST 20: LIBRARY DASHBOARD ---' AS test_step;
SELECT * FROM vw_library_dashboard;

SELECT '--- TEST 21: DEPARTMENT ANALYTICS ---' AS test_step;
SELECT * FROM vw_department_analytics;

SELECT '--- TEST 22: BOOK POPULARITY RANKING ---' AS test_step;
SELECT * FROM vw_book_popularity LIMIT 10;

SELECT '--- TEST 23: STUDENT BORROWING PROFILES ---' AS test_step;
SELECT * FROM vw_student_borrowing_profile WHERE total_borrows > 0;

SELECT '--- TEST 24: GENRE DISTRIBUTION ---' AS test_step;
SELECT * FROM vw_genre_distribution;

SELECT '--- TEST 25: AUDIT LOG VERIFICATION ---' AS test_step;
SELECT log_id, table_name, action_type, performed_by, action_time
FROM audit_log ORDER BY log_id DESC LIMIT 25;

SELECT '--- TEST 26: AUDIT LOG COUNTS BY TYPE ---' AS test_step;
SELECT table_name, action_type, COUNT(*) AS entry_count
FROM audit_log GROUP BY table_name, action_type ORDER BY table_name, action_type;

SELECT '--- TEST 27: VERIFY SCHEDULED EVENTS ---' AS test_step;
SELECT EVENT_NAME, EVENT_TYPE, EXECUTE_AT, INTERVAL_VALUE, INTERVAL_FIELD, STATUS
FROM INFORMATION_SCHEMA.EVENTS WHERE EVENT_SCHEMA = 'library_db';

SELECT '--- TEST 28: VERIFY ALL TRIGGERS ---' AS test_step;
SELECT TRIGGER_NAME, EVENT_MANIPULATION, EVENT_OBJECT_TABLE, ACTION_TIMING
FROM INFORMATION_SCHEMA.TRIGGERS WHERE TRIGGER_SCHEMA = 'library_db';

SELECT '--- TEST 29: INACTIVE STUDENTS CHECK ---' AS test_step;
CALL sp_check_inactive_students();

SELECT '--- TEST 30: VERIFY INACTIVE STUDENTS ---' AS test_step;
SELECT student_id, CONCAT(first_name, ' ', last_name) AS name, status
FROM students WHERE status = 'INACTIVE';

SELECT '=== ALL VALIDATION TESTS COMPLETED ===' AS final_status;
