USE library_db;

ALTER TABLE borrow_transactions
ADD CONSTRAINT fk_borrow_student
FOREIGN KEY (student_id) REFERENCES students(student_id)
ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE borrow_transactions
ADD CONSTRAINT fk_borrow_book
FOREIGN KEY (book_id) REFERENCES books(book_id)
ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE book_reservations
ADD CONSTRAINT fk_reservation_student
FOREIGN KEY (student_id) REFERENCES students(student_id)
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE book_reservations
ADD CONSTRAINT fk_reservation_book
FOREIGN KEY (book_id) REFERENCES books(book_id)
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE book_ratings
ADD CONSTRAINT fk_rating_student
FOREIGN KEY (student_id) REFERENCES students(student_id)
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE book_ratings
ADD CONSTRAINT fk_rating_book
FOREIGN KEY (book_id) REFERENCES books(book_id)
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE loyalty_points
ADD CONSTRAINT fk_loyalty_student
FOREIGN KEY (student_id) REFERENCES students(student_id)
ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE notifications
ADD CONSTRAINT fk_notification_student
FOREIGN KEY (student_id) REFERENCES students(student_id)
ON DELETE CASCADE ON UPDATE CASCADE;

CREATE INDEX idx_students_department ON students(department);
CREATE INDEX idx_students_status ON students(status);
CREATE INDEX idx_students_enrollment ON students(enrollment_date);

CREATE INDEX idx_books_genre ON books(genre);
CREATE INDEX idx_books_author ON books(author);
CREATE INDEX idx_books_title ON books(title);
CREATE INDEX idx_books_publish_year ON books(publish_year);

CREATE INDEX idx_borrow_student ON borrow_transactions(student_id);
CREATE INDEX idx_borrow_book ON borrow_transactions(book_id);
CREATE INDEX idx_borrow_status ON borrow_transactions(status);
CREATE INDEX idx_borrow_due_date ON borrow_transactions(due_date);
CREATE INDEX idx_borrow_return_date ON borrow_transactions(return_date);
CREATE INDEX idx_borrow_dates ON borrow_transactions(borrow_date, due_date, return_date);

CREATE INDEX idx_reservations_student ON book_reservations(student_id);
CREATE INDEX idx_reservations_book ON book_reservations(book_id);
CREATE INDEX idx_reservations_status ON book_reservations(status);

CREATE INDEX idx_ratings_book ON book_ratings(book_id);
CREATE INDEX idx_ratings_student ON book_ratings(student_id);

CREATE INDEX idx_loyalty_student ON loyalty_points(student_id);

CREATE INDEX idx_notifications_student ON notifications(student_id);
CREATE INDEX idx_notifications_type ON notifications(notification_type);
CREATE INDEX idx_notifications_read ON notifications(is_read);

CREATE INDEX idx_audit_table ON audit_log(table_name);
CREATE INDEX idx_audit_action ON audit_log(action_type);
CREATE INDEX idx_audit_time ON audit_log(action_time);

CREATE FULLTEXT INDEX idx_books_fulltext ON books(title, author);
