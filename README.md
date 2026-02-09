# 📚 Library Management System

A complete **MySQL database project** for managing library operations — designed and built entirely by **Siva**.

![MySQL](https://img.shields.io/badge/MySQL-8.0+-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen?style=for-the-badge)
![Tables](https://img.shields.io/badge/Tables-8-blue?style=for-the-badge)
![Procedures](https://img.shields.io/badge/Procedures-14-orange?style=for-the-badge)
![Views](https://img.shields.io/badge/Views-11-purple?style=for-the-badge)
![Tests](https://img.shields.io/badge/Tests-30-red?style=for-the-badge)

---

## 📋 Table of Contents

- [Features](#-features)
- [Tech Stack](#️-tech-stack)
- [Database Schema](#-database-schema)
- [ER Diagram](#-er-diagram)
- [Project Structure](#-project-structure)
- [How to Run](#-how-to-run)
- [Demo Commands](#-demo-commands)
- [Stored Procedures](#-stored-procedures)
- [Report Views](#-report-views)
- [Scheduled Events](#-scheduled-events)
- [What Makes This Advanced](#-what-makes-this-project-advanced)
- [Author](#-author)

---

## ✨ Features

| Category | Feature | Details |
|----------|---------|---------|
| 📖 **Core** | Student Management | 50 students, ACTIVE/INACTIVE tracking |
| 📖 **Core** | Book Catalog | 50 books, condition tracking (NEW / GOOD / FAIR / POOR / DAMAGED) |
| 🔄 **Transactions** | Borrow & Return | Max 5 books per student, 14-day borrowing period |
| 🔄 **Transactions** | Book Renewal | 7-day extension, max 2 renewals per transaction |
| 💰 **Fines** | Auto Fine Calculation | $1/day (days 1–7), $2/day (days 8+), $50 max cap |
| 📋 **Reservations** | Reservation Queue | FIFO fulfillment with 3-day auto-expiry |
| ⭐ **Ratings** | Rating & Reviews | 1–5 stars, only for borrowed books |
| 🏆 **Loyalty** | Rewards Program | BRONZE → SILVER → GOLD → PLATINUM tiers |
| 🤖 **Smart** | Book Recommendations | Genre-based, sorted by rating & popularity |
| 🔍 **Search** | Fulltext Search | Natural language search across titles and authors |
| 🔔 **Alerts** | Notifications | Overdue alerts, return reminders, reservation notices |
| 📝 **Audit** | Change Tracking | JSON-based logging for INSERT / UPDATE / DELETE |
| 📊 **Reports** | 11 Report Views | Dashboard, overdue, fines, popularity, department analytics |
| ⏰ **Automation** | 4 Scheduled Events | Daily fine updates, reminders, expiry + monthly checks |
| ✅ **Testing** | Validation Suite | 30 end-to-end tests |

---

## 🛠️ Tech Stack

| Component       | Details                                      |
|-----------------|----------------------------------------------|
| **Database**    | MySQL 8.0+                                   |
| **Tables**      | 8 normalized tables                          |
| **Procedures**  | 14 stored procedures with error handling      |
| **Functions**   | 1 deterministic function                      |
| **Triggers**    | 9 audit triggers (JSON logging)              |
| **Events**      | 4 scheduled events (cron jobs)               |
| **Views**       | 11 report views                              |
| **Indexes**     | 22+ performance indexes (including FULLTEXT) |

---

## 📐 Database Schema

| # | Table                  | Description                                          |
|---|------------------------|------------------------------------------------------|
| 1 | `students`             | Student registration with ACTIVE/INACTIVE status     |
| 2 | `books`                | Book catalog with condition tracking                 |
| 3 | `borrow_transactions`  | Borrowing records with renewal tracking              |
| 4 | `audit_log`            | JSON-based change tracking for all tables            |
| 5 | `book_reservations`    | FIFO reservation queue with auto-expiry              |
| 6 | `book_ratings`         | 1–5 star rating and review system                    |
| 7 | `loyalty_points`       | Points earned for on-time returns and reviews        |
| 8 | `notifications`        | Automated alerts (overdue, reminders, reservations)  |

---

## 🗺️ ER Diagram

```
┌──────────────────┐          ┌──────────────────────────┐
│     students     │          │          books            │
├──────────────────┤          ├──────────────────────────┤
│ PK student_id    │          │ PK book_id               │
│    first_name    │          │    title                  │
│    last_name     │          │    author                 │
│    email         │          │    genre                  │
│    department    │          │    total_copies           │
│    status        │          │    available_copies       │
│    join_date     │          │    book_condition         │
└──────┬───────────┘          └──────────┬───────────────┘
       │                                  │
       │  1:N                       1:N   │
       ▼                                  ▼
┌──────────────────────────────────────────────────┐
│              borrow_transactions                  │
├──────────────────────────────────────────────────┤
│ PK transaction_id                                 │
│ FK student_id  ──────────►  students              │
│ FK book_id     ──────────►  books                 │
│    borrow_date      │    return_date              │
│    due_date         │    fine_amount              │
│    renewal_count    │    status                   │
└──────────────────────────────────────────────────┘
       │                                  │
       │                                  │
       ▼                                  ▼
┌──────────────────┐    ┌──────────────────────────┐
│  loyalty_points  │    │      book_ratings         │
├──────────────────┤    ├──────────────────────────┤
│ PK loyalty_id    │    │ PK rating_id              │
│ FK student_id    │    │ FK student_id             │
│    points        │    │ FK book_id                │
│    reason        │    │    rating (1-5)           │
│    earned_date   │    │    review_text            │
└──────────────────┘    └──────────────────────────┘

┌──────────────────┐    ┌──────────────────────────┐
│ book_reservations│    │      notifications        │
├──────────────────┤    ├──────────────────────────┤
│ PK reservation_id│    │ PK notification_id        │
│ FK student_id    │    │ FK student_id             │
│ FK book_id       │    │    message                │
│    reserve_date  │    │    type                   │
│    status        │    │    is_read                │
│    expiry_date   │    │    created_at             │
└──────────────────┘    └──────────────────────────┘

┌──────────────────────────────────────────────────┐
│                   audit_log                       │
├──────────────────────────────────────────────────┤
│ PK log_id                                         │
│    table_name     │    operation (INSERT/UPDATE)   │
│    old_data (JSON)│    new_data (JSON)             │
│    changed_by     │    changed_at                  │
└──────────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
library-management-system/
│
├── run_all.sql                          # Master script — runs everything in order
├── demo_for_hr.sql                      # 25-step live demo script for showcasing
├── README.md                            # Project documentation
│
├── data/
│   ├── students.csv                     # 50 student records (cleaned & validated)
│   └── books.csv                        # 50 book records (cleaned & validated)
│
└── sql/
    ├── phase02_database_setup.sql       # Create database
    ├── phase03_table_design.sql         # Create 8 tables with constraints
    ├── phase04_keys_indexes.sql         # Foreign keys + 22 indexes
    ├── phase05_load_data.sql            # Load student & book data
    ├── phase06_transaction_flow.sql     # Borrow / Return / Renew procedures
    ├── phase07_fine_automation.sql       # Fine function + procedures
    ├── phase08_scheduler.sql            # 4 scheduled events (cron jobs)
    ├── phase09_audit_tracking.sql       # 9 audit triggers (JSON logging)
    ├── phase10_student_activity.sql     # Inactive student detection
    ├── phase11_reports.sql              # 11 report views
    ├── phase12_final_validation.sql     # 30 end-to-end tests
    └── special_features.sql             # Reservations, ratings, loyalty,
                                         # recommendations, search, notifications
```

---

## 🚀 How to Run

### Prerequisites
- MySQL 8.0 or higher
- MySQL Event Scheduler enabled (`SET GLOBAL event_scheduler = ON;`)

### Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/siva/library-management-system.git
cd library-management-system

# 2. Open MySQL terminal
mysql -u root -p

# 3. Run the complete setup (creates DB, tables, data, procedures, triggers, views)
SOURCE run_all.sql;
```

### Verify Installation

```sql
USE library_db;
SHOW TABLES;                              -- Should show 8 tables
SELECT * FROM vw_library_dashboard;       -- Full system overview
SHOW EVENTS FROM library_db;              -- 4 scheduled events
SHOW TRIGGERS FROM library_db;            -- 9 audit triggers
```

---

## 🎮 Demo Commands

### Quick Test
```sql
-- Borrow a book
CALL sp_borrow_book(1, 12);

-- Return a book
CALL sp_return_book(1);

-- Renew a book
CALL sp_renew_book(2);

-- Search books by keyword
CALL sp_search_books('Tolkien', NULL, 1);

-- Fulltext search (natural language)
CALL sp_fulltext_search_books('history time');

-- Rate a book (1-5 stars)
CALL sp_rate_book(1, 12, 5, 'Amazing book');

-- Get personalized recommendations
CALL sp_recommend_books(1, 5);

-- View student borrowing history
CALL sp_student_history(1);

-- Loyalty leaderboard
CALL sp_loyalty_leaderboard(10);
```

### Reports
```sql
SELECT * FROM vw_library_dashboard;       -- 📊 Library dashboard
SELECT * FROM vw_overdue_books;           -- ⚠️ Overdue books
SELECT * FROM vw_most_borrowed;           -- 📈 Popular books
SELECT * FROM vw_highest_fines;           -- 💰 Fine rankings
SELECT * FROM vw_department_analytics;    -- 🏢 Department stats
SELECT * FROM vw_genre_distribution;      -- 📚 Genre analysis
SELECT * FROM audit_log ORDER BY log_id DESC LIMIT 10;  -- 📝 Audit trail
```

> 💡 Run `SOURCE demo_for_hr.sql;` for a complete **25-step guided demo** — perfect for presentations!

---

## ⚙️ Stored Procedures

| # | Procedure | Purpose |
|---|-----------|---------|
| 1 | `sp_borrow_book(student_id, book_id)` | Borrow a book with validation |
| 2 | `sp_return_book(transaction_id)` | Return a book with fine calculation |
| 3 | `sp_renew_book(transaction_id)` | Extend due date by 7 days |
| 4 | `sp_search_books(keyword, genre, available)` | Search with filters |
| 5 | `sp_fulltext_search_books(search_text)` | Natural language search |
| 6 | `sp_rate_book(student, book, rating, review)` | Rate and review a book |
| 7 | `sp_recommend_books(student_id, limit)` | Personalized recommendations |
| 8 | `sp_student_history(student_id)` | Complete borrowing history |
| 9 | `sp_loyalty_leaderboard(limit)` | Top students by loyalty points |
| 10 | `sp_reserve_book(student_id, book_id)` | Reserve an unavailable book |
| 11 | `sp_update_overdue_fines()` | Recalculate all active fines |
| 12 | `sp_send_return_reminders()` | Send reminders for books due tomorrow |
| 13 | `sp_expire_reservations()` | Auto-expire old reservations |
| 14 | `sp_mark_inactive_students()` | Flag students with no activity |

---

## 📊 Report Views

| # | View | Description |
|---|------|-------------|
| 1 | `vw_library_dashboard` | Single-row overview of entire library |
| 2 | `vw_overdue_books` | Currently overdue books with days count |
| 3 | `vw_highest_fines` | Students ranked by total fines |
| 4 | `vw_most_borrowed` | Most popular books with popularity tier |
| 5 | `vw_student_status` | Active vs Inactive student breakdown |
| 6 | `vw_monthly_summary` | Monthly borrowing statistics |
| 7 | `vw_department_analytics` | Per-department borrowing patterns |
| 8 | `vw_book_popularity` | Book ranking with DENSE_RANK() |
| 9 | `vw_genre_distribution` | Genre-wise analysis |
| 10 | `vw_student_borrowing_profile` | Student profile with loyalty tier |
| 11 | `vw_fine_summary` | Fine severity distribution |

---

## ⏰ Scheduled Events (Cron Jobs)

| Event | Schedule | Action |
|-------|----------|--------|
| `evt_daily_fine_update` | Every day | Recalculates fines for overdue books |
| `evt_daily_return_reminder` | Every day | Sends reminders for books due tomorrow |
| `evt_daily_expire_reservations` | Every day | Expires reservations older than 3 days |
| `evt_monthly_inactive_check` | Every month | Marks students with no recent activity |

---

## 🔧 What Makes This Project Advanced

| Concept | Implementation |
|---------|---------------|
| **Modular Architecture** | 12 separate SQL files organized by phase |
| **Error Handling** | `SIGNAL SQLSTATE` in all 14 stored procedures |
| **Transaction Safety** | `START TRANSACTION` + `COMMIT` for data integrity |
| **JSON Audit Logging** | Old/new data stored as JSON (not plain text) |
| **Scheduled Automation** | MySQL `EVENT SCHEDULER` for daily/monthly tasks |
| **Tiered Fine System** | Multi-rate calculation with $50 cap |
| **Loyalty Gamification** | Points + tiers + leaderboard |
| **Reservation Queue** | FIFO with auto-expiry |
| **Fulltext Search** | `MATCH AGAINST` in natural language mode |
| **Window Functions** | `DENSE_RANK()`, `RANK()` for analytics |
| **Validation Suite** | 30 end-to-end tests covering all features |

---

## 💰 Fine Calculation Logic

```
Days Overdue    Rate            Example (10 days late)
─────────────   ──────────────  ─────────────────────
Days 1–7        $1.00 / day     7 × $1.00 = $7.00
Days 8+         $2.00 / day     3 × $2.00 = $6.00
                                ─────────────────
                Total:          $13.00
                Max Cap:        $50.00
```

**Fine Severity Levels:** `NONE` → `LOW` → `MEDIUM` → `HIGH` → `CRITICAL`

---

## 🏆 Loyalty Points System

| Action | Points Earned |
|--------|--------------|
| Return book on time | +10 points |
| Return within grace period | +5 points |
| Rate a book | +5 points |

| Tier | Points Required |
|------|----------------|
| 🥉 BRONZE | 0 – 49 |
| 🥈 SILVER | 50 – 149 |
| 🥇 GOLD | 150 – 299 |
| 💎 PLATINUM | 300+ |

---

## 👤 Author

**Siva**

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

<p align="center">
  ⭐ If you found this project useful, consider giving it a star!
</p>
