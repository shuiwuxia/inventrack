

from fastapi.middleware.cors import CORSMiddleware
from fastapi import FastAPI
from . import models
from .database import engine 
from .dependencies import get_db 
from .routes import auth, products,inventory

models.Base.metadata.create_all(bind=engine)
app = FastAPI()
app.include_router(inventory.router) 
app.include_router(auth.router)
app.include_router(products.router) 

# A simple welcome route to check if the server is running
@app.get("/")
def read_root():
    return {"message": "Welcome to InvenTrack API"}

origins = ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


 