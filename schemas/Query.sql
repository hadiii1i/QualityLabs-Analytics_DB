-- =====================================================
-- PHARMACEUTICAL QMS OLAP DATABASE
-- PostgreSQL 12+ | Schema: qms
-- Star Schema Design for Quality Analytics
-- =====================================================

CREATE TABLE qms.dim_time
(
    id_time         INTEGER GENERATED ALWAYS AS IDENTITY,
    full_date       DATE NOT NULL,
    day_of_week     SMALLINT NOT NULL,
    day_name        VARCHAR(10) NOT NULL,
    week_of_year    SMALLINT NOT NULL,
    month_number    SMALLINT NOT NULL,
    quarter         SMALLINT NOT NULL,
    year            SMALLINT NOT NULL,
    is_weekend      BOOLEAN NOT NULL DEFAULT FALSE,
    is_holiday      BOOLEAN NOT NULL DEFAULT FALSE,
    fiscal_quarter  SMALLINT,
    fiscal_year     SMALLINT,

    CONSTRAINT dim_time_pk PRIMARY KEY (id_time),
    CONSTRAINT dim_time_uq UNIQUE (full_date)
);

COMMENT ON TABLE qms.dim_time IS
    'Date dimension providing consistent time context for QA/QMS event analysis. Grain: One row per calendar day. Purpose: Enables trend analysis, seasonality detection, year-over-year / quarter-over-quarter / month-over-month comparisons of deviations, NCRs, CAPAs, audit findings and process incidents. All attributes are derived / calculated from the full_date column. Surrogate key: id_time (auto-increment integer) Business key / natural key: full_date (date)';

CREATE INDEX idx_dim_time_full_date
    ON qms.dim_time (full_date);

CREATE INDEX idx_dim_time_year_quarter
    ON qms.dim_time (year, quarter);


-- =====================================================
-- DIMENSION TABLE 2: dim_organization
-- Grain: One row per organizational unit version
-- SCD Type 2: effective_date, end_date, is_active
-- =====================================================

CREATE TABLE qms.dim_organization
(
    id_organization INTEGER GENERATED ALWAYS AS IDENTITY,
    org_code        VARCHAR(20) NOT NULL,
    org_name        VARCHAR(100) NOT NULL,
    org_type        VARCHAR(50) NOT NULL,
    parent_org_code VARCHAR(20),
    site_location   VARCHAR(100),
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    effective_date  DATE NOT NULL,
    end_date        DATE,

    CONSTRAINT dim_organization_pk PRIMARY KEY (id_organization),
    CONSTRAINT dim_organization_uq UNIQUE (org_code, effective_date),
    CONSTRAINT chk_org_dates CHECK (end_date IS NULL OR end_date >= effective_date)
);

COMMENT ON TABLE qms.dim_organization IS
    'SCD Type 2 Dimension - Grain: One row per organizational unit version valid during a specific time period (effective_date to end_date). Supports traceability of organizational changes in QA/QMS events.';

COMMENT ON COLUMN qms.dim_organization.parent_org_code IS
    'Self-referencing foreign key for organizational hierarchy. NULL indicates top-level unit.';

CREATE INDEX idx_dim_org_code
    ON qms.dim_organization (org_code);

CREATE INDEX idx_dim_org_type
    ON qms.dim_organization (org_type);

CREATE INDEX idx_dim_org_active
    ON qms.dim_organization (is_active);

CREATE INDEX idx_dim_org_parent
    ON qms.dim_organization (parent_org_code);


-- =====================================================
-- DIMENSION TABLE 3: dim_product
-- Grain: One row per product formulation version
-- SCD Type 2: effective_date, end_date, is_active
-- =====================================================

