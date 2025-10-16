codeunit 85999 "Data Patching (Hadi)"
{
    Permissions = tabledata "Sales Invoice Line" = rm;

    trigger OnRun()
    begin
        // Test
        Clear(Progress);

        Patch_251007();

        Progress.Close();
        Message('Patch is completed.');
    end;

    var
        Progress: Codeunit "Progress Dialog Box";

    local procedure Patch_251007()
    var
        CostCurrency: Record Currency;
        SalesInvLine: Record "Sales Invoice Line";
    begin
        Progress.Open('Patching... \@1@@@@@ \\Document No. #2########## \Line No. #3#####');

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
                SalesInvLine."Cost Excl. Disc." := CostCurrency.RoundAmount(SalesInvLine.Quantity * SalesInvLine."Unit Cost");
                SalesInvLine."Total Cost" := SalesInvLine."Cost Excl. Disc." - SalesInvLine."Cost Discount";
                SalesInvLine.Modify();
            end;
        until SalesInvLine.Next() = 0;
        Progress.Complete(1);
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
