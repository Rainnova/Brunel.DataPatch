codeunit 85999 "Data Patching (Hadi)"
{
    Permissions = tabledata "Sales Invoice Line" = rm;

    trigger OnRun()
    begin
        Patch_251002();
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
        SalesInvLine.Get('BVC-SIP-2509-0001', 80000);
        SalesInvLine."Cost Excl. Disc." := SalesInvLine."Cost Excl. Disc. (LCY)";
        SalesInvLine."Total Cost" := SalesInvLine."Total Cost (LCY)";
        SalesInvLine.Modify();
    end;
}
