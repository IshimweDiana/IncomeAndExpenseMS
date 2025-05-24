-- Set the session to the correct Pluggable Database (PDB)
-- This ensures we're working in the Tues_25408_Diane_ExpenseIncome_DB PDB for all operations
ALTER SESSION SET CONTAINER = Tues_25408_Diane_ExpenseIncome_DB;

-- Verify the user
SHOW USER;

-- Confirm CDB connection
SHOW CON_NAME;

-- PHASE 5: Create Tables and Insert Data

-- 1. Create Users Table
CREATE TABLE Users (
    user_id NUMBER GENERATED ALWAYS AS IDENTITY,
    username VARCHAR2(50) NOT NULL,
    password VARCHAR2(100) NOT NULL,
    role VARCHAR2(20) NOT NULL,
    email VARCHAR2(100),
    created_at DATE DEFAULT SYSDATE,
    CONSTRAINT pk_users PRIMARY KEY (user_id),
    CONSTRAINT uk_users_username UNIQUE (username),
    CONSTRAINT uk_users_email UNIQUE (email)
);

-- 2. Create Categories Table
CREATE TABLE Categories (
    category_id NUMBER GENERATED ALWAYS AS IDENTITY,
    category_name VARCHAR2(50) NOT NULL,
    category_type VARCHAR2(20) NOT NULL,
    description VARCHAR2(200),
    CONSTRAINT pk_categories PRIMARY KEY (category_id),
    CONSTRAINT chk_category_type CHECK (category_type IN ('Income', 'Expense'))
);

-- 3. Create Transactions Table
CREATE TABLE Transactions (
    transaction_id NUMBER GENERATED ALWAYS AS IDENTITY,
    user_id NUMBER NOT NULL,
    category_id NUMBER NOT NULL,
    amount NUMBER(10,2) NOT NULL,
    transaction_date DATE NOT NULL,
    description VARCHAR2(200),
    transaction_type VARCHAR2(20) NOT NULL,
    CONSTRAINT pk_transactions PRIMARY KEY (transaction_id),
    CONSTRAINT fk_transactions_user FOREIGN KEY (user_id) REFERENCES Users(user_id),
    CONSTRAINT fk_transactions_category FOREIGN KEY (category_id) REFERENCES Categories(category_id),
    CONSTRAINT chk_transaction_type CHECK (transaction_type IN ('Income', 'Expense')),
    CONSTRAINT chk_amount_positive CHECK (amount > 0)
);

-- 4. Create Budgets Table
CREATE TABLE Budgets (
    budget_id NUMBER GENERATED ALWAYS AS IDENTITY,
    user_id NUMBER NOT NULL,
    category_id NUMBER NOT NULL,
    budget_amount NUMBER(10,2) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    CONSTRAINT pk_budgets PRIMARY KEY (budget_id),
    CONSTRAINT fk_budgets_user FOREIGN KEY (user_id) REFERENCES Users(user_id),
    CONSTRAINT fk_budgets_category FOREIGN KEY (category_id) REFERENCES Categories(category_id),
    CONSTRAINT chk_budget_amount CHECK (budget_amount > 0),
    CONSTRAINT chk_date_range CHECK (end_date > start_date)
);

