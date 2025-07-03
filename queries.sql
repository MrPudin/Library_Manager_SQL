-- In this SQL file, write (and comment!) the typical SQL queries users will run on your database

--**Writing Data Querries**

--Add new Author Operation
INSERT INTO "authors" ("name")
VALUES ('Miguel de Cervantes');

INSERT INTO "authors" ("name", "lastName")
VALUES ('Dmitri', 'Glukhovsky');

--Add new Book Operation
INSERT INTO "books" ("title", "genre", "authorId")
VALUES ('El Quijote', "satire", 1);

--Add new Member Operation
INSERT INTO "members" ("name", "lastName", "address")
VALUES ('Cristian', 'Daranuta', '123 Dream Street Sun Building, 4th Floor Fantasy City, ZIP 45678 Imagination Country');

--Delete Member Operation
DELETE FROM "members"
WHERE "id" = 2;

--Loan Book Operation
INSERT INTO "loans" ("memberId", "bookId")
VALUES (1, 1);

--Return Book Operation
UPDATE "loans"
SET "isActive" = 0, "returnDate" = strftime('%Y-%m-%d', 'now')
WHERE "isActive" = 1
AND   "bookId" = (
    SELECT "id" FROM "books"
    WHERE "title" = 'El Quijote'
);

--Archive old loans operation
BEGIN TRANSACTION;
    --Move the old loans
    INSERT INTO "archived_loans" ("memberId", "bookId", "loanDate", "returnDate")
    SELECT "memberId", "bookId", "loanDate", "returnDate" FROM "loans"
    WHERE "returnDate" < date('now', '-365 days');

    --Delete the old loans
    DELETE FROM "loans"
    WHERE "returnDate" < date('now', '-365 days');
COMMIT;

--**Tipical Querries**

--AUTHOR MANAGEMENT QUERIES

-- See an author's info
SELECT "name", "lastName", "numBooks", "addedDate"
FROM "authors"
WHERE "name" LIKE "Miguel de%";

-- see all books by an author
SELECT "name", "lastName", "title", "genre", "isAvailable"
FROM "view_authors_and_books_info"
WHERE "name" LIKE "Miguel de%";

-- see all books by an author based on book title
SELECT "name", "lastName", "title", "genre", "isAvailable"
FROM "view_authors_and_books_info"
WHERE "authorId" = (
    SELECT "authorId"
    FROM "books"
    WHERE "title" LIKE "%Quijote%"
);

-- See an author by the book
SELECT "name", "lastName", "numBooks"
FROM "view_authors_and_books_info"
WHERE "authorId" = (
    SELECT "authorId"
    FROM "books"
    WHERE "title" LIKE "%Quijote%"
)
GROUP BY "authorId";

-- see all books by a recent author
SELECT "view_authors_and_books_info"."name", "view_authors_and_books_info"."lastName", "title", "genre", "isAvailable"
FROM "view_authors_and_books_info"
JOIN "view_recent_authors" ON "view_recent_authors"."id" = "view_authors_and_books_info"."authorId"
WHERE "authorId" = (
    SELECT "authorId"
    FROM "books"
    WHERE "title" LIKE "%Quijote%"
);

-- See the status of an author's books
SELECT "view_books_loan_status"."bookId", "view_books_loan_status"."title", "view_books_loan_status"."addedDate", "loanStatus"
FROM "view_books_loan_status"
JOIN "books" ON "books"."id" = "view_books_loan_status"."bookId"
WHERE "books"."authorId" = (
    SELECT "id"
    FROM "authors"
    WHERE "name" LIKE '%Cervantes%'
);

-- BOOK MANAGEMENT QUERIES

-- See all books by genre
SELECT "title", "authorId", "addedDate"
FROM "books"
WHERE "genre" = 'satire';

-- See the status of the books
SELECT *
FROM "view_books_loan_status";

-- See which books from an author are available
SELECT "title", "genre", "name", "lastName"
FROM "view_available_books"
WHERE "authorId" = (
    SELECT "authorId"
    FROM "books"
    WHERE "title" LIKE "%Quijote%"
);

-- See which books are on loan
SELECT *
FROM "view_books_on_loan";

-- See loan history of a specific book
SELECT "loans"."loanDate", "loans"."returnDate","members"."id" AS 'memberId', "members"."name", "members"."lastName", "books"."id" AS 'bookId', "books"."title", "books"."genre"
FROM "loans"
FULL JOIN "archived_loans" ON "archived_loans"."bookId" = "loans"."bookId"
JOIN "members" ON "loans"."memberId" = "members"."id"
JOIN "books" ON "loans"."bookId" = "books"."id"
WHERE "loans"."bookId" = 1
ORDER BY "loans"."loanDate" DESC, "archived_loans"."loanDate" DESC;


-- MEMBER MANAGEMENT QUERIES

-- See how many books members have
SELECT *
FROM "view_member_loan_counts";

SELECT *
FROM "view_member_loan_counts"
WHERE "id" = 1;

SELECT *
FROM "view_member_loan_counts"
WHERE "numBooksLoaned" = 3;

--QUERIES FOR NEWS AND STATISTICS

-- See what's new in books
SELECT "title", "genre", "name", "lastName", "addedDate", "status"
FROM "view_recent_books";

SELECT "title", "genre", "name", "lastName", "addedDate", "status"
FROM "view_recent_books"
WHERE "authorId" = 1;

-- See what's new in authors
SELECT *
FROM "view_recent_authors";

-- See the most read books in history
SELECT *
FROM "view_top_100_books_all_time";

-- See the most read books in the last year
SELECT *
FROM "view_top_100_books_last_year";
