codeunit 85999 "Data Patching (Hadi)"
{
    Permissions = tabledata "Sales Invoice Line" = rm;

    trigger OnRun()
    begin
        Patch_250930();
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
