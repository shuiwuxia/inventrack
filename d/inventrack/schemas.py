# File: inventrack/schemas.py

from pydantic import BaseModel
from typing import Optional
from datetime import datetime

# --- User Schemas (Mapped to 'users' table) ---

class UserCreate(BaseModel):
    full_name: str
    email: str
    password: str  
    role: str    
    phone: str
    location: Optional[str] = None

class UserLogin(BaseModel):
    identifier: str  # Accepts either email or phone
    password: str

class User(BaseModel):
    id: int # Maps to user_id
    full_name: str
    email: str
    role: str
    phone: str
    location: Optional[str] = None
    
    class Config:
        from_attributes = True

# --- Shopkeeper Schema (Mapped to 'users' & 'shops') ---

class ShopkeeperCreate(BaseModel):
    full_name: str
    email: str
    password: str
    phone: str
    location: Optional[str] = None
    shop_name: str
    business_verification_id: Optional[str] = None
    address: str      # Maps to Address_Line1
    city: str
    shop_phone: Optional[str] = None
    store_type: Optional[str] = None


# --- Product Schemas (Mapped to 'products' table) ---

# FOR API 1: Creating a new product
class ProductCreate(BaseModel):
    product_name: str
    category: str
    mrp: float
    msp: float
    stock_quantity: int
    # description and unit_of_measure REMOVED

# The data we return about a product
class Product(BaseModel):
    id: str # Maps to Product_ID (which is VARCHAR/String)
    product_name: str
    category: str
    mrp: float
    msp: float
    # description and unit_of_measure REMOVED
    
    class Config:
        from_attributes = True

# FOR API 2: Editing an existing product
class ProductUpdate(BaseModel):
    product_name: Optional[str] = None
    category: Optional[str] = None
    mrp: Optional[float] = None
    msp: Optional[float] = None
    stock_quantity: Optional[int] = None
    # description and unit_of_measure REMOVED

# --- Inventory Schemas (Mapped to 'inventory' table) ---

class Inventory(BaseModel):
    inventory_id: int
    store_id: str
    product_id: str
    stock_quantity: int
    last_updated: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# --- Schema for returning a product WITH its stock level ---
class InventoryProduct(BaseModel):
    id: str
    product_name: str
    category: str
    mrp: float
    msp: float
    stock_quantity: int
    # description and unit_of_measure REMOVED

    class Config:
        from_attributes = True