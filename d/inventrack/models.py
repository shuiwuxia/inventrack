from sqlalchemy import Column, Integer, String, Float, Text, ForeignKey, TIMESTAMP, DECIMAL, Date
from sqlalchemy.ext.declarative import declarative_base 
from .database import Base 
class User(Base):
    __tablename__ = "users"
    id = Column("user_id", Integer, primary_key=True, index=True) 
    full_name = Column("full_name", String(100), nullable=False)
    location = Column("location", String(255))
    phone = Column("phone_number", String(15), unique=True, nullable=False)
    email = Column("email", String(100), unique=True, index=True, nullable=False)
    password = Column("password_hash", String(255), nullable=False) # Stores the HASHED password
    role = Column("user_role", String(20), nullable=False)
class Product(Base):
    __tablename__ = "products"
    id = Column("Product_ID", String(50), primary_key=True, index=True)
    product_name = Column("Product_Name", String(150), nullable=False)
    category = Column("Category", String(100), nullable=False)
    description = Column("Description", Text)
    mrp = Column("MRP", DECIMAL(10, 2))
    msp = Column("MSP", DECIMAL(10, 2))
    unit_of_measure = Column("Unit_Of_Measure", String(20))

class Shop(Base):
    __tablename__ = "shops"
    store_id = Column("Store_ID", String(50), primary_key=True, index=True)
    shop_name = Column("Shop_Name", String(150), nullable=False)
    business_verification_id = Column("Business_Verification_ID", String(100), unique=True)
    address = Column("Address_Line1", String(255), nullable=False)
    city = Column("City", String(100), nullable=False)
    shop_phone = Column("Shop_Phone", String(15))
    store_type = Column("Store_Type", String(50))
    status = Column("Status", String(20), default='Active')
    owner_id = Column("User_ID", Integer, ForeignKey("users.user_id"), nullable=False)
class Inventory(Base):
    __tablename__ = "inventory"
    inventory_id = Column("Inventory_ID", Integer, primary_key=True, index=True)
    store_id = Column("Store_ID", String(50), ForeignKey("shops.Store_ID"), nullable=False)
    product_id = Column("Product_ID", String(50), ForeignKey("products.Product_ID"), nullable=False)
    stock_quantity = Column("Stock_Quantity", Integer, nullable=False)
    last_updated = Column("Last_Updated", TIMESTAMP)
class SalesData(Base):
    __tablename__ = "SalesData"
    record_id = Column("RecordID", Integer, primary_key=True, index=True)
    date = Column("Date", Date, nullable=False)
    store_id = Column("Store_ID", String(50), ForeignKey("shops.Store_ID"), nullable=False)
    product_id = Column("Product_ID", String(50), ForeignKey("products.Product_ID"), nullable=False)
    units_sold = Column("Units_Sold", Integer, nullable=False)
    price = Column("Price", DECIMAL(10, 2))
    discount = Column("Discount", DECIMAL(5, 2))
    weather_competit_seasonality = Column("Weather_Competit_Seasonality", String(255))