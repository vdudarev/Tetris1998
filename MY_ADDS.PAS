Unit My_adds;
                                 INTERFACE
Uses Data;

Procedure GAME;
{ Фактически сама игра }
Function EDIT_LINE (X0, Y0, Font, FontSize: Integer; MaxNum: Byte): String;
{ Функция возвращает строку длинной максимум в MaxNum символов.
  (X0,Y0) - Координата левого верхнего угла строки редактирования.
  Font - Шрифт;   FontSize - Размер шрифта }
Procedure FIRST_PICTURE;
{ Рисование заставки к игре }
Procedure VGADRIVER;
{ Драйвер графического режима }
Procedure TRIPLEXFONTDRIVER;
{ Драйвер шрифта Triplex }
Procedure BOLDRFONTDRIVER;
{ Драйвер шрифта Bold }
Procedure GRAPHICS (Var Success: Boolean);
{ Процедура установки графического режима и подключение шрифтов
  Success = TRUE - установка графики успешна }
Procedure HELP_SCREEN;
{ Рисует экран помощи с сохранением области экрана занятого им }
Procedure BEST_RESULTS;
{ Процедура вывода на экран таблицы лучших результатов
  с сохранением области экрана занятого ей }
Procedure INIT_GAME;
{ Прорисовка экрана и установка начальных параметров }
Procedure PAUSE;
{ Рисует сообщение о паузе на экране с
  сохранением области экрана занятого им }
Procedure ESCAPE;
{ Процедура отображения меню выхода из текущей игры с формированием значения
  переменной EndOfGame }
Procedure QUIT;
{ Процедура отображения меню выхода из игры с формированием значения
  переменной Exit }
Procedure KEY;
{ Процедура паузы до нажатия клаваши }
Procedure ACTIONS_WITH_FIGURE;
{ Действия с фигурой }
Procedure ROTATE;
{ Процедура поворота матрицы фигуры }
Procedure CUT;
{ "Вырезает" фигуру из массива стакана }
Procedure PASTE;
{ Процедура "вставки" фигуры в массив стакана }
Function CANPUT (F: Mas; X, Y:ShortInt): Boolean;
{ True = можно вставить фигуру F в массив стакана A по координатам (X,Y)
  без наложения на другие фигуры }
Procedure PUT_FIGURE;
{ Процедура вставки фигуры в массив стакана A и ее прорисовки на экране }
Procedure REMOVE_FIGURE;
{ Процедура удаления фигуры из массива стакана A и с экрана }
Function HIGH_TIME: Boolean;
{ TRUE = Пора отпустить фигуру на одну позицию вниз }
Procedure ANALYSE;
{ Анализирует заполнились ли какие-либо горизонтальные ряды в массиве стакана,
  если да, то убирает их по правилам Tetris'а и увеличивает очки, число линий и
  может быть уровень сложности. }
Procedure SHOW_NEXT;
{ Показывает следующую фигуру в соответствующем окне }
Procedure UPDATE_RESULTS;
{ Заносит данные об игроке в таблицу лучших результатов, если игрок его
  (хороший результат) показал }

                               IMPLEMENTATION
USES Crt, Graph, Dos;

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
   TripFont:= RegisterBGIfont (@TriplexFontDriver); { Регистрация шрифтов }
   BoldFont:= RegisterBGIfont (@BoldRFontDriver);
   GrDriver:= VGA; { Задание параметров графического режима }
   GrMode:= VGAHi;
   if (TripFont<0) or (BoldFont<0) or (RegisterBGIDriver(@VgaDriver)<0) then
      begin
         Success:= FALSE;
         Writeln('Графический драйвер или фонт не подключен');
      end
   else
      begin
         InitGraph (GrDriver, GrMode, ''); { Попытка инициализации графики }
         ErrorCode:= GraphResult;
         if ErrorCode <> GrOk then
            begin
               writeln ('Ошибка графики:',GraphErrorMsg(ErrorCode));
               Success:= FALSE;
            end
         else
            Success:= True;
      end;
End; { GRAPHICS }

Function EDIT_LINE (X0, Y0, Font, FontSize: Integer; MaxNum: Byte): String;
Const
   Width = 5; { "толщина каймы" поля ввода }
Type
   PTList = ^TList;
   TList = Record { Тип элемента списка }
      Ch: Char;
      Next, Prev: PTList;
   end;
