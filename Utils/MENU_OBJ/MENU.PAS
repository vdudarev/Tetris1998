Unit Menu;
                                 INTERFACE
Uses GRAPH, CRT;
CONST
   KbLeft = #75; { Коды клавиш управления }
   KbRight = #77;
   KbUp = #72;
   KbDown = #80;
   KbEnter = #13;
   KbEscape = #27;
   KbBackSpace = #8;
   KbF1 = #59;

   ScoreFile = 'Records.dat';
   FigFile = 'Figures.dat';
   MaxX = 12;
   MaxY = 19;
   XN = 540;
   YN = 200;
   XS = 500;
   YS = 80;
   X0 = 50;
   Y0 = 50;
   Sst = 25;
   TimeStep0 = 80; { Начальное время шага фигуры (в мс) }
   LevelTimeStep = 10; { Уменьшение времени шага с переходом на новый уровень }
   LevelLines = 10; { Число линий, которое необходимо удалить для
                     перехода на новый уровень }
   Tmp = 15; { Служебная константа. Для  }
   Item = 20;

CONST
   StepHor = 50; { "растояние" между кнопками в горизонтальном меню }
   StepVer = 30; { "растояние" между кнопками в вертикальном меню }
   Width = 5;                { "толщина каймы" кнопки }
   Shad = 5;                 { "глубина" тени }
   ShadowColor = DarkGray;   { Цвет тени }
   FillPattern = SolidFill;  { Шаблон заполнения }

TYPE
   Name = String[21]; { No comments... }

   PTL = ^TList;
   TList = Record
      Title: Name;
      Prev, Next: PTL;
      Number: Byte;
      X, Y: Integer;
   End;

   PTMenu = ^TMenu;
   TMenu = Object
      Head, Tail, Cur: PTL;
      N: Byte;
      Constructor INIT_MENU;
      Destructor DESTROY_MENU;
      Procedure ADD_MENU (NewName: Name; Var Suc: Boolean);
      Function CHOICE_MENU (Vertical: Boolean; XC, YC: Integer;
      NormalFore, NormalBack, SelectedFore, SelectedBack: Word): Byte;
   End;

                               IMPLEMENTATION

Constructor TMenu.INIT_MENU;
Begin
   Head:= nil;
   Tail:= nil;
   Cur:= nil;
   N:=0;
End; { INIT_MENU }

Destructor TMenu.DESTROY_MENU;
Var
   Current, Next: PTL;
   TheEnd: Boolean;
Begin
   TheEnd:= Head = nil;
   Current:= Head;
   While Not TheEnd do
      begin
         TheEnd:= Current^.Number = N;
         Next:= Current^.Next;
         Dispose (Current);
         Current:= Next;
      end;
   INIT_MENU;
End; { DESTROY_MENU }

Procedure TMenu.ADD_MENU (NewName: Name; Var Suc: Boolean);
Var
   P: PTL;
Begin
   New (P);
   if P <> nil then
      begin
         Suc:= TRUE;
         Inc (N);
         if Head = nil then { Список пока пуст }
            begin
               Head:= P;
               Tail:= P;
            end;
         Head^.Prev:= P;
         Tail^.Next:= P;

         P^.Title:= NewName;
         P^.Number:= N;
         P^.Next:= Head;
         P^.Prev:= Tail;
         Tail:= P;
      end
   else
      Suc:= FALSE;
End; { ADD_MENU }

Function TMenu.CHOICE_MENU (Vertical: Boolean; XC, YC: Integer;
      NormalFore, NormalBack, SelectedFore, SelectedBack: Word): Byte;
