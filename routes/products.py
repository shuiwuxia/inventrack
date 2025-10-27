# File: routes/products.py

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List  # Import List for the response model
from .. import schemas, models, database

# Create a "router" for products.
# We use a prefix to ensure all routes in this file start with /products
router = APIRouter(
    prefix="/products",  # All routes here will be like http://.../products/
    tags=['Products']      # This creates a "Products" section in your API docs
)

# Dependency to get a database session for each request
def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()

# --- Endpoint to CREATE a new product ---
@router.post("/", response_model=schemas.Product, status_code=status.HTTP_201_CREATED)
def create_product(request: schemas.ProductCreate, db: Session = Depends(get_db)):
    # Check if a product with the same SKU already exists
    existing_product = db.query(models.Product).filter(models.Product.sku == request.sku).first()
    if existing_product:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT,
                            detail=f"Product with SKU '{request.sku}' already exists.")

    # Create the new product object
    new_product = models.Product(
        product_name=request.product_name,
        sku=request.sku,
        price=request.price
    )
    db.add(new_product)
    db.commit()
    db.refresh(new_product)
    return new_product

# --- Endpoint to GET all products ---
@router.get("/", response_model=List[schemas.Product])
def get_all_products(db: Session = Depends(get_db)):
    # Query the database to get all products
    products = db.query(models.Product).all()
    return products