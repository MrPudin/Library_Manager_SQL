-- In this SQL file, write (and comment!) the schema of your database, including the CREATE TABLE, CREATE INDEX, CREATE VIEW, etc. statements that compose it.re

--**TABLES**--

-- Table for Authors
CREATE TABLE  authors (
    "id" INTEGER,
    "name" TEXT NOT NULL,
    --in case of a nickname or pseudonym we will not use a last name
    "lastName" TEXT DEFAULT NULL,
    -- if he didn't write any book, he cannot be assigned the id of any book
    "numBooks" INTEGER DEFAULT 0 CHECK ("numBooks" >= 0),
    "addedDate" DATE DEFAULT (strftime('%Y-%m-%d', 'now')),
    PRIMARY KEY ("id")
);

-- Table for Books
CREATE TABLE books (
    "id" INTEGER,
    "title" TEXT NOT NULL,
    "genre" TEXT NOT NULL,
    "authorId" INTEGER,
    -- Check that the book is on loan
    "canLoan" INTEGER DEFAULT 1 CHECK ("canLoan" IN (0,1)),
    "addedDate" DATE DEFAULT (strftime('%Y-%m-%d', 'now')),
    PRIMARY KEY ("id"),
    FOREIGN KEY ("authorId") REFERENCES "authors"("id")
);

-- Table for Members
CREATE TABLE members (
    "id" INTEGER,
    "name" TEXT NOT NULL,
    "lastName" TEXT NOT NULL,
    "address" TEXT NOT NULL,
    "addedDate" DATE DEFAULT (strftime('%Y-%m-%d', 'now')),
    PRIMARY KEY ("id")
);

