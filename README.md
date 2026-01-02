# QualityLabs Analytics Database

This project is a SQL Server database schema designed for
quality assurance, production monitoring, and maintenance
analytics in a pharmaceutical manufacturing environment.

# QualityLabs-Analytics

A practical SQL-based analytics project for **Quality Control / Quality Assurance** environments, focused on equipment, production shifts, and inspections data.

## Project Structure

```text
QualityLabs-Analytics/
│
├── README.md
│
├── database/
│   ├── 01_create_database.sql      # Database initialization
│   ├── 02_create_schemas.sql       # Logical schema separation
│   ├── 03_create_tables.sql        # Core tables
│   ├── 04_constraints.sql          # PK, FK, CHECK, NOT NULL constraints
│   └── 05_seed_data.sql            # Sample seed data
│
├── data_samples/
│   ├── equipment.csv               # Equipment master data
│   ├── production_shift.csv        # Shift and production data
│   └── inspections.csv             # Quality inspection records
│
└── diagrams/
    └── erd.png                     # Entity Relationship Diagram (ERD)


## Scope
- Equipment master data
- Production shifts
- QA inspections and defects
- Calibration and preventive maintenance

## Tech Stack
- Microsoft SQL Server
- T-SQL
- SSMS

## How to Deploy
1. Run scripts in order:
   - 01_create_database.sql
   - 02_create_schemas.sql
   - 03_create_tables.sql
   - 04_constraints.sql
   - 05_seed_data.sql

## Notes
- No real company data is included.
- Sample data is fictional but realistic.
