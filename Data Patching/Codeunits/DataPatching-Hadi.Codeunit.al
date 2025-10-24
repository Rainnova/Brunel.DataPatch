codeunit 85999 "Data Patching (Hadi)"
{
    Permissions = tabledata "Sales Invoice Line" = rm,
                  tabledata "Purch. Inv. Line" = rm;

    trigger OnRun()
    begin
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
