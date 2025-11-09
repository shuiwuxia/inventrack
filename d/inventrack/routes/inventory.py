from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from sqlalchemy.orm import Session
from typing import Annotated, List, Any 
from .. import models, schemas
from ..dependencies import get_db 
import uuid

# Imports for CSV processing
import csv
import io

router = APIRouter(prefix="/inventory", tags=["Inventory"])
DBDependency = Annotated[Session, Depends(get_db)]

@router.get(
    "/{store_id}/products", 
    status_code=status.HTTP_200_OK,
    response_model=List[schemas.InventoryProduct] 
)
def get_products_by_shop(store_id: str, db: DBDependency): 
    """
    Gets all products for a specific shop by joining the
    inventory and products tables.
    """
    
    products_with_stock = db.query(
        models.Product, 
        models.Inventory.stock_quantity
    ).join(
        models.Inventory, 
        models.Product.id == models.Inventory.product_id
    ).filter(
        models.Inventory.store_id == store_id
    ).all()

    results = []
    for product, stock in products_with_stock:
        results.append({
            "id": product.id,
            "product_name": product.product_name,
            "category": product.category,
            "mrp": product.mrp,
            "msp": product.msp,
            "stock_quantity": stock
        })

    return results

@router.patch("/{store_id}/{product_id}", status_code=status.HTTP_200_OK)
def update_product_details(
    store_id: str, 
    product_id: str, 
    request: schemas.ProductUpdate, 
    db: DBDependency
):
    """
    API 2: Updates a product's details (name, category, mrp, msp, etc.)
    in the master 'products' table AND updates its 'stock_quantity'
    in the 'inventory' table.
    """
    
    product = db.query(models.Product).filter(models.Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,
                            detail=f"Product with id {product_id} not found")

    inventory_item = db.query(models.Inventory).filter(
        models.Inventory.store_id == store_id,
        models.Inventory.product_id == product_id
    ).first()
    if not inventory_item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,
                            detail=f"Product not found in this shop's inventory")

    if request.product_name is not None:
        product.product_name = request.product_name
    if request.category is not None:
        product.category = request.category
    if request.mrp is not None:
        product.mrp = request.mrp
    if request.msp is not None:
        product.msp = request.msp

    if request.stock_quantity is not None:
        inventory_item.stock_quantity = request.stock_quantity

    db.commit()

    return {"message": "Product details updated successfully"}


# --- NEW: Smart CSV Upload Endpoint ---
@router.post("/{store_id}/upload_csv")
async def upload_inventory_csv(store_id: str, db: DBDependency, file: UploadFile = File(...)):
    """
    Uploads a CSV to bulk-update inventory.
    - If product name exists, it ADDS to the stock.
    - If product name does not exist, it CREATES a new product and inventory item.
    
    Required CSV columns: product_name, category, mrp, msp, stock_quantity
    """
    # 1. Check if the shop exists
    shop = db.query(models.Shop).filter(models.Shop.store_id == store_id).first()
    if not shop:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,
                            detail=f"Shop with id {store_id} not found")

    # 2. Read the CSV file
    contents = await file.read()
    file_data = io.StringIO(contents.decode('utf-8'))
    
    # Use DictReader to read CSV as dictionaries (header row is key)
    csv_reader = csv.DictReader(file_data)
    
    updated_items = 0
    created_items = 0

    # 3. Process each row in the CSV
    for row in csv_reader:
        try:
            # Get data from the row, case-insensitive and stripping whitespace
            product_name = row['product_name'].strip()
            stock_from_csv = int(row['stock_quantity'])
        except (ValueError, KeyError, TypeError):
            # Skip bad rows (e.g., missing product_name or bad stock number)
            continue 

        # 4. Check if product exists in the master 'products' table
        product = db.query(models.Product).filter(models.Product.product_name == product_name).first()

        if product:
            # --- LOGIC A: PRODUCT EXISTS ---
            
            # Now check if it's in this shop's inventory
            inventory_item = db.query(models.Inventory).filter(
                models.Inventory.store_id == store_id,
                models.Inventory.product_id == product.id
            ).first()

            if inventory_item:
                # --- A1: Exists in this shop -> ADD stock ---
                inventory_item.stock_quantity += stock_from_csv # This is the "add" logic
                updated_items += 1
            else:
                # --- A2: Exists in master list, but not in this shop -> CREATE inventory item ---
                new_inventory_item = models.Inventory(
                    store_id=store_id,
                    product_id=product.id,
                    stock_quantity=stock_from_csv
                )
                db.add(new_inventory_item)
                created_items += 1
        
        else:
            # --- LOGIC B: NEW PRODUCT ---
            try:
                # Get the rest of the details from the CSV
                category = row['category'].strip()
                mrp = float(row['mrp'])
                msp = float(row['msp'])
            except (ValueError, KeyError, TypeError):
                # Skip rows that are missing data for a new product
                continue

            # B1: Create new product in 'products' table
            new_product_id = "P" + str(uuid.uuid4()).split('-')[0].upper()
            new_product = models.Product(
                id=new_product_id,
                product_name=product_name,
                category=category,
                mrp=mrp,
                msp=msp
            )
            db.add(new_product)
            
            # B2: Create new inventory item in 'inventory' table
            new_inventory_item = models.Inventory(
                store_id=store_id,
                product_id=new_product_id,
                stock_quantity=stock_from_csv
            )
            db.add(new_inventory_item)
            created_items += 1

    # 4. Save all changes to the database
    db.commit()

    return {
        "message": "Inventory upload complete.",
        "shop_id": store_id,
        "new_products_created": created_items,
        "existing_products_updated": updated_items
    }