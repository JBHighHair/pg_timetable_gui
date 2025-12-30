{------------------------------------------------------------------------------
pg_timetable_gui
Copyright © 2026 John Buoro, Harvey Norman Holdings Limited. All Rights Reserved.
------------------------------------------------------------------------------}

unit Unit2;

{$mode ObjFPC}{$H+}

interface

uses
     Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
     EditBtn, IniFiles;

type

     { TForm2 }

     TForm2 = class(TForm)
          Bevel1: TBevel;
          btnCancel: TButton;
          btnOk: TButton;
          edDatabase: TEdit;
          edHost: TEdit;
          edPasswd: TEditButton;
          edPort: TEdit;
          edUserID: TEdit;
          laDbName: TLabel;
          laHost: TLabel;
          laPass: TLabel;
          laPort: TLabel;
          laUser: TLabel;
          pnlHeader: TPanel;
          procedure btnCancelClick(Sender: TObject);
          procedure Connect(Sender: TObject);
          procedure FormShow(Sender: TObject);
     private

     public

     end;

var
     Form2: TForm2;

implementation

uses Unit1;

{$R *.lfm}

{ TForm2 }

procedure TForm2.Connect(Sender: TObject);
var
    INI : TIniFile;
    msg : string;
begin
   {Set the fields with the contents}
   DatabaseName := edDatabase.Text;
   UserName := edUserID.Text;
   Password := edPasswd.Text;
   HostName := edHost.Text;
   Port := edPort.Text;

   {Disable connections}
   Form1.PQConnection1.Close;
   Form1.SQLQueryChains.Close;
   Form1.SQLQueryChains.Clear;
   Form1.SQLTransaction1.Active := False;

   {Connect}
   Form1.PQConnection1.CharSet := 'UTF8';
   Form1.PQConnection1.LoginPrompt := False;
   Form1.PQConnection1.HostName := HostName;
   Form1.PQConnection1.Params.Add(Format('port=%d', [StrToIntDef(Port, 5432)]));
   Form1.PQConnection1.DatabaseName := DatabaseName;
   Form1.PQConnection1.UserName := UserName; {Blank is Trusted authentication.}
   Form1.PQConnection1.Password := Password; {Blank is Trusted authentication.}
   if (Form1.PQConnection1.Connected) then Form1.PQConnection1.Connected := False;
   if (not Form1.PQConnection1.Connected) then
   begin
   try
        Form1.PQConnection1.Open;
   except on E:Exception do
        begin
             msg := 'There was an error connecting to PostgresSQL Server database ' + DatabaseName + ' on server ' + HostName + ^J + 'Error: ' + e.Message;
             MessageDlg(msg, mtError, [mbOk], 0);
             Screen.Cursor := crDefault;
             Form1.PQConnection1.Close(True);
             isConnected := false;

             Close;
        end;
   end;
   end;

   Form1.SQLTransaction1.Active := True;

   {Save the connection details}
   INI := TIniFile.Create(CurrPath + 'pg_timetable_gui.ini');
   INI.WriteString('pg_timetable_gui', 'DatabaseName', DatabaseName);
   INI.WriteString('pg_timetable_gui', 'UserName', UserName);
   INI.WriteString('pg_timetable_gui', 'Password', Form1.encrypt(key+UserName, Password));
   INI.WriteString('pg_timetable_gui', 'HostName', HostName);
   INI.WriteString('pg_timetable_gui', 'Port', Port);
   INI.Free;

   Close;
end;

procedure TForm2.btnCancelClick(Sender: TObject);
begin
   Close;
end;

procedure TForm2.FormShow(Sender: TObject);
begin
     edDatabase.Text := DatabaseName;
     edUserID.Text := UserName;
     edPasswd.Text := Password;
     edHost.Text := HostName;
     edPort.Text := Port;
     if edPort.Text = '' then edPort.Text := '5432';
end;

end.