CREATE TABLE qms.dim_product
(
    id_product          INTEGER GENERATED ALWAYS AS IDENTITY,
    product_code        VARCHAR(30) NOT NULL,
    product_name        VARCHAR(150) NOT NULL,
    generic_name        VARCHAR(150) NOT NULL,
    dosage_form         VARCHAR(50) NOT NULL,
    strength            VARCHAR(50) NOT NULL,
    formulation_version VARCHAR(20) NOT NULL,
    regulatory_status   VARCHAR(50) NOT NULL,
    approval_date       DATE,
    product_category    VARCHAR(100) NOT NULL,
    manufacturer_code   VARCHAR(30),
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    effective_date      DATE NOT NULL,
    end_date            DATE,

    CONSTRAINT dim_product_pk PRIMARY KEY (id_product),
    CONSTRAINT dim_product_uq UNIQUE (product_code, effective_date),
    CONSTRAINT chk_product_dates CHECK (end_date IS NULL OR end_date >= effective_date),
    CONSTRAINT chk_regulatory_status CHECK (
        regulatory_status IN (
                              'Under_Development',
                              'Under_Review',
                              'Approved',
                              'Active_Production',
                              'Discontinued',
                              'Recalled'
            )
        )
);

COMMENT ON TABLE qms.dim_product IS
    'SCD Type 2 Dimension - Grain: One row per product formulation version valid during a specific time period (effective_date to end_date). Supports traceability of product-related quality events across formulation changes and regulatory status transitions.';

COMMENT ON COLUMN qms.dim_product.formulation_version IS
    'Version identifier for formulation changes (e.g., F-01, F-02). New version creates new row for historical tracking.';

COMMENT ON COLUMN qms.dim_product.regulatory_status IS
    'Current regulatory approval status. Valid values: Under_Development, Under_Review, Approved, Active_Production, Discontinued, Recalled.';

CREATE INDEX idx_dim_product_code
    ON qms.dim_product (product_code);

CREATE INDEX idx_dim_product_name
    ON qms.dim_product (product_name);

CREATE INDEX idx_dim_product_category
    ON qms.dim_product (product_category);

CREATE INDEX idx_dim_product_status
    ON qms.dim_product (regulatory_status);

CREATE INDEX idx_dim_product_active
    ON qms.dim_product (is_active);


-- =====================================================
-- DIMENSION TABLE 4: dim_equipment
-- Grain: One row per equipment configuration version
-- SCD Type 2: effective_date, end_date, is_active
-- =====================================================

CREATE TABLE qms.dim_equipment
(
    id_equipment          INTEGER GENERATED ALWAYS AS IDENTITY,
    equipment_code        VARCHAR(30) NOT NULL,
    equipment_name        VARCHAR(150) NOT NULL,
    equipment_type        VARCHAR(50) NOT NULL,
    manufacturer          VARCHAR(100) NOT NULL,
    model_number          VARCHAR(50) NOT NULL,
    serial_number         VARCHAR(50) NOT NULL,
    installation_date     DATE NOT NULL,
    calibration_status    VARCHAR(30) NOT NULL,
    last_calibration_date DATE,
    next_calibration_date DATE,
    location              VARCHAR(100) NOT NULL,
    operational_status    VARCHAR(30) NOT NULL DEFAULT 'Operational',
    is_active             BOOLEAN NOT NULL DEFAULT TRUE,
    effective_date        DATE NOT NULL,
    end_date              DATE,

    CONSTRAINT dim_equipment_pk PRIMARY KEY (id_equipment),
    CONSTRAINT uq_equipment_version UNIQUE (equipment_code, effective_date),
    CONSTRAINT uq_serial_number UNIQUE (serial_number),
    CONSTRAINT chk_equipment_dates CHECK (end_date IS NULL OR end_date >= effective_date),
    CONSTRAINT chk_calibration_dates CHECK (
        last_calibration_date IS NULL OR
        next_calibration_date IS NULL OR
        next_calibration_date >= last_calibration_date
        ),
    CONSTRAINT chk_equipment_type CHECK (
        equipment_type IN (
                           'Production',
                           'Testing',
                           'Packaging',
                           'Storage',
                           'Cleaning'
            )
        ),
    CONSTRAINT chk_calibration_status CHECK (
        calibration_status IN (
                               'Valid',
                               'Expired',
                               'Pending',
                               'Out_of_Spec'
            )
        ),
    CONSTRAINT chk_operational_status CHECK (
        operational_status IN (
                               'Operational',
                               'Under_Maintenance',
                               'Under_Qualification',
                               'Out_of_Service',
                               'Retired'
            )
        )
);

