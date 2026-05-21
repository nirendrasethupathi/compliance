@extends('compliance.layouts.antd_base')

@section('title', 'Dashboard - Compliance Engine')

@section('content')
    <div class="container-fluid dashboard-wrapper">
        @include('compliance.partials.org-info')
        @include('compliance.partials.timeline-status')

        @if (isset($subscription) && $subscription === 'MINIMAL')
            <div class="ant-alert ant-alert-warning">
                <strong>⚠️ MINIMAL Subscription:</strong> Enter statutory data manually to auto-generate forms.
            </div>
        @endif

        @if (session('success'))
            <div class="ant-alert ant-alert-success">{{ session('success') }}</div>
        @endif

        @if (session('error'))
            <div class="ant-alert ant-alert-error">{{ session('error') }}</div>
        @endif

        <div class="ant-row" gutter="16">
            <div class="ant-col ant-col-6">
                @include('compliance.partials.create-batch-card')
            </div>
            <div class="ant-col ant-col-6">
                @include('compliance.partials.quick-stats')
            </div>
        </div>

        <style>
            #batch-section-row { display: flex; flex-wrap: wrap; gap: 16px; }
            #batch-col { flex: 1 1 0; min-width: 0; display: flex; justify-content: center; }
            #batch-col > #batch-review-container { width: 100%; max-width: 900px; }
            #manual-col { flex: 0 0 auto; width: 60%;min-width: 0; }
            #batch-section-row.has-manual #batch-col > #batch-review-container { max-width: 100%; }
        </style>

        <div id="batch-section-row" class="mt-4">
            <div id="batch-col">
                <div id="batch-review-container"></div>
            </div>
            <div id="manual-col">
                @include('compliance.partials.manual-compliance-panel')
            </div>
        </div>

        <div class="ant-row mt-4" style="justify-content: center;">
            <div class="ant-col ant-col-24">
                @include('compliance.partials.recent-batches')
            </div>
        </div>
    </div>

    @include('compliance.partials.preview-modal')

@endsection

