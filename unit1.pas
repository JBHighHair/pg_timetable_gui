{------------------------------------------------------------------------------
pg_timetable_gui
Copyright © 2026 John Buoro, Harvey Norman Holdings Limited. All Rights Reserved.
------------------------------------------------------------------------------}
{
https://cybertec-postgresql.github.io/pg_timetable/v6.x/database_schema/#main-tables-and-objects
https://cybertec-postgresql.github.io/pg_timetable/v6.x/samples/
}

unit Unit1;

{$mode objfpc}{$H+}

interface

uses
     Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, Menus,
     DBGrids, StdCtrls, FileInfo {need this for reading exe info}
     , winpeimagereader {need this for reading exe info}
     , elfreader {needed for reading ELF executables}
     , machoreader, {needed for reading MACH-O executables}
     IniFiles, PQConnection, SQLDB, Unit2, Unit3, Unit4,
     DB, blowfish, LCLType, Buttons, ExtCtrls, LCLIntf, IpHtml, GraphUtil;

type

     { TForm1 }

     TForm1 = class(TForm)
        AddChainBitBtn: TBitBtn;
        AddTaskBitBtn: TBitBtn;
        ConnectBitBtn: TBitBtn;
        DBGridChains: TDBGrid;
        DBGridLog: TDBGrid;
        DBGridTasks: TDBGrid;
        DeleteChainBitBtn: TBitBtn;
        DeleteTaskBitBtn: TBitBtn;
        HelpIpHtmlPanel: TIpHtmlPanel;
        SearchBitBtn: TBitBtn;
        SearchEdit: TEdit;
        EditChainBitBtn: TBitBtn;
        EditTaskBitBtn: TBitBtn;
        ExitBitBtn: TBitBtn;
        ImageList1: TImageList;
        DataSourceChains: TDataSource;
        DataSourceLog: TDataSource;
        DataSourceTasks: TDataSource;
        LabelChains: TLabel;
        LabelTasks: TLabel;
        MainMenu: TMainMenu;
        MenuItemConnect: TMenuItem;
        MenuItemAbout: TMenuItem;
        MenuItemExit: TMenuItem;
        MoveTaskDownBitBtn: TBitBtn;
        MoveTaskUpBitBtn: TBitBtn;
        PageControl1: TPageControl;
        PanelTasks: TPanel;
        PanelChains: TPanel;
        PQConnection1: TPQConnection;
        RefreshGridsBitBtn: TBitBtn;
        RefreshLogBitBtn: TBitBtn;
        RunChainBitBtn: TBitBtn;
        SQLQueryAdhoc: TSQLQuery;
        SQLQueryChains: TSQLQuery;
        SQLQueryLog: TSQLQuery;
        SQLQueryTasks: TSQLQuery;
        SQLTransaction1: TSQLTransaction;
        StatusBar1: TStatusBar;
        StopChainBitBtn: TBitBtn;
        TabSheet1: TTabSheet;
        TabSheet2: TTabSheet;
        TabSheet3: TTabSheet;
        WorkerLabel: TLabel;
        procedure AddChain(Sender: TObject);
        procedure AddTask(Sender: TObject);
        procedure DBGridChainsCellClick(Column: TColumn);
        procedure DeleteChain(Sender: TObject);
        procedure DeleteTask(Sender: TObject);
        procedure EditChain(Sender: TObject);
        procedure EditTask(Sender: TObject);
        procedure HelpIpHtmlPanelHotClick(Sender: TObject);
        procedure MoveTaskDown(Sender: TObject);
        procedure MoveTaskUp(Sender: TObject);
        procedure PageControl1Change(Sender: TObject);
        procedure RefreshGrids(Sender: TObject);
        procedure GridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
        procedure RunChain(Sender: TObject);
        procedure SearchEditKeyDown(Sender: TObject; var Key: Word;
           Shift: TShiftState);
        procedure SearchExecutionLog(Sender: TObject);
        procedure ShowLog(Sender: TObject);
        procedure FormCreate(Sender: TObject);
        procedure FormDestroy(Sender: TObject);
        procedure About(Sender: TObject);
        procedure Connect(Sender: TObject);
        procedure ExitClick(Sender: TObject);
        procedure ReadSettings;
        function encrypt(key:string; stext:string):string;
        function decrypt(key:string; stext:string):string;
        procedure ShowChains(Sender: TObject);
        procedure ShowTasks(Sender: TObject);
        procedure CheckSchema(Sender: TObject);
        procedure StopChain(Sender: TObject);
        procedure ToggleUI(Sender: TObject);
        procedure ShowWorker(Sender: TObject);
        procedure RefreshChainGridUI(Sender: TObject);
        function GetContrastColour(const ABackgroundColour, objColor: TColor): TColor;
     private

     public

     end;

