unit imCustomCombo;

{ Custom Combo using igArrowButton
  inspired from https://github.com/ocornut/imgui/issues/1658 }

interface

uses
  SysUtils,
  PasImGui;

type
  // Persistent UI state for the combo
  TComboState = record
    Items: array of string;
    CurrentIndex: Integer; // -1 means "no selection"
  end;

  // Initialize state with a predefined list of items
procedure InitComboState(var S: TComboState; const AItems: array of string;
  const ADefaultIndex: Integer = -1);

// Render the combo + left/right arrow buttons.
// Returns True if the selection changed this frame.
function RenderCustomCombo(var S: TComboState; const ACaption: PAnsiChar;
  const AIdSuffix: PAnsiChar): Boolean; overload;
function RenderCustomCombo(var S: TComboState; const ACaption: PAnsiChar)
  : Boolean; overload;

// Retrieve the selected value as string. Returns '' if none.
function GetSelectedValue(const S: TComboState): string;

// Set by value; picks the first exact match, or keeps current if not found.
procedure SetSelectedValue(var S: TComboState; const AValue: string);

implementation

procedure InitComboState(var S: TComboState; const AItems: array of string;
  const ADefaultIndex: Integer);
var
  i: Integer;
begin
  SetLength(S.Items, Length(AItems));
  for i := 0 to High(AItems) do
    S.Items[i] := AItems[i];
  if (ADefaultIndex >= 0) and (ADefaultIndex <= High(S.Items)) then
    S.CurrentIndex := ADefaultIndex
  else
    S.CurrentIndex := -1; // none selected
end;

function GetSelectedValue(const S: TComboState): string;
begin
  if (S.CurrentIndex >= 0) and (S.CurrentIndex <= High(S.Items)) then
    Result := S.Items[S.CurrentIndex]
  else
    Result := '';
end;

procedure SetSelectedValue(var S: TComboState; const AValue: string);
var
  i: Integer;
begin
  for i := 0 to High(S.Items) do
    if S.Items[i] = AValue then
    begin
      S.CurrentIndex := i;
      Exit;
    end;
  // not found -> keep current
end;

function RenderCustomCombo(var S: TComboState;
  const ACaption: PAnsiChar): Boolean;
begin
  Result := RenderCustomCombo(S, ACaption, '##custom');
end;

function RenderCustomCombo(var S: TComboState; const ACaption: PAnsiChar;
  const AIdSuffix: PAnsiChar): Boolean;
var
  style: PImGuiStyle;
  w, spacing, buttonSz: Single;
  preview: string;
  changed: Boolean;
  i: Integer;
  isSelected: Boolean;
  labelCombo, labelLeft, labelRight: RawByteString;
begin
  Result := False;
  if Length(S.Items) = 0 then
    Exit;

  changed := False;

  // Sizing & style
  style := ImGui.GetStyle;
  w := ImGui.CalcItemWidth;
  spacing := style.ItemInnerSpacing.x;
  buttonSz := ImGui.GetFrameHeight;

  // IDs: use a suffix to isolate multiple instances on the same frame if needed
  labelCombo := '##combo' + AnsiString(AIdSuffix);
  labelLeft := '##left' + AnsiString(AIdSuffix);
  labelRight := '##right' + AnsiString(AIdSuffix);

  // Preview text (NULL -> no preview; use empty to be explicit)
  preview := GetSelectedValue(S);
  if preview = '' then
    preview := 'Select…';

  // Reserve width for combo + two arrow buttons
  ImGui.PushItemWidth(w - spacing * 2.0 - buttonSz * 2.0);

  if ImGui.BeginCombo(PAnsiChar(labelCombo), PAnsiChar(AnsiString(preview)),
    ImGuiComboFlags_NoArrowButton) then
  begin
    for i := 0 to High(S.Items) do
    begin
      isSelected := (S.CurrentIndex = i);
      if ImGui.Selectable(PAnsiChar(AnsiString(S.Items[i])), isSelected) then
      begin
        if S.CurrentIndex <> i then
        begin
          S.CurrentIndex := i;
          changed := True;
        end;
      end;
      if isSelected then
        ImGui.SetItemDefaultFocus;
    end;
    ImGui.EndCombo;
  end;

  ImGui.PopItemWidth;

  // Left arrow: previous
  ImGui.SameLine(0, spacing);
  if ImGui.ArrowButton(PAnsiChar(labelLeft), ImGuiDir_Left) then
  begin
    if Length(S.Items) > 0 then
    begin
      if S.CurrentIndex < 0 then
        S.CurrentIndex := 0
      else if S.CurrentIndex = 0 then
        S.CurrentIndex := High(S.Items)
      else
        Dec(S.CurrentIndex);
      changed := True;
    end;
  end;

  // Right arrow: next
  ImGui.SameLine(0, spacing);
  if ImGui.ArrowButton(PAnsiChar(labelRight), ImGuiDir_Right) then
  begin
    if Length(S.Items) > 0 then
    begin
      if S.CurrentIndex < 0 then
        S.CurrentIndex := 0
      else if S.CurrentIndex = High(S.Items) then
        S.CurrentIndex := 0
      else
        Inc(S.CurrentIndex);
      changed := True;
    end;
  end;

  ImGui.SameLine(0, style.ItemInnerSpacing.x);
  ImGui.Text(ACaption);

  Result := changed;
end;

end.
