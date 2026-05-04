/* ==============================================================================
   DBMS BANKING SYSTEM - JAVASCRIPT FRONTEND
   Fixed for XAMPP MySQL columns: TX_TYPE and TX_DATE
   ============================================================================== */

const API_BASE = 'http://localhost:3000/api';

document.addEventListener('DOMContentLoaded', () => {
    refreshAllData();
});

function money(value) {
    const num = parseFloat(value);
    if (isNaN(num)) return "₹0.00";
    return "₹" + num.toFixed(2);
}

function safeDate(value) {
    if (!value) return '';
    return new Date(value).toLocaleString();
}

function getVal(obj, ...keys) {
    if (!obj) return '';

    for (let key of keys) {
        if (obj[key] !== undefined && obj[key] !== null) {
            return obj[key];
        }
    }

    return '';
}

async function refreshAllData() {
    await updateDashboard();
    await renderTables();
}

/* ---------------- NAVIGATION ---------------- */

function showSection(sectionId) {
    document.querySelectorAll('.nav-links li').forEach(li => li.classList.remove('active'));

    const clickedItem = Array.from(document.querySelectorAll('.nav-links li'))
        .find(li => li.getAttribute('onclick')?.includes(sectionId));

    if (clickedItem) clickedItem.classList.add('active');

    document.querySelectorAll('.content-section').forEach(sec => sec.classList.remove('active'));

    const section = document.getElementById(sectionId);
    if (section) section.classList.add('active');

    const titleMap = {
        dashboard: 'Dashboard',
        customers: 'Customer Management',
        accounts: 'Account Management',
        transactions: 'Transactions',
        loans: 'Loan Management'
    };

    document.getElementById('page-title').innerText = titleMap[sectionId] || 'Dashboard';

    refreshAllData();
}

/* ---------------- MODALS ---------------- */

function openModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) modal.style.display = 'flex';
}

function closeModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) modal.style.display = 'none';
}

window.onclick = function (event) {
    if (event.target.classList.contains('modal')) {
        event.target.style.display = 'none';
    }
};

/* ---------------- API ---------------- */

async function fetchAPI(endpoint, method = 'GET', body = null) {
    try {
        const options = {
            method,
            headers: { 'Content-Type': 'application/json' }
        };

        if (body) {
            options.body = JSON.stringify(body);
        }

        const res = await fetch(`${API_BASE}${endpoint}`, options);
        const data = await res.json();

        if (!res.ok) {
            throw new Error(data.error || 'API Error');
        }

        return data;

    } catch (err) {
        alert(err.message);
        throw err;
    }
}

/* ---------------- DASHBOARD ---------------- */

async function updateDashboard() {
    try {
        const data = await fetchAPI('/dashboard');

        document.getElementById('dash-customers').innerText = data.customers || 0;
        document.getElementById('dash-accounts').innerText = data.accounts || 0;
        document.getElementById('dash-balance').innerText = money(data.balance);
        document.getElementById('dash-loans').innerText = data.loans || 0;

        const tbody = document.querySelector('#dash-txn-table tbody');

        if (tbody) {
            tbody.innerHTML = '';

            (data.recentTransactions || []).forEach(txn => {
                tbody.innerHTML += `
                    <tr>
                        <td>${getVal(txn, 'TRANSACTION_ID')}</td>
                        <td>${getVal(txn, 'ACCOUNT_NUMBER')}</td>
                        <td>${getVal(txn, 'TX_TYPE', 'TRANSACTION_TYPE')}</td>
                        <td>${money(getVal(txn, 'AMOUNT'))}</td>
                        <td>${safeDate(getVal(txn, 'TX_DATE', 'TRANSACTION_DATE'))}</td>
                    </tr>
                `;
            });
        }

    } catch (e) {
        console.error('Dashboard error:', e);
    }
}

/* ---------------- TABLES ---------------- */

