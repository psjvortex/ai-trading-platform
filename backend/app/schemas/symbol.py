from pydantic import BaseModel

class SymbolOut(BaseModel):
    id: int
    name: str
    description: str | None = None

    class Config:
        from_attributes = True


class SymbolCreate(BaseModel):
    name: str
    description: str | None = None


class SymbolUpdate(BaseModel):
    name: str | None = None
    description: str | None = None