-- 5. Create Reports Table
CREATE TABLE Reports (
    report_id NUMBER GENERATED ALWAYS AS IDENTITY,
    user_id NUMBER NOT NULL,
    report_type VARCHAR2(50) NOT NULL,
    generated_at DATE DEFAULT SYSDATE,
    report_data CLOB,
    CONSTRAINT pk_reports PRIMARY KEY (report_id),
    CONSTRAINT fk_reports_user FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

-- 6. Create Holidays Table
CREATE TABLE Holidays (
    holiday_id NUMBER GENERATED ALWAYS AS IDENTITY,
    holiday_date DATE NOT NULL,
    holiday_name VARCHAR2(100) NOT NULL,
    CONSTRAINT pk_holidays PRIMARY KEY (holiday_id)
);

-- Create Indexes for Performance
CREATE INDEX idx_transactions_user ON Transactions(user_id);
CREATE INDEX idx_transactions_category ON Transactions(category_id);
CREATE INDEX idx_budgets_user ON Budgets(user_id);
CREATE INDEX idx_budgets_category ON Budgets(category_id);
CREATE INDEX idx_reports_user ON Reports(user_id);
CREATE INDEX idx_holidays_date ON Holidays(holiday_date);

-- Commit changes
COMMIT;

-- Insert Data
INSERT INTO Users (username, password, role, email) VALUES ('diane_admin', 'hashed_password_123', 'Admin', 'diane@example.com');
INSERT INTO Users (username, password, role, email) VALUES ('john_accountant', 'hashed_password_456', 'Accountant', 'john@example.com');
INSERT INTO Users (username, password, role, email) VALUES ('mary_user', 'hashed_password_789', 'User', 'mary@example.com');

INSERT INTO Categories (category_name, category_type, description) VALUES ('Salary', 'Income', 'Monthly salary income');
INSERT INTO Categories (category_name, category_type, description) VALUES ('Freelance', 'Income', 'Freelance project earnings');
INSERT INTO Categories (category_name, category_type, description) VALUES ('Rent', 'Expense', 'Monthly rent payment');
INSERT INTO Categories (category_name, category_type, description) VALUES ('Groceries', 'Expense', 'Weekly grocery shopping');

INSERT INTO Transactions (user_id, category_id, amount, transaction_date, description, transaction_type) 
VALUES (1, 1, 5000.00, TO_DATE('2025-05-01', 'YYYY-MM-DD'), 'May salary', 'Income');
INSERT INTO Transactions (user_id, category_id, amount, transaction_date, description, transaction_type) 
VALUES (1, 3, 1200.00, TO_DATE('2025-05-02', 'YYYY-MM-DD'), 'Apartment rent', 'Expense');
INSERT INTO Transactions (user_id, category_id, amount, transaction_date, description, transaction_type) 
VALUES (2, 2, 1500.00, TO_DATE('2025-05-03', 'YYYY-MM-DD'), 'Freelance project', 'Income');
INSERT INTO Transactions (user_id, category_id, amount, transaction_date, description, transaction_type) 
VALUES (3, 4, 300.00, TO_DATE('2025-05-04', 'YYYY-MM-DD'), 'Weekly groceries', 'Expense');

INSERT INTO Budgets (user_id, category_id, budget_amount, start_date, end_date) 
VALUES (1, 3, 1500.00, TO_DATE('2025-05-01', 'YYYY-MM-DD'), TO_DATE('2025-05-31', 'YYYY-MM-DD'));
INSERT INTO Budgets (user_id, category_id, budget_amount, start_date, end_date) 
VALUES (3, 4, 400.00, TO_DATE('2025-05-01', 'YYYY-MM-DD'), TO_DATE('2025-05-31', 'YYYY-MM-DD'));

INSERT INTO Reports (user_id, report_type, generated_at, report_data) 
VALUES (1, 'Monthly Summary', TO_DATE('2025-05-23', 'YYYY-MM-DD'), '{"total_income": 5000, "total_expense": 1200}');
INSERT INTO Reports (user_id, report_type, generated_at, report_data) 
VALUES (2, 'Income Analysis', TO_DATE('2025-05-23', 'YYYY-MM-DD'), '{"freelance_income": 1500}');

INSERT INTO Holidays (holiday_date, holiday_name) 
VALUES (TO_DATE('2025-05-01', 'YYYY-MM-DD'), 'Labor Day');
INSERT INTO Holidays (holiday_date, holiday_name) 
VALUES (TO_DATE('2025-12-25', 'YYYY-MM-DD'), 'Christmas Day');

-- Commit changes
COMMIT;

-- Verify Data

-- Verify Data in Users and Transactions
-- Calculates total income and expenses per user
SELECT 
    u.username,
    SUM(CASE WHEN t.transaction_type = 'Income' THEN t.amount ELSE 0 END) AS total_income,
    SUM(CASE WHEN t.transaction_type = 'Expense' THEN t.amount ELSE 0 END) AS total_expenses
FROM Users u
LEFT JOIN Transactions t ON u.user_id = t.user_id
GROUP BY u.username;
-- Verify Budgets and Spending
-- Compares budgeted amounts with actual spending for each budget
SELECT 
    b.budget_id,
    u.username,
    c.category_name,
    b.budget_amount,
    SUM(t.amount) AS actual_spent
FROM Budgets b
JOIN Users u ON b.user_id = u.user_id
JOIN Categories c ON b.category_id = c.category_id
LEFT JOIN Transactions t ON b.category_id = t.category_id 
    AND t.transaction_date BETWEEN b.start_date AND b.end_date
    AND t.transaction_type = 'Expense'
GROUP BY b.budget_id, u.username, c.category_name, b.budget_amount;
-- Verify Holidays
-- Retrieves holiday details for a specific date (Labor Day)
SELECT holiday_name, holiday_date
FROM Holidays
WHERE holiday_date = TO_DATE('2025-05-01', 'YYYY-MM-DD');

-- PHASE 6: Database Interaction and Transactions
--DDL Operations
--Added an index to improve Transactions query performance
CREATE INDEX idx_transactions_date ON Transactions(transaction_date);
--Altered the Users table to add a last_login column
ALTER TABLE Users ADD (last_login DATE DEFAULT NULL);

--DML Operations
-- a new transaction
INSERT INTO Transactions (user_id, category_id, amount, transaction_date, description, transaction_type)
VALUES (1, 1, 6000.00, TO_DATE('2025-05-23', 'YYYY-MM-DD'), 'Bonus payment', 'Income');
--updated a user’s last login
UPDATE Users
SET last_login = TO_DATE('2025-05-23 20:30', 'YYYY-MM-DD HH24:MI')
WHERE user_id = 1;
--Delete: Remove an old transaction
DELETE FROM Transactions
WHERE transaction_id = (SELECT MAX(transaction_id) FROM Transactions WHERE amount = 300.00);

COMMIT;

/*Implementation with Window Functions
Use a window function to calculate the running total of income per user, grouped by transaction date.*/

-- Calculate running total of income per user
SELECT 
    u.username,
    t.transaction_date,
    t.amount,
    SUM(t.amount) OVER (
        PARTITION BY u.user_id 
        ORDER BY t.transaction_date
    ) AS running_total_income
FROM Users u
JOIN Transactions t ON u.user_id = t.user_id
WHERE t.transaction_type = 'Income'
ORDER BY u.user_id, t.transaction_date;

/*Procedure: Fetch User Transactions
A parameterized procedure to retrieve transactions for a given user, using a cursor and exception handling.*/

CREATE OR REPLACE PROCEDURE get_user_transactions(p_user_id IN NUMBER, p_result OUT SYS_REFCURSOR) IS
BEGIN
    OPEN p_result FOR
        SELECT t.transaction_id, t.amount, t.transaction_date, t.description, t.transaction_type
        FROM Transactions t
        WHERE t.user_id = p_user_id;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'Error fetching transactions: ' || SQLERRM);
