-- =====================================================
-- PHARMACEUTICAL QMS OLAP DATABASE
-- =====================================================
-- Database: PostgreSQL 12+
-- Schema: (default / depends on search_path)
-- Design: Star Schema (Kimball Methodology)
-- Purpose: Quality Management System Analytics
-- Owner: postgres
-- =====================================================
-- Export Date: 2025-02-23
-- Source: DataGrip
-- Tables: 7 (6 dimensions + 1 fact)
-- Total Indexes: 45
-- Total Constraints: 30+
-- =====================================================


-- =====================================================
-- DIMENSION TABLE 1: dim_time
-- =====================================================
-- Purpose: Calendar dimension for time-based analysis
-- Grain: One row per calendar day
-- Key Type: Surrogate (id_time) + Natural (full_date)
-- Records: ~3,650 (10 years typical)
-- =====================================================

create table dim_time
(
    -- Primary Key (Surrogate)
    id_time        integer generated always as identity
        constraint dim_time_pk
            primary key,

    -- Natural Key (Business Key)
    full_date      date                  not null
        constraint dim_time_uq
            unique,

    -- Calendar Attributes
    day_of_week    smallint              not null,  -- 1=Monday, 7=Sunday
    day_name       varchar(10)           not null,  -- 'Monday', 'Tuesday', ...
    week_of_year   smallint              not null,  -- 1-52/53
    month_number   smallint              not null,  -- 1-12
    quarter        smallint              not null,  -- 1-4
    year           smallint              not null,  -- YYYY

    -- Boolean Flags
    is_weekend     boolean default false not null,  -- Saturday/Sunday
    is_holiday     boolean default false not null,  -- Company holidays

    -- Fiscal Calendar (Optional)
    fiscal_quarter smallint,                        -- Fiscal Q1-Q4
    fiscal_year    smallint                         -- Fiscal year YYYY
);

-- Table Documentation
comment on table dim_time is 'Date dimension providing consistent time context for QA/QMS event analysis. Grain: One row per calendar day. Purpose: Enables trend analysis, seasonality detection, year-over-year / quarter-over-quarter / month-over-month comparisons of deviations, NCRs, CAPAs, audit findings and process incidents. All attributes are derived / calculated from the full_date column. Surrogate key: id_time (auto-increment integer) Business key / natural key: full_date (date)';

-- Table Ownership
alter table dim_time
    owner to postgres;

-- Indexes for Performance
create index idx_dim_time_full_date
    on dim_time (full_date);              -- Natural key lookup

create index idx_dim_time_year_quarter
    on dim_time (year, quarter);          -- Period aggregations


-- =====================================================
-- DIMENSION TABLE 2: dim_organization
-- =====================================================
-- Purpose: Organizational hierarchy with historical tracking
-- Grain: One row per org unit version per time period
-- SCD Type: Type 2 (maintains full history)
-- Key Type: Surrogate (id_organization) + Natural (org_code, effective_date)
-- Records: 50-200 typical
-- =====================================================

create table dim_organization
(
    -- Primary Key (Surrogate)
    id_organization integer generated always as identity
        constraint dim_organization_pk
            primary key,

    -- Natural Keys (Business Keys)
    org_code        varchar(20)          not null,  -- Org unit identifier
    org_name        varchar(100)         not null,  -- Display name

    -- Organizational Attributes
    org_type        varchar(50)          not null,  -- Site/Dept/Line/Team
    parent_org_code varchar(20),                    -- Hierarchy parent (self-ref)
    site_location   varchar(100),                   -- Physical location

    -- SCD Type 2 Columns
    is_active       boolean default true not null,  -- Current version flag
    effective_date  date                 not null,  -- Version start date
    end_date        date,                           -- Version end date (NULL=current)

    -- Constraints
    constraint dim_organization_uq
        unique (org_code, effective_date),          -- Version uniqueness
    constraint chk_org_dates
        check ((end_date IS NULL) OR (end_date >= effective_date))  -- Date logic
);