-- Table for Loans
CREATE TABLE loans (
    "memberId" INTEGER,
    "bookId" INTEGER,
    "loanDate" DATE DEFAULT (strftime('%Y-%m-%d', 'now')),
    "returnDate" DATE DEFAULT NULL,
    -- Soft deletion for the loan (1 if the book is on loan// 0 if the book was returned)
    "isActive" INTEGER DEFAULT 1 CHECK ("isActive" IN (0,1)),
    PRIMARY KEY ("memberId", "bookId"),
    -- If the member unsubscribes, the books on loan will be deleted from the member's account
    FOREIGN KEY ("memberId") REFERENCES "members"("id") ON DELETE SET NULL,
    FOREIGN KEY ("bookId") REFERENCES "books"("id")
);

-- Table fot Archived Loans
CREATE TABLE archived_loans (
    "memberId" INTEGER,
    "bookId" INTEGER,
    "loanDate" DATE NOT NULL,
    "returnDate" DATE NOT NULL,
    PRIMARY KEY ("memberId", "bookId"),
    -- If the member unsubscribes, the books on loan will be deleted from the member's account
    FOREIGN KEY ("memberId") REFERENCES "members"("id") ON DELETE SET NULL,
    FOREIGN KEY ("bookId") REFERENCES "books"("id")
);

--**INDEXES**--

-- Indexes for Authors
CREATE INDEX index_authors_name ON "authors"("name");
CREATE INDEX index_authors_lastName ON "authors"("lastName");

-- Indexes for Books
CREATE INDEX index_books_title ON "books"("title");
CREATE INDEX index_books_genre ON "books"("genre");
CREATE INDEX index_books_authorId_canLoan ON "books"("authorId", "canLoan");

-- Indexes for Members
CREATE INDEX index_members_name_lastName ON "members"("name", "lastName");

-- Indexes for Loans
CREATE INDEX index_loans_loanDate ON "loans"("loanDate");
CREATE INDEX index_loans_memberId_isActive ON "loans"("memberId", "isActive");
CREATE INDEX index_loans_bookId_isActive ON "loans"("bookId", "isActive");
CREATE INDEX index_archived_loans_memberId_bookId ON "archived_loans"("memberId", "bookId");

--**TRIGGERS**--

-- Update the number of the author's books
CREATE TRIGGER update_after_insert_book
AFTER INSERT ON "books"
BEGIN
    UPDATE "authors"
    SET "numBooks" = "numBooks" + 1
    WHERE "id" = NEW."authorId";
END;

-- Set that the book has been loaned
CREATE TRIGGER set_book_on_loan
BEFORE INSERT ON "loans"
BEGIN
    UPDATE "books"
    SET "canLoan" = 0
    WHERE "id" = NEW."bookID";
END;

-- Set that the book has been returned
CREATE TRIGGER set_book_on_return
AFTER UPDATE ON "loans"
FOR EACH ROW
WHEN NEW."isActive" = 0
BEGIN
    -- Update books table to mark the book as available for loan
    UPDATE "books"
    SET "canLoan" = 1
    WHERE "id" = NEW."bookId";
END;

CREATE TRIGGER check_if_can_loan
BEFORE INSERT ON "loans"
BEGIN
    -- Check if the book has been loaned before making another loan
    SELECT
    CASE
        -- Check if the book has been loaned before making another loan
        WHEN (SELECT "canLoan" FROM "books" WHERE "id" = NEW."bookId") = 0
        THEN RAISE(ABORT, 'This book is already on loan')

        -- Check if the member has been loaned more than three books
        WHEN (SELECT COUNT("memberId") FROM "loans" WHERE "memberId" = NEW."memberId" AND "isActive" = 1) = 3
        THEN RAISE(ABORT, 'This member is already three books on loan')
    END;
END;

-- We return the books if the member unsubscribes
CREATE TRIGGER delete_member
BEFORE DELETE ON "members"
BEGIN
    UPDATE "books"
    SET "canLoan" = 1
    WHERE "id" IN (
        SELECT "bookId" FROM "loans"
        WHERE "memberId" = OLD."id" AND "isActive" = 1
    );
END;

--**VIEWS**--

-- View to find out what books an author wrote
CREATE VIEW view_authors_and_books_info AS
SELECT
    "authors"."id" AS 'authorId',
    "authors"."name",
    "authors"."lastName",
    "authors"."numBooks",
    "books"."id" AS 'bookId',
    "books"."title", "books"."genre",
    "books"."canLoan" AS 'isAvailable'
FROM "authors"
JOIN "books" ON "books"."authorId" = "authors"."id";

-- View to know which books are on loan
CREATE VIEW view_books_on_loan AS
SELECT
    "books"."id" AS 'bookId',
    "books"."title",
    "members"."id",
    "members"."name" AS 'memberName',
    "members"."lastName",
    "loans"."loanDate" AS 'loanDate',
    date("loans"."loanDate", '+21 days') AS "spectedReturnDate"
FROM "books"
JOIN "loans" ON "loans"."bookId" = "books"."id"
JOIN "members" ON "members"."id" = "loans"."memberId"
WHERE "loans"."isActive" = 1;

-- View to know which books ara available
CREATE VIEW view_available_books AS
SELECT
    "books"."id" AS 'bookId',
    "books"."title",
    "books"."genre",
    "books"."addedDate",
    "authors"."id" AS 'authorId',
    "authors"."name",
    "authors"."lastName"
FROM "books"
JOIN "authors" ON "authors"."id" = "books"."authorId"
WHERE "books"."canLoan" = 1;

-- View to know the book status
CREATE VIEW view_books_loan_status AS
SELECT
    "id" AS 'bookId',
    "title",
    "addedDate",
    --This will cause a name to be assigned to the status of the book
    CASE
        WHEN "canLoan" = 0 THEN 'On Loan'
        ELSE 'Available'
    END AS 'loanStatus'
FROM "books";

-- View to see how many books each member has on loan
CREATE VIEW view_member_loan_counts AS
SELECT
    "members"."id",
    "members"."name",
    "members"."lastName",
    COUNT("loans"."memberId") AS "numBooksLoaned"
FROM "members"
JOIN "loans" ON "loans"."memberId" = "members"."id"
WHERE "loans"."isActive" = 1
GROUP BY "members"."id"
HAVING COUNT("loans"."memberId") > 0;

-- View to see recent added Books
CREATE VIEW view_recent_books AS
SELECT
    "books"."id" AS "bookId",
    "books"."title", "books"."genre",
    "authors"."id" AS 'authorId',
    "authors"."name",
    "authors"."lastName",
    "books"."addedDate",
    "view_books_loan_status"."loanStatus" AS 'status'
FROM "books"
JOIN "authors" ON "authors"."id" = "books"."authorId"
JOIN "view_books_loan_status" ON "view_books_loan_status"."bookId" = "books"."id"
WHERE "books"."addedDate" >= date('now', '-30 days');

-- View to see recent added Authors
CREATE VIEW view_recent_authors AS
SELECT
    "id",
    "name" AS 'authorName',
    "lastName" AS 'authorLastName',
    "numBooks" AS 'booksWritten',
    "addedDate" AS 'dateAdded'
FROM "authors"
WHERE "addedDate" >= date('now', '-30 days')
AND "numBooks" > 0;

-- View to see the most readed books in history
CREATE VIEW view_top_100_books_all_time AS
SELECT
    "books"."id" AS 'bookId',
    "books"."title",
    "books"."genre",
    (COUNT("loans"."bookId") + COUNT("archived_loans"."bookId")) AS 'numTimesLoaned'
FROM "books"
JOIN "loans" ON "loans"."bookId" = "books"."id"
JOIN "archived_loans" ON "archived_loans"."bookId" = "books"."id"
GROUP BY "books"."id", "books"."title", "books"."genre"
ORDER BY "numTimesLoaned" DESC LIMIT 100;

-- View to see the most readed books in last year
CREATE VIEW view_top_100_books_last_year AS
SELECT
    "books"."id" AS 'bookId',
    "books"."title",
    "books"."genre",
    COUNT("loans"."bookId") AS 'numTimesLoaned'
FROM "books"
JOIN "loans" ON "loans"."bookId" = "books"."id"
JOIN "archived_loans" ON "archived_loans"."bookId" = "books"."id"
GROUP BY "books"."id", "books"."title", "books"."genre"
ORDER BY "numTimesLoaned" DESC LIMIT 100;
