{------------------------------------------------------------------------------
pg_timetable_gui
Copyright © 2026 John Buoro, Harvey Norman Holdings Limited. All Rights Reserved.
------------------------------------------------------------------------------}

unit Unit4;

{$mode ObjFPC}{$H+}

interface

uses
   Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
   Buttons, SynEdit, SynHighlighterJScript, synhighlighterunixshellscript,
   SynHighlighterSQL, SynEditMarkupHighAll, SynEditTypes,
   lclintf, ComCtrls;

type

   { TForm4 }

   TForm4 = class(TForm)
      BitBtnClose: TBitBtn;
      BitBtnSave: TBitBtn;
      CheckBoxAutonomous: TCheckBox;
      CheckBoxIgnoreError: TCheckBox;
      ComboBoxKind: TComboBox;
      ComboBoxCommandBuiltin: TComboBox;
      CommandBuiltinLabel: TLabel;
      BuiltinHelpLabel: TLabel;
      LabeledEditRunAs: TLabeledEdit;
      LabeledEditTaskOrder: TLabeledEdit;
      LabelParameter: TLabel;
      LabeledEditDbConnString: TLabeledEdit;
      StatusBar1: TStatusBar;
      SynEditCommand: TSynEdit;
      SynJScriptSyn1: TSynJScriptSyn;
      SynSQLSyn1: TSynSQLSyn;
      SynUNIXShellScriptSyn1: TSynUNIXShellScriptSyn;
      LabeledEditChainID: TLabeledEdit;
      LabeledEditTaskID: TLabeledEdit;
      LabeledEditTaskName: TLabeledEdit;
      LabeledEditTimeout: TLabeledEdit;
      KindLabel: TLabel;
      SynEditParameters: TSynEdit;
      procedure BitBtnCloseClick(Sender: TObject);
      procedure FormCreate(Sender: TObject);
      procedure FormShow(Sender: TObject);
      procedure HelpBuiltin(Sender: TObject);
      procedure OnChangeKind(Sender: TObject);
      procedure SaveTask(Sender: TObject);
   private

   public
      chain_id : integer;
      task_id : integer;
   end;

var
   Form4: TForm4;
   MarkCaretSynEditCommand : TSynEditMarkupHighlightAllCaret;
   MarkCaretSynEditParameters : TSynEditMarkupHighlightAllCaret;

implementation

uses Unit1;

{$R *.lfm}

{ TForm4 }

procedure TForm4.BitBtnCloseClick(Sender: TObject);
begin
   Close
end;

procedure TForm4.FormCreate(Sender: TObject);
begin
   {Limit form minimum size}
   Form4.Constraints.MinWidth := Form4.Width;
   Form4.Constraints.MinHeight := Form4.Height;

   {Set editor style}
   SynEditCommand.Lines.TextLineBreakStyle := tlbsLF;
   SynEditParameters.Lines.TextLineBreakStyle := tlbsLF;

   MarkCaretSynEditCommand := TSynEditMarkupHighlightAllCaret(SynEditCommand.MarkupByClass[TSynEditMarkupHighlightAllCaret]);
   MarkCaretSynEditCommand.MarkupInfo.Background := clYellow;
   MarkCaretSynEditCommand.WaitTime := 10;
   MarkCaretSynEditCommand.SearchOptions := [ssoWholeWord, ssoSelectedOnly, ssoMatchCase];

   MarkCaretSynEditParameters := TSynEditMarkupHighlightAllCaret(SynEditParameters.MarkupByClass[TSynEditMarkupHighlightAllCaret]);
   MarkCaretSynEditParameters.MarkupInfo.Background := clYellow;
   MarkCaretSynEditParameters.WaitTime := 10;
   MarkCaretSynEditParameters.SearchOptions := [ssoWholeWord, ssoSelectedOnly, ssoMatchCase];
end;

procedure TForm4.FormShow(Sender: TObject);
var
   sql : string;
   max_task_order : integer;
