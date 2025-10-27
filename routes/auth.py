# File: routes/auth.py

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from .. import schemas, models, database

router = APIRouter(
    tags=['Authentication']
)

def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()

# --- Endpoint for Shopkeeper Sign Up ---
@router.post("/register/shopkeeper", status_code=status.HTTP_201_CREATED)
def create_shopkeeper(request: schemas.ShopkeeperCreate, db: Session = Depends(get_db)):
    """
    Handles the combined registration for a new shopkeeper and their shop.
    """
    # 1. Check if a user with this email already exists
    existing_user = db.query(models.User).filter(models.User.email == request.email).first()
    if existing_user:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT,
                            detail=f"User with email '{request.email}' already exists.")

    # 2. Create the new user object with the 'shopkeeper' role
    new_user = models.User(
        full_name=request.full_name,
        email=request.email,
        phone=request.phone,
        password=request.password,
        role='shopkeeper'
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    # 3. Create the new shop object and link it to the new user
    new_shop = models.Shop(
        shop_name=request.shop_name,
        address=request.address,
        owner_id=new_user.id  # Link to the user we just created
    )
    db.add(new_shop)
    db.commit()
    db.refresh(new_shop)

    return {"message": f"Shopkeeper '{new_user.full_name}' and shop '{new_shop.shop_name}' created successfully."}


# --- Endpoint for Regular User (e.g., Customer) Registration ---
@router.post("/register", response_model=schemas.User)
def create_user(request: schemas.UserCreate, db: Session = Depends(get_db)):
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
        role=request.role
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user


# --- Endpoint for Login (Corrected for Email or Phone) ---
@router.post("/login", response_model=schemas.User)
def login(request: schemas.UserLogin, db: Session = Depends(get_db)):
    """
    Logs in any user by verifying their password against either
    their email or phone number.
    """
    user = None
    # Check if the identifier looks like an email
    if '@' in request.identifier:
        user = db.query(models.User).filter(models.User.email == request.identifier).first()
    # Otherwise, assume it's a phone number
    else:
        user = db.query(models.User).filter(models.User.phone == request.identifier).first()

    # Verify the user was found and the password matches
    if not user or user.password != request.password:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect credentials"
        )
    return user