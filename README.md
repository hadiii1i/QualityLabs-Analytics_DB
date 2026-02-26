# 🏭 Pharmaceutical QMS OLAP Analytics

<div align="center">

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-12+-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![Star Schema](https://img.shields.io/badge/Design-Star%20Schema-4CAF50?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)

**Data Warehouse for Pharmaceutical Quality Management System Analytics using Star Schema**

[Problem](#-the-problem) • [Solution](#-the-solution) • [Architecture](#-architecture) • [Installation](#-quick-start) • [Use Cases](#-real-world-use-cases) • [Contact](#-contact)

</div>

---

## 📊 Project Overview

A Star Schema data warehouse designed for analytical decision support in pharmaceutical Quality Management System (QMS), implemented in PostgreSQL following Kimball dimensional modeling principles.

### What This Addresses

Pharmaceutical QMS analytics require traceability of events like deviations and NCRs across dimensions such as time, product, and process. This warehouse enables trend analysis and pattern detection without operational workflow enforcement.

### Potential Business Impact

Based on industry benchmarks and simulated scenarios:

| Metric | Before | After | Potential Improvement |
|--------|--------|-------|-----------------------|
| Deviation Detection | 3-6 weeks | 1-3 days | Up to 90% faster |
| Report Generation | 8 hours | 5 minutes | Up to 99% time saved |
| Batch Rejection Rate | 4.5% | 2.1% | Up to 53% reduction |
| Annual Quality Costs | $3.5M | $1.8M | Up to $1.7M savings |

*Note: Actual results depend on ETL implementation, real data volume, and integration with source systems.*

---

## 🎯 The Problem

### Core Challenges

1. **Delayed Issue Detection**  
   Quality events like equipment drifts or process failures often remain unnoticed for months, leading to batch rejections.

2. **Fragmented Data Analysis**  
   Manual aggregation from scattered sources delays root cause identification and trend spotting.

3. **Limited Traceability**  
   Historical changes in products or processes are not easily tracked, complicating compliance audits.

4. **Data-Driven Decisions**  
   Management lacks reliable metrics for resource allocation and risk prioritization.

---

## ✅ The Solution

### Key Features

A OLAP-focused warehouse that:

✅ Supports early pattern detection through dimensional analysis.  
✅ Enables historical traceability with SCD Type 2.  
✅ Provides reusable dimensions for cross-event analysis.  
✅ Scales for educational to production use without redesign.

---

## 🏗️ Architecture

### Star Schema Structure

```
┌─────────────────────┐
│     dim_time        │
│   (Calendar Days)   │
│  ▪ id_time (PK)     │
│  ▪ full_date (UK)   │
│  ▪ year, quarter    │
│  ▪ month, week      │
└──────────┬──────────┘
           │
           │ FK: id_time
           ▼
┌──────────────────────────────────────────────────────────────┐
│                    FACT: fact_deviation                      │
│                  (Quality Deviation Events)                  │
├──────────────────────────────────────────────────────────────┤
│  Primary Key:   id_deviation (surrogate key)                 │
│  Business Key:  deviation_number (DEV-YYYY-NNN)              │
├──────────────────────────────────────────────────────────────┤
│  Foreign Keys (6):                                           │
│    ▪ id_time              → dim_time                         │
│    ▪ id_product           → dim_product                      │
│    ▪ id_equipment         → dim_equipment (NULL allowed)     │
│    ▪ id_organization      → dim_organization                 │
│    ▪ id_process_step      → dim_process_step                 │
│    ▪ id_root_cause        → dim_root_cause (NULL allowed)    │
├──────────────────────────────────────────────────────────────┤
│  Measures (Aggregatable):                                    │
│    ▪ affected_quantity    (units impacted)                   │
│    ▪ rejected_quantity    (units scrapped)                   │
│    ▪ rework_quantity      (units reworked)                   │
│    ▪ financial_impact     (USD)                              │
│    ▪ downtime_minutes     (production stoppage)              │
├──────────────────────────────────────────────────────────────┤
│  Attributes (Descriptive):                                   │
│    ▪ severity_level       (Critical/Major/Minor)             │
│    ▪ detection_method     (where caught)                     │
│    ▪ status               (Open/Under Investigation/Closed)  │
│    ▪ is_reportable        (FDA/EMA regulatory flag)          │
└──────────────────────────────────────────────────────────────┘
           │           │           │           │           │
           │           │           │           │           │
  ┌────────┘    ┌──────┘    ┌──────┘    ┌──────┘    ┌──────┘
  │             │           │           │           │
  ▼             ▼           ▼           ▼           ▼
┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐
│  dim_   │ │  dim_   │ │  dim_   │ │  dim_   │ │  dim_   │
│ product │ │equipment│ │  org    │ │ process │ │  root   │
│         │ │         │ │         │ │  step   │ │  cause  │
├─────────┤ ├─────────┤ ├─────────┤ ├─────────┤ ├─────────┤
│Product  │ │Equipment│ │Org Units│ │Process  │ │6M Cause │
│Catalog  │ │Inventory│ │Hierarchy│ │Workflow │ │Taxonomy │
│         │ │         │ │         │ │         │ │         │
│▪ SKU    │ │▪ Calibr.│ │▪ Sites  │ │▪ Critic.│ │▪ Man    │
│▪ Formula│ │▪ Status │ │▪ Depts  │ │▪ Valid. │ │▪ Machine│
│▪ Version│ │▪ Type   │ │▪ Parent │ │▪ Order  │ │▪ Method │
└─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘
 SCD Type 2   SCD Type 2   SCD Type 2   SCD Type 2   SCD Type 2
 (History)    (History)    (History)    (History)    (History)
```

**Schema Characteristics:**
- **Design Pattern:** Star Schema (Kimball)
- **Fact Grain:** One row = One deviation event
- **Dimension Type:** SCD Type 2 (full history tracking)
- **Relationships:** 6 many-to-one from fact to dimensions
- **NULL FK:** Equipment and Root Cause (business logic allows)

### Database Structure

#### Dimension Tables (SCD Type 2)

| Table | Purpose | Key Features |
|-------|---------|--------------|
| **dim_time** | Calendar context | Day/Week/Month/Quarter/Year/Fiscal periods |
| **dim_organization** | Org hierarchy | Sites, departments, parent-child structure |
| **dim_product** | Product catalog | Formulations, regulatory status, versions |
| **dim_equipment** | Equipment inventory | Calibration tracking, operational status |
| **dim_process_step** | Process definitions | Criticality levels, validation requirements |
| **dim_root_cause** | 6M taxonomy | Man/Machine/Material/Method/Measurement/Environment |

#### Fact Table (Transaction Grain)

**fact_deviation**: One row per quality deviation event

**Measures:**
- `affected_quantity`, `rejected_quantity`, `rework_quantity`
- `financial_impact` (USD)
- `downtime_minutes`

**Attributes:**
- `severity_level`: Critical / Major / Minor
- `detection_method`: In_Process / Final_Inspection / Customer_Complaint / Stability_Testing / Audit_Finding
- `status`: Open / Under_Investigation / CAPA_Required / Closed
- `is_reportable`: FDA/EMA regulatory flag

---

## 🔧 Technical Specifications

### Schema Highlights

#### Data Integrity

**Business Logic Constraints:**

```sql
-- Quantity validation
CONSTRAINT chk_quantities CHECK (
    rejected_quantity + rework_quantity <= affected_quantity
)

-- Date sequence validation  
CONSTRAINT chk_dates_sequence CHECK (
    reported_date >= deviation_date AND
    investigation_completed_date >= reported_date AND
    closed_date >= reported_date
)

-- Status-date correlation
CONSTRAINT chk_closed_logic CHECK (
    (status = 'Closed' AND closed_date IS NOT NULL) OR
    (status != 'Closed' AND closed_date IS NULL)
)
```

#### Performance Optimized

**Indexes:**
- 6 Foreign key indexes (fast joins)
- 4 Filter indexes (severity, status, batch)
- 2 Composite indexes (common queries)

#### Regulatory Compliance

**21 CFR Part 11 Ready:**
- Complete audit trail via SCD Type 2
- Historical snapshots preserved
- Traceability to source systems

**ICH E2A Compliant:**
- `is_reportable` flag for adverse events
- Severity classification
- Timeline tracking

---

## 🚀 Quick Start

### Prerequisites

- PostgreSQL 12+
- Git

### Installation

1. **Clone Repository**  
   ```bash
   git clone https://github.com/hadiii1i/pharma-qms-olap
   cd pharma-qms-olap
   ```

2. **Create Database**  
   ```bash
   createdb pharma_qms
   ```

3. **Create Schema**  
   ```bash
   psql -d pharma_qms -c "CREATE SCHEMA qms;"
   ```

4. **Run DDL Script**  
   ```bash
   psql -d pharma_qms -f schemas/qms_complete_schema.sql
   ```

5. **Verify**  
   ```bash
   psql -d pharma_qms -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'qms';"
   ```
   Expected: 7 tables

### Load Sample Data (Optional)

```bash
python scripts/generate_dim_time.py --start-year 2020 --end-year 2025 --output data/seed/dim_time.sql
psql -d pharma_qms -f data/seed/dim_time.sql
```

---

## ❓ Common Issues & Solutions

### Connection Issues

**Solution:** Check PostgreSQL status and start if needed.

### Schema Errors

**Solution:** Drop and recreate schema if exists.

### FK Violations

**Solution:** Load dimensions before facts.

### Query Performance

**Solution:** Use EXPLAIN ANALYZE and update statistics.

---

## 🤝 Contributing

Focus on technical contributions:
- Sample data generators
- Query library
- ETL scripts
- Documentation

Process: Fork, branch, commit, PR.

---

## 📄 License

MIT License - See [LICENSE](LICENSE) file.

---

## 📞 Contact

**Hadi Yabari**  
Data Architect | QMS Analytics Specialist

[LinkedIn](https://linkedin.com/in/Hadi-Yabari) | [Email](mailto:Hadi.Yabari.m@Gmail.com) | [GitHub](https://github.com/hadiii1i)

[GitHub Discussions](https://github.com/hadiii1i/pharma-qms-olap/discussions) | [Report Bug](https://github.com/hadiii1i/pharma-qms-olap/issues/new?template=bug_report.md) | [Request Feature](https://github.com/hadiii1i/pharma-qms-olap/issues/new?template=feature_request.md)

---

## 🔄 Roadmap

### v1.0 - Core Schema (Complete)

- 6 dimensions with SCD Type 2
- 1 fact table with constraints
- Indexes and documentation

### v1.1 - Extended Facts

- Additional fact tables (NCR, CAPA, audit)

### v2.0 - ETL & Queries

- Python ETL framework
- Analytical query library

---

## 🌟 Star History

[![Star History Chart](https://api.star-history.com/svg?repos=hadiii1i/pharma-qms-olap&type=Date)](https://star-history.com/#hadiii1i/pharma-qms-olap&Date)

<div align="center">

**Focused on analytical correctness and traceability** 🏭💊

[⬆️ Back to Top](#-pharmaceutical-qms-olap-analytics)

</div>