-- Table & Column Documentation
comment on table dim_organization is 'SCD Type 2 Dimension - Grain: One row per organizational unit version valid during a specific time period (effective_date to end_date). Supports traceability of organizational changes in QA/QMS events.';

comment on column dim_organization.parent_org_code is 'Self-referencing foreign key for organizational hierarchy. NULL indicates top-level unit.';

-- Table Ownership
alter table dim_organization
    owner to postgres;

-- Indexes for Performance
create index idx_dim_org_code
    on dim_organization (org_code);       -- Business key lookup

create index idx_dim_org_type
    on dim_organization (org_type);       -- Filter by type

create index idx_dim_org_active
    on dim_organization (is_active);      -- Current records only

create index idx_dim_org_parent
    on dim_organization (parent_org_code); -- Hierarchy queries


-- =====================================================
-- DIMENSION TABLE 3: dim_product
-- =====================================================
-- Purpose: Product catalog with formulation history
-- Grain: One row per product formulation version per time period
-- SCD Type: Type 2 (maintains full history)
-- Key Type: Surrogate (id_product) + Natural (product_code, effective_date)
-- Records: 100-500 typical
-- =====================================================

create table dim_product
(
    -- Primary Key (Surrogate)
    id_product          integer generated always as identity
        constraint dim_product_pk
            primary key,

    -- Natural Keys (Business Keys)
    product_code        varchar(30)          not null,  -- SKU identifier
    product_name        varchar(150)         not null,  -- Brand/trade name

    -- Product Attributes
    generic_name        varchar(150)         not null,  -- API/chemical name
    dosage_form         varchar(50)          not null,  -- Tablet/Capsule/Injection
    strength            varchar(50)          not null,  -- "500mg", "10mg/mL"
    formulation_version varchar(20)          not null,  -- F-01, F-02, F-03

    -- Regulatory Attributes
    regulatory_status   varchar(50)          not null
        constraint chk_regulatory_status
            check ((regulatory_status)::text = ANY
                   ((ARRAY ['Under_Development'::character varying,
                       'Under_Review'::character varying,
                       'Approved'::character varying,
                       'Active_Production'::character varying,
                       'Discontinued'::character varying,
                       'Recalled'::character varying])::text[])),
    approval_date       date,                           -- FDA/EMA approval

    -- Classification & Manufacturing
    product_category    varchar(100)         not null,  -- Therapeutic category
    manufacturer_code   varchar(30),                    -- CMO identifier

    -- SCD Type 2 Columns
    is_active           boolean default true not null,  -- Current version flag
    effective_date      date                 not null,  -- Version start date
    end_date            date,                           -- Version end date (NULL=current)

    -- Constraints
    constraint dim_product_uq
        unique (product_code, effective_date),          -- Version uniqueness
    constraint chk_product_dates
        check ((end_date IS NULL) OR (end_date >= effective_date))  -- Date logic
);

-- Table & Column Documentation
comment on table dim_product is 'SCD Type 2 Dimension - Grain: One row per product formulation version valid during a specific time period (effective_date to end_date). Supports traceability of product-related quality events across formulation changes and regulatory status transitions.';

comment on column dim_product.formulation_version is 'Version identifier for formulation changes (e.g., F-01, F-02). New version creates new row for historical tracking.';

comment on column dim_product.regulatory_status is 'Current regulatory approval status. Valid values: Under_Development, Under_Review, Approved, Active_Production, Discontinued, Recalled.';

-- Table Ownership
alter table dim_product
    owner to postgres;

-- Indexes for Performance
create index idx_dim_product_code
    on dim_product (product_code);        -- Business key lookup

create index idx_dim_product_name
    on dim_product (product_name);        -- Search by name

create index idx_dim_product_category
    on dim_product (product_category);    -- Group by category

create index idx_dim_product_status
    on dim_product (regulatory_status);   -- Filter by status

create index idx_dim_product_active
    on dim_product (is_active);           -- Current records only


