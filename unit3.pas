{------------------------------------------------------------------------------
pg_timetable_gui
Copyright © 2026 John Buoro, Harvey Norman Holdings Limited. All Rights Reserved.
------------------------------------------------------------------------------}

unit Unit3;

{$mode ObjFPC}{$H+}

interface

uses
   Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, DBCtrls,
   StdCtrls, ComCtrls, Buttons, PQConnection, SQLDB, RegExpr, lclintf,
   SynHighlighterSQL, SynEditMarkupHighAll, SynEditTypes, SynEdit;

type

   { TForm3 }

   TForm3 = class(TForm)
      BitBtnClose: TBitBtn;
      BitBtnSave: TBitBtn;
      CheckBoxSelfDestruct: TCheckBox;
      CheckBoxLive: TCheckBox;
      CheckBoxExclusive: TCheckBox;
      CronHelpLabel1: TLabel;
      edCron: TEdit;
      Label1: TLabel;
      Label2: TLabel;
      CronHelpLabel2: TLabel;
      LabeledEditChainName: TLabeledEdit;
      LabeledEditChainID: TLabeledEdit;
      LabeledEditClient: TLabeledEdit;
      LabeledEditMaxInst: TLabeledEdit;
      LabeledEditTimeout: TLabeledEdit;
      lblDayMonth: TLabel;
      lblHour: TLabel;
      lblMinute: TLabel;
      lblMonth: TLabel;
      lblNextRuns: TLabel;
      lblWeekday: TLabel;
      mmRuns: TMemo;
      StatusBar1: TStatusBar;
      SynEditOnError: TSynEdit;
      SynSQLSyn1: TSynSQLSyn;
      procedure BitBtnCloseClick(Sender: TObject);
      procedure CronHelpLabel2Click(Sender: TObject);
      procedure FormCreate(Sender: TObject);
      procedure FormShow(Sender: TObject);
      procedure SaveChain(Sender: TObject);
      procedure ShowCronHelp(Sender: TObject);
      procedure UpdateCronTimes(Sender: TObject);
      function IsCronValueValid(const S: string): boolean;
      function SelectSQL(const sql: string; params: array of string; out Output: string): boolean;
   private

   public
      chain_id : integer;
   end;

var
   Form3: TForm3;
   MarkCaretSynEditOnError : TSynEditMarkupHighlightAllCaret;
   IsCronHelp : boolean = False;

implementation

uses Unit1;

{$R *.lfm}

{ TForm3 }

procedure TForm3.FormCreate(Sender: TObject);
begin
   {Set editor style}
   MarkCaretSynEditOnError := TSynEditMarkupHighlightAllCaret(SynEditOnError.MarkupByClass[TSynEditMarkupHighlightAllCaret]);
   MarkCaretSynEditOnError.MarkupInfo.Background := clYellow;
   MarkCaretSynEditOnError.WaitTime := 10;
   MarkCaretSynEditOnError.SearchOptions := [ssoWholeWord, ssoSelectedOnly, ssoMatchCase];

   {Adjust font colour for certain objects to cope with potential theme changes}
   Form3.CronHelpLabel1.Font.Color := Form1.GetContrastColour(clForm, Form3.CronHelpLabel1.Font.Color);
   Form3.CronHelpLabel2.Font.Color := Form1.GetContrastColour(clForm, Form3.CronHelpLabel2.Font.Color);
end;