const
     key = 'pg_Timetable_GUI';

var
     Form1: TForm1;
     FileVerInfo : TFileVersionInfo;
     CurrPath : string;
     isConnected : boolean;
     worker : string;
     DatabaseName, UserName, HostName, Password, Port : string;

implementation

{$R *.lfm}

{ TForm1 }

function TForm1.GetContrastColour(const ABackgroundColour, objColor: TColor): TColor;
var
  R, G, B: Byte;
  Luminance: Double;
  // Constants for sRGB luminance calculation (gamma-adjusted)
  const
    CR = 0.2126;
    CG = 0.7152;
    CB = 0.0722;
    // A threshold of 0.5 (or 128 in a 0-255 range) is standard
    // to decide between a light or dark foreground colour
    Threshold = 0.5;

begin
  // Convert TColor to RGB components.
  // Note: TColor can be a system color, so ColorToRGB ensures we get a usable RGB value.
  R := GetRValue(ColorToRGB(ABackgroundColour));
  G := GetGValue(ColorToRGB(ABackgroundColour));
  B := GetBValue(ColorToRGB(ABackgroundColour));

  // Calculate luminance (perceived brightness)
  // The formula below is a simplification assuming gamma correction is handled by the constants
  // or a close approximation for general use.
  // The simpler weighted average works well for this purpose:
  Luminance := (R * CR + G * CG + B * CB) / 255.0;

  // Choose black or white based on the luminance threshold
  if Luminance >= Threshold then
    Result := ColorAdjustLuma(objColor, -20, True) {Darker}
  else
    Result := ColorAdjustLuma(objColor, 70, True); {Lighter}
end;

function TForm1.encrypt(key:string; stext:string):string;
var
  en: TBlowFishEncryptStream;
  s1: TStringStream;
begin
    if stext <> '' then
    begin
       s1 := TStringStream.Create('');
       en := TBlowFishEncryptStream.Create(key,s1);
       en.WriteAnsiString(stext);
       result := s1.datastring;

       s1.Free;
       en.Free;
    end
    else
    begin
        result := '';
    end;
end;

function TForm1.decrypt(key:string; stext:string):string;
var
  de: TBlowFishDeCryptStream;
  s1: TStringStream;
  temp: string;
begin
    if stext <> '' then
    begin
        s1 := TStringStream.Create(stext);
        de := TBlowFishDecryptStream.Create(key,s1);
        temp := de.ReadAnsiString;

        s1.Free;
        de.Free;
    end
    else
    begin
        temp := '';
    end;
    result := temp;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
    RS : TResourceStream;
    N: Longint;
    Result: String;
begin
    isConnected := False;
    CurrPath := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));

    {Limit form minimum size}
    Form1.Constraints.MinWidth := Form1.Width;
    Form1.Constraints.MinHeight := Form1.Height;

    PageControl1.TabIndex := 0; {Show first tab}

    ReadSettings;

    { Get file version }
    FileVerInfo := TFileVersionInfo.Create(nil);
    FileVerInfo.ReadFileInfo;

    {Load help}
    RS := TResourceStream.Create(HInstance, 'HELPHTML', RT_RCDATA);
    try
       HelpIpHtmlPanel.SetHtmlFromStream(RS);
    finally
       RS.Free;
    end;

    {Adjust font colour for certain objects to cope with potential theme changes}
    ConnectBitBtn.Font.Color := GetContrastColour(clForm, ConnectBitBtn.Font.Color);
    ExitBitBtn.Font.Color := GetContrastColour(clForm, ExitBitBtn.Font.Color);
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
     FileVerInfo.Free;