-- =====================================================
-- DIMENSION TABLE 4: dim_equipment
-- =====================================================
-- Purpose: Equipment inventory with calibration history
-- Grain: One row per equipment configuration version per time period
-- SCD Type: Type 2 (maintains full history)
-- Key Type: Surrogate (id_equipment) + Natural (equipment_code, effective_date)
-- Records: 200-1000 typical
-- =====================================================

create table dim_equipment
(
    -- Primary Key (Surrogate)
    id_equipment          integer generated always as identity
        constraint dim_equipment_pk
            primary key,

    -- Natural Keys (Business Keys)
    equipment_code        varchar(30)                                          not null,  -- Logical ID
    equipment_name        varchar(150)                                         not null,  -- Display name

    -- Equipment Classification
    equipment_type        varchar(50)                                          not null
        constraint chk_equipment_type
            check ((equipment_type)::text = ANY
                   ((ARRAY ['Production'::character varying,
                       'Testing'::character varying,
                       'Packaging'::character varying,
                       'Storage'::character varying,
                       'Cleaning'::character varying])::text[])),

    -- Manufacturer Information
    manufacturer          varchar(100)                                         not null,  -- Vendor name
    model_number          varchar(50)                                          not null,  -- Model ID
    serial_number         varchar(50)                                          not null   -- Physical unit ID
        constraint uq_serial_number
            unique,                                                                        -- Globally unique

    -- Installation & Location
    installation_date     date                                                 not null,  -- First install
    location              varchar(100)                                         not null,  -- Physical location

    -- Calibration Tracking
    calibration_status    varchar(30)                                          not null
        constraint chk_calibration_status
            check ((calibration_status)::text = ANY
                   ((ARRAY ['Valid'::character varying,
                       'Expired'::character varying,
                       'Pending'::character varying,
                       'Out_of_Spec'::character varying])::text[])),
    last_calibration_date date,                                                           -- Last calibrated
    next_calibration_date date,                                                           -- Next scheduled

    -- Operational Status
    operational_status    varchar(30) default 'Operational'::character varying not null
        constraint chk_operational_status
            check ((operational_status)::text = ANY
                   ((ARRAY ['Operational'::character varying,
                       'Under_Maintenance'::character varying,
                       'Under_Qualification'::character varying,
                       'Out_of_Service'::character varying,
                       'Retired'::character varying])::text[])),

    -- SCD Type 2 Columns
    is_active             boolean     default true                             not null,  -- Current version
    effective_date        date                                                 not null,  -- Version start
    end_date              date,                                                           -- Version end (NULL=current)

    -- Constraints
    constraint uq_equipment_version
        unique (equipment_code, effective_date),                                          -- Version uniqueness
    constraint chk_equipment_dates
        check ((end_date IS NULL) OR (end_date >= effective_date)),                      -- Date logic
    constraint chk_calibration_dates
        check ((last_calibration_date IS NULL) OR
               (next_calibration_date IS NULL) OR
               (next_calibration_date >= last_calibration_date))                          -- Calibration logic
);

-- Table & Column Documentation
comment on table dim_equipment is 'SCD Type 2 Dimension - Grain: One row per equipment configuration version valid during a specific time period (effective_date to end_date). New row created for: model upgrade, serial replacement, equipment type change, or critical location change. Tracks equipment state for quality event traceability and compliance analysis.';

comment on column dim_equipment.equipment_code is 'Logical equipment identifier in system. Can have multiple versions (rows) across time. Use with effective_date for unique identification.';

comment on column dim_equipment.serial_number is 'Physical manufacturer serial number - globally unique across all equipment versions. Changes only when physical unit is replaced.';

comment on column dim_equipment.calibration_status is 'Current calibration status. Valid values: Valid, Expired, Pending, Out_of_Spec. Note: Frequent changes should be tracked in fact_calibration_event, not as new dimension rows.';

comment on column dim_equipment.operational_status is 'Current operational state. Valid values: Operational, Under_Maintenance, Under_Qualification, Out_of_Service, Retired. Note: State transitions should be tracked in fact_equipment_event.';

