USE library_db;
CREATE TABLE students (
    student_id INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20),
    department VARCHAR(100),
    enrollment_date DATE,
    status ENUM('ACTIVE', 'INACTIVE') DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
CREATE TABLE books (
    book_id INT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    author VARCHAR(150) NOT NULL,
    genre VARCHAR(50),
    isbn VARCHAR(20) NOT NULL UNIQUE,
    publisher VARCHAR(150),
    publish_year INT,
    total_copies INT DEFAULT 1,
    available_copies INT DEFAULT 1,
    book_condition ENUM('NEW', 'GOOD', 'FAIR', 'POOR', 'DAMAGED') DEFAULT 'GOOD',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
CREATE TABLE borrow_transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    book_id INT NOT NULL,
    borrow_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE,
    fine_amount DECIMAL(10,2) DEFAULT 0.00,
    renewal_count INT DEFAULT 0,
    status ENUM('BORROWED', 'RETURNED', 'OVERDUE') DEFAULT 'BORROWED',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
CREATE TABLE audit_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    action_type ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    performed_by VARCHAR(100),
    action_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    old_data JSON,
    new_data JSON
);

CREATE TABLE book_reservations (
    reservation_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    book_id INT NOT NULL,
    reservation_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    expiry_date DATETIME,
    status ENUM('PENDING', 'FULFILLED', 'CANCELLED', 'EXPIRED') DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE book_ratings (
    rating_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    book_id INT NOT NULL,
    rating TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review TEXT,
    rated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE loyalty_points (
    point_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    points INT NOT NULL,
    reason VARCHAR(200),
    transaction_id INT,
    earned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    message TEXT NOT NULL,
    notification_type ENUM('OVERDUE', 'RESERVATION', 'FINE', 'RETURN_REMINDER', 'GENERAL') NOT NULL,
    is_read TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
