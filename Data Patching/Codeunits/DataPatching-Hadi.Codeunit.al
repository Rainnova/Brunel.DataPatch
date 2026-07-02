codeunit 85999 "Data Patching (Hadi)"
{
    Permissions = tabledata "Sales Invoice Line" = rm,
                  tabledata "Purch. Inv. Line" = rm;

    trigger OnRun()
    begin
        Clear(Progress);

        // SetupPayrollProcessing(true);
        Patch_260618();

        Progress.Close();
        Message('Patch is completed.');
    end;

    var
        Progress: Codeunit "Progress Dialog Box";
        AL: Codeunit "AL Helper";
        TextHelper: Codeunit "Text Helper";

    #region --- Payroll-specific setup ---

    procedure SetupPayrollProcessing(Enable: Boolean)
    var
        SourceCodeSetup: Record "Source Code Setup";
        PayrollSetup: Record "Payroll Setup (Work.4s)";
    begin
        SetupSourceCode(SourceCodeSetup.FieldNo(Payroll), 'PAYROLL', 'Payroll Processing');
        SetupPayrollAssignmentJournal('SYSTEM', '', 'PAYROLL', 'Payroll Processing');
        SetupPayrollGeneralJournal('PAYROLL', 'Payroll Processing', 'PAYROLL', 'General Payroll Processing');
        SetupPayrollNoSeries(PayrollSetup.FieldNo("Payroll Set Nos."), 'T-PAYROLLSET', 'Payroll Set', true, false, true, 'PYS', "No. Series Reset Period"::Monthly, true, 4, '-');

        SetupRecognitionGroup(
            'PAYROLLBYEMP', 'Payroll Grouped by Employee by Assignment',
            StrSubstNo('%1,%2,%3,%4', "Recognition Group Item"::Employee, "Recognition Group Item"::Assignment, "Recognition Group Item"::Period, "Recognition Group Item"::"Rate Group"));
        SetupRecognitionGroup(
            'PAYROLLBYASGR', 'Payroll Grouped by Assignment Group by Assignment',
            StrSubstNo('%1,%2,%3,%4', "Recognition Group Item"::"Assignment Group", "Recognition Group Item"::Assignment, "Recognition Group Item"::Period, "Recognition Group Item"::"Rate Group"));
        SetupRecognitionGroup(
            'PAYROLLBYASG', 'Payroll Grouped by Assignment',
            StrSubstNo('%1,%2,%3', "Recognition Group Item"::Assignment, "Recognition Group Item"::Period, "Recognition Group Item"::"Rate Group"));
        SetupPayrollRecognitionGroups('PAYROLLBYEMP', 'PAYROLLBYEMP', 'PAYROLLBYASGR', 'PAYROLLBYASG');

        PayrollSetup.GetSetup();
        PayrollSetup.Validate("Enable Payroll Processing", Enable);
        PayrollSetup.Modify(true);
    end;

    procedure SetupPayrollAssignmentJournal(JournalTemplateName: Code[20]; JournaTemplateDescription: Text; JournalBatchName: Code[20]; JournalBatchDescription: Text)
    var
        ManpowerSetup: Record "Manpower Setup";
        AssignmentJnlTemplate: Record "Assignment Journal Template";
        AssignmentJnlBatch: Record "Assignment Journal Batch";
    begin
        if (JournalTemplateName = '') or (JournalBatchName = '') then
            exit;

        AssignmentJnlTemplate := SetupAssignmentJnlTemplate(JournalTemplateName, JournaTemplateDescription);
        AssignmentJnlBatch := SetupAssignmentJnlBatch(AssignmentJnlTemplate."Name", JournalBatchName, JournalBatchDescription);

        ManpowerSetup.GetSetup();
        ManpowerSetup.Validate("Payroll Asgmt. Jnl. Template", AssignmentJnlBatch."Journal Template Name");
        ManpowerSetup.Validate("Payroll Asgmt. Jnl. Batch", AssignmentJnlBatch."Name");
        ManpowerSetup.Modify(true);
    end;

    procedure SetupPayrollGeneralJournal(JournalTemplateName: Code[20]; JournaTemplateDescription: Text; JournalBatchName: Code[20]; JournalBatchDescription: Text)
    var
        GLSetup: Record "General Ledger Setup";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        if (JournalTemplateName = '') or (JournalBatchName = '') then
            exit;

        GenJnlTemplate := SetupGeneralJnlTemplate(JournalTemplateName, JournaTemplateDescription);
        GenJnlBatch := SetupGeneralJnlBatch(GenJnlTemplate."Name", JournalBatchName, JournalBatchDescription);

        GLSetup.GetSetup();
        GLSetup.Validate("Payroll Journal Template Name", GenJnlBatch."Journal Template Name");
        GLSetup.Validate("Payroll Journal Batch Name", GenJnlBatch."Name");
        GLSetup.Modify(true);
    end;

    procedure SetupPayrollRecognitionGroups(RecognitionGroupingCode: Code[20]; EmployeeGroupingCode: Code[20]; AssignmentGroupGroupingCode: Code[20]; AssignmentGroupingCode: Code[20])
    var
        PayrollSetup: Record "Payroll Setup (Work.4s)";
    begin
        PayrollSetup.GetSetup();
        PayrollSetup.Validate("Default Recognition Grouping", RecognitionGroupingCode);
        PayrollSetup.Validate("Default Employee Grouping", EmployeeGroupingCode);
        PayrollSetup.Validate("Default Asgmt. Group Grouping", AssignmentGroupGroupingCode);
        PayrollSetup.Validate("Default Assignment Grouping", AssignmentGroupingCode);
        PayrollSetup.Modify(true);
    end;

    procedure SetupPayrollNoSeries(SetupFieldNumber: Integer; SeriesCode: Code[20]; SeriesDescription: Text; DefaultNos: Boolean; ManualNos: Boolean; PrefixWithCoIntials: Boolean; Prefix: Code[10]; ResetPeriod: Enum "No. Series Reset Period"; IncludeResetPeriod: Boolean; NoOfDigits: Integer; Separator: Text[1])
    var
        NoSeries: Record "No. Series";
        PayrollSetup: Record "Payroll Setup (Work.4s)";
        PayrollSetupRef: RecordRef;
        PayrollSetupField: FieldRef;
    begin
        if (SetupFieldNumber = 0) or (SeriesCode = '') then
            exit;

        PayrollSetup.GetSetup();
        PayrollSetupRef.GetTable(PayrollSetup);
        PayrollSetupField := PayrollSetupRef.Field(SetupFieldNumber);

        NoSeries := SetupNoSeries(SeriesCode, SeriesDescription, DefaultNos, ManualNos, PrefixWithCoIntials, Prefix, ResetPeriod, IncludeResetPeriod, NoOfDigits, Separator);

        PayrollSetupField.Validate(NoSeries."Code");
        PayrollSetupRef.Modify(true);
        PayrollSetupRef.SetTable(PayrollSetup);
    end;

    #endregion --- Payroll-specific setup ---

    #region --- Generic setup ---

    procedure SetupSourceCode(SetupFieldNumber: Integer; SourceCode: Code[20]; SourceDescription: Text)
    var
        SourceCodeRec: Record "Source Code";
        SourceCodeSetup: Record "Source Code Setup";
        SourceCodeSetupRef: RecordRef;
        SourceCodeSetupField: FieldRef;
    begin
        if (SetupFieldNumber = 0) or (SourceCode = '') then
            exit;

        SourceCodeSetup.GetSetup();
        SourceCodeSetupRef.GetTable(SourceCodeSetup);
        SourceCodeSetupField := SourceCodeSetupRef.Field(SetupFieldNumber);

        SourceCodeRec := SetupSourceCode(SourceCode, SourceDescription);

        SourceCodeSetupField.Validate(SourceCodeRec."Code");
        SourceCodeSetupRef.Modify(true);
        SourceCodeSetupRef.SetTable(SourceCodeSetup);
    end;

    procedure SetupSourceCode(SourceCode: Code[20]; SourceDescription: Text) SourceCodeRec: Record "Source Code"
    begin
        if SourceCode = '' then
            exit;

        SourceCodeRec.Init();
        SourceCodeRec.Validate("Code", SourceCode);
        if not SourceCodeRec.Find() then
            SourceCodeRec.Insert(true);
        if SourceDescription <> '' then begin
            SourceCodeRec.Validate(Description, SourceDescription);
            SourceCodeRec.Modify(true);
        end;
    end;

    procedure SetupAssignmentJnlTemplate(TemplateName: Code[20]; TemplateDescription: Text) AssignmentJnlTemplate: Record "Assignment Journal Template"
    begin
        if TemplateName = '' then
            exit;

        AssignmentJnlTemplate.Init();
        AssignmentJnlTemplate.Validate("Name", TemplateName);
        if not AssignmentJnlTemplate.Find() then
            AssignmentJnlTemplate.Insert(true);
        if TemplateDescription <> '' then begin
            AssignmentJnlTemplate.Validate(Description, TemplateDescription);
            AssignmentJnlTemplate.Modify(true);
        end;
    end;

    procedure SetupAssignmentJnlBatch(TemplateName: Code[20]; BatchName: Code[20]; BatchDescription: Text) AssignmentJnlBatch: Record "Assignment Journal Batch"
    begin
        if (TemplateName = '') or (BatchName = '') then
            exit;

        AssignmentJnlBatch.Init();
        AssignmentJnlBatch.Validate("Journal Template Name", TemplateName);
        AssignmentJnlBatch.Validate("Name", BatchName);
        if not AssignmentJnlBatch.Find() then
            AssignmentJnlBatch.Insert(true);
        if BatchDescription <> '' then begin
            AssignmentJnlBatch.Validate(Description, BatchDescription);
            AssignmentJnlBatch.Modify(true);
        end;
    end;

    procedure SetupGeneralJnlTemplate(TemplateName: Code[20]; TemplateDescription: Text) GeneralJnlTemplate: Record "Gen. Journal Template"
    begin
        if TemplateName = '' then
            exit;

        GeneralJnlTemplate.Init();
        GeneralJnlTemplate.Validate("Name", TemplateName);
        if not GeneralJnlTemplate.Find() then
            GeneralJnlTemplate.Insert(true);
        if TemplateDescription <> '' then begin
            GeneralJnlTemplate.Validate(Description, TemplateDescription);
            GeneralJnlTemplate.Modify(true);
        end;
    end;

    procedure SetupGeneralJnlBatch(TemplateName: Code[20]; BatchName: Code[20]; BatchDescription: Text) GeneralJnlBatch: Record "Gen. Journal Batch"
    begin
        if (TemplateName = '') or (BatchName = '') then
            exit;

        GeneralJnlBatch.Init();
        GeneralJnlBatch.Validate("Journal Template Name", TemplateName);
        GeneralJnlBatch.Validate("Name", BatchName);
        if not GeneralJnlBatch.Find() then
            GeneralJnlBatch.Insert(true);
        if BatchDescription <> '' then begin
            GeneralJnlBatch.Validate(Description, BatchDescription);
            GeneralJnlBatch.Modify(true);
        end;
    end;

    procedure SetupRecognitionGroup(GroupCode: Code[20]; GroupName: Text; GroupItemsInCSV: Text) Group: Record "Asgmt. Recognition Group"
    var
        RecogGroupItem: Record "Asgmt. Recognition Group Item";
        LineNo: Integer;
        GroupItemList: List of [Text];
        GroupItemName: Text;
        GroupItem: Enum "Recognition Group Item";
    begin
        if (GroupCode = '') or (GroupItemsInCSV = '') then
            exit;

        Group.Init();
        Group.Validate("Code", GroupCode);
        if not Group.Find() then
            Group.Insert(true);
        if GroupName <> '' then begin
            Group.Validate("Name", GroupName);
            Group.Modify(true);
        end;

        RecogGroupItem.SetRange("Group Code", Group."Code");
        RecogGroupItem.DeleteAll(true);

        TextHelper.Deserialize(GroupItemsInCSV, GroupItemList);
        foreach GroupItemName in GroupItemList do begin
            RecogGroupItem.Init();
            RecogGroupItem.Validate("Group Code", Group."Code");
            RecogGroupItem.Validate("Line No.", AL.Plus(LineNo, 10000));
            RecogGroupItem.Validate("Group Item", GroupItem.Names.IndexOf(GroupItemName) - 1);
            RecogGroupItem.Insert(true);
        end;
    end;

    procedure SetupNoSeries(SeriesCode: Code[20]; SeriesDescription: Text; DefaultNos: Boolean; ManualNos: Boolean; PrefixWithCoIntials: Boolean; Prefix: Code[10]; ResetPeriod: Enum "No. Series Reset Period"; IncludeResetPeriod: Boolean; NoOfDigits: Integer; Separator: Text[1]) NoSeries: Record "No. Series"
    var
        CreateNoSeriesLines: Report "Create No. Series Lines";
    begin
        if SeriesCode = '' then
            exit;

        NoSeries.Init();
        NoSeries.Validate("Code", SeriesCode);
        if not NoSeries.Find() then
            NoSeries.Insert(true);

        if SeriesDescription <> '' then
            NoSeries.Validate(Description, SeriesDescription);
        NoSeries.Validate("Default Nos.", DefaultNos);
        NoSeries.Validate("Manual Nos.", ManualNos);
        NoSeries.Validate("Prefix with Company Initials", PrefixWithCoIntials);
        NoSeries.Validate(Prefix, Prefix);
        NoSeries.Validate("Reset Period", ResetPeriod);
        NoSeries.Validate("Include Reset Period", IncludeResetPeriod);
        NoSeries.Validate("No. of Digits", NoOfDigits);
        NoSeries.Validate("Element Separator", Separator);
        NoSeries.Modify(true);
        NoSeries.AutoCreateLines();
    end;

    #endregion --- Generic setup ---

    local procedure Patch_260618()
    var
        A: Record Assignment;
        ALE: Record "Assignment Ledger Entry";
        ALES: Record "Assignment Ledger Entry Status";
        Input: Page "Request Input";
        Progress: Codeunit "Progress Dialog Box";
        DateFilter: Text;
    begin
        Input.SetParameter('Enter Date Filter');
        Input.RunModal();
        Input.GetValue(DateFilter);

        if DateFilter <> '' then begin
            ALE.SetCurrentKey("Entry Type", "Posting Date");
            ALE.SetRange("Entry Type", ALE."Entry Type"::Origin);
            ALE.SetFilter("Posting Date", DateFilter);
        end;
        ALE.FindSet();

        Progress.Open('Updating Assignment Ledger Entries... @1@@@@@', ALE.CountApprox);

        repeat
            Progress.Increase(1);

            if A.Get(ALE."Assignment No.") then begin
                if A."Subcontractor Vendor No." = '' then
                    ALE."Pay-to Vendor Type" := ALE."Pay-to Vendor Type"::Employee
                else
                    ALE."Pay-to Vendor Type" := ALE."Pay-to Vendor Type"::Subcontractor;
                ALE.SuppressStatusUpdate();
                ALE.Modify();

                if ALES.FindRecords(ALE, false) then
                    repeat
                        ALES."Pay-to Vendor Type" := ALE."Pay-to Vendor Type";
                        ALES.Modify();
                    until ALES.Next() = 0;
            end;
        until ALE.Next() = 0;

        Progress.Close(1);
    end;

    local procedure Patch_260603()
    var
        TimeSheetHeader: Record "Time Sheet Header (Work.4s)";
        TimeSheetLine: Record "Time Sheet Line (Work.4s)";
        PostedTimeSheetHeader: Record "Posted Time Sheet Header";
    begin
        TimeSheetHeader.Get('BIS-TS-2605-0063');
        TimeSheetHeader.Status := TimeSheetHeader.Status::"Pending Approval";
        TimeSheetHeader.Modify();
        TimeSheetLine.SetRange("Time Sheet No.", 'BIS-TS-2605-0063');
        if TimeSheetLine.FindSet() then
            repeat
                TimeSheetLine.Status := TimeSheetLine.Status::"Pending Approval";
                TimeSheetLine.Modify();
            until TimeSheetLine.Next() = 0;

        PostedTimeSheetHeader.Get('BIS-TS-2605-0063');
        PostedTimeSheetHeader.AllowDeletion(true);
        PostedTimeSheetHeader.Delete(true);
    end;

    local procedure Patch_260401()
    var
        Co: Record Company;
        TSL: Record "Time Sheet Line (Work.4s)";
        PTSL: Record "Posted Time Sheet Line";
    begin
        Co.FindSet();
        repeat
            TSL.ChangeCompany(Co.Name);
            PTSL.ChangeCompany(Co.Name);

            if TSL.FindSet() then
                repeat
                    if TSL."Time Calendar Code" = '' then begin
                        TSL."Time Calendar Code" := TSL."Calendar Code";
                        TSL."Time Period Starting Date" := TSL."Calendar Period Starting Date";
                        TSL.Modify();
                    end
                until TSL.Next() = 0;

            if PTSL.FindSet() then
                repeat
                    if PTSL."Time Calendar Code" = '' then begin
                        PTSL."Time Calendar Code" := PTSL."Calendar Code";
                        PTSL."Time Period Starting Date" := PTSL."Calendar Period Starting Date";
                        PTSL.Modify();
                    end
                until PTSL.Next() = 0;
        until Co.Next() = 0;
    end;

    local procedure Patch_260213()
    var
        AssignmentCalendar: Record "Assignment Calendar";
    begin
        AssignmentCalendar.SetRange("Calendar Type", AssignmentCalendar."Calendar Type"::"Time Entries");
        AssignmentCalendar.DeleteAll();
    end;

    local procedure Patch_260207()
    var
        Company: Record Company;
        AssignmentRate: Record "Assignment Rate";
        AssignmentLedgStatus: Record "Assignment Ledger Entry Status";
    begin
        Company.SetFilter(Name, '%1|%2|%3', '142 BRU CN BEQ', '146 BRU CN BEN', '165 BRU CN BTJ');
        Company.FindSet();
        repeat
            AssignmentRate.ChangeCompany(Company.Name);
            AssignmentLedgStatus.ChangeCompany(Company.Name);

            AssignmentRate.SetRange("Rate Code", '41900');
            AssignmentRate.FindSet();
            repeat
                AssignmentRate.TestField("Rate Code", '41900');
                AssignmentRate.Validate("Cost Accrual Noncancelable", true);
                AssignmentRate.Modify();

                AssignmentLedgStatus.SetRange("Rate Code", AssignmentRate."Rate Code");
                if AssignmentLedgStatus.FindSet() then
                    repeat
                        AssignmentLedgStatus.TestField("Rate Code", '41900');
                        AssignmentLedgStatus."Cost Accrual Noncancelable" := true;
                        AssignmentLedgStatus.Modify();
                    until AssignmentLedgStatus.Next() = 0;
            until AssignmentRate.Next() = 0;
        until Company.Next() = 0;
    end;

    local procedure Patch_251007()
    var
        CostCurrency: Record Currency;
        PriceCurrency: Record Currency;
        SalesInvLine: Record "Sales Invoice Line";
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        Progress.Open(
            'Patching... ' +
            '\@1@@@@@ \\Sales Invoice No. #2########## \Sales Invoice Line No. #3##### \' +
            '\@4@@@@@ \\Purch. Invoice No. #5########## \Purch. Invoice Line No. #6##### \');

        SalesInvLine.SetRange(Type, SalesInvLine.Type::"G/L Account");
        SalesInvLine.SetFilter("No.", '<>%1', '');
        SalesInvLine.SetFilter("Assignment No.", '<>%1', '');
        SalesInvLine.SetFilter("Rate Code", '<>%1', '');
        SalesInvLine.FindSet();
        Progress.Initialize(1, SalesInvLine.Count);
        repeat
            Progress.Increase(1);
            Progress.Update(2, SalesInvLine."Document No.");
            Progress.Update(3, Format(SalesInvLine."Line No."));

            if SalesInvLine."Cost Quantity" = 0 then begin
                SalesInvLine."Cost Unit of Measure Code" := '';
                SalesInvLine."Cost/Price UOM Conv. Factor" := 0;
                SalesInvLine."Cost Currency Code" := '';
                SalesInvLine."Cost Currency Factor" := 0;
                SalesInvLine."Cost/Price Currency Factor" := 0;
                SalesInvLine."Unit Cost" := 0;
                SalesInvLine."Cost Excl. Disc." := 0;
                SalesInvLine."Cost Discount" := 0;
                SalesInvLine."Total Cost" := 0;
                SalesInvLine."Unit Cost (LCY)" := 0;
                SalesInvLine."Cost Excl. Disc. (LCY)" := 0;
                SalesInvLine."Cost Discount (LCY)" := 0;
                SalesInvLine."Total Cost (LCY)" := 0;
                SalesInvLine.Modify();
            end else if (SalesInvLine."Cost Excl. Disc." = 0) and (SalesInvLine."Unit Cost" <> 0) then begin
                CostCurrency.Initialize(SalesInvLine."Cost Currency Code");
                SalesInvLine."Cost Excl. Disc." := CostCurrency.RoundAmount(SalesInvLine."Cost Quantity" * SalesInvLine."Unit Cost");
                SalesInvLine."Total Cost" := SalesInvLine."Cost Excl. Disc." - SalesInvLine."Cost Discount";
                SalesInvLine.Modify();
            end;
        until SalesInvLine.Next() = 0;

        Progress.Complete(1);

        PurchInvLine.SetRange(Type, PurchInvLine.Type::"G/L Account");
        PurchInvLine.SetFilter("No.", '<>%1', '');
        PurchInvLine.SetFilter("Assignment No.", '<>%1', '');
        PurchInvLine.SetFilter("Rate Code", '<>%1', '');
        PurchInvLine.FindSet();
        Progress.Initialize(4, PurchInvLine.Count);
        repeat
            Progress.Increase(4);
            Progress.Update(5, PurchInvLine."Document No.");
            Progress.Update(6, Format(PurchInvLine."Line No."));

            if PurchInvLine."Price Quantity" = 0 then begin
                PurchInvLine."Price Unit of Measure Code" := '';
                PurchInvLine."Cost/Price UOM Conv. Factor" := 0;
                PurchInvLine."Price Currency Code" := '';
                PurchInvLine."Price Currency Factor" := 0;
                PurchInvLine."Cost/Price Currency Factor" := 0;
                PurchInvLine."Unit Price" := 0;
                PurchInvLine."Price Excl. Disc." := 0;
                PurchInvLine."Price Discount" := 0;
                PurchInvLine."Total Price" := 0;
                PurchInvLine."Unit Price (LCY)" := 0;
                PurchInvLine."Price Excl. Disc. (LCY)" := 0;
                PurchInvLine."Price Discount (LCY)" := 0;
                PurchInvLine."Total Price (LCY)" := 0;
                PurchInvLine.Modify();
            end else if (PurchInvLine."Price Excl. Disc." = 0) and (PurchInvLine."Unit Price" <> 0) then begin
                PriceCurrency.Initialize(PurchInvLine."Price Currency Code");
                PurchInvLine."Price Excl. Disc." := PriceCurrency.RoundAmount(PurchInvLine."Price Quantity" * PurchInvLine."Unit Price");
                PurchInvLine."Total Price" := PurchInvLine."Price Excl. Disc." - PurchInvLine."Price Discount";
                PurchInvLine.Modify();
            end;
        until PurchInvLine.Next() = 0;

        Progress.Complete(4);
    end;

    local procedure Patch_251002()
    var
        ARR: Record "Assignment Rate Relation";
    begin
        ARR.SetRange(Level, 1);
        ARR.FindSet();
        repeat
            if ARR."Parent Line No." = 0 then begin
                ARR.Validate("Parent Line No.", 10000);
                ARR.Modify(true);
            end;
        until ARR.Next() = 0;
    end;

    local procedure Patch_251001()
    var
        ALE: Record "Assignment Ledger Entry";
    begin
        ALE.SetCurrentKey("Document No.");
        case CompanyName of
            '023 BRU SG BISEA':
                ALE.SetRange("Document No.", 'OPEN_ASGN_AUG25');  // BISEA
            '100 BRU JP BEJKK':
                ALE.SetRange("Document No.", 'OPEN_ASG_JUL25');  // BEJKK
            '160 BRU TW Taiwan':
                ALE.SetRange("Document No.", 'OPEN_ASGN_JUL25');  // BTW
            else
                Error('Company not allowed to run this patch.');
        end;
        ALE.FindSet();
        repeat
            ALE."Auto-adjustment Blocked" := true;
            ALE.Modify();
        until ALE.Next() = 0;
    end;

    local procedure Patch_250930()
    var
        SalesInvLine: Record "Sales Invoice Line";
    begin
        // SalesInvLine.Get('BVC-SIP-2509-0001', 80000);

        SalesInvLine.Get('BIS-SIP-2509-0089', 90000);
        SalesInvLine."Cost Excl. Disc." := SalesInvLine."Cost Excl. Disc. (LCY)";
        SalesInvLine."Total Cost" := SalesInvLine."Total Cost (LCY)";
        SalesInvLine.Modify();

        SalesInvLine.Get('BIS-SIP-2509-0089', 110000);
        SalesInvLine."Cost Excl. Disc." := SalesInvLine."Cost Excl. Disc. (LCY)";
        SalesInvLine."Total Cost" := SalesInvLine."Total Cost (LCY)";
        SalesInvLine.Modify();
    end;
}
