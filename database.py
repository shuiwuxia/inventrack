from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# The database URL. For now, it points to a file named `sql_app.db`
# in the same directory.
SQLALCHEMY_DATABASE_URL = "mysql+pymysql://admin:my_secret_password@192.168.42.197/project_db"
# This is the main engine that connects SQLAlchemy to the database
engine = create_engine(
    SQLALCHEMY_DATABASE_URL
)

# Each instance of SessionLocal will be a database session.
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base will be used by our models (in models.py) to inherit from.
Base = declarative_base()