Var
   W: String;
   Len: Byte; { Длинна строки }
   Cur, P, Head, Tail: PTList;
   Ch: Char;

   Procedure View;
   { Выводит на экран строку редактирования }
   Var
      X: Integer;
   Begin
      Bar (X0-Width, Y0-Width, X0+(MaxNum+1)*TextWidth('W')+Width, Y0+Width+TextHeight('W'));
      P:= Head;
      X:= X0;
      While P <> nil do
         begin
            OutTextXY (X, Y0, P^.Ch);
            Inc (X, TextWidth(P^.Ch));
            P:= P^.Next;
         end;
      OutTextXY (X, Y0, '_');
   End; { View }
Begin
   SetTextJustify (LeftText, TopText);
   SetTextStyle (Font, 0, FontSize);
   SetFillStyle (SolidFill, GetBkColor);
   W:= '';
   Len:= 0;
   Cur:= nil;
   Head:= nil;
   Tail:= nil;
   View;
   Repeat { Редактирование }
      Ch:= ReadKey;
      if Ch <> #0 then
         Case Ch of
            ' '..'п',
            'р'..'ё': if Len < MaxNum then
                         begin { Включаем символ в список }
                            Inc (Len);
                            New (P);
                            P^.Ch:=Ch;
                            P^.Next:= nil;
                            if Head = nil then
                               Head:=P
                            else
                               begin
                                  P^.Prev:= Tail;
                                  Tail^.Next:= P;
                               end;
                            Tail:= P;
                            Cur:= P;
                            View;
                         end;
            KbBackSpace:
                if Len > 0  then
                   begin { Удаляем символ из списка }
                      Dec (Len);
                      P:= Tail;
                      Tail^.Prev^.Next:= nil;
                      Tail:= Tail^.Prev;
                      Dispose (P);
                      if Len = 0 then
                         Head:= nil;
                      View;
                   end;
         end
      else
         Ch:= ReadKey;
   Until Ch = KbEnter;
   P:= Head; { Формируем строку из имеющегося списка букв }
   While P <> nil do
      begin
         w:= w+P^.Ch;
         P:= P^.Next;
      end;
   Edit_Line:= W;
End; { EDIT_LINE }

Procedure FIRST_PICTURE;
Begin
   SetColor(Yellow);
   SetBkColor (DarkGray);
   SetTextStyle (TripFont, 0, 16);
   OutTextXY (10,0, 'TETRIS');
   SetColor (White);
   { Стакан }
   SetLineStyle (0,0, 0);
   Ellipse (450, 150, 0,360, 90, 20);
   Ellipse (450, 400, 0,360, 60, 15);
   Line (360, 150, 390, 400);
   Line (540, 150, 510, 400);
   { Broken Figure }
   SetLineStyle (0,0,ThickWidth);
   MoveTo (384, 356);
   LineTo (443, 415);
   LineRel (40,-40);
   LineRel (-20,-20);
   LineRel (-20,20);
   LineRel (-40,-40);
   LineRel (-20,20);
   SetLineStyle (0,0,NormWidth);
   LineRel (30,-30);
   LineRel (40,40);
   LineRel (20,-20);
   LineRel (20,20);
   LineRel (-10,10);
   SetFillStyle (6, LightGreen);
   FloodFill (440,400 ,White);
   FloodFill (440,380, White);
   SetFillStyle (6, LightBlue);
   FloodFill (430, 360, White);
   FloodFill (470, 360, White);
   { Мордашка }
   SetFillStyle (SolidFill,Green);
   FillEllipse (480, 250, 30,30);
   SetFillStyle (1, Red);
   FillEllipse (465, 240, 6,4);
   FillEllipse (495, 240, 6,4);
   FillEllipse (480, 265, 15,10); { Рот }
   SetFillStyle (1, White);
   FillEllipse (570, 265, 50,25); { Сообщение }
   SetTextStyle (TripFont,0,1);
   SetColor (Red);
   OutTextXY (525, 255, 'HELP ME !');
   { Bar3D }
   SetFillStyle (1,Cyan);
   SetColor (White);
   Bar3D (385, 190, 410, 290, 10, True);
   SetFillStyle (4,Yellow);
   FloodFill (415,250, White);
   SetFillStyle (9, Magenta);
   FloodFill (390, 188, White);
   { Tестовая информация }
   SetTextStyle (BoldFont, HorizDir, 1);
   OutTextXY (50,200, 'АВТОР:');
   SetTextStyle (TripFont, HorizDir, 3);
   OutTextXY (50,235, 'Дударев Виктор');
   SetColor (Yellow);
   OutTextXY (20,400, 'МОСКВА'' 98');
   SetColor (LightBlue);
   OutTextXY (150, 450, 'НАЖМИТЕ  ЛЮБУЮ  КЛАВИШУ ...');
