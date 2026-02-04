from pydantic import BaseModel, ConfigDict


class SchemaBase(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
        protected_namespaces=(),  # libera campos como model_version / model_run_id
    )
