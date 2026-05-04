-- ==============================================================================
-- DBMS BANKING SYSTEM - PROCEDURES AND TRIGGERS
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. PROCEDURE: DEPOSIT MONEY
-- ------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE PR_DEPOSIT (
    p_account_no IN NUMBER,
    p_amount     IN NUMBER,
    p_desc       IN VARCHAR2 DEFAULT 'Cash Deposit'
) 
AS
    v_status VARCHAR2(10);
BEGIN
    -- Check if account exists and is active
    SELECT Status INTO v_status FROM ACCOUNTS WHERE Account_Number = p_account_no;
    
    IF v_status != 'ACTIVE' THEN
        RAISE_APPLICATION_ERROR(-20001, 'Account is not active.');
    END IF;

    IF p_amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Deposit amount must be greater than zero.');
    END IF;

    -- Update balance
    UPDATE ACCOUNTS
    SET Balance = Balance + p_amount
    WHERE Account_Number = p_account_no;

    -- Insert into transactions
    INSERT INTO TRANSACTIONS (Account_Number, Tx_Type, Amount, Description)
    VALUES (p_account_no, 'DEPOSIT', p_amount, p_desc);

    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20003, 'Account not found.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END PR_DEPOSIT;
/

-- ------------------------------------------------------------------------------
-- 2. PROCEDURE: WITHDRAW MONEY
-- ------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE PR_WITHDRAW (
    p_account_no IN NUMBER,
    p_amount     IN NUMBER,
    p_desc       IN VARCHAR2 DEFAULT 'Cash Withdrawal'
)
AS
    v_balance NUMBER;
    v_status  VARCHAR2(10);
BEGIN
    -- Check account status and balance
    SELECT Balance, Status INTO v_balance, v_status 
    FROM ACCOUNTS 
    WHERE Account_Number = p_account_no
    FOR UPDATE; -- Lock row to prevent concurrent issues
    
    IF v_status != 'ACTIVE' THEN
        RAISE_APPLICATION_ERROR(-20001, 'Account is not active.');
    END IF;

    IF p_amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Withdrawal amount must be greater than zero.');
    END IF;

    IF v_balance < p_amount THEN
        RAISE_APPLICATION_ERROR(-20004, 'Insufficient balance.');
    END IF;

    -- Update balance
    UPDATE ACCOUNTS
    SET Balance = Balance - p_amount
    WHERE Account_Number = p_account_no;

    -- Insert into transactions
    INSERT INTO TRANSACTIONS (Account_Number, Tx_Type, Amount, Description)
    VALUES (p_account_no, 'WITHDRAWAL', p_amount, p_desc);

    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20003, 'Account not found.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END PR_WITHDRAW;
/

-- ------------------------------------------------------------------------------
-- 3. PROCEDURE: TRANSFER MONEY
-- ------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE PR_TRANSFER (
    p_from_account IN NUMBER,
    p_to_account   IN NUMBER,
    p_amount       IN NUMBER,
    p_desc         IN VARCHAR2 DEFAULT 'Fund Transfer'
)
AS
    v_from_balance NUMBER;
    v_from_status  VARCHAR2(10);
    v_to_status    VARCHAR2(10);
BEGIN
    -- Basic validations
    IF p_from_account = p_to_account THEN
        RAISE_APPLICATION_ERROR(-20005, 'Cannot transfer to the same account.');
    END IF;

    IF p_amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Transfer amount must be greater than zero.');
    END IF;

    -- Lock both rows in a specific order to avoid deadlocks (smallest ID first)
    IF p_from_account < p_to_account THEN
        SELECT Balance, Status INTO v_from_balance, v_from_status FROM ACCOUNTS WHERE Account_Number = p_from_account FOR UPDATE;
        SELECT Status INTO v_to_status FROM ACCOUNTS WHERE Account_Number = p_to_account FOR UPDATE;
    ELSE
        SELECT Status INTO v_to_status FROM ACCOUNTS WHERE Account_Number = p_to_account FOR UPDATE;
        SELECT Balance, Status INTO v_from_balance, v_from_status FROM ACCOUNTS WHERE Account_Number = p_from_account FOR UPDATE;
    END IF;

    IF v_from_status != 'ACTIVE' OR v_to_status != 'ACTIVE' THEN
        RAISE_APPLICATION_ERROR(-20001, 'One or both accounts are not active.');
    END IF;

    IF v_from_balance < p_amount THEN
        RAISE_APPLICATION_ERROR(-20004, 'Insufficient balance for transfer.');
    END IF;

    -- Deduct from sender
    UPDATE ACCOUNTS
    SET Balance = Balance - p_amount
    WHERE Account_Number = p_from_account;

    -- Add to receiver
    UPDATE ACCOUNTS
    SET Balance = Balance + p_amount
    WHERE Account_Number = p_to_account;

    -- Insert outgoing transaction for sender
    INSERT INTO TRANSACTIONS (Account_Number, Tx_Type, Amount, Description, Ref_Account_Number)
    VALUES (p_from_account, 'TRANSFER_OUT', p_amount, p_desc, p_to_account);

    -- Insert incoming transaction for receiver
    INSERT INTO TRANSACTIONS (Account_Number, Tx_Type, Amount, Description, Ref_Account_Number)
    VALUES (p_to_account, 'TRANSFER_IN', p_amount, p_desc, p_from_account);

    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20003, 'One or both accounts not found.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END PR_TRANSFER;
/

-- ------------------------------------------------------------------------------
-- 4. FUNCTION: GET BALANCE
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION FN_GET_BALANCE (p_account_no IN NUMBER)
RETURN NUMBER
AS
    v_balance NUMBER;
BEGIN
    SELECT Balance INTO v_balance FROM ACCOUNTS WHERE Account_Number = p_account_no;
    RETURN v_balance;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN -1; -- Indicates account not found
END FN_GET_BALANCE;
/

-- ------------------------------------------------------------------------------
-- 5. TRIGGER: PREVENT NEGATIVE BALANCE UPDATE
-- ------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_PREVENT_NEGATIVE_BAL
BEFORE UPDATE OF Balance ON ACCOUNTS
FOR EACH ROW
BEGIN
    IF :NEW.Balance < 0 THEN
        RAISE_APPLICATION_ERROR(-20010, 'Balance cannot be negative. Update rejected.');
    END IF;
END;
/

-- ------------------------------------------------------------------------------
-- 6. PROCEDURE: APPLY LOAN
-- ------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE PR_APPLY_LOAN (
    p_customer_id IN NUMBER,
    p_branch_id   IN VARCHAR2,
    p_amount      IN NUMBER
)
AS
    v_interest NUMBER := 8.5; -- Default interest rate
BEGIN
    IF p_amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Loan amount must be greater than zero.');
    END IF;

    INSERT INTO LOANS (Customer_ID, Branch_ID, Loan_Amount, Interest_Rate, Status)
    VALUES (p_customer_id, p_branch_id, p_amount, v_interest, 'PENDING');
    
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END PR_APPLY_LOAN;
/