procedure TForm3.FormShow(Sender: TObject);
begin
   SynEditOnError.Lines.TextLineBreakStyle := tlbsLF;

   {If new chain}
   if chain_id = -1 then
   begin
     LabeledEditChainID.Text := 'NEW';
     LabeledEditChainName.Text := '';
     CheckBoxLive.Checked := False;
     edCron.Text := '* * * * *';
     LabeledEditClient.Text := '';
     LabeledEditMaxInst.Text := '1';
     CheckBoxSelfDestruct.Checked := False;
     CheckBoxExclusive.Checked := False;
     LabeledEditTimeout.Text := '0';
     Exit;
   end;

   {Modifying instead}
   {Update fields directly from grid}
   LabeledEditChainID.Text := Form1.DataSourceChains.DataSet.FieldByName('Chain ID').AsString;
   LabeledEditChainName.Text := Form1.DataSourceChains.DataSet.FieldByName('Chain Name').AsString;
   CheckBoxLive.Checked := Form1.DataSourceChains.DataSet.FieldByName('Live').AsBoolean;
   edCron.Text := Form1.DataSourceChains.DataSet.FieldByName('Run At').AsString;
   LabeledEditClient.Text := Form1.DataSourceChains.DataSet.FieldByName('Client').AsString;
   LabeledEditMaxInst.Text := Form1.DataSourceChains.DataSet.FieldByName('Max Instances').AsString;
   CheckBoxExclusive.Checked := Form1.DataSourceChains.DataSet.FieldByName('Exclusive').AsBoolean;
   CheckBoxSelfDestruct.Checked := Form1.DataSourceChains.DataSet.FieldByName('Self Destruct').AsBoolean;
   LabeledEditTimeout.Text := Form1.DataSourceChains.DataSet.FieldByName('Timeout (ms)').AsString;

   {Get other fields directly via SQL}
   try
       Form1.SQLQueryAdhoc.SQL.Clear;
       Form1.SQLQueryAdhoc.SQL.Add('SELECT on_error FROM timetable.chain WHERE chain_id = ' + IntToStr(chain_id));
       Form1.SQLQueryAdhoc.ParamCheck := False;
       Form1.SQLQueryAdhoc.Open;
       SynEditOnError.Lines.Text := Form1.SQLQueryAdhoc.FieldByName('on_error').AsString;
   finally
       Form1.SQLQueryAdhoc.Close;
   end;

   UpdateCronTimes(Sender);
end;

procedure TForm3.SaveChain(Sender: TObject);
var
     sql : string;
     i : integer;
     task_id : integer;
