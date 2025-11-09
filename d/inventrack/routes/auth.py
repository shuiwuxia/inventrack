# File: routes/auth.py

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Annotated, Dict, Any # Added Dict, Any for the shopkeeper response
import uuid 
from .. import schemas, models
from ..dependencies import get_db 

router = APIRouter(
    prefix="/auth",
    tags=['Authentication']
)

# Define the dependency type alias
DBDependency = Annotated[Session, Depends(get_db)]


# --- Endpoint for Shopkeeper Sign Up ---
@router.post("/register/shopkeeper", status_code=status.HTTP_201_CREATED, response_model=Dict[str, Any])
def create_shopkeeper(request: schemas.ShopkeeperCreate, db: DBDependency): 
    """
    Handles the combined registration for a new shopkeeper and their shop.
    """
    # 1. Check if a user with this email already exists
    existing_user = db.query(models.User).filter(models.User.email == request.email).first()
    if existing_user:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT,
                            detail=f"User with email '{request.email}' already exists.")

    # 2. Create the new user object
    new_user = models.User(
        full_name=request.full_name,
        email=request.email,
        location=request.location, 
        phone=request.phone,
        password=request.password,
        role='Shopkeeper'
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    # 3. Create the new shop object and link it to the new user
    
    # FIX: Generate a unique Store_ID string
    new_store_id = str(uuid.uuid4()).split('-')[0].upper() 
    
    new_shop = models.Shop(
        store_id=new_store_id,        
        shop_name=request.shop_name,
        address=request.address, 
        city=request.city,           
        owner_id=new_user.id,
        shop_phone=request.shop_phone,
        business_verification_id=request.business_verification_id,
        store_type=request.store_type
    )
    db.add(new_shop)
    db.commit()
    db.refresh(new_shop)

    return {
        "message": f"Shopkeeper '{new_user.full_name}' and shop '{new_shop.shop_name}' created successfully.",
        "user_id": new_user.id,
        "store_id": new_store_id
    }


# --- Endpoint for Regular User (e.g., Customer) Registration ---
@router.post("/register", response_model=schemas.User)
def create_user(request: schemas.UserCreate, db: DBDependency):
    """
    Registers a new non-shopkeeper user, like a customer or staff.
    """
    existing_user = db.query(models.User).filter(models.User.email == request.email).first()
    if existing_user:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT,
                            detail=f"User with email '{request.email}' already exists.")

    new_user = models.User(
        full_name=request.full_name,
        email=request.email,
        password=request.password,
        phone=request.phone,
        location=request.location, 
        role=request.role
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user


# --- Endpoint for Login ---
@router.post("/login", response_model=schemas.User)
def login(request: schemas.UserLogin, db: DBDependency):
    """
    Logs in any user by verifying their password against either
    their email or phone number.
    """
    user = None
    if '@' in request.identifier:
        user = db.query(models.User).filter(models.User.email == request.identifier).first()
    else:
        user = db.query(models.User).filter(models.User.phone == request.identifier).first()

    if not user or user.password != request.password:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect credentials" 
        )
    return user