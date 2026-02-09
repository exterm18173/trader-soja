from alembic import op
import sqlalchemy as sa

revision = "8353320007fd"
down_revision = "71de7301ef6d"

def upgrade() -> None:
    conn = op.get_bind()

    # 1) cria/garante usuário "system"
    system_email = "system@local"
    system_name = "System"
    system_password = "$2b$12$aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"  # hash fake (não será usado)

    # tenta achar um user existente (system), senão cria
    system_user_id = conn.execute(
        sa.text("SELECT id FROM users WHERE email = :email LIMIT 1"),
        {"email": system_email},
    ).scalar()

    if system_user_id is None:
        system_user_id = conn.execute(
            sa.text("""
                INSERT INTO users (nome, email, hashed_password, ativo, is_superuser)
                VALUES (:nome, :email, :pwd, TRUE, FALSE)
                RETURNING id
            """),
            {"nome": system_name, "email": system_email, "pwd": system_password},
        ).scalar()

    # 2) backfill dos NULLs
    conn.execute(
        sa.text("""
            UPDATE interest_rates
            SET created_by_user_id = :uid
            WHERE created_by_user_id IS NULL
        """),
        {"uid": system_user_id},
    )
    conn.execute(
        sa.text("""
            UPDATE offset_calibration
            SET created_by_user_id = :uid
            WHERE created_by_user_id IS NULL
        """),
        {"uid": system_user_id},
    )

    # 3) agora sim: NOT NULL
    op.alter_column("interest_rates", "created_by_user_id",
                    existing_type=sa.INTEGER(), nullable=False)
    op.alter_column("offset_calibration", "created_by_user_id",
                    existing_type=sa.INTEGER(), nullable=False)

    # competencia_mes: mesma lógica se existir NULL
    conn.execute(sa.text("""
        UPDATE expenses_usd
        SET competencia_mes = CURRENT_DATE
        WHERE competencia_mes IS NULL
    """))
    op.alter_column("expenses_usd", "competencia_mes",
                    existing_type=sa.DATE(), nullable=False)


def downgrade() -> None:
    op.alter_column("offset_calibration", "created_by_user_id",
                    existing_type=sa.INTEGER(), nullable=True)
    op.alter_column("interest_rates", "created_by_user_id",
                    existing_type=sa.INTEGER(), nullable=True)
    op.alter_column("expenses_usd", "competencia_mes",
                    existing_type=sa.DATE(), nullable=True)
