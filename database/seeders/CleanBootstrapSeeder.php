<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class CleanBootstrapSeeder extends Seeder
{
    public function run(): void
    {
        // Disable foreign key checks (MySQL compatible)
        DB::statement('SET FOREIGN_KEY_CHECKS=0');

        // Clear old data
        DB::table('compliance_forms_master')->truncate();
        DB::table('compliance_sections')->truncate();

        // Re-enable foreign key checks
        DB::statement('SET FOREIGN_KEY_CHECKS=1');

        // Seed sections
        $sections = [
            ['section_name' => 'Contract Labour Regulation Act', 'section_code' => 'CLRA', 'is_active' => true],
            ['section_name' => 'Labour Welfare', 'section_code' => 'LABOUR_WELFARE', 'is_active' => true],
            ['section_name' => 'Social Security', 'section_code' => 'SOCIAL_SECURITY', 'is_active' => true],
            ['section_name' => 'Factories Act', 'section_code' => 'FACTORIES_ACT', 'is_active' => true],
            ['section_name' => 'Shops & Establishment', 'section_code' => 'SHOPS_ESTABLISHMENT', 'is_active' => true],
        ];

        foreach ($sections as $section) {
            DB::table('compliance_sections')->insert($section);
        }

        // Seed forms with correct ENUM values
        $forms = [
            // CLRA Forms
            ['form_code' => 'FormXII', 'form_name' => 'Register of Contractors', 'act_type' => 'CLRA', 'frequency' => 'Monthly', 'priority' => 'High', 'is_active' => true],
            ['form_code' => 'FormXIII', 'form_name' => 'Register of Workmen Employed by Contractor', 'act_type' => 'CLRA', 'frequency' => 'Monthly', 'priority' => 'High', 'is_active' => true],
            ['form_code' => 'FormXIV', 'form_name' => 'Employment Card', 'act_type' => 'CLRA', 'frequency' => 'Monthly', 'priority' => 'High', 'is_active' => true],
            ['form_code' => 'FormXVI', 'form_name' => 'Muster Roll', 'act_type' => 'CLRA', 'frequency' => 'Monthly', 'priority' => 'High', 'is_active' => true],
            ['form_code' => 'FormXVII', 'form_name' => 'Register of Wages', 'act_type' => 'CLRA', 'frequency' => 'Monthly', 'priority' => 'High', 'is_active' => true],
            ['form_code' => 'FormXIX', 'form_name' => 'Wage Slip', 'act_type' => 'CLRA', 'frequency' => 'Monthly', 'priority' => 'Medium', 'is_active' => true],
            ['form_code' => 'FormXX', 'form_name' => 'Register of Deductions', 'act_type' => 'CLRA', 'frequency' => 'Monthly', 'priority' => 'High', 'is_active' => true],
            ['form_code' => 'FormXXI', 'form_name' => 'Register of Fines', 'act_type' => 'CLRA', 'frequency' => 'Monthly', 'priority' => 'Medium', 'is_active' => true],
            ['form_code' => 'FormXXII', 'form_name' => 'Register of Advances', 'act_type' => 'CLRA', 'frequency' => 'Monthly', 'priority' => 'Medium', 'is_active' => true],
            ['form_code' => 'FormXXIII', 'form_name' => 'Register of Overtime', 'act_type' => 'CLRA', 'frequency' => 'Monthly', 'priority' => 'Medium', 'is_active' => true],

            // Labour Welfare Forms
            ['form_code' => 'FormA', 'form_name' => 'Bonus Register', 'act_type' => 'ESI', 'frequency' => 'Annual', 'priority' => 'High', 'is_active' => true],
            ['form_code' => 'FormC', 'form_name' => 'Bonus Register', 'act_type' => 'ESI', 'frequency' => 'Annual', 'priority' => 'High', 'is_active' => true],
            ['form_code' => 'FormD', 'form_name' => 'Equal Remuneration Register', 'act_type' => 'ESI', 'frequency' => 'Monthly', 'priority' => 'Medium', 'is_active' => true],
            ['form_code' => 'FormDER', 'form_name' => 'Equal Remuneration Details', 'act_type' => 'ESI', 'frequency' => 'Monthly', 'priority' => 'Medium', 'is_active' => true],

            // Social Security Forms
            ['form_code' => 'Form11', 'form_name' => 'Accident Register', 'act_type' => 'ESI', 'frequency' => 'Monthly', 'priority' => 'High', 'is_active' => true],
            ['form_code' => 'ESIForm12', 'form_name' => 'Adult Worker Register', 'act_type' => 'ESI', 'frequency' => 'Monthly', 'priority' => 'High', 'is_active' => true],
            ['form_code' => 'EPFInspection', 'form_name' => 'EPF Inspection Register', 'act_type' => 'EPF', 'frequency' => 'HalfYearly', 'priority' => 'High', 'is_active' => true],

            // Factories Act Forms
            ['form_code' => 'FormB', 'form_name' => 'Muster Roll', 'act_type' => 'Factories', 'frequency' => 'Monthly', 'priority' => 'High', 'is_active' => true],
            ['form_code' => 'Form2', 'form_name' => 'Notice of Periods of Work', 'act_type' => 'Factories', 'frequency' => 'Monthly', 'priority' => 'High', 'is_active' => true],
            ['form_code' => 'Form8', 'form_name' => 'Register of Workmen', 'act_type' => 'Factories', 'frequency' => 'Monthly', 'priority' => 'High', 'is_active' => true],
            ['form_code' => 'Form10', 'form_name' => 'Register of Fines', 'act_type' => 'Factories', 'frequency' => 'Monthly', 'priority' => 'Medium', 'is_active' => true],
            ['form_code' => 'Form12', 'form_name' => 'Register of Advances', 'act_type' => 'Factories', 'frequency' => 'Monthly', 'priority' => 'Medium', 'is_active' => true],
            ['form_code' => 'Form17', 'form_name' => 'Health Register', 'act_type' => 'Factories', 'frequency' => 'Monthly', 'priority' => 'Medium', 'is_active' => true],
            ['form_code' => 'Form18', 'form_name' => 'Report of Accident', 'act_type' => 'Factories', 'frequency' => 'Monthly', 'priority' => 'High', 'is_active' => true],
            ['form_code' => 'Form25', 'form_name' => 'Muster Roll', 'act_type' => 'Factories', 'frequency' => 'Monthly', 'priority' => 'High', 'is_active' => true],
            ['form_code' => 'Form26', 'form_name' => 'Register of Accident', 'act_type' => 'Factories', 'frequency' => 'Monthly', 'priority' => 'High', 'is_active' => true],
            ['form_code' => 'Form26A', 'form_name' => 'Register of Dangerous Occurrences', 'act_type' => 'Factories', 'frequency' => 'Monthly', 'priority' => 'High', 'is_active' => true],
            ['form_code' => 'HazardReg', 'form_name' => 'Hazard Register', 'act_type' => 'Factories', 'frequency' => 'Monthly', 'priority' => 'High', 'is_active' => true],

            // Shops & Establishment Forms
            ['form_code' => 'ShopsForm12', 'form_name' => 'Shops Register', 'act_type' => 'Shops', 'frequency' => 'Monthly', 'priority' => 'High', 'is_active' => true],
            ['form_code' => 'ShopsForm13', 'form_name' => 'Shops Register', 'act_type' => 'Shops', 'frequency' => 'Monthly', 'priority' => 'High', 'is_active' => true],
            ['form_code' => 'ShopsFormC', 'form_name' => 'Shops Register', 'act_type' => 'Shops', 'frequency' => 'Monthly', 'priority' => 'High', 'is_active' => true],
            ['form_code' => 'ShopsFormVI', 'form_name' => 'Holidays Register', 'act_type' => 'Shops', 'frequency' => 'Monthly', 'priority' => 'Medium', 'is_active' => true],
            ['form_code' => 'ShopsUnpaid', 'form_name' => 'Unpaid Wages Register', 'act_type' => 'Shops', 'frequency' => 'Monthly', 'priority' => 'High', 'is_active' => true],
            ['form_code' => 'ShopsFines', 'form_name' => 'Fines Register', 'act_type' => 'Shops', 'frequency' => 'Monthly', 'priority' => 'Medium', 'is_active' => true],
        ];

        DB::table('compliance_forms_master')->insert($forms);

        $this->command->info('✓ Bootstrap seeding complete: 5 sections + 34 forms');
    }
}