-- Table Ownership
alter table dim_equipment
    owner to postgres;

-- Indexes for Performance
create index idx_dim_equipment_code
    on dim_equipment (equipment_code);              -- Business key lookup

create index idx_dim_equipment_serial
    on dim_equipment (serial_number);               -- Physical unit lookup

create index idx_dim_equipment_type
    on dim_equipment (equipment_type);              -- Filter by type

create index idx_dim_equipment_status
    on dim_equipment (operational_status);          -- Operational only

create index idx_dim_equipment_calibration
    on dim_equipment (calibration_status);          -- Expired alerts

create index idx_dim_equipment_location
    on dim_equipment (location);                    -- Site reports

create index idx_dim_equipment_active
    on dim_equipment (is_active);                   -- Current version only


-- =====================================================
-- DIMENSION TABLE 5: dim_process_step
-- =====================================================
-- Purpose: Manufacturing process steps with criticality
-- Grain: One row per process step configuration version per time period
-- SCD Type: Type 2 (maintains full history)
-- Key Type: Surrogate (id_process_step) + Natural (process_code, effective_date)
-- Records: 30-100 typical
-- =====================================================

create table dim_process_step
(
    -- Primary Key (Surrogate)
    id_process_step           integer generated always as identity
        constraint dim_process_step_pk
            primary key,

    -- Natural Keys (Business Keys)
    process_code              varchar(30)                                     not null,  -- Process ID
    process_name              varchar(100)                                    not null,  -- Display name

    -- Process Classification
    process_category          varchar(50)                                     not null
        constraint chk_process_category
            check ((process_category)::text = ANY
                   ((ARRAY ['Pre_Compression'::character varying,
                       'Compression'::character varying,
                       'Post_Compression'::character varying,
                       'Quality_Control'::character varying,
                       'Packaging'::character varying])::text[])),

    -- Process Attributes
    process_description       text,                                                      -- Detailed description
    standard_duration_minutes integer
        constraint chk_duration
            check ((standard_duration_minutes IS NULL) OR
                   (standard_duration_minutes > 0)),                                     -- Expected duration

    -- Risk & Compliance
    criticality_level         varchar(20) default 'Medium'::character varying not null
        constraint chk_criticality_level
            check ((criticality_level)::text = ANY
                   ((ARRAY ['High'::character varying,
                       'Medium'::character varying,
                       'Low'::character varying])::text[])),
    requires_validation       boolean     default false                       not null,  -- IQ/OQ/PQ required

    -- Process Flow
    sequence_order            smallint
        constraint chk_sequence
            check ((sequence_order IS NULL) OR (sequence_order > 0)),                    -- Typical order

    -- SCD Type 2 Columns
    is_active                 boolean     default true                        not null,  -- Current version
    effective_date            date                                            not null,  -- Version start
    end_date                  date,                                                      -- Version end (NULL=current)

    -- Constraints
    constraint uq_process_version
        unique (process_code, effective_date),                                           -- Version uniqueness
    constraint chk_process_dates
        check ((end_date IS NULL) OR (end_date >= effective_date))                       -- Date logic
);

-- Table & Column Documentation
comment on table dim_process_step is 'SCD Type 2 Dimension - Grain: One row per process step configuration version valid during a specific time period (effective_date to end_date). New row created for: duration standard change, criticality reclassification, or validation requirement change. Enables process-level quality analysis and bottleneck identification.';

comment on column dim_process_step.process_code is 'Logical process identifier. Can have multiple versions across time. Use with effective_date for unique identification.';

comment on column dim_process_step.process_category is 'Process phase classification. Valid values: Pre_Compression, Compression, Post_Compression, Quality_Control, Packaging.';

comment on column dim_process_step.criticality_level is 'Risk classification for quality impact. High = batch rejection risk, Medium = monitoring required, Low = minimal quality impact.';

comment on column dim_process_step.requires_validation is 'Indicates if process requires IQ/OQ/PQ validation documentation per regulatory requirements (FDA, EMA).';