begin
   {If new task}
   if task_id = -1 then
   begin
      {Get highest task_order}
      try
          Form1.SQLQueryAdhoc.Close;
          Form1.SQLQueryAdhoc.SQL.Clear;
          Form1.SQLQueryAdhoc.ParamCheck := true;
          sql := 'SELECT max(task_order) + 10 as max_task_order FROM timetable.task WHERE chain_id = :chain_id';
          Form1.SQLQueryAdhoc.SQL.Add(sql);
          Form1.SQLQueryAdhoc.ParamByName('chain_id').AsInteger := chain_id;
          Form1.SQLQueryAdhoc.Open;
          max_task_order := Form1.SQLQueryAdhoc.FieldByName('max_task_order').AsInteger;
      finally
          Form1.SQLQueryAdhoc.Close;
      end;

      {Populate with default values}
      LabeledEditChainID.Text := IntToStr(chain_id);
      LabeledEditTaskID.Text := 'NEW';
      LabeledEditTaskOrder.Text := IntToStr(max_task_order);
      LabeledEditTaskName.Text := '';
      CheckBoxIgnoreError.Checked := False;
      CheckBoxAutonomous.Checked := False;
      LabeledEditRunAs.Text := '';
      LabeledEditDbConnString.Text := '';
      LabeledEditTimeout.Text := '0';
      ComboBoxKind.Text := 'SQL';
      ComboBoxCommandBuiltin.Text := 'NoOp';
      SynEditCommand.Lines.Text := '';
      SynEditParameters.Lines.Text := '';
      Exit;
   end;

   {Modifying instead}
   {Update fields directly from grid}
   LabeledEditChainID.Text := Form1.DataSourceTasks.DataSet.FieldByName('Chain ID').AsString;
   LabeledEditTaskID.Text := Form1.DataSourceTasks.DataSet.FieldByName('Task ID').AsString;
   LabeledEditTaskName.Text := Form1.DataSourceTasks.DataSet.FieldByName('Task Name').AsString;
   LabeledEditTaskOrder.Text := Form1.DataSourceTasks.DataSet.FieldByName('Task Order').AsString;
   CheckBoxIgnoreError.Checked := Form1.DataSourceTasks.DataSet.FieldByName('Ignore Error').AsBoolean;
   CheckBoxAutonomous.Checked := Form1.DataSourceTasks.DataSet.FieldByName('Autonomous').AsBoolean;
   LabeledEditRunAs.Text := Form1.DataSourceTasks.DataSet.FieldByName('Run As').AsString;
   LabeledEditDbConnString.Text := Form1.DataSourceTasks.DataSet.FieldByName('Connection String').AsString;
   LabeledEditTimeout.Text := Form1.DataSourceTasks.DataSet.FieldByName('Timeout (ms)').AsString;
   ComboBoxKind.Text := Form1.DataSourceTasks.DataSet.FieldByName('Task Kind').AsString;
   if ComboBoxKind.Text = 'BUILTIN' then
   begin
   ComboBoxCommandBuiltin.Text := Form1.DataSourceTasks.DataSet.FieldByName('Command').AsString;
   end
   else
   begin
      SynEditCommand.Lines.Text := Form1.DataSourceTasks.DataSet.FieldByName('Command').AsString;
   end;

   {Get other fields directly via SQL}
   try
        Form1.SQLQueryAdhoc.SQL.Clear;
        Form1.SQLQueryAdhoc.ParamCheck := True;
        Form1.SQLQueryAdhoc.SQL.Add('SELECT command, jsonb_pretty(value) as param_value from timetable.task t left join timetable.parameter p on t.task_id = p.task_id WHERE t.task_id = :task_id');
        Form1.SQLQueryAdhoc.ParamByName('task_id').AsInteger := task_id;
        Form1.SQLQueryAdhoc.Open;
        SynEditCommand.Lines.Text := Form1.SQLQueryAdhoc.FieldByName('command').AsString;
        SynEditParameters.Lines.Text := Form1.SQLQueryAdhoc.FieldByName('param_value').AsString;
   finally
        Form1.SQLQueryAdhoc.Close;
   end;

   {Update UI}
   OnChangeKind(Sender);
end;

procedure TForm4.HelpBuiltin(Sender: TObject);
begin
   OpenURL('https://cybertec-postgresql.github.io/pg_timetable/v6.x/components/');
end;

procedure TForm4.OnChangeKind(Sender: TObject);
begin
   {Change the command fields based upon Kind}
   if ComboBoxKind.Text = 'BUILTIN' then
   begin
        SynEditCommand.Visible := False;
        ComboBoxCommandBuiltin.Visible := True;
        BuiltinHelpLabel.Visible := True;
        SynEditParameters.Highlighter := SynJScriptSyn1;
   end
   else
   if ComboBoxKind.Text = 'PROGRAM' then
   begin
        SynEditCommand.Visible := True;
        ComboBoxCommandBuiltin.Visible := False;
        BuiltinHelpLabel.Visible := False;
        SynEditCommand.Highlighter := SynUNIXShellScriptSyn1;
        SynEditCommand.Hint := 'Command to execute. Can be external program.';
        SynEditParameters.Highlighter := SynUNIXShellScriptSyn1;
   end
   else
   if ComboBoxKind.Text = 'SQL' then
   begin
        SynEditCommand.Visible := True;
        ComboBoxCommandBuiltin.Visible := False;
        BuiltinHelpLabel.Visible := False;
        SynEditCommand.Highlighter := SynSQLSyn1;
        SynEditCommand.Hint := 'SQL to execute.';
        SynEditParameters.Highlighter := SynJScriptSyn1;
   end;
