-- ==============================================================================
-- DBMS BANKING SYSTEM - USEFUL QUERIES FOR DEMO/VIVA
-- ==============================================================================

-- 1. View all customers with their total account balance
SELECT 
    c.Customer_ID, 
    c.First_Name || ' ' || c.Last_Name AS Full_Name, 
    c.Phone, 
    COUNT(a.Account_Number) AS Total_Accounts,
    SUM(a.Balance) AS Total_Balance
FROM CUSTOMERS c
LEFT JOIN ACCOUNTS a ON c.Customer_ID = a.Customer_ID
GROUP BY c.Customer_ID, c.First_Name, c.Last_Name, c.Phone
ORDER BY c.Customer_ID;

-- 2. View full details of a specific account with branch info
SELECT 
    a.Account_Number, 
    c.First_Name || ' ' || c.Last_Name AS Owner, 
    a.Account_Type, 
    a.Balance, 
    a.Status, 
    b.Name AS Branch_Name
FROM ACCOUNTS a
JOIN CUSTOMERS c ON a.Customer_ID = c.Customer_ID
JOIN BRANCHES b ON a.Branch_ID = b.Branch_ID
WHERE a.Status = 'ACTIVE';

-- 3. View recent transactions for a specific account (e.g., Account 10000)
SELECT 
    Transaction_ID, 
    Tx_Date, 
    Tx_Type, 
    Amount, 
    Description, 
    Ref_Account_Number
FROM TRANSACTIONS
WHERE Account_Number = 10000
ORDER BY Tx_Date DESC;

-- 4. Find branches with the highest total deposits (balances)
SELECT 
    b.Name AS Branch_Name, 
    b.City, 
    SUM(a.Balance) AS Total_Deposits
FROM BRANCHES b
JOIN ACCOUNTS a ON b.Branch_ID = a.Branch_ID
GROUP BY b.Name, b.City
ORDER BY Total_Deposits DESC;

-- 5. List pending loans with customer details
SELECT 
    l.Loan_ID, 
    c.First_Name || ' ' || c.Last_Name AS Customer_Name, 
    l.Loan_Amount, 
    l.Interest_Rate, 
    l.Apply_Date
FROM LOANS l
JOIN CUSTOMERS c ON l.Customer_ID = c.Customer_ID
WHERE l.Status = 'PENDING';

-- 6. View the transaction history (statement) for a specific user joining across tables
SELECT 
    t.Tx_Date,
    a.Account_Number,
    t.Tx_Type,
    t.Amount,
    t.Description
FROM TRANSACTIONS t
JOIN ACCOUNTS a ON t.Account_Number = a.Account_Number
JOIN CUSTOMERS c ON a.Customer_ID = c.Customer_ID
WHERE c.First_Name = 'Alice' AND c.Last_Name = 'Smith'
ORDER BY t.Tx_Date DESC;
