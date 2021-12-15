PROGRAM Tetris;
{  НАЗНАЧЕНИЕ = Игра TETRIS
   АВТОР = Дударев Виктор 3ИТ-I-41
   ДАТА = 30.05.98г.                }
USES
   Dos, Crt, Graph, My_Adds, Files, Data; { подключаем модули }

BEGIN
   Randomize;
   PREPARE;
   GRAPHICS (GrSuc);
   if GrSuc then { графика установлена успешно }
      Begin
         FIRST_PICTURE;
         KEY;
         INIT_GAME;
         M.INIT_MENU;
         GAME;
      End;
   CloseGraph;
   SAVE_RESULTS; { записать лучшие результаты на диск }
END.
