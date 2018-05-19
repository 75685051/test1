unit mFunc;           {功能函数}
interface
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, comctrls,
  Dialogs, StrUtils, StdCtrls, MMSystem, ShlObj, CodeSiteLogging;  //

  procedure f_ShowTS(mmTS:String);
  function  f_YesOrNo(mmTS:String; mmDefault:Boolean):Boolean;
  function  f_PathStr(mmPath:String):String;
  function  fAdd0Num(aNum:Integer; aLen: Integer): string;
  function  f_RandomizeNum(mmLen:Integer):String;
  function  fRoundFloat(f:double; i:integer) : double;
  function  f_PWGenerate(aLen:Integer=8):String;
  procedure SPstr(Source,Deli:string; var StringList :TStringList);
  function  fGetStrCounts(ASubStr, AStr: string): Integer;
  function  fNowStr():String;
  function  fDiffNum():Integer;
  function  SelectFolderDialog(const Handle:integer; const Caption:string; const InitFolder:string; var SelectedFolder:string):boolean;
  function  fGetFileVersion(FileName: string): string;
  function  fSetMyDateFormat() : String;
  //function fEnumComPorts(var aStrList: TStringList):String;
  //function fSetFont(aForm:TForm):Boolean;
  //function fCountChar(aStr:String):Integer;

  procedure fFmtDateDTP(aDTPStart,aDTPEnd:TDateTimePicker; aDateTime:TDateTime);
  procedure fDTPsetDateTime(aDTP:TDateTimePicker; aDstr:String);   
  procedure f_dtpChangeTime(mmSender:TObject);
  function  fAddMemoInfo(aMemo:TMemo; aInfo:String):String;
  function  fLoadFileToList(aFile:String; var aList:TStringList; aNoSpace:Boolean=true) : String;
  function  fWriteFLine(aFName,aStr:String; var aEStr:String):boolean;

  function  f_CodeSiteDest(AHost:String; APort:Integer):Boolean;
implementation
const
  cMsgTitle = 'Message';    //提示框标题
var
  mDiffNum       : Integer=0;
  //mCodeSiteCount : Integer=0;
  //mOnlySignFlag  : Integer=0;

{提示信息框}
procedure f_ShowTS(mmTS:String);
begin
  Application.MessageBox(PChar(mmTS),cMsgTitle,MB_TOPMOST+MB_ICONWARNING+MB_OK);
end;

{Yes Or No信息框}
function f_YesOrNo(mmTS:String; mmDefault:Boolean):Boolean;
begin
  if mmDefault then begin
    if Application.MessageBox(Pchar(mmTS),cMsgTitle,MB_TOPMOST + MB_ICONINFORMATION + MB_YESNO)=6 then result:=True
    else result := False;
  end else begin
    if Application.MessageBox(Pchar(mmTS),cMsgTitle,MB_TOPMOST + MB_ICONINFORMATION + MB_YESNO + MB_DEFBUTTON2)=6 then result:=True
    else result := False;
  end;
end;

{路径字串后加 \}
function f_PathStr(mmPath:String):String;
begin
  if RightStr(mmPath,1)<>'\' then result:=trim(mmPath + '\')
  else result:=trim(mmPath);
end;

{格式化数字长度,不足长的前补0}
function fAdd0Num(aNum:Integer; aLen: Integer): string;
begin
  result := intToStr(aNum);
  while Length(result) < aLen do result := '0' + result;
end;

{产生一个随机数字字符串,使用前要Randomize}
function f_RandomizeNum(mmLen:Integer):String;
var
  i:Integer;
  mmS:String;
begin
  mmS := '0123456789';
  Result := '';
  for i := 0 to mmLen-1 do
    Result := Result + mmS[Random(Length(mmS)-1)+1];
end;

{四舍五入}
function fRoundFloat(f:double; i:integer) : double;
var
  s:string;
  ef:extended;
begin
  s  := '#.'+ StringOfChar('0',i);
  ef := StrToFloat(FloatToStr(f));//防止浮点运算的误差
  result:=StrToFloat(FormatFloat(s,ef));