End; { FIRST_PICTURE }

Procedure HELP_SCREEN;
Begin
   Size:= ImageSize (120,90,550,390); { Сохранение области экрана }
   GetMem (P, Size);                  { на которую будет наложено }
   GetImage (120,90,550,390, P^);     { окно справки              }
   SetTextJustify (1,1);
   SetFillStyle (1, Blue);
   Bar (120,90,550, 390);
   SetColor (Yellow);
   SetTextStyle (BoldFont, 0, 3);
   OutTextXY (345, 110, 'СПРАВКА');
   SetTextStyle (TripFont, 0, 1);
   OutTextXY (345, 150, 'Вашему вниманию представляется');
   OutTextXY (345, 170, 'очередная версия популярной игры TETRIS');
   OutTextXY (345, 375,'нажмите любую клавишу...');
   SetColor (LightGreen);
   OutTextXY (345, 210, 'НАЗНАЧЕНИЕ  КЛАВИШ:');
   SetTextStyle (0,0,1);
   SetTextJustify (0,1);
   SetColor (White);
   OutTextXY (240, 235, 'F1  -  СПРАВКА (ЭТО ОКНО)');
   Line (240, 249, 250, 249);
   Line (240, 249, 243, 252);
   Line (240, 249, 243, 246);
   OutTextXY (260, 250, ' -  ПЕРЕМЕЩЕНИЕ ФИГУРЫ ВЛЕВО');
   Line (240, 264, 250, 264);
   Line (250, 264, 247, 267);
   Line (250, 264, 247, 261);
   OutTextXY (260, 265, ' -  ПЕРЕМЕЩЕНИЕ ФИГУРЫ ВПРАВО');
   Line (245, 272, 245, 282);
   Line (245, 272, 248, 275);
   Line (245, 272, 242, 275);
   OutTextXY (260, 280, ' -  ПОВОРОТ ФИГУРЫ');
   Line (245,287  ,245, 297);
   Line (245, 297, 248, 294);
   Line (245, 297, 242, 294);
   OutTextXY (260, 295, ' -  БРОСОК ФИГУРЫ ВНИЗ');
   OutTextXY (240, 310, 'Enter  -  ВЫБОР ПУНКТА МЕНЮ');
   OutTextXY (240, 325, 'P  -  ПАУЗА');
   OutTextXY (240, 340, 'Esc  -  ВЫХОД ИЗ ИГРЫ');
   Rectangle (120,90, 550, 390);
   KEY;
   PutImage (120, 90, P^, NormalPut); { Восстановление ранее сохраненной }
   FreeMem (P, Size);                 { области экрана }
End; { HELP_SCREEN }

Procedure KEY;
Begin
   Ch:= Readkey;
   While KeyPressed do
      Ch:= Readkey;
End; { Key }

Procedure BEST_RESULTS;
Begin
   Size:= ImageSize (110,100, 530,380); { Сохранение области экрана }
   GetMem (P, Size);                    { на которую будет наложено }
   GetImage (110,100, 530,380, P^);     { окно лучших результатов   }
   SetFillStyle (1, Blue);
   Bar (110,100, 530,380);
   SetTextStyle (TripFont, 0, 4);
   SetTextJustify (1,1);
   SetColor (LightGreen);
   OutTextXY (320, 120, 'ЛУЧШИЕ РЕЗУЛЬТАТЫ');
   SetTextStyle (TripFont,0, 2);
   SetColor (Yellow);
   OutTextXY (230, 150, 'ИМЯ');
   OutTextXY (420, 150, 'РЕЗУЛЬТАТ');
   SetTextJustify (LeftText, 1);
   SetColor (LightGreen);
   SetTextStyle (TripFont, 0, 1);
   OutTextXY (260,360, Rec.WinnerText);
   SetColor (Yellow);
   SetTextStyle (0,0,1);
   OutTextXY (120, 367, 'ТЕКСТ ПОБЕДИТЕЛЯ:');
   SetColor (White);
   Rectangle (110,100, 530,380);
   For i:=1 to 10 do
      begin
         OutTextXY (150, 180+(i-1)*17, Rec.Name[i]);
         Str (Rec.Sc[i], St);
         OutTextXY (400, 180+(i-1)*17, St);
      end;
   KEY;
   PutImage (110,100, P^, NormalPut); { Восстановление ранее сохраненной }
   FreeMem (P, Size);                 { области экрана }
