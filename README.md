# Pharmaceutical OLAP Analytics

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Database](https://img.shields.io/badge/database-SQL%20Server%20%7C%20PostgreSQL%20%7C%20MySQL-orange)
![Design](https://img.shields.io/badge/design-Star%20Schema-green)

Dimensional data model for pharmaceutical Quality Assurance and Quality Management System (QA/QMS) analytics.

---

## Table of Contents

- [Project Objective](#project-objective)
- [Design Approach](#design-approach)
  - [Architecture](#architecture)
  - [Fact Tables](#fact-tables)
  - [Dimension Tables](#dimension-tables)
- [Structural Principles](#structural-principles)
- [Constraints](#constraints)
- [Decision Support Capabilities](#decision-support-capabilities)
- [Project Structure](#project-structure)
- [Requirements](#requirements)
- [Installation & Setup](#installation--setup)
- [Contributing](#contributing)
- [License](#license)

---

## Project Objective

Build an analytical database to enable:

- **Organizational weakness detection** across quality processes
- **Repeated failure pattern recognition** in production and compliance
- **Deviation and corrective action trend analysis**
- **Management decision support** based on data-driven insights

[↑ Back to top](#pharmaceutical-olap-analytics)

---

## Design Approach

### Architecture

| Element | Value |
|---------|-------|
| **Primary Pattern** | Star Schema |
| **Methodology** | GUI-First (no direct SQL scripting) |
| **Focus** | Data integrity before optimization |

### Fact Tables

Core event tables capturing measurable business processes:

- **Deviations** — Quality incidents and non-conformances
- **NCRs** (Non-Conformance Reports) — Formal quality defects
- **CAPA Actions** — Corrective and Preventive Actions
- **Audit Findings** — Internal/external audit results
- **Batch/Process Events** — Production and manufacturing events

### Dimension Tables

Context tables for slicing and filtering facts:

- **Time** — Date hierarchy (day, week, month, quarter, year)
- **Organization Units** — Departments, sites, divisions
- **Process Steps** — Manufacturing stages, workflows
- **Equipment** — Machines, instruments, tools
- **Products** — SKUs, formulations, batches
- **Root Cause Categories** — Standardized failure taxonomy

[↑ Back to top](#pharmaceutical-olap-analytics)

---

## Structural Principles

### 1. Grain Definition

Every Fact table must clearly answer:

- ✅ **What happened?** (event type)
- ✅ **Where?** (location, unit)
- ✅ **When?** (timestamp)
- ✅ **In what process context?** (stage, product, equipment)

### 2. Traceability

All changes must be auditable from a **QA/Compliance perspective**:

- Change tracking on dimensional attributes
- Historical snapshots where regulatory required
- Clear lineage from raw data to aggregated metrics

### 3. Design Priorities (Strict Order)
```
Structure > Features
Data Integrity > Analytics or Performance
Clear Grain > Flexibility
```

[↑ Back to top](#pharmaceutical-olap-analytics)

---

## Constraints

- 🎯 **Focus on analytics**, not workflow or automation
- ⚠️ **Explicitly warn** when design decisions are hard to reverse

[↑ Back to top](#pharmaceutical-olap-analytics)

---

## Decision Support Capabilities

The model enables:

| Capability | Description |
|------------|-------------|
| **Bottleneck Identification** | Find process stages with highest failure rates |
| **Trend Analysis** | Track deviation frequency over time |
| **Weak Process Detection** | Identify units/products with recurring issues |
| **Failure Pattern Discovery** | Correlate root causes across events |

[↑ Back to top](#pharmaceutical-olap-analytics)

---

## Project Structure
```
pharmaceutical-olap-analytics/
│
├── docs/               # Design documentation and rationale
│   ├── grain-definitions.md
│   ├── business-rules.md
│   └── gui-procedures.md
│
├── models/             # ERD diagrams and schema files
│   ├── star-schema.png
│   ├── fact-tables.md
│   └── dimension-tables.md
│
├── scripts/            # Helper scripts (if needed)
│   └── sample-data-generator.py
│
├── examples/           # Sample datasets
│   └── deviations-sample.csv
│
├── .gitignore
├── LICENSE
└── README.md
```

[↑ Back to top](#pharmaceutical-olap-analytics)

---

## Requirements

### Database Platforms

- SQL Server 2019+
- PostgreSQL 13+
- MySQL 8.0+

### GUI Tools

- [DBeaver](https://dbeaver.io/) (cross-platform)
- [pgAdmin](https://www.pgadmin.org/) (PostgreSQL)
- [SQL Server Management Studio](https://aka.ms/ssmsfullsetup) (SSMS)

### Knowledge Areas

- Dimensional modeling (Kimball methodology)
- QA/QMS processes in pharmaceutical manufacturing
- GMP compliance requirements

[↑ Back to top](#pharmaceutical-olap-analytics)

---

## Installation & Setup

### Step 1: Clone Repository
```bash
git clone https://github.com/yourusername/pharmaceutical-olap-analytics.git
cd pharmaceutical-olap-analytics
```

### Step 2: Choose Database Platform

Follow platform-specific setup in `/docs/setup-{platform}.md`

### Step 3: Create Schema via GUI

1. Open your preferred database GUI tool
2. Follow step-by-step instructions in `/docs/gui-procedures.md`
3. Create Dimension tables first
4. Create Fact tables with foreign key relationships

### Step 4: Load Sample Data (Optional)

Import `/examples/` CSV files to validate structure

[↑ Back to top](#pharmaceutical-olap-analytics)

---

## Contributing

Pull requests are welcome. For major changes:

1. **Open an issue first** to discuss proposed changes
2. **Document GUI steps** for any structural modifications
3. **Preserve grain definitions** — do not alter fact table granularity without approval
4. **Maintain data integrity** — all changes must pass referential integrity checks

### Contribution Guidelines

✅ **Do:**
- Explain changes using GUI tool screenshots
- Update `/docs/` when modifying structure
- Test against sample data before submitting

❌ **Don't:**
- Submit raw SQL migration scripts
- Change dimension keys without discussion
- Add transactional logic to analytical model

[↑ Back to top](#pharmaceutical-olap-analytics)

---

## License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## Contact

For questions about pharmaceutical QMS modeling or implementation:

- 📧 Email: [Hadi.Yabari.m@Gmail.com](Hadi.Yabari.m@Gmail.com)
- 💼 LinkedIn: [Hadi Yabari](https://linkedin.com/in/Hadi-Yabari)
- 🐛 Issues: [GitHub Issues](https://github.com/hadiii1i/QualityLabs-Analytics_DB/issues)

---

**Made with focus on data integrity and regulatory compliance** 🏭💊

[↑ Back to top](#pharmaceutical-olap-analytics)