END get_user_transactions;
/

/*Function: Calculate Total Income
A function to calculate the total income for a user, with exception handling.*/

CREATE OR REPLACE FUNCTION get_total_income(p_user_id IN NUMBER) RETURN NUMBER IS
    v_total_income NUMBER := 0;
BEGIN
    SELECT SUM(amount) INTO v_total_income
    FROM Transactions
    WHERE user_id = p_user_id AND transaction_type = 'Income';
    RETURN NVL(v_total_income, 0);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'Error calculating total income: ' || SQLERRM);
END get_total_income;
/

--TESTING

/*Test the Procedure .Test get_user_transactions for user_id 1 (Diane)*/
VARIABLE result REFCURSOR;
EXEC get_user_transactions(1, :result);
PRINT result;

/*Test the Function
Test get_total_income for user_id 1*/

SELECT get_total_income(1) AS total_income FROM dual;

/*Test Error Handling
Test with an invalid user_id (e.g., 999)*/

VARIABLE result REFCURSOR;
EXEC get_user_transactions(999, :result);
PRINT result;

/*Created a package to organize the procedure and function for data retrieval.*/

CREATE OR REPLACE PACKAGE income_expense_pkg AS
    PROCEDURE get_user_transactions(p_user_id IN NUMBER, p_result OUT SYS_REFCURSOR);
    FUNCTION get_total_income(p_user_id IN NUMBER) RETURN NUMBER;
