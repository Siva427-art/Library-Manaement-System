USE library_db;

CREATE OR REPLACE VIEW vw_overdue_books AS
SELECT
    bt.transaction_id,
    s.student_id,
    CONCAT(s.first_name, ' ', s.last_name) AS student_name,
    s.email,
    s.department,
    b.book_id,
    b.title AS book_title,
    b.author,
    bt.borrow_date,
    bt.due_date,
    DATEDIFF(CURDATE(), bt.due_date) AS days_overdue,
    bt.fine_amount,
    bt.renewal_count
FROM borrow_transactions bt
JOIN students s ON bt.student_id = s.student_id
JOIN books b ON bt.book_id = b.book_id
WHERE bt.return_date IS NULL
AND bt.due_date < CURDATE()
ORDER BY days_overdue DESC;

CREATE OR REPLACE VIEW vw_highest_fines AS
SELECT
    s.student_id,
    CONCAT(s.first_name, ' ', s.last_name) AS student_name,
    s.email,
    s.department,
    SUM(bt.fine_amount) AS total_fines,
    COUNT(CASE WHEN bt.fine_amount > 0 THEN 1 END) AS late_returns,
    COUNT(*) AS total_transactions,
    ROUND(AVG(bt.fine_amount), 2) AS avg_fine_per_transaction
FROM students s
JOIN borrow_transactions bt ON s.student_id = bt.student_id
GROUP BY s.student_id, s.first_name, s.last_name, s.email, s.department
HAVING SUM(bt.fine_amount) > 0
ORDER BY total_fines DESC;

CREATE OR REPLACE VIEW vw_most_borrowed AS
SELECT
    b.book_id,
    b.title,
    b.author,
    b.genre,
    COUNT(bt.transaction_id) AS times_borrowed,
    b.total_copies,
    b.available_copies,
    COALESCE(ROUND(AVG(br.rating), 2), 0) AS avg_rating,
    COUNT(DISTINCT br.rating_id) AS total_ratings,
    CASE
        WHEN COUNT(bt.transaction_id) >= 10 THEN 'BESTSELLER'
        WHEN COUNT(bt.transaction_id) >= 5 THEN 'POPULAR'
        WHEN COUNT(bt.transaction_id) >= 2 THEN 'MODERATE'
        ELSE 'LOW DEMAND'
    END AS popularity_tier
FROM books b
LEFT JOIN borrow_transactions bt ON b.book_id = bt.book_id
LEFT JOIN book_ratings br ON b.book_id = br.book_id
GROUP BY b.book_id, b.title, b.author, b.genre, b.total_copies, b.available_copies
ORDER BY times_borrowed DESC;

CREATE OR REPLACE VIEW vw_student_status AS
SELECT
    status,
    COUNT(*) AS student_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM students), 2) AS percentage
FROM students
GROUP BY status;

CREATE OR REPLACE VIEW vw_monthly_summary AS
SELECT
    DATE_FORMAT(bt.borrow_date, '%Y-%m') AS month,
    COUNT(*) AS total_borrows,
    COUNT(CASE WHEN bt.status = 'RETURNED' THEN 1 END) AS total_returns,
    COUNT(CASE WHEN bt.status = 'OVERDUE' THEN 1 END) AS total_overdue,
    COUNT(CASE WHEN bt.status = 'BORROWED' THEN 1 END) AS currently_borrowed,
    COALESCE(SUM(bt.fine_amount), 0) AS total_fines_collected,
    COUNT(DISTINCT bt.student_id) AS unique_borrowers,
    COUNT(DISTINCT bt.book_id) AS unique_books_borrowed
FROM borrow_transactions bt
GROUP BY DATE_FORMAT(bt.borrow_date, '%Y-%m')
ORDER BY month DESC;

CREATE OR REPLACE VIEW vw_library_dashboard AS
SELECT
    (SELECT COUNT(*) FROM students) AS total_students,
    (SELECT COUNT(*) FROM students WHERE status = 'ACTIVE') AS active_students,
    (SELECT COUNT(*) FROM students WHERE status = 'INACTIVE') AS inactive_students,
    (SELECT COUNT(*) FROM books) AS total_books,
    (SELECT SUM(total_copies) FROM books) AS total_copies,
    (SELECT SUM(available_copies) FROM books) AS available_copies,
    (SELECT SUM(total_copies) - SUM(available_copies) FROM books) AS copies_in_circulation,
    (SELECT COUNT(*) FROM borrow_transactions WHERE status = 'BORROWED') AS currently_borrowed,
    (SELECT COUNT(*) FROM borrow_transactions WHERE status = 'OVERDUE') AS currently_overdue,
    (SELECT COUNT(*) FROM borrow_transactions WHERE status = 'RETURNED') AS total_returned,
    (SELECT COALESCE(SUM(fine_amount), 0) FROM borrow_transactions) AS total_fines_revenue,
    (SELECT COALESCE(SUM(fine_amount), 0) FROM borrow_transactions WHERE status = 'OVERDUE') AS outstanding_fines,
    (SELECT COUNT(*) FROM book_reservations WHERE status = 'PENDING') AS pending_reservations,
    (SELECT COUNT(DISTINCT student_id) FROM borrow_transactions WHERE borrow_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)) AS active_borrowers_last_30_days;