End; { BEST_RESULTS }

Procedure INIT_GAME;
Begin
   ClearDevice;
   SetTextJustify (RightText, CenterText);
   SetTextStyle (BoldFont, HorizDir, 3);
   SetColor (LightGreen);
   OutTextXY (XS+100, YS-50, 'ИНФОРМАЦИЯ:');
   SetTextStyle (TripFont, HorizDir, 2);
   SetColor (White);
   Rectangle (0,0,639,479);
   OutTextXY (XS-10, YS, 'ОЧКИ:');
   OutTextXY (XS-10, YS+Sst, 'ЛИНИИ:');
   OutTextXY (XS-10, YS+2*Sst, 'УРОВЕНЬ:');
   OutTextXY (XN-20, YN+Item, 'СЛЕДУЮЩАЯ');
   OutTextXY (XN-20, YN+2*Item, 'ФИГУРА');
   SetTextJustify (LeftText, CenterText);
   Rectangle (XN-1, YN-1, XN+4*Item, YN+4*Item);{ для отображения след. фигуры }
   SetFillStyle(1,White);
   Bar(X0-10, Y0, X0+MaxX*20+9, Y0+MaxY*20+9);
   SetFillStyle(1,Black);
   Bar(X0,Y0, X0+MaxX*20-1, Y0+MaxY*20-1);
   SetBkColor (Black);
   { $ }
   SetColor (Black);
   SetFillStyle (1, Yellow);
   FillEllipse (XS-100, YS, 12,12);
   FillEllipse (350, 400, 20,25);
   OutTextXY (XS-104, YS-2, '$');
   { Подиум }
   SetFillStyle (9, Yellow);
   SetColor (White);
   MoveTo (390, 430);
   LineRel (240,0);
   LineRel (0,-30);
   LineRel (-80,0);
   LineRel (0,-30);
   For i:=1 to 2 do
      begin
         LineRel (-80,0);
         LineRel (0,30);
      end;
   FloodFill (500, 420, White);
   { Рисунок "уровень" }
   SetFillStyle (2, Green);
   Bar (XS-125, YS+18, XS-105, YS+35);
   SetFillStyle (4, LightRed);
   MoveTo (XS-160, YS+60);
   LineRel (21,0);
   LineRel (0,-21);
   For i:=1 to 3 do
      begin
         LineRel (-7,0);
         LineRel (0,7)
      end;
   FloodFill (XS-150, YS+55, White);
   { Установка начальных параметров }
   Exit:= FALSE;
   TimeStep:= TimeStep0;
   EndOfGame:= TRUE;
   Level:= 1;
   Score:= 0;
   Lines:= 0;
   CurLines:= 0;
   SetColor (LightGreen);
   OutTextXY (XS, YS+2*Sst, '1');
   OutTextXY (XS, YS, '0');
   OutTextXY (XS, YS+Sst, '0');
   { Цифра "1" на подиуме }
   SetTextStyle (TripFont, 0, 7);
   SetColor (Black);
   OutTextXY (502, 390, '1');
   { имя победителя }
   SetFillStyle (1, Black);
   SetTextJustify (1,1);
   SetTextStyle (0, 0, 1);
   SetColor (LightBlue);
   Bar (400, 340, 620, 360);
   Str (Rec.Sc[1], St);
   OutTextXY (510,350,Rec.Name[1]+'  '+St);
   { Вывод остальной текстовой info и остальные рисунки }
   SetTextStyle (TripFont, 0, 1);
   SetColor (LightCyan);
   OutTextXY (330,460, 'Клавиши управления: Курсор, Enter.     Нажми F1 для справки.');
   SetTextStyle (TripFont, 0, 5);
   MoveTo (350, 400);
   SetColor (Yellow);
   LineRel (-10, -40);
   LineRel (10,5);
   LineRel (10,-5);
   LineRel (-10, 40);
   SetFillStyle (1,Yellow);
   FloodFill (350, 370, Yellow);
   SetColor (LightRed);
   OutTextXY (351, 396, '$');
   MoveTo (343, 376);
   LineRel (15,0);
   SetColor (LightCyan);
   SetTextStyle (TripFont, 0, 7);
   OutTextXY (170, 18, 'TETRIS');