END income_expense_pkg;
/

CREATE OR REPLACE PACKAGE BODY income_expense_pkg AS
    PROCEDURE get_user_transactions(p_user_id IN NUMBER, p_result OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN p_result FOR
            SELECT t.transaction_id, t.amount, t.transaction_date, t.description, t.transaction_type
            FROM Transactions t
            WHERE t.user_id = p_user_id;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20001, 'Error fetching transactions: ' || SQLERRM);
    END get_user_transactions;

    FUNCTION get_total_income(p_user_id IN NUMBER) RETURN NUMBER IS
        v_total_income NUMBER := 0;
    BEGIN
        SELECT SUM(amount) INTO v_total_income
        FROM Transactions
        WHERE user_id = p_user_id AND transaction_type = 'Income';
        RETURN NVL(v_total_income, 0);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20002, 'Error calculating total income: ' || SQLERRM);
    END get_total_income;
END income_expense_pkg;
/
--testing the package
VARIABLE result REFCURSOR;
EXEC income_expense_pkg.get_user_transactions(1, :result);
PRINT result;
SELECT income_expense_pkg.get_total_income(1) AS total_income FROM dual;

-- PHASE 7: Advanced Database Programming and Auditing

-- Insert Additional Holidays
-- Adds holidays in June 2025 for transaction restrictions

INSERT INTO Holidays (holiday_date, holiday_name) 
VALUES (TO_DATE('2025-06-01', 'YYYY-MM-DD'), 'National Heroes Day');
INSERT INTO Holidays (holiday_date, holiday_name) 
VALUES (TO_DATE('2025-06-04', 'YYYY-MM-DD'), 'Independence Day');

COMMIT;

/* Create Audit Table
Create a table to store audit logs, capturing user ID, date/time, operation, and status.*/

CREATE TABLE Audit_Logs (
    audit_id NUMBER GENERATED ALWAYS AS IDENTITY,
    user_id NUMBER,
    action_date DATE DEFAULT SYSDATE,
    operation VARCHAR2(10) NOT NULL,
    table_name VARCHAR2(50) NOT NULL,
    status VARCHAR2(10) NOT NULL,
    error_message VARCHAR2(500),
    CONSTRAINT pk_audit_logs PRIMARY KEY (audit_id),
    CONSTRAINT fk_audit_user FOREIGN KEY (user_id) REFERENCES Users(user_id),
    CONSTRAINT chk_operation CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    CONSTRAINT chk_status CHECK (status IN ('ALLOWED', 'DENIED'))
);

-- Create index for faster audit queries
CREATE INDEX idx_audit_logs_date ON Audit_Logs(action_date);

COMMIT;

-- Update Package Specification to Include Audit Logging
-- Adds a procedure to log audit actions

