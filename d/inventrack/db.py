from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv
import os
from fastapi import HTTPException, status 

# Ensure this file is run from the directory containing or near the .env file
load_dotenv()

# Check for the DATABASE_URL and handle if it's not set
db_url_raw = os.getenv("DATABASE_URL")

if db_url_raw is None:
    # Raise a Python error during startup if the environment variable is missing
    raise EnvironmentError(
        "DATABASE_URL not found in environment variables or .env file. "
        "Please check your .env file and ensure it's in the correct directory."
    )
DATABASE_URL = db_url_raw.replace("mysql+mysqlconnector", "mysql+pymysql")

engine = create_engine(
    DATABASE_URL, 
    pool_pre_ping=True, 
    pool_recycle=3600
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()