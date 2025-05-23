# SQLAlchemy or Pydantic models will go here 

from pydantic import BaseModel
from datetime import datetime

class Lab(BaseModel):
    id: int
    name: str
    description: str

class QuizResultInput(BaseModel):
    lab_id: int
    score: int

class QuizResultOutput(BaseModel):
    id: int # This would likely be auto-generated by DB later
    lab_id: int
    score: int
    timestamp: datetime 