CREATE OR REPLACE PACKAGE income_expense_pkg AS
    PROCEDURE get_user_transactions(p_user_id IN NUMBER, p_result OUT SYS_REFCURSOR);
    FUNCTION get_total_income(p_user_id IN NUMBER) RETURN NUMBER;
    PROCEDURE log_audit_action(p_user_id IN NUMBER, p_operation IN VARCHAR2, p_table_name IN VARCHAR2, p_status IN VARCHAR2, p_error_message IN VARCHAR2 DEFAULT NULL);
END income_expense_pkg;
/

CREATE OR REPLACE PACKAGE BODY income_expense_pkg AS
    PROCEDURE get_user_transactions(p_user_id IN NUMBER, p_result OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN p_result FOR
            SELECT t.transaction_id, t.amount, t.transaction_date, t.description, t.transaction_type
            FROM Transactions t
            WHERE t.user_id = p_user_id;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20001, 'Error fetching transactions: ' || SQLERRM);
    END get_user_transactions;

    FUNCTION get_total_income(p_user_id IN NUMBER) RETURN NUMBER IS
        v_total_income NUMBER := 0;
    BEGIN
        SELECT SUM(amount) INTO v_total_income
        FROM Transactions
        WHERE user_id = p_user_id AND transaction_type = 'Income';
        RETURN NVL(v_total_income, 0);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20002, 'Error calculating total income: ' || SQLERRM);
    END get_total_income;

    PROCEDURE log_audit_action(p_user_id IN NUMBER, p_operation IN VARCHAR2, p_table_name IN VARCHAR2, p_status IN VARCHAR2, p_error_message IN VARCHAR2 DEFAULT NULL) IS
    BEGIN
        INSERT INTO Audit_Logs (user_id, operation, table_name, status, error_message)
        VALUES (p_user_id, p_operation, p_table_name, p_status, p_error_message);
        -- Removed COMMIT to avoid ORA-04092 in triggers
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20008, 'Error logging audit action: ' || SQLERRM);
    END log_audit_action;
END income_expense_pkg;
/

/* Simple Trigger: Restrict Manipulations on Transactions
Create a BEFORE trigger on the Transactions table to prevent INSERT, UPDATE, and DELETE operations on weekdays and holidays in June 2025.*/

CREATE OR REPLACE TRIGGER restrict_transactions
BEFORE INSERT OR UPDATE OR DELETE ON Transactions
FOR EACH ROW
DECLARE
    v_day_of_week VARCHAR2(10);
    v_holiday_count NUMBER;
    v_current_user_id NUMBER;
