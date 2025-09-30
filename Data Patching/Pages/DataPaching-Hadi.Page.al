page 85999 "Data Patching (Hadi)"
{
    ApplicationArea = All;
    Caption = 'Data Patching';
    PageType = List;
    UsageCategory = Tasks;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field(ClickPatch; 'Click "Patch" to start the data patching.')
                {
                    ShowCaption = false;
                    Editable = false;
                    QuickEntry = false;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action("Patch")
            {
                ApplicationArea = All;
                Caption = '&Patch';
                Image = ExecuteBatch;

                trigger OnAction()
                begin
                    Codeunit.Run(Codeunit::"Data Patching (Hadi)");
                    Message('Data patching completed.');
                end;
            }
        }
        area(Promoted)
        {
            actionref(Patch_Promoted; Patch) { }
        }
    }
}