end;

procedure TForm1.About(Sender: TObject);
var
   list : TStringList;
begin
     MessageDlg('About...',
     FileVerInfo.VersionStrings.Values['ProductName'] + ^J +
     FileVerInfo.VersionStrings.Values['FileDescription'] + ^J +
     'Version ' + FileVerInfo.VersionStrings.Values['FileVersion'] + ^J +
     FileVerInfo.VersionStrings.Values['Comments'] + ^J +
     FileVerInfo.VersionStrings.Values['CompanyName'] + ^J +
     FileVerInfo.VersionStrings.Values['LegalCopyright'] + ^J, mtInformation, [mbOk], 0);

     {Test exception}
     {raise Exception.Create('Test Exception.');}

     {Test memory leaks}
     {list := TStringList.Create();
     list.Add('Test memory leak.');}
end;

procedure TForm1.Connect(Sender: TObject);
begin
    {Show connect form}
    Form1.Enabled := False;
    try
       Form2.ShowModal;
    finally
       Form1.Enabled := True;
    end;

    {Continue if connected}
    if (PQConnection1.Connected) then
    begin
        isConnected := true;
        CheckSchema(Sender);
        ShowWorker(Sender);
        ShowChains(Sender);
    end;
    ToggleUI(Sender);

    PageControl1.TabIndex := 0; {Show first tab}
end;

procedure TForm1.CheckSchema(Sender: TObject);
var
   i : integer;
   msg : string;
begin
   {Basic check that pg_timetable schema exists}
   try
        SQLQueryAdhoc.SQL.Clear;
        SQLQueryAdhoc.SQL.Add('SELECT count(*) as cnt FROM information_schema.tables WHERE table_schema = ''timetable'' and table_name in (''chain'', ''task'', ''parameter'', ''execution_log'')');
        SQLQueryAdhoc.ParamCheck:=False;
        SQLQueryAdhoc.Open;
        i := SQLQueryAdhoc.FieldByName('cnt').AsInteger;
   finally
        SQLQueryAdhoc.Close;
   end;

   if i <> 4 then
   begin
       msg := 'The pg_timetable schema does not appear to be located in database ' + DatabaseName + ' on server ' + HostName;
       MessageDlg(msg, mtError, [mbOk], 0);
       Close;
   end;
end;

procedure TForm1.ExitClick(Sender: TObject);
begin
   Close;
end;

procedure TForm1.ReadSettings;
var
  INI : TIniFile;
begin
     INI := TIniFile.Create(CurrPath + 'pg_timetable_gui.ini');
     DatabaseName := INI.ReadString('pg_timetable_gui', 'DatabaseName', 'postgres');
     UserName := INI.ReadString('pg_timetable_gui', 'UserName', 'postgres');
     Password := decrypt(key+UserName, INI.ReadString('pg_timetable_gui', 'Password', ''));
     HostName := INI.ReadString('pg_timetable_gui', 'HostName', '');
     Port := INI.ReadString('pg_timetable_gui', 'Port', '5432');
     INI.Free;
end;

procedure TForm1.ShowWorker(Sender: TObject);
begin
    {Get worker name}
    SQLQueryAdhoc.Close;
     try
          SQLQueryAdhoc.SQL.Clear;
          SQLQueryAdhoc.SQL.Add('SELECT client_name FROM timetable.active_session LIMIT 1;');
          SQLQueryAdhoc.ParamCheck := False;
          SQLQueryAdhoc.Open;
          WorkerLabel.Caption := 'Worker: ' + SQLQueryAdhoc.FieldByName('client_name').AsString;
          worker := SQLQueryAdhoc.FieldByName('client_name').AsString;
     finally
          SQLQueryAdhoc.Close;
     end;
end;