BEGIN
    -- Use :NEW.user_id for INSERT/UPDATE, :OLD.user_id for DELETE
    IF INSERTING OR UPDATING THEN
        v_current_user_id := :NEW.user_id;
    ELSE -- DELETING
        v_current_user_id := :OLD.user_id;
    END IF;

    v_day_of_week := TO_CHAR(SYSDATE, 'DY');
    
    IF UPPER(v_day_of_week) IN ('MON', 'TUE', 'WED', 'THU', 'FRI') THEN
        income_expense_pkg.log_audit_action(
            v_current_user_id,
            CASE WHEN INSERTING THEN 'INSERT' WHEN UPDATING THEN 'UPDATE' ELSE 'DELETE' END,
            'Transactions',
            'DENIED',
            'Operation not allowed on weekdays'
        );
        
        RAISE_APPLICATION_ERROR(-20003, 'Table manipulations are not allowed on weekdays (Monday to Friday).');
    END IF;
    
    SELECT COUNT(*)
    INTO v_holiday_count
    FROM Holidays
    WHERE holiday_date = TRUNC(SYSDATE)
    AND holiday_date BETWEEN TO_DATE('2025-06-01', 'YYYY-MM-DD') 
                        AND TO_DATE('2025-06-30', 'YYYY-MM-DD');
    
    IF v_holiday_count > 0 THEN
        income_expense_pkg.log_audit_action(
            v_current_user_id,
            CASE WHEN INSERTING THEN 'INSERT' WHEN UPDATING THEN 'UPDATE' ELSE 'DELETE' END,
            'Transactions',
            'DENIED',
            'Operation not allowed on public holidays in June 2025'
        );
        
        RAISE_APPLICATION_ERROR(-20004, 'Table manipulations are not allowed on public holidays in June 2025.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20006, 'Error in trigger: ' || SQLERRM);
END;
/

/* Compound Trigger: Audit and Restrict Across All Tables
A compound trigger to enforce restrictions and audit actions across Transactions, Budgets, and Reports tables.*/

CREATE OR REPLACE TRIGGER compound_restrictions
FOR INSERT OR UPDATE OR DELETE ON Transactions
COMPOUND TRIGGER
    v_day_of_week NUMBER;
    v_holiday_count NUMBER;
    v_current_user_id NUMBER;
    v_operation VARCHAR2(10);
    
    BEFORE STATEMENT IS
    BEGIN
        -- Get the day of the week as a number (1 = Sunday, 2 = Monday, ..., 7 = Saturday)
        v_day_of_week := TO_NUMBER(TO_CHAR(SYSDATE, 'D'));
        
        -- Check if today is a holiday in June 2025
        SELECT COUNT(*)
        INTO v_holiday_count
        FROM Holidays
        WHERE holiday_date = TRUNC(SYSDATE)
        AND holiday_date BETWEEN TO_DATE('2025-06-01', 'YYYY-MM-DD')
                            AND TO_DATE('2025-06-30', 'YYYY-MM-DD');
    END BEFORE STATEMENT;
    
    BEFORE EACH ROW IS
    BEGIN
        -- Use :NEW.user_id for INSERT/UPDATE, :OLD.user_id for DELETE
        IF INSERTING OR UPDATING THEN
            v_current_user_id := :NEW.user_id;
        ELSE -- DELETING
            v_current_user_id := :OLD.user_id;
        END IF;

        -- Determine the operation type
        IF INSERTING THEN
            v_operation := 'INSERT';
        ELSIF UPDATING THEN
            v_operation := 'UPDATE';
        ELSE
            v_operation := 'DELETE';
        END IF;
        
        -- Check if today is a weekday (Monday to Friday, i.e., 2 to 6)
        IF v_day_of_week BETWEEN 2 AND 6 THEN
            INSERT INTO Audit_Logs (user_id, operation, table_name, status, error_message)
            VALUES (v_current_user_id, v_operation, 'Transactions', 'DENIED', 'Operation not allowed on weekdays');
            RAISE_APPLICATION_ERROR(-20003, 'Table manipulations are not allowed on weekdays (Monday to Friday).');
        END IF;
        
        -- Check if today is a holiday
        IF v_holiday_count > 0 THEN
            INSERT INTO Audit_Logs (user_id, operation, table_name, status, error_message)
            VALUES (v_current_user_id, v_operation, 'Transactions', 'DENIED', 'Operation not allowed on public holidays in June 2025');
            RAISE_APPLICATION_ERROR(-20004, 'Table manipulations are not allowed on public holidays in June 2025.');
        END IF;
    END BEFORE EACH ROW;
    
    AFTER EACH ROW IS
    BEGIN
        -- Use :NEW.user_id for INSERT/UPDATE, :OLD.user_id for DELETE
        IF INSERTING OR UPDATING THEN
            v_current_user_id := :NEW.user_id;
        ELSE -- DELETING
            v_current_user_id := :OLD.user_id;
        END IF;

        -- Determine the operation type for successful logging
        IF INSERTING THEN
            v_operation := 'INSERT';
        ELSIF UPDATING THEN
            v_operation := 'UPDATE';
        ELSE
            v_operation := 'DELETE';
        END IF;
        
        -- Log successful actions
        INSERT INTO Audit_Logs (user_id, operation, table_name, status)
        VALUES (v_current_user_id, v_operation, 'Transactions', 'ALLOWED');
    END AFTER EACH ROW;
END compound_restrictions;
/

-- Testing and Verification

-- Test 1: Attempt an Insert on a Weekday (Simulate May 23, 2025, a Friday)
CREATE OR REPLACE TRIGGER restrict_transactions
BEFORE INSERT OR UPDATE OR DELETE ON Transactions
FOR EACH ROW
DECLARE
    v_day_of_week VARCHAR2(10);
    v_holiday_count NUMBER;
    v_current_user_id NUMBER;
BEGIN
    -- Use :NEW.user_id for INSERT/UPDATE, :OLD.user_id for DELETE
    IF INSERTING OR UPDATING THEN
        v_current_user_id := :NEW.user_id;
    ELSE -- DELETING
        v_current_user_id := :OLD.user_id;
    END IF;

    v_day_of_week := TO_CHAR(TO_DATE('2025-05-23', 'YYYY-MM-DD'), 'DY');
    
    IF UPPER(v_day_of_week) IN ('MON', 'TUE', 'WED', 'THU', 'FRI') THEN
        income_expense_pkg.log_audit_action(
            v_current_user_id,
            CASE WHEN INSERTING THEN 'INSERT' WHEN UPDATING THEN 'UPDATE' ELSE 'DELETE' END,
            'Transactions',
            'DENIED',
            'Operation not allowed on weekdays'
        );
        
        RAISE_APPLICATION_ERROR(-20003, 'Table manipulations are not allowed on weekdays (Monday to Friday).');
    END IF;
    
    SELECT COUNT(*)
    INTO v_holiday_count
    FROM Holidays
    WHERE holiday_date = TRUNC(TO_DATE('2025-05-23', 'YYYY-MM-DD'))
    AND holiday_date BETWEEN TO_DATE('2025-06-01', 'YYYY-MM-DD') 
                        AND TO_DATE('2025-06-30', 'YYYY-MM-DD');
    
    IF v_holiday_count > 0 THEN
        income_expense_pkg.log_audit_action(
            v_current_user_id,
            CASE WHEN INSERTING THEN 'INSERT' WHEN UPDATING THEN 'UPDATE' ELSE 'DELETE' END,
            'Transactions',
            'DENIED',
            'Operation not allowed on public holidays in June 2025'
        );
        
        RAISE_APPLICATION_ERROR(-20004, 'Table manipulations are not allowed on public holidays in June 2025.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20006, 'Error in trigger: ' || SQLERRM);
END;
/

INSERT INTO Transactions (user_id, category_id, amount, transaction_date, description, transaction_type)
VALUES (1, 1, 7000.00, TO_DATE('2025-05-23', 'YYYY-MM-DD'), 'Extra income', 'Income');

SELECT * FROM Audit_Logs;

-- Test 2: Attempt an Insert on a Holiday (Simulate June 1, 2025)
CREATE OR REPLACE TRIGGER restrict_transactions
BEFORE INSERT OR UPDATE OR DELETE ON Transactions
FOR EACH ROW
DECLARE
    v_day_of_week VARCHAR2(10);
    v_holiday_count NUMBER;
    v_current_user_id NUMBER;
BEGIN
    -- Use :NEW.user_id for INSERT/UPDATE, :OLD.user_id for DELETE
    IF INSERTING OR UPDATING THEN
        v_current_user_id := :NEW.user_id;
    ELSE -- DELETING
        v_current_user_id := :OLD.user_id;
    END IF;

    v_day_of_week := TO_CHAR(TO_DATE('2025-06-01', 'YYYY-MM-DD'), 'DY');
    
    IF UPPER(v_day_of_week) IN ('MON', 'TUE', 'WED', 'THU', 'FRI') THEN
        income_expense_pkg.log_audit_action(
            v_current_user_id,
            CASE WHEN INSERTING THEN 'INSERT' WHEN UPDATING THEN 'UPDATE' ELSE 'DELETE' END,
            'Transactions',
            'DENIED',
            'Operation not allowed on weekdays'
        );
        
        RAISE_APPLICATION_ERROR(-20003, 'Table manipulations are not allowed on weekdays (Monday to Friday).');
    END IF;
    
    SELECT COUNT(*)
    INTO v_holiday_count
    FROM Holidays
    WHERE holiday_date = TRUNC(TO_DATE('2025-06-01', 'YYYY-MM-DD'))
    AND holiday_date BETWEEN TO_DATE('2025-06-01', 'YYYY-MM-DD') 
                        AND TO_DATE('2025-06-30', 'YYYY-MM-DD');
    
    IF v_holiday_count > 0 THEN
        income_expense_pkg.log_audit_action(
            v_current_user_id,
            CASE WHEN INSERTING THEN 'INSERT' WHEN UPDATING THEN 'UPDATE' ELSE 'DELETE' END,
            'Transactions',
            'DENIED',
            'Operation not allowed on public holidays in June 2025'
        );
        
        RAISE_APPLICATION_ERROR(-20004, 'Table manipulations are not allowed on public holidays in June 2025.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20006, 'Error in trigger: ' || SQLERRM);
END;
/

INSERT INTO Transactions (user_id, category_id, amount, transaction_date, description, transaction_type)
VALUES (1, 1, 7000.00, TO_DATE('2025-06-01', 'YYYY-MM-DD'), 'Extra income', 'Income');

SELECT * FROM Audit_Logs;

-- Test 3: Attempt an Insert on a Weekend (Today is Saturday, May 24, 2025)
CREATE OR REPLACE TRIGGER restrict_transactions
BEFORE INSERT OR UPDATE OR DELETE ON Transactions
FOR EACH ROW
DECLARE
    v_day_of_week VARCHAR2(10);
    v_holiday_count NUMBER;
    v_current_user_id NUMBER;
BEGIN
    -- Use :NEW.user_id for INSERT/UPDATE, :OLD.user_id for DELETE
    IF INSERTING OR UPDATING THEN
        v_current_user_id := :NEW.user_id;
    ELSE -- DELETING
        v_current_user_id := :OLD.user_id;
    END IF;

    v_day_of_week := TO_CHAR(SYSDATE, 'DY');
    
    IF UPPER(v_day_of_week) IN ('MON', 'TUE', 'WED', 'THU', 'FRI') THEN
        income_expense_pkg.log_audit_action(
            v_current_user_id,
            CASE WHEN INSERTING THEN 'INSERT' WHEN UPDATING THEN 'UPDATE' ELSE 'DELETE' END,
            'Transactions',
            'DENIED',
            'Operation not allowed on weekdays'
        );
        
        RAISE_APPLICATION_ERROR(-20003, 'Table manipulations are not allowed on weekdays (Monday to Friday).');
    END IF;
    
    SELECT COUNT(*)
    INTO v_holiday_count
    FROM Holidays
    WHERE holiday_date = TRUNC(SYSDATE)
    AND holiday_date BETWEEN TO_DATE('2025-06-01', 'YYYY-MM-DD') 
                        AND TO_DATE('2025-06-30', 'YYYY-MM-DD');
    
    IF v_holiday_count > 0 THEN
        income_expense_pkg.log_audit_action(
            v_current_user_id,
            CASE WHEN INSERTING THEN 'INSERT' WHEN UPDATING THEN 'UPDATE' ELSE 'DELETE' END,
            'Transactions',
            'DENIED',
            'Operation not allowed on public holidays in June 2025'
        );
        
        RAISE_APPLICATION_ERROR(-20004, 'Table manipulations are not allowed on public holidays in June 2025.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20006, 'Error in trigger: ' || SQLERRM);
END;
/

INSERT INTO Transactions (user_id, category_id, amount, transaction_date, description, transaction_type)
VALUES (1, 1, 7000.00, SYSDATE, 'Extra income', 'Income');

SELECT * FROM Audit_Logs;