end;

{产生指定位的随机字符串,使用前要Randomize}
function f_PWGenerate(aLen:Integer=8):String;
var
  i:Integer;
  mmS:String;
begin
  mmS := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'+ 'abcdefghijklmnopqrstuvwxyz'+ '0123456789';
  mmS := mmS +'+-)(*&^%$#@![]{}\~`';
  Result := '';
  for i := 0 to aLen-1 do Result := Result + mmS[Random(Length(mmS)-1)+1];
end;

//自定义分隔字符串: Delphi自带的Delimiter有Bug,空格会被当成分隔符,空串会被忽略
procedure SPstr(Source,Deli:string; var StringList :TStringList);
var
  mmEndOfCurrentString: Integer;
begin
  if  StringList = nil then exit;
  StringList.Clear;
  while Pos(Deli, Source)>0 do begin
    mmEndOfCurrentString := Pos(Deli, Source);
    StringList.add(Copy(Source, 1, mmEndOfCurrentString - 1));
    Source := Copy(Source, mmEndOfCurrentString + length(Deli), length(Source) - mmEndOfCurrentString);
  end;
  StringList.Add(source);
end;

//判断指定的内容在字符串中出现的次数
function fGetStrCounts(ASubStr, AStr: string): Integer;
var
  i: Integer;
begin
  Result := 0;
  i := 1;
  while PosEx(ASubStr, AStr, i) <> 0 do begin
    Inc(Result);
    i := PosEx(ASubStr, AStr, i) + 1;
  end;
end;

{返回当前时间的字符串}
function fNowStr():String;
begin
  result := formatdatetime('yyyy-MM-dd HH:mm:ss',now);    //19位
end;

//返回不同的数值(递增)
function fDiffNum():Integer;
begin
  inc(mDiffNum);
  result := mDiffNum;
end;

{设置调试信息输出的机器}
function f_CodeSiteDest(AHost:String; APort:Integer):Boolean;
begin
  result := true;
  if uppercase(trim(AHost))<>'LOCALHOST' then begin
    CodeSite.Destination := TCodeSiteDestination.Create(nil);
    try
      CodeSite.Destination.TCP.Host   := trim(AHost);
      CodeSite.Destination.TCP.Port   := APort;
      CodeSite.Destination.TCP.Active := true;
    except
      result := false;
    end;
  end
end;

{SHBrowseForFolder执行时的回调函数,
截取BFFM_INITIALIZED消息,在目录选择对话框初始化时向对话框发送一个BFFM_SETSELECTION消息,选中默认的目录}
function BrowseCallbackProc(Wnd: HWND; uMsg: UINT; lParam, lpData: LPARAM): Integer stdcall;
begin
  case uMsg of
    BFFM_INITIALIZED: SendMessage(Wnd, BFFM_SETSELECTION, 1, lpData);
  end;
  Result := 0;
end;
{显示选择文件夹对话框 (有新建按钮) uses ShlObj}
function SelectFolderDialog(const Handle:integer; const Caption:string; const InitFolder:string; var SelectedFolder:string):boolean;
var
  BInfo: _browseinfoA;
  Buffer: array[0..MAX_PATH] of Char;
  ID: IShellFolder;
  Eaten, Attribute: Cardinal;
  ItemID: PItemidlist;
