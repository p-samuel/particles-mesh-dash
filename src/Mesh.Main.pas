unit Mesh.Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Layouts, FMX.StdCtrls, FMX.Controls.Presentation, FMX.Colors;

type
  TLine = record
    P1, P2: TPointF;
    Id1, Id2: Integer;
    Opa: Single;
  end;

  TLineList = Array of TLine;

  TParticle = record
    Pos, Pos2,
    Dir: TPointF;
    Vel: Single;
    gVel: Single;
    Avaiable: Boolean;
    function CircleRec(const aRect: TRectF): TRectF;
  end;

  TParticleList = array of TParticle;

  TFormMain = class(TForm)
    lytMesh: TLayout;
    PaintBox: TPaintBox;
    lytControls: TLayout;
    lytColor: TLayout;
    lbColor: TLabel;
    cbColor: TComboColorBox;
    lytDistance: TLayout;
    lbDistance: TLabel;
    trkDistance: TTrackBar;
    lytMaxSpeed: TLayout;
    lbMaxSpeed: TLabel;
    trkMaxSpeed: TTrackBar;
    lytParticles: TLayout;
    trkParticles: TTrackBar;
    lbParticles: TLabel;
    lytSpeed: TLayout;
    lbSpeed: TLabel;
    trkSpeed: TTrackBar;
    lytThickness: TLayout;
    lbThickness: TLabel;
    trkThickness: TTrackBar;
    Timer: TTimer;
    Layout1: TLayout;
    lbGravity: TLabel;
    trkGravity: TTrackBar;
    procedure trkParticlesTracking(Sender: TObject);
    procedure trkSpeedTracking(Sender: TObject);
    procedure trkDistanceTracking(Sender: TObject);
    procedure trkThicknessTracking(Sender: TObject);
    procedure trkMaxSpeedTracking(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure PaintBoxPainting(Sender: TObject; Canvas: TCanvas;
      const ARect: TRectF);
    procedure PaintBoxPaint(Sender: TObject; Canvas: TCanvas);
    procedure FormCreate(Sender: TObject);
    procedure trkGravityTracking(Sender: TObject);
    public
      Pal: TParticleList;
      Lil: TLineList;
      IsCalc: Boolean;
      procedure Init;
      procedure CalcUpdate;
  end;

var
  FormMain: TFormMain;



implementation

uses System.Math, FMX.Utils;

{$R *.fmx}

{ TParticle }

function TParticle.CircleRec(const aRect: TRectF): TRectF;
var P: TPointF;
  S, U: Single;
begin
  if Vel <> 0 then
  begin
    P := aRect.CenterPoint + Pos * aRect.BottomRight;
    Result := TRectF.Empty;
    Result.Location := P;
    U := 3 / 1800;
    S := U * aRect.BottomRight.Length;
    S := ((1 - Vel) + 1E-2) * S;
    Result.Inflate(S, S);
  end;
end;

{ TFormMain }

procedure TFormMain.CalcUpdate;
var Anz, I, A, B: Integer;
  g, Dis, Spe, SpeVal, L: Single;
  P, N: TParticle;
  U: TLine;
  K: TPointF;

begin

  if IsCalc then Exit;
  IsCalc := True;

  try
    Anz := Trunc(trkParticles.Value);
    Spe := trkSpeed.Value;
    Dis := 1E-6 + trkDistance.Value;
    SpeVal := trkSpeed.Value;
    g := trkGravity.Value;
    
    SetLength(Pal, Anz);
    for i := Low(Pal) to High(Pal) do
    begin
      P := Pal[i];
      with P do
      begin
        if Avaiable then                                         
        begin
          K := Pos + Dir * (Vel * SpeVal);
          with Dir do 
          begin
            if K.X > 0.5 then X := -X;
            if K.Y > 0.5 then Y := -Y;
            if K.X < -0.5 then X := Abs(X);
            if K.Y < -0.5 then Y := Abs(Y);
          end;
          Pos2 := Pos;
          Pos := Pos + Dir * (Vel * SpeVal);
          gVel := Vel;
          Vel := Sqrt(Power(gVel, 2) + 2 * g * (Pos - Pos2).Length);
          Pos := Pos + Dir * (Vel * SpeVal )  ;

        end else begin
          Pos := TPointF.Create(0.5 - Random, 0.5 - Random);
          Dir := TPointF.Create(0.5 - Random, 0.5 - Random)/10;
          Vel := 0.01 + Random + Spe;
          Avaiable := True;
        end  
      end;
      Pal[i] := P;
    end;

    Lil := nil;

    for A := 0 to High(Pal) do
    begin
      P := Pal[A];
      for B := 0 to High(Pal) do
      begin
        if A >= B then Continue;
        N := Pal[B];
        L := (P.Pos - N.Pos).Length;
        if L >= Dis then Continue;

        U.Id1 := A;
        U.Id2 := B;
        U.P1 := P.Pos;
        U.P2 := N.Pos;
        U.Opa := 0;

        if L < Dis 
        then U.Opa := (1/Dis) * (Dis - L)
        else Continue;

        SetLength(Lil, Length(Lil) + 1);
        Lil[High(Lil)] := U;
      end;
    end;
    
  finally
    IsCalc := False;    
  end;
end;

procedure TFormMain.FormCreate(Sender: TObject);
begin
  RandSeed := 1;
  Init;
end;

procedure TFormMain.Init;
begin                                                   
 trkDistanceTracking(nil);
 trkMaxSpeedTracking(nil);
 trkParticlesTracking(nil);
 trkSpeedTracking(nil);
 trkThicknessTracking(nil);
 trkGravityTracking(nil);
end;

procedure TFormMain.PaintBoxPaint(Sender: TObject; Canvas: TCanvas);
var 
  P: TParticle;
  I: Integer;
  Save: TCanvasSaveState;
  G: TBrush;
  S: TStrokeBrush;
  R: TRectF;
  U: TLine;
const 
  ParticleC: array [0..5] of TAlphaColor = (
    $FF54A7D6, $FFE38B41, $FFE2D84A, $FF5A99C, $FFCEA942, $FF4662C4);
begin

  Save := Canvas.SaveState;
  R := PaintBox.LocalRect;
  G := TBrush.Create(TBrushKind.Solid, TAlphacolors.White);
  S := TStrokeBrush.Create(TBrushKind.Solid, TAlphaColors.White);
  S.Thickness := trkThickness.Value;

  for i := 0 to High(Lil) do 
  begin
    U := Lil[i];
    S.Color := InterpolateColor(ParticleC[U.Id1 mod 6], ParticleC[U.Id2 mod 6], 0.5);

    Canvas.DrawLine(
      R.CenterPoint + U.P1 * R.BottomRight,
      R.CenterPoint + U.P2 * R.BottomRight,
      U.Opa, S
    );    
  end;

  for i := 0 to High(Pal) do
  begin
    P := Pal[i];
    G.Color := ParticleC[i mod 6];
    Canvas.FillEllipse(P.CircleRec(R), 1, G);
  end;
  
  S.Free;
  G.Free;
  Canvas.RestoreState(Save);
  
end;

procedure TFormMain.PaintBoxPainting(Sender: TObject; Canvas: TCanvas;
  const ARect: TRectF);
begin
  Canvas.ClearRect(ARect, cbColor.Color);
end;

procedure TFormMain.TimerTimer(Sender: TObject);
begin
  CalcUpdate;
  if not IsCalc then PaintBox.Repaint;
end;

procedure TFormMain.trkDistanceTracking(Sender: TObject);
var L: Single; S: String;
begin
  lbDistance.Text := Format('Distance: %.3f', [trkDistance.Value]);
end;

procedure TFormMain.trkGravityTracking(Sender: TObject);
begin
  lbGravity.Text := Format('Gravity: %.3f', [trkGravity.Value])
end;

procedure TFormMain.trkMaxSpeedTracking(Sender: TObject);
begin
  lbMaxSpeed.Text := Format('Max. Speed: %.3f', [trkMaxSpeed.Value])
end;

procedure TFormMain.trkParticlesTracking(Sender: TObject);
begin
  lbParticles.Text := Format('Particles: %.0f', [trkParticles.Value]);
end;

procedure TFormMain.trkSpeedTracking(Sender: TObject);
begin
  lbSpeed.Text := Format('Speed: %.3f', [trkSpeed.Value])
end;

procedure TFormMain.trkThicknessTracking(Sender: TObject);
begin
  lbThickness.Text :=  Format('Thickness: %.0f', [trkThickness.Value])
end;

end.