@push('scripts')
    <script>
    (function () {
        const SUBSCRIPTION = '{{ $subscription ?? 'MINIMAL' }}';
        const IS_FULL = SUBSCRIPTION === 'FULL';

        const BatchProcessor = {
            processing: false,
            currentBatchId: null,

            async processBatch(batchId) {
                this.processing = true;
                this.currentBatchId = batchId;

                this.showProcessingUI(batchId);

                while (this.processing) {
                    try {
                        const response = await fetch(`/compliance/batch/${batchId}/process-next`, {
                            method: 'POST',
                            headers: {
                                'Content-Type': 'application/json',
                                'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content
                            }
                        });

                        const data = await response.json();

                        if (data.status === 'complete') {
                            this.showComplete(batchId);
                            this.processing = false;
                            break;
                        }

                        if (data.status === 'processing') {
                            this.updateProgress(data);
                            await new Promise(resolve => setTimeout(resolve, 500));
                        }
                    } catch (error) {
                        console.error('Processing error:', error);
                        this.processing = false;
                        alert('Error: ' + error.message);
                    }
                }
            },

            showProcessingUI(batchId) {
                const html = `
                    <div class="ant-card mb-3" id="processing-card">
                        <div class="ant-card-head info">⏳ Processing Batch #${batchId}</div>
                        <div class="ant-card-body">
                            <div style="margin-bottom:20px">
                                <div style="display:flex; justify-content:space-between; margin-bottom:8px;">
                                    <strong>Progress</strong>
                                    <span id="progress-text" class="ant-tag ant-tag-processing">0/0 forms</span>
                                </div>
                                <div class="progress" style="height:24px;">
                                    <div id="progress-bar" class="progress-bar progress-bar-striped progress-bar-animated" style="width:0%; font-weight:bold;">0%</div>
                                </div>
                            </div>
                            <div style="overflow-x:auto">
                                <table class="ant-table">
                                    <thead>
                                        <tr>
                                            <th style="width:35%">Form Code</th>
                                            <th style="width:30%">Status</th>
                                            <th style="width:35%">Action</th>
                                        </tr>
                                    </thead>
                                    <tbody id="forms-table-body"></tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                `;

                document.getElementById('batch-review-container').innerHTML = html;
            },

            updateProgress(data) {
                const progressBar = document.getElementById('progress-bar');
                if (progressBar) {
                    progressBar.style.width = data.progress + '%';
                    progressBar.textContent = data.progress + '%';
                }

                const progressText = document.getElementById('progress-text');
                if (progressText) {
                    progressText.textContent = `${data.generated}/${data.total} forms`;
                }

                const tbody = document.getElementById('forms-table-body');
                if (tbody && data.forms) {
                    tbody.innerHTML = data.forms.map(form => {
                        let statusBadge = '';
                        let actionBtn = '';

                        if (form.status === 'generated') {
                            statusBadge = '<span class="ant-tag ant-tag-success">✅ Generated</span>';
                            actionBtn = `<button class="ant-btn ant-btn-primary ant-btn-sm preview-btn" data-batch="${data.batch_id}" data-form="${form.form_code}">👁️ Preview</button>`;
                        } else if (form.status === 'processing') {
                            statusBadge = '<span class="ant-tag ant-tag-processing">⏳ Processing</span>';
                            actionBtn = '-';
                        } else {
                            statusBadge = '<span class="ant-tag">⏸️ Pending</span>';
                            actionBtn = '-';
                        }

                        return `
                            <tr>
                                <td><strong>${form.form_code}</strong></td>
                                <td>${statusBadge}</td>
                                <td>${actionBtn}</td>
                            </tr>
                        `;
                    }).join('');
                }
            },

            showComplete(batchId) {
                const progressBar = document.getElementById('progress-bar');
                if (progressBar) {
                    progressBar.style.width = '100%';
                    progressBar.textContent = '100%';
                    progressBar.classList.remove('progress-bar-animated');
                    progressBar.classList.add('bg-success');
                }

                const card = document.getElementById('processing-card');
                if (card) {
                    const completeMsg = document.createElement('div');
                    completeMsg.className = 'ant-alert ant-alert-success mt-3';
                    completeMsg.innerHTML = '<strong>✅ All Forms Generated Successfully!</strong>';
                    card.appendChild(completeMsg);
                }
            }
        };

        function escapeHtml(text) {
            if (!text) return '';
            const map = {'&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#039;'};
            return text.replace(/[&<>"']/g, m => map[m]);
        }

        document.getElementById('batchForm')?.addEventListener('submit', function(e) {
            e.preventDefault();

            const month = document.getElementById('period_month').value;
            const year  = document.getElementById('period_year').value;
            const btn     = document.getElementById('createBatchBtn');
            const spinner = document.getElementById('submitSpinner');

            if (!month || !year) { alert('Please select both month and year'); return; }

            btn.disabled = true;
            spinner.classList.remove('d-none');

            const endpoint = IS_FULL ? '/compliance/batch/create' : '/compliance/batch/create-minimal';

            fetch(endpoint, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content
                },
                body: JSON.stringify({ period_month: month, period_year: year })
            })
            .then(r => r.json())
            .then(data => {
                if (data.status === 'success') {
                    renderBatchReview(data);
                    document.getElementById('batchForm').reset();
                } else {
                    alert('Error: ' + (data.message || 'Failed to create batch'));
                }
            })
            .catch(err => alert('Error: ' + err.message))
            .finally(() => {
                btn.disabled = false;
                spinner.classList.add('d-none');
            });
        });

        // Track which data categories have been provided in MINIMAL mode
        const _minimalDataProvided = { employees: false, attendance: false, payroll: false };

        function markMinimalDataProvided(category) {
            if (category === 'manual')    { _minimalDataProvided.employees = _minimalDataProvided.attendance = _minimalDataProvided.payroll = true; }
            else if (category === 'csv') { _minimalDataProvided[document.getElementById('csvDataType')?.value] = true; }
            else if (category === 'pdf') { _minimalDataProvided.employees = true; } // PDF covers form data
            refreshMinimalProceedBtn();
        }

        function refreshMinimalProceedBtn() {
            const allProvided = _minimalDataProvided.employees && _minimalDataProvided.attendance && _minimalDataProvided.payroll;
            const btn = document.getElementById('proceed-generate-btn');
            if (!btn) return;
            if (allProvided) {
                btn.removeAttribute('disabled');
                btn.classList.remove('ant-btn-default');
                btn.classList.add('ant-btn-primary');
                const hint = document.getElementById('proceed-hint');
                if (hint) hint.textContent = '✅ All data provided. You can now generate forms.';
            }
            // Update checklist badges
            ['employees','attendance','payroll'].forEach(cat => {
                const el = document.getElementById('data-check-' + cat);
                if (el) el.className = 'ant-tag ' + (_minimalDataProvided[cat] ? 'ant-tag-success' : 'ant-tag-error');
            });
        }

        function renderBatchReview(data) {
            const isMinimal = data.minimal_mode === true;

            const dataAvailabilityHtml = data.data_availability.all_data_exists
                ? `<div class="ant-alert ant-alert-success mb-3"><strong>✅ All Required Data Available</strong></div>`
                : isMinimal
                    ? `<div class="ant-alert ant-alert-warning mb-3">
                        <strong>📋 Provide data for all three categories below to generate forms.</strong>
                       </div>`
                    : `<div class="ant-alert ant-alert-warning mb-3">
                        <strong>⚠️ Missing Data Detected</strong>
                        <ul class="mb-0 mt-2">
                            ${data.data_availability.missing_data.map(m => `<li>${escapeHtml(m.charAt(0).toUpperCase() + m.slice(1).replace(/_/g, ' '))}</li>`).join('')}
                        </ul>
                       </div>`;

            // Data checklist for MINIMAL
            const minimalChecklist = isMinimal ? `
                <div style="display:flex; gap:12px; flex-wrap:wrap; margin-bottom:16px;">
                    <span>Data status:</span>
                    <span id="data-check-employees" class="ant-tag ant-tag-error">Employees ✗</span>
                    <span id="data-check-attendance" class="ant-tag ant-tag-error">Attendance ✗</span>
                    <span id="data-check-payroll"    class="ant-tag ant-tag-error">Payroll ✗</span>
                </div>` : '';

            // Data summary table (FULL only)
            const dataSummaryHtml = !isMinimal ? `
                <div class="mt-3">
                    <p class="mb-2"><strong>Data Summary:</strong></p>
                    <table class="ant-table" style="font-size:12px; margin-bottom:0;">
                        <tbody>
                            ${Object.entries(data.data_availability.data_summary).map(([key, count]) => `
                                <tr>
                                    <td style="width:60%;"><strong>${escapeHtml(key.charAt(0).toUpperCase() + key.slice(1).replace(/_/g, ' '))}</strong></td>
                                    <td style="text-align:right;">
                                        <span class="ant-tag ${parseInt(count) > 0 ? 'ant-tag-success' : 'ant-tag-error'}">${parseInt(count)} records</span>
                                    </td>
                                </tr>`).join('')}
                        </tbody>
                    </table>
                </div>` : '';

            // Show data input panel: always for MINIMAL, only when missing for FULL
            const showDataInput = isMinimal || !data.can_proceed;
            const dataInputHtml = showDataInput ? `
                <div class="ant-card mb-3" id="data-input-options">
                    <div class="ant-card-head info">📥 ${isMinimal ? 'Provide Compliance Data' : 'Fill Missing Data'}</div>
                    <div class="ant-card-body">
                        ${isMinimal
                            ? `<p class="mb-3" style="font-size:13px;">Provide data using any combination of the three methods below. All three categories (Employees, Attendance, Payroll) must be covered before you can generate forms.</p>`
                            : `<p class="mb-3">Choose one of the following options to provide missing data:</p>`
                        }
                        <div class="ant-row" gutter="16">
                            <div class="ant-col ant-col-8">
                                <div class="ant-card" style="cursor:pointer; text-align:center; padding:20px;" onclick="showManualDataModal(${data.batch_id})">
                                    <div style="font-size:32px; margin-bottom:10px;">✍️</div>
                                    <strong>Manual Data Entry</strong>
                                    <p class="text-muted mt-2" style="font-size:12px;">Enter employees, attendance &amp; payroll data directly</p>
                                </div>
                            </div>
                            <div class="ant-col ant-col-8">
                                <div class="ant-card" style="cursor:pointer; text-align:center; padding:20px;" onclick="showPdfUploadModal(${data.batch_id}, ${JSON.stringify(data.forms).replace(/"/g, '&quot;')})">
                                    <div style="font-size:32px; margin-bottom:10px;">📄</div>
                                    <strong>PDF Upload</strong>
                                    <p class="text-muted mt-2" style="font-size:12px;">Upload filled PDF forms directly</p>
                                </div>
                            </div>
                            <div class="ant-col ant-col-8">
                                <div class="ant-card" style="cursor:pointer; text-align:center; padding:20px;" onclick="showCsvUploadModal(${data.batch_id})">
                                    <div style="font-size:32px; margin-bottom:10px;">📊</div>
                                    <strong>CSV Upload</strong>
                                    <p class="text-muted mt-2" style="font-size:12px;">Upload CSV for employees, attendance or payroll</p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>` : '';

            const proceedDisabled = isMinimal ? 'disabled' : (!data.can_proceed ? 'disabled' : '');
            const proceedHint = isMinimal
                ? 'Provide all three data categories above to enable generation.'
                : (!data.can_proceed ? 'Proceed button will be enabled once all required data is provided.' : '');

            const html = `
                <div class="batch-review-wrapper" data-batch-id="${data.batch_id}">
                    <div class="ant-card mb-3">
                        <div class="ant-card-head success">✅ Batch Created — ${escapeHtml(data.period)}</div>
                        <div class="ant-card-body">
                            <div class="ant-row">
                                <div class="ant-col ant-col-6"><p class="mb-0"><strong>Batch ID:</strong> #${data.batch_id}</p></div>
                                <div class="ant-col ant-col-6"><p class="mb-0"><strong>Period:</strong> ${escapeHtml(data.period)}</p></div>
                            </div>
                        </div>
                    </div>

                    <div class="ant-card mb-3">
                        <div class="ant-card-head info">📋 Forms to be Generated (${data.forms.length})</div>
                        <div class="ant-card-body">
                            ${data.forms.length > 0 ? `
                                <div style="max-height:260px; overflow-y:auto;">
                                    <table class="ant-table" style="font-size:13px; margin-bottom:0;">
                                        <thead><tr><th>Form Code</th><th>Section</th><th>Status</th></tr></thead>
                                        <tbody>
                                            ${data.forms.map(f => `
                                                <tr>
                                                    <td><strong>${escapeHtml(f.form_code)}</strong></td>
                                                    <td>${escapeHtml(f.section || '-')}</td>
                                                    <td><span class="ant-tag ant-tag-processing">${escapeHtml(f.status.charAt(0).toUpperCase() + f.status.slice(1))}</span></td>
                                                </tr>`).join('')}
                                        </tbody>
                                    </table>
                                </div>` : `<p class="text-muted text-center" style="padding:20px 0;">No forms detected.</p>`}
                        </div>
                    </div>

                    <div class="ant-card mb-3">
                        <div class="ant-card-head warning">📊 Data ${isMinimal ? 'Input Required' : 'Availability Check'}</div>
                        <div class="ant-card-body">
                            ${dataAvailabilityHtml}
                            ${minimalChecklist}
                            ${dataSummaryHtml}
                        </div>
                    </div>

                    ${dataInputHtml}

                    <div class="ant-card">
                        <div class="ant-card-body">
                            <div class="d-flex gap-2 justify-content-end">
                                <button type="button" class="ant-btn ant-btn-default cancel-batch-btn" data-batch="${data.batch_id}">❌ Cancel</button>
                                <button type="button" class="ant-btn ant-btn-default proceed-batch-btn" id="proceed-generate-btn"
                                        data-batch="${data.batch_id}" ${proceedDisabled}>
                                    ✅ Proceed to Generate
                                </button>
                            </div>
                            ${proceedHint ? `<p class="text-muted text-center mt-2" id="proceed-hint" style="font-size:12px;">${proceedHint}</p>` : ''}
                        </div>
                    </div>
                </div>`;

            document.getElementById('batch-review-container').innerHTML = html;
        }

        function showManualDataModal(batchId) {
            const existing = document.getElementById('manualDataModal');
            if (existing) existing.remove();
            const modal = document.createElement('div');
            modal.className = 'modal fade';
            modal.id = 'manualDataModal';
            modal.innerHTML = `
                <div class="modal-dialog modal-lg">
                    <div class="modal-content">
                        <div class="modal-header">
                            <h5 class="modal-title">✍️ Manual Data Entry</h5>
                            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                        </div>
                        <div class="modal-body">
                            ${!IS_FULL ? `<div class="alert alert-info" style="font-size:13px;">
                                <strong>📌 MINIMAL mode:</strong> Fill all three sections. This data will be used directly for form generation.
                            </div>` : ''}
                            <form id="manualDataForm">
                                <div class="mb-3">
                                    <label class="form-label"><strong>Employees Data</strong></label>
                                    <textarea class="form-control" name="employees_data" rows="4"
                                        placeholder="Name, Designation, Salary (one per line)&#10;e.g. John Doe, Operator, 18000"></textarea>
                                    <small class="text-muted">Format: Name, Designation, Salary (one per line)</small>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label"><strong>Attendance Data</strong></label>
                                    <textarea class="form-control" name="attendance_data" rows="4"
                                        placeholder="Employee Name, Days Present, Days Absent (one per line)&#10;e.g. John Doe, 26, 0"></textarea>
                                    <small class="text-muted">Format: Employee Name, Days Present, Days Absent (one per line)</small>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label"><strong>Payroll Data</strong></label>
                                    <textarea class="form-control" name="payroll_data" rows="4"
                                        placeholder="Employee Name, Basic, HRA, Deductions, Net Pay (one per line)&#10;e.g. John Doe, 18000, 2000, 1800, 18200"></textarea>
                                    <small class="text-muted">Format: Employee Name, Basic, HRA, Deductions, Net Pay (one per line)</small>
                                </div>
                            </form>
                        </div>
                        <div class="modal-footer">
                            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                            <button type="button" class="btn btn-primary" onclick="submitManualData(${batchId})">Save &amp; Continue</button>
                        </div>
                    </div>
                </div>`;
            document.body.appendChild(modal);
            new bootstrap.Modal(modal).show();
        }

        function showPdfUploadModal(batchId, forms) {
            const modal = document.createElement('div');
            modal.className = 'modal fade';
            modal.id = 'pdfUploadModal';
            modal.innerHTML = `
                <div class="modal-dialog modal-lg">
                    <div class="modal-content">
                        <div class="modal-header">
                            <h5 class="modal-title">📄 PDF Upload - Multiple Forms</h5>
                            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                        </div>
                        <div class="modal-body">
                            <div id="pdf-uploads-container"></div>
                            <button type="button" class="btn btn-secondary btn-sm mt-3" onclick="addPdfUploadRow()">
                                ➕ Add Another Form
                            </button>
                        </div>
                        <div class="modal-footer">
                            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                            <button type="button" class="btn btn-primary" onclick="submitAllPdfUploads(${batchId})">Upload All PDFs</button>
                        </div>
                    </div>
                </div>
            `;
            document.body.appendChild(modal);
            const bsModal = new bootstrap.Modal(modal);
            bsModal.show();

            // Initialize with first row
            const container = document.getElementById('pdf-uploads-container');
            container.innerHTML = '';
            addPdfUploadRow(forms);
        }

        function addPdfUploadRow(forms) {
            const container = document.getElementById('pdf-uploads-container');
            const rowId = 'pdf-row-' + Date.now();

            const row = document.createElement('div');
            row.id = rowId;
            row.className = 'mb-3 p-3 border rounded';
            row.innerHTML = `
                <div class="row">
                    <div class="col-md-6">
                        <label class="form-label"><strong>Select Form</strong></label>
                        <select class="form-control form-code-select" required>
                            <option value="">-- Select a form --</option>
                            ${forms.map(f => `<option value="${f.form_code}">${f.form_code}</option>`).join('')}
                        </select>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label"><strong>Upload PDF File</strong></label>
                        <input type="file" class="form-control pdf-file-input" accept=".pdf" required>
                    </div>
                </div>
                <button type="button" class="btn btn-danger btn-sm mt-2" onclick="removePdfUploadRow('${rowId}')">
                    🗑️ Remove
                </button>
            `;
            container.appendChild(row);
        }

        function removePdfUploadRow(rowId) {
            const row = document.getElementById(rowId);
            if (row) {
                row.remove();
            }
        }

        async function submitAllPdfUploads(batchId) {
            const rows = document.querySelectorAll('#pdf-uploads-container > div');

            if (rows.length === 0) {
                alert('Please add at least one PDF');
                return;
            }

            let uploadedCount = 0;
            let failedCount = 0;

            for (const row of rows) {
                const formCode = row.querySelector('.form-code-select').value;
                const fileInput = row.querySelector('.pdf-file-input');
                const file = fileInput.files[0];

                if (!formCode || !file) {
                    alert('Please select both form and file for all rows');
                    return;
                }

                try {
                    const formData = new FormData();
                    formData.append('file', file);

                    const response = await fetch(`/compliance/form/upload/${batchId}/${formCode}`, {
                        method: 'POST',
                        headers: {
                            'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content
                        },
                        body: formData
                    });

                    const data = await response.json();
                    if (data.status === 'success') {
                        uploadedCount++;
                    } else {
                        failedCount++;
                    }
                } catch (error) {
                    failedCount++;
                }
            }

            if (failedCount === 0) {
                bootstrap.Modal.getInstance(document.getElementById('pdfUploadModal'))?.hide();
                if (!IS_FULL) {
                    markMinimalDataProvided('pdf');
                } else {
                    location.reload();
                }
            } else {
                alert(`⚠️ ${uploadedCount} uploaded, ${failedCount} failed`);
            }
        }

        function showCsvUploadModal(batchId) {
            // Remove stale modal if re-opened
            document.getElementById('csvUploadModal')?.remove();

            const modal = document.createElement('div');
            modal.className = 'modal fade';
            modal.id = 'csvUploadModal';
            modal.innerHTML = `
                <div class="modal-dialog modal-lg">
                    <div class="modal-content">
                        <div class="modal-header">
                            <h5 class="modal-title">📊 CSV Upload — All 3 Datasets</h5>
                            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                        </div>
                        <div class="modal-body">
                            <div id="csv-upload-result" class="mb-3" style="display:none;"></div>
                            <form id="csvUploadForm" novalidate>
                                <div class="row g-3">

                                    <div class="col-md-4">
                                        <div class="p-3 border rounded h-100 d-flex flex-column">
                                            <label class="form-label"><strong>👥 Employees CSV</strong> <span class="text-danger">*</span></label>
                                            <input type="file" class="form-control csv-file-input" id="csvEmployees"
                                                   data-type="employees" accept=".csv,.txt" required>
                                            <div class="form-text">Required: <code>employee_code, name</code></div>
                                            <div class="mt-2" id="csv-status-employees"></div>
                                            <div class="mt-auto pt-3 border-top">
                                                <div class="text-muted" style="font-size:11px; margin-bottom:4px;">📥 Sample CSV Format</div>
                                                <a href="/compliance/csv-template/employees" class="btn btn-outline-secondary btn-sm w-100" download>⬇️ Download Template</a>
                                            </div>
                                        </div>
                                    </div>

                                    <div class="col-md-4">
                                        <div class="p-3 border rounded h-100 d-flex flex-column">
                                            <label class="form-label"><strong>💰 Payroll CSV</strong> <span class="text-danger">*</span></label>
                                            <input type="file" class="form-control csv-file-input" id="csvPayroll"
                                                   data-type="payroll" accept=".csv,.txt" required>
                                            <div class="form-text">Required: <code>employee_code, gross_salary, net_salary</code></div>
                                            <div class="mt-2" id="csv-status-payroll"></div>
                                            <div class="mt-auto pt-3 border-top">
                                                <div class="text-muted" style="font-size:11px; margin-bottom:4px;">📥 Sample CSV Format</div>
                                                <a href="/compliance/csv-template/payroll" class="btn btn-outline-secondary btn-sm w-100" download>⬇️ Download Template</a>
                                            </div>
                                        </div>
                                    </div>

                                    <div class="col-md-4">
                                        <div class="p-3 border rounded h-100 d-flex flex-column">
                                            <label class="form-label"><strong>📅 Attendance CSV</strong> <span class="text-danger">*</span></label>
                                            <input type="file" class="form-control csv-file-input" id="csvAttendance"
                                                   data-type="attendance" accept=".csv,.txt" required>
                                            <div class="form-text">Required: <code>employee_code, working_days</code></div>
                                            <div class="mt-2" id="csv-status-attendance"></div>
                                            <div class="mt-auto pt-3 border-top">
                                                <div class="text-muted" style="font-size:11px; margin-bottom:4px;">📥 Sample CSV Format</div>
                                                <a href="/compliance/csv-template/attendance" class="btn btn-outline-secondary btn-sm w-100" download>⬇️ Download Template</a>
                                            </div>
                                        </div>
                                    </div>

                                </div>
                            </form>
                        </div>
                        <div class="modal-footer">
                            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                            <button type="button" class="btn btn-primary" id="csvSubmitBtn"
                                    onclick="submitCsvUpload(${batchId})">
                                ⬆️ Upload All 3 Files
                            </button>
                        </div>
                    </div>
                </div>`;

            document.body.appendChild(modal);

            // File-picker feedback
            modal.querySelectorAll('.csv-file-input').forEach(input => {
                input.addEventListener('change', function () {
                    const type   = this.dataset.type;
                    const status = document.getElementById('csv-status-' + type);
                    if (this.files.length) {
                        const kb = (this.files[0].size / 1024).toFixed(1);
                        status.innerHTML = `<span class="badge bg-success">✓ ${escapeHtml(this.files[0].name)} (${kb} KB)</span>`;
                    } else {
                        status.innerHTML = '';
                    }
                });
            });

            new bootstrap.Modal(modal).show();
        }

        function submitManualData(batchId) {
            const form = document.getElementById('manualDataForm');
            const employees = form.querySelector('[name=employees_data]').value.trim();
            const attendance = form.querySelector('[name=attendance_data]').value.trim();
            const payroll    = form.querySelector('[name=payroll_data]').value.trim();

            if (!employees || !attendance || !payroll) {
                alert('Please fill in all three sections: Employees, Attendance, and Payroll.');
                return;
            }

            const formData = new FormData(form);

            fetch(`/compliance/batch/${batchId}/save-manual-data`, {
                method: 'POST',
                headers: { 'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content },
                body: formData
            })
            .then(r => r.json())
            .then(data => {
                if (data.status === 'success') {
                    bootstrap.Modal.getInstance(document.getElementById('manualDataModal'))?.hide();
                    markMinimalDataProvided('manual');
                } else {
                    alert('Error: ' + (data.message || 'Failed to save data'));
                }
            })
            .catch(err => alert('Error: ' + err.message));
        }

        async function submitCsvUpload(batchId) {
            const inputs = [
                { id: 'csvEmployees',  type: 'employees'  },
                { id: 'csvPayroll',    type: 'payroll'    },
                { id: 'csvAttendance', type: 'attendance' },
            ];

            // Validate all 3 files are selected
            const missing = inputs.filter(i => !document.getElementById(i.id)?.files[0]);
            if (missing.length) {
                _csvShowResult('error', '⚠️ Please select all 3 CSV files: ' +
                    missing.map(i => i.type).join(', '));
                return;
            }

            const btn = document.getElementById('csvSubmitBtn');
            btn.disabled = true;
            btn.textContent = '⏳ Uploading…';
            _csvShowResult('', '');

            const results = { success: [], failed: [], generationResult: null };

            // Upload each file sequentially so employees exist before payroll/attendance
            for (const { id, type } of inputs) {
                const file = document.getElementById(id).files[0];
                const fd   = new FormData();
                fd.append('file', file);
                fd.append('dataset_type', type);

                try {
                    const res = await fetch(`/compliance/batch/${batchId}/upload-csv`, {
                        method: 'POST',
                        headers: {
                            'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content,
                            'Accept': 'application/json',
                        },
                        body: fd,
                    });

                    // Guard: always read as text first, then parse — prevents
                    // JSON.parse crash when server returns HTML on fatal errors.
                    const rawText = await res.text();
                    // Strip UTF-8 BOM (\uFEFF) that some PHP environments prepend
                    const cleanText = rawText.replace(/^\uFEFF/, '').trim();
                    let data;
                    try {
                        data = JSON.parse(cleanText);
                    } catch (_) {
                        console.error(`[CSV Upload] Non-JSON response for ${type} (HTTP ${res.status}):`, cleanText.slice(0, 400));
                        data = { status: 'error', message: `Server error (HTTP ${res.status}) — check browser console for details` };
                    }

                    if (data.status === 'success') {
                        results.success.push(`${type} (${data.records_inserted} records)`);
                        document.getElementById('csv-status-' + type).innerHTML =
                            `<span class="badge bg-success">✅ ${data.records_inserted} records imported</span>`;
                        // Capture generation result from the last file (attendance triggers it)
                        if (data.generation) results.generationResult = data.generation;
                    } else {
                        const hint = data.hint ? ` <em style="font-size:11px;">(${escapeHtml(data.hint)})</em>` : '';
                        results.failed.push(`${type}: ${data.message}`);
                        document.getElementById('csv-status-' + type).innerHTML =
                            `<span class="badge bg-danger">❌ ${escapeHtml(data.message)}</span>${hint}`;
                    }
                } catch (err) {
                    results.failed.push(`${type}: ${err.message}`);
                    document.getElementById('csv-status-' + type).innerHTML =
                        `<span class="badge bg-danger">❌ ${escapeHtml(err.message)}</span>`;
                }
            }

            btn.disabled = false;
            btn.textContent = '⬆️ Upload All 3 Files';

            if (results.failed.length === 0) {
                // All 3 succeeded — check if generation was auto-triggered
                const gen = results.generationResult;

                let successMsg = `<strong>✅ All 3 datasets uploaded successfully.</strong>`;

                if (gen && gen.triggered) {
                    successMsg += `<br><span class="badge bg-success mt-1">🚀 Forms generated automatically: ${gen.generated_forms} generated, ${gen.failed_forms} failed</span>`;
                } else if (gen && !gen.triggered) {
                    successMsg += `<br><span class="badge bg-warning text-dark mt-1">⏳ ${escapeHtml(gen.reason)}</span>`;
                }

                _csvShowResult('success', successMsg);

                setTimeout(() => {
                    bootstrap.Modal.getInstance(document.getElementById('csvUploadModal'))?.hide();

                    // If generation ran, trigger the batch processing UI so the
                    // dashboard reflects the new state without a page reload
                    if (gen && gen.triggered && gen.generated_forms > 0) {
                        BatchProcessor.showComplete(batchId);
                    }
                }, 1200);

                if (!IS_FULL) {
                    _minimalDataProvided.employees  = true;
                    _minimalDataProvided.payroll    = true;
                    _minimalDataProvided.attendance = true;
                    refreshMinimalProceedBtn();
                }

                if (ManualPanel.batchId) ManualPanel.loadItems();

            } else {
                _csvShowResult('error',
                    '❌ Some uploads failed:<br>' + results.failed.map(escapeHtml).join('<br>') +
                    (results.success.length ? '<br>✅ Succeeded: ' + results.success.join(', ') : ''));
            }
        }

        function _csvShowResult(type, msg) {
            const el = document.getElementById('csv-upload-result');
            if (!el) return;
            if (!type) { el.style.display = 'none'; return; }
            el.className = type === 'error' ? 'alert alert-danger' : 'alert alert-success';
            el.innerHTML = msg;
            el.style.display = '';
        }

        document.addEventListener('click', function(e) {
            if (e.target.classList.contains('proceed-batch-btn')) {
                const batchId = e.target.dataset.batch;
                BatchProcessor.processBatch(batchId);
            }

            if (e.target.classList.contains('cancel-batch-btn')) {
                document.getElementById('batch-review-container').innerHTML = '';
            }

            if (e.target.classList.contains('preview-btn')) {
                const batchId = e.target.dataset.batch;
                const formCode = e.target.dataset.form;
                openPreview(batchId, formCode);
            }
        });

        function openPreview(batchId, formCode) {
            const previewModal = new bootstrap.Modal(document.getElementById('preview-modal'));
            document.getElementById('preview-title').textContent = `Preview - ${escapeHtml(formCode)}`;
            document.getElementById('preview-content').innerHTML = '<div class="text-center"><div class="spinner-border"></div></div>';

            fetch(`/compliance/batch/${batchId}/preview/${formCode}`)
                .then(r => r.text())
                .then(html => {
                    document.getElementById('preview-content').innerHTML = html;
                })
                .catch(err => {
                    document.getElementById('preview-content').innerHTML = `<div class="alert alert-danger">Error: ${escapeHtml(err.message)}</div>`;
                });

            previewModal.show();
        }

        // ─── Manual Compliance Panel ───────────────────────────────────────────

        const ManualPanel = {
            batchId: null,
            uploadItemId: null,
            uploadModal: null,

            init(batchId) {
                this.batchId = batchId;
                this.uploadModal = new bootstrap.Modal(document.getElementById('manualUploadModal'));
                document.getElementById('manual-compliance-panel').style.display = '';
                document.getElementById('batch-section-row').classList.add('has-manual');
                this.loadItems();
            },

            async loadItems() {
                try {
                    const res = await fetch(`/compliance/manual-batch/${this.batchId}`);
                    const data = await res.json();
                    if (!res.ok) throw new Error(data.message || 'Failed to load tasks');
                    this.renderItems(data.items || []);
                    this.updateProgress();
                } catch (err) {
                    this.showGlobalError(err.message);
                }
            },

            renderItems(items) {
                const tbody = document.getElementById('manual-tasks-body');
                if (!items.length) {
                    tbody.innerHTML = '<tr><td colspan="4" class="text-center text-muted" style="padding:20px;">No manual tasks for this period.</td></tr>';
                    return;
                }
                tbody.innerHTML = items.map(item => {
                    const statusBadge = {
                        completed: '<span class="ant-tag ant-tag-success">✅ Completed</span>',
                        skipped:   '<span class="ant-tag ant-tag-default">⏭️ Skipped</span>',
                        pending:   '<span class="ant-tag ant-tag-processing">⏳ Pending</span>',
                    }[item.status] || `<span class="ant-tag">${escapeHtml(item.status)}</span>`;

                    const actions = item.status === 'pending'
                        ? `<button class="ant-btn ant-btn-primary ant-btn-sm me-1 manual-yes-btn" data-id="${item.item_id}" data-name="${escapeHtml(item.compliance_name)}">✅ YES</button>
                           <button class="ant-btn ant-btn-default ant-btn-sm manual-no-btn" data-id="${item.item_id}">❌ NO</button>`
                        : `<span class="text-muted" style="font-size:12px;">—</span>`;

                    return `<tr id="manual-row-${item.item_id}">
                        <td><strong>${escapeHtml(item.compliance_name)}</strong></td>
                        <td>${escapeHtml(item.act_name || '—')}</td>
                        <td>${statusBadge}</td>
                        <td>${actions}</td>
                    </tr>`;
                }).join('');
            },

            async updateProgress() {
                try {
                    const res = await fetch(`/compliance/manual-batch/${this.batchId}/summary`);
                    const data = await res.json();
                    if (!res.ok) return;

                    const { total, completed, skipped, pending } = data;
                    const done = completed + skipped;
                    const pct = total > 0 ? Math.round(done / total * 100) : 0;

                    document.getElementById('manual-progress-badge').textContent = `${completed} / ${total} completed`;
                    const bar = document.getElementById('manual-progress-bar');
                    bar.style.width = pct + '%';
                    bar.textContent = pct + '%';
                    if (pct === 100) {
                        bar.classList.remove('progress-bar-animated', 'bg-info');
                        bar.classList.add('bg-success');
                    }

                    // Store for download-lock check
                    window._manualPending = pending;
                    checkDownloadLock();
                } catch (_) {}
            },

            openUploadModal(itemId, name) {
                this.uploadItemId = itemId;
                document.getElementById('manual-upload-compliance-name').textContent = name;
                document.getElementById('manual-upload-file').value = '';
                document.getElementById('manual-upload-error').style.display = 'none';
                this.uploadModal.show();
            },

            async submitUpload() {
                const file = document.getElementById('manual-upload-file').files[0];
                const errEl = document.getElementById('manual-upload-error');
                if (!file) { errEl.textContent = 'Please select a file.'; errEl.style.display = ''; return; }

                const btn = document.getElementById('manual-upload-submit');
                btn.disabled = true;
                btn.textContent = 'Uploading…';

                const fd = new FormData();
                fd.append('item_id', this.uploadItemId);
                fd.append('file', file);

                try {
                    const res = await fetch('/compliance/manual-item/upload', {
                        method: 'POST',
                        headers: { 'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content },
                        body: fd
                    });
                    const data = await res.json();
                    if (!data.success) throw new Error(data.message || 'Upload failed');

                    this.uploadModal.hide();
                    this.updateRowStatus(this.uploadItemId, 'completed');
                    this.updateProgress();
                } catch (err) {
                    errEl.textContent = err.message;
                    errEl.style.display = '';
                } finally {
                    btn.disabled = false;
                    btn.textContent = 'Upload & Complete';
                }
            },

            async skipItem(itemId) {
                const row = document.getElementById(`manual-row-${itemId}`);
                if (row) row.style.opacity = '0.5';

                try {
                    const res = await fetch('/compliance/manual-item/skip', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content
                        },
                        body: JSON.stringify({ item_id: itemId })
                    });
                    const data = await res.json();
                    if (!data.success) throw new Error(data.message || 'Skip failed');

                    this.updateRowStatus(itemId, 'skipped');
                    this.updateProgress();
                } catch (err) {
                    if (row) row.style.opacity = '';
                    const errCell = row?.querySelector('td:last-child');
                    if (errCell) errCell.innerHTML += `<div class="text-danger" style="font-size:11px;">${escapeHtml(err.message)}</div>`;
                }
            },

            updateRowStatus(itemId, status) {
                const row = document.getElementById(`manual-row-${itemId}`);
                if (!row) return;
                row.style.opacity = '';
                const badges = {
                    completed: '<span class="ant-tag ant-tag-success">✅ Completed</span>',
                    skipped:   '<span class="ant-tag ant-tag-default">⏭️ Skipped</span>',
                };
                row.cells[2].innerHTML = badges[status] || '';
                row.cells[3].innerHTML = '<span class="text-muted" style="font-size:12px;">—</span>';
            },

            showGlobalError(msg) {
                const el = document.getElementById('manual-global-error');
                el.textContent = msg;
                el.style.display = '';
            }
        };

        // Wire up manual panel button clicks via delegation
        document.addEventListener('click', function(e) {
            if (e.target.classList.contains('manual-yes-btn')) {
                ManualPanel.openUploadModal(
                    e.target.dataset.id,
                    e.target.dataset.name
                );
            }
            if (e.target.classList.contains('manual-no-btn')) {
                ManualPanel.skipItem(e.target.dataset.id);
            }
        });

        document.getElementById('manual-upload-submit').addEventListener('click', () => ManualPanel.submitUpload());

        // Prevent disabled download link from navigating
        document.addEventListener('click', function(e) {
            const btn = e.target.closest('#download-pack-btn');
            if (btn && btn.hasAttribute('disabled')) e.preventDefault();
        });

        // ─── Download Lock Logic ───────────────────────────────────────────────
        window._automatedComplete = false;
        window._manualPending = null; // null = not yet loaded

        function checkDownloadLock() {
            const btn = document.getElementById('download-pack-btn');
            if (!btn) return;

            // null means manual panel hasn't loaded yet — don't unlock
            const manualReady = window._manualPending === 0;
            const canDownload = window._automatedComplete && manualReady;

            if (canDownload) {
                btn.removeAttribute('disabled');
                btn.style.pointerEvents = '';
                btn.title = '';
                btn.classList.remove('ant-btn-default');
                btn.classList.add('ant-btn-primary');

                if (!btn.dataset.unlocked) {
                    btn.dataset.unlocked = '1';
                    showUnlockToast();
                }
            } else {
                btn.setAttribute('disabled', 'disabled');
                btn.style.pointerEvents = 'none';
                btn.title = 'Complete all automated PDFs and manual tasks first';
                btn.classList.remove('ant-btn-primary');
                btn.classList.add('ant-btn-default');
            }

            updateDualProgressLabel();
        }

        function updateDualProgressLabel() {
            const lbl = document.getElementById('manual-progress-label');
            if (!lbl) return;
            if (window._manualPending === null) {
                lbl.textContent = 'Loading…';
            } else if (window._manualPending === 0) {
                lbl.textContent = 'Complete ✅';
            } else {
                lbl.textContent = `${window._manualPending} task(s) pending ⏳`;
            }
        }

        function showUnlockToast() {
            const toast = document.createElement('div');
            toast.className = 'ant-alert ant-alert-success';
            toast.style.cssText = 'position:fixed;bottom:24px;right:24px;z-index:9999;padding:14px 20px;border-radius:6px;box-shadow:0 4px 12px rgba(0,0,0,.15);max-width:360px;';
            toast.innerHTML = '🎉 <strong>All compliance tasks completed.</strong> You can now download the inspection pack.';
            document.body.appendChild(toast);
            setTimeout(() => toast.remove(), 5000);
        }

        // Patch BatchProcessor.showComplete to set automated flag
        const _origShowComplete = BatchProcessor.showComplete.bind(BatchProcessor);
        BatchProcessor.showComplete = function(batchId) {
            _origShowComplete(batchId);
            window._automatedComplete = true;

            const card = document.getElementById('processing-card');
            if (card && !document.getElementById('dual-progress-summary')) {
                const summary = document.createElement('div');
                summary.id = 'dual-progress-summary';
                summary.className = 'mt-3';
                summary.innerHTML = `
                    <div class="ant-alert ant-alert-info" style="margin-bottom:12px;">
                        <div style="display:flex; gap:24px; flex-wrap:wrap;">
                            <span>🤖 <strong>Automated PDFs:</strong> <span id="auto-progress-label">Complete ✅</span></span>
                            <span>📋 <strong>Manual Compliance:</strong> <span id="manual-progress-label">Loading…</span></span>
                        </div>
                    </div>
                    <div class="text-end">
                        <button type="button"
                                class="ant-btn ant-btn-default"
                                id="download-pack-btn"
                                disabled
                                style="pointer-events:none;"
                                title="Complete all automated PDFs and manual tasks first"
                                onclick="window.location='/compliance/batch/${batchId}/inspection-pack'">
                            📦 Download Inspection Pack
                        </button>
                    </div>`;
                card.appendChild(summary);
            }

            checkDownloadLock();
        };

        // Keep dual-progress label in sync
        const _origUpdateProgress = BatchProcessor.updateProgress.bind(BatchProcessor);
        BatchProcessor.updateProgress = function(data) {
            _origUpdateProgress(data);
            const lbl = document.getElementById('auto-progress-label');
            if (lbl) lbl.textContent = `${data.generated} / ${data.total} generated`;
        };

        // Activate manual panel when batch processing starts
        const _origProcessBatch = BatchProcessor.processBatch.bind(BatchProcessor);
        BatchProcessor.processBatch = async function(batchId) {
            ManualPanel.init(batchId);
            await _origProcessBatch(batchId);
        };
    })();
    </script>
@endpush
