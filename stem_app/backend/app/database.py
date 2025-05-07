from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker, declarative_base
from sqlalchemy import Column, Integer, String, DateTime, func
from datetime import datetime

from .models import QuizResultInput # Import the Pydantic model for type hint

# --- Database Configuration --- #
DATABASE_URL = "sqlite+aiosqlite:///./quiz_results.db"
# Use check_same_thread=False only for SQLite, needed for FastAPI async context
engine = create_async_engine(DATABASE_URL, connect_args={"check_same_thread": False})

# expire_on_commit=False is important for async sessions
AsyncSessionLocal = sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False
)

Base = declarative_base()

# --- SQLAlchemy Table Model --- #
class QuizResult(Base):
    __tablename__ = "quiz_results"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    lab_id = Column(Integer, nullable=False)
    score = Column(Integer, nullable=False)
    timestamp = Column(DateTime(timezone=True), server_default=func.now())

# --- Database Utility Functions --- #
async def create_db_and_tables():
    async with engine.begin() as conn:
        # await conn.run_sync(Base.metadata.drop_all) # Optional: Drop tables first if needed for reset
        await conn.run_sync(Base.metadata.create_all)

async def get_db() -> AsyncSession:
    """FastAPI Dependency to get an async database session."""
    async with AsyncSessionLocal() as session:
        yield session
        # Optional: await session.commit() here if you want auto-commit
        # Optional: await session.rollback() on errors

async def add_quiz_result(db: AsyncSession, result: QuizResultInput) -> QuizResult:
    """Adds a new quiz result to the database."""
    db_result = QuizResult(
        lab_id=result.lab_id,
        score=result.score
        # timestamp is handled by server_default
    )
    db.add(db_result)
    await db.commit()
    await db.refresh(db_result) # Refresh to get the auto-generated id and timestamp
    return db_result 