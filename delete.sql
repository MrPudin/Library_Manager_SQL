-- Drop tables
DROP TABLE IF EXISTS "authors";
DROP TABLE IF EXISTS "books";
DROP TABLE IF EXISTS "members";
DROP TABLE IF EXISTS "loans";
DROP TABLE IF EXISTS "archived_loans";

-- Frop indexes
DROP INDEX IF EXISTS "index_authors_name";
DROP INDEX IF EXISTS "index_authors_lastName";
DROP INDEX IF EXISTS "index_books_title";
DROP INDEX IF EXISTS "index_books_genre";
DROP INDEX IF EXISTS "index_books_authorId_canLoan";
DROP INDEX IF EXISTS "index_members_name";
DROP INDEX IF EXISTS "index_members_lastName";
DROP INDEX IF EXISTS "index_loans_loanDate";
DROP INDEX IF EXISTS "index_loans_memberId_isActive";
DROP INDEX IF EXISTS "index_loans_bookId_isActive";
DROP INDEX IF EXISTS "index_archived_loans_memberId_bookId";

-- Drop triggers
DROP TRIGGER IF EXISTS "update_after_insert_book";
DROP TRIGGER IF EXISTS "set_book_on_loan";
DROP TRIGGER IF EXISTS "set_book_on_return";
DROP TRIGGER IF EXISTS "check_if_can_loan";
DROP TRIGGER IF EXISTS "delete_member";

-- Drop views
DROP VIEW IF EXISTS "view_authors_and_books_info";
DROP VIEW IF EXISTS "view_books_on_loan";
DROP VIEW IF EXISTS "view_available_books";
DROP VIEW IF EXISTS "view_books_loan_status";
DROP VIEW IF EXISTS "view_member_loan_counts";
DROP VIEW IF EXISTS "view_recent_books";
DROP VIEW IF EXISTS "view_recent_authors";
DROP VIEW IF EXISTS "view_top_100_books_all_time";
DROP VIEW IF EXISTS "view_top_100_books_last_year";

-- Clean up unused space
VACUUM;