async function renderTables() {
    try {
        /* Customers */
        const custBody = document.querySelector('#customers-table tbody');

        if (custBody) {
            const customers = await fetchAPI('/customers');

            custBody.innerHTML = customers.map(c => `
                <tr>
                    <td>${getVal(c, 'CUSTOMER_ID')}</td>
                    <td>${getVal(c, 'FIRST_NAME')} ${getVal(c, 'LAST_NAME')}</td>
                    <td>${getVal(c, 'PHONE')}</td>
                    <td>${getVal(c, 'EMAIL')}</td>
                    <td><button class="btn small primary">View</button></td>
                </tr>
            `).join('');
        }

        /* Accounts */
        const accBody = document.querySelector('#accounts-table tbody');

        if (accBody) {
            const accounts = await fetchAPI('/accounts');

            accBody.innerHTML = accounts.map(a => {
                const accNo = getVal(a, 'ACCOUNT_NUMBER');
                const status = getVal(a, 'STATUS');

                return `
                    <tr>
                        <td>${accNo}</td>
                        <td>${getVal(a, 'CUSTOMER_ID')}</td>
                        <td>${getVal(a, 'ACCOUNT_TYPE')}</td>
                        <td>${money(getVal(a, 'BALANCE'))}</td>
                        <td><span class="badge ${String(status).toLowerCase()}">${status}</span></td>
                        <td>
                            <button class="btn small success"
                                onclick="openModal('depositModal'); document.getElementById('dep-acc').value='${accNo}'">
                                Deposit
                            </button>
                        </td>
                    </tr>
                `;
            }).join('');
        }

        /* Transactions */
        const txnBody = document.querySelector('#transactions-table tbody');

        if (txnBody) {
            const txns = await fetchAPI('/transactions');

            txnBody.innerHTML = txns.map(t => `
                <tr>
                    <td>${getVal(t, 'TRANSACTION_ID')}</td>
                    <td>${getVal(t, 'ACCOUNT_NUMBER')}</td>
                    <td>${getVal(t, 'TX_TYPE', 'TRANSACTION_TYPE')}</td>
                    <td>${money(getVal(t, 'AMOUNT'))}</td>
                    <td>${getVal(t, 'DESCRIPTION')}</td>
                    <td>${safeDate(getVal(t, 'TX_DATE', 'TRANSACTION_DATE'))}</td>
                </tr>
            `).join('');
        }

        /* Loans */
        const loanBody = document.querySelector('#loans-table tbody');

        if (loanBody) {
            const loans = await fetchAPI('/loans');

            loanBody.innerHTML = loans.map(l => {
                const status = getVal(l, 'STATUS');

                return `
                    <tr>
                        <td>${getVal(l, 'LOAN_ID')}</td>
                        <td>${getVal(l, 'CUSTOMER_ID')}</td>
                        <td>${getVal(l, 'BRANCH_ID')}</td>
                        <td>${money(getVal(l, 'LOAN_AMOUNT'))}</td>
                        <td>${Number(getVal(l, 'INTEREST_RATE') || 0).toFixed(2)}%</td>
                        <td><span class="badge ${String(status).toLowerCase()}">${status}</span></td>
                    </tr>
                `;
            }).join('');
        }

    } catch (e) {
        console.error('Render error:', e);
    }
}

/* ---------------- FORM SUBMISSIONS ---------------- */

async function handleCustomerSubmit(e) {
    e.preventDefault();

    const payload = {
        first: document.getElementById('cust-first').value,
        last: document.getElementById('cust-last').value,
        phone: document.getElementById('cust-phone').value,
        email: document.getElementById('cust-email').value
    };

    try {
        const res = await fetchAPI('/customers', 'POST', payload);
        alert(res.message);
        closeModal('customerModal');
        e.target.reset();
        refreshAllData();
    } catch (e) {}
}

async function handleAccountSubmit(e) {
    e.preventDefault();

    const payload = {
        custId: parseInt(document.getElementById('acc-cust-id').value),
        branch: document.getElementById('acc-branch').value,
        type: document.getElementById('acc-type').value
    };

    try {
        const res = await fetchAPI('/accounts', 'POST', payload);
        alert(res.message);
        closeModal('accountModal');
        e.target.reset();
        refreshAllData();
    } catch (e) {}
}

async function handleDeposit(e) {
    e.preventDefault();

    const payload = {
        accNo: parseInt(document.getElementById('dep-acc').value),
        amount: parseFloat(document.getElementById('dep-amt').value),
        desc: document.getElementById('dep-desc').value
    };

    try {
        const res = await fetchAPI('/deposit', 'POST', payload);
        alert(res.message);
        closeModal('depositModal');
        e.target.reset();
        refreshAllData();
    } catch (e) {}
}

async function handleWithdraw(e) {
    e.preventDefault();

    const payload = {
        accNo: parseInt(document.getElementById('with-acc').value),
        amount: parseFloat(document.getElementById('with-amt').value),
        desc: document.getElementById('with-desc').value
    };

    try {
        const res = await fetchAPI('/withdraw', 'POST', payload);
        alert(res.message);
        closeModal('withdrawModal');
        e.target.reset();
        refreshAllData();
    } catch (e) {}
}

async function handleTransfer(e) {
    e.preventDefault();

    const payload = {
        fromAcc: parseInt(document.getElementById('trf-from').value),
        toAcc: parseInt(document.getElementById('trf-to').value),
        amount: parseFloat(document.getElementById('trf-amt').value)
    };

    try {
        const res = await fetchAPI('/transfer', 'POST', payload);
        alert(res.message);
        closeModal('transferModal');
        e.target.reset();
        refreshAllData();
    } catch (e) {}
}

async function handleLoanSubmit(e) {
    e.preventDefault();

    const payload = {
        custId: parseInt(document.getElementById('loan-cust-id').value),
        branch: document.getElementById('loan-branch').value,
        amount: parseFloat(document.getElementById('loan-amt').value)
    };

    try {
        const res = await fetchAPI('/loans', 'POST', payload);
        alert(res.message);
        closeModal('loanModal');
        e.target.reset();
        refreshAllData();
    } catch (e) {}
}