begin
   {Insert chain directly via SQL}
   if chain_id = -1 then
   begin
     {Test to see if chain name already exists}
     try
          Form1.SQLQueryAdhoc.Close;
          Form1.SQLQueryAdhoc.SQL.Clear;
          Form1.SQLQueryAdhoc.ParamCheck := true;
          sql := 'SELECT count(1) as cnt FROM timetable.chain WHERE chain_name ILIKE :chain_name';
          Form1.SQLQueryAdhoc.SQL.Add(sql);
          Form1.SQLQueryAdhoc.ParamByName('chain_name').AsString := LabeledEditChainName.Text;
          Form1.SQLQueryAdhoc.Open;
          i := Form1.SQLQueryAdhoc.FieldByName('cnt').AsInteger;
     finally
          Form1.SQLQueryAdhoc.Close;
     end;
     {showmessage('cnt = ' + inttostr(i));}
     if i > 0 then
     begin
          MessageDlg('Insert Chain...', 'Cannot add this chain because the Chain Name [' + LabeledEditChainName.Text + '] already exsits.', mtWarning, [mbOk], 0);
          Exit;
     end
     else
     try
          {Insert the chain}
          Form1.SQLQueryAdhoc.Close;
          Form1.SQLQueryAdhoc.SQL.Clear;
          Form1.SQLQueryAdhoc.ParamCheck := true;
          sql := 'INSERT INTO timetable.chain(chain_name, run_at, max_instances, timeout, live, self_destruct, exclusive_execution, client_name, on_error) VALUES (:chain_name, :run_at, :max_instances, :timeout, :live, :self_destruct, :exclusive_execution, :client_name, :on_error) RETURNING chain_id;';
          Form1.SQLQueryAdhoc.SQL.Add(sql);
          Form1.SQLQueryAdhoc.ParamByName('chain_name').AsString := LabeledEditChainName.Text;
          Form1.SQLQueryAdhoc.ParamByName('live').AsBoolean := CheckBoxLive.Checked;
          Form1.SQLQueryAdhoc.ParamByName('run_at').AsString := edCron.Text;
          Form1.SQLQueryAdhoc.ParamByName('exclusive_execution').AsBoolean := CheckBoxExclusive.Checked;
          Form1.SQLQueryAdhoc.ParamByName('self_destruct').AsBoolean := CheckBoxSelfDestruct.Checked;
          Form1.SQLQueryAdhoc.ParamByName('timeout').AsInteger := StrToIntDef(LabeledEditTimeout.Text, 0);

          if Length(Trim(LabeledEditClient.Text)) = 0 then
             Form1.SQLQueryAdhoc.ParamByName('client_name').Value := null
          else
             Form1.SQLQueryAdhoc.ParamByName('client_name').AsString := LabeledEditClient.Text;

          if Length(Trim(SynEditOnError.Lines.Text)) = 0 then
             Form1.SQLQueryAdhoc.ParamByName('on_error').Value := null
          else
             Form1.SQLQueryAdhoc.ParamByName('on_error').AsString := SynEditOnError.Lines.Text;

          if LabeledEditMaxInst.Text = '' then
             Form1.SQLQueryAdhoc.ParamByName('max_instances').Value := null
          else
             Form1.SQLQueryAdhoc.ParamByName('max_instances').AsInteger := StrToInt(LabeledEditMaxInst.Text);

          Form1.SQLQueryAdhoc.Open;
          chain_id := Form1.SQLQueryAdhoc.FieldByName('chain_id').AsInteger;
          LabeledEditChainID.Text := IntToStr(chain_id);
          {showmessage('chain_id = ' + IntToStr(chain_id));}

          {Insert a default task}
          Form1.SQLQueryAdhoc.Close;
          Form1.SQLQueryAdhoc.SQL.Clear;
          Form1.SQLQueryAdhoc.ParamCheck := true;
          sql := 'INSERT INTO timetable.task (chain_id, task_order, task_name, kind, command) VALUES (:chain_id, 10, ''No Op'', ''BUILTIN'', ''NoOp'') RETURNING task_id;';
          Form1.SQLQueryAdhoc.SQL.Add(sql);
          Form1.SQLQueryAdhoc.ParamByName('chain_id').AsInteger := chain_id;
          Form1.SQLQueryAdhoc.Open;
          task_id := Form1.SQLQueryAdhoc.FieldByName('task_id').AsInteger;
          {showmessage('task_id = ' + IntToStr(task_id));}
     finally
          Form1.SQLQueryAdhoc.Close;
          StatusBar1.SimpleText := 'Record added.';
          Close;
     end;
   end

   {Update chain directly via SQL}
   else if chain_id <> -1 then
   begin
     try
          Form1.SQLQueryAdhoc.Close;
          Form1.SQLQueryAdhoc.SQL.Clear;
          Form1.SQLQueryAdhoc.ParamCheck := true;
          sql := 'UPDATE timetable.chain SET chain_name = :chain_name, run_at = :run_at, max_instances = :max_instances, timeout = :timeout, live = :live, self_destruct = :self_destruct, exclusive_execution = :exclusive_execution, client_name = :client_name, on_error = :on_error WHERE chain_id = ' + IntToStr(chain_id);
          Form1.SQLQueryAdhoc.SQL.Add(sql);
          Form1.SQLQueryAdhoc.ParamByName('chain_name').AsString := LabeledEditChainName.Text;
          Form1.SQLQueryAdhoc.ParamByName('live').AsBoolean := CheckBoxLive.Checked;
          Form1.SQLQueryAdhoc.ParamByName('run_at').AsString := edCron.Text;
          Form1.SQLQueryAdhoc.ParamByName('exclusive_execution').AsBoolean := CheckBoxExclusive.Checked;
          Form1.SQLQueryAdhoc.ParamByName('self_destruct').AsBoolean := CheckBoxSelfDestruct.Checked;
          Form1.SQLQueryAdhoc.ParamByName('timeout').AsInteger := StrToIntDef(LabeledEditTimeout.Text, 0);

          if Length(Trim(LabeledEditClient.Text)) = 0 then
             Form1.SQLQueryAdhoc.ParamByName('client_name').Value := null
          else
             Form1.SQLQueryAdhoc.ParamByName('client_name').AsString := LabeledEditClient.Text;

          if Length(Trim(SynEditOnError.Lines.Text)) = 0 then
             Form1.SQLQueryAdhoc.ParamByName('on_error').Value := null
          else
             Form1.SQLQueryAdhoc.ParamByName('on_error').AsString := SynEditOnError.Lines.Text;

          if LabeledEditMaxInst.Text = '' then
             Form1.SQLQueryAdhoc.ParamByName('max_instances').Value := null
          else
             Form1.SQLQueryAdhoc.ParamByName('max_instances').AsInteger := StrToInt(LabeledEditMaxInst.Text);

          Form1.SQLQueryAdhoc.ExecSQL;
     finally
          Form1.SQLQueryAdhoc.Close;
          StatusBar1.SimpleText := 'Record updated.';
          Close;
     end;
   end;
end;