comment on column dim_process_step.sequence_order is 'Typical sequence position in manufacturing workflow. Used for process flow analysis and deviation sequence tracking.';

-- Table Ownership
alter table dim_process_step
    owner to postgres;

-- Indexes for Performance
create index idx_dim_process_code
    on dim_process_step (process_code);             -- Business key lookup

create index idx_dim_process_category
    on dim_process_step (process_category);         -- Group by phase

create index idx_dim_process_criticality
    on dim_process_step (criticality_level);        -- High-risk only

create index idx_dim_process_sequence
    on dim_process_step (sequence_order);           -- Flow analysis

create index idx_dim_process_active
    on dim_process_step (is_active);                -- Current version only


-- =====================================================
-- DIMENSION TABLE 6: dim_root_cause
-- =====================================================
-- Purpose: Root cause taxonomy (6M Ishikawa methodology)
-- Grain: One row per root cause classification version per time period
-- SCD Type: Type 2 (maintains full history)
-- Key Type: Surrogate (id_root_cause) + Natural (cause_code, effective_date)
-- Records: 50-150 typical
-- =====================================================

create table dim_root_cause
(
    -- Primary Key (Surrogate)
    id_root_cause       integer generated always as identity
        constraint dim_root_cause_pk
            primary key,

    -- Natural Keys (Business Keys)
    cause_code          varchar(30)                                     not null,  -- Cause identifier
    cause_name          varchar(150)                                    not null,  -- Display name

    -- 6M Classification (Ishikawa)
    cause_category      varchar(50)                                     not null
        constraint chk_cause_category
            check ((cause_category)::text = ANY
                   ((ARRAY ['Man'::character varying,                              -- Human error
                       'Machine'::character varying,                           -- Equipment failure
                       'Material'::character varying,                          -- Raw material issues
                       'Method'::character varying,                            -- Process/SOP issues
                       'Measurement'::character varying,                       -- Testing/calibration
                       'Environment'::character varying])::text[])),           -- Temperature/humidity
    cause_subcategory   varchar(100),                                              -- Detailed classification
    cause_description   text,                                                      -- Full description

    -- Risk Assessment
    severity_potential  varchar(20) default 'Medium'::character varying not null
        constraint chk_severity_potential
            check ((severity_potential)::text = ANY
                   ((ARRAY ['Critical'::character varying,                         -- Patient safety
                       'High'::character varying,                              -- Batch rejection
                       'Medium'::character varying,                            -- Rework
                       'Low'::character varying])::text[])),                  -- Minimal impact

    -- CAPA Strategy
    prevention_strategy text,                                                      -- Recommended prevention
    is_systemic         boolean     default false                       not null,  -- Requires CAPA (vs simple correction)

    -- SCD Type 2 Columns
    is_active           boolean     default true                        not null,  -- Current version
    effective_date      date                                            not null,  -- Version start
    end_date            date,                                                      -- Version end (NULL=current)

    -- Constraints
    constraint uq_cause_version
        unique (cause_code, effective_date),                                       -- Version uniqueness
    constraint chk_cause_dates
        check ((end_date IS NULL) OR (end_date >= effective_date))                 -- Date logic
);

-- Table & Column Documentation
comment on table dim_root_cause is 'SCD Type 2 Dimension - Grain: One row per root cause classification version valid during a specific time period (effective_date to end_date). Based on 6M (Ishikawa) methodology. New row created for: category reclassification, severity reassessment, or systemic flag change. Enables root cause trend analysis and CAPA effectiveness tracking.';

comment on column dim_root_cause.cause_code is 'Logical root cause identifier. Can have multiple versions across time as understanding of cause evolves.';

comment on column dim_root_cause.cause_category is 'Primary classification per 6M framework. Valid values: Man, Machine, Material, Method, Measurement, Environment.';

comment on column dim_root_cause.severity_potential is 'Risk assessment of cause impact. Critical = patient safety, High = batch rejection, Medium = rework, Low = minimal impact.';

