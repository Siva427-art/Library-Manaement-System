USE library_db;

DELIMITER //

CREATE PROCEDURE sp_reserve_book(IN p_student_id INT, IN p_book_id INT)
BEGIN
    DECLARE v_available INT DEFAULT 0;
    DECLARE v_existing INT DEFAULT 0;
    DECLARE v_student_status VARCHAR(10);

    SELECT status INTO v_student_status FROM students WHERE student_id = p_student_id;

    IF v_student_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Student not found';
    END IF;

    IF v_student_status != 'ACTIVE' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Student account is inactive';
    END IF;

    SELECT available_copies INTO v_available FROM books WHERE book_id = p_book_id;

    IF v_available IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Book not found';
    END IF;

    IF v_available > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Book is available - please borrow directly instead of reserving';
    END IF;

    SELECT COUNT(*) INTO v_existing FROM book_reservations
    WHERE student_id = p_student_id AND book_id = p_book_id AND status = 'PENDING';

    IF v_existing > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You already have a pending reservation for this book';
    END IF;

    INSERT INTO book_reservations (student_id, book_id, reservation_date, expiry_date, status)
    VALUES (p_student_id, p_book_id, NOW(), DATE_ADD(NOW(), INTERVAL 3 DAY), 'PENDING');

    INSERT INTO notifications (student_id, message, notification_type)
    VALUES (p_student_id,
        CONCAT('Your reservation has been placed. Reservation expires on ',
               DATE_FORMAT(DATE_ADD(NOW(), INTERVAL 3 DAY), '%Y-%m-%d %H:%i')),
        'RESERVATION');

    SELECT LAST_INSERT_ID() AS reservation_id, 'Book reserved successfully' AS message;
END //

CREATE PROCEDURE sp_cancel_reservation(IN p_reservation_id INT, IN p_student_id INT)
BEGIN
    DECLARE v_exists INT DEFAULT 0;

    SELECT COUNT(*) INTO v_exists FROM book_reservations
    WHERE reservation_id = p_reservation_id AND student_id = p_student_id AND status = 'PENDING';

    IF v_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No active reservation found';
    END IF;

    UPDATE book_reservations SET status = 'CANCELLED' WHERE reservation_id = p_reservation_id;

    SELECT 'Reservation cancelled successfully' AS message;
END //

CREATE PROCEDURE sp_fulfill_next_reservation(IN p_book_id INT)
BEGIN
    DECLARE v_reservation_id INT DEFAULT NULL;
    DECLARE v_student_id INT DEFAULT NULL;
    DECLARE v_available INT DEFAULT 0;
    DECLARE v_book_title VARCHAR(255);

    SELECT available_copies INTO v_available FROM books WHERE book_id = p_book_id;
    SELECT title INTO v_book_title FROM books WHERE book_id = p_book_id;

    IF v_available > 0 THEN
        SELECT reservation_id, student_id INTO v_reservation_id, v_student_id
        FROM book_reservations
        WHERE book_id = p_book_id AND status = 'PENDING'
        ORDER BY reservation_date ASC
        LIMIT 1;

        IF v_reservation_id IS NOT NULL THEN
            UPDATE book_reservations SET status = 'FULFILLED' WHERE reservation_id = v_reservation_id;

            INSERT INTO notifications (student_id, message, notification_type)
            VALUES (v_student_id,
                CONCAT('Your reserved book "', v_book_title, '" is now available for pickup. Please collect within 3 days.'),
                'RESERVATION');

            SELECT v_reservation_id AS reservation_id,
                   v_student_id AS student_id,
                   v_book_title AS book_title,
                   'Reservation fulfilled - student notified' AS message;
        ELSE
            SELECT 'No pending reservations for this book' AS message;
        END IF;
    ELSE
        SELECT 'Book has no available copies' AS message;
    END IF;
END //