End; { INIT_GAME }

Procedure PAUSE;
Begin
   SetTextJustify (1,1);
   SetColor (White);
   SetTextStyle (TripFont, HorizDir, 8);
   Size:= ImageSize (185, 210, 455, 290); { Сохранение области экрана }
   GetMem (P, Size);
   GetImage (185, 210, 455, 290, P^);
   SetFillStyle (1, Green);
   Bar (185, 210, 455, 290);
   Rectangle (185, 210, 455, 290);
   OutTextXY (320 , 240, 'ПАУЗА');
   KEY;
   PutImage (185, 210, P^, NormalPut); { Восстановление ранее сохраненной }
   FreeMem (P, Size);                  { области экрана }
End; {PAUSE }

Procedure ESCAPE;
Begin
   Size:= ImageSize (155,200, 485,280); { Сохранение области экрана }
   GetMem (P, Size);
   GetImage (155,200, 485,280, P^);
   SetFillStyle (1, Red);
   Bar (155,200, 485,280);
   SetTextJustify(1,1);
   SetColor (White);
   Rectangle (155,200, 485,280);
   SetTextStyle (0, 0,1);
   OutTextXY (320, 210, 'ВЫ ДЕЙСТВИТЕЛЬНО ХОТИТЕ ЗАКОНЧИТЬ ИГРУ ?');
   M.ADD_MENU ('ДА', GrSuc);
   M.ADD_MENU ('НЕТ',GrSuc);
   SetTextStyle (TripFont, 0, 3);
   if M.CHOICE_MENU (FALSE, 340,250, Cyan, Blue, Green, White) = 1 then
      EndOfGame:= TRUE;
   PutImage (155,200, P^, NormalPut); { Восстановление ранее сохраненной }
   FreeMem (P, Size);                 { области экрана }
   M.DESTROY_MENU;
End; { ESCAPE }

Procedure QUIT;
Begin
   Size:= ImageSize (155,200, 485,280); { Сохранение области экрана }
   GetMem (P, Size);
   GetImage (155,200, 485,280, P^);
   SetFillStyle (1, Red);
   Bar (155,200, 485,280);
   SetTextJustify(1,1);
   SetColor (White);
   Rectangle (155,200, 485,280);
   SetTextStyle (0, 0,1);
   OutTextXY (320, 210, 'ВЫ ДЕЙСТВИТЕЛЬНО ХОТИТЕ ВЫЙТИ ИЗ ИГРЫ ?');
   M.DESTROY_MENU;
   M.ADD_MENU ('ДА', GrSuc);
   M.ADD_MENU ('НЕТ',GrSuc);
   SetTextStyle (TripFont, 0, 3);
   if M.CHOICE_MENU (FALSE, 340,250, Cyan, Blue, Green, White) = 1 then
      Exit:= TRUE;
   PutImage (155,200, P^, NormalPut); { Восстановление ранее сохраненной }
   FreeMem (P, Size);                 { области экрана }
   M.DESTROY_MENU;
End; { QUIT }

Procedure ROTATE;
Var
   i, j: Byte;
Begin { поворот }
   for i:=1 to 4 do
      for j:=1 to 4 do
          Fig[Tmp+1].Image[i,j]:= Fig[Tmp].Image[5-j,i];
End; { ROTATE }

Procedure CUT;
Var
   i,j: ShortInt;
Begin { "вырезаем" фигуру из стакана }
   For i:=1 to 4 do
      For j:=1 to 4 do
         if Fig[Tmp].Image[j,i] = '1' then
            A[X+i-1,Y+j-1]:= FALSE;
End; { CUT }

Procedure PASTE;
Var
   i,j: ShortInt;
Begin { вставляем образ фигуры в массив стакана }
   For i:=1 to 4 do
      For j:=1 to 4 do
         If Fig[Tmp].Image[j,i] = '1' then
            A[X+i-1,Y+j-1]:= TRUE;
End; { PASTE }

Function CANPUT (F: Mas; X, Y:ShortInt): Boolean;
Var
   i, j: ShortInt;
   Fl: Boolean;
Begin { проверка возможности вставка фигуры в стакан }
   Fl:=TRUE;
   for i:=1 to 4 do
      for j:=1 to 4 do
         if (F[j,i]='1') AND ((A[X+i-1,Y+j-1] <> FALSE) OR (X+i-1<1) OR (X+i-1>MaxX) OR (Y+j-1>MaxY)) then
               Fl:=FALSE;
   CanPut:=Fl;