comment on column dim_root_cause.prevention_strategy is 'Recommended prevention approach based on historical analysis. Updated as lessons learned accumulate.';

comment on column dim_root_cause.is_systemic is 'Indicates if root cause is systemic (requires CAPA) vs isolated incident (simple correction). Critical for compliance and management escalation.';

-- Table Ownership
alter table dim_root_cause
    owner to postgres;

-- Indexes for Performance
create index idx_dim_cause_code
    on dim_root_cause (cause_code);                 -- Business key lookup

create index idx_dim_cause_category
    on dim_root_cause (cause_category);             -- 6M analysis

create index idx_dim_cause_severity
    on dim_root_cause (severity_potential);         -- Risk-based filtering

create index idx_dim_cause_systemic
    on dim_root_cause (is_systemic);                -- CAPA triggers

create index idx_dim_cause_active
    on dim_root_cause (is_active);                  -- Current version only


-- =====================================================
-- FACT TABLE: fact_deviation
-- =====================================================
-- Purpose: Quality deviation events (core fact table)
-- Grain: One row per deviation event
-- Fact Type: Transaction (one event = one row)
-- Foreign Keys: 6 (to all dimension tables)
-- Measures: 5 aggregatable (quantities, cost, downtime)
-- Attributes: 10 descriptive (status, severity, method, etc.)
-- Records: 500-5000 per year typical
-- =====================================================
-- NOTE: This schema has BOTH id_time FK AND deviation_date FK
-- This is redundant but may improve JOIN performance
-- Standard Star Schema uses only deviation_date → dim_time(full_date)
-- =====================================================