procedure TForm1.ShowChains(Sender: TObject);
begin
    {Get chains}
    SQLQueryChains.Close;
     try
          SQLQueryChains.SQL.Clear;
          SQLQueryChains.SQL.Add('SELECT c.chain_id as "Chain ID", chain_name as "Chain Name", (case when a.chain_id is null then '''' else ''Y'' end) as "Running", live as "Live", COALESCE(run_at, ''* * * * *'') as "Run At", c.client_name as "Client", max_instances as "Max Instances", exclusive_execution as "Exclusive", self_destruct as "Self Destruct", timeout as "Timeout (ms)" FROM timetable.chain c LEFT JOIN timetable.active_chain a on a.chain_id = c.chain_id ORDER BY c.chain_id;');
          SQLQueryChains.ParamCheck := False;
          SQLQueryChains.Open;
     finally
     end;
end;

procedure TForm1.ShowTasks(Sender: TObject);
var
  chain_id : integer;
begin
    {Get chain ID}
    chain_id := DBGridChains.DataSource.DataSet.FieldByName('Chain ID').AsInteger;
    {showmessage('Chain ID = ' + chain_id);}

    {Show tasks for the selected chain}
    SQLQueryTasks.Close;
    try
          SQLQueryTasks.SQL.Clear;
          SQLQueryTasks.SQL.Add('SELECT chain_id as "Chain ID", t.task_id as "Task ID", task_name as "Task Name", task_order as "Task Order", kind as "Task Kind", command as "Command", ' +
          'case jsonb_typeof(value) when ''string'' then left(trim(''"'' from value::text), 30) else left(value::text, 30) end as "Parameters", run_as as "Run As", ignore_error as "Ignore Error", autonomous as "Autonomous", database_connection as "Connection String", timeout as "Timeout (ms)" ' +
          'FROM timetable.task t ' +
          'LEFT JOIN timetable.parameter p ON t.task_id = p.task_id ' +
          'WHERE chain_id = ' + IntToStr(chain_id) + ' ORDER BY t.task_order ASC');
          SQLQueryTasks.ParamCheck:=False;
          SQLQueryTasks.Open;
    finally
    end;
end;

procedure TForm1.ShowLog(Sender: TObject);
begin
    if not isConnected then Exit;

    {Show the log}
    SQLQueryLog.Close;
    try
         SQLQueryLog.SQL.Clear;
         SQLQueryLog.SQL.Add('SELECT c.chain_name as "Chain Name", t.task_name as "Task Name", l.txid as TxID, ' +
         'l.last_run::timestamp as "Last Run", l.finished::timestamp as "Finished", ' +
         'cast(DATE_TRUNC(''second'', age(l.finished, l.last_run)) as varchar) "hh:mm:ss", ' +
         'l.returncode as "Return Code", l.ignore_error as "Ignore Error", ' +
         'l.kind as "Kind", l.command as "Command", left(l.output, 500) as "Output" ' +
         'FROM timetable.execution_log l ' +
         'left join timetable.chain c on c.chain_id = l.chain_id ' +
         'left join timetable.task t on t.task_id = l.task_id ' +
         'ORDER BY last_run desc');
         SQLQueryLog.ParamCheck:=False;
         SQLQueryLog.Open;
    finally
    end;
end;

procedure TForm1.SearchExecutionLog(Sender: TObject);
begin
    if not isConnected then Exit;
    if Length(Trim(SearchEdit.Text)) = 0 then Exit;

    {Search the log}
    SQLQueryLog.Close;
    try
         SQLQueryLog.SQL.Clear;
         SQLQueryLog.SQL.Add('SELECT c.chain_name as "Chain Name", t.task_name as "Task Name", l.txid as TxID, ' +
         'l.last_run::timestamp as "Last Run", l.finished::timestamp as "Finished", l.returncode as "Return Code", l.ignore_error as "Ignore Error", ' +
         'l.kind as "Kind", l.command as "Command", left(l.output, 500) as "Output" ' +
         'FROM timetable.execution_log l ' +
         'left join timetable.chain c on c.chain_id = l.chain_id ' +
         'left join timetable.task t on t.task_id = l.task_id ' +
         'WHERE concat(c.chain_name, t.task_name, l.kind, l.command, l.output) ILIKE ''%' + SearchEdit.Text + '%''' +
         'ORDER BY last_run desc');
         SQLQueryLog.ParamCheck:=False;
         SQLQueryLog.Open;
    finally
    end;
end;

procedure TForm1.SearchEditKeyDown(Sender: TObject; var Key: Word;
   Shift: TShiftState);