End; { CANPUT }

Procedure PUT_FIGURE;
Var
   i,j: ShortInt;
Begin { поместить фигуру в стакан }
   SetFillStyle (1, Fig[Tmp].Color);
   for i:=1 to 4 do
      for j:=1 to 4 do
         if (Fig[Tmp].Image[j,i]='1') then
            begin
               A[X+i-1, Y+j-1]:= TRUE;
               { Графические изменения }
               Bar(X0+(X+i-2)*Item, Y0+(Y+j-2)*Item, X0+(X+i-1)*Item-1, Y0+(Y+j-1)*Item-1);
            end;
End; { PUT_FIGURE }

Procedure REMOVE_FIGURE;
Var
   i,j: ShortInt;
Begin { удалить фигуру из стакана }
   SetFillStyle (1, Black);
   for i:=1 to 4 do
      for j:=1 to 4 do
         if (Fig[Tmp].Image[j,i]='1') then
            begin
               A[X+i-1, Y+j-1]:= FALSE;
               { Графические изменения }
               Bar(X0+(X+i-2)*Item, Y0+(Y+j-2)*Item, X0+(X+i-1)*Item-1, Y0+(Y+j-1)*Item-1);
            end;
End; { REMOVE_FIGURE }

Function HIGH_TIME: Boolean;
Var
   Fl: Boolean;
   H, M, S, S100: Word;
Begin { проверка необходимости сдвинуть фигуру вниз }
   Fl:= FALSE;
   GetTime (H, M, S, S100);
   if Sec < S then { Та же минута } begin
      if (S100+(100-Sec100)+100*(S-Sec-1)) >= TimeStep then
         Fl:= TRUE; end
   else if Sec = S then begin
      if (S100-Sec100) >= TimeStep then
         Fl:= TRUE; end
   else { Sec > S }
      if (S100+(100-Sec100)+100*(S+59-Sec)) >= TimeStep then
         Fl:= TRUE;
   High_Time:= Fl;
End; { HIGH_TIME }

Procedure ANALYSE;
Var
   i,j,k,N: ShortInt;
   Fl: Boolean;

   Procedure UpdateIt;
   { Отображение на экране текстовой информации (очки, линии, уровень) }
   Begin
      Inc (Lines, N);
      Inc (CurLines, N);
      Case N Of
         1: Inc (Score);
         2: Inc (Score,3);
         3: Inc (Score,6);
         4: Inc (Score,10);
      end;
      SetFillStyle (1, GetBkColor);
      Bar (XS-5, YS-Sst div 2, XS+100, YS+Round(1.5*Sst));
      SetColor (LightGreen);
      SetTextJustify (LeftText, 1);
      SetTextStyle (TripFont, HorizDir, 2);
      if CurLines >= LevelLines then
         begin
            CurLines:= 0;
            if TimeStep-LevelTimeStep >= 0 then
               begin
                  Dec (TimeStep, LevelTimeStep);
                  Inc (Level);
                  Bar (XS-5, YS+Round(1.5*Sst), XS+100, YS+Round(2.5*Sst));
                  { Отображение уровня }
                  Str (Level, St);
                  OutTextXY (XS, YS+2*Sst, St);
               end;
         end;
      { Отображение очков и числа линий }
      Str (Score, St);
      OutTextXY (XS, YS, St);
      Str (Lines, St);
      OutTextXY (XS, YS+Sst, St);
   End; { UpdateIt }