begin
  result := false;
  try
    BInfo.HwndOwner := Handle;
    BInfo.lpfn      := BrowseCallbackProc;          //回调函数
    BInfo.lParam    := Integer(PChar(InitFolder));  //初始目录
    BInfo.lpszTitle := Pchar(Caption);
    BInfo.ulFlags   := BIF_RETURNONLYFSDIRS+BIF_NEWDIALOGSTYLE;
    SHGetDesktopFolder(ID); //获得桌面文件夹的IShellFolder接口
    ID.ParseDisplayName(0,nil,'\',Eaten,ItemID,Attribute);
    BInfo.pidlRoot  := ItemID;
    GetMem(BInfo.pszDisplayName, MAX_PATH);
    try
      if SHGetPathFromIDList(SHBrowseForFolder(BInfo), Buffer) then begin
        SelectedFolder := Buffer;
        //if Length(SelectedFolder)<>3 then SelectedFolder := SelectedFolder;
        SelectedFolder := f_PathStr(SelectedFolder);
        result := True;
      end else begin
        SelectedFolder := '';
        result := False;
      end;
    finally
      FreeMem(BInfo.pszDisplayName);
    end;
  except
  end;
end;

{获取版本信息}
function fGetFileVersion(FileName: string): string;
type
  PVerInfo = ^TVS_FIXEDFILEINFO;
  TVS_FIXEDFILEINFO = record
    dwSignature     : longint;
    dwStrucVersion  : longint;
    dwFileVersionMS : longint;
    dwFileVersionLS : longint;
    dwFileFlagsMask : longint;
    dwFileFlags     : longint;
    dwFileOS        : longint;
    dwFileType      : longint;
    dwFileSubtype   : longint;
    dwFileDateMS    : longint;
    dwFileDateLS    : longint;
  end;
var
  mmExeNames  : array[0..255] of char;
  mmVerInfo   : PVerInfo;
  mmBuf       : pointer;
  mmSz        : word;
  mmL, mmLen  : Cardinal;
begin
  result := '??.??';
  try
    StrPCopy(mmExeNames, FileName);
    mmSz := GetFileVersionInfoSize(mmExeNames, mmL);
    if mmSz=0 then exit;

    GetMem(mmBuf, mmSz);
    try
      GetFileVersionInfo(mmExeNames, 0, mmSz, mmBuf);
      if VerQueryValue(mmBuf, '\', Pointer(mmVerInfo), mmLen) then result := Format('%d.%d.%d.%d',
        [HIWORD(mmVerInfo.dwFileVersionMS), LOWORD(mmVerInfo.dwFileVersionMS), HIWORD(mmVerInfo.dwFileVersionLS), LOWORD(mmVerInfo.dwFileVersionLS)]);
    finally
     FreeMem(mmBuf);
    end;
  except
  end;
end;

//参考: delphi application 属性和方法 http://blog.sina.com.cn/s/blog_66357ab901012t2d.html
//不受WINDOWS日期格式的影响: 设置WINDOWS系统的短日期的格式
function fSetMyDateFormat() : String;
begin
  SetLocaleInfo(LOCALE_SYSTEM_DEFAULT, LOCALE_SSHORTDATE, 'yyyy-MM-dd');
  Application.UpdateFormatSettings := False;        //当用户改变系统配置时应用程序是否自动更新格式设置
  LongDateFormat  := 'yyyy-MM-dd';                  //设定程序本身所使用的日期时间格式
  ShortDateFormat := 'yyyy-MM-dd';
  LongTimeFormat  := 'HH:nn:ss';
  ShortTimeFormat := 'HH:nn:ss';
  DateSeparator   := '-';
  TimeSeparator   := ':';
end;

{TDateTimePicker时间格式化}
procedure fFmtDateDTP(aDTPStart,aDTPEnd:TDateTimePicker; aDateTime:TDateTime);
begin
  ReplaceTime(aDateTime,strtotime('00:00:00'));
  if assigned(aDTPStart) then aDTPStart.DateTime := aDateTime;
  ReplaceTime(aDateTime,strtotime('23:59:59'));
  if assigned(aDTPEnd) then aDTPEnd.DateTime := aDateTime;  //+10
end;

{设置DateTimePicker的时间}
procedure fDTPsetDateTime(aDTP:TDateTimePicker; aDstr:String);
var
  mmFSetting : TFormatSettings;
begin
  mmFSetting.ShortDateFormat:='yyyy-MM-dd';   //日期时间格式: 避免不同操作系统格式不同的Bug
  mmFSetting.DateSeparator:='-';
  mmFSetting.LongTimeFormat:='HH:mm:ss';
  mmFSetting.TimeSeparator:=':';
  aDTP.DateTime := StrToDateTime(aDstr, mmFSetting);
end;

{动态改变DateTimePicker控件的值}
procedure f_dtpChangeTime(mmSender:TObject);
var
  mmBuffer : PChar;
  mmSize   : Byte;
  mmDstr   : String;
  mmFSetting : TFormatSettings;
begin
  mmSize := TDateTimePicker(mmSender).GetTextLen;
    inc(mmSize);
    GetMem(mmBuffer,mmSize);
  try
    TDateTimePicker(mmSender).GetTextBuf(mmBuffer,mmSize);

    mmDstr := mmBuffer;
    mmFSetting.ShortDateFormat:='yyyy-MM-dd';   //日期时间格式: 避免不同操作系统格式不同的Bug
    mmFSetting.DateSeparator:='-';
    mmFSetting.LongTimeFormat:='HH:mm:ss';
    mmFSetting.TimeSeparator:=':';
    TDateTimePicker(mmSender).DateTime := StrToDateTime(mmDstr, mmFSetting);
    //f_CodeSite(formatdatetime('yyyy-MM-dd HH:mm:ss',TDateTimePicker(mmSender).Datetime));
  finally
    FreeMem(mmBuffer,mmSize);
  end;
end;

{Memo控件添加信息}
function  fAddMemoInfo(aMemo:TMemo; aInfo:String):String;
begin
  aMemo.Lines.Add(FormatDateTime('yyyy-MM-dd HH:mm:ss ',now)+aInfo);
  if aMemo.Lines.Count>1000 then aMemo.Lines.Clear;
end;

//按行读入一个文件到TStringList
function fLoadFileToList(aFile:String; var aList:TStringList; aNoSpace:Boolean=true) : String;
var
  mmFile : TextFile;
  mmStr  : String;
begin
  try
    aList.Clear;
    if Not FileExists(aFile) then exit;
      
    AssignFile(mmFile, aFile);
    try
      Reset(mmFile);                            //以只读方式打开文件
      while not Eof(mmFile) do begin
        readln(mmFile,mmStr);                   //按行读入
        mmStr := trim(mmStr);
        if aNoSpace then begin                  //忽略空行
          if mmStr<>'' then aList.Add(mmStr);
        end else            aList.Add(mmStr);
      end;
    finally
      CloseFile(mmFile);
    end;
  except
    on e: exception do result := E.Message;
  end;
end;

//写入文件一行
function fWriteFLine(aFName,aStr:String; var aEStr:String):boolean;
var
  mmF : TextFile;
begin
  result := false;
  aEStr  := '';
  try
    AssignFile(mmF, aFName);
    try
      if FileExists(aFName) then  Append(mmF)
      else                        ReWrite(mmF);
      WriteLn(mmF, aStr);
      result := true;
    finally
      CloseFile(mmF);
    end;
  except
    on e: exception do aEStr := E.Message;
  end;
end;

{
function wxcLogToFile(aWhere:String; aLog:String; aType:Integer=0):Boolean;
  //写入文件一行
  function fffWriteFLine(aFName,aStr:String):boolean;
  var
    mmF : TextFile;
  begin
    result := false;
    try
      AssignFile(mmF, aFName);
      try
        if FileExists(aFName) then  Append(mmF)
        else                        ReWrite(mmF);
        WriteLn(mmF, aStr);
        result := true;
      finally
        CloseFile(mmF);
      end;
    except
      //
    end;
  end;
var
  mmDir, mmFName : String;
begin
  result := false;
  try
    mmDir   := gMyApp.Path + 'wxcLog\';
    if Not DirectoryExists(mmDir) then ForceDirectories(mmDir);
    mmFName := mmDir + FormatDateTime('yyyy-MM-dd', now) + '.Log';
    result  := fffWriteFLine(mmFName, FormatDateTime('yyyy-MM-dd HH:mm:ss',now) + ' ' + aLog);
  except

  end;
end;
}

end.