begin
    if Key = VK_RETURN then SearchExecutionLog(Sender);
end;

procedure TForm1.EditChain(Sender: TObject);
var
   chain_id : integer;
begin
    if not isConnected then Exit;

    {Get chain ID}
    chain_id := DBGridChains.DataSource.DataSet.FieldByName('Chain ID').AsInteger;

    {Show chain edit form}
    Form1.Enabled := False;
    try
       Form3.chain_id := chain_id;
       Form3.ShowModal;
    finally
       Form1.Enabled := True;
    end;
    RefreshGrids(Sender);
end;

procedure TForm1.EditTask(Sender: TObject);
var
    task_id : integer;
begin
    if not isConnected then Exit;

    {Get task ID}
    task_id := DBGridTasks.DataSource.DataSet.FieldByName('Task ID').AsInteger;

    {Show task edit form}
    Form1.Enabled := False;
    try
       Form4.task_id := task_id;
       Form4.ShowModal;
    finally
       Form1.Enabled := True;
    end;
    RefreshGrids(Sender);
end;

procedure TForm1.HelpIpHtmlPanelHotClick(Sender: TObject);
var
    URL : string;
begin
    URL := (Sender as TIpHtmlPanel).HotURL;
    OpenURL(URL);
end;

procedure TForm1.MoveTaskUp(Sender: TObject);
var
    task_id : integer;
    task_name, sql : string;
begin
    if not isConnected then Exit;

    {Get task ID}
    task_id := DBGridTasks.DataSource.DataSet.FieldByName('Task ID').AsInteger;
    task_name := DBGridTasks.DataSource.DataSet.FieldByName('Task Name').AsString;

    {Move task up}
    try
         SQLQueryAdhoc.Close;
         SQLQueryAdhoc.SQL.Clear;
         SQLQueryAdhoc.ParamCheck := true;
         sql := 'SELECT timetable.move_task_up(:task_id);';
         SQLQueryAdhoc.SQL.Add(sql);
         SQLQueryAdhoc.ParamByName('task_id').AsInteger := task_id;
         SQLQueryAdhoc.ExecSQL;
    finally
         SQLQueryAdhoc.Close;
         SQLQueryTasks.Refresh;
         StatusBar1.SimpleText := 'Task ' + task_name + ' [ID ' + IntToStr(task_id) + '] moved up.';
    end;
end;

procedure TForm1.PageControl1Change(Sender: TObject);
begin
    {Refresh selected tab}
    if PageControl1.TabIndex = 0 then RefreshGrids(Sender);
    if PageControl1.TabIndex = 1 then ShowLog(Sender);
end;

procedure TForm1.MoveTaskDown(Sender: TObject);
var
    task_id : integer;
    task_name, sql : string;
begin
    if not isConnected then Exit;

    {Get task ID}
    task_id := DBGridTasks.DataSource.DataSet.FieldByName('Task ID').AsInteger;
    task_name := DBGridTasks.DataSource.DataSet.FieldByName('Task Name').AsString;

    {Move task down}
    try
         SQLQueryAdhoc.Close;
         SQLQueryAdhoc.SQL.Clear;
         SQLQueryAdhoc.ParamCheck := true;
         sql := 'SELECT timetable.move_task_down(:task_id);';
         SQLQueryAdhoc.SQL.Add(sql);
         SQLQueryAdhoc.ParamByName('task_id').AsInteger := task_id;
         SQLQueryAdhoc.ExecSQL;
    finally
         SQLQueryAdhoc.Close;
         SQLQueryTasks.Refresh;
         StatusBar1.SimpleText := 'Task ' + task_name + ' [ID ' + IntToStr(task_id) + '] moved down.';
    end;
end;

procedure TForm1.RunChain(Sender: TObject);
var
    chain_id : integer;
    chain_name : string;
    sql : string;
