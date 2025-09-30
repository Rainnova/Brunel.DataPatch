codeunit 85998 "BZ Development Tools Events"
{
    var
        DeveloperTools: Page "Developer Tools";


    local procedure DataPatchingID(): Integer
    begin
        exit(85999);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Developer Tools", OnAfterPopulateToolList, '', false, false)]
    local procedure DeveloperTools_OnAfterPopulateToolList(var Rec: Record "CSV Buffer" temporary)
    begin
        DeveloperTools.AddTool(Rec, DataPatchingID(), 'Execute data patching procedure (by Hadi)');
    end;

    [EventSubscriber(ObjectType::Page, Page::"Developer Tools", OnAfterLaunchTools, '', false, false)]
    local procedure DeveloperTools_OnAfterLaunchTools(var Rec: Record "CSV Buffer" temporary)
    begin
        case Rec."Line No." of
            DataPatchingID():
                Page.RunModal(Page::"Data Patching (Hadi)");
        end;
    end;

}
