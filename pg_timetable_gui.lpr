{------------------------------------------------------------------------------
pg_timetable_gui
Copyright © 2026 John Buoro, Harvey Norman Holdings Limited. All Rights Reserved.

Portions of code taken from https://github.com/cybertec-postgresql/pg_timetable_gui (Pavlo Golub):
   * UpdateCronTimes
   * IsCronValueValid
   * SelectSQL

Icons: https://remixicon.com/

------------------------------------------------------------------------------}
{
Extra Packages required:
None
}

program pg_timetable_gui;

{$mode objfpc}{$H+}

uses
     {$IFDEF UNIX}
     cthreads,
     {$ENDIF}
     {$IFDEF HASAMIGA}
     athreads,
     {$ENDIF}
     Interfaces, // this includes the LCL widgetset
     Forms, Unit1, Unit2, Unit3, Unit4;

{$R *.res}

begin
   //http://wiki.freepascal.org/heaptrc
   {$if declared(UseHeapTrace)}
      GlobalSkipIfNoLeaks := true; // Show report only on leak.
      SetHeapTraceOutput('LeakTrace.log');
   {$endif}
   RequireDerivedFormResource:=True;
   Application.Scaled:=True;
   {$PUSH}{$WARN 5044 OFF}
   Application.MainFormOnTaskbar:=True;
   {$POP}
   Application.Initialize;
   Application.CreateForm(TForm1, Form1);
   Application.CreateForm(TForm2, Form2);
   Application.CreateForm(TForm3, Form3);
   Application.CreateForm(TForm4, Form4);
   Application.Run;
end.

