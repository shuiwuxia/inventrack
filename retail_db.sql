create database retail_db_1;
use retail_db_1;
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY, 
    -- User's full name.
    full_name VARCHAR(100) NOT NULL, 
    -- User's location.
    location VARCHAR(255), 
    -- User's contact number.
    phone_number VARCHAR(15) UNIQUE NOT NULL, 
    -- Login username or email (must be unique).
    email VARCHAR(100) UNIQUE NOT NULL, 
    -- Hashed password for security. VARCHAR(200) is appropriate for hashed passwords.
    password_hash VARCHAR(255) NOT NULL, 
    -- Role-based access control (e.g., 'Consumer', 'Shopkeeper', 'Admin')..
    user_role VARCHAR(20) NOT NULL 
);
CREATE TABLE products (
    Product_ID VARCHAR(50) PRIMARY KEY, 
    Product_Name VARCHAR(150) NOT NULL,
    Category VARCHAR(100) NOT NULL, 
    Description TEXT,
    MRP DECIMAL(10, 2),
    MSP DECIMAL(10, 2),
    Unit_Of_Measure VARCHAR(20)
);
CREATE TABLE inventory (
    Inventory_ID INT AUTO_INCREMENT PRIMARY KEY, 
    Store_ID VARCHAR(50) NOT NULL,
    Product_ID VARCHAR(50) NOT NULL,
    Stock_Quantity INT NOT NULL, 
    Last_Updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_store_product (Store_ID, Product_ID),
    FOREIGN KEY (Product_ID) REFERENCES products(Product_ID) 
);
CREATE TABLE shops (
    Store_ID VARCHAR(50) PRIMARY KEY,
    Shop_Name VARCHAR(150) NOT NULL,
    Business_Verification_ID VARCHAR(100) UNIQUE,
    Address_Line1 VARCHAR(255) NOT NULL,
    City VARCHAR(100) NOT NULL,
    Shop_Phone VARCHAR(15),
    Store_Type VARCHAR(50), 
    Status VARCHAR(20) DEFAULT 'Active'
);
ALTER TABLE shops
ADD COLUMN User_ID INT NOT NULL,
ADD FOREIGN KEY (User_ID) REFERENCES users(user_id);
ALTER TABLE inventory
ADD FOREIGN KEY (Store_ID) REFERENCES shops(Store_ID);
CREATE TABLE SalesData (
    RecordID INT AUTO_INCREMENT PRIMARY KEY, 
    Date DATE NOT NULL,
    Store_ID VARCHAR(50) NOT NULL,
    Product_ID VARCHAR(50) NOT NULL,
    Units_Sold INT NOT NULL, 
    Price DECIMAL(10, 2),
    Discount DECIMAL(5, 2),
    Weather_Competit_Seasonality VARCHAR(255),
    INDEX idx_store_product_date (Store_ID, Product_ID, Date),
    FOREIGN KEY (Store_ID) REFERENCES shops(Store_ID),
    FOREIGN KEY (Product_ID) REFERENCES products(Product_ID)
);
SELECT COUNT(*) FROM SalesData;
CREATE USER 'admin'@'%' IDENTIFIED BY 'Project@1234';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'43.37.150.8' WITH GRANT OPTION;
FLUSH PRIVILEGES;
DROP USER 'admin'@'HANEETH';
CREATE USER 'admin'@'HANEETH' IDENTIFIED BY 'Project@1234';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'HANEETH' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SELECT user, host FROM mysql.user WHERE user = 'admin';
GRANT ALL PRIVILEGES ON project_db.* TO 'admin'@'%';