COMMENT ON TABLE qms.dim_equipment IS
    'SCD Type 2 Dimension - Grain: One row per equipment configuration version valid during a specific time period (effective_date to end_date). New row created for: model upgrade, serial replacement, equipment type change, or critical location change. Tracks equipment state for quality event traceability and compliance analysis.';

COMMENT ON COLUMN qms.dim_equipment.equipment_code IS
    'Logical equipment identifier in system. Can have multiple versions (rows) across time. Use with effective_date for unique identification.';

COMMENT ON COLUMN qms.dim_equipment.serial_number IS
    'Physical manufacturer serial number - globally unique across all equipment versions. Changes only when physical unit is replaced.';

COMMENT ON COLUMN qms.dim_equipment.calibration_status IS
    'Current calibration status. Valid values: Valid, Expired, Pending, Out_of_Spec. Note: Frequent changes should be tracked in fact_calibration_event, not as new dimension rows.';

COMMENT ON COLUMN qms.dim_equipment.operational_status IS
    'Current operational state. Valid values: Operational, Under_Maintenance, Under_Qualification, Out_of_Service, Retired. Note: State transitions should be tracked in fact_equipment_event.';

CREATE INDEX idx_dim_equipment_code
    ON qms.dim_equipment (equipment_code);

CREATE INDEX idx_dim_equipment_serial
    ON qms.dim_equipment (serial_number);

CREATE INDEX idx_dim_equipment_type
    ON qms.dim_equipment (equipment_type);

CREATE INDEX idx_dim_equipment_status
    ON qms.dim_equipment (operational_status);

CREATE INDEX idx_dim_equipment_calibration
    ON qms.dim_equipment (calibration_status);

CREATE INDEX idx_dim_equipment_location
    ON qms.dim_equipment (location);

CREATE INDEX idx_dim_equipment_active
    ON qms.dim_equipment (is_active);


-- =====================================================
-- DIMENSION TABLE 5: dim_process_step
-- Grain: One row per process step configuration version
-- SCD Type 2: effective_date, end_date, is_active
-- =====================================================

CREATE TABLE qms.dim_process_step
(
    id_process_step           INTEGER GENERATED ALWAYS AS IDENTITY,
    process_code              VARCHAR(30) NOT NULL,
    process_name              VARCHAR(100) NOT NULL,
    process_category          VARCHAR(50) NOT NULL,
    process_description       TEXT,
    standard_duration_minutes INTEGER,
    criticality_level         VARCHAR(20) NOT NULL DEFAULT 'Medium',
    requires_validation       BOOLEAN NOT NULL DEFAULT FALSE,
    sequence_order            SMALLINT,
    is_active                 BOOLEAN NOT NULL DEFAULT TRUE,
    effective_date            DATE NOT NULL,
    end_date                  DATE,

    CONSTRAINT dim_process_step_pk PRIMARY KEY (id_process_step),
    CONSTRAINT uq_process_version UNIQUE (process_code, effective_date),
    CONSTRAINT chk_process_dates CHECK (end_date IS NULL OR end_date >= effective_date),
    CONSTRAINT chk_duration CHECK (
        standard_duration_minutes IS NULL OR standard_duration_minutes > 0
        ),
    CONSTRAINT chk_sequence CHECK (
        sequence_order IS NULL OR sequence_order > 0
        ),
    CONSTRAINT chk_process_category CHECK (
        process_category IN (
                             'Pre_Compression',
                             'Compression',
                             'Post_Compression',
                             'Quality_Control',
                             'Packaging'
            )
        ),
    CONSTRAINT chk_criticality_level CHECK (
        criticality_level IN ('High', 'Medium', 'Low')
        )
);

COMMENT ON TABLE qms.dim_process_step IS
    'SCD Type 2 Dimension - Grain: One row per process step configuration version valid during a specific time period (effective_date to end_date). New row created for: duration standard change, criticality reclassification, or validation requirement change. Enables process-level quality analysis and bottleneck identification.';

COMMENT ON COLUMN qms.dim_process_step.process_code IS
    'Logical process identifier. Can have multiple versions across time. Use with effective_date for unique identification.';