begin
    if not isConnected then Exit;

    {Get chain ID}
    chain_id := -1;
    chain_id := DBGridChains.DataSource.DataSet.FieldByName('Chain ID').AsInteger;
    chain_name := DBGridChains.DataSource.DataSet.FieldByName('Chain Name').AsString;
    if chain_id <= 0 then Exit;

    if MessageDlg('Run confirmation', 'Are you sure you want to execute the chain [' + chain_name + '] now ?', mtConfirmation, [mbYes, mbNo], 0) = mrNo then Exit;

    {Run chain now}
    try
         SQLQueryAdhoc.Close;
         SQLQueryAdhoc.SQL.Clear;
         SQLQueryAdhoc.ParamCheck := true;
         sql := 'select timetable.notify_chain_start(:chain_id, :worker);';
         SQLQueryAdhoc.SQL.Add(sql);
         SQLQueryAdhoc.ParamByName('chain_id').AsInteger := chain_id;
         SQLQueryAdhoc.ParamByName('worker').AsString := worker;
         SQLQueryAdhoc.ExecSQL;
    finally
         SQLQueryAdhoc.Close;
         StatusBar1.SimpleText := 'Chain ' + chain_name + ' [ID ' + IntToStr(chain_id) + '] has been signalled to execute.';
    end;
    RunChainBitBtn.Enabled := False;
end;

procedure TForm1.StopChain(Sender: TObject);
var
    chain_id : integer;
    chain_name : string;
    sql : string;
begin
    Exit; // notify_chain_stop DOES NOT SEEM TO WORK !
    if not isConnected then Exit;

    {Get chain ID}
    chain_id := -1;
    chain_id := DBGridChains.DataSource.DataSet.FieldByName('Chain ID').AsInteger;
    chain_name := DBGridChains.DataSource.DataSet.FieldByName('Chain Name').AsString;
    if chain_id <= 0 then Exit;

    if MessageDlg('Confirmation', 'Are you sure you want to stop the chain [' + chain_name + '] now ?', mtConfirmation, [mbYes, mbNo], 0) = mrNo then Exit;

    {Stop chain now}
    try
         SQLQueryAdhoc.Close;
         SQLQueryAdhoc.SQL.Clear;
         SQLQueryAdhoc.ParamCheck := true;
         sql := 'select timetable.notify_chain_stop(:chain_id, :worker);';
         SQLQueryAdhoc.SQL.Add(sql);
         SQLQueryAdhoc.ParamByName('chain_id').AsInteger := chain_id;
         SQLQueryAdhoc.ParamByName('worker').AsString := worker;
         SQLQueryAdhoc.ExecSQL;
    finally
         SQLQueryAdhoc.Close;
         StatusBar1.SimpleText := 'Chain ' + chain_name + ' [ID ' + IntToStr(chain_id) + '] has been signalled to stop.';
    end;
    StopChainBitBtn.Enabled := False;
end;

procedure TForm1.AddChain(Sender: TObject);
begin
   if not isConnected then Exit;

   {Show chain edit form}
   Form1.Enabled := False;
   try
      Form3.chain_id := -1; {New chain}
      Form3.ShowModal;
   finally
      Form1.Enabled := True;
   end;
   RefreshGrids(Sender);
end;

procedure TForm1.AddTask(Sender: TObject);
var
    chain_id : integer;
begin
   if not isConnected then Exit;

   {Get chain ID}
   chain_id := DBGridTasks.DataSource.DataSet.FieldByName('Chain ID').AsInteger;

   {Show task edit form}
   Form1.Enabled := False;
   try
      Form4.chain_id := chain_id;
      Form4.task_id := -1; {New task}
      Form4.ShowModal;
   finally
      Form1.Enabled := True;
   end;
   RefreshGrids(Sender);
end;

procedure TForm1.DBGridChainsCellClick(Column: TColumn);
begin
     RefreshChainGridUI(Self);
end;

procedure TForm1.RefreshChainGridUI(Sender: TObject);
var
    Running : string;
begin
   Running := DBGridChains.DataSource.DataSet.FieldByName('Running').AsString;
   if Running = 'Y' then
   begin
        RunChainBitBtn.Enabled := False;
        StopChainBitBtn.Enabled := True;
   end
   else
   begin
       RunChainBitBtn.Enabled := True;
       StopChainBitBtn.Enabled := False;
   end;
end;

procedure TForm1.DeleteChain(Sender: TObject);
var
   chain_name : string;
   sql : string;
