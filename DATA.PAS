Unit Data;
                                 INTERFACE
Uses Graph;
CONST
   KbLeft = #75; { Коды клавиш управления }
   KbRight = #77;
   KbUp = #72;
   KbDown = #80;
   KbEnter = #13;
   KbEscape = #27;
   KbBackSpace = #8;
   KbF1 = #59;

   ScoreFile = 'Records.dat'; { Имена внешних файлов }
   FigFile = 'Figures.dat';
   MaxX = 12; { размер стакана }
   MaxY = 19;
   XN = 540; { служебные константы, }
   YN = 200; { характеризующие расположение }
   XS = 500; { рисунков относительно экрана }
   YS = 80;
   X0 = 50;
   Y0 = 50;
   Sst = 25;
   TimeStep0 = 80; { Начальное время шага фигуры (в мс) }
   LevelTimeStep = 10; { Уменьшение времени шага с переходом на новый уровень }
   LevelLines = 20; { Число линий, которое необходимо удалить
                      для перехода на новый уровень }
   Tmp = 15;  { Служебная константа }
   Item = 20; { Размерность элемента фигуры на экране }
                         { Константы для меню }
   StepHor = 100; { "растояние" между кнопками в горизонтальном меню }
   StepVer = 30; { "растояние" между кнопками в вертикальном меню }
   Width = 5;                { "толщина каймы" кнопки }
   Shad = 5;                 { "глубина" тени }
   ShadowColor = DarkGray;   { Цвет тени }
   FillPattern = SolidFill;  { Шаблон заполнения }

TYPE
   Name = String[21];
   PTL = ^TList;
   TList = Record { Тип элемента меню }
      Title: Name; { заглавие }
      Prev, Next: PTL; { ссылки на соседние элементы }
      Number: Byte; { номер опции }
      X, Y: Integer; { координаты кнопки относительно экрана }
   End;

   TMenu = Object { Объект меню }
      Head, Tail, Cur: PTL; { указатели на "голову", "хвост" и активную опцию }
      N: Byte; { число элементов в меню }
      Constructor INIT_MENU; { Создает пустое меню }
      Destructor DESTROY_MENU; { Уничтожает меню с освобождением памяти }
      Procedure ADD_MENU (NewName: Name; Var Suc: Boolean);
       { Добавляет опцию с именем NewName в меню и присваивает ей следующий по
         счету номер. Результат:  Suc = TRUE - добаление успешно, иначе - нет }
      Function CHOICE_MENU (Vertical: Boolean; XC, YC: Integer;
      NormalFore, NormalBack, SelectedFore, SelectedBack: Word): Byte;
       { Рисует на экране меню и позволяет осуществить выбор опции используя клавиши
         управления курсором и Enter. Возвращаемое число является номером соответст-
         вующего пункта меню. Параметры:
         Vertical = TRUE - Рисуется вертикальное меню, иначе - горизонтальное.
         (XC, YC) - Координаты точки, являющейся центром меню.
         Остальные параметры являются цветами букв в неактивной опции, фона в неактивной
         опции, букв в активной опции и фона в активной опции соответственно. }
   End;

   Field = Array [-2..MaxX+3,1..MaxY+3] Of Boolean; { Тип массива стакана }

   Mas = Array [1..4] Of String[4]; { Образ фигуры }
   Figure = Record { Тип определяющий 1 игровую фигуру }
      Color: Byte; { Цвет фигуры }
      Image: Mas; { Образ фигуры }
   End;
   Figures = Array [0..Tmp+1] Of Figure; { Тип массива игровых фигур }

   Stroka = String[20];
   Records = Record { Тип лучшие результаты }
      WinnerText: Stroka; { Текст победителя }
      Name: Array [1..10] Of Stroka; { Имена лучших игроков }
      Sc: Array [1..10] Of Word; { Результаты лучших игроков }
   End;

VAR
   TripFont, BoldFont: Integer; { Переменные указывающие на номер шрифтов }
   P: Pointer; { Служебный указатель }
   Ch: Char; { Для чтения с клавиатуры }
   Rec: Records; { Тип лучшие результаты }
   Buf: Text; { Файловая переменная }
   St: String; { Служебная переменная }
   NumFig, i,j, Cur, Next, X,Y, CurLines, Level: ShortInt;
   Fig: Figures; { Информация об игровых фигурах }
   A: Field; { Массив стакана }
   GrSuc, EndOfGame, Drop, NextFig, Exit: Boolean;
   Hour, Min, Sec, Sec100, Score, Lines, TimeStep, Size: Word;
   Code: Integer;
   M: TMenu; { Меню }
                               IMPLEMENTATION
Uses My_Adds, Crt;

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
      begin { Добавляем опцию }
         Suc:= TRUE;
         Inc (N);
         if Head = nil then { Список пока пуст }
            begin
               Head:= P;
               Tail:= P;
            end;
         Head^.Prev:= P;
         Tail^.Next:= P;
         { Заполнение полей в новой опции }
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
         While Not TheEnd do { подсчет высоты или ширины текста всех опций меню }
            begin
               if Vertical then
                  Inc (Z, TextHeight (P^.Title))
               else
                  Inc (Z, TextWidth ('  '+P^.Title));
               TheEnd:= P^.Number = N;
               P:= P^.Next;
            end;
         { Учет всех интервалов между кнопками }
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
         { "Привязывание" каждой кнопки к ее координатам на экране }
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
         begin { Установка цветов для активной кнопки }
            SetColor (SelectedFore);
            SetFillStyle (FillPattern, SelectedBack);
         end
      else
         begin { Установка цветов для неактивной кнопки }
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
               KbLeft, KbUp: begin { Установка предыдущего пункта меню активным }
                     DrawItem (Cur, FALSE);
                     Cur:= Cur^.Prev;
                     NSelected:= Cur^.Number;
                     DrawItem (Cur, TRUE);
                  end;
               KbRight, KbDown: begin { Установка следущего пункта меню активным }
                     DrawItem (Cur, FALSE);
                     Cur:= Cur^.Next;
                     NSelected:= Cur^.Number;
                     DrawItem (Cur, TRUE);
                  end;
            End; { Case }
         end; { if ch...}
   Until Ch = KbEnter;
   Choice_Menu:= NSelected;
End; { CHOICE_MENU }

END.
