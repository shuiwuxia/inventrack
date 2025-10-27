# File: main.py

from fastapi import FastAPI
from . import models
from .database import engine
from .routes import auth, products # 1. Import the new products router

# This command tells SQLAlchemy to create the database tables based on our models.
models.Base.metadata.create_all(bind=engine)

# Create the main FastAPI app instance
app = FastAPI()

# Include the routers from your route files
app.include_router(auth.router)
app.include_router(products.router) # 2. Include the products router

# A simple welcome route to check if the server is running
@app.get("/")
def read_root():
    return {"message": "Welcome to InvenTrack API"}