create table fact_deviation
(
    -- ===================================================
    -- PRIMARY KEY
    -- ===================================================

    id_deviation                 integer generated always as identity
        constraint fact_deviation_pk
            primary key,                                   -- Surrogate key

    deviation_number             varchar(50)               not null
        constraint uq_deviation_number
            unique,                                        -- Business key (DEV-YYYY-NNN)


    -- ===================================================
    -- FOREIGN KEYS (Dimension References)
    -- ===================================================

    -- ⚠️ NOTE: Both id_time AND deviation_date exist
    -- This is redundant but may be intentional for performance
    id_time                      integer                   not null
        constraint fk_deviation_time
            references dim_time
            on update cascade on delete restrict,          -- FK to surrogate key

    deviation_date               date                      not null,  -- Also serves as date attribute

    id_product                   integer                   not null
        constraint fk_deviation_product
            references dim_product
            on update cascade on delete restrict,          -- Product involved

    id_equipment                 integer                                    -- NULL allowed
        constraint fk_deviation_equipment
            references dim_equipment
            on update cascade on delete set null,          -- Equipment (NULL for non-equipment deviations)

    id_organization              integer                   not null
        constraint fk_deviation_organization
            references dim_organization
            on update cascade on delete restrict,          -- Responsible org unit

    id_process_step              integer                   not null
        constraint fk_deviation_process
            references dim_process_step
            on update cascade on delete restrict,          -- Process step where occurred

    id_root_cause                integer                                    -- NULL allowed
        constraint fk_deviation_cause
            references dim_root_cause
            on update cascade on delete set null,          -- Root cause (NULL until investigation complete)


    -- ===================================================
    -- MEASURES (Aggregatable Numeric Facts)
    -- ===================================================

    batch_number                 varchar(50)               not null,        -- Batch identifier (degenerate dimension)
    affected_quantity            integer,                                   -- Total units impacted (NULL if not quantifiable)
    rejected_quantity            integer        default 0  not null,        -- Units scrapped
    rework_quantity              integer        default 0  not null,        -- Units reworked
    financial_impact             numeric(15, 2) default 0.00               not null  -- USD loss estimate
        constraint chk_financial
            check (financial_impact >= (0)::numeric),                       -- Non-negative
    downtime_minutes             integer        default 0  not null         -- Production stoppage
        constraint chk_downtime
            check (downtime_minutes >= 0),                                  -- Non-negative


    -- ===================================================
    -- ATTRIBUTES (Descriptive, Non-Aggregatable)
    -- ===================================================

    -- Severity & Classification
    severity_level               varchar(20)               not null
        constraint chk_severity_level
            check ((severity_level)::text = ANY
                   ((ARRAY ['Critical'::character varying,                 -- Patient safety / recall
                       'Major'::character varying,                     -- Batch rejection likely
                       'Medium'::character varying,                    -- ⚠️ NOTE: Added in this version
                       'Minor'::character varying])::text[])),        -- Limited impact

    detection_method             varchar(50)               not null
        constraint chk_detection_method
            check ((detection_method)::text = ANY
                   ((ARRAY ['In_Process'::character varying,               -- Caught during mfg (best)
                       'Final_Inspection'::character varying,          -- Caught at release (good)
                       'Customer_Complaint'::character varying,        -- Escaped to customer (bad)
                       'Stability_Testing'::character varying,         -- Found in stability (bad)
                       'Audit_Finding'::character varying])::text[])), -- Found by auditor (bad)

    -- Status Tracking
    status                       varchar(30)    default 'Open'::character varying not null
        constraint chk_status
            check ((status)::text = ANY
                   ((ARRAY ['Open'::character varying,                     -- Initial state
                       'Under_Investigation'::character varying,       -- Investigation ongoing
                       'CAPA_Required'::character varying,             -- Needs formal CAPA
                       'Closed'::character varying])::text[])),       -- Completed

    -- Regulatory
    is_reportable                boolean        default false not null,     -- FDA/EMA reporting required (21 CFR Part 314.80)

    -- People & Dates
    reported_by                  varchar(100)              not null,        -- Reporter name
    reported_date                date                      not null,        -- When reported
    investigation_completed_date date,                                      -- When investigation done (NULL if ongoing)
    closed_date                  date,                                      -- When closed (NULL if open)

    -- Description
    deviation_description        text                      not null,        -- Full narrative description


    -- ===================================================
    -- BUSINESS LOGIC CONSTRAINTS
    -- ===================================================

    -- Constraint 1: Quantity Validation
    constraint chk_quantities
        check ((rejected_quantity >= 0) AND
               (rework_quantity >= 0) AND
               ((affected_quantity IS NULL) OR (affected_quantity >= 0)) AND
               ((affected_quantity IS NULL) OR ((rejected_quantity + rework_quantity) <= affected_quantity))),

    -- Constraint 2: Date Sequence Validation
    constraint chk_dates_sequence
        check ((reported_date >= deviation_date) AND
               ((investigation_completed_date IS NULL) OR (investigation_completed_date >= reported_date)) AND
               ((closed_date IS NULL) OR (closed_date >= reported_date))),

    -- Constraint 3: Status-Date Correlation
    constraint chk_closed_logic
        check ((((status)::text = 'Closed'::text) AND (closed_date IS NOT NULL)) OR
               (((status)::text <> 'Closed'::text) AND (closed_date IS NULL)))
);

-- Table Ownership
alter table fact_deviation
    owner to postgres;


-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================
-- Run these after deployment to verify schema

-- Query 1: List all tables
-- SELECT table_name FROM information_schema.tables
-- WHERE table_schema = current_schema()
-- ORDER BY table_name;
-- Expected: 7 tables

-- Query 2: Count indexes per table
-- SELECT tablename, COUNT(*) as index_count
-- FROM pg_indexes
-- WHERE schemaname = current_schema()
-- GROUP BY tablename
-- ORDER BY tablename;
-- Expected: 45 total indexes

-- Query 3: Check all constraints
-- SELECT conname, contype, conrelid::regclass
-- FROM pg_constraint
-- WHERE connamespace = current_schema()::regnamespace
-- ORDER BY conrelid::regclass, contype;
-- Expected: 30+ constraints

-- =====================================================
-- END OF SCHEMA
-- =====================================================
