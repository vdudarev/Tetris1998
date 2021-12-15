Unit Files;
                                  INTERFACE
Uses Data;

Procedure PREPARE;
{ Процедура чтения информации из файлов данных }
Procedure READ_RESULTS;
{ Читает лучшие результаты из файла ScoreFile }
Procedure SAVE_RESULTS;
{ Сохраняет таблицу лучших результатов в файле ScoreFile }

                                IMPLEMENTATION

Procedure READ_RESULTS;
Begin { Чтение лучших результатов из файла }
   Assign (Buf, ScoreFile);
   Reset (Buf);
   Readln(Buf, Rec.WinnerText);
   For i:=1 to 10 do
      begin
         Readln (Buf, St);
         Rec.Name[i]:= Copy(St, 1, 20);
         While Rec.Name[i,Length (Rec.Name[i])] = ' ' do
            Delete (Rec.Name[i], Length(Rec.Name[i]), 1);
         Val (Copy(St,21,5), Rec.Sc[i], Code);
      end;
   Close (Buf);
End; { READ_RESULTS }

Procedure SAVE_RESULTS;
Begin
   Assign (Buf, ScoreFile);
   Rewrite (Buf);
   Writeln (Buf, Rec.WinnerText);
   For i:=1 to 10 do
      begin
         While Length (Rec.Name[i]) < 20 do
            Rec.Name[i]:=Rec.Name[i]+' ';
         Str (Rec.Sc[i], St);
         While Length(St) < 5 do
            St:=' '+St;
         Writeln (Buf, Rec.Name[i]+St);
      end;
   Close (Buf);
End; { SAVE_RESULTS }

Procedure PREPARE;
Begin
   NumFig:=-1;
   { Чтение фигур из файла FigFile }
   Assign(Buf, FigFile);
   Reset(Buf);
   While Not EOF(Buf) do
      begin
         inc(NumFig);
         readln(Buf, Fig[NumFig].Color);
         for i:=1 to 4 do
            Readln(Buf, Fig[NumFig].Image[i]);
      end;
   Close(Buf);
   READ_RESULTS; { Чтение результатов их файла }
End; { PREPARE }

END.
