USE library_db;

DELIMITER //

CREATE TRIGGER trg_students_after_insert
AFTER INSERT ON students
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, action_type, performed_by, old_data, new_data)
    VALUES ('students', 'INSERT', CURRENT_USER(), NULL,
        JSON_OBJECT(
            'student_id', NEW.student_id,
            'first_name', NEW.first_name,
            'last_name', NEW.last_name,
            'email', NEW.email,
            'phone', NEW.phone,
            'department', NEW.department,
            'enrollment_date', NEW.enrollment_date,
            'status', NEW.status
        ));
END //

CREATE TRIGGER trg_students_after_update
AFTER UPDATE ON students
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, action_type, performed_by, old_data, new_data)
    VALUES ('students', 'UPDATE', CURRENT_USER(),
        JSON_OBJECT(
            'student_id', OLD.student_id,
            'first_name', OLD.first_name,
            'last_name', OLD.last_name,
            'email', OLD.email,
            'phone', OLD.phone,
            'department', OLD.department,
            'enrollment_date', OLD.enrollment_date,
            'status', OLD.status
        ),
        JSON_OBJECT(
            'student_id', NEW.student_id,
            'first_name', NEW.first_name,
            'last_name', NEW.last_name,
            'email', NEW.email,
            'phone', NEW.phone,
            'department', NEW.department,
            'enrollment_date', NEW.enrollment_date,
            'status', NEW.status
        ));
END //

CREATE TRIGGER trg_students_after_delete
AFTER DELETE ON students
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, action_type, performed_by, old_data, new_data)
    VALUES ('students', 'DELETE', CURRENT_USER(),
        JSON_OBJECT(
            'student_id', OLD.student_id,
            'first_name', OLD.first_name,
            'last_name', OLD.last_name,
            'email', OLD.email,
            'phone', OLD.phone,
            'department', OLD.department,
            'enrollment_date', OLD.enrollment_date,
            'status', OLD.status
        ), NULL);
END //

CREATE TRIGGER trg_books_after_insert
AFTER INSERT ON books
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, action_type, performed_by, old_data, new_data)
    VALUES ('books', 'INSERT', CURRENT_USER(), NULL,
        JSON_OBJECT(
            'book_id', NEW.book_id,
            'title', NEW.title,
            'author', NEW.author,
            'genre', NEW.genre,
            'isbn', NEW.isbn,
            'publisher', NEW.publisher,
            'total_copies', NEW.total_copies,
            'available_copies', NEW.available_copies,
            'book_condition', NEW.book_condition
        ));
END //

CREATE TRIGGER trg_books_after_update
AFTER UPDATE ON books
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, action_type, performed_by, old_data, new_data)
    VALUES ('books', 'UPDATE', CURRENT_USER(),
        JSON_OBJECT(
            'book_id', OLD.book_id,
            'title', OLD.title,
            'author', OLD.author,
            'available_copies', OLD.available_copies,
            'book_condition', OLD.book_condition
        ),
        JSON_OBJECT(
            'book_id', NEW.book_id,
            'title', NEW.title,
            'author', NEW.author,
            'available_copies', NEW.available_copies,
            'book_condition', NEW.book_condition
        ));
END //

CREATE TRIGGER trg_books_after_delete
AFTER DELETE ON books
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, action_type, performed_by, old_data, new_data)
    VALUES ('books', 'DELETE', CURRENT_USER(),
        JSON_OBJECT(
            'book_id', OLD.book_id,
            'title', OLD.title,
            'author', OLD.author,
            'isbn', OLD.isbn,
            'total_copies', OLD.total_copies,
            'available_copies', OLD.available_copies
        ), NULL);
END //

CREATE TRIGGER trg_borrow_after_insert
AFTER INSERT ON borrow_transactions
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, action_type, performed_by, old_data, new_data)
    VALUES ('borrow_transactions', 'INSERT', CURRENT_USER(), NULL,
        JSON_OBJECT(
            'transaction_id', NEW.transaction_id,
            'student_id', NEW.student_id,
            'book_id', NEW.book_id,
            'borrow_date', NEW.borrow_date,
            'due_date', NEW.due_date,
            'fine_amount', NEW.fine_amount,
            'status', NEW.status
        ));
END //

CREATE TRIGGER trg_borrow_after_update
AFTER UPDATE ON borrow_transactions
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, action_type, performed_by, old_data, new_data)
    VALUES ('borrow_transactions', 'UPDATE', CURRENT_USER(),
        JSON_OBJECT(
            'transaction_id', OLD.transaction_id,
            'student_id', OLD.student_id,
            'book_id', OLD.book_id,
            'borrow_date', OLD.borrow_date,
            'due_date', OLD.due_date,
            'return_date', OLD.return_date,
            'fine_amount', OLD.fine_amount,
            'renewal_count', OLD.renewal_count,
            'status', OLD.status
        ),
        JSON_OBJECT(
            'transaction_id', NEW.transaction_id,
            'student_id', NEW.student_id,
            'book_id', NEW.book_id,
            'borrow_date', NEW.borrow_date,
            'due_date', NEW.due_date,
            'return_date', NEW.return_date,
            'fine_amount', NEW.fine_amount,
            'renewal_count', NEW.renewal_count,
            'status', NEW.status
        ));
END //

CREATE TRIGGER trg_borrow_after_delete
AFTER DELETE ON borrow_transactions
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, action_type, performed_by, old_data, new_data)
    VALUES ('borrow_transactions', 'DELETE', CURRENT_USER(),
        JSON_OBJECT(
            'transaction_id', OLD.transaction_id,
            'student_id', OLD.student_id,
            'book_id', OLD.book_id,
            'borrow_date', OLD.borrow_date,
            'due_date', OLD.due_date,
            'return_date', OLD.return_date,
            'fine_amount', OLD.fine_amount,
            'status', OLD.status
        ), NULL);
END //

DELIMITER ;