COMMENT ON COLUMN qms.dim_process_step.process_category IS
    'Process phase classification. Valid values: Pre_Compression, Compression, Post_Compression, Quality_Control, Packaging.';

COMMENT ON COLUMN qms.dim_process_step.criticality_level IS
    'Risk classification for quality impact. High = batch rejection risk, Medium = monitoring required, Low = minimal quality impact.';

COMMENT ON COLUMN qms.dim_process_step.requires_validation IS
    'Indicates if process requires IQ/OQ/PQ validation documentation per regulatory requirements (FDA, EMA).';

COMMENT ON COLUMN qms.dim_process_step.sequence_order IS
    'Typical sequence position in manufacturing workflow. Used for process flow analysis and deviation sequence tracking.';

CREATE INDEX idx_dim_process_code
    ON qms.dim_process_step (process_code);

CREATE INDEX idx_dim_process_category
    ON qms.dim_process_step (process_category);

CREATE INDEX idx_dim_process_criticality
    ON qms.dim_process_step (criticality_level);

CREATE INDEX idx_dim_process_sequence
    ON qms.dim_process_step (sequence_order);

CREATE INDEX idx_dim_process_active
    ON qms.dim_process_step (is_active);


-- =====================================================
-- DIMENSION TABLE 6: dim_root_cause
-- Grain: One row per root cause classification version
-- SCD Type 2: effective_date, end_date, is_active
-- Based on 6M (Ishikawa) methodology
-- =====================================================

CREATE TABLE qms.dim_root_cause
(
    id_root_cause       INTEGER GENERATED ALWAYS AS IDENTITY,
    cause_code          VARCHAR(30) NOT NULL,
    cause_name          VARCHAR(150) NOT NULL,
    cause_category      VARCHAR(50) NOT NULL,
    cause_subcategory   VARCHAR(100),
    cause_description   TEXT,
    severity_potential  VARCHAR(20) NOT NULL DEFAULT 'Medium',
    prevention_strategy TEXT,
    is_systemic         BOOLEAN NOT NULL DEFAULT FALSE,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    effective_date      DATE NOT NULL,
    end_date            DATE,

    CONSTRAINT dim_root_cause_pk PRIMARY KEY (id_root_cause),
    CONSTRAINT uq_cause_version UNIQUE (cause_code, effective_date),
    CONSTRAINT chk_cause_dates CHECK (end_date IS NULL OR end_date >= effective_date),
    CONSTRAINT chk_cause_category CHECK (
        cause_category IN (
                           'Man',
                           'Machine',
                           'Material',
                           'Method',
                           'Measurement',
                           'Environment'
            )
        ),
    CONSTRAINT chk_severity_potential CHECK (
        severity_potential IN ('Critical', 'High', 'Medium', 'Low')
        )
);

COMMENT ON TABLE qms.dim_root_cause IS
    'SCD Type 2 Dimension - Grain: One row per root cause classification version valid during a specific time period (effective_date to end_date). Based on 6M (Ishikawa) methodology. New row created for: category reclassification, severity reassessment, or systemic flag change. Enables root cause trend analysis and CAPA effectiveness tracking.';

COMMENT ON COLUMN qms.dim_root_cause.cause_code IS
    'Logical root cause identifier. Can have multiple versions across time as understanding of cause evolves.';

COMMENT ON COLUMN qms.dim_root_cause.cause_category IS
    'Primary classification per 6M framework. Valid values: Man, Machine, Material, Method, Measurement, Environment.';

COMMENT ON COLUMN qms.dim_root_cause.severity_potential IS
    'Risk assessment of cause impact. Critical = patient safety, High = batch rejection, Medium = rework, Low = minimal impact.';

COMMENT ON COLUMN qms.dim_root_cause.prevention_strategy IS
    'Recommended prevention approach based on historical analysis. Updated as lessons learned accumulate.';

COMMENT ON COLUMN qms.dim_root_cause.is_systemic IS
    'Indicates if root cause is systemic (requires CAPA) vs isolated incident (simple correction). Critical for compliance and management escalation.';

CREATE INDEX idx_dim_cause_code
    ON qms.dim_root_cause (cause_code);

CREATE INDEX idx_dim_cause_category
    ON qms.dim_root_cause (cause_category);

