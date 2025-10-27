# File: models.py

from sqlalchemy import Column, Integer, String, Float, ForeignKey
from .database import Base

# 1. User Model
class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String(150), nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=False)
    phone = Column(String(20), nullable=True)
    password = Column(String(255), nullable=False)
    role = Column(String(50), nullable=False)
    
# 2. Product Model
class Product(Base):
    __tablename__ = "products"
    id = Column(Integer, primary_key=True, index=True)
    product_name = Column(String(200), index=True)
    sku = Column(String(64), unique=True, index=True)
    price = Column(Float)

# 3. Shop Model (Corrected)
class Shop(Base):
    __tablename__ = "shops"
    id = Column(Integer, primary_key=True, index=True)
    shop_name = Column(String(150), index=True)
    address = Column(String)
    owner_id = Column(Integer, ForeignKey("users.id")) # This line was missing

# 4. Inventory Model
class Inventory(Base):
    __tablename__ = "inventory"
    shop_id = Column(Integer, ForeignKey("shops.id"), primary_key=True)
    product_id = Column(Integer, ForeignKey("products.id"), primary_key=True)
    quantity = Column(Integer)