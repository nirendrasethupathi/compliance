
   INFO  Preparing database.  

  Creating migration table ...................................... 15.77ms DONE

   INFO  Running migrations.  

  0001_01_01_000000_create_users_table .......................................  
  ⇂ create table "users" ("id" integer primary key autoincrement not null, "name" varchar not null, "email" varchar not null, "email_verified_at" datetime, "password" varchar not null, "remember_token" varchar, "created_at" datetime, "updated_at" datetime)  
  ⇂ create unique index "users_email_unique" on "users" ("email")  
  ⇂ create table "password_reset_tokens" ("email" varchar not null, "token" varchar not null, "created_at" datetime, primary key ("email"))  
  ⇂ create table "sessions" ("id" varchar not null, "user_id" integer, "ip_address" varchar, "user_agent" text, "payload" text not null, "last_activity" integer not null, primary key ("id"))  
  ⇂ create index "sessions_user_id_index" on "sessions" ("user_id")  
  ⇂ create index "sessions_last_activity_index" on "sessions" ("last_activity")  
  0001_01_01_000001_create_cache_table .......................................  
  ⇂ create table "cache" ("key" varchar not null, "value" text not null, "expiration" integer not null, primary key ("key"))  
  ⇂ create index "cache_expiration_index" on "cache" ("expiration")  
  ⇂ create table "cache_locks" ("key" varchar not null, "owner" varchar not null, "expiration" integer not null, primary key ("key"))  
  ⇂ create index "cache_locks_expiration_index" on "cache_locks" ("expiration")  
  0001_01_01_000002_create_jobs_table ........................................  
  ⇂ create table "jobs" ("id" integer primary key autoincrement not null, "queue" varchar not null, "payload" text not null, "attempts" integer not null, "reserved_at" integer, "available_at" integer not null, "created_at" integer not null)  
  ⇂ create index "jobs_queue_index" on "jobs" ("queue")  
  ⇂ create table "job_batches" ("id" varchar not null, "name" varchar not null, "total_jobs" integer not null, "pending_jobs" integer not null, "failed_jobs" integer not null, "failed_job_ids" text not null, "options" text, "cancelled_at" integer, "created_at" integer not null, "finished_at" integer, primary key ("id"))  
  ⇂ create table "failed_jobs" ("id" integer primary key autoincrement not null, "uuid" varchar not null, "connection" text not null, "queue" text not null, "payload" text not null, "exception" text not null, "failed_at" datetime not null default CURRENT_TIMESTAMP)  
  ⇂ create unique index "failed_jobs_uuid_unique" on "failed_jobs" ("uuid")  
  2024_01_01_000000_create_tenants_table .....................................  
  ⇂ create table "tenants" ("id" integer primary key autoincrement not null, "name" varchar not null, "created_at" datetime, "updated_at" datetime)  
  2024_01_01_000001_create_branches_table ....................................  
  ⇂ create table "branches" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "branch_name" varchar not null, "unit_name" varchar, "factory_license_number" varchar, "address" text, "pf_code" varchar, "esi_code" varchar, "created_at" datetime, "updated_at" datetime, foreign key("tenant_id") references "tenants"("id") on delete cascade)  
  ⇂ create index "branches_tenant_id_branch_name_index" on "branches" ("tenant_id", "branch_name")  
  ⇂ create index "branches_tenant_id_index" on "branches" ("tenant_id")  
  2024_01_01_000001_create_workforce_employee_table ..........................  
  ⇂ create table "workforce_employee" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "branch_id" integer, "employee_code" varchar not null, "name" varchar not null, "pf_number" varchar, "esi_number" varchar, "date_of_joining" date not null, "designation" varchar, "department" varchar, "basic_salary" numeric not null default '0', "status" varchar not null default 'active', "created_at" datetime, "updated_at" datetime, "deleted_at" datetime, foreign key("tenant_id") references "tenants"("id") on delete cascade, foreign key("branch_id") references "branches"("id") on delete set null)  
  ⇂ create index "workforce_employee_tenant_id_index" on "workforce_employee" ("tenant_id")  
  ⇂ create index "workforce_employee_branch_id_index" on "workforce_employee" ("branch_id")  
  ⇂ create unique index "workforce_employee_employee_code_unique" on "workforce_employee" ("employee_code")  
  2024_01_01_000003_create_payroll_cycles_table ..............................  
  ⇂ create table "payroll_cycles" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "cycle_name" varchar not null, "period_from" date not null, "period_to" date not null, "processed_at" datetime, "status" varchar not null default 'pending', "created_at" datetime, "updated_at" datetime, foreign key("tenant_id") references "tenants"("id") on delete cascade)  
  2024_01_01_000003_create_payroll_settings_table ............................  
  ⇂ create table "payroll_settings" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "pf_rate" numeric not null default '12', "esi_rate" numeric not null default '0.75', "ot_multiplier" numeric not null default '2', "bonus_min_percent" numeric not null default '8.33', "bonus_max_percent" numeric not null default '20', "created_at" datetime, "updated_at" datetime, foreign key("tenant_id") references "tenants"("id") on delete cascade)  
  ⇂ create unique index "payroll_settings_tenant_id_unique" on "payroll_settings" ("tenant_id")  
  2024_01_01_000004_create_payroll_entries_table .............................  
  ⇂ create table "payroll_entries" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "branch_id" integer, "employee_id" integer not null, "payroll_cycle_id" integer not null, "total_days_worked" integer not null, "paid_leave_days" integer not null default '0', "unpaid_leave_days" integer not null default '0', "overtime_hours" numeric not null default '0', "basic_earned" numeric not null, "da_earned" numeric not null default '0', "hra_earned" numeric not null default '0', "other_allowances" numeric not null default '0', "overtime_wages" numeric not null default '0', "gross_salary" numeric not null, "pf_employee" numeric not null default '0', "esi_employee" numeric not null default '0', "professional_tax" numeric not null default '0', "fines" numeric not null default '0', "advances" numeric not null default '0', "other_deductions" numeric not null default '0', "total_deductions" numeric not null default '0', "net_salary" numeric not null, "payment_date" date, "payment_mode" varchar, "transaction_reference" varchar, "created_at" datetime, "updated_at" datetime, "deleted_at" datetime, foreign key("tenant_id") references "tenants"("id") on delete cascade, foreign key("branch_id") references "branches"("id") on delete set null, foreign key("employee_id") references "workforce_employee"("id") on delete cascade, foreign key("payroll_cycle_id") references "payroll_cycles"("id") on delete cascade)  
  ⇂ create index "payroll_entries_tenant_id_branch_id_payroll_cycle_id_index" on "payroll_entries" ("tenant_id", "branch_id", "payroll_cycle_id")  
  ⇂ create index "payroll_entries_employee_id_payroll_cycle_id_index" on "payroll_entries" ("employee_id", "payroll_cycle_id")  
  ⇂ create index "payroll_entries_tenant_id_index" on "payroll_entries" ("tenant_id")  
  ⇂ create index "payroll_entries_branch_id_index" on "payroll_entries" ("branch_id")  
  ⇂ create index "payroll_entries_employee_id_index" on "payroll_entries" ("employee_id")  
  ⇂ create index "payroll_entries_payroll_cycle_id_index" on "payroll_entries" ("payroll_cycle_id")  
  2024_01_01_000005_create_bonus_records_table ...............................  
  ⇂ create table "bonus_records" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "branch_id" integer, "employee_id" integer not null, "financial_year" varchar not null, "bonus_percentage" numeric not null, "bonus_amount" numeric not null, "payment_date" date, "created_at" datetime, "updated_at" datetime, "deleted_at" datetime, foreign key("tenant_id") references "tenants"("id") on delete cascade, foreign key("branch_id") references "branches"("id") on delete set null, foreign key("employee_id") references "workforce_employee"("id") on delete cascade)  
  ⇂ create index "bonus_records_tenant_id_branch_id_financial_year_index" on "bonus_records" ("tenant_id", "branch_id", "financial_year")  
  ⇂ create index "bonus_records_tenant_id_index" on "bonus_records" ("tenant_id")  
  ⇂ create index "bonus_records_branch_id_index" on "bonus_records" ("branch_id")  
  ⇂ create index "bonus_records_employee_id_index" on "bonus_records" ("employee_id")  
  ⇂ create index "bonus_records_financial_year_index" on "bonus_records" ("financial_year")  
  2024_01_01_000006_create_contractor_compliance_table .......................  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'contractor_compliance' and type = 'table') as "exists"  
  ⇂ create table "contractor_compliance" ("id" integer primary key autoincrement not null, "contractor_id" integer not null, "branch_id" integer, "clra_license_number" varchar, "license_valid_from" date, "license_valid_to" date, "max_worker_limit" integer not null default '0', "pf_code" varchar, "esi_code" varchar, "labour_registration_number" varchar, "last_return_filed" date, "is_compliant" tinyint(1) not null default '1', "compliance_notes" text, "created_at" datetime, "updated_at" datetime, "deleted_at" datetime, foreign key("contractor_id") references "contractor_master"("id") on delete cascade)  
  ⇂ create index "contractor_compliance_contractor_id_branch_id_index" on "contractor_compliance" ("contractor_id", "branch_id")  
  ⇂ create index "contractor_compliance_contractor_id_index" on "contractor_compliance" ("contractor_id")  
  ⇂ create index "contractor_compliance_branch_id_index" on "contractor_compliance" ("branch_id")  
  2024_01_01_000006_create_contractor_master_table ...........................  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'contractor_master' and type = 'table') as "exists"  
  ⇂ create table "contractor_master" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "company_type" varchar, "company_name" varchar not null, "license_number" varchar, "valid_from" date, "valid_to" date, "max_worker_limit" integer not null default '0', "company_address" varchar, "contact_person" varchar, "contact_number" varchar, "email" varchar, "pan_number" varchar, "gst_number" varchar, "status" varchar not null default 'active', "created_at" datetime, "updated_at" datetime, "deleted_at" datetime, foreign key("tenant_id") references "tenants"("id") on delete cascade)  
  ⇂ create index "contractor_master_tenant_id_company_name_index" on "contractor_master" ("tenant_id", "company_name")  
  ⇂ create index "contractor_master_tenant_id_index" on "contractor_master" ("tenant_id")  
  2024_01_01_000006_create_contractors_table .................................  
  ⇂ create table "contractors" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "contractor_name" varchar not null, "license_number" varchar not null, "valid_from" date not null, "valid_to" date not null, "max_worker_limit" integer not null, "pf_code" varchar, "esi_code" varchar, "created_at" datetime, "updated_at" datetime, "deleted_at" datetime, foreign key("tenant_id") references "tenants"("id") on delete cascade)  
  ⇂ create index "contractors_tenant_id_license_number_index" on "contractors" ("tenant_id", "license_number")  
  ⇂ create index "contractors_tenant_id_index" on "contractors" ("tenant_id")  
  ⇂ create index "contractors_license_number_index" on "contractors" ("license_number")  
  2024_01_01_000007_create_all_contractor_tables .............................  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'contract_labour_deployment' and type = 'table') as "exists"  
  ⇂ create table "contract_labour_deployment" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "branch_id" integer, "contractor_id" integer, "contractor_compliance_id" integer, "employee_id" integer not null, "wage_rate" numeric not null, "deployment_start" date not null, "deployment_end" date, "work_order_number" varchar, "work_order_date" date, "status" varchar not null default 'active', "overtime_hours" numeric not null default '0', "overtime_wages" numeric not null default '0', "deployment_date" date, "workmen_count" integer not null default '0', "work_description" text, "remarks" text, "nature_of_work" varchar, "work_location" varchar, "termination_reason" varchar, "created_at" datetime, "updated_at" datetime, "deleted_at" datetime, foreign key("tenant_id") references "tenants"("id") on delete cascade, foreign key("employee_id") references "workforce_employee"("id") on delete cascade)  
  ⇂ create index "contract_labour_deployment_tenant_id_contractor_id_index" on "contract_labour_deployment" ("tenant_id", "contractor_id")  
  ⇂ create index "contract_labour_deployment_contractor_id_employee_id_index" on "contract_labour_deployment" ("contractor_id", "employee_id")  
  ⇂ create index "contract_labour_deployment_tenant_id_index" on "contract_labour_deployment" ("tenant_id")  
  ⇂ create index "contract_labour_deployment_branch_id_index" on "contract_labour_deployment" ("branch_id")  
  ⇂ create index "contract_labour_deployment_contractor_id_index" on "contract_labour_deployment" ("contractor_id")  
  ⇂ create index "contract_labour_deployment_contractor_compliance_id_index" on "contract_labour_deployment" ("contractor_compliance_id")  
  ⇂ create index "contract_labour_deployment_employee_id_index" on "contract_labour_deployment" ("employee_id")  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'contractor_master' and type = 'table') as "exists"  
  ⇂ create table "contractor_master" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "branch_id" integer, "company_type" varchar, "company_name" varchar not null, "contractor_code" varchar, "contractor_name" varchar, "license_number" varchar, "valid_from" date, "valid_to" date, "max_worker_limit" integer not null default '0', "company_address" varchar, "address" text, "contact_person" varchar, "contact_number" varchar, "phone" varchar, "email" varchar, "pan_number" varchar, "gst_number" varchar, "license_no" varchar, "license_expiry" date, "status" varchar not null default 'active', "created_at" datetime, "updated_at" datetime, "deleted_at" datetime, foreign key("tenant_id") references "tenants"("id") on delete cascade)  
  ⇂ create index "contractor_master_tenant_id_company_name_index" on "contractor_master" ("tenant_id", "company_name")  
  ⇂ create index "contractor_master_tenant_id_index" on "contractor_master" ("tenant_id")  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'contractor_compliance' and type = 'table') as "exists"  
  ⇂ create table "contractor_compliance" ("id" integer primary key autoincrement not null, "contractor_id" integer not null, "branch_id" integer, "clra_license_number" varchar, "license_valid_from" date, "license_valid_to" date, "max_worker_limit" integer not null default '0', "pf_code" varchar, "esi_code" varchar, "labour_registration_number" varchar, "last_return_filed" date, "is_compliant" tinyint(1) not null default '1', "compliance_notes" text, "created_at" datetime, "updated_at" datetime, "deleted_at" datetime, foreign key("contractor_id") references "contractor_master"("id") on delete cascade)  
  ⇂ create index "contractor_compliance_contractor_id_branch_id_index" on "contractor_compliance" ("contractor_id", "branch_id")  
  ⇂ create index "contractor_compliance_contractor_id_index" on "contractor_compliance" ("contractor_id")  
  ⇂ create index "contractor_compliance_branch_id_index" on "contractor_compliance" ("branch_id")  
  2024_01_01_000007_create_clra_returns_table ................................  
  ⇂ create table "clra_returns" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "return_type" varchar check ("return_type" in ('half_yearly', 'annual')) not null, "period_from" date not null, "period_to" date not null, "total_workers" integer not null, "total_wages" numeric not null, "total_ot" numeric not null default '0', "total_deductions" numeric not null default '0', "created_at" datetime, "updated_at" datetime, "deleted_at" datetime, foreign key("tenant_id") references "tenants"("id") on delete cascade)  
  ⇂ create index "clra_returns_tenant_id_index" on "clra_returns" ("tenant_id")  
  ⇂ create index "clra_returns_return_type_index" on "clra_returns" ("return_type")  
  2024_01_01_000007_create_contract_labour_deployment_table ..................  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'contract_labour_deployment' and type = 'table') as "exists"  
  ⇂ create table "contract_labour_deployment" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "branch_id" integer, "contractor_id" integer, "contractor_compliance_id" integer, "employee_id" integer not null, "wage_rate" numeric not null, "deployment_start" date not null, "deployment_end" date, "work_order_number" varchar, "work_order_date" date, "status" varchar not null default 'active', "created_at" datetime, "updated_at" datetime, "deleted_at" datetime, foreign key("tenant_id") references "tenants"("id") on delete cascade, foreign key("employee_id") references "workforce_employee"("id") on delete cascade)  
  ⇂ create index "contract_labour_deployment_tenant_id_contractor_id_index" on "contract_labour_deployment" ("tenant_id", "contractor_id")  
  ⇂ create index "contract_labour_deployment_contractor_id_employee_id_index" on "contract_labour_deployment" ("contractor_id", "employee_id")  
  ⇂ create index "contract_labour_deployment_tenant_id_index" on "contract_labour_deployment" ("tenant_id")  
  ⇂ create index "contract_labour_deployment_branch_id_index" on "contract_labour_deployment" ("branch_id")  
  ⇂ create index "contract_labour_deployment_contractor_id_index" on "contract_labour_deployment" ("contractor_id")  
  ⇂ create index "contract_labour_deployment_contractor_compliance_id_index" on "contract_labour_deployment" ("contractor_compliance_id")  
  ⇂ create index "contract_labour_deployment_employee_id_index" on "contract_labour_deployment" ("employee_id")  
  2024_01_01_000007_create_contract_labour_table .............................  
  ⇂ create table "contract_labour" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "contractor_id" integer not null, "employee_id" integer not null, "deployment_location" varchar, "wage_rate" numeric not null, "employment_start" date not null, "employment_end" date, "created_at" datetime, "updated_at" datetime, "deleted_at" datetime, foreign key("tenant_id") references "tenants"("id") on delete cascade, foreign key("contractor_id") references "contractors"("id") on delete cascade, foreign key("employee_id") references "workforce_employee"("id") on delete cascade)  
  ⇂ create index "contract_labour_tenant_id_contractor_id_index" on "contract_labour" ("tenant_id", "contractor_id")  
  ⇂ create index "contract_labour_contractor_id_employee_id_index" on "contract_labour" ("contractor_id", "employee_id")  
  ⇂ create index "contract_labour_tenant_id_index" on "contract_labour" ("tenant_id")  
  ⇂ create index "contract_labour_contractor_id_index" on "contract_labour" ("contractor_id")  
  ⇂ create index "contract_labour_employee_id_index" on "contract_labour" ("employee_id")  
  2024_01_01_000008_create_incident_documents_table ..........................  
  ⇂ create table "incident_documents" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "employee_id" integer, "incident_type" varchar check ("incident_type" in ('accident', 'serious', 'dangerous', 'esi')) not null, "incident_date" date not null, "location" varchar, "description" text, "authority_name" varchar, "reference_number" varchar, "document_path" varchar not null, "uploaded_by" integer not null, "uploaded_at" datetime not null, "created_at" datetime, "updated_at" datetime, "deleted_at" datetime, foreign key("tenant_id") references "tenants"("id") on delete cascade, foreign key("employee_id") references "workforce_employee"("id") on delete cascade, foreign key("uploaded_by") references "users"("id") on delete cascade)  
  ⇂ create index "incident_documents_tenant_id_index" on "incident_documents" ("tenant_id")  
  ⇂ create index "incident_documents_incident_type_index" on "incident_documents" ("incident_type")  
  ⇂ create index "incident_documents_incident_date_index" on "incident_documents" ("incident_date")  
  2024_01_01_000008_create_workforce_attendance_table ........................  
  ⇂ create table "workforce_attendance" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "employee_id" integer not null, "attendance_date" date not null, "status" varchar check ("status" in ('present', 'absent', 'leave', 'holiday')) not null default 'present', "created_at" datetime, "updated_at" datetime, "deleted_at" datetime, foreign key("tenant_id") references "tenants"("id") on delete cascade, foreign key("employee_id") references "workforce_employee"("id") on delete cascade)  
  ⇂ create unique index "att_unique" on "workforce_attendance" ("tenant_id", "employee_id", "attendance_date")  
  ⇂ create index "workforce_attendance_tenant_id_attendance_date_index" on "workforce_attendance" ("tenant_id", "attendance_date")  
  ⇂ create index "workforce_attendance_tenant_id_index" on "workforce_attendance" ("tenant_id")  
  ⇂ create index "workforce_attendance_employee_id_index" on "workforce_attendance" ("employee_id")  
  ⇂ create index "workforce_attendance_attendance_date_index" on "workforce_attendance" ("attendance_date")  
  2024_01_01_000009_create_compliance_execution_batches_table ................  
  ⇂ create table "compliance_execution_batches" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "section_id" integer not null, "period_from" date not null, "period_to" date not null, "period_month" integer, "period_year" integer, "form_ids" text not null, "branch_id" integer, "status" varchar not null default 'pending', "created_by" integer, "processed_at" datetime, "results" text, "generated_report_path" varchar, "created_at" datetime, "updated_at" datetime)  
  2024_01_01_000009_create_incidents_table ...................................  
  ⇂ create table "incidents" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "branch_id" integer not null, "incident_date" date not null, "description" varchar, "severity" varchar, "status" varchar, "created_at" datetime, "updated_at" datetime, foreign key("tenant_id") references "tenants"("id") on delete cascade, foreign key("branch_id") references "branches"("id") on delete cascade)  
  ⇂ create index "incidents_tenant_id_branch_id_index" on "incidents" ("tenant_id", "branch_id")  
  ⇂ create index "incidents_incident_date_index" on "incidents" ("incident_date")  
  ⇂ create index "incidents_tenant_id_index" on "incidents" ("tenant_id")  
  ⇂ create index "incidents_branch_id_index" on "incidents" ("branch_id")  
  2024_01_01_000009_create_inspection_documents_table ........................  
  ⇂ create table "inspection_documents" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "inspection_type" varchar check ("inspection_type" in ('epf', 'esi', 'labour', 'factory')) not null, "inspection_date" date not null, "inspecting_authority" varchar, "reference_number" varchar, "document_path" varchar not null, "remarks" text, "uploaded_by" integer not null, "uploaded_at" datetime not null, "created_at" datetime, "updated_at" datetime, "deleted_at" datetime, foreign key("tenant_id") references "tenants"("id") on delete cascade, foreign key("uploaded_by") references "users"("id") on delete cascade)  
  ⇂ create index "inspection_documents_tenant_id_index" on "inspection_documents" ("tenant_id")  
  ⇂ create index "inspection_documents_inspection_type_index" on "inspection_documents" ("inspection_type")  
  ⇂ create index "inspection_documents_inspection_date_index" on "inspection_documents" ("inspection_date")  
  2024_01_01_000010_create_compliance_execution_logs_table ...................  
  ⇂ create table "compliance_execution_logs" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "branch_id" integer not null, "batch_id" integer not null, "form_code" varchar not null, "status" varchar check ("status" in ('pending', 'processing', 'success', 'failed', 'preview')) not null default 'pending', "execution_time" integer, "records_generated" integer not null default '0', "error_message" text, "execution_mode" varchar not null default 'batch', "created_at" datetime, "updated_at" datetime, foreign key("tenant_id") references "tenants"("id") on delete cascade, foreign key("branch_id") references "branches"("id") on delete cascade, foreign key("batch_id") references "compliance_execution_batches"("id") on delete cascade)  
  ⇂ create index "compliance_execution_logs_tenant_id_batch_id_index" on "compliance_execution_logs" ("tenant_id", "batch_id")  
  ⇂ create index "compliance_execution_logs_batch_id_form_code_index" on "compliance_execution_logs" ("batch_id", "form_code")  
  ⇂ create index "compliance_execution_logs_status_index" on "compliance_execution_logs" ("status")  
  ⇂ create index "compliance_execution_logs_tenant_id_index" on "compliance_execution_logs" ("tenant_id")  
  ⇂ create index "compliance_execution_logs_branch_id_index" on "compliance_execution_logs" ("branch_id")  
  ⇂ create index "compliance_execution_logs_batch_id_index" on "compliance_execution_logs" ("batch_id")  
  2024_01_01_000010_create_compliance_forms_table ............................  
  ⇂ create table "compliance_forms" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "form_code" varchar not null, "period_from" date, "period_to" date, "frequency_type" varchar check ("frequency_type" in ('monthly', 'annual', 'event', 'inspection')) not null, "file_path" varchar not null, "generated_by" integer not null, "generated_at" datetime not null, "created_at" datetime, "updated_at" datetime, "deleted_at" datetime, foreign key("tenant_id") references "tenants"("id") on delete cascade, foreign key("generated_by") references "users"("id") on delete cascade)  
  ⇂ create index "compliance_forms_tenant_id_form_code_index" on "compliance_forms" ("tenant_id", "form_code")  
  ⇂ create index "compliance_forms_tenant_id_index" on "compliance_forms" ("tenant_id")  
  ⇂ create index "compliance_forms_form_code_index" on "compliance_forms" ("form_code")  
  ⇂ create index "compliance_forms_generated_at_index" on "compliance_forms" ("generated_at")  
  2024_01_02_000001_standardize_tenant_id_column .............................  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'workforce_employee' and type = 'table') as "exists"  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'workforce_payroll_cycle' and type = 'table') as "exists"  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'workforce_attendance' and type = 'table') as "exists"  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'contractor_master' and type = 'table') as "exists"  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'contract_labour_deployment' and type = 'table') as "exists"  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'clra_returns' and type = 'table') as "exists"  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'incident_documents' and type = 'table') as "exists"  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'inspection_documents' and type = 'table') as "exists"  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'compliance_forms' and type = 'table') as "exists"  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'bonus_records' and type = 'table') as "exists"  
  2024_01_02_000002_restructure_clra_module ..................................  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'contractors' and type = 'table') as "exists"  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'contractor_master' and type = 'table') as "exists"  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'contractor_compliance' and type = 'table') as "exists"  
  ⇂ create table "contractor_compliance" ("id" integer primary key autoincrement not null, "contractor_id" integer not null, "branch_id" integer, "clra_license_number" varchar, "license_valid_from" date, "license_valid_to" date, "max_worker_limit" integer, "pf_code" varchar, "esi_code" varchar, "labour_registration_number" varchar, "last_return_filed" date, "is_compliant" tinyint(1) not null default '1', "compliance_notes" text, "created_at" datetime, "updated_at" datetime, "deleted_at" datetime, foreign key("contractor_id") references "contractor_master"("id") on delete cascade)  
  ⇂ create index "contractor_compliance_contractor_id_branch_id_index" on "contractor_compliance" ("contractor_id", "branch_id")  
  ⇂ create index "contractor_compliance_contractor_id_index" on "contractor_compliance" ("contractor_id")  
  ⇂ create index "contractor_compliance_branch_id_index" on "contractor_compliance" ("branch_id")  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'contract_labour' and type = 'table') as "exists"  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'contract_labour_deployment' and type = 'table') as "exists"  
  2024_01_02_000003_add_payroll_constraints ..................................  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'payroll_cycles' and type = 'table') as "exists"  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'payroll_entries' and type = 'table') as "exists"  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'workforce_payroll_cycle' and type = 'table') as "exists"  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'workforce_payroll_entry' and type = 'table') as "exists"  
  2024_01_02_000004_add_soft_deletes .........................................  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'workforce_employee' and type = 'table') as "exists"  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'contractor_master' and type = 'table') as "exists"  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'contractor_compliance' and type = 'table') as "exists"  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'contract_labour_deployment' and type = 'table') as "exists"  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'workforce_payroll_cycle' and type = 'table') as "exists"  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'workforce_payroll_entry' and type = 'table') as "exists"  
  2024_01_02_000005_add_composite_indexes ....................................  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'workforce_attendance' and type = 'table') as "exists"  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'workforce_payroll_entry' and type = 'table') as "exists"  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'contract_labour_deployment' and type = 'table') as "exists"  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'contractor_compliance' and type = 'table') as "exists"  
  2024_01_03_000001_create_compliance_forms_master_table .....................  
  ⇂ create table "compliance_forms_master" ("id" integer primary key autoincrement not null, "form_code" varchar not null, "form_name" varchar not null, "act_type" varchar check ("act_type" in ('Factories', 'CLRA', 'Shops', 'EPF', 'ESI')) not null, "frequency" varchar check ("frequency" in ('Monthly', 'Annual', 'HalfYearly', 'Event')) not null, "priority" varchar check ("priority" in ('High', 'Medium', 'Low')) not null default 'Medium', "auto_generate" tinyint(1) not null default '0', "upload_only" tinyint(1) not null default '0', "is_active" tinyint(1) not null default '1', "created_at" datetime, "updated_at" datetime)  
  ⇂ create unique index "compliance_forms_master_form_code_unique" on "compliance_forms_master" ("form_code")  
  2024_01_03_000002_create_compliance_status_table ...........................  
  ⇂ create table "compliance_status" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "branch_id" integer, "form_id" integer not null, "period_from" date not null, "period_to" date not null, "status" varchar check ("status" in ('Pending', 'Generated', 'Uploaded', 'NIL', 'Locked')) not null default 'Pending', "generated_at" datetime, "uploaded_at" datetime, "approved_by" integer, "approved_at" datetime, "created_at" datetime, "updated_at" datetime, foreign key("tenant_id") references "tenants"("id") on delete cascade, foreign key("form_id") references "compliance_forms_master"("id") on delete cascade, foreign key("approved_by") references "users"("id") on delete set null)  
  ⇂ create unique index "unique_compliance_period" on "compliance_status" ("tenant_id", "branch_id", "form_id", "period_from", "period_to")  
  ⇂ create index "compliance_status_tenant_id_index" on "compliance_status" ("tenant_id")  
  ⇂ create index "compliance_status_branch_id_index" on "compliance_status" ("branch_id")  
  ⇂ create index "compliance_status_form_id_index" on "compliance_status" ("form_id")  
  2024_01_03_000003_create_compliance_generation_logs_table ..................  
  ⇂ create table "compliance_generation_logs" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "form_id" integer not null, "compliance_status_id" integer, "generated_by" integer not null, "file_path" varchar, "checksum_hash" varchar, "ip_address" varchar not null, "user_agent" text not null, "created_at" datetime, "updated_at" datetime, foreign key("tenant_id") references "tenants"("id") on delete cascade, foreign key("form_id") references "compliance_forms_master"("id") on delete cascade, foreign key("compliance_status_id") references "compliance_status"("id") on delete set null, foreign key("generated_by") references "users"("id") on delete cascade)  
  ⇂ create index "compliance_generation_logs_tenant_id_index" on "compliance_generation_logs" ("tenant_id")  
  ⇂ create index "compliance_generation_logs_form_id_index" on "compliance_generation_logs" ("form_id")  
  ⇂ create index "compliance_generation_logs_compliance_status_id_index" on "compliance_generation_logs" ("compliance_status_id")  
  2024_01_03_000004_create_compliance_reminders_table ........................  
  ⇂ create table "compliance_reminders" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "form_id" integer not null, "reminder_type" varchar check ("reminder_type" in ('Monthly', 'Annual', 'Expiry', 'Event')) not null, "due_date" date not null, "reminder_sent_at" datetime, "status" varchar check ("status" in ('Pending', 'Sent', 'Skipped')) not null default 'Pending', "created_at" datetime, "updated_at" datetime, foreign key("tenant_id") references "tenants"("id") on delete cascade, foreign key("form_id") references "compliance_forms_master"("id") on delete cascade)  
  ⇂ create index "compliance_reminders_tenant_id_index" on "compliance_reminders" ("tenant_id")  
  ⇂ create index "compliance_reminders_form_id_index" on "compliance_reminders" ("form_id")  
  ⇂ create index "compliance_reminders_due_date_index" on "compliance_reminders" ("due_date")  
  2024_01_03_000005_create_compliance_attachments_table ......................  
  ⇂ create table "compliance_attachments" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "form_id" integer not null, "compliance_status_id" integer not null, "uploaded_by" integer not null, "file_path" varchar not null, "reference_number" varchar, "remarks" text, "created_at" datetime not null, foreign key("tenant_id") references "tenants"("id") on delete cascade, foreign key("form_id") references "compliance_forms_master"("id") on delete cascade, foreign key("compliance_status_id") references "compliance_status"("id") on delete cascade, foreign key("uploaded_by") references "users"("id") on delete cascade)  
  ⇂ create index "compliance_attachments_tenant_id_index" on "compliance_attachments" ("tenant_id")  
  ⇂ create index "compliance_attachments_form_id_index" on "compliance_attachments" ("form_id")  
  ⇂ create index "compliance_attachments_compliance_status_id_index" on "compliance_attachments" ("compliance_status_id")  
  2024_01_04_000001_add_snapshot_to_generation_logs ..........................  
  ⇂ alter table "compliance_generation_logs" add column "generated_snapshot" text  
  2024_01_04_000002_add_versioning_to_compliance_status ......................  
  ⇂ select name, type, not "notnull" as "nullable", dflt_value as "default", pk as "primary", hidden as "extra" from pragma_table_xinfo('compliance_status', 'main') order by cid asc  
  ⇂ select "sql" from "main".sqlite_master where type = 'table' and name = 'compliance_status'  
  ⇂ select 'primary' as name, group_concat(col) as columns, 1 as "unique", 1 as "primary" from (select name as col from pragma_table_xinfo('compliance_status', 'main') where pk > 0 order by pk, cid) group by name union select name, group_concat(col) as columns, "unique", origin = 'pk' as "primary" from (select il.*, ii.name as col from pragma_index_list('compliance_status', 'main') il, pragma_index_info(il.name, 'main') ii order by il.seq, ii.seqno) group by name, "unique", "primary"  
  ⇂ select group_concat("from") as columns, 'main' as foreign_schema, "table" as foreign_table, group_concat("to") as foreign_columns, on_update, on_delete from (select * from pragma_foreign_key_list('compliance_status', 'main') order by id desc, seq) group by id, "table", on_update, on_delete  
  ⇂ pragma foreign_keys  
  ⇂ alter table "compliance_status" add column "version_number" integer not null default '1'  
  ⇂ alter table "compliance_status" add column "is_revised" tinyint(1) not null default '0'  
  ⇂ alter table "compliance_status" add column "revised_from_id" integer  
  ⇂ alter table "compliance_status" add column "revision_reason" text  
  ⇂ create table "__temp__compliance_status" ("version_number" integer not null default '1', "is_revised" tinyint(1) not null default '0', "revised_from_id" integer, "revision_reason" text, foreign key("revised_from_id") references "compliance_status"("id") on delete set null)  
  ⇂ insert into "__temp__compliance_status" ("version_number", "is_revised", "revised_from_id", "revision_reason") select "version_number", "is_revised", "revised_from_id", "revision_reason" from "compliance_status"  
  ⇂ drop table "compliance_status"  
  ⇂ alter table "__temp__compliance_status" rename to "compliance_status"  
  ⇂ create index "compliance_status_revised_from_id_index" on "compliance_status" ("revised_from_id")  
  2024_01_04_000003_add_due_date_fields_to_forms_master ......................  
  ⇂ alter table "compliance_forms_master" add column "due_day" integer  
  ⇂ alter table "compliance_forms_master" add column "due_month" integer  
  ⇂ alter table "compliance_forms_master" add column "grace_days" integer  
  2024_01_04_000005_create_compliance_form_sources_table .....................  
  ⇂ create table "compliance_form_sources" ("id" integer primary key autoincrement not null, "form_id" integer not null, "source_table" varchar not null, "source_type" varchar check ("source_type" in ('Payroll', 'Attendance', 'CLRA', 'Upload')) not null, "created_at" datetime, "updated_at" datetime, foreign key("form_id") references "compliance_forms_master"("id") on delete cascade)  
  ⇂ create index "compliance_form_sources_form_id_index" on "compliance_form_sources" ("form_id")  
  2024_01_05_000001_create_compliance_sections_table .........................  
  ⇂ create table "compliance_sections" ("id" integer primary key autoincrement not null, "section_name" varchar not null, "section_code" varchar not null, "is_active" tinyint(1) not null default '1', "created_at" datetime, "updated_at" datetime)  
  ⇂ create unique index "compliance_sections_section_code_unique" on "compliance_sections" ("section_code")  
  2024_01_05_000003_add_section_id_to_compliance_forms_master ................  
  ⇂ alter table "compliance_forms_master" add column "section_id" integer  
  2024_01_06_000001_add_subscription_type_to_tenants .........................  
  ⇂ alter table "tenants" add column "subscription_type" varchar check ("subscription_type" in ('FULL', 'MINIMAL')) not null default 'FULL'  
  2024_01_06_000002_add_batch_and_upload_type_to_attachments .................  
  ⇂ alter table "compliance_attachments" add column "batch_id" integer  
  ⇂ alter table "compliance_attachments" add column "upload_type" varchar check ("upload_type" in ('manual', 'automated')) not null default 'automated'  
  2024_01_06_000003_add_tenant_id_to_users ...................................  
  ⇂ alter table "users" add column "tenant_id" integer  
  2024_01_07_000001_add_period_month_year_to_batches .........................  
  ⇂ select name, type, not "notnull" as "nullable", dflt_value as "default", pk as "primary", hidden as "extra" from pragma_table_xinfo('compliance_execution_batches', 'main') order by cid asc  
  ⇂ select "sql" from "main".sqlite_master where type = 'table' and name = 'compliance_execution_batches'  
  ⇂ select name, type, not "notnull" as "nullable", dflt_value as "default", pk as "primary", hidden as "extra" from pragma_table_xinfo('compliance_execution_batches', 'main') order by cid asc  
  ⇂ select "sql" from "main".sqlite_master where type = 'table' and name = 'compliance_execution_batches'  
  ⇂ alter table "compliance_execution_batches" add column "period_month" integer  
  ⇂ alter table "compliance_execution_batches" add column "period_year" integer  
  2024_01_20_000001_create_compliance_signatures_table .......................  
  ⇂ create table "compliance_signatures" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "branch_id" integer not null, "form_code" varchar not null, "batch_id" integer not null, "signed_by_user_id" integer not null, "signatory_name" varchar not null, "signatory_designation" varchar not null, "signature_type" varchar check ("signature_type" in ('DRAWN', 'IMAGE', 'DIGITAL_CERT')) not null, "signature_path" varchar, "signature_hash" varchar not null, "document_hash" varchar not null, "ip_address" varchar not null, "signed_at" datetime not null, "created_at" datetime, "updated_at" datetime)  
  ⇂ create unique index "compliance_signatures_batch_id_form_code_unique" on "compliance_signatures" ("batch_id", "form_code")  
  ⇂ create index "compliance_signatures_tenant_id_batch_id_index" on "compliance_signatures" ("tenant_id", "batch_id")  
  ⇂ create index "compliance_signatures_document_hash_index" on "compliance_signatures" ("document_hash")  
  2024_01_20_000002_create_compliance_audit_logs_table .......................  
  ⇂ create table "compliance_audit_logs" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "user_id" integer, "action" varchar not null, "form_code" varchar, "batch_id" integer, "ip_address" varchar not null, "user_agent" text, "metadata" text, "created_at" datetime not null)  
  ⇂ create index "compliance_audit_logs_tenant_id_created_at_index" on "compliance_audit_logs" ("tenant_id", "created_at")  
  ⇂ create index "compliance_audit_logs_batch_id_action_index" on "compliance_audit_logs" ("batch_id", "action")  
  2024_01_20_000003_add_locking_to_batches ...................................  
  ⇂ alter table "compliance_execution_batches" add column "is_locked" tinyint(1) not null default '0'  
  ⇂ alter table "compliance_execution_batches" add column "locked_at" datetime  
  ⇂ alter table "compliance_execution_batches" add column "locked_by_user_id" integer  
  2024_12_20_000001_remove_forms_from_automation .............................  
  ⇂ update "compliance_forms_master" set "auto_generate" = 1  
  ⇂ update "compliance_forms_master" set "auto_generate" = 0 where "form_code" in ('Form8', 'HazardReg', 'ShopsForm13')  
  2026_02_24_081112_add_pf_esi_codes_to_branches_table .......................  
  ⇂ select name, type, not "notnull" as "nullable", dflt_value as "default", pk as "primary", hidden as "extra" from pragma_table_xinfo('branches', 'main') order by cid asc  
  ⇂ select "sql" from "main".sqlite_master where type = 'table' and name = 'branches'  
  ⇂ select name, type, not "notnull" as "nullable", dflt_value as "default", pk as "primary", hidden as "extra" from pragma_table_xinfo('branches', 'main') order by cid asc  
  ⇂ select "sql" from "main".sqlite_master where type = 'table' and name = 'branches'  
  ⇂ alter table "branches" add column "pf_code" varchar  
  ⇂ alter table "branches" add column "esi_code" varchar  
  2026_02_24_110000_create_compliance_timelines_table ........................  
  ⇂ create table "compliance_timelines" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "form_master_id" integer not null, "period_month" integer not null, "period_year" integer not null, "due_date" date not null, "status" varchar check ("status" in ('Pending', 'Generated', 'Filed', 'Overdue')) not null default 'Pending', "reminder_sent" tinyint(1) not null default '0', "created_at" datetime, "updated_at" datetime, foreign key("tenant_id") references "tenants"("id") on delete cascade, foreign key("form_master_id") references "compliance_forms_master"("id") on delete cascade)  
  ⇂ create unique index "timeline_unique" on "compliance_timelines" ("tenant_id", "form_master_id", "period_month", "period_year")  
  ⇂ create index "compliance_timelines_tenant_id_status_index" on "compliance_timelines" ("tenant_id", "status")  
  ⇂ create index "compliance_timelines_due_date_status_index" on "compliance_timelines" ("due_date", "status")  
  2026_02_24_120000_add_overtime_to_contract_labour_deployment ...............  
  ⇂ select name, type, not "notnull" as "nullable", dflt_value as "default", pk as "primary", hidden as "extra" from pragma_table_xinfo('contract_labour_deployment', 'main') order by cid asc  
  ⇂ select "sql" from "main".sqlite_master where type = 'table' and name = 'contract_labour_deployment'  
  ⇂ select name, type, not "notnull" as "nullable", dflt_value as "default", pk as "primary", hidden as "extra" from pragma_table_xinfo('contract_labour_deployment', 'main') order by cid asc  
  ⇂ select "sql" from "main".sqlite_master where type = 'table' and name = 'contract_labour_deployment'  
  ⇂ alter table "contract_labour_deployment" add column "overtime_hours" numeric not null default '0'  
  ⇂ alter table "contract_labour_deployment" add column "overtime_wages" numeric not null default '0'  
  2026_02_24_130000_add_subscription_to_users ................................  
  ⇂ select name, type, not "notnull" as "nullable", dflt_value as "default", pk as "primary", hidden as "extra" from pragma_table_xinfo('users', 'main') order by cid asc  
  ⇂ select "sql" from "main".sqlite_master where type = 'table' and name = 'users'  
  ⇂ alter table "users" add column "subscription_type" varchar check ("subscription_type" in ('MINIMAL', 'FULL')) not null default 'MINIMAL'  
  2026_02_24_130001_create_compliance_manual_uploads_table ...................  
  ⇂ create table "compliance_manual_uploads" ("id" integer primary key autoincrement not null, "user_id" integer not null, "batch_id" integer not null, "form_code" varchar not null, "file_path" varchar not null, "uploaded_at" datetime not null, "created_at" datetime, "updated_at" datetime, foreign key("user_id") references "users"("id") on delete cascade, foreign key("batch_id") references "compliance_execution_batches"("id") on delete cascade)  
  ⇂ create index "compliance_manual_uploads_batch_id_form_code_index" on "compliance_manual_uploads" ("batch_id", "form_code")  
  ⇂ create index "compliance_manual_uploads_user_id_form_code_index" on "compliance_manual_uploads" ("user_id", "form_code")  
  2026_02_24_141243_add_statutory_fields_to_tenants_table ....................  
  ⇂ alter table "tenants" add column "establishment_name" varchar  
  ⇂ alter table "tenants" add column "factory_license_no" varchar  
  ⇂ alter table "tenants" add column "pf_code" varchar  
  ⇂ alter table "tenants" add column "esi_code" varchar  
  ⇂ alter table "tenants" add column "labour_office_address" varchar  
  2026_02_24_141310_add_unit_fields_to_branches_table ........................  
  ⇂ select name, type, not "notnull" as "nullable", dflt_value as "default", pk as "primary", hidden as "extra" from pragma_table_xinfo('branches', 'main') order by cid asc  
  ⇂ select "sql" from "main".sqlite_master where type = 'table' and name = 'branches'  
  ⇂ alter table "branches" add column "unit_name" varchar  
  2026_02_24_144216_add_address_to_branches_table ............................  
  ⇂ select name, type, not "notnull" as "nullable", dflt_value as "default", pk as "primary", hidden as "extra" from pragma_table_xinfo('branches', 'main') order by cid asc  
  ⇂ select "sql" from "main".sqlite_master where type = 'table' and name = 'branches'  
  ⇂ alter table "branches" add column "address" text  
  2026_02_25_000000_remove_subscription_from_users ...........................  
  ⇂ select name, type, not "notnull" as "nullable", dflt_value as "default", pk as "primary", hidden as "extra" from pragma_table_xinfo('users', 'main') order by cid asc  
  ⇂ select "sql" from "main".sqlite_master where type = 'table' and name = 'users'  
  2026_02_25_072904_add_batch_id_to_compliance_generation_logs_table .........  
  ⇂ alter table "compliance_generation_logs" add column "batch_id" integer  
  ⇂ create index "compliance_generation_logs_batch_id_index" on "compliance_generation_logs" ("batch_id")  
  2026_02_25_073139_fix_compliance_generation_logs_schema ....................  
  ⇂ select name, type, not "notnull" as "nullable", dflt_value as "default", pk as "primary", hidden as "extra" from pragma_table_xinfo('compliance_generation_logs', 'main') order by cid asc  
  ⇂ select "sql" from "main".sqlite_master where type = 'table' and name = 'compliance_generation_logs'  
  ⇂ select name, type, not "notnull" as "nullable", dflt_value as "default", pk as "primary", hidden as "extra" from pragma_table_xinfo('compliance_generation_logs', 'main') order by cid asc  
  ⇂ select "sql" from "main".sqlite_master where type = 'table' and name = 'compliance_generation_logs'  
  ⇂ select name, type, not "notnull" as "nullable", dflt_value as "default", pk as "primary", hidden as "extra" from pragma_table_xinfo('compliance_generation_logs', 'main') order by cid asc  
  ⇂ select "sql" from "main".sqlite_master where type = 'table' and name = 'compliance_generation_logs'  
  ⇂ select name, type, not "notnull" as "nullable", dflt_value as "default", pk as "primary", hidden as "extra" from pragma_table_xinfo('compliance_generation_logs', 'main') order by cid asc  
  ⇂ select "sql" from "main".sqlite_master where type = 'table' and name = 'compliance_generation_logs'  
  ⇂ select name, type, not "notnull" as "nullable", dflt_value as "default", pk as "primary", hidden as "extra" from pragma_table_xinfo('compliance_generation_logs', 'main') order by cid asc  
  ⇂ select "sql" from "main".sqlite_master where type = 'table' and name = 'compliance_generation_logs'  
  ⇂ alter table "compliance_generation_logs" add column "batch_id" integer  
  ⇂ alter table "compliance_generation_logs" add column "form_code" varchar not null  
  ⇂ alter table "compliance_generation_logs" add column "tenant_id" integer not null  
  ⇂ alter table "compliance_generation_logs" add column "status" varchar not null default 'pending'  
  ⇂ alter table "compliance_generation_logs" add column "generated_file_path" varchar  
  2026_02_25_090245_add_error_message_to_compliance_generation_logs ..........  
  ⇂ select name, type, not "notnull" as "nullable", dflt_value as "default", pk as "primary", hidden as "extra" from pragma_table_xinfo('compliance_generation_logs', 'main') order by cid asc  
  ⇂ select "sql" from "main".sqlite_master where type = 'table' and name = 'compliance_generation_logs'  
  ⇂ alter table "compliance_generation_logs" add column "error_message" text  
  2026_02_26_000001_create_statutory_manual_data_table .......................  
  ⇂ create table "statutory_manual_data" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "month" integer not null, "year" integer not null, "establishment_details" text, "employer_details" text, "employee_summary" text, "wage_summary" text, "attendance_summary" text, "accident_details" text, "contractor_summary" text, "created_at" datetime, "updated_at" datetime, foreign key("tenant_id") references "tenants"("id") on delete cascade)  
  ⇂ create unique index "statutory_manual_data_tenant_id_month_year_unique" on "statutory_manual_data" ("tenant_id", "month", "year")  
  2026_02_26_000002_create_compliance_batch_forms_table ......................  
  ⇂ create table "compliance_batch_forms" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "batch_id" integer not null, "form_code" varchar not null, "section" varchar not null, "file_path" varchar not null, "status" varchar not null default 'success', "created_at" datetime not null)  
  ⇂ create index "compliance_batch_forms_batch_id_status_index" on "compliance_batch_forms" ("batch_id", "status")  
  ⇂ create index "compliance_batch_forms_tenant_id_index" on "compliance_batch_forms" ("tenant_id")  
  2026_02_27_051302_create_compliance_form_audit_scores_table ................  
  ⇂ create table "compliance_form_audit_scores" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "batch_id" integer not null, "form_code" varchar not null, "audit_score" integer not null default '0', "status" varchar not null default 'pending', "violations" text, "created_at" datetime, "updated_at" datetime)  
  ⇂ create index "compliance_form_audit_scores_tenant_id_batch_id_index" on "compliance_form_audit_scores" ("tenant_id", "batch_id")  
  ⇂ create index "compliance_form_audit_scores_form_code_index" on "compliance_form_audit_scores" ("form_code")  
  AddDeletedAtToWorkforceAttendance ..........................................  
  ⇂ select name, type, not "notnull" as "nullable", dflt_value as "default", pk as "primary", hidden as "extra" from pragma_table_xinfo('workforce_attendance', 'main') order by cid asc  
  ⇂ select "sql" from "main".sqlite_master where type = 'table' and name = 'workforce_attendance'  
  ⇂ alter table "workforce_attendance" add column "deleted_at" datetime  
  2026_03_10_000001_add_branch_id_to_payroll_entry ...........................  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'workforce_payroll_entry' and type = 'table') as "exists"  
  2026_03_10_000002_add_branch_id_to_attendance ..............................  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'workforce_attendance' and type = 'table') as "exists"  
  2026_03_10_000003_add_branch_id_to_bonus_records ...........................  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'bonus_records' and type = 'table') as "exists"  
  2026_03_10_000004_add_branch_id_to_incident_documents ......................  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'incident_documents' and type = 'table') as "exists"  
  2026_03_10_000005_add_contractor_id_to_deployment ..........................  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'contract_labour_deployment' and type = 'table') as "exists"  
  AddFineDateToWorkforceFinesTable ...........................................  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'workforce_fines' and type = 'table') as "exists"  
  UpdateWorkforceFinesTableSchema ............................................  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'workforce_fines' and type = 'table') as "exists"  
  FixMissingComplianceColumns ................................................  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'workforce_advances' and type = 'table') as "exists"  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'workforce_deductions' and type = 'table') as "exists"  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'workforce_fines' and type = 'table') as "exists"  
  AddRemarksToContractLabourDeployment .......................................  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'contract_labour_deployment' and type = 'table') as "exists"  
  2026_03_11_000001_make_file_path_nullable_in_compliance_batch_forms ........  
  ⇂ select name, type, not "notnull" as "nullable", dflt_value as "default", pk as "primary", hidden as "extra" from pragma_table_xinfo('compliance_batch_forms', 'main') order by cid asc  
  ⇂ select "sql" from "main".sqlite_master where type = 'table' and name = 'compliance_batch_forms'  
  ⇂ select 'primary' as name, group_concat(col) as columns, 1 as "unique", 1 as "primary" from (select name as col from pragma_table_xinfo('compliance_batch_forms', 'main') where pk > 0 order by pk, cid) group by name union select name, group_concat(col) as columns, "unique", origin = 'pk' as "primary" from (select il.*, ii.name as col from pragma_index_list('compliance_batch_forms', 'main') il, pragma_index_info(il.name, 'main') ii order by il.seq, ii.seqno) group by name, "unique", "primary"  
  ⇂ select group_concat("from") as columns, 'main' as foreign_schema, "table" as foreign_table, group_concat("to") as foreign_columns, on_update, on_delete from (select * from pragma_foreign_key_list('compliance_batch_forms', 'main') order by id desc, seq) group by id, "table", on_update, on_delete  
  ⇂ pragma foreign_keys  
  ⇂ create table "__temp__compliance_batch_forms" ()  
  ⇂ insert into "__temp__compliance_batch_forms" () select from "compliance_batch_forms"  
  ⇂ drop table "compliance_batch_forms"  
  ⇂ alter table "__temp__compliance_batch_forms" rename to "compliance_batch_forms"  
  2026_03_11_052038_create_contractors_table_fix .............................  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'contractors' and type = 'table') as "exists"  
  ⇂ create table "contractors" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "contractor_name" varchar not null, "license_number" varchar not null, "valid_from" date not null, "valid_to" date not null, "max_worker_limit" integer not null, "pf_code" varchar, "esi_code" varchar, "created_at" datetime, "updated_at" datetime)  
  2026_03_11_143004_create_telescope_entries_table ...........................  
  ⇂ create table "telescope_entries" ("sequence" integer primary key autoincrement not null, "uuid" varchar not null, "batch_id" varchar not null, "family_hash" varchar, "should_display_on_index" tinyint(1) not null default '1', "type" varchar not null, "content" text not null, "created_at" datetime)  
  ⇂ create unique index "telescope_entries_uuid_unique" on "telescope_entries" ("uuid")  
  ⇂ create index "telescope_entries_batch_id_index" on "telescope_entries" ("batch_id")  
  ⇂ create index "telescope_entries_family_hash_index" on "telescope_entries" ("family_hash")  
  ⇂ create index "telescope_entries_created_at_index" on "telescope_entries" ("created_at")  
  ⇂ create index "telescope_entries_type_should_display_on_index_index" on "telescope_entries" ("type", "should_display_on_index")  
  ⇂ create table "telescope_entries_tags" ("entry_uuid" varchar not null, "tag" varchar not null, foreign key("entry_uuid") references "telescope_entries"("uuid") on delete cascade, primary key ("entry_uuid", "tag"))  
  ⇂ create index "telescope_entries_tags_tag_index" on "telescope_entries_tags" ("tag")  
  ⇂ create table "telescope_monitoring" ("tag" varchar not null, primary key ("tag"))  
  2026_03_12_000001_add_updated_at_to_compliance_batch_forms .................  
  ⇂ alter table "compliance_batch_forms" add column "updated_at" datetime  
  2026_03_12_135241_alter_incidents_for_esi_forms ............................  
  ⇂ alter table "incidents" add column "employee_id" integer  
  ⇂ alter table "incidents" add column "notice_date" date  
  ⇂ alter table "incidents" add column "notice_time" time  
  ⇂ alter table "incidents" add column "incident_time" time  
  ⇂ alter table "incidents" add column "location" varchar  
  ⇂ alter table "incidents" add column "cause" text  
  ⇂ alter table "incidents" add column "injury_type" varchar  
  ⇂ alter table "incidents" add column "activity" text  
  ⇂ alter table "incidents" add column "first_aid_by" varchar  
  ⇂ alter table "incidents" add column "witness" text  
  ⇂ alter table "incidents" add column "remarks" text  
  2026_03_15_000001_create_workforce_deductions_table ........................  
  ⇂ create table "workforce_deductions" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "branch_id" integer not null, "employee_id" integer not null, "deduction_date" date not null, "particulars" varchar, "showed_cause" tinyint(1) not null default '0', "witness_name" varchar, "amount" numeric not null default '0', "num_instalments" integer, "first_month" varchar, "last_month" varchar, "remarks" text, "created_at" datetime, "updated_at" datetime, "deleted_at" datetime, foreign key("tenant_id") references "tenants"("id") on delete cascade, foreign key("branch_id") references "branches"("id") on delete cascade, foreign key("employee_id") references "workforce_employee"("id") on delete cascade)  
  ⇂ create index "workforce_deductions_tenant_id_branch_id_deduction_date_index" on "workforce_deductions" ("tenant_id", "branch_id", "deduction_date")  
  ⇂ create index "workforce_deductions_employee_id_deduction_date_index" on "workforce_deductions" ("employee_id", "deduction_date")  
  2026_03_15_000002_create_workforce_fines_table .............................  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'workforce_fines' and type = 'table') as "exists"  
  ⇂ create table "workforce_fines" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "branch_id" integer not null, "employee_id" integer not null, "fine_date" date not null, "reason" varchar, "amount" numeric not null default '0', "remarks" text, "created_at" datetime, "updated_at" datetime, "deleted_at" datetime, foreign key("tenant_id") references "tenants"("id") on delete cascade, foreign key("branch_id") references "branches"("id") on delete cascade, foreign key("employee_id") references "workforce_employee"("id") on delete cascade)  
  ⇂ create index "workforce_fines_tenant_id_branch_id_fine_date_index" on "workforce_fines" ("tenant_id", "branch_id", "fine_date")  
  ⇂ create index "workforce_fines_employee_id_fine_date_index" on "workforce_fines" ("employee_id", "fine_date")  
  2026_03_15_000003_create_workforce_advances_table ..........................  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'workforce_advances' and type = 'table') as "exists"  
  ⇂ create table "workforce_advances" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "branch_id" integer not null, "employee_id" integer not null, "advance_date" date not null, "amount" numeric not null default '0', "num_instalments" integer, "first_month" varchar, "last_month" varchar, "remarks" text, "created_at" datetime, "updated_at" datetime, "deleted_at" datetime, foreign key("tenant_id") references "tenants"("id") on delete cascade, foreign key("branch_id") references "branches"("id") on delete cascade, foreign key("employee_id") references "workforce_employee"("id") on delete cascade)  
  ⇂ create index "workforce_advances_tenant_id_branch_id_advance_date_index" on "workforce_advances" ("tenant_id", "branch_id", "advance_date")  
  ⇂ create index "workforce_advances_employee_id_advance_date_index" on "workforce_advances" ("employee_id", "advance_date")  
  2026_03_20_000001_add_missing_columns_to_workforce_employee ................  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'workforce_employee' and type = 'table') as "exists"  
  2026_03_20_000002_add_missing_compliance_columns ...........................  
  ⇂ select name, type, not "notnull" as "nullable", dflt_value as "default", pk as "primary", hidden as "extra" from pragma_table_xinfo('contract_labour_deployment', 'main') order by cid asc  
  ⇂ select "sql" from "main".sqlite_master where type = 'table' and name = 'contract_labour_deployment'  
  ⇂ select name, type, not "notnull" as "nullable", dflt_value as "default", pk as "primary", hidden as "extra" from pragma_table_xinfo('contract_labour_deployment', 'main') order by cid asc  
  ⇂ select "sql" from "main".sqlite_master where type = 'table' and name = 'contract_labour_deployment'  
  ⇂ select name, type, not "notnull" as "nullable", dflt_value as "default", pk as "primary", hidden as "extra" from pragma_table_xinfo('contract_labour_deployment', 'main') order by cid asc  
  ⇂ select "sql" from "main".sqlite_master where type = 'table' and name = 'contract_labour_deployment'  
  ⇂ alter table "contract_labour_deployment" add column "nature_of_work" varchar  
  ⇂ alter table "contract_labour_deployment" add column "work_location" varchar  
  ⇂ alter table "contract_labour_deployment" add column "termination_reason" varchar  
  2026_03_20_000004_fix_contractor_master_schema .............................  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'contractor_master' and type = 'table') as "exists"  
  2026_03_20_000005_fix_contract_labour_deployment_schema ....................  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'contract_labour_deployment' and type = 'table') as "exists"  
  2026_03_20_000006_add_shift_id_to_workforce_employee .......................  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'workforce_employee' and type = 'table') as "exists"  
  2026_03_20_000007_add_branch_id_to_clra_returns ............................  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'clra_returns' and type = 'table') as "exists"  
  2026_03_20_000008_create_employee_leave_table ..............................  
  ⇂ create table "employee_leave" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "branch_id" integer not null, "employee_id" integer not null, "leave_from" date not null, "leave_to" date not null, "leave_type" varchar not null, "days" integer not null, "reason" text, "status" varchar not null default 'approved', "created_at" datetime, "updated_at" datetime, "deleted_at" datetime, foreign key("tenant_id") references "tenants"("id") on delete cascade, foreign key("branch_id") references "branches"("id") on delete cascade, foreign key("employee_id") references "workforce_employee"("id") on delete cascade)  
  ⇂ create index "employee_leave_tenant_id_branch_id_index" on "employee_leave" ("tenant_id", "branch_id")  
  2026_03_20_000009_create_holidays_table ....................................  
  ⇂ create table "holidays" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "branch_id" integer not null, "holiday_date" date not null, "holiday_name" varchar not null, "holiday_type" varchar not null default 'national', "created_at" datetime, "updated_at" datetime, foreign key("tenant_id") references "tenants"("id") on delete cascade, foreign key("branch_id") references "branches"("id") on delete cascade)  
  ⇂ create index "holidays_tenant_id_branch_id_index" on "holidays" ("tenant_id", "branch_id")  
  2026_03_20_000010_create_hazard_register_table .............................  
  ⇂ create table "hazard_register" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "branch_id" integer not null, "hazard_date" date not null, "hazard_type" varchar not null, "description" text not null, "location" varchar not null, "severity" varchar not null default 'medium', "status" varchar not null default 'open', "corrective_action" text, "action_date" date, "created_at" datetime, "updated_at" datetime, "deleted_at" datetime, foreign key("tenant_id") references "tenants"("id") on delete cascade, foreign key("branch_id") references "branches"("id") on delete cascade)  
  ⇂ create index "hazard_register_tenant_id_branch_id_index" on "hazard_register" ("tenant_id", "branch_id")  
  2026_03_20_000011_create_employee_financial_register_table .................  
  ⇂ create table "employee_financial_register" ("id" integer primary key autoincrement not null, "tenant_id" integer not null, "branch_id" integer not null, "employee_id" integer not null, "transaction_type" varchar not null, "amount" numeric not null, "transaction_date" date not null, "reason" varchar not null, "status" varchar not null default 'active', "installments" integer, "installment_amount" numeric, "remarks" text, "created_at" datetime, "updated_at" datetime, "deleted_at" datetime, foreign key("tenant_id") references "tenants"("id") on delete cascade, foreign key("branch_id") references "branches"("id") on delete cascade, foreign key("employee_id") references "workforce_employee"("id") on delete cascade)  
  ⇂ create index "employee_financial_register_tenant_id_branch_id_index" on "employee_financial_register" ("tenant_id", "branch_id")  
  2026_03_20_000012_fix_batch_forms_file_path ................................  
  ⇂ select name, type, not "notnull" as "nullable", dflt_value as "default", pk as "primary", hidden as "extra" from pragma_table_xinfo('compliance_batch_forms', 'main') order by cid asc  
  ⇂ select "sql" from "main".sqlite_master where type = 'table' and name = 'compliance_batch_forms'  
  ⇂ select 'primary' as name, group_concat(col) as columns, 1 as "unique", 1 as "primary" from (select name as col from pragma_table_xinfo('compliance_batch_forms', 'main') where pk > 0 order by pk, cid) group by name union select name, group_concat(col) as columns, "unique", origin = 'pk' as "primary" from (select il.*, ii.name as col from pragma_index_list('compliance_batch_forms', 'main') il, pragma_index_info(il.name, 'main') ii order by il.seq, ii.seqno) group by name, "unique", "primary"  
  ⇂ select group_concat("from") as columns, 'main' as foreign_schema, "table" as foreign_table, group_concat("to") as foreign_columns, on_update, on_delete from (select * from pragma_foreign_key_list('compliance_batch_forms', 'main') order by id desc, seq) group by id, "table", on_update, on_delete  
  ⇂ pragma foreign_keys  
  ⇂ create table "__temp__compliance_batch_forms" ()  
  ⇂ insert into "__temp__compliance_batch_forms" () select from "compliance_batch_forms"  
  ⇂ drop table "compliance_batch_forms"  
  ⇂ alter table "__temp__compliance_batch_forms" rename to "compliance_batch_forms"  
  2026_03_25_000001_make_file_path_nullable_in_batch_forms ...................  
  ⇂ select name, type, not "notnull" as "nullable", dflt_value as "default", pk as "primary", hidden as "extra" from pragma_table_xinfo('compliance_batch_forms', 'main') order by cid asc  
  ⇂ select "sql" from "main".sqlite_master where type = 'table' and name = 'compliance_batch_forms'  
  ⇂ select 'primary' as name, group_concat(col) as columns, 1 as "unique", 1 as "primary" from (select name as col from pragma_table_xinfo('compliance_batch_forms', 'main') where pk > 0 order by pk, cid) group by name union select name, group_concat(col) as columns, "unique", origin = 'pk' as "primary" from (select il.*, ii.name as col from pragma_index_list('compliance_batch_forms', 'main') il, pragma_index_info(il.name, 'main') ii order by il.seq, ii.seqno) group by name, "unique", "primary"  
  ⇂ select group_concat("from") as columns, 'main' as foreign_schema, "table" as foreign_table, group_concat("to") as foreign_columns, on_update, on_delete from (select * from pragma_foreign_key_list('compliance_batch_forms', 'main') order by id desc, seq) group by id, "table", on_update, on_delete  
  ⇂ pragma foreign_keys  
  ⇂ create table "__temp__compliance_batch_forms" ()  
  ⇂ insert into "__temp__compliance_batch_forms" () select from "compliance_batch_forms"  
  ⇂ drop table "compliance_batch_forms"  
  ⇂ alter table "__temp__compliance_batch_forms" rename to "compliance_batch_forms"  
  2026_03_25_000002_drop_compliance_certification_logs_table .................  
  ⇂ drop table if exists "compliance_certification_logs"  
  2026_03_25_000003_create_compliance_manual_master_table ....................  
  ⇂ create table "compliance_manual_master" ("id" integer primary key autoincrement not null, "compliance_name" varchar not null, "act_name" varchar not null, "frequency" varchar check ("frequency" in ('monthly', 'quarterly', 'half_yearly', 'annual', 'event')) not null, "due_month" integer, "requires_document" tinyint(1) not null default '1', "is_event_based" tinyint(1) not null default '0', "created_at" datetime, "updated_at" datetime)  
  2026_03_25_000004_create_compliance_manual_batch_items_table ...............  
  ⇂ create table "compliance_manual_batch_items" ("id" integer primary key autoincrement not null, "batch_id" integer not null, "tenant_id" integer not null, "branch_id" integer not null, "compliance_id" integer not null, "status" varchar check ("status" in ('pending', 'uploaded', 'skipped')) not null default 'pending', "document_path" varchar, "remarks" text, "created_at" datetime, "updated_at" datetime, foreign key("batch_id") references "compliance_execution_batches"("id") on delete cascade, foreign key("compliance_id") references "compliance_manual_master"("id") on delete cascade)  
  2026_03_25_000005_harden_compliance_manual_batch_items_table ...............  
  ⇂ select name, type, not "notnull" as "nullable", dflt_value as "default", pk as "primary", hidden as "extra" from pragma_table_xinfo('compliance_manual_batch_items', 'main') order by cid asc  
  ⇂ select "sql" from "main".sqlite_master where type = 'table' and name = 'compliance_manual_batch_items'  
  ⇂ select 'primary' as name, group_concat(col) as columns, 1 as "unique", 1 as "primary" from (select name as col from pragma_table_xinfo('compliance_manual_batch_items', 'main') where pk > 0 order by pk, cid) group by name union select name, group_concat(col) as columns, "unique", origin = 'pk' as "primary" from (select il.*, ii.name as col from pragma_index_list('compliance_manual_batch_items', 'main') il, pragma_index_info(il.name, 'main') ii order by il.seq, ii.seqno) group by name, "unique", "primary"  
  ⇂ select group_concat("from") as columns, 'main' as foreign_schema, "table" as foreign_table, group_concat("to") as foreign_columns, on_update, on_delete from (select * from pragma_foreign_key_list('compliance_manual_batch_items', 'main') order by id desc, seq) group by id, "table", on_update, on_delete  
  ⇂ pragma foreign_keys  
  ⇂ pragma foreign_keys  
  ⇂ create table "__temp__compliance_manual_batch_items" ()  
  ⇂ insert into "__temp__compliance_manual_batch_items" () select from "compliance_manual_batch_items"  
  ⇂ drop table "compliance_manual_batch_items"  
  ⇂ alter table "__temp__compliance_manual_batch_items" rename to "compliance_manual_batch_items"  
  ⇂ alter table "compliance_manual_batch_items" add column "compliance_result" varchar check ("compliance_result" in ('compliant', 'not_applicable'))  
  ⇂ alter table "compliance_manual_batch_items" add column "uploaded_at" datetime  
  ⇂ alter table "compliance_manual_batch_items" add column "uploaded_by" integer  
  ⇂ create table "__temp__compliance_manual_batch_items" ("compliance_result" varchar check ("compliance_result" in ('compliant', 'not_applicable')), "uploaded_at" datetime, "uploaded_by" integer, foreign key("uploaded_by") references "users"("id") on delete set null)  
  ⇂ insert into "__temp__compliance_manual_batch_items" ("compliance_result", "uploaded_at", "uploaded_by") select "compliance_result", "uploaded_at", "uploaded_by" from "compliance_manual_batch_items"  
  ⇂ drop table "compliance_manual_batch_items"  
  ⇂ alter table "__temp__compliance_manual_batch_items" rename to "compliance_manual_batch_items"  
  ⇂ alter table "compliance_manual_batch_items" add column "file_size" integer  
  ⇂ create index "idx_manual_items_tenant_branch_batch" on "compliance_manual_batch_items" ("tenant_id", "branch_id", "batch_id")  
  2026_03_25_000006_add_is_automatable_to_compliance_manual_master ...........  
  ⇂ alter table "compliance_manual_master" add column "is_automatable" tinyint(1) not null default '0'  
  ⇂ update "compliance_manual_master" set "is_automatable" = 1 where "id" in (1, 2, 3, 4, 5, 9, 10, 14, 15, 16, 17, 19, 20, 21, 22, 23, 24, 29, 35, 36, 37, 11, 34, 58)  
  2026_04_01_000001_add_branch_id_to_users ...................................  
  ⇂ select name, type, not "notnull" as "nullable", dflt_value as "default", pk as "primary", hidden as "extra" from pragma_table_xinfo('users', 'main') order by cid asc  
  ⇂ select "sql" from "main".sqlite_master where type = 'table' and name = 'users'  
  ⇂ alter table "users" add column "branch_id" integer  
  2026_04_10_000001_add_full_employee_fields_to_workforce_employee ...........  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'workforce_employee' and type = 'table') as "exists"  
  2026_04_15_000001_add_overtime_hours_to_workforce_attendance ...............  
  ⇂ select exists (select 1 from "main".sqlite_master where name = 'workforce_attendance' and type = 'table') as "exists"  