CREATE INDEX idx_dim_cause_severity
    ON qms.dim_root_cause (severity_potential);

CREATE INDEX idx_dim_cause_systemic
    ON qms.dim_root_cause (is_systemic);

CREATE INDEX idx_dim_cause_active
    ON qms.dim_root_cause (is_active);


-- =====================================================
-- FACT TABLE 1: fact_deviation
-- Grain: One row per quality deviation event
-- =====================================================

CREATE TABLE qms.fact_deviation
(
    -- Primary Key
    id_deviation                  INTEGER GENERATED ALWAYS AS IDENTITY,
    deviation_number              VARCHAR(50) NOT NULL,

    -- Foreign Keys
    deviation_date                DATE NOT NULL,
    id_product                    INTEGER NOT NULL,
    id_equipment                  INTEGER,
    id_organization               INTEGER NOT NULL,
    id_process_step               INTEGER NOT NULL,
    id_root_cause                 INTEGER,

    -- Measures (aggregatable)
    batch_number                  VARCHAR(50) NOT NULL,
    affected_quantity             INTEGER,
    rejected_quantity             INTEGER NOT NULL DEFAULT 0,
    rework_quantity               INTEGER NOT NULL DEFAULT 0,
    financial_impact              NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    downtime_minutes              INTEGER NOT NULL DEFAULT 0,

    -- Attributes (descriptive)
    severity_level                VARCHAR(20) NOT NULL,
    detection_method              VARCHAR(50) NOT NULL,
    status                        VARCHAR(30) NOT NULL DEFAULT 'Open',
    is_reportable                 BOOLEAN NOT NULL DEFAULT FALSE,
    reported_by                   VARCHAR(100) NOT NULL,
    reported_date                 DATE NOT NULL,
    investigation_completed_date  DATE,
    closed_date                   DATE,
    deviation_description         TEXT NOT NULL,

    -- Constraints
    CONSTRAINT fact_deviation_pk PRIMARY KEY (id_deviation),
    CONSTRAINT uq_deviation_number UNIQUE (deviation_number),

    -- Foreign Key Constraints
    CONSTRAINT fk_deviation_time
        FOREIGN KEY (deviation_date)
            REFERENCES qms.dim_time(full_date)
            ON DELETE RESTRICT
            ON UPDATE CASCADE,

    CONSTRAINT fk_deviation_product
        FOREIGN KEY (id_product)
            REFERENCES qms.dim_product(id_product)
            ON DELETE RESTRICT
            ON UPDATE CASCADE,

    CONSTRAINT fk_deviation_equipment
        FOREIGN KEY (id_equipment)
            REFERENCES qms.dim_equipment(id_equipment)
            ON DELETE SET NULL
            ON UPDATE CASCADE,

    CONSTRAINT fk_deviation_organization
        FOREIGN KEY (id_organization)
            REFERENCES qms.dim_organization(id_organization)
            ON DELETE RESTRICT
            ON UPDATE CASCADE,

    CONSTRAINT fk_deviation_process
        FOREIGN KEY (id_process_step)
            REFERENCES qms.dim_process_step(id_process_step)
            ON DELETE RESTRICT
            ON UPDATE CASCADE,

    CONSTRAINT fk_deviation_cause
        FOREIGN KEY (id_root_cause)
            REFERENCES qms.dim_root_cause(id_root_cause)
            ON DELETE SET NULL
            ON UPDATE CASCADE,

    -- Business Logic Constraints
    CONSTRAINT chk_quantities CHECK (
        rejected_quantity >= 0 AND
        rework_quantity >= 0 AND
        (affected_quantity IS NULL OR affected_quantity >= 0) AND
        (affected_quantity IS NULL OR (rejected_quantity + rework_quantity <= affected_quantity))
        ),

    CONSTRAINT chk_financial CHECK (
        financial_impact >= 0
        ),

    CONSTRAINT chk_downtime CHECK (
        downtime_minutes >= 0
        ),

    CONSTRAINT chk_dates_sequence CHECK (
        reported_date >= deviation_date AND
        (investigation_completed_date IS NULL OR investigation_completed_date >= reported_date) AND
        (closed_date IS NULL OR closed_date >= reported_date)
        ),

    CONSTRAINT chk_severity_level CHECK (
        severity_level IN ('Critical', 'Major', 'Minor')
        ),

    CONSTRAINT chk_detection_method CHECK (
        detection_method IN (
                             'In_Process',
                             'Final_Inspection',
                             'Customer_Complaint',
                             'Stability_Testing',
                             'Audit_Finding'
            )
        ),

    CONSTRAINT chk_status CHECK (
        status IN ('Open', 'Under_Investigation', 'CAPA_Required', 'Closed')
        ),

    CONSTRAINT chk_closed_logic CHECK (
        (status = 'Closed' AND closed_date IS NOT NULL) OR
        (status != 'Closed' AND closed_date IS NULL)
        )
);