CREATE PROCEDURE sp_rate_book(IN p_student_id INT, IN p_book_id INT, IN p_rating INT, IN p_review TEXT)
BEGIN
    DECLARE v_has_borrowed INT DEFAULT 0;
    DECLARE v_already_rated INT DEFAULT 0;

    IF p_rating < 1 OR p_rating > 5 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Rating must be between 1 and 5';
    END IF;

    SELECT COUNT(*) INTO v_has_borrowed FROM borrow_transactions
    WHERE student_id = p_student_id AND book_id = p_book_id;

    IF v_has_borrowed = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You can only rate books you have borrowed';
    END IF;

    SELECT COUNT(*) INTO v_already_rated FROM book_ratings
    WHERE student_id = p_student_id AND book_id = p_book_id;

    IF v_already_rated > 0 THEN
        UPDATE book_ratings
        SET rating = p_rating, review = p_review, rated_at = CURRENT_TIMESTAMP
        WHERE student_id = p_student_id AND book_id = p_book_id;

        SELECT 'Rating updated successfully' AS message;
    ELSE
        INSERT INTO book_ratings (student_id, book_id, rating, review)
        VALUES (p_student_id, p_book_id, p_rating, p_review);

        INSERT INTO loyalty_points (student_id, points, reason)
        VALUES (p_student_id, 5, CONCAT('Rated book ID: ', p_book_id));

        SELECT 'Rating submitted successfully' AS message;
    END IF;
END //

CREATE PROCEDURE sp_recommend_books(IN p_student_id INT, IN p_limit INT)
BEGIN
    IF p_limit IS NULL OR p_limit <= 0 THEN
        SET p_limit = 5;
    END IF;

    SELECT DISTINCT
        b.book_id,
        b.title,
        b.author,
        b.genre,
        b.available_copies,
        COALESCE(ROUND(AVG(br.rating), 2), 0) AS avg_rating,
        COUNT(DISTINCT bt2.transaction_id) AS popularity_score
    FROM books b
    LEFT JOIN book_ratings br ON b.book_id = br.book_id
    LEFT JOIN borrow_transactions bt2 ON b.book_id = bt2.book_id
    WHERE b.genre IN (
        SELECT DISTINCT bo.genre
        FROM borrow_transactions bt
        JOIN books bo ON bt.book_id = bo.book_id
        WHERE bt.student_id = p_student_id
    )
    AND b.book_id NOT IN (
        SELECT book_id FROM borrow_transactions WHERE student_id = p_student_id
    )
    AND b.available_copies > 0
    GROUP BY b.book_id, b.title, b.author, b.genre, b.available_copies
    ORDER BY avg_rating DESC, popularity_score DESC
    LIMIT p_limit;
END //

CREATE PROCEDURE sp_student_history(IN p_student_id INT)
BEGIN
    SELECT
        s.student_id,
        CONCAT(s.first_name, ' ', s.last_name) AS student_name,
        s.email,
        s.department,
        s.status AS account_status,
        s.enrollment_date,
        (SELECT COALESCE(SUM(lp.points), 0) FROM loyalty_points lp WHERE lp.student_id = s.student_id) AS total_loyalty_points,
        (SELECT COUNT(*) FROM borrow_transactions bt WHERE bt.student_id = s.student_id) AS total_transactions,
        (SELECT COALESCE(SUM(bt.fine_amount), 0) FROM borrow_transactions bt WHERE bt.student_id = s.student_id) AS total_fines_paid
    FROM students s WHERE s.student_id = p_student_id;

    SELECT
        bt.transaction_id,
        b.title,
        b.author,
        b.genre,
        bt.borrow_date,
        bt.due_date,
        bt.return_date,
        bt.fine_amount,
        bt.renewal_count,
        bt.status,
        CASE
            WHEN bt.return_date IS NOT NULL AND bt.return_date <= bt.due_date THEN 'ON TIME'
            WHEN bt.return_date IS NOT NULL AND bt.return_date > bt.due_date THEN 'LATE'
            WHEN bt.return_date IS NULL AND bt.due_date < CURDATE() THEN 'OVERDUE'
            ELSE 'ACTIVE'
        END AS return_status
    FROM borrow_transactions bt
    JOIN books b ON bt.book_id = b.book_id
    WHERE bt.student_id = p_student_id
    ORDER BY bt.borrow_date DESC;

    SELECT
        b.title,
        br.rating,
        br.review,
        br.rated_at
    FROM book_ratings br
    JOIN books b ON br.book_id = b.book_id
    WHERE br.student_id = p_student_id
    ORDER BY br.rated_at DESC;
