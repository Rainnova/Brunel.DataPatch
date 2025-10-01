codeunit 85999 "Data Patching (Hadi)"
{
    Permissions = tabledata "Sales Invoice Line" = rm;

    trigger OnRun()
    begin
        Patch_251001();
    end;

    local procedure Patch_251001()
    var
        ALE: Record "Assignment Ledger Entry";
    begin
        ALE.SetCurrentKey("Document No.");
        ALE.SetRange("Document No.", 'OPEN_ASGN_AUG25');
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