-- Table Comment
COMMENT ON TABLE qms.fact_deviation IS
    'Fact table for quality deviations - Grain: One row per deviation event at a specific time, product, process step, and organization. NULL FK allowed: id_equipment (non-equipment deviations), id_root_cause (populated after investigation). Measures: quantities, financial impact, downtime. Purpose: Deviation trend analysis, root cause frequency, process weakness detection, financial impact tracking, CAPA trigger identification.';

-- Column Comments
COMMENT ON COLUMN qms.fact_deviation.id_deviation IS
    'Surrogate primary key - auto-generated integer.';

COMMENT ON COLUMN qms.fact_deviation.deviation_number IS
    'Business key - unique identifier (format: DEV-YYYY-NNN). Example: DEV-2025-001.';

COMMENT ON COLUMN qms.fact_deviation.id_equipment IS
    'FK to dim_equipment. NULL allowed for deviations not related to equipment (e.g., documentation, materials).';

COMMENT ON COLUMN qms.fact_deviation.id_root_cause IS
    'FK to dim_root_cause. NULL until investigation completes and root cause is identified.';

COMMENT ON COLUMN qms.fact_deviation.affected_quantity IS
    'Total quantity impacted by deviation. NULL if not quantifiable (e.g., documentation deviation).';

COMMENT ON COLUMN qms.fact_deviation.financial_impact IS
    'Estimated financial loss in USD. Includes: material waste, rework labor, batch rejection, investigation costs.';

COMMENT ON COLUMN qms.fact_deviation.severity_level IS
    'Critical=patient safety risk/recall required, Major=batch rejection likely, Minor=limited impact/correctable.';

COMMENT ON COLUMN qms.fact_deviation.detection_method IS
    'Where deviation was caught. Earlier detection (In_Process) = better quality system. Customer_Complaint = escaped defect (critical issue).';

COMMENT ON COLUMN qms.fact_deviation.is_reportable IS
    'Regulatory reporting required per 21 CFR Part 314.80 or ICH E2A. TRUE = report to FDA/EMA within timeframe.';

-- Indexes for query performance
CREATE INDEX idx_fact_deviation_date
    ON qms.fact_deviation (deviation_date);

CREATE INDEX idx_fact_deviation_product
    ON qms.fact_deviation (id_product);

CREATE INDEX idx_fact_deviation_equipment
    ON qms.fact_deviation (id_equipment);

CREATE INDEX idx_fact_deviation_org
    ON qms.fact_deviation (id_organization);

CREATE INDEX idx_fact_deviation_process
    ON qms.fact_deviation (id_process_step);

CREATE INDEX idx_fact_deviation_cause
    ON qms.fact_deviation (id_root_cause);

CREATE INDEX idx_fact_deviation_severity
    ON qms.fact_deviation (severity_level);

CREATE INDEX idx_fact_deviation_status
    ON qms.fact_deviation (status);

CREATE INDEX idx_fact_deviation_batch
    ON qms.fact_deviation (batch_number);

CREATE INDEX idx_fact_deviation_reportable
    ON qms.fact_deviation (is_reportable);

-- Composite indexes for common analytical queries
CREATE INDEX idx_fact_deviation_date_severity
    ON qms.fact_deviation (deviation_date, severity_level);

CREATE INDEX idx_fact_deviation_product_date
    ON qms.fact_deviation (id_product, deviation_date);