begin
   if not isConnected then Exit;

   {Get chain name}
   chain_name := DBGridChains.DataSource.DataSet.FieldByName('Chain Name').AsString;

   if MessageDlg('Delete confirmation', 'Are you sure you want to delete the chain [' + chain_name + '] ?', mtConfirmation, [mbYes, mbNo], 0) = mrNo then Exit;

   {Delete the chain by name}
   {This will also delete all associated tasks and parameters}
   if Length(chain_name) > 0 then
   begin
      try
           SQLQueryAdhoc.Close;
           SQLQueryAdhoc.SQL.Clear;
           SQLQueryAdhoc.ParamCheck := true;
           sql := 'SELECT timetable.delete_job(:chain_name);';
           SQLQueryAdhoc.SQL.Add(sql);
           SQLQueryAdhoc.ParamByName('chain_name').AsString := chain_name;
           SQLQueryAdhoc.ExecSQL;
      finally
           SQLQueryAdhoc.Close;
           SQLQueryChains.Refresh;
           SQLQueryTasks.Refresh;
           StatusBar1.SimpleText := 'Chain ' + chain_name + ' deleted.';
      end;
   end;
end;

procedure TForm1.DeleteTask(Sender: TObject);
var
   task_id : integer;
   task_name : string;
   sql : string;
begin
   if not isConnected then Exit;

   {Get task ID}
   task_name := DBGridTasks.DataSource.DataSet.FieldByName('Task Name').AsString;
   task_id := DBGridTasks.DataSource.DataSet.FieldByName('Task ID').AsInteger;

   if MessageDlg('Delete confirmation', 'Are you sure you want to delete the task [' + task_name + '] ?', mtConfirmation, [mbYes, mbNo], 0) = mrNo then Exit;

   {Delete the task by ID}
   {This will also delete the associated parameter if any}
   if task_id >= 0 then
   begin
      try
           SQLQueryAdhoc.Close;
           SQLQueryAdhoc.SQL.Clear;
           SQLQueryAdhoc.ParamCheck := true;
           sql := 'SELECT timetable.delete_task(:task_id);';
           SQLQueryAdhoc.SQL.Add(sql);
           SQLQueryAdhoc.ParamByName('task_id').AsInteger := task_id;
           SQLQueryAdhoc.ExecSQL;
      finally
           SQLQueryAdhoc.Close;
           RefreshGrids(Sender);
           StatusBar1.SimpleText := 'Task ' + task_name + ' deleted.';
      end;
   end;
end;

procedure TForm1.RefreshGrids(Sender: TObject);
var
   chain_id : integer;
begin
    if not isConnected then Exit;

    {Select the record by chain ID}
    chain_id := DBGridChains.DataSource.DataSet.FieldByName('Chain ID').AsInteger;
    SQLQueryChains.DisableControls;
    SQLQueryChains.Refresh;
    SQLQueryChains.First;
    SQLQueryChains.Locate('Chain ID', chain_id, []);
    SQLQueryChains.EnableControls;
    SQLQueryTasks.Refresh;
end;

procedure TForm1.GridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
   {Refresh grids}
   if Key = VK_F5 then
   begin
       if not isConnected then Exit;
       RefreshGrids(Sender);
   end;

   RefreshChainGridUI(Sender);
end;

procedure TForm1.ToggleUI(Sender: TObject);
begin
     {Change UI based on connection status}
     AddChainBitBtn.Enabled := isConnected;
     EditChainBitBtn.Enabled := isConnected;
     DeleteChainBitBtn.Enabled := isConnected;
     RunChainBitBtn.Enabled := isConnected;
     {StopChainBitBtn.Enabled := isConnected;}

     AddTaskBitBtn.Enabled := isConnected;
     EditTaskBitBtn.Enabled := isConnected;
     DeleteTaskBitBtn.Enabled := isConnected;
     MoveTaskUpBitBtn.Enabled := isConnected;
     MoveTaskDownBitBtn.Enabled := isConnected;

     RefreshLogBitBtn.Enabled := isConnected;
     RefreshGridsBitBtn.Enabled := isConnected;
     SearchEdit.Enabled := isConnected;
     SearchBitBtn.Enabled := isConnected;
end;

end.

