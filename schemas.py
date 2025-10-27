# File: schemas.py

from pydantic import BaseModel

# --- User Schemas ---

# For creating a user (like a customer)
class UserCreate(BaseModel):
    full_name: str
    email: str
    password: str
    role: str
    phone: str | None = None  # Phone is optional for a regular user

# For logging any user in
class UserLogin(BaseModel):
    identifier: str  # This field will accept either email or phone
    password: str

# The data we return about a user
class User(BaseModel):
    id: int
    full_name: str
    email: str
    role: str
    phone: str | None = None

    class Config:
        from_attributes = True

# --- Shopkeeper Schema ---

# For the combined Shopkeeper Sign Up screen
class ShopkeeperCreate(BaseModel):
    shop_name: str
    address: str
    full_name: str
    email: str
    phone: str
    password: str

# --- Product Schemas ---

# For creating a new product
class ProductCreate(BaseModel):
    product_name: str
    sku: str
    price: float

# The data we return about a product
class Product(BaseModel):
    id: int
    product_name: str
    sku: str
    price: float
    
    class Config:
        from_attributes = True