end;

procedure TForm4.SaveTask(Sender: TObject);
var
   sql : string;
   ParameterExists : boolean = false;
   isError : boolean = false;
begin
   //TODO: Does Command work with path C:\temp\ or c:\\temp\\ ?

   {Insert task directly via SQL}
   if task_id = -1 then
   begin
     try
          {Insert the chain}
          Form1.SQLQueryAdhoc.Close;
          Form1.SQLQueryAdhoc.SQL.Clear;
          Form1.SQLQueryAdhoc.ParamCheck := true;
          sql := 'INSERT INTO timetable.task (chain_id, task_order, task_name, kind, command, run_as, database_connection, ignore_error, autonomous, timeout) VALUES (:chain_id, :task_order, :task_name, ' + QuotedStr(ComboBoxKind.Text) + ', :command, :run_as, :database_connection, :ignore_error, :autonomous, :timeout) RETURNING task_id;';
          Form1.SQLQueryAdhoc.SQL.Add(sql);
          Form1.SQLQueryAdhoc.ParamByName('chain_id').AsInteger := chain_id;
          Form1.SQLQueryAdhoc.ParamByName('task_order').AsInteger := StrToInt(LabeledEditTaskOrder.Text);
          Form1.SQLQueryAdhoc.ParamByName('ignore_error').AsBoolean := CheckBoxIgnoreError.Checked;
          Form1.SQLQueryAdhoc.ParamByName('autonomous').AsBoolean := CheckBoxAutonomous.Checked;
          Form1.SQLQueryAdhoc.ParamByName('timeout').AsInteger := StrToIntDef(LabeledEditTimeout.Text, 0);

          if ComboBoxKind.Text = 'BUILTIN' then
             Form1.SQLQueryAdhoc.ParamByName('command').AsString := ComboBoxCommandBuiltin.Text
          else
             Form1.SQLQueryAdhoc.ParamByName('command').AsString := SynEditCommand.Lines.Text;

          if Length(Trim(LabeledEditTaskName.Text)) = 0 then
             Form1.SQLQueryAdhoc.ParamByName('task_name').Value := null
          else
             Form1.SQLQueryAdhoc.ParamByName('task_name').AsString := LabeledEditTaskName.Text;

          if Length(Trim(LabeledEditRunAs.Text)) = 0 then
             Form1.SQLQueryAdhoc.ParamByName('run_as').Value := null
          else
             Form1.SQLQueryAdhoc.ParamByName('run_as').AsString := LabeledEditRunAs.Text;

          if Length(Trim(LabeledEditDbConnString.Text)) = 0 then
             Form1.SQLQueryAdhoc.ParamByName('database_connection').Value := null
          else
             Form1.SQLQueryAdhoc.ParamByName('database_connection').AsString := LabeledEditDbConnString.Text;

          Form1.SQLQueryAdhoc.Open;
          task_id := Form1.SQLQueryAdhoc.FieldByName('task_id').AsInteger;
          LabeledEditTaskID.Text := IntToStr(task_id);
          {showmessage('task_id = ' + IntToStr(task_id));}

          {Insert a parameter}
          if Length(Trim(SynEditParameters.Lines.Text)) > 0 then
          begin
             Form1.SQLQueryAdhoc.Close;
             Form1.SQLQueryAdhoc.SQL.Clear;
             Form1.SQLQueryAdhoc.ParamCheck := true;
             sql := 'INSERT INTO timetable.parameter (task_id, order_id, value) VALUES (:task_id, 1, ' + QuotedStr(SynEditParameters.Lines.Text) + ' ::jsonb);';
             Form1.SQLQueryAdhoc.SQL.Add(sql);
             Form1.SQLQueryAdhoc.ParamByName('task_id').AsInteger := task_id;

             try
                Form1.SQLQueryAdhoc.ExecSQL;
             except
                isError := true;
             end;
          end;
     finally
          Form1.SQLQueryAdhoc.Close;
          if not isError then
          begin
               StatusBar1.SimpleText := 'Record added.';
               Close;
          end;
     end;
   end

   {Update task directly via SQL}
   else if task_id <> -1 then
   begin
        {Update the task}
        try
            Form1.SQLQueryAdhoc.Close;
            Form1.SQLQueryAdhoc.SQL.Clear;
            Form1.SQLQueryAdhoc.ParamCheck := true;
            sql := 'UPDATE timetable.task SET task_name = :task_name, kind = ' + QuotedStr(ComboBoxKind.Text) + ', command = :command, run_as = :run_as, database_connection = :database_connection, ignore_error = :ignore_error, autonomous = :autonomous, timeout = :timeout WHERE task_id = :task_id;';
            Form1.SQLQueryAdhoc.SQL.Add(sql);
            Form1.SQLQueryAdhoc.ParamByName('task_id').AsInteger := task_id;
            Form1.SQLQueryAdhoc.ParamByName('ignore_error').AsBoolean := CheckBoxIgnoreError.Checked;
            Form1.SQLQueryAdhoc.ParamByName('autonomous').AsBoolean := CheckBoxAutonomous.Checked;
            Form1.SQLQueryAdhoc.ParamByName('timeout').AsInteger := StrToIntDef(LabeledEditTimeout.Text, 0);

            if ComboBoxKind.Text = 'BUILTIN' then
               Form1.SQLQueryAdhoc.ParamByName('command').AsString := ComboBoxCommandBuiltin.Text
            else
               Form1.SQLQueryAdhoc.ParamByName('command').AsString := SynEditCommand.Lines.Text;

            if Length(Trim(LabeledEditTaskName.Text)) = 0 then
               Form1.SQLQueryAdhoc.ParamByName('task_name').Value := null
            else
              Form1.SQLQueryAdhoc.ParamByName('task_name').AsString := LabeledEditTaskName.Text;

            if Length(Trim(LabeledEditRunAs.Text)) = 0 then
               Form1.SQLQueryAdhoc.ParamByName('run_as').Value := null
            else
               Form1.SQLQueryAdhoc.ParamByName('run_as').AsString := LabeledEditRunAs.Text;

            if Length(Trim(LabeledEditDbConnString.Text)) = 0 then
               Form1.SQLQueryAdhoc.ParamByName('database_connection').Value := null
            else
               Form1.SQLQueryAdhoc.ParamByName('database_connection').AsString := LabeledEditDbConnString.Text;

            try
               Form1.SQLQueryAdhoc.ExecSQL;
            except
               isError := true;
            end;
        finally
            Form1.SQLQueryAdhoc.Close;
        end;

        {Does a parameter record exist?}
        try
             Form1.SQLQueryAdhoc.Close;
             Form1.SQLQueryAdhoc.SQL.Clear;
             Form1.SQLQueryAdhoc.ParamCheck := true;
             sql := 'SELECT * FROM timetable.parameter WHERE task_id = :task_id';
             Form1.SQLQueryAdhoc.SQL.Add(sql);
             Form1.SQLQueryAdhoc.ParamByName('task_id').AsInteger := task_id;
             Form1.SQLQueryAdhoc.Open;
             if Form1.SQLQueryAdhoc.RowsAffected > 0 then ParameterExists := true;
        finally
             Form1.SQLQueryAdhoc.Close;
        end;

        {Update the parameter}
        try
             Form1.SQLQueryAdhoc.Close;
             Form1.SQLQueryAdhoc.SQL.Clear;
             Form1.SQLQueryAdhoc.ParamCheck := true;

             {No\empty parameter - so delete if it exists}
             if Length(Trim(SynEditParameters.Lines.Text)) = 0 then
             begin
                sql := 'DELETE FROM timetable.parameter WHERE task_id = :task_id';
                Form1.SQLQueryAdhoc.SQL.Add(sql);
             end
             else
             begin
                if ParameterExists then
                   sql := 'UPDATE timetable.parameter SET value = ' + QuotedStr(SynEditParameters.Lines.Text) + ' ::jsonb WHERE task_id = :task_id'
                else
                   sql := 'INSERT INTO timetable.parameter (task_id, order_id, value) VALUES (:task_id, 1, ' + QuotedStr(SynEditParameters.Lines.Text) + ' ::jsonb);';

                Form1.SQLQueryAdhoc.SQL.Add(sql);
             end;
             Form1.SQLQueryAdhoc.ParamByName('task_id').AsInteger := task_id;

             try
                Form1.SQLQueryAdhoc.ExecSQL;
             except
                isError := true;
             end;
        finally
             Form1.SQLQueryAdhoc.Close;
             if not isError then
             begin
                  StatusBar1.SimpleText := 'Record updated.';
                  Close;
             end;
        end;
   end;
end;

end.

