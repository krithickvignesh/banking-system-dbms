-- ==============================================================================
-- DBMS BANKING SYSTEM - SCHEMA DEFINITION (Oracle 10g Compatible)
-- ==============================================================================

-- Drop tables and sequences if they already exist (useful for re-running)
BEGIN
   EXECUTE IMMEDIATE 'DROP SEQUENCE seq_customers';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP SEQUENCE seq_accounts';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP SEQUENCE seq_transactions';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP SEQUENCE seq_loans';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE TRANSACTIONS CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE LOANS CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE ACCOUNTS CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE CUSTOMERS CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE BRANCHES CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- ==============================================================================
-- 1. SEQUENCES
-- ==============================================================================

CREATE SEQUENCE seq_customers START WITH 1000 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_accounts START WITH 10000 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_transactions START WITH 50000 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_loans START WITH 2000 INCREMENT BY 1 NOCACHE;

-- ==============================================================================
-- 2. TABLES
-- ==============================================================================

-- Branches Table
CREATE TABLE BRANCHES (
    Branch_ID VARCHAR2(10) PRIMARY KEY,
    Name VARCHAR2(100) NOT NULL,
    City VARCHAR2(50) NOT NULL,
    Phone VARCHAR2(15) UNIQUE
);

-- Customers Table
CREATE TABLE CUSTOMERS (
    Customer_ID NUMBER PRIMARY KEY,
    First_Name VARCHAR2(50) NOT NULL,
    Last_Name VARCHAR2(50) NOT NULL,
    Phone VARCHAR2(15) UNIQUE NOT NULL,
    Email VARCHAR2(100) UNIQUE,
    Address VARCHAR2(255),
    Join_Date DATE DEFAULT SYSDATE
);

-- Accounts Table
CREATE TABLE ACCOUNTS (
    Account_Number NUMBER PRIMARY KEY,
    Customer_ID NUMBER NOT NULL,
    Branch_ID VARCHAR2(10) NOT NULL,
    Account_Type VARCHAR2(20) CHECK (Account_Type IN ('SAVINGS', 'CURRENT', 'SALARY')),
    Balance NUMBER(15, 2) DEFAULT 0 CHECK (Balance >= 0),
    Status VARCHAR2(10) DEFAULT 'ACTIVE' CHECK (Status IN ('ACTIVE', 'CLOSED', 'BLOCKED')),
    Open_Date DATE DEFAULT SYSDATE,
    -- Foreign Key constraints
    CONSTRAINT fk_acc_customer FOREIGN KEY (Customer_ID) REFERENCES CUSTOMERS(Customer_ID) ON DELETE CASCADE,
    CONSTRAINT fk_acc_branch FOREIGN KEY (Branch_ID) REFERENCES BRANCHES(Branch_ID)
);

-- Transactions Table
CREATE TABLE TRANSACTIONS (
    Transaction_ID NUMBER PRIMARY KEY,
    Account_Number NUMBER NOT NULL,
    Tx_Type VARCHAR2(20) CHECK (Tx_Type IN ('DEPOSIT', 'WITHDRAWAL', 'TRANSFER_IN', 'TRANSFER_OUT')),
    Amount NUMBER(15, 2) NOT NULL CHECK (Amount > 0),
    Tx_Date TIMESTAMP DEFAULT SYSTIMESTAMP,
    Description VARCHAR2(255),
    -- Related Account (Optional, for transfers)
    Ref_Account_Number NUMBER,
    -- Foreign Key constraint
    CONSTRAINT fk_txn_account FOREIGN KEY (Account_Number) REFERENCES ACCOUNTS(Account_Number) ON DELETE CASCADE
);

-- Loans Table
CREATE TABLE LOANS (
    Loan_ID NUMBER PRIMARY KEY,
    Customer_ID NUMBER NOT NULL,
    Branch_ID VARCHAR2(10) NOT NULL,
    Loan_Amount NUMBER(15, 2) NOT NULL CHECK (Loan_Amount > 0),
    Interest_Rate NUMBER(5, 2) NOT NULL CHECK (Interest_Rate >= 0),
    Status VARCHAR2(20) DEFAULT 'PENDING' CHECK (Status IN ('PENDING', 'APPROVED', 'REJECTED', 'PAID_OFF')),
    Apply_Date DATE DEFAULT SYSDATE,
    -- Foreign Key constraints
    CONSTRAINT fk_loan_customer FOREIGN KEY (Customer_ID) REFERENCES CUSTOMERS(Customer_ID) ON DELETE CASCADE,
    CONSTRAINT fk_loan_branch FOREIGN KEY (Branch_ID) REFERENCES BRANCHES(Branch_ID)
);

-- ==============================================================================
-- 3. TRIGGERS FOR AUTO-GENERATED PRIMARY KEYS
-- ==============================================================================

-- Trigger to auto-generate Customer_ID
CREATE OR REPLACE TRIGGER TRG_CUSTOMERS_ID
BEFORE INSERT ON CUSTOMERS
FOR EACH ROW
WHEN (NEW.Customer_ID IS NULL)
BEGIN
  SELECT seq_customers.NEXTVAL INTO :NEW.Customer_ID FROM DUAL;
END;
/

-- Trigger to auto-generate Account_Number
CREATE OR REPLACE TRIGGER TRG_ACCOUNTS_ID
BEFORE INSERT ON ACCOUNTS
FOR EACH ROW
WHEN (NEW.Account_Number IS NULL)
BEGIN
  SELECT seq_accounts.NEXTVAL INTO :NEW.Account_Number FROM DUAL;
END;
/

-- Trigger to auto-generate Transaction_ID
CREATE OR REPLACE TRIGGER TRG_TRANSACTIONS_ID
BEFORE INSERT ON TRANSACTIONS
FOR EACH ROW
WHEN (NEW.Transaction_ID IS NULL)
BEGIN
  SELECT seq_transactions.NEXTVAL INTO :NEW.Transaction_ID FROM DUAL;
END;
/

-- Trigger to auto-generate Loan_ID
CREATE OR REPLACE TRIGGER TRG_LOANS_ID
BEFORE INSERT ON LOANS
FOR EACH ROW
WHEN (NEW.Loan_ID IS NULL)
BEGIN
  SELECT seq_loans.NEXTVAL INTO :NEW.Loan_ID FROM DUAL;
END;
/

COMMIT;
