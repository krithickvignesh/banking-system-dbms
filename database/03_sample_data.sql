-- ==============================================================================
-- DBMS BANKING SYSTEM - SAMPLE DATA
-- ==============================================================================
-- Run this after schema.sql and procedures.sql

-- Clear old data (if any)
DELETE FROM LOANS;
DELETE FROM TRANSACTIONS;
DELETE FROM ACCOUNTS;
DELETE FROM CUSTOMERS;
DELETE FROM BRANCHES;
COMMIT;

-- ------------------------------------------------------------------------------
-- 1. INSERT BRANCHES
-- ------------------------------------------------------------------------------
INSERT INTO BRANCHES (Branch_ID, Name, City, Phone) VALUES ('BR001', 'Downtown Main', 'New York', '111-222-3333');
INSERT INTO BRANCHES (Branch_ID, Name, City, Phone) VALUES ('BR002', 'Westside Branch', 'Los Angeles', '444-555-6666');
INSERT INTO BRANCHES (Branch_ID, Name, City, Phone) VALUES ('BR003', 'Northpark Hub', 'Chicago', '777-888-9999');

-- ------------------------------------------------------------------------------
-- 2. INSERT CUSTOMERS (Using Sequence for ID)
-- ------------------------------------------------------------------------------
-- IDs will be generated starting from 1000 due to sequence
INSERT INTO CUSTOMERS (First_Name, Last_Name, Phone, Email, Address) VALUES ('Alice', 'Smith', '555-0101', 'alice@email.com', '123 Apple St, NY');
INSERT INTO CUSTOMERS (First_Name, Last_Name, Phone, Email, Address) VALUES ('Bob', 'Johnson', '555-0102', 'bob@email.com', '456 Banana Rd, LA');
INSERT INTO CUSTOMERS (First_Name, Last_Name, Phone, Email, Address) VALUES ('Charlie', 'Brown', '555-0103', 'charlie@email.com', '789 Cherry Blvd, CHI');
INSERT INTO CUSTOMERS (First_Name, Last_Name, Phone, Email, Address) VALUES ('Diana', 'Prince', '555-0104', 'diana@email.com', '321 Amazon Way, NY');
INSERT INTO CUSTOMERS (First_Name, Last_Name, Phone, Email, Address) VALUES ('Evan', 'Wright', '555-0105', 'evan@email.com', '654 Elm St, LA');

-- ------------------------------------------------------------------------------
-- 3. INSERT ACCOUNTS (Using Sequence for Account Number)
-- ------------------------------------------------------------------------------
-- Note: Assuming the sequence generated IDs 1000, 1001, 1002, 1003, 1004 for customers
INSERT INTO ACCOUNTS (Customer_ID, Branch_ID, Account_Type, Balance, Status) VALUES (1000, 'BR001', 'SAVINGS', 5000, 'ACTIVE');
INSERT INTO ACCOUNTS (Customer_ID, Branch_ID, Account_Type, Balance, Status) VALUES (1001, 'BR002', 'CURRENT', 12000, 'ACTIVE');
INSERT INTO ACCOUNTS (Customer_ID, Branch_ID, Account_Type, Balance, Status) VALUES (1002, 'BR003', 'SAVINGS', 850, 'ACTIVE');
INSERT INTO ACCOUNTS (Customer_ID, Branch_ID, Account_Type, Balance, Status) VALUES (1003, 'BR001', 'SALARY', 95000, 'ACTIVE');
INSERT INTO ACCOUNTS (Customer_ID, Branch_ID, Account_Type, Balance, Status) VALUES (1004, 'BR002', 'SAVINGS', 0, 'BLOCKED');

-- ------------------------------------------------------------------------------
-- 4. INSERT LOANS (Using Sequence for ID)
-- ------------------------------------------------------------------------------
INSERT INTO LOANS (Customer_ID, Branch_ID, Loan_Amount, Interest_Rate, Status) VALUES (1000, 'BR001', 15000, 8.5, 'APPROVED');
INSERT INTO LOANS (Customer_ID, Branch_ID, Loan_Amount, Interest_Rate, Status) VALUES (1002, 'BR003', 5000, 10.0, 'PENDING');
INSERT INTO LOANS (Customer_ID, Branch_ID, Loan_Amount, Interest_Rate, Status) VALUES (1003, 'BR001', 250000, 7.5, 'PAID_OFF');

COMMIT;

-- ------------------------------------------------------------------------------
-- 5. PERFORM SAMPLE TRANSACTIONS USING PROCEDURES
-- ------------------------------------------------------------------------------
-- Assuming the first account is 10000, the second is 10001, etc.
BEGIN
    -- Alice deposits $1000
    PR_DEPOSIT(10000, 1000, 'Salary Bonus');
    
    -- Bob withdraws $500
    PR_WITHDRAW(10001, 500, 'ATM Withdrawal');
    
    -- Diana transfers $2000 to Bob
    PR_TRANSFER(10003, 10001, 2000, 'Rent Payment');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error in sample transactions: ' || SQLERRM);
END;
/
