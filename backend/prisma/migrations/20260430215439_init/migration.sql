-- CreateEnum
CREATE TYPE "LoanRequestStatus" AS ENUM ('pending', 'approved', 'rejected', 'cancelled');

-- CreateEnum
CREATE TYPE "ReservationStatus" AS ENUM ('waiting', 'notified', 'expired', 'fulfilled', 'cancelled');

-- CreateEnum
CREATE TYPE "LoanStatus" AS ENUM ('active', 'returned', 'overdue');

-- CreateEnum
CREATE TYPE "SuggestionStatus" AS ENUM ('submitted', 'approved', 'rejected', 'under_review');

-- CreateEnum
CREATE TYPE "PeriodStatus" AS ENUM ('upcoming', 'active', 'closed');

-- CreateEnum
CREATE TYPE "AdminRole" AS ENUM ('admin', 'super_admin');

-- CreateTable
CREATE TABLE "books" (
    "id" TEXT NOT NULL,
    "title" VARCHAR(500) NOT NULL,
    "author" VARCHAR(200) NOT NULL,
    "isbn" VARCHAR(13),
    "category" VARCHAR(100) NOT NULL,
    "description" TEXT,
    "publicationYear" INTEGER,
    "quantity" INTEGER NOT NULL DEFAULT 1,
    "availableQuantity" INTEGER NOT NULL DEFAULT 1,
    "coverImageUrl" VARCHAR(500),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "books_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "students" (
    "id" TEXT NOT NULL,
    "fortytwoUserId" INTEGER NOT NULL,
    "username" VARCHAR(50) NOT NULL,
    "email" VARCHAR(255) NOT NULL,
    "fullName" VARCHAR(200) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastLoginAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "students_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "loan_requests" (
    "id" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "bookId" TEXT NOT NULL,
    "status" "LoanRequestStatus" NOT NULL DEFAULT 'pending',
    "requestDate" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "reviewedAt" TIMESTAMP(3),
    "reviewedBy" TEXT,
    "rejectionReason" TEXT,
    "notes" TEXT,

    CONSTRAINT "loan_requests_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "reservations" (
    "id" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "bookId" TEXT NOT NULL,
    "queuePosition" INTEGER NOT NULL,
    "status" "ReservationStatus" NOT NULL DEFAULT 'waiting',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "notifiedAt" TIMESTAMP(3),
    "expiresAt" TIMESTAMP(3),
    "fulfilledAt" TIMESTAMP(3),

    CONSTRAINT "reservations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "loans" (
    "id" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "bookId" TEXT NOT NULL,
    "loanRequestId" TEXT,
    "reservationId" TEXT,
    "status" "LoanStatus" NOT NULL DEFAULT 'active',
    "checkoutDate" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "dueDate" TIMESTAMP(3) NOT NULL,
    "returnedDate" TIMESTAMP(3),
    "approvedBy" TEXT NOT NULL,
    "notes" TEXT,

    CONSTRAINT "loans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "book_suggestions" (
    "id" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "suggestedTitle" VARCHAR(500) NOT NULL,
    "suggestedAuthor" VARCHAR(200) NOT NULL,
    "reason" TEXT,
    "collectionPeriodId" TEXT NOT NULL,
    "status" "SuggestionStatus" NOT NULL DEFAULT 'submitted',
    "submittedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "reviewedAt" TIMESTAMP(3),
    "reviewedBy" TEXT,
    "adminNotes" TEXT,

    CONSTRAINT "book_suggestions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "collection_periods" (
    "id" TEXT NOT NULL,
    "name" VARCHAR(100) NOT NULL,
    "startDate" TIMESTAMP(3) NOT NULL,
    "endDate" TIMESTAMP(3) NOT NULL,
    "status" "PeriodStatus" NOT NULL DEFAULT 'upcoming',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "collection_periods_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "administrators" (
    "id" TEXT NOT NULL,
    "username" VARCHAR(50) NOT NULL,
    "passwordHash" VARCHAR(255) NOT NULL,
    "email" VARCHAR(255) NOT NULL,
    "fullName" VARCHAR(200) NOT NULL,
    "role" "AdminRole" NOT NULL DEFAULT 'admin',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastLoginAt" TIMESTAMP(3),

    CONSTRAINT "administrators_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "books_isbn_key" ON "books"("isbn");

-- CreateIndex
CREATE INDEX "idx_book_search" ON "books"("title", "author");

-- CreateIndex
CREATE INDEX "idx_book_category" ON "books"("category");

-- CreateIndex
CREATE UNIQUE INDEX "students_fortytwoUserId_key" ON "students"("fortytwoUserId");

-- CreateIndex
CREATE INDEX "idx_student_42id" ON "students"("fortytwoUserId");

-- CreateIndex
CREATE INDEX "idx_loan_request_lookup" ON "loan_requests"("studentId", "bookId", "status");

-- CreateIndex
CREATE INDEX "idx_loan_request_status" ON "loan_requests"("status");

-- CreateIndex
CREATE INDEX "idx_reservation_queue" ON "reservations"("bookId", "queuePosition");

-- CreateIndex
CREATE INDEX "idx_reservation_status" ON "reservations"("status");

-- CreateIndex
CREATE UNIQUE INDEX "reservations_bookId_queuePosition_key" ON "reservations"("bookId", "queuePosition");

-- CreateIndex
CREATE UNIQUE INDEX "loans_loanRequestId_key" ON "loans"("loanRequestId");

-- CreateIndex
CREATE UNIQUE INDEX "loans_reservationId_key" ON "loans"("reservationId");

-- CreateIndex
CREATE INDEX "idx_loan_student" ON "loans"("studentId");

-- CreateIndex
CREATE INDEX "idx_loan_book" ON "loans"("bookId");

-- CreateIndex
CREATE INDEX "idx_loan_overdue" ON "loans"("status", "dueDate");

-- CreateIndex
CREATE INDEX "idx_suggestion_period" ON "book_suggestions"("collectionPeriodId", "status");

-- CreateIndex
CREATE INDEX "idx_suggestion_duplicate" ON "book_suggestions"("suggestedTitle", "suggestedAuthor");

-- CreateIndex
CREATE UNIQUE INDEX "collection_periods_name_key" ON "collection_periods"("name");

-- CreateIndex
CREATE INDEX "idx_period_status" ON "collection_periods"("status");

-- CreateIndex
CREATE INDEX "idx_period_dates" ON "collection_periods"("startDate", "endDate");

-- CreateIndex
CREATE UNIQUE INDEX "administrators_username_key" ON "administrators"("username");

-- CreateIndex
CREATE UNIQUE INDEX "administrators_email_key" ON "administrators"("email");

-- CreateIndex
CREATE INDEX "idx_admin_username" ON "administrators"("username");

-- AddForeignKey
ALTER TABLE "loan_requests" ADD CONSTRAINT "loan_requests_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "loan_requests" ADD CONSTRAINT "loan_requests_bookId_fkey" FOREIGN KEY ("bookId") REFERENCES "books"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "loan_requests" ADD CONSTRAINT "loan_requests_reviewedBy_fkey" FOREIGN KEY ("reviewedBy") REFERENCES "administrators"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reservations" ADD CONSTRAINT "reservations_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reservations" ADD CONSTRAINT "reservations_bookId_fkey" FOREIGN KEY ("bookId") REFERENCES "books"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "loans" ADD CONSTRAINT "loans_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "loans" ADD CONSTRAINT "loans_bookId_fkey" FOREIGN KEY ("bookId") REFERENCES "books"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "loans" ADD CONSTRAINT "loans_loanRequestId_fkey" FOREIGN KEY ("loanRequestId") REFERENCES "loan_requests"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "loans" ADD CONSTRAINT "loans_reservationId_fkey" FOREIGN KEY ("reservationId") REFERENCES "reservations"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "loans" ADD CONSTRAINT "loans_approvedBy_fkey" FOREIGN KEY ("approvedBy") REFERENCES "administrators"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "book_suggestions" ADD CONSTRAINT "book_suggestions_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "students"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "book_suggestions" ADD CONSTRAINT "book_suggestions_collectionPeriodId_fkey" FOREIGN KEY ("collectionPeriodId") REFERENCES "collection_periods"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "book_suggestions" ADD CONSTRAINT "book_suggestions_reviewedBy_fkey" FOREIGN KEY ("reviewedBy") REFERENCES "administrators"("id") ON DELETE SET NULL ON UPDATE CASCADE;