Var
   Ch, Scan: Char;
   NSelected: Byte;

   Procedure SetCoordinates;
   { Возвращает значение отступа от (XC,YC) при начале рисования }
   Var
      Z, X, Y: Integer;
      P: PTL;
      TheEnd: Boolean;
   Begin
      if N > 1 then begin
         Z:=0;
         TheEnd:= Not (Head <> nil);
         P:= Head;
         While Not TheEnd do
            begin
               if Vertical then
                  Inc (Z, TextHeight (P^.Title))
               else
                  Inc (Z, TextWidth ('  '+P^.Title));
               TheEnd:= P^.Number = N;
               P:= P^.Next;
            end;
         if Vertical then
            begin
               Inc (Z, (N-1)*StepVer);
               Dec (Z, (TextHeight (Head^.Title) + TextHeight (Tail^.Title)) div 2);
               Y:= YC-(Z div 2);
               X:= XC;
            end
         else
            begin
               Inc (Z, (N-1)*StepHor);
               Dec (Z, (TextWidth (Head^.Title) + TextWidth (Tail^.Title)) div 2);
               X:= XC-(Z div 2);
               Y:= YC;
            end;

         P^.X:= X;
         P^.Y:= Y;
         P:= Head^.Next;
         TheEnd:= Not (Head <> nil);
         While Not TheEnd do
            begin
               if Vertical then
                  begin
                     Inc (Y, (TextHeight (P^.Title) + TextHeight (P^.Prev^.Title)) div 2 + StepVer);
                     P^.X:= X;
                     P^.Y:= Y;
                  end
               else
                  begin
                     Inc (X, (TextWidth ('  '+P^.Title) + TextWidth (P^.Prev^.Title)) div 2 + StepHor);
                     P^.X:= X;
                     P^.Y:= Y;
                  end;
               TheEnd:= P^.Number = N;
               P:= P^.Next;
            end;
         end
      else
         begin
            Head^.X:= XC;
            Head^.Y:= YC;
         end;
   End; { SetCoordinates }

   Procedure DrawItem (Cur: PTL; IsSelected: Boolean);
   { Рисует на экране пункт меню }
   Var
      XS, YS: Integer;
   Begin
      XS:=TextWidth (' '+Cur^.Title+' ') div 2;
      YS:=TextHeight (Cur^.Title) div 2;
      SetFillStyle (FillPattern, ShadowColor);
      Bar (Cur^.X-Width+Shad-XS, Cur^.Y-Width+Shad-YS, Cur^.X+XS+Width+Shad, Cur^.Y+YS+Width+Shad);
      if IsSelected then
         begin
            SetColor (SelectedFore);
            SetFillStyle (FillPattern, SelectedBack);
         end
      else
         begin
            SetColor (NormalFore);
            SetFillStyle (FillPattern, NormalBack);
         end;
      Bar (Cur^.X-Width-XS, Cur^.Y-Width-YS, Cur^.X+XS+Width, Cur^.Y+YS+Width);
      OutTextXY (Cur^.X, Cur^.Y, ' '+Cur^.Title+' ');
   End; { DrawItem }

   Procedure DrawMenu (Sel: PTL);
   { Рисует на экране меню }
   Var
      P: PTL;
      TheEnd: Boolean;
   Begin
      TheEnd:= Not (Head <> nil);
      P:= Head;

      While Not TheEnd do
         begin
            if Sel = P then
               DrawItem (P, True)
            else
               DrawItem (P, False);
            TheEnd:= P^.Number = N;
            P:= P^.Next;
         end;
   End; { DrawMenu }

Begin { CHOICE_MENU }
   SetTextJustify (CenterText, CenterText);
   SetCoordinates;
   if Cur = nil then
      Cur:= Head;
   NSelected:= Cur^.Number;
   DrawMenu (Cur);
   Repeat
      Ch:= ReadKey;
      if Ch = #0 then
         begin
            Scan:= ReadKey;
            Case Scan Of
               KbLeft, KbUp: begin
                     DrawItem (Cur, FALSE);
                     Cur:= Cur^.Prev;
                     NSelected:= Cur^.Number;
                     DrawItem (Cur, TRUE);
                  end;
               KbRight, KbDown: begin
                     DrawItem (Cur, FALSE);
                     Cur:= Cur^.Next;
                     NSelected:= Cur^.Number;
                     DrawItem (Cur, TRUE);
                  end;
               {KbF1: begin
                     HELP_SCREEN;
                     SetTextJustify (1,1);
                     SetTextStyle (TripFont, 0, 1);
                  end;}
            End; { Case }
         end; { if ch...}
   Until Ch = KbEnter;
   Choice_Menu:= NSelected;
End; { CHOICE_MENU }

END.
