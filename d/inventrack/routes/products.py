# File: inventrack/routes/products.py

from fastapi import APIRouter, HTTPException, status, Depends
from .. import schemas, models
from ..dependencies import get_db
from sqlalchemy.orm import Session
from typing import Annotated
import uuid

# Set the prefix and tags for this router
router = APIRouter(
    prefix="/products",
    tags=["Products"]
)

DBDependency = Annotated[Session, Depends(get_db)]

@router.post(
    "/{store_id}/",
    response_model=schemas.Product, 
    status_code=status.HTTP_201_CREATED,
)
def create_product(
    store_id: str,
    product: schemas.ProductCreate, 
    db: DBDependency
):
    """
    API 1: Creates a new product in the master 'products' table AND
    adds it to the specified shop's 'inventory' table.
    """
    
    db_product = db.query(models.Product).filter(
        models.Product.product_name == product.product_name
    ).first()
    
    if db_product:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Product with name '{product.product_name}' already exists."
        )

    # 1. ACTION 1: Create the product in the 'products' table
    # This now generates the 'id' (which maps to 'Product_ID')
    new_product_id = "P" + str(uuid.uuid4()).split('-')[0].upper()
    
    db_product = models.Product(
        id=new_product_id,
        product_name=product.product_name,
        category=product.category,
    
        mrp=product.mrp,
        msp=product.msp,
       
    )
    db.add(db_product)
    db.commit()
    db.refresh(db_product)

    # 2. ACTION 2: Add the new product to the shop's 'inventory' table
    new_inventory_item = models.Inventory(
        store_id=store_id,
        product_id=new_product_id,
        stock_quantity=product.stock_quantity
    )
    db.add(new_inventory_item)
    db.commit()
    
    return db_product