END //

CREATE PROCEDURE sp_search_books(
    IN p_keyword VARCHAR(255),
    IN p_genre VARCHAR(50),
    IN p_available_only TINYINT
)
BEGIN
    SELECT
        b.book_id,
        b.title,
        b.author,
        b.genre,
        b.isbn,
        b.publisher,
        b.publish_year,
        b.available_copies,
        b.total_copies,
        b.book_condition,
        COALESCE(ROUND(AVG(br.rating), 2), 0) AS avg_rating,
        COUNT(DISTINCT bt.transaction_id) AS times_borrowed
    FROM books b
    LEFT JOIN book_ratings br ON b.book_id = br.book_id
    LEFT JOIN borrow_transactions bt ON b.book_id = bt.book_id
    WHERE (p_keyword IS NULL OR b.title LIKE CONCAT('%', p_keyword, '%') OR b.author LIKE CONCAT('%', p_keyword, '%'))
    AND (p_genre IS NULL OR b.genre = p_genre)
    AND (p_available_only = 0 OR b.available_copies > 0)
    GROUP BY b.book_id, b.title, b.author, b.genre, b.isbn, b.publisher,
             b.publish_year, b.available_copies, b.total_copies, b.book_condition
    ORDER BY b.title;
END //

CREATE PROCEDURE sp_fulltext_search_books(IN p_search_term VARCHAR(255))
BEGIN
    SELECT
        b.book_id,
        b.title,
        b.author,
        b.genre,
        b.available_copies,
        MATCH(b.title, b.author) AGAINST(p_search_term IN NATURAL LANGUAGE MODE) AS relevance_score,
        COALESCE(ROUND(AVG(br.rating), 2), 0) AS avg_rating
    FROM books b
    LEFT JOIN book_ratings br ON b.book_id = br.book_id
    WHERE MATCH(b.title, b.author) AGAINST(p_search_term IN NATURAL LANGUAGE MODE)
    GROUP BY b.book_id, b.title, b.author, b.genre, b.available_copies
    ORDER BY relevance_score DESC;
END //

CREATE PROCEDURE sp_get_loyalty_summary(IN p_student_id INT)
BEGIN
    SELECT
        s.student_id,
        CONCAT(s.first_name, ' ', s.last_name) AS student_name,
        s.department,
        COALESCE(SUM(lp.points), 0) AS total_points,
        CASE
            WHEN COALESCE(SUM(lp.points), 0) >= 500 THEN 'PLATINUM'
            WHEN COALESCE(SUM(lp.points), 0) >= 200 THEN 'GOLD'
            WHEN COALESCE(SUM(lp.points), 0) >= 100 THEN 'SILVER'
            ELSE 'BRONZE'
        END AS loyalty_tier,
        CASE
            WHEN COALESCE(SUM(lp.points), 0) >= 500 THEN '3 extra renewal days + priority reservations'
            WHEN COALESCE(SUM(lp.points), 0) >= 200 THEN '2 extra renewal days'
            WHEN COALESCE(SUM(lp.points), 0) >= 100 THEN '1 extra renewal day'
            ELSE 'Standard benefits'
        END AS tier_benefits
    FROM students s
    LEFT JOIN loyalty_points lp ON s.student_id = lp.student_id
    WHERE s.student_id = p_student_id
    GROUP BY s.student_id, s.first_name, s.last_name, s.department;

    SELECT
        points,
        reason,
        transaction_id,
        earned_at
    FROM loyalty_points
    WHERE student_id = p_student_id
    ORDER BY earned_at DESC;
END //

CREATE PROCEDURE sp_loyalty_leaderboard(IN p_limit INT)
BEGIN
    IF p_limit IS NULL OR p_limit <= 0 THEN
        SET p_limit = 10;
    END IF;

    SELECT
        s.student_id,
        CONCAT(s.first_name, ' ', s.last_name) AS student_name,
        s.department,
        COALESCE(SUM(lp.points), 0) AS total_points,
        CASE
            WHEN COALESCE(SUM(lp.points), 0) >= 500 THEN 'PLATINUM'
            WHEN COALESCE(SUM(lp.points), 0) >= 200 THEN 'GOLD'
            WHEN COALESCE(SUM(lp.points), 0) >= 100 THEN 'SILVER'
            ELSE 'BRONZE'
        END AS loyalty_tier,
        RANK() OVER (ORDER BY COALESCE(SUM(lp.points), 0) DESC) AS leaderboard_rank
    FROM students s
    LEFT JOIN loyalty_points lp ON s.student_id = lp.student_id
    GROUP BY s.student_id, s.first_name, s.last_name, s.department
    HAVING total_points > 0
    ORDER BY total_points DESC
    LIMIT p_limit;
END //

CREATE PROCEDURE sp_bulk_overdue_notification()
BEGIN
    DECLARE v_count INT DEFAULT 0;

    INSERT INTO notifications (student_id, message, notification_type)
    SELECT
        bt.student_id,
        CONCAT('URGENT REMINDER: "', b.title, '" is overdue by ',
               DATEDIFF(CURDATE(), bt.due_date), ' days. Current fine: $',
               ROUND(bt.fine_amount, 2), '. Please return immediately.'),
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

    SET v_count = ROW_COUNT();

    SELECT v_count AS notifications_sent, 'Bulk overdue notifications completed' AS message;
END //

CREATE PROCEDURE sp_get_unread_notifications(IN p_student_id INT)
BEGIN
    SELECT
        notification_id,
        message,
        notification_type,
        created_at
    FROM notifications
    WHERE student_id = p_student_id
    AND is_read = 0
    ORDER BY created_at DESC;

    UPDATE notifications SET is_read = 1
    WHERE student_id = p_student_id AND is_read = 0;
END //

CREATE PROCEDURE sp_genre_popularity_report()
BEGIN
    SELECT
        b.genre,
        COUNT(DISTINCT b.book_id) AS total_books,
        SUM(b.total_copies) AS total_copies,
        COUNT(bt.transaction_id) AS total_borrows,
        COUNT(DISTINCT bt.student_id) AS unique_readers,
        COALESCE(ROUND(AVG(br.rating), 2), 0) AS avg_rating,
        SUM(CASE WHEN bt.status = 'OVERDUE' THEN 1 ELSE 0 END) AS overdue_count,
        ROUND(COUNT(bt.transaction_id) * 100.0 / NULLIF((SELECT COUNT(*) FROM borrow_transactions), 0), 2) AS borrow_percentage
    FROM books b
    LEFT JOIN borrow_transactions bt ON b.book_id = bt.book_id
    LEFT JOIN book_ratings br ON b.book_id = br.book_id
    GROUP BY b.genre
    ORDER BY total_borrows DESC;
END //

CREATE PROCEDURE sp_yearly_analytics(IN p_year INT)
BEGIN
    IF p_year IS NULL THEN
        SET p_year = YEAR(CURDATE());
    END IF;

    SELECT
        MONTH(bt.borrow_date) AS month_number,
        DATE_FORMAT(bt.borrow_date, '%M') AS month_name,
        COUNT(*) AS total_borrows,
        COUNT(CASE WHEN bt.status = 'RETURNED' THEN 1 END) AS returns,
        COUNT(CASE WHEN bt.status = 'OVERDUE' THEN 1 END) AS overdue,
        COALESCE(SUM(bt.fine_amount), 0) AS fines_collected,
        COUNT(DISTINCT bt.student_id) AS unique_borrowers,
        COUNT(DISTINCT bt.book_id) AS unique_books
    FROM borrow_transactions bt
    WHERE YEAR(bt.borrow_date) = p_year
    GROUP BY MONTH(bt.borrow_date), DATE_FORMAT(bt.borrow_date, '%M')
    ORDER BY month_number;
END //

CREATE PROCEDURE sp_book_availability_report()
BEGIN
    SELECT
        b.book_id,
        b.title,
        b.author,
        b.genre,
        b.total_copies,
        b.available_copies,
        b.total_copies - b.available_copies AS copies_borrowed,
        ROUND((b.total_copies - b.available_copies) * 100.0 / b.total_copies, 2) AS utilization_rate,
        b.book_condition,
        CASE
            WHEN b.available_copies = 0 THEN 'UNAVAILABLE'
            WHEN b.available_copies <= 1 THEN 'LOW STOCK'
            ELSE 'AVAILABLE'
        END AS availability_status,
        (SELECT COUNT(*) FROM book_reservations br WHERE br.book_id = b.book_id AND br.status = 'PENDING') AS pending_reservations
    FROM books b
    ORDER BY utilization_rate DESC;
END //

DELIMITER ;

CALL sp_rate_book(25, 1, 4, 'A timeless classic that everyone should read');
CALL sp_rate_book(26, 4, 5, 'Masterpiece of American literature');
CALL sp_rate_book(27, 9, 4, 'Thought-provoking dystopian novel');
CALL sp_rate_book(28, 15, 3, 'Good strategic insights but repetitive');
CALL sp_rate_book(29, 22, 5, 'Essential reference for CS students');
CALL sp_rate_book(30, 37, 4, 'Classic detective stories, very engaging');
CALL sp_rate_book(1, 1, 5, 'My favorite book of all time');
CALL sp_rate_book(2, 12, 5, 'Magical and unforgettable');
CALL sp_rate_book(3, 16, 4, 'Eye-opening perspective on human history');
CALL sp_rate_book(4, 33, 5, 'Best science fiction ever written');
CALL sp_rate_book(5, 46, 5, 'Changed my daily routine completely');

SELECT '--- BOOK RATINGS SUMMARY ---' AS test;
SELECT b.title, ROUND(AVG(br.rating), 2) AS avg_rating, COUNT(*) AS num_ratings
FROM book_ratings br JOIN books b ON br.book_id = b.book_id
GROUP BY b.title ORDER BY avg_rating DESC;

SELECT '--- BOOK RECOMMENDATIONS FOR STUDENT 1 ---' AS test;
CALL sp_recommend_books(1, 5);

SELECT '--- STUDENT HISTORY FOR STUDENT 1 ---' AS test;
CALL sp_student_history(1);

SELECT '--- SEARCH: FICTION BOOKS ---' AS test;
CALL sp_search_books(NULL, 'Fiction', 0);

SELECT '--- SEARCH: TOLKIEN ---' AS test;
CALL sp_search_books('Tolkien', NULL, 1);

SELECT '--- FULLTEXT SEARCH: HISTORY ---' AS test;
CALL sp_fulltext_search_books('history time');

SELECT '--- LOYALTY SUMMARY FOR STUDENT 1 ---' AS test;
CALL sp_get_loyalty_summary(1);

SELECT '--- LOYALTY LEADERBOARD ---' AS test;
CALL sp_loyalty_leaderboard(10);

SELECT '--- GENRE POPULARITY ---' AS test;
CALL sp_genre_popularity_report();

SELECT '--- YEARLY ANALYTICS 2025 ---' AS test;
CALL sp_yearly_analytics(2025);

SELECT '--- BOOK AVAILABILITY REPORT ---' AS test;
CALL sp_book_availability_report();

SELECT '--- BULK OVERDUE NOTIFICATIONS ---' AS test;
CALL sp_bulk_overdue_notification();

SELECT '--- UNREAD NOTIFICATIONS FOR STUDENT 20 ---' AS test;
CALL sp_get_unread_notifications(20);

SELECT '=== ALL SPECIAL FEATURES VALIDATED ===' AS final_status;
