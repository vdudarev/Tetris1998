Program proba;
Uses Graph, Crt, Menu;

VAR
   TripFont, BoldFont: Integer; { Переменные указывающие на номер шрифтов }

Procedure VgaDriver; External;
{$L EGAVGA.OBJ }

Procedure TriplexFontDriver; External;
{$L TRIP.OBJ }

Procedure BoldRFontDriver; External;
{$L BOLDR.OBJ }

Procedure GRAPHICS (Var Success: Boolean);
Var
   GrDriver, GrMode, ErrorCode: Integer;
Begin
   TripFont:= RegisterBGIfont (@TriplexFontDriver);
   BoldFont:= RegisterBGIfont (@BoldRFontDriver);
   GrDriver:= VGA;
   GrMode:= VGAHi;
   if (TripFont<0) or (BoldFont<0) or (RegisterBGIDriver(@VgaDriver)<0) then
      begin
         Success:= FALSE;
         Writeln('Графический драйвер или фонт не подключен');
      end
   else
      begin
         InitGraph (GrDriver, GrMode, '');
         ErrorCode:=GraphResult;
         if ErrorCode<>GrOk then
            begin
               writeln('Graphics error:',GraphErrorMsg(ErrorCode));
               Success:= False;
            end
         else
            Success:= True;
      end;
End; { GRAPHICS }

Var
   Suc: Boolean;
   M: TMenu;
   i: Byte;

BEGIN
   Graphics (Suc);
   M.Init_Menu;
   If Suc then
      begin
         M.ADD_MENU ('QAZXSW', Suc);
         M.ADD_MENU ('DFGHGHFHGHHGhgh', Suc);
         M.ADD_MENU ('rtyrtyryhfgh', Suc);
         M.ADD_MENU ('fghgjhkjhkh', Suc);
{Function CHOICE_MENU (Vertical: Boolean; XC, YC: Integer; Var M: TMenu;
      NormalFore, NormalBack, SelectedFore, SelectedBack: Word): Byte;}
      Repeat
         i:= M.CHOICE_MENU (not True, 320, 240, Blue, LightBlue, White, Green);

      Until i=1;



      end;


   CloseGraph;
   Writeln (i);
   M.Destroy_Menu;

END.