CREATE OR REPLACE VIEW vw_department_analytics AS
SELECT
    s.department,
    COUNT(DISTINCT s.student_id) AS total_students,
    COUNT(DISTINCT CASE WHEN s.status = 'ACTIVE' THEN s.student_id END) AS active_students,
    COUNT(bt.transaction_id) AS total_borrows,
    ROUND(COUNT(bt.transaction_id) * 1.0 / NULLIF(COUNT(DISTINCT s.student_id), 0), 2) AS avg_borrows_per_student,
    COALESCE(SUM(bt.fine_amount), 0) AS total_fines,
    COUNT(CASE WHEN bt.status = 'OVERDUE' THEN 1 END) AS overdue_count,
    COUNT(CASE WHEN bt.status = 'RETURNED' AND bt.fine_amount = 0 THEN 1 END) AS on_time_returns
FROM students s
LEFT JOIN borrow_transactions bt ON s.student_id = bt.student_id
GROUP BY s.department
ORDER BY total_borrows DESC;

CREATE OR REPLACE VIEW vw_book_popularity AS
SELECT
    b.book_id,
    b.title,
    b.author,
    b.genre,
    b.publish_year,
    COUNT(bt.transaction_id) AS borrow_count,
    COALESCE(ROUND(AVG(br.rating), 2), 0) AS avg_rating,
    COUNT(DISTINCT br.rating_id) AS total_ratings,
    b.available_copies,
    b.total_copies,
    CASE
        WHEN COUNT(bt.transaction_id) >= 10 THEN 'BESTSELLER'
        WHEN COUNT(bt.transaction_id) >= 5 THEN 'POPULAR'
        WHEN COUNT(bt.transaction_id) >= 2 THEN 'MODERATE'
        ELSE 'LOW DEMAND'
    END AS popularity_tier,
    DENSE_RANK() OVER (ORDER BY COUNT(bt.transaction_id) DESC) AS popularity_rank
FROM books b
LEFT JOIN borrow_transactions bt ON b.book_id = bt.book_id
LEFT JOIN book_ratings br ON b.book_id = br.book_id
GROUP BY b.book_id, b.title, b.author, b.genre, b.publish_year, b.available_copies, b.total_copies
ORDER BY borrow_count DESC, avg_rating DESC;

CREATE OR REPLACE VIEW vw_genre_distribution AS
SELECT
    b.genre,
    COUNT(DISTINCT b.book_id) AS total_titles,
    SUM(b.total_copies) AS total_copies,
    SUM(b.available_copies) AS available_copies,
    COUNT(bt.transaction_id) AS total_borrows,
    COUNT(DISTINCT bt.student_id) AS unique_readers,
    COALESCE(ROUND(AVG(br.rating), 2), 0) AS avg_genre_rating
FROM books b
LEFT JOIN borrow_transactions bt ON b.book_id = bt.book_id
LEFT JOIN book_ratings br ON b.book_id = br.book_id
GROUP BY b.genre
ORDER BY total_borrows DESC;

CREATE OR REPLACE VIEW vw_student_borrowing_profile AS
SELECT
    s.student_id,
    CONCAT(s.first_name, ' ', s.last_name) AS student_name,
    s.department,
    s.status,
    COUNT(bt.transaction_id) AS total_borrows,
    COUNT(CASE WHEN bt.status = 'RETURNED' THEN 1 END) AS returned,
    COUNT(CASE WHEN bt.status = 'BORROWED' THEN 1 END) AS currently_borrowed,
    COUNT(CASE WHEN bt.status = 'OVERDUE' THEN 1 END) AS overdue,
    COALESCE(SUM(bt.fine_amount), 0) AS total_fines,
    COALESCE(SUM(lp.points), 0) AS loyalty_points,
    MAX(bt.borrow_date) AS last_borrow_date,
    CASE
        WHEN COALESCE(SUM(lp.points), 0) >= 500 THEN 'PLATINUM'
        WHEN COALESCE(SUM(lp.points), 0) >= 200 THEN 'GOLD'
        WHEN COALESCE(SUM(lp.points), 0) >= 100 THEN 'SILVER'
        ELSE 'BRONZE'
    END AS loyalty_tier
FROM students s
LEFT JOIN borrow_transactions bt ON s.student_id = bt.student_id
LEFT JOIN loyalty_points lp ON s.student_id = lp.student_id
GROUP BY s.student_id, s.first_name, s.last_name, s.department, s.status
ORDER BY total_borrows DESC;
