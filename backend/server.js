require('dotenv').config({ path: __dirname + '/.env' });

const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise');
const path = require('path');

const app = express();
const port = 3000;

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, '../frontend')));

const db = mysql.createPool({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'banking_system',
    port: 3306
});

function norm(row) {
    const obj = {};
    for (let key in row) {
        obj[key.toUpperCase()] = row[key];
    }
    return obj;
}

app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, '../frontend/index.html'));
});

/* DASHBOARD */
app.get('/api/dashboard', async (req, res) => {
    try {
        const [[cust]] = await db.query(`SELECT COUNT(*) count FROM CUSTOMERS`);
        const [[acc]] = await db.query(`SELECT COUNT(*) count FROM ACCOUNTS`);
        const [[bal]] = await db.query(`SELECT IFNULL(SUM(BALANCE),0) total FROM ACCOUNTS`);
        const [[loan]] = await db.query(`SELECT COUNT(*) count FROM LOANS`);
        const [recent] = await db.query(`SELECT * FROM TRANSACTIONS ORDER BY TRANSACTION_ID DESC LIMIT 5`);

        res.json({
            customers: cust.count,
            accounts: acc.count,
            balance: bal.total,
            loans: loan.count,
            recentTransactions: recent.map(norm)
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/* CUSTOMERS */
app.get('/api/customers', async (req, res) => {
    try {
        const [rows] = await db.query(`SELECT * FROM CUSTOMERS`);
        res.json(rows.map(norm));
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/api/customers', async (req, res) => {
    const { first, last, phone, email } = req.body;

    try {
        await db.query(
            `INSERT INTO CUSTOMERS (FIRST_NAME, LAST_NAME, PHONE, EMAIL, ADDRESS)
             VALUES (?, ?, ?, ?, ?)`,
            [first, last, phone, email, 'N/A']
        );

        res.json({ success: true, message: 'Customer added successfully' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/* ACCOUNTS */
app.get('/api/accounts', async (req, res) => {
    try {
        const [rows] = await db.query(`SELECT * FROM ACCOUNTS`);
        res.json(rows.map(norm));
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/api/accounts', async (req, res) => {
    const { custId, branch, type } = req.body;

    try {
        await db.query(
            `INSERT INTO ACCOUNTS (CUSTOMER_ID, BRANCH_ID, ACCOUNT_TYPE, BALANCE, STATUS)
             VALUES (?, ?, ?, 0, 'ACTIVE')`,
            [custId, branch, type]
        );

        res.json({ success: true, message: 'Account created successfully' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/* TRANSACTIONS */
app.get('/api/transactions', async (req, res) => {
    try {
        const [rows] = await db.query(`SELECT * FROM TRANSACTIONS ORDER BY TRANSACTION_ID DESC`);
        res.json(rows.map(norm));
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

/* DEPOSIT */
app.post('/api/deposit', async (req, res) => {
    const { accNo, amount, desc } = req.body;
    const conn = await db.getConnection();

    try {
        await conn.beginTransaction();

        await conn.query(
            `UPDATE ACCOUNTS SET BALANCE = BALANCE + ? WHERE ACCOUNT_NUMBER = ?`,
            [amount, accNo]
        );

        await conn.query(
            `INSERT INTO TRANSACTIONS
             (ACCOUNT_NUMBER, TX_TYPE, AMOUNT, DESCRIPTION, TX_DATE)
             VALUES (?, 'DEPOSIT', ?, ?, NOW())`,
            [accNo, amount, desc || 'Cash Deposit']
        );

        await conn.commit();
        res.json({ success: true, message: 'Deposit successful' });
    } catch (err) {
        await conn.rollback();
        res.status(400).json({ error: err.message });
    } finally {
        conn.release();
    }
});

/* WITHDRAW */
app.post('/api/withdraw', async (req, res) => {
    const { accNo, amount, desc } = req.body;
    const conn = await db.getConnection();

    try {
        const [[acc]] = await conn.query(
            `SELECT BALANCE FROM ACCOUNTS WHERE ACCOUNT_NUMBER = ?`,
            [accNo]
        );

        if (!acc || parseFloat(acc.BALANCE) < parseFloat(amount)) {
            throw new Error('Insufficient Balance');
        }

        await conn.beginTransaction();

        await conn.query(
            `UPDATE ACCOUNTS SET BALANCE = BALANCE - ? WHERE ACCOUNT_NUMBER = ?`,
            [amount, accNo]
        );

        await conn.query(
            `INSERT INTO TRANSACTIONS
             (ACCOUNT_NUMBER, TX_TYPE, AMOUNT, DESCRIPTION, TX_DATE)
             VALUES (?, 'WITHDRAWAL', ?, ?, NOW())`,
            [accNo, amount, desc || 'ATM Withdrawal']
        );

        await conn.commit();
        res.json({ success: true, message: 'Withdrawal successful' });
    } catch (err) {
        await conn.rollback();
        res.status(400).json({ error: err.message });
    } finally {
        conn.release();
    }
});

/* TRANSFER */
app.post('/api/transfer', async (req, res) => {
    const { fromAcc, toAcc, amount } = req.body;
    const conn = await db.getConnection();

    try {
        await conn.beginTransaction();

        const [[fromAccount]] = await conn.query(
            `SELECT BALANCE FROM ACCOUNTS WHERE ACCOUNT_NUMBER = ?`,
            [fromAcc]
        );

        const [[toAccount]] = await conn.query(
            `SELECT BALANCE FROM ACCOUNTS WHERE ACCOUNT_NUMBER = ?`,
            [toAcc]
        );

        if (!fromAccount) throw new Error('From account not found');
        if (!toAccount) throw new Error('To account not found');

        if (parseFloat(fromAccount.BALANCE) < parseFloat(amount)) {
            throw new Error('Insufficient Balance');
        }

        await conn.query(
            `UPDATE ACCOUNTS SET BALANCE = BALANCE - ? WHERE ACCOUNT_NUMBER = ?`,
            [amount, fromAcc]
        );

        await conn.query(
            `UPDATE ACCOUNTS SET BALANCE = BALANCE + ? WHERE ACCOUNT_NUMBER = ?`,
            [amount, toAcc]
        );

        await conn.query(
            `INSERT INTO TRANSACTIONS
             (ACCOUNT_NUMBER, TX_TYPE, AMOUNT, DESCRIPTION, TX_DATE)
             VALUES (?, 'TRANSFER_OUT', ?, ?, NOW())`,
            [fromAcc, amount, `Transfer to ${toAcc}`]
        );

        await conn.query(
            `INSERT INTO TRANSACTIONS
             (ACCOUNT_NUMBER, TX_TYPE, AMOUNT, DESCRIPTION, TX_DATE)
             VALUES (?, 'TRANSFER_IN', ?, ?, NOW())`,
            [toAcc, amount, `Transfer from ${fromAcc}`]
        );

        await conn.commit();
        res.json({ success: true, message: 'Transfer successful' });
    } catch (err) {
        await conn.rollback();
        res.status(400).json({ error: err.message });
    } finally {
        conn.release();
    }
});

/* LOANS */
app.get('/api/loans', async (req, res) => {
    try {
        const [rows] = await db.query(`SELECT * FROM LOANS`);
        res.json(rows.map(norm));
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/api/loans', async (req, res) => {
    const { custId, branch, amount } = req.body;

    try {
        await db.query(
            `INSERT INTO LOANS (CUSTOMER_ID, BRANCH_ID, LOAN_AMOUNT, INTEREST_RATE, STATUS)
             VALUES (?, ?, ?, 8.5, 'PENDING')`,
            [custId, branch, amount]
        );

        res.json({ success: true, message: 'Loan applied successfully' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.listen(port, () => {
    console.log(`Server running at http://localhost:${port}`);
    console.log('Connected to XAMPP MySQL');
});