Begin { ANALYSE }
   N:= 0;
   for i:=1 to MaxY do
      begin
         Fl:= TRUE;
         for j:=1 to MaxX do
            if A[j,i] = FALSE then
               Fl:= FALSE;
         if Fl then { Удаляем i-ю "строку" из массива стакана }
            begin   { по правилам Tetris'a }
               Inc(N);
               for j:=i downto 1 do
                  for k:=1 to MaxX do
                     if j <> 1 then
                        A[k,j]:= A[k,j-1]
                     else A[k,j]:= FALSE;
               { Графические изменения }
               Size:= ImageSize (X0, Y0, X0+MaxX*Item-1, Y0+(i-1)*Item-1);
               GetMem (P, Size);
               GetImage (X0, Y0, X0+MaxX*Item-1, Y0+(i-1)*Item-1, P^);
               PutImage (X0, Y0+Item, P^, NormalPut);
               FreeMem (P, Size);
               SetFillStyle (1, Black);
               Bar (X0, Y0, X0+MaxX*Item-1, Y0+Item-1);
            end;
      end;
   If N > 0 then { удалены заполненные строки }
      UpdateIt;
End; { ANALYSE }

Procedure SHOW_NEXT;
Var i,j: ShortInt;
Begin { слудующая фигура }
   SetFillStyle (1, GetBkColor);
   Bar (XN, YN, XN+4*Item-1, YN+4*Item-1);
   Next:= Random (NumFig+1);
   SetFillStyle (1, Fig[Next].Color);
   for i:=1 to 4 do
      for j:=1 to 4 do
         if (Fig[Next].Image[j,i]='1') then
            { Графические изменения }
            Bar (XN+(i-1)*Item, YN+(j-1)*Item, XN+i*Item-1, YN+j*Item-1);
End; { SHOW_NEXT }

Procedure ACTIONS_WITH_FIGURE;
Begin
   Repeat { Действия с фигурой }
      GetTime (Hour, Min, Sec, Sec100);
      While (Not HIGH_TIME) And (Not Drop) And (Not EndOfGame) do
         if KeyPressed then { Нажата клавиша }
             begin { Опрос клавиатуры }
                Ch:= ReadKey;
                if Ord(Ch)<>0 then { Direct Code }
                   Case UpCase(Ch) Of
                      'P','з','З': PAUSE;
                      KbEscape: ESCAPE;
                   end
                else { Scan Code }
                   begin
                      Ch:= ReadKey;
                      Case Ch Of
                         KbLeft:
                            begin
                               CUT;
                               if CANPUT (Fig[Tmp].Image, X-1, Y) then
                                      begin
                                         REMOVE_FIGURE;
                                         Dec (X);
                                         PUT_FIGURE;
                                      end
                               else
                                  PASTE;
                            end;
                         KbRight:
                            begin
                               CUT;
                               if CANPUT (Fig[Tmp].Image, X+1, Y) then
                                  begin
                                     REMOVE_FIGURE;
                                     Inc (X);
                                     PUT_FIGURE;
                                  end
                               else
                                  PASTE;
                            end;
                         KbUp:
                            begin
                               ROTATE;
                               CUT;
                               if CANPUT (Fig[Tmp+1].Image, X, Y) then
                                  begin
                                     REMOVE_FIGURE;
                                     Fig[Tmp].Image:=Fig[Tmp+1].Image;
                                     PUT_FIGURE;
                                  end
                               else
                                  PASTE;
                            end;
                         KbDown: Drop:= TRUE;
                         KbF1: HELP_SCREEN;
                      end; { Case }
                   end;
             end; { if KeyPressed }
      { Движение фигуры вниз }
      Repeat
         CUT;
         if CANPUT (Fig[Tmp].Image, X, Y+1) then
            begin
               REMOVE_FIGURE;
               Inc (Y);
               PUT_FIGURE;
            end
         else
            begin
               PASTE;
               NextFig:= TRUE;
            end;
      Until ((NextFig) And Drop) or (Not Drop);
      if NextFig then
         ANALYSE;
   Until NextFig;
End; { ACTIONS_WITH_FIGURE }

Procedure UPDATE_RESULTS;
   Function Good_Result: Stroka;
   { Ввод имени игрока }
   Begin
      Size:= ImageSize (120,200, 520,280);
      GetMem (P, Size);
      GetImage (120,200, 520,280, P^);
      SetTextJustify (1,1);
      SetFillStyle(1, Green);
      Bar (120,200, 520,280);
      SetColor (White);
      Rectangle (120,200, 520,280);
      SetTextStyle (TripFont, 0, 1);
      OutTextXY (330, 215, 'Поздравляю, неплохо! Введите ваше имя:');
      SetColor (Yellow);
      Good_Result:= EDIT_LINE (141,240, TripFont, 3, 20);
      PutImage (120,200, P^, NormalPut);
      FreeMem (P, Size);
   End; { Good_Result }

   Function First_Place: Stroka;
   { Ввод текста победителя }
   Begin
      Size:= ImageSize (120,200, 520,300);
      GetMem (P, Size);
      GetImage (120,200, 520,300, P^);
      SetTextJustify (1,1);
      SetFillStyle(1, LightGreen);
      Bar (120,200, 520,300);
      SetColor (LightBlue);
      Rectangle (120,200, 520,300);
      SetTextStyle (TripFont, 0, 1);
      OutTextXY (330, 213, 'Поздравляю! Вы стали ЧЕМПИОНОМ!');
      OutTextXY (330, 238, 'Введите текст победителя:');
      SetColor (LightGreen);
      First_Place:= EDIT_LINE (141,267, TripFont, 3, 20);
      PutImage (120,200, P^, NormalPut);
      FreeMem (P, Size);
   End; { First_Place }

Begin { UPDATE_RESULTS }
   j:=0;
   For i:=1 to 10 do
      if Rec.Sc[i] <= Score then
         begin
            j:=i;
            Break;
         end;
   if j>0 then { игрок попал в лучшую десятку }
      begin
         For i:=9 downto j do
            begin
               Rec.Name[i+1]:= Rec.Name[i];
               Rec.Sc[i+1]:= Rec.Sc[i];
            end;
         { Запрос имени + может быть запрос WinnerText }
         Rec.Name[j]:= Good_Result;
         Rec.Sc[j]:= Score;
         if j=1 then
            begin
               Rec.WinnerText:= First_Place;
               SetFillStyle (1, Black);
               SetTextJustify (1,1);
               SetTextStyle (0, 0, 1);
               SetColor (LightBlue);
               Bar (400, 340, 620, 360);
               Str (Rec.Sc[1], St);
               OutTextXY (510,350,Rec.Name[1]+'  '+St);
            end;
         BEST_RESULTS;
      end;
End; { UPDATE_RESULTS }

Procedure GAME;
Begin
   REPEAT
      M.ADD_MENU ('НОВАЯ ИГРА', GrSuc); { Добавление пунктов в меню }
      M.ADD_MENU ('ЛУЧШИЕ РЕЗУЛЬТАТЫ', GrSuc);
      M.ADD_MENU ('СПРАВКА', GrSuc);
      M.ADD_MENU ('ВЫХОД ИЗ ИГРЫ', GrSuc);
      Repeat
          SetFillStyle (1,Black);
          Bar (X0,Y0, X0+MaxX*20-1, Y0+MaxY*20-1);
          SetTextStyle (BoldFont, 0, 3);
          SetTextJustify (1,1);
          SetColor (LightGreen);
          OutTextXY (X0+(MaxX*Item div 2), Y0+60, '* МЕНЮ *');
          SetTextStyle (TripFont, 0, 1);
          I:= M.CHOICE_MENU (TRUE, X0+(MaxX*Item div 2)-3, Y0+(MaxY*Item div 2),
             LightGray, Blue, White, Green);
          Case I of { номер выбранного пункта меню }
             2: BEST_RESULTS;
             3: HELP_SCREEN;
             4: QUIT;
             1: begin
                EndOfGame:= FALSE;
                for X:=-2 to MaxX+3 do
                   for j:=1 to MaxY+3 do
                      A[X,j]:= FALSE;
                TimeStep:= TimeStep0;
                Level:= 1;
                Score:= 0;
                Lines:= 0;
                CurLines:= 0;
                SetFillStyle (1, GetBkColor);
                Bar (XS-5, YS-Sst div 2, XS+100, YS+Round(2.5*Sst));
                SetColor (LightGreen);
                SetTextStyle (TripFont, HorizDir, 2);
                SetTextJustify (LeftText, CenterText);
                OutTextXY (XS, YS+2*Sst, '1');
                OutTextXY (XS, YS, '0');
                OutTextXY (XS, YS+Sst, '0');
             end;
          End { Case I Of...}
      Until (I=1) Or (I=4);
      M.DESTROY_MENU;

      IF Not Exit then BEGIN
         SetFillStyle (1, Black);
         Bar (X0,Y0, X0+MaxX*20-1, Y0+MaxY*20-1);
         While Not EndOfGame DO Begin
            SHOW_NEXT;
            X:= 5;
            Y:= 1;
            Drop:= FALSE;
            Fig[Tmp]:= Fig[Cur];
            if CANPUT (Fig[Tmp].Image, X,Y) then
               begin { помещаем новую фигуру в стакан }
                  PUT_FIGURE;
                  NextFig:= FALSE;
                  ACTIONS_WITH_FIGURE;
                  Cur:= Next;
               end
            else { нельзя поместить новую фигуру в стакан }
               EndOfGame:=True;
         if EndOfGame then
            UPDATE_RESULTS;
         End; { WHILE Not EndOfGame }
      END;{ if not exit }
   UNTIL Exit;
End; { GAME }

END.
