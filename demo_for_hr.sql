USE library_db;

SELECT '============================================' AS '';
SELECT '   LIBRARY MANAGEMENT SYSTEM - LIVE DEMO   ' AS '';
SELECT '============================================' AS '';

SELECT '' AS '';
SELECT 'DEMO 1: LIBRARY DASHBOARD (Full System Overview)' AS '';
SELECT '------------------------------------------------' AS '';
SELECT * FROM vw_library_dashboard\G

SELECT '' AS '';
SELECT 'DEMO 2: BORROW A BOOK (Student 1 borrows Harry Potter)' AS '';
SELECT '------------------------------------------------------' AS '';
CALL sp_borrow_book(1, 12);

SELECT '' AS '';
SELECT 'DEMO 3: VERIFY - Book copies decreased' AS '';
SELECT '---------------------------------------' AS '';
SELECT book_id, title, total_copies, available_copies
FROM books WHERE book_id = 12;

SELECT '' AS '';
SELECT 'DEMO 4: RETURN A BOOK (with fine calculation)' AS '';
SELECT '----------------------------------------------' AS '';
CALL sp_return_book(1);

SELECT '' AS '';
SELECT 'DEMO 5: VERIFY - Book copies restored' AS '';
SELECT '--------------------------------------' AS '';
SELECT book_id, title, total_copies, available_copies
FROM books WHERE book_id = 12;

SELECT '' AS '';
SELECT 'DEMO 6: SEARCH BOOKS (keyword search)' AS '';
SELECT '--------------------------------------' AS '';
CALL sp_search_books('Tolkien', NULL, 1);

SELECT '' AS '';
SELECT 'DEMO 7: FULLTEXT SEARCH (natural language)' AS '';
SELECT '-------------------------------------------' AS '';
CALL sp_fulltext_search_books('history time');

SELECT '' AS '';
SELECT 'DEMO 8: RATE A BOOK (Student rates a book 5 stars)' AS '';
SELECT '---------------------------------------------------' AS '';
CALL sp_rate_book(1, 12, 5, 'Magical and unforgettable experience');

SELECT '' AS '';
SELECT 'DEMO 9: BOOK RECOMMENDATIONS (based on borrowing history)' AS '';
SELECT '---------------------------------------------------------' AS '';
CALL sp_recommend_books(1, 5);

SELECT '' AS '';
SELECT 'DEMO 10: LOYALTY POINTS & TIER' AS '';
SELECT '------------------------------' AS '';
CALL sp_get_loyalty_summary(1);

SELECT '' AS '';
SELECT 'DEMO 11: LOYALTY LEADERBOARD (Top 10)' AS '';
SELECT '--------------------------------------' AS '';
CALL sp_loyalty_leaderboard(10);

SELECT '' AS '';
SELECT 'DEMO 12: STUDENT COMPLETE HISTORY' AS '';
SELECT '----------------------------------' AS '';
CALL sp_student_history(1);

SELECT '' AS '';
SELECT 'DEMO 13: OVERDUE BOOKS REPORT' AS '';
SELECT '-----------------------------' AS '';
SELECT * FROM vw_overdue_books;

SELECT '' AS '';
SELECT 'DEMO 14: HIGHEST FINES REPORT' AS '';
SELECT '-----------------------------' AS '';
SELECT * FROM vw_highest_fines LIMIT 5;

SELECT '' AS '';
SELECT 'DEMO 15: MOST BORROWED BOOKS' AS '';
SELECT '----------------------------' AS '';
SELECT * FROM vw_most_borrowed LIMIT 5;

SELECT '' AS '';
SELECT 'DEMO 16: ACTIVE vs INACTIVE STUDENTS' AS '';
SELECT '-------------------------------------' AS '';
SELECT * FROM vw_student_status;

SELECT '' AS '';
SELECT 'DEMO 17: MONTHLY BORROWING SUMMARY' AS '';
SELECT '-----------------------------------' AS '';
SELECT * FROM vw_monthly_summary;

SELECT '' AS '';
SELECT 'DEMO 18: DEPARTMENT ANALYTICS' AS '';
SELECT '-----------------------------' AS '';
SELECT * FROM vw_department_analytics;

SELECT '' AS '';
SELECT 'DEMO 19: GENRE DISTRIBUTION' AS '';
SELECT '---------------------------' AS '';
SELECT * FROM vw_genre_distribution;

SELECT '' AS '';
SELECT 'DEMO 20: BOOK AVAILABILITY REPORT' AS '';
SELECT '----------------------------------' AS '';
CALL sp_book_availability_report();

SELECT '' AS '';
SELECT 'DEMO 21: AUDIT LOG (last 10 changes tracked automatically)' AS '';
SELECT '-----------------------------------------------------------' AS '';
SELECT log_id, table_name, action_type, performed_by,
       DATE_FORMAT(action_time, '%Y-%m-%d %H:%i:%s') AS action_time
FROM audit_log ORDER BY log_id DESC LIMIT 10;

SELECT '' AS '';
SELECT 'DEMO 22: SCHEDULED EVENTS (Automated Cron Jobs)' AS '';
SELECT '------------------------------------------------' AS '';
SELECT EVENT_NAME, INTERVAL_VALUE, INTERVAL_FIELD, STATUS
FROM INFORMATION_SCHEMA.EVENTS WHERE EVENT_SCHEMA = 'library_db';

SELECT '' AS '';
SELECT 'DEMO 23: ALL TRIGGERS (Automatic Audit Tracking)' AS '';
SELECT '-------------------------------------------------' AS '';
SELECT TRIGGER_NAME, EVENT_MANIPULATION, EVENT_OBJECT_TABLE
FROM INFORMATION_SCHEMA.TRIGGERS WHERE TRIGGER_SCHEMA = 'library_db';

SELECT '' AS '';
SELECT 'DEMO 24: FINE CALCULATION FUNCTION TEST' AS '';
SELECT '---------------------------------------' AS '';
SELECT 'On time'     AS scenario, fn_calculate_fine('2026-01-01', '2026-01-01') AS fine
UNION ALL
SELECT '3 days late'  AS scenario, fn_calculate_fine('2026-01-01', '2026-01-04') AS fine
UNION ALL
SELECT '7 days late'  AS scenario, fn_calculate_fine('2026-01-01', '2026-01-08') AS fine
UNION ALL
SELECT '10 days late' AS scenario, fn_calculate_fine('2026-01-01', '2026-01-11') AS fine
UNION ALL
SELECT '30 days late' AS scenario, fn_calculate_fine('2026-01-01', '2026-01-31') AS fine
UNION ALL
SELECT '90 days late (capped)' AS scenario, fn_calculate_fine('2026-01-01', '2026-04-01') AS fine;

SELECT '' AS '';
SELECT 'DEMO 25: SYSTEM SUMMARY' AS '';
SELECT '-----------------------' AS '';
SELECT
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'library_db') AS total_tables,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_SCHEMA = 'library_db' AND ROUTINE_TYPE = 'PROCEDURE') AS total_procedures,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_SCHEMA = 'library_db' AND ROUTINE_TYPE = 'FUNCTION') AS total_functions,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TRIGGERS WHERE TRIGGER_SCHEMA = 'library_db') AS total_triggers,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.EVENTS WHERE EVENT_SCHEMA = 'library_db') AS total_events,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_SCHEMA = 'library_db') AS total_views;

SELECT '' AS '';
SELECT '============================================' AS '';
SELECT '     DEMO COMPLETED SUCCESSFULLY            ' AS '';
SELECT '============================================' AS '';