procedure TForm3.ShowCronHelp(Sender: TObject);
begin
   if not IsCronHelp then
   begin
      mmRuns.Clear;
      mmRuns.Append('CRON HELP:');
      mmRuns.Append('');
      mmRuns.Append('Example: Daily at 04:45:');
      mmRuns.Append('45 4 * * *');
      mmRuns.Append('Example: Every 5 minutes:');
      mmRuns.Append('*/5 * * * *');
      mmRuns.Append('@every 5 minutes');
      mmRuns.Append('Example: After 1 hour:');
      mmRuns.Append('@after 1 hour');
      mmRuns.Append('Example: Execute after pg_timetable restarts:');
      mmRuns.Append('@reboot');
      IsCronHelp := True;
   end
   else
   begin
      IsCronHelp := False;
      UpdateCronTimes(Sender);
   end;
end;

procedure TForm3.BitBtnCloseClick(Sender: TObject);
begin
     Close;
end;

procedure TForm3.CronHelpLabel2Click(Sender: TObject);
begin
     OpenURL('https://crontab.guru');
end;

{Code taken from https://github.com/cybertec-postgresql/pg_timetable_gui (Pavlo Golub)}
procedure TForm3.UpdateCronTimes(Sender: TObject);
var
  ValidCron: boolean;
  S: string;
  Output: string;
const
  cronRE          = '^(((\d+,)+\d+|(\d+(\/|-)\d+)|(\*(\/|-)\d+)|\d+|\*) +){4}'+
                    '(((\d+,)+\d+|(\d+(\/|-)\d+)|(\*(\/|-)\d+)|\d+|\*) ?)$';
  sqlCronRuns     = 'SELECT to_char(r.r, ''FMDay, FMDD FMMon YYYY at HH24:MI:SS'') FROM '+
                    'generate_series(now(), now() + 10 * :cron :: interval, :cron :: interval) AS r(r) LIMIT 10';
  sqlIntervalRuns = 'SELECT to_char(r.r, ''FMDay, FMDD FMMon YYYY at HH24:MI:SS'') FROM '+
                    'timetable.cron_runs(now(), :cron) AS r(r) LIMIT 10';
  minIntervalLen  = length('@every '); // @ modifier and at least one space char
begin
  S := edCron.Text;
  ValidCron := S.Trim() = '@reboot';
  if not ValidCron then
    if S.StartsWith('@every ') or S.StartsWith('@after ') then //special values
      ValidCron := (S.Length > minIntervalLen)
                   and IsCronValueValid(S)
                   and SelectSQL(sqlCronRuns, [S.Substring(minIntervalLen)], Output)
  else
    with TRegExpr.Create(cronRE) do
    try
      ValidCron := Exec(S) and SelectSQL(sqlIntervalRuns, [S], Output);
    finally
      Free();
    end;
  mmRuns.Text := Output;
  if ValidCron then edCron.Color := clDefault else edCron.Color := clRed;
end;

{Code taken from https://github.com/cybertec-postgresql/pg_timetable_gui (Pavlo Golub)}
function TForm3.IsCronValueValid(const S: string): boolean;
var
  Q: TSQLQuery;
begin
  Result := True;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := Form1.PQConnection1;
    Q.SQL.Text := 'SELECT CAST(:cron AS timetable.cron)';
    Q.ParamByName('cron').AsString := S;
    try
      Q.Open;
    except
      Exit(False);
    end;
    Q.Close;
  finally
    FreeAndNil(Q);
  end;
end;

{Code taken from https://github.com/cybertec-postgresql/pg_timetable_gui (Pavlo Golub)}
function TForm3.SelectSQL(const sql: string; params: array of string; out Output: string): boolean;
var
  Q: TSQLQuery;
  i: Integer;
begin
  Result := True;
  Output := '';
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := Form1.PQConnection1;
    Q.SQL.Text := sql;
    for i := Low(params) to High(params) do
      Q.Params[i].AsString := params[i];
    try
      Q.Open;
      while not Q.EOF do
      begin
        Output := Output + Q.Fields[0].AsString + LineEnding;
        Q.Next;
      end;
    except
      on E: Exception do
      begin
        Result := False;
        if E is EPQDatabaseError then
          Output := EPQDatabaseError(E).MESSAGE_PRIMARY
        else
          Output := E.Message;
      end;
    end;
    Q.Close;
  finally
    FreeAndNil(Q);
  